import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ru_family/dashboard.dart';

class MemberRegistrationPage extends StatefulWidget {
  const MemberRegistrationPage({super.key});

  @override
  State<MemberRegistrationPage> createState() => _MemberRegistrationPageState();
}

class _MemberRegistrationPageState extends State<MemberRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _universityIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _hallController = TextEditingController();
  final _presentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _socialMediaIdController = TextEditingController();

  String? _selectedSomiti;
  String? _selectedBloodGroup;
  List<String> _somitiNames = [];
  String _searchQuery = '';
  bool _isLoadingSomitis = true;
  bool _isSubmitting = false;
  bool _showVerification = false;

  // Blood groups
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSomitiNames();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _hallController.dispose();
    _presentAddressController.dispose();
    _permanentAddressController.dispose();
    _emergencyContactController.dispose();
    _socialMediaIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchSomitiNames() async {
    setState(() {
      _isLoadingSomitis = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('somitis')
          .get();

      setState(() {
        _somitiNames = snapshot.docs
            .map((doc) => doc['somitiName'] as String)
            .toList();
        _isLoadingSomitis = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('সমিতি লোড করতে সমস্যা: $e')));
      setState(() {
        _isLoadingSomitis = false;
      });
    }
  }

  List<String> _getFilteredSomitiNames() {
    if (_searchQuery.isEmpty) {
      return _somitiNames;
    }
    return _somitiNames
        .where(
          (name) => name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedSomiti == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('সমস্ত তথ্য পূরণ করুন।')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Add member data to Firestore
      await FirebaseFirestore.instance.collection('members').add({
        'name': _nameController.text.trim(),
        'universityId': _universityIdController.text.trim(),
        'email': _emailController.text.trim(),
        'mobileNumber': _mobileController.text.trim(),
        'hall': _hallController.text.trim(),
        'presentAddress': _presentAddressController.text.trim(),
        'permanentAddress': _permanentAddressController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'socialMediaId': _socialMediaIdController.text.trim(),
        'bloodGroup': _selectedBloodGroup ?? '',
        'somitiName': _selectedSomiti,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user!.uid,
      });

      if (mounted) {
        setState(() {
          _showVerification = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'সদস্য তথ্য সফলভাবে সংরক্ষিত! ইমেইলে ভেরিফিকেশন লিঙ্ক চেক করুন এবং নিচের বাটনে ক্লিক করুন।',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'সংরক্ষণ ত্রুটি';
      if (e.code == 'email-already-in-use') {
        message = 'এই ইমেইল ইতিমধ্যে ব্যবহার করা হয়েছে।';
      } else if (e.code == 'weak-password') {
        message = 'পাসওয়ার্ড দুর্বল।';
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('সংরক্ষণ ত্রুটি: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _checkVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      await user.getIdToken(true); // Refresh token
      if (user.emailVerified) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SomitiDashboard()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('এখনও ইমেইল ভেরিফাই করা হয়নি। লিঙ্কে ক্লিক করুন।'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSomitiNames = _getFilteredSomitiNames();

    return Scaffold(
      appBar: AppBar(
        title: const Text('সদস্য নিবন্ধন'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_showVerification) ...[
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'নাম',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'নাম প্রয়োজনীয়।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // University ID
                  TextFormField(
                    controller: _universityIdController,
                    decoration: const InputDecoration(
                      labelText: 'বিশ্ববিদ্যালয় আইডি',
                      prefixIcon: Icon(Icons.school),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'বিশ্ববিদ্যালয় আইডি প্রয়োজনীয়।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'ইমেইল',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'ইমেইল প্রয়োজনীয়।';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'অবৈধ ইমেইল ঠিকানা।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'পাসওয়ার্ড',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'পাসওয়ার্ড প্রয়োজনীয়।';
                      }
                      if (value.length < 6) {
                        return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mobile Number
                  TextFormField(
                    controller: _mobileController,
                    decoration: const InputDecoration(
                      labelText: 'মোবাইল নম্বর',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'মোবাইল নম্বর প্রয়োজনীয়।';
                      }
                      if (value.length < 11) {
                        return 'সঠিক মোবাইল নম্বর দিন।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Hall
                  TextFormField(
                    controller: _hallController,
                    decoration: const InputDecoration(
                      labelText: 'হল',
                      prefixIcon: Icon(Icons.home),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'হলের নাম প্রয়োজনীয়।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Present Address
                  TextFormField(
                    controller: _presentAddressController,
                    decoration: const InputDecoration(
                      labelText: 'বর্তমান ঠিকানা',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'বর্তমান ঠিকানা প্রয়োজনীয়।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Permanent Address
                  TextFormField(
                    controller: _permanentAddressController,
                    decoration: const InputDecoration(
                      labelText: 'স্থায়ী ঠিকানা',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'স্থায়ী ঠিকানা প্রয়োজনীয়।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Emergency Contact
                  TextFormField(
                    controller: _emergencyContactController,
                    decoration: const InputDecoration(
                      labelText: 'জরুরি যোগাযোগ (পরিবারের সংখ্যা/নম্বর)',
                      prefixIcon: Icon(Icons.security),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'জরুরি যোগাযোগ প্রয়োজনীয়।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Social Media ID
                  TextFormField(
                    controller: _socialMediaIdController,
                    decoration: const InputDecoration(
                      labelText: 'সোশ্যাল মিডিয়া আইডি',
                      prefixIcon: Icon(Icons.share),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'সোশ্যাল মিডিয়া আইডি প্রয়োজনীয়।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Blood Group Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    decoration: const InputDecoration(
                      labelText: 'রক্তের গ্রুপ',
                      prefixIcon: Icon(Icons.favorite),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    items: _bloodGroups.map((group) {
                      return DropdownMenuItem<String>(
                        value: group,
                        child: Text(group),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBloodGroup = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'রক্তের গ্রুপ নির্বাচন করুন।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Searchable Somiti Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'সমিতি নির্বাচন করুন',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'সমিতি খুঁজুন...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingSomitis)
                        const Center(child: CircularProgressIndicator())
                      else if (_getFilteredSomitiNames().isEmpty)
                        const Text('কোনো সমিতি পাওয়া যায়নি।')
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            itemCount: _getFilteredSomitiNames().length,
                            itemBuilder: (context, index) {
                              final name = _getFilteredSomitiNames()[index];
                              return ListTile(
                                title: Text(name),
                                onTap: () {
                                  setState(() {
                                    _selectedSomiti = name;
                                    _searchQuery = '';
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      if (_selectedSomiti != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'নির্বাচিত: $_selectedSomiti',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'সদস্য যোগ করুন',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  // Verification Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.email, size: 80, color: Colors.blue),
                          const SizedBox(height: 16),
                          const Text(
                            'ইমেইল ভেরিফিকেশন',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'আপনার ইমেইলে একটি লিঙ্ক পাঠানো হয়েছে: ${_emailController.text.trim()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'লিঙ্কে ক্লিক করুন এবং নিচের বাটনে ক্লিক করে ভেরিফিকেশন চেক করুন।',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _checkVerification,
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'ভেরিফিকেশন চেক করুন',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showVerification = false;
                              });
                              _emailController.clear();
                              // Clear other fields if needed
                            },
                            child: const Text('ফর্মে ফিরে যান'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder for SomitiDashboard - define this class elsewhere in your app
