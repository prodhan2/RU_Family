import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:RUConnect_plus/member/dashboard.dart'; // Make sure this is SomitiDashboard

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
  final _unionController = TextEditingController();

  String? _selectedSomiti;
  Map<String, dynamic>? _selectedSomitiData;
  String? _selectedUnion;
  List<String> _somitiNames = [];
  List<Map<String, dynamic>> _somitis = [];
  bool _isLoadingSomitis = true;
  bool _isSubmitting = false;
  bool _showVerification = false;
  bool _isVerifying = false;

  // Auto-detected values
  String _detectedSession = '';
  String _detectedHall = '';
  String _detectedDept = '';

  String? _selectedBloodGroup;

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
  List<Map<String, dynamic>> _fullUnions = [];
  bool _isLoadingHallDept = false;

  Timer? _verificationTimer;
  int _retryCount = 0;
  final int _maxRetries = 40; // ~2 minutes max

  // Base URL for location API
  static const String BASE_URL =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/RUCSEHUB/LocationApiOFBD/';

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
    _unionController.dispose();
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
        _somitis = snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();
        _somitiNames = _somitis.map((s) => s['somitiName'] as String).toList();
        _isLoadingSomitis = false;
      });
    } catch (e) {
      _showSnackBar('সমিতি লোড করতে সমস্যা: $e');
      setState(() => _isLoadingSomitis = false);
    }
  }

  // ==================== HALL, DEPT & UNIONS JSON WITH SHARED PREFERENCES ====================
  Future<void> _fetchHallAndDeptData() async {
    setState(() => _isLoadingHallDept = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hallsLoaded = false, deptsLoaded = false, unionsLoaded = false;

    // Load halls from SharedPreferences
    if (prefs.containsKey('hall_list')) {
      String? str = prefs.getString('hall_list');
      if (str != null) {
        try {
          List<dynamic> jsonList = jsonDecode(str);
          _hallList = jsonList.cast<Map<String, dynamic>>();
          hallsLoaded = true;
        } catch (e) {
          print('Error loading halls: $e');
        }
      }
    }

    // Load depts from SharedPreferences
    if (prefs.containsKey('dept_list')) {
      String? str = prefs.getString('dept_list');
      if (str != null) {
        try {
          List<dynamic> jsonList = jsonDecode(str);
          _deptList = jsonList.cast<Map<String, dynamic>>();
          deptsLoaded = true;
        } catch (e) {
          print('Error loading depts: $e');
        }
      }
    }

    // Load unions from SharedPreferences
    if (prefs.containsKey('unions_list')) {
      String? str = prefs.getString('unions_list');
      if (str != null) {
        try {
          List<dynamic> jsonList = jsonDecode(str);
          _fullUnions = jsonList.cast<Map<String, dynamic>>();
          unionsLoaded = true;
        } catch (e) {
          print('Error loading unions: $e');
        }
      }
    }

    // If all data loaded from cache, done
    if (hallsLoaded && deptsLoaded && unionsLoaded) {
      setState(() => _isLoadingHallDept = false);
      return;
    }

    // Fetch from API if not fully cached
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
      final unionsRes = await http.get(Uri.parse('$BASE_URL/unions.json'));

      if (hallRes.statusCode == 200) {
        final hallJson = jsonDecode(hallRes.body) as List;
        _hallList = hallJson.cast<Map<String, dynamic>>();
        await prefs.setString('hall_list', jsonEncode(hallJson));
      }
      if (deptRes.statusCode == 200) {
        final deptJson = jsonDecode(deptRes.body) as List;
        _deptList = deptJson.cast<Map<String, dynamic>>();
        await prefs.setString('dept_list', jsonEncode(deptJson));
      }
      if (unionsRes.statusCode == 200) {
        final unionsJson = jsonDecode(unionsRes.body) as List;
        _fullUnions = unionsJson.cast<Map<String, dynamic>>();
        await prefs.setString('unions_list', jsonEncode(unionsJson));
      }
    } catch (e) {
      _showSnackBar('Hall/Dept/Unions লোড করতে সমস্যা: $e');
    } finally {
      setState(() => _isLoadingHallDept = false);
    }
  }

  void _autoFillPermanentAddress() {
    if (_selectedSomitiData == null) return;

    final div = _selectedSomitiData!['divisionName'] ?? '';
    final dist = _selectedSomitiData!['districtName'] ?? '';
    final upa = _selectedSomitiData!['upazillaName'] ?? '';

    String address = '';
    final type = _selectedSomitiData!['somitiType'] as String?;

    if (type == 'zilla') {
      address = '$dist জেলা, $div বিভাগ';
    } else if (type == 'upazilla') {
      String unionPart = '';
      if (_selectedUnion != null) {
        unionPart = '$_selectedUnion, ';
      }
      address = '$unionPart$upa উপজেলা, $dist জেলা, $div বিভাগ';
    }

    _permanentAddressController.text = address;
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
            orElse: () => <String, dynamic>{},
          )
        : <String, dynamic>{};
    final hallName = hallEntry['hallName']?.toString() ?? 'অজানা হল';

    // Department: digits 6-7 → 76
    final deptCodeStr = id.substring(5, 7);
    final deptCode = int.tryParse(deptCodeStr);
    final deptEntry = deptCode != null
        ? _deptList.firstWhere(
            (e) => e['code'] == deptCode,
            orElse: () => <String, dynamic>{},
          )
        : <String, dynamic>{};
    final deptName = deptEntry['name']?.toString() ?? 'অজানা বিভাগ';

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

  void _showSomitiSearchDialog() {
    String searchQuery = '';
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredSomitis = _somitis
                .where(
                  (s) => s['somitiName'].toString().toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
                )
                .toList();

            // স্ক্রিনের পুরো প্রস্থ নেওয়া হচ্ছে (প্যাডিং ছাড়া)
            final double screenWidth = MediaQuery.of(context).size.width;
            final double screenHeight = MediaQuery.of(context).size.height;

            return Dialog(
              insetPadding: const EdgeInsets.all(0), // কোনো প্যাডিং নয়
              backgroundColor: Colors.transparent,
              child: Container(
                width: screenWidth, // Full Width
                height: screenHeight * 0.75, // 75% উচ্চতা (চাইলে 0.9 করতে পারো)
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  children: [
                    // === Title Bar ===
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'সমিতি নির্বাচন করুন',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.blue),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // === Search Field ===
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        onChanged: (value) {
                          setDialogState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'সমিতি খুঁজুন',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // === List of Somitis ===
                    Expanded(
                      child: filteredSomitis.isEmpty
                          ? const Center(
                              child: Text(
                                'কোনো সমিতি পাওয়া যায়নি',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: filteredSomitis.length,
                              itemBuilder: (context, index) {
                                final somiti = filteredSomitis[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      somiti['somitiName'],
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedSomiti = somiti['somitiName'];
                                        _selectedSomitiData = somiti;
                                        _selectedUnion = null;
                                        _unionController.clear();
                                        _autoFillPermanentAddress();
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                );
                              },
                            ),
                    ),

                    // === Cancel Button ===
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'বাতিল',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== Custom Searchable Dropdown for Union ====================
  void _showUnionSearchDialog() {
    if (_selectedSomitiData == null ||
        _selectedSomitiData!['upazillaId'] == null) {
      return;
    }

    final upazilaId = _selectedSomitiData!['upazillaId'].toString();
    String searchQuery = '';

    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredUnions = _fullUnions
                .where((u) => u['upazila_id'].toString() == upazilaId)
                .where(
                  (u) => u['bn_name'].toString().toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
                )
                .toList();

            final double screenWidth = MediaQuery.of(context).size.width;
            final double screenHeight = MediaQuery.of(context).size.height;

            return Dialog(
              insetPadding: const EdgeInsets.all(0),
              backgroundColor: Colors.transparent,
              child: Container(
                width: screenWidth,
                height: screenHeight * 0.75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  children: [
                    // === Title Bar ===
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ইউনিয়ন নির্বাচন করুন',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.blue),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // === Search Field ===
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        onChanged: (value) {
                          setDialogState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'ইউনিয়ন খুঁজুন',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // === List of Unions ===
                    Expanded(
                      child: filteredUnions.isEmpty
                          ? const Center(
                              child: Text(
                                'কোনো ইউনিয়ন পাওয়া যায়নি',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: filteredUnions.length,
                              itemBuilder: (context, index) {
                                final unionData = filteredUnions[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      unionData['bn_name'],
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedUnion = unionData['bn_name'];
                                        _unionController.text = _selectedUnion!;
                                        _autoFillPermanentAddress();
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                );
                              },
                            ),
                    ),

                    // === Cancel Button ===
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'বাতিল',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== UI BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('সদস্য নিবন্ধন'),
        backgroundColor: Colors.blue,
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

                  // Somiti Custom Searchable Field
                  GestureDetector(
                    onTap: _isLoadingSomitis ? null : _showSomitiSearchDialog,
                    child: AbsorbPointer(
                      absorbing: true,
                      child: TextFormField(
                        enabled: false,
                        controller: TextEditingController(
                          text: _selectedSomiti ?? '',
                        ),
                        decoration: InputDecoration(
                          labelText: 'সমিতি নির্বাচন করুন',
                          prefixIcon: const Icon(Icons.groups),
                          suffixIcon: Icon(
                            Icons.arrow_drop_down,
                            color: _isLoadingSomitis
                                ? Colors.grey
                                : Colors.blue,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                        ),
                        validator: (v) => _selectedSomiti == null
                            ? 'সমিতি নির্বাচন করুন।'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Union Custom Searchable Field (only for upazilla somiti)
                  if (_selectedSomitiData != null &&
                      _selectedSomitiData!['somitiType'] == 'upazilla') ...[
                    GestureDetector(
                      onTap: _showUnionSearchDialog,
                      child: AbsorbPointer(
                        absorbing: true,
                        child: TextFormField(
                          enabled: false,
                          controller: _unionController,
                          decoration: InputDecoration(
                            labelText:
                                'ইউনিয়ন নির্বাচন করুন (স্থায়ী ঠিকানার জন্য)',
                            prefixIcon: const Icon(Icons.location_city),
                            suffixIcon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.blue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide(
                                color: Colors.blue.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide(
                                color: Colors.blue.shade300,
                              ),
                            ),
                          ),
                          validator: (v) => _selectedUnion == null
                              ? 'ইউনিয়ন নির্বাচন করুন।'
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // University ID
                  TextFormField(
                    controller: _universityIdController,
                    decoration: InputDecoration(
                      labelText: 'বিশ্ববিদ্যালয় আইডি (যেমন: 2110476128)',
                      prefixIcon: const Icon(Icons.school),
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        borderSide: BorderSide(color: Colors.blue.shade300),
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
                    'অভিভাবকের নাম্বার (জরুরি অবস্থায় )',
                    Icons.security,
                    validator: (v) => v?.isEmpty ?? true
                        ? 'অভিভাবকের নাম্বার (জরুরি অবস্থায় ) প্রয়োজনীয়।'
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
                    decoration: InputDecoration(
                      labelText: 'রক্তের গ্রুপ',
                      prefixIcon: const Icon(Icons.favorite),
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                    items: _bloodGroups
                        .map<DropdownMenuItem<String>>(
                          (String g) => DropdownMenuItem<String>(
                            value: g,
                            child: Text(g),
                          ),
                        )
                        .toList(),
                    onChanged: (String? v) =>
                        setState(() => _selectedBloodGroup = v),
                    validator: (String? v) =>
                        v == null ? 'রক্তের গ্রুপ নির্বাচন করুন।' : null,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.blue.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.blue.shade300),
        ),
      ),
      validator: validator,
    );
  }
}
