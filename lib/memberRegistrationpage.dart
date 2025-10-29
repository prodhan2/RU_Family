import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ru_family/dashboard.dart'; // Make sure this is SomitiDashboard

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
  final _presentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _socialMediaIdController = TextEditingController();

  String? _selectedSomiti;
  String? _selectedBloodGroup;
  List<String> _somitiNames = [];
  bool _isLoadingSomitis = true;
  bool _isSubmitting = false;
  bool _showVerification = false;
  bool _isVerifying = false;

  // Auto-detected values
  String _detectedSession = '';
  String _detectedHall = '';
  String _detectedDept = '';

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

  // JSON cache
  List<Map<String, dynamic>> _hallList = [];
  List<Map<String, dynamic>> _deptList = [];
  bool _isLoadingHallDept = false;

  Timer? _verificationTimer;
  int _retryCount = 0;
  final int _maxRetries = 40; // ~2 minutes max

  @override
  void initState() {
    super.initState();
    _fetchSomitiNames();
    _fetchHallAndDeptData();
    _universityIdController.addListener(_onUniversityIdChanged);
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _nameController.dispose();
    _universityIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _presentAddressController.dispose();
    _permanentAddressController.dispose();
    _emergencyContactController.dispose();
    _socialMediaIdController.dispose();
    super.dispose();
  }

  // ==================== SOMITI LOADING ====================
  Future<void> _fetchSomitiNames() async {
    setState(() => _isLoadingSomitis = true);
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
      _showSnackBar('সমিতি লোড করতে সমস্যা: $e');
      setState(() => _isLoadingSomitis = false);
    }
  }

  // ==================== HALL & DEPT JSON ====================
  Future<void> _fetchHallAndDeptData() async {
    setState(() => _isLoadingHallDept = true);
    try {
      final hallRes = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/RU_Hall_api.json',
        ),
      );
      final deptRes = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/RU_Subjcet_api.json',
        ),
      );

      if (hallRes.statusCode == 200 && deptRes.statusCode == 200) {
        final hallJson = jsonDecode(hallRes.body) as List;
        final deptJson = jsonDecode(deptRes.body) as List;

        setState(() {
          _hallList = hallJson.cast<Map<String, dynamic>>();
          _deptList = deptJson.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      _showSnackBar('Hall/Dept লোড করতে সমস্যা: $e');
    } finally {
      setState(() => _isLoadingHallDept = false);
    }
  }

  // ==================== UNIVERSITY ID AUTO-DETECT ====================
  void _onUniversityIdChanged() {
    final id = _universityIdController.text.trim();

    if (id.length != 10 || !RegExp(r'^\d{10}$').hasMatch(id)) {
      setState(() {
        _detectedSession = _detectedHall = _detectedDept = '';
      });
      return;
    }

    // Session: first 2 digits → 21 → 2020-21
    final sessionCode = id.substring(0, 2);
    final sessionYear = int.parse('20$sessionCode') - 1;
    final session = '$sessionYear-${sessionYear + 1}';

    // Hall: next 3 digits → 104
    final hallCode = int.tryParse(id.substring(2, 5));
    final hallEntry = hallCode != null
        ? _hallList.firstWhere(
            (e) => e['hallCode'] == hallCode,
            orElse: () => {},
          )
        : null;
    final hallName = hallEntry?['hallName']?.toString() ?? 'অজানা হল';

    // Department: digits 6-7 → 76
    final deptCodeStr = id.substring(5, 7);
    final deptCode = int.tryParse(deptCodeStr);
    final deptEntry = deptCode != null
        ? _deptList.firstWhere((e) => e['code'] == deptCode, orElse: () => {})
        : null;
    final deptName = deptEntry?['name']?.toString() ?? 'অজানা বিভাগ';

    setState(() {
      _detectedSession = session;
      _detectedHall = hallName;
      _detectedDept = deptName;
    });
  }

  // ==================== FORM SUBMIT ====================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _selectedSomiti == null ||
        _universityIdController.text.length != 10) {
      _showSnackBar('সমস্ত তথ্য সঠিকভাবে পূরণ করুন।');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await cred.user!.sendEmailVerification();

      // Save to Firestore
      await FirebaseFirestore.instance.collection('members').add({
        'name': _nameController.text.trim(),
        'universityId': _universityIdController.text.trim(),
        'email': _emailController.text.trim(),
        'mobileNumber': _mobileController.text.trim(),
        'hall': _detectedHall,
        'department': _detectedDept,
        'presentAddress': _presentAddressController.text.trim(),
        'permanentAddress': _permanentAddressController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'socialMediaId': _socialMediaIdController.text.trim(),
        'bloodGroup': _selectedBloodGroup ?? '',
        'somitiName': _selectedSomiti,
        'session': _detectedSession,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': cred.user!.uid,
      });

      if (mounted) {
        setState(() {
          _showVerification = true;
          _isVerifying = true;
          _retryCount = 0;
        });

        _showSnackBar(
          'ইমেইল ভেরিফিকেশন লিঙ্ক পাঠানো হয়েছে। চেক করুন!',
          backgroundColor: Colors.green,
        );

        _startVerificationPolling();
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'সংরক্ষণ ত্রুটি';
      if (e.code == 'email-already-in-use') {
        msg = 'এই ইমেইল ইতিমধ্যে ব্যবহার করা হয়েছে।';
      } else if (e.code == 'weak-password') {
        msg = 'পাসওয়ার্ড দুর্বল।';
      }
      _showSnackBar(msg);
    } catch (e) {
      _showSnackBar('সংরক্ষণ ত্রুটি: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ==================== AUTO VERIFICATION POLLING ====================
  void _startVerificationPolling() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      if (_retryCount++ >= _maxRetries) {
        timer.cancel();
        if (mounted) {
          setState(() => _isVerifying = false);
          _showSnackBar(
            'সময় শেষ। ম্যানুয়ালি চেক করুন।',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        timer.cancel();
        return;
      }

      try {
        await user.reload();
        if (user.emailVerified) {
          timer.cancel();
          if (mounted) {
            _showSnackBar(
              'ইমেইল ভেরিফাইড! ড্যাশবোর্ডে যাচ্ছেন...',
              backgroundColor: Colors.green,
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SomitiDashboard()),
            );
          }
        }
      } catch (e) {
        // Ignore network errors, continue polling
      }
    });
  }

  // Optional: Manual check fallback
  Future<void> _checkVerificationManually() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        _verificationTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SomitiDashboard()),
        );
      } else {
        _showSnackBar(
          'এখনও ভেরিফাই করা হয়নি। ইমেইল চেক করুন।',
          backgroundColor: Colors.orange,
        );
      }
    }
  }

  // Helper: Show SnackBar
  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  // ==================== UI BUILD ====================
  @override
  Widget build(BuildContext context) {
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
                  _buildTextField(
                    _nameController,
                    'নাম',
                    Icons.person,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'নাম প্রয়োজনীয়।' : null,
                  ),

                  const SizedBox(height: 16),

                  // Somiti Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedSomiti,
                    decoration: const InputDecoration(
                      labelText: 'সমিতি নির্বাচন করুন',
                      prefixIcon: Icon(Icons.groups),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    hint: _isLoadingSomitis
                        ? const Text('লোড হচ্ছে...')
                        : const Text('সমিতি নির্বাচন করুন'),
                    isExpanded: true,
                    items: _somitiNames
                        .map(
                          (name) =>
                              DropdownMenuItem(value: name, child: Text(name)),
                        )
                        .toList(),
                    onChanged: _isLoadingSomitis
                        ? null
                        : (v) => setState(() => _selectedSomiti = v),
                    validator: (v) => v == null ? 'সমিতি নির্বাচন করুন।' : null,
                  ),
                  const SizedBox(height: 16),

                  // University ID
                  TextFormField(
                    controller: _universityIdController,
                    decoration: const InputDecoration(
                      labelText: 'বিশ্ববিদ্যালয় আইডি (যেমন: 2110476128)',
                      prefixIcon: Icon(Icons.school),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'আইডি প্রয়োজনীয়।';
                      if (v!.length != 10) return 'আইডি ১০ সংখ্যার হতে হবে।';
                      return null;
                    },
                  ),

                  // Auto-detected info
                  if (_detectedSession.isNotEmpty ||
                      _detectedHall.isNotEmpty ||
                      _detectedDept.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_detectedSession.isNotEmpty)
                                Text(
                                  'সেশন: $_detectedSession',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (_detectedHall.isNotEmpty)
                                Text(
                                  'হল: $_detectedHall',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              if (_detectedDept.isNotEmpty)
                                Text(
                                  'বিভাগ: $_detectedDept',
                                  style: const TextStyle(color: Colors.purple),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Email
                  _buildTextField(
                    _emailController,
                    'ইমেইল',
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'ইমেইল প্রয়োজনীয়।';
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(v!))
                        return 'অবৈধ ইমেইল।';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password
                  _buildTextField(
                    _passwordController,
                    'পাসওয়ার্ড',
                    Icons.lock,
                    obscureText: true,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'পাসওয়ার্ড প্রয়োজনীয়।';
                      if (v!.length < 6) return 'কমপক্ষে ৬ অক্ষর।';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Mobile
                  _buildTextField(
                    _mobileController,
                    'মোবাইল নম্বর',
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'মোবাইল প্রয়োজনীয়।';
                      if (v!.length < 11) return 'সঠিক নম্বর দিন।';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Present Address
                  _buildTextField(
                    _presentAddressController,
                    'বর্তমান ঠিকানা',
                    Icons.location_on,
                    maxLines: 3,
                    validator: (v) => v?.isEmpty ?? true
                        ? 'বর্তমান ঠিকানা প্রয়োজনীয়।'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Permanent Address
                  _buildTextField(
                    _permanentAddressController,
                    'স্থায়ী ঠিকানা',
                    Icons.location_city,
                    maxLines: 3,
                    validator: (v) => v?.isEmpty ?? true
                        ? 'স্থায়ী ঠিকানা প্রয়োজনীয়।'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Emergency Contact
                  _buildTextField(
                    _emergencyContactController,
                    'জরুরি যোগাযোগ',
                    Icons.security,
                    validator: (v) => v?.isEmpty ?? true
                        ? 'জরুরি যোগাযোগ প্রয়োজনীয়।'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Social Media ID
                  _buildTextField(
                    _socialMediaIdController,
                    'সোশ্যাল মিডিয়া আইডি',
                    Icons.share,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'সোশ্যাল আইডি প্রয়োজনীয়।' : null,
                  ),

                  const SizedBox(height: 16),

                  // Blood Group
                  DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    decoration: const InputDecoration(
                      labelText: 'রক্তের গ্রুপ',
                      prefixIcon: Icon(Icons.favorite),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    items: _bloodGroups
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBloodGroup = v),
                    validator: (v) =>
                        v == null ? 'রক্তের গ্রুপ নির্বাচন করুন।' : null,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
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
                                valueColor: AlwaysStoppedAnimation(
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
                  // Verification Screen
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            _isVerifying
                                ? Icons.hourglass_empty
                                : Icons.mark_email_read,
                            size: 80,
                            color: _isVerifying ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isVerifying
                                ? 'ভেরিফিকেশন চেক হচ্ছে...'
                                : 'ইমেইল ভেরিফাইড!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ইমেইল পাঠানো হয়েছে:\n${_emailController.text.trim()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          if (_isVerifying) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 12),
                            const Text(
                              'ইনবক্স/স্প্যাম চেক করুন। লিঙ্কে ক্লিক করুন।\n'
                              'ভেরিফাই হলে স্বয়ংক্রিয়ভাবে ড্যাশবোর্ডে যাবেন।',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Manual Check (Fallback)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isVerifying
                                  ? null
                                  : _checkVerificationManually,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                _isVerifying
                                    ? 'চেক হচ্ছে...'
                                    : 'ম্যানুয়ালি চেক করুন',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              _verificationTimer?.cancel();
                              setState(() {
                                _showVerification = false;
                                _isVerifying = false;
                              });
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

  // Helper: Reusable TextFormField
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      validator: validator,
    );
  }
}
