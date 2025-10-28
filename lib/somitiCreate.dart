import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'আরইউ ফ্যামিলি',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
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

  String? selectedDivisionId;
  String? selectedDistrictId;
  String? selectedUpazillaId;

  bool isLoadingDivision = false;
  bool isLoadingDistrict = false;
  bool isLoadingUpazilla = false;
  bool showError = false;
  String? errorMessage;

  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    try {
      prefs = await SharedPreferences.getInstance();
      _loadCachedData();
      await fetchDivisions();
    } catch (e) {
      _handleError(e, "ডেটা লোড করতে সমস্যা হয়েছে");
    }
  }

  void _loadCachedData() {
    try {
      final divisionsJson = prefs.getString('divisions_data');
      if (divisionsJson != null) {
        setState(() {
          divisions = jsonDecode(divisionsJson);
        });
      }

      final cachedDivisionId = prefs.getString('selected_division_id');
      if (cachedDivisionId != null) {
        selectedDivisionId = cachedDivisionId;

        final districtsJson = prefs.getString(
          'districts_data_$cachedDivisionId',
        );
        if (districtsJson != null) {
          setState(() {
            districts = jsonDecode(districtsJson);
          });
        }

        final cachedDistrictId = prefs.getString('selected_district_id');
        if (cachedDistrictId != null) {
          selectedDistrictId = cachedDistrictId;

          final upazillasJson = prefs.getString(
            'upazillas_data_$cachedDistrictId',
          );
          if (upazillasJson != null) {
            setState(() {
              upazillas = jsonDecode(upazillasJson);
            });
          }

          selectedUpazillaId = prefs.getString('selected_upazilla_id');
        }
      }

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
      } else if (value is List) {
        await prefs.setString(key, jsonEncode(value));
      } else if (value == null) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error saving to prefs: $e');
    }
  }

  Future<void> fetchDivisions() async {
    setState(() {
      isLoadingDivision = true;
      showError = false;
      errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('https://bdapi.vercel.app/api/v.1/division'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final divisionsData = data['data'] is List ? data['data'] : [];

        await _saveToPrefs('divisions_data', divisionsData);

        setState(() {
          divisions = divisionsData;
        });

        // Auto-select if only one division exists
        if (divisions.length == 1) {
          await _autoSelectDivision(divisions[0]['id'].toString());
        }
      } else {
        throw HttpException('API Error: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e, "বিভাগ লোড করতে সমস্যা হয়েছে");
    } finally {
      setState(() {
        isLoadingDivision = false;
      });
    }
  }

  Future<void> _autoSelectDivision(String divisionId) async {
    setState(() {
      selectedDivisionId = divisionId;
    });
    await _saveToPrefs('selected_division_id', divisionId);
    await fetchDistricts(divisionId);
  }

  Future<void> fetchDistricts(String divisionId) async {
    setState(() {
      isLoadingDistrict = true;
      districts = [];
      selectedDistrictId = null;
      upazillas = [];
      selectedUpazillaId = null;
      showError = false;
      errorMessage = null;
    });

    await _saveToPrefs('selected_division_id', divisionId);
    await _saveToPrefs('selected_district_id', null);
    await _saveToPrefs('selected_upazilla_id', null);

    try {
      final response = await http
          .get(
            Uri.parse('https://bdapi.vercel.app/api/v.1/district/$divisionId'),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final districtsData = data['data'] is List ? data['data'] : [];

        await _saveToPrefs('districts_data_$divisionId', districtsData);

        setState(() {
          districts = districtsData;
        });

        // Auto-select if only one district exists
        if (districts.length == 1) {
          await _autoSelectDistrict(districts[0]['id'].toString());
        }
      } else {
        throw HttpException('API Error: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e, "জেলা লোড করতে সমস্যা হয়েছে");
    } finally {
      setState(() {
        isLoadingDistrict = false;
      });
    }
  }

  Future<void> _autoSelectDistrict(String districtId) async {
    setState(() {
      selectedDistrictId = districtId;
    });
    await _saveToPrefs('selected_district_id', districtId);

    if (somitiType == "upazilla") {
      await fetchUpazillas(districtId);
    }
  }

  Future<void> fetchUpazillas(String districtId) async {
    setState(() {
      isLoadingUpazilla = true;
      upazillas = [];
      selectedUpazillaId = null;
      showError = false;
      errorMessage = null;
    });

    await _saveToPrefs('selected_district_id', districtId);
    await _saveToPrefs('selected_upazilla_id', null);

    try {
      final response = await http
          .get(
            Uri.parse('https://bdapi.vercel.app/api/v.1/upazilla/$districtId'),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final upazillasData = data['data'] is List ? data['data'] : [];

        await _saveToPrefs('upazillas_data_$districtId', upazillasData);

        setState(() {
          upazillas = upazillasData;
        });

        // Auto-select if only one upazilla exists
        if (upazillas.length == 1) {
          await _autoSelectUpazilla(upazillas[0]['id'].toString());
        }
      } else {
        throw HttpException('API Error: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e, "উপজেলা লোড করতে সমস্যা হয়েছে");
    } finally {
      setState(() {
        isLoadingUpazilla = false;
      });
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
                border: Border.all(color: Colors.grey.shade300),
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
                            child: Text(item['name'] ?? 'অজানা'),
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
      return item['name'] ?? 'অজানা';
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
      setState(() {
        divisions = [];
        districts = [];
        upazillas = [];
        selectedDivisionId = null;
        selectedDistrictId = null;
        selectedUpazillaId = null;
        somitiType = null;
        errorMessage = null;
        showError = false;
      });
      await fetchDivisions();
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
        title: const Text("আরইউ ফ্যামিলি"),
        backgroundColor: Colors.green,
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
            const Text(
              "আপনি কোন সমিতি খুলতে চান?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  selectedColor: Colors.green,
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
                        fetchUpazillas(selectedDistrictId!);
                      }
                    });
                  },
                  selectedColor: Colors.green,
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
                  fetchDistricts(value);
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
                    if (somitiType == "upazilla") {
                      fetchUpazillas(value);
                    } else {
                      setState(() {
                        selectedDistrictId = value;
                      });
                      _saveToPrefs('selected_district_id', value);
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
                    onPressed: fetchDivisions,
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
  bool _isEmailVerified = false;

  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _generateAutoName();
    _checkEmailVerification();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      if (user != null && user.emailVerified && !_isEmailVerified) {
        setState(() {
          _isEmailVerified = true;
        });
        _showVerificationSuccess();
      }
    });
  }

  void _showVerificationSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ইমেইল যাচাই সফল! ড্যাশবোর্ডে রিডাইরেক্ট হচ্ছে...'),
        backgroundColor: Colors.green,
      ),
    );

    // Delay to show the message, then navigate
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    });
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

  Future<void> _checkEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        setState(() {
          _isEmailVerified = user.emailVerified;
        });
        if (user.emailVerified) {
          _showVerificationSuccess();
        }
      }
    } catch (e) {
      _handleError(e, "ইমেইল যাচাইকরণ চেক করতে সমস্যা হয়েছে");
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _somitiNameController.dispose();
    super.dispose();
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

      setState(() {
        _isEmailVerified = false;
      });

      _showSuccessSnackbar();
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

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'সমিতি সফলভাবে তৈরি করা হয়েছে! দয়া করে আপনার ইমেইল যাচাই করুন।',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'যাচাই করুন',
          textColor: Colors.white,
          onPressed: () async {
            await _checkEmailVerification();
          },
        ),
      ),
    );
    // Do not pop immediately; let the user stay to check verification
  }

  Future<void> _resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('যাচাইকরণ ইমেইল পাঠানো হয়েছে!'),
            backgroundColor: Colors.green,
          ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
        backgroundColor: Colors.green,
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
                  decoration: const InputDecoration(
                    labelText: 'সমিতির নাম',
                    prefixIcon: Icon(Icons.group),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
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

                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'পাসওয়ার্ড নিশ্চিত করুন',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
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
                      backgroundColor: Colors.green,
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
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),

                if (FirebaseAuth.instance.currentUser != null &&
                    !_isEmailVerified) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'ইমেইল যাচাই করুন',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _resendVerificationEmail,
                    icon: const Icon(Icons.email),
                    label: const Text('যাচাইকরণ ইমেইল পাঠান'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _checkEmailVerification,
                    child: const Text('যাচাই স্থিতি চেক করুন'),
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
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, size: 100, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'ইমেইল যাচাই সফল!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
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
