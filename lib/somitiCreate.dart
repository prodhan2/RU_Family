import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ru_family/SomitiDetailsForm.dart';
import 'package:ru_family/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

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

  // SharedPreferences instance
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    _loadCachedData();
    fetchDivisions();
  }

  // Load cached data from SharedPreferences
  void _loadCachedData() {
    try {
      final divisionsJson = prefs.getString('divisions_data');
      if (divisionsJson != null) {
        setState(() {
          divisions = jsonDecode(divisionsJson);
        });
      }

      final districtsJson = prefs.getString(
        'districts_data_$selectedDivisionId',
      );
      if (districtsJson != null) {
        setState(() {
          districts = jsonDecode(districtsJson);
        });
      }

      final upazillasJson = prefs.getString(
        'upazillas_data_$selectedDistrictId',
      );
      if (upazillasJson != null) {
        setState(() {
          upazillas = jsonDecode(upazillasJson);
        });
      }

      setState(() {
        somitiType = prefs.getString('somiti_type');
        selectedDivisionId = prefs.getString('selected_division_id');
        selectedDistrictId = prefs.getString('selected_district_id');
        selectedUpazillaId = prefs.getString('selected_upazilla_id');
      });
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  // Save data to SharedPreferences
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
    });

    try {
      final response = await http
          .get(Uri.parse('https://bdapi.vercel.app/api/v.1/division'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final divisionsData = data['data'] is List ? data['data'] : [];

        // Store in SharedPreferences
        await _saveToPrefs('divisions_data', divisionsData);

        setState(() {
          divisions = divisionsData;
        });
      } else {
        setState(() {
          showError = divisions.isEmpty;
        });
      }
    } catch (e) {
      setState(() {
        showError = divisions.isEmpty;
      });
    } finally {
      setState(() {
        isLoadingDivision = false;
      });
    }
  }

  Future<void> fetchDistricts(String divisionId) async {
    setState(() {
      isLoadingDistrict = true;
      districts = [];
      selectedDistrictId = null;
      upazillas = [];
      selectedUpazillaId = null;
      showError = false;
    });

    // Save selection
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

        // Store in SharedPreferences
        await _saveToPrefs('districts_data_$divisionId', districtsData);

        setState(() {
          districts = districtsData;
        });
      } else {
        setState(() {
          showError = districts.isEmpty;
        });
      }
    } catch (e) {
      setState(() {
        showError = districts.isEmpty;
      });
    } finally {
      setState(() {
        isLoadingDistrict = false;
      });
    }
  }

  Future<void> fetchUpazillas(String districtId) async {
    setState(() {
      isLoadingUpazilla = true;
      upazillas = [];
      selectedUpazillaId = null;
      showError = false;
    });

    // Save selection
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

        // Store in SharedPreferences
        await _saveToPrefs('upazillas_data_$districtId', upazillasData);

        setState(() {
          upazillas = upazillasData;
        });
      } else {
        setState(() {
          showError = upazillas.isEmpty;
        });
      }
    } catch (e) {
      setState(() {
        showError = upazillas.isEmpty;
      });
    } finally {
      setState(() {
        isLoadingUpazilla = false;
      });
    }
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
                        child: Center(child: CircularProgressIndicator()),
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // Clear all saved data
  Future<void> _clearData() async {
    await prefs.clear();
    setState(() {
      divisions = [];
      districts = [];
      upazillas = [];
      selectedDivisionId = null;
      selectedDistrictId = null;
      selectedUpazillaId = null;
      somitiType = null;
    });
    fetchDivisions();
    _showSuccessSnackBar('ডেটা রিসেট করা হয়েছে');
  }

  // Navigate to the details form page
  void _navigateToDetailsForm() {
    final divisionName = getNameById(divisions, selectedDivisionId);
    final districtName = getNameById(districts, selectedDistrictId);
    String? upazillaName;

    if (somitiType == "upazilla") {
      upazillaName = getNameById(upazillas, selectedUpazillaId);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SomitiDetailsForm(
          somitiType: somitiType!,
          divisionId: selectedDivisionId!,
          divisionName: divisionName!,
          districtId: selectedDistrictId!,
          districtName: districtName!,
          upazillaId: selectedUpazillaId,
          upazillaName: upazillaName,
        ),
      ),
    );
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

            if (showError && divisions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'ইন্টারনেট সংযোগ সমস্যা। পূর্বের ডেটা দেখানো হচ্ছে।',
                  style: TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
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
                  });
                  _saveToPrefs('selected_division_id', value);
                  _saveToPrefs('selected_district_id', null);
                  _saveToPrefs('selected_upazilla_id', null);
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
                    setState(() {
                      selectedDistrictId = value;
                      selectedUpazillaId = null;
                    });
                    _saveToPrefs('selected_district_id', value);
                    _saveToPrefs('selected_upazilla_id', null);
                    if (somitiType == "upazilla") {
                      fetchUpazillas(value);
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
