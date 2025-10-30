import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'আরইউ ফ্যামিলি',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const SomitiChoicePage(),
    );
  }
}

class SomitiChoicePage extends StatefulWidget {
  const SomitiChoicePage({super.key});

  @override
  State<SomitiChoicePage> createState() => _SomitiChoicePageState();
}

class _SomitiChoicePageState extends State<SomitiChoicePage> {
  String? somitiType;

  List divisions = [];
  List districts = [];
  List upazillas = [];
  List fullDistricts = [];
  List fullUpazillas = [];

  String? selectedDivisionId;
  String? selectedDistrictId;
  String? selectedUpazillaId;

  bool isLoadingDivision = false;
  bool isLoadingDistrict = false;
  bool isLoadingUpazilla = false;
  bool showError = false;
  String? errorMessage;

  late SharedPreferences prefs;

  // Base URL for GitHub raw files
  static const String BASE_URL =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/RUCSEHUB/LocationApiOFBD/';

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    try {
      prefs = await SharedPreferences.getInstance();
      _loadCachedData();
      await _loadLocalData();
      if (divisions.isNotEmpty && selectedDivisionId != null) {
        _filterDistricts();
        if (selectedDistrictId != null) {
          _filterUpazillas();
        }
      }
    } catch (e) {
      _handleError(e, "ডেটা লোড করতে সমস্যা হয়েছে");
    }
  }

  Future<String> _getLocalFilePath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$filename';
  }

  Future<List> _loadFromLocal(String filename) async {
    try {
      final filePath = await _getLocalFilePath(filename);
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as List;
      }
    } catch (e) {
      print('Error loading from local: $e');
    }
    return [];
  }

  Future<void> _saveToLocal(String filename, List data) async {
    try {
      final filePath = await _getLocalFilePath(filename);
      final file = File(filePath);
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Error saving to local: $e');
    }
  }

  Future<List> _fetchJson(String url) async {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw HttpException('API Error: ${response.statusCode}');
    }
  }

  Future<List> _loadOrFetch(String filename, String url) async {
    var data = await _loadFromLocal(filename);
    if (data.isEmpty) {
      setState(() {
        if (filename == 'divisions.json') isLoadingDivision = true;
        if (filename == 'districts.json') isLoadingDistrict = true;
        if (filename == 'upazilas.json') isLoadingUpazilla = true;
      });
      try {
        data = await _fetchJson(url);
        await _saveToLocal(filename, data);
      } catch (e) {
        _handleError(e, "ডেটা লোড করতে সমস্যা হয়েছে: $filename");
      } finally {
        setState(() {
          if (filename == 'divisions.json') isLoadingDivision = false;
          if (filename == 'districts.json') isLoadingDistrict = false;
          if (filename == 'upazilas.json') isLoadingUpazilla = false;
        });
      }
    }
    return data;
  }

  Future<void> _loadLocalData() async {
    setState(() {
      isLoadingDivision = true;
    });
    try {
      divisions = await _loadOrFetch(
        'divisions.json',
        '$BASE_URL/divisions.json',
      );
      fullDistricts = await _loadOrFetch(
        'districts.json',
        '$BASE_URL/districts.json',
      );
      fullUpazillas = await _loadOrFetch(
        'upazilas.json',
        '$BASE_URL/upazilas.json',
      );

      // Auto-select if only one division exists and none selected
      if (divisions.isNotEmpty &&
          selectedDivisionId == null &&
          divisions.length == 1) {
        await _autoSelectDivision(divisions[0]['id'].toString());
      }
    } finally {
      setState(() {
        isLoadingDivision = false;
      });
    }
  }

  void _filterDistricts() {
    if (selectedDivisionId != null && fullDistricts.isNotEmpty) {
      setState(() {
        districts = fullDistricts
            .where((d) => d['division_id'].toString() == selectedDivisionId)
            .toList();
        isLoadingDistrict = false;
      });

      // Auto-select if only one district exists
      if (districts.length == 1 && selectedDistrictId == null) {
        _autoSelectDistrict(districts[0]['id'].toString());
      }
    }
  }

  void _filterUpazillas() {
    if (selectedDistrictId != null && fullUpazillas.isNotEmpty) {
      setState(() {
        upazillas = fullUpazillas
            .where((u) => u['district_id'].toString() == selectedDistrictId)
            .toList();
        isLoadingUpazilla = false;
      });

      // Auto-select if only one upazilla exists
      if (upazillas.length == 1 && selectedUpazillaId == null) {
        _autoSelectUpazilla(upazillas[0]['id'].toString());
      }
    }
  }

  void _loadCachedData() {
    try {
      final cachedDivisionId = prefs.getString('selected_division_id');
      if (cachedDivisionId != null) {
        selectedDivisionId = cachedDivisionId;
      }

      final cachedDistrictId = prefs.getString('selected_district_id');
      if (cachedDistrictId != null) {
        selectedDistrictId = cachedDistrictId;
      }

      selectedUpazillaId = prefs.getString('selected_upazilla_id');

      setState(() {
        somitiType = prefs.getString('somiti_type');
      });
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  Future<void> _saveToPrefs(String key, dynamic value) async {
    try {
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value == null) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error saving to prefs: $e');
    }
  }

  Future<void> _autoSelectDivision(String divisionId) async {
    setState(() {
      selectedDivisionId = divisionId;
    });
    await _saveToPrefs('selected_division_id', divisionId);
    _filterDistricts();
  }

  Future<void> _autoSelectDistrict(String districtId) async {
    setState(() {
      selectedDistrictId = districtId;
    });
    await _saveToPrefs('selected_district_id', districtId);

    if (somitiType == "upazilla") {
      _filterUpazillas();
    }
  }

  Future<void> _autoSelectUpazilla(String upazillaId) async {
    setState(() {
      selectedUpazillaId = upazillaId;
    });
    await _saveToPrefs('selected_upazilla_id', upazillaId);
  }

  void _handleError(dynamic error, String defaultMessage) {
    String errorMessage = defaultMessage;

    if (error is http.ClientException) {
      errorMessage = "নেটওয়ার্ক সংযোগ সমস্যা। ইন্টারনেট চেক করুন।";
    } else if (error is HttpException) {
      errorMessage = "সার্ভার থেকে ডেটা লোড করতে সমস্যা: ${error.message}";
    } else if (error is TimeoutException) {
      errorMessage = "রিকোয়েস্ট টাইমআউট হয়েছে। আবার চেষ্টা করুন।";
    } else if (error is FormatException) {
      errorMessage = "ডেটা ফরমেট সমস্যা।";
    } else {
      errorMessage = "ত্রুটি: ${error.toString()}";
    }

    setState(() {
      this.errorMessage = errorMessage;
      showError = true;
    });

    _showErrorSnackBar(errorMessage);
  }

  Widget _buildModernDropdownWithLabel({
    required String label,
    required String hint,
    required List items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : DropdownButton<String>(
                        isExpanded: true,
                        value: selectedValue,
                        hint: Text(hint),
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(12),
                        items: items.map<DropdownMenuItem<String>>((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'].toString(),
                            child: Text(
                              item['bn_name'] ?? item['name'] ?? 'অজানা',
                            ),
                          );
                        }).toList(),
                        onChanged: onChanged,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? getNameById(List list, String? id) {
    if (id == null) return null;
    try {
      var item = list.firstWhere((e) => e['id'].toString() == id);
      return item['bn_name'] ?? item['name'] ?? 'অজানা';
    } catch (e) {
      return null;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearData() async {
    try {
      await prefs.clear();

      // Delete local files
      final files = ['divisions.json', 'districts.json', 'upazilas.json'];
      for (String file in files) {
        final filePath = await _getLocalFilePath(file);
        final localFile = File(filePath);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      }

      setState(() {
        divisions = [];
        fullDistricts = [];
        fullUpazillas = [];
        districts = [];
        upazillas = [];
        selectedDivisionId = null;
        selectedDistrictId = null;
        selectedUpazillaId = null;
        somitiType = null;
        errorMessage = null;
        showError = false;
      });

      await _loadLocalData();
      _showSuccessSnackBar('ডেটা রিসেট করা হয়েছে');
    } catch (e) {
      _handleError(e, "ডেটা রিসেট করতে সমস্যা হয়েছে");
    }
  }

  void _navigateToDetailsForm() {
    try {
      final divisionName = getNameById(divisions, selectedDivisionId);
      final districtName = getNameById(districts, selectedDistrictId);
      String? upazillaName;

      if (somitiType == "upazilla") {
        upazillaName = getNameById(upazillas, selectedUpazillaId);
      }

      if (divisionName == null || districtName == null) {
        throw Exception("স্থানীয় নাম পাওয়া যায়নি");
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SomitiDetailsForm(
            somitiType: somitiType!,
            divisionId: selectedDivisionId!,
            divisionName: divisionName,
            districtId: selectedDistrictId!,
            districtName: districtName,
            upazillaId: selectedUpazillaId,
            upazillaName: upazillaName,
          ),
        ),
      );
    } catch (e) {
      _handleError(e, "ফর্ম খুলতে সমস্যা হয়েছে");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RU Connect+"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearData,
            tooltip: 'ডেটা রিফ্রেশ করুন',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
            const Text(
              "আপনি কোন সমিতি খুলতে চান?",
              style: TextStyle(
                fontFamily:
                    'CustomBangla2', // ✅ শুধু এখানে CustomBangla2 ব্যবহার
                fontSize: 35,
                // fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("জেলা সমিতি"),
                  selected: somitiType == "zilla",
                  onSelected: (selected) {
                    setState(() {
                      somitiType = selected ? "zilla" : null;
                      _saveToPrefs('somiti_type', somitiType);
                      if (somitiType == "zilla") {
                        upazillas = [];
                        selectedUpazillaId = null;
                        _saveToPrefs('selected_upazilla_id', null);
                      }
                    });
                  },
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: somitiType == "zilla" ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text("উপজেলা সমিতি"),
                  selected: somitiType == "upazilla",
                  onSelected: (selected) {
                    setState(() {
                      somitiType = selected ? "upazilla" : null;
                      _saveToPrefs('somiti_type', somitiType);
                      if (somitiType == "upazilla" &&
                          selectedDistrictId != null &&
                          upazillas.isEmpty) {
                        _filterUpazillas();
                      }
                    });
                  },
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: somitiType == "upazilla"
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            _buildModernDropdownWithLabel(
              label: "বিভাগ:",
              hint: "বিভাগ নির্বাচন করুন",
              items: divisions,
              selectedValue: selectedDivisionId,
              isLoading: isLoadingDivision,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedDivisionId = value;
                    selectedDistrictId = null;
                    selectedUpazillaId = null;
                    districts = [];
                    upazillas = [];
                  });
                  _saveToPrefs('selected_division_id', value);
                  _saveToPrefs('selected_district_id', null);
                  _saveToPrefs('selected_upazilla_id', null);
                  _filterDistricts();
                }
              },
            ),

            if (selectedDivisionId != null)
              _buildModernDropdownWithLabel(
                label: "জেলা:",
                hint: "জেলা নির্বাচন করুন",
                items: districts,
                selectedValue: selectedDistrictId,
                isLoading: isLoadingDistrict,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedDistrictId = value;
                      selectedUpazillaId = null;
                      upazillas = [];
                    });
                    _saveToPrefs('selected_district_id', value);
                    _saveToPrefs('selected_upazilla_id', null);
                    if (somitiType == "upazilla") {
                      _filterUpazillas();
                    }
                  }
                },
              ),

            if (somitiType == "upazilla" && selectedDistrictId != null)
              _buildModernDropdownWithLabel(
                label: "উপজেলা:",
                hint: "উপজেলা নির্বাচন করুন",
                items: upazillas,
                selectedValue: selectedUpazillaId,
                isLoading: isLoadingUpazilla,
                onChanged: (value) {
                  setState(() {
                    selectedUpazillaId = value;
                  });
                  _saveToPrefs('selected_upazilla_id', value);
                },
              ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (somitiType == "zilla" &&
                            selectedDivisionId != null &&
                            selectedDistrictId != null) ||
                        (somitiType == "upazilla" &&
                            selectedDivisionId != null &&
                            selectedDistrictId != null &&
                            selectedUpazillaId != null)
                    ? _navigateToDetailsForm
                    : null,
                child: const Text(
                  "নিশ্চিত করুন",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            if (showError)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loadLocalData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      "আবার চেষ্টা করুন",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// The rest of the code (SomitiDetailsForm, Dashboard, HttpException) remains the same as before, but with updates for blue theme.
class SomitiDetailsForm extends StatefulWidget {
  final String somitiType;
  final String divisionId;
  final String divisionName;
  final String districtId;
  final String districtName;
  final String? upazillaId;
  final String? upazillaName;

  const SomitiDetailsForm({
    super.key,
    required this.somitiType,
    required this.divisionId,
    required this.divisionName,
    required this.districtId,
    required this.districtName,
    this.upazillaId,
    this.upazillaName,
  });

  @override
  State<SomitiDetailsForm> createState() => _SomitiDetailsFormState();
}

class _SomitiDetailsFormState extends State<SomitiDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _somitiNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showVerification = false;
  bool _isVerifying = false;

  Timer? _verificationTimer;
  int _retryCount = 0;
  final int _maxRetries = 40; // ~2 minutes max

  @override
  void initState() {
    super.initState();
    _generateAutoName();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _somitiNameController.dispose();
    super.dispose();
  }

  void _generateAutoName() {
    try {
      String autoName;
      if (widget.somitiType == "zilla") {
        autoName = "${widget.districtName} জেলা সমিতি";
      } else {
        autoName = "${widget.upazillaName ?? widget.districtName} উপজেলা সমিতি";
      }
      _somitiNameController.text = autoName;
    } catch (e) {
      _somitiNameController.text = "নতুন সমিতি";
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'পাসওয়ার্ড এবং কনফার্ম পাসওয়ার্ড মিলছে না।';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
          .catchError((error) {
            throw FirebaseAuthException(
              code: error.code ?? 'unknown-error',
              message: error.message ?? 'An unknown error occurred',
            );
          });

      await userCredential.user!.sendEmailVerification();
      await _saveSomitiToFirestore(userCredential.user!.uid);

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
    } catch (e) {
      _handleError(e, "সমিতি তৈরি করতে সমস্যা হয়েছে");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSomitiToFirestore(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('somitis').add({
        'userId': userId,
        'email': _emailController.text.trim(),
        'somitiName': _somitiNameController.text.trim(),
        'somitiType': widget.somitiType,
        'divisionId': widget.divisionId,
        'divisionName': widget.divisionName,
        'districtId': widget.districtId,
        'districtName': widget.districtName,
        if (widget.upazillaId != null) 'upazillaId': widget.upazillaId,
        if (widget.upazillaName != null) 'upazillaName': widget.upazillaName,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });
    } catch (e) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (deleteError) {
        print('Error deleting user: $deleteError');
      }
      rethrow;
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
              MaterialPageRoute(builder: (_) => const Dashboard()),
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
          MaterialPageRoute(builder: (_) => const Dashboard()),
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

  Future<void> _resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _showSnackBar(
          'যাচাইকরণ ইমেইল পাঠানো হয়েছে!',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      _handleError(e, "যাচাইকরণ ইমেইল পাঠাতে সমস্যা হয়েছে");
    }
  }

  void _handleError(dynamic error, String defaultMessage) {
    String errorMessage = defaultMessage;

    if (error is FirebaseAuthException) {
      errorMessage = _getAuthErrorMessage(error.code);
    } else if (error is FirebaseException) {
      errorMessage = "ফায়ারবেজ ত্রুটি: ${error.message ?? error.code}";
    } else if (error is String) {
      errorMessage = error;
    } else if (error.toString().contains('JavaScriptObject')) {
      errorMessage = "নেটওয়ার্ক সংযোগ সমস্যা। দয়া করে আবার চেষ্টা করুন।";
    } else {
      errorMessage = "ত্রুটি: ${error.toString()}";
    }

    setState(() {
      _errorMessage = errorMessage;
    });

    _showSnackBar(errorMessage, backgroundColor: Colors.red);
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'এই ইমেইল ইতিমধ্যে ব্যবহৃত হয়েছে।';
      case 'weak-password':
        return 'পাসওয়ার্ড খুব দুর্বল। কমপক্ষে ৬ অক্ষর ব্যবহার করুন।';
      case 'invalid-email':
        return 'অবৈধ ইমেইল ঠিকানা।';
      case 'network-request-failed':
        return 'নেটওয়ার্ক সংযোগ সমস্যা। দয়া করে ইন্টারনেট সংযোগ চেক করুন।';
      case 'too-many-requests':
        return 'অনেকগুলি অনুরোধ করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।';
      case 'operation-not-allowed':
        return 'এই অপারেশনটি অনুমোদিত নয়।';
      default:
        return 'অথেনটিকেশন ত্রুটি: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.somitiType == "zilla" ? "জেলা" : "উপজেলা"} সমিতি বিস্তারিত',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_showVerification) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'বিভাগ: ${widget.divisionName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'জেলা: ${widget.districtName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.upazillaName != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'উপজেলা: ${widget.upazillaName}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _somitiNameController,
                    decoration: InputDecoration(
                      labelText: 'সমিতির নাম',
                      prefixIcon: const Icon(Icons.group),
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'সমিতির নাম প্রয়োজনীয়।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'ইমেইল',
                      prefixIcon: const Icon(Icons.email),
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

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'পাসওয়ার্ড',
                      prefixIcon: const Icon(Icons.lock),
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

                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'পাসওয়ার্ড নিশ্চিত করুন',
                      prefixIcon: const Icon(Icons.lock_outline),
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
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'পাসওয়ার্ড নিশ্চিত করুন।';
                      }
                      if (value != _passwordController.text) {
                        return 'পাসওয়ার্ড মিলছে না।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
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
                              'সমিতি তৈরি করুন',
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
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ড্যাশবোর্ড'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, size: 100, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'ইমেইল যাচাই সফল!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'স্বাগতম, ${user?.email ?? 'ব্যবহারকারী'}!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Add logout or other actions here
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SomitiChoicePage(),
                  ),
                );
              },
              child: const Text('লগ আউট'),
            ),
          ],
        ),
      ),
    );
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}
