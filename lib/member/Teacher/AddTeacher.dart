// lib/Teacher/AddTeacherInfoPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddTeacherInfoPage extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? docId;

  const AddTeacherInfoPage({super.key, this.existingData, this.docId});

  @override
  State<AddTeacherInfoPage> createState() => _AddTeacherInfoPageState();
}

class _AddTeacherInfoPageState extends State<AddTeacherInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;

  String? _selectedDepartment;
  String? _selectedBloodGroup;
  String _somitiName = 'লোড হচ্ছে...';
  bool _isSubmitting = false;
  bool _isLoading = true;

  List<Map<String, dynamic>> _departments = [];
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

  // Social Media Links
  final List<TextEditingController> _socialControllers = [];
  final List<FocusNode> _socialFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserSomitiAndDept();
    _addSocialField(); // প্রথম ফিল্ড
  }

  void _initializeControllers() {
    final data = widget.existingData ?? {};
    _nameController = TextEditingController(text: data['name'] ?? '');
    _mobileController = TextEditingController(text: data['mobile'] ?? '');
    _addressController = TextEditingController(text: data['address'] ?? '');
    _selectedDepartment = data['department'];
    _selectedBloodGroup = data['bloodGroup'];
    final List<dynamic> social = data['socialMedia'] ?? [];
    if (social.isNotEmpty) {
      _socialControllers.clear();
      _socialFocusNodes.clear();
      for (var link in social) {
        final ctrl = TextEditingController(text: link);
        final focus = FocusNode();
        _socialControllers.add(ctrl);
        _socialFocusNodes.add(focus);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    for (var c in _socialControllers) c.dispose();
    for (var f in _socialFocusNodes) f.dispose();
    super.dispose();
  }

  // Add new social field
  void _addSocialField() {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    setState(() {
      _socialControllers.add(controller);
      _socialFocusNodes.add(focusNode);
    });
  }

  // Remove social field
  void _removeSocialField(int index) {
    if (_socialControllers.length > 1) {
      setState(() {
        _socialControllers[index].dispose();
        _socialFocusNodes[index].dispose();
        _socialControllers.removeAt(index);
        _socialFocusNodes.removeAt(index);
      });
    }
  }

  // Get valid social links
  List<String> _getSocialLinks() {
    return _socialControllers
        .map((c) => c.text.trim())
        .where((link) => link.isNotEmpty && link.startsWith('http'))
        .toList();
  }

  // ==================== LOAD SOMITI & DEPARTMENTS ====================
  Future<void> _loadUserSomitiAndDept() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('লগইন করা নেই।')));
      }
      return;
    }

    try {
      // Load Somiti
      final memberSnap = await FirebaseFirestore.instance
          .collection('members')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      String somiti = 'অজানা সমিতি';
      if (memberSnap.docs.isNotEmpty) {
        somiti =
            memberSnap.docs.first['somitiName']?.toString() ?? 'অজানা সমিতি';
      }

      // Load Departments from API
      final deptRes = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/RU_Subjcet_api.json',
        ),
      );

      List<Map<String, dynamic>> depts = [];
      if (deptRes.statusCode == 200) {
        final List jsonList = jsonDecode(deptRes.body);
        depts = jsonList.cast<Map<String, dynamic>>();
      }

      if (mounted) {
        setState(() {
          _somitiName = somiti;
          _departments = depts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('লোড করতে সমস্যা: $e')));
        setState(() {
          _somitiName = 'লোড করা যায়নি';
          _isLoading = false;
        });
      }
    }
  }

  // ==================== SEARCHABLE DEPARTMENT FIELD ====================
  Widget _buildDepartmentField() {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: _selectedDepartment),
      decoration: InputDecoration(
        labelText: 'বিভাগ',
        prefixIcon: const Icon(Icons.school),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        hintText: 'বিভাগ নির্বাচন করুন',
      ),
      validator: (v) =>
          _selectedDepartment == null ? 'বিভাগ নির্বাচন করুন' : null,
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) {
            String searchQuery = '';
            List<Map<String, dynamic>> filtered = List.from(_departments);

            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  title: const Text('বিভাগ নির্বাচন করুন'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: Column(
                      children: [
                        TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'বিভাগ খুঁজুন...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setStateDialog(() {
                              searchQuery = value;
                              filtered = _departments.where((dept) {
                                return dept['name']
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.toLowerCase());
                              }).toList();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Text('কোনো বিভাগ পাওয়া যায়নি'),
                                )
                              : ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (ctx, i) {
                                    final name = filtered[i]['name'].toString();
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.school,
                                        color: Colors.blue,
                                      ),
                                      title: Text(
                                        name,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _selectedDepartment = name;
                                        });
                                        Navigator.pop(ctx);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('বাতিল'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ==================== SUBMIT / UPDATE FORM ====================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDepartment == null ||
        _selectedBloodGroup == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('সব তথ্য পূরণ করুন।')));
      return;
    }

    final socialLinks = _getSocialLinks();
    if (socialLinks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অন্তত একটি সোশ্যাল লিংক দিন।')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final teacherData = {
        'name': _nameController.text.trim(),
        'department': _selectedDepartment,
        'mobile': _mobileController.text.trim(),
        'address': _addressController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'socialMedia': socialLinks,
        'somitiName': _somitiName,
        'addedByUid': user.uid,
        'addedByEmail': user.email,
        'createdAt': widget.existingData == null
            ? FieldValue.serverTimestamp()
            : widget.existingData!['createdAt'],
      };

      if (widget.docId == null) {
        // নতুন যোগ
        await FirebaseFirestore.instance
            .collection('teachers')
            .add(teacherData);
      } else {
        // আপডেট
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(widget.docId)
            .update(teacherData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.docId == null
                  ? 'শিক্ষকের তথ্য সফলভাবে যোগ করা হয়েছে!'
                  : 'শিক্ষকের তথ্য আপডেট করা হয়েছে!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('সংরক্ষণে ত্রুটি: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.docId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'শিক্ষকের তথ্য এডিট করুন' : 'শিক্ষকের তথ্য যোগ করুন',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Somiti (Auto)
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.groups, color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(
                                'সমিতি: $_somitiName',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'নাম',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'নাম দিন' : null,
                      ),
                      const SizedBox(height: 16),

                      // Department
                      _buildDepartmentField(),
                      const SizedBox(height: 16),

                      // Mobile
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'মোবাইল নম্বর',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v?.trim().isEmpty ?? true) return 'মোবাইল দিন';
                          if (v!.length < 11) return 'সঠিক নম্বর দিন';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'বর্তমান ঠিকানা',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'ঠিকানা দিন' : null,
                      ),
                      const SizedBox(height: 16),

                      // Blood Group
                      DropdownButtonFormField<String>(
                        value: _selectedBloodGroup,
                        decoration: InputDecoration(
                          labelText: 'রক্তের গ্রুপ',
                          prefixIcon: const Icon(Icons.bloodtype),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                        ),
                        items: _bloodGroups
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedBloodGroup = v),
                        validator: (v) =>
                            v == null ? 'রক্তের গ্রুপ নির্বাচন করুন' : null,
                      ),
                      const SizedBox(height: 20),

                      // Social Media Links
                      const Text(
                        'সোশ্যাল মিডিয়া লিংক',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._socialControllers.asMap().entries.map((entry) {
                        int idx = entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: _socialControllers[idx],
                            focusNode: _socialFocusNodes[idx],
                            decoration: InputDecoration(
                              hintText: 'https://facebook.com/...',
                              prefixIcon: const Icon(Icons.link),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_socialControllers.length > 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeSocialField(idx),
                                    ),
                                  if (idx == _socialControllers.length - 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Colors.green,
                                      ),
                                      onPressed: _addSocialField,
                                    ),
                                ],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.url,
                            validator: (v) {
                              final link = v?.trim() ?? '';
                              if (link.isEmpty) return null;
                              if (!link.startsWith('http'))
                                return 'সঠিক URL দিন';
                              return null;
                            },
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isSubmitting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'সংরক্ষণ হচ্ছে...',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                )
                              : Text(
                                  isEditMode ? 'আপডেট করুন' : 'শিক্ষক যোগ করুন',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
