// lib/MakeSomiti/SomitiChoicePage.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:RUConnect_plus/MakeSomiti/somitiDetailsform.dart';

class SomitiChoicePage extends StatefulWidget {
  const SomitiChoicePage({super.key});

  @override
  State<SomitiChoicePage> createState() => _SomitiChoicePageState();
}

class _SomitiChoicePageState extends State<SomitiChoicePage> {
  // --------------------------------------------------------------
  //  UI STATE
  // --------------------------------------------------------------
  String? _somitiType; // "zilla" | "upazilla"
  bool _showError = false;
  String? _errorMessage;

  // --------------------------------------------------------------
  //  LOCATION DATA
  // --------------------------------------------------------------
  List<Map<String, dynamic>> _divisions = [];
  List<Map<String, dynamic>> _fullDistricts = [];
  List<Map<String, dynamic>> _fullUpazilas = [];

  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _upazilas = [];

  String? _selDivId;
  String? _selDistId;
  String? _selUpazilaId;

  // --------------------------------------------------------------
  //  LOADING FLAGS
  // --------------------------------------------------------------
  bool _loadingDiv = false;
  bool _loadingDist = false;
  bool _loadingUpa = false;

  // --------------------------------------------------------------
  //  PERSISTENCE
  // --------------------------------------------------------------
  late SharedPreferences _prefs;
  static const _baseUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/RUCSEHUB/LocationApiOFBD/';

  // --------------------------------------------------------------
  //  INIT
  // --------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPersistedSelection();
    await _loadAllJson(); // cache‑first
    if (_selDivId != null) _filterDistricts();
    if (_selDistId != null && _somitiType == 'upazilla') _filterUpazilas();
  }

  // --------------------------------------------------------------
  //  PERSISTENCE – read
  // --------------------------------------------------------------
  Future<void> _loadPersistedSelection() async {
    _somitiType = _prefs.getString('somiti_type');
    _selDivId = _prefs.getString('sel_div_id');
    _selDistId = _prefs.getString('sel_dist_id');
    _selUpazilaId = _prefs.getString('sel_upa_id');
    setState(() {});
  }

  // --------------------------------------------------------------
  //  PERSISTENCE – write
  // --------------------------------------------------------------
  Future<void> _save(String key, String? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }

  // --------------------------------------------------------------
  //  LOCAL FILE HELPERS
  // --------------------------------------------------------------
  Future<String> _localPath(String file) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$file';
  }

  Future<List<Map<String, dynamic>>> _readLocal(String file) async {
    try {
      final path = await _localPath(file);
      final f = File(path);
      if (await f.exists()) {
        final json = await f.readAsString();
        final list = jsonDecode(json) as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Read local $file error: $e');
    }
    return [];
  }

  Future<void> _writeLocal(String file, List data) async {
    try {
      final path = await _localPath(file);
      final f = File(path);
      await f.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Write local $file error: $e');
    }
  }

  // --------------------------------------------------------------
  //  FETCH FROM NETWORK (only when missing)
  // --------------------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetch(String file, String url) async {
    final resp = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
    final list = jsonDecode(resp.body) as List;
    await _writeLocal(file, list);
    return list.cast<Map<String, dynamic>>();
  }

  // --------------------------------------------------------------
  //  LOAD ALL JSON (cache → network)
  // --------------------------------------------------------------
  Future<void> _loadAllJson() async {
    setState(() => _loadingDiv = true);
    try {
      // 1. Divisions
      _divisions = await _readLocal('divisions.json');
      if (_divisions.isEmpty) {
        _divisions = await _fetch('divisions.json', '$_baseUrl/divisions.json');
      }

      // 2. Districts
      _fullDistricts = await _readLocal('districts.json');
      if (_fullDistricts.isEmpty) {
        _fullDistricts = await _fetch(
          'districts.json',
          '$_baseUrl/districts.json',
        );
      }

      // 3. Upazilas
      _fullUpazilas = await _readLocal('upazilas.json');
      if (_fullUpazilas.isEmpty) {
        _fullUpazilas = await _fetch(
          'upazilas.json',
          '$_baseUrl/upazilas.json',
        );
      }
    } catch (e) {
      _handleError(e, 'ডেটা লোড করতে সমস্যা');
    } finally {
      setState(() => _loadingDiv = false);
    }
  }

  // --------------------------------------------------------------
  //  CASCADING FILTERS
  // --------------------------------------------------------------
  void _filterDistricts() {
    if (_selDivId == null) {
      _districts = [];
      return;
    }
    setState(() {
      _loadingDist = true;
      _districts = _fullDistricts
          .where((d) => d['division_id'].toString() == _selDivId)
          .toList();
      _loadingDist = false;
    });
    // auto‑select if only one
    if (_districts.length == 1 && _selDistId == null) {
      _selectDistrict(_districts[0]['id'].toString());
    }
  }

  void _filterUpazilas() {
    if (_selDistId == null) {
      _upazilas = [];
      return;
    }
    setState(() {
      _loadingUpa = true;
      _upazilas = _fullUpazilas
          .where((u) => u['district_id'].toString() == _selDistId)
          .toList();
      _loadingUpa = false;
    });
    if (_upazilas.length == 1 && _selUpazilaId == null) {
      _selectUpazila(_upazilas[0]['id'].toString());
    }
  }

  // --------------------------------------------------------------
  //  SELECTION HANDLERS (persist + cascade)
  // --------------------------------------------------------------
  Future<void> _selectDivision(String? id) async {
    if (id == _selDivId) return;
    _selDivId = id;
    _selDistId = null;
    _selUpazilaId = null;
    await _save('sel_div_id', id);
    await _save('sel_dist_id', null);
    await _save('sel_upa_id', null);
    _filterDistricts();
    setState(() {});
  }

  Future<void> _selectDistrict(String? id) async {
    if (id == _selDistId) return;
    _selDistId = id;
    _selUpazilaId = null;
    await _save('sel_dist_id', id);
    await _save('sel_upa_id', null);
    if (_somitiType == 'upazilla') _filterUpazilas();
    setState(() {});
  }

  Future<void> _selectUpazila(String? id) async {
    if (id == _selUpazilaId) return;
    _selUpazilaId = id;
    await _save('sel_upa_id', id);
    setState(() {});
  }

  // --------------------------------------------------------------
  //  SOMITI TYPE
  // --------------------------------------------------------------
  Future<void> _setSomitiType(String? type) async {
    _somitiType = type;
    await _save('somiti_type', type);
    if (type == 'zilla') {
      _selUpazilaId = null;
      _upazilas = [];
      await _save('sel_upa_id', null);
    } else if (type == 'upazilla' && _selDistId != null && _upazilas.isEmpty) {
      _filterUpazilas();
    }
    setState(() {});
  }

  // --------------------------------------------------------------
  //  NAVIGATION
  // --------------------------------------------------------------
  void _goToDetails() {
    final divName = _nameFrom(_divisions, _selDivId);
    final distName = _nameFrom(_districts, _selDistId);
    final upaName = _somitiType == 'upazilla'
        ? _nameFrom(_upazilas, _selUpazilaId)
        : null;

    if (divName == null || distName == null) {
      _handleError(Exception('নাম পাওয়া যায়নি'), 'স্থান নির্বাচন করুন');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SomitiDetailsForm(
          somitiType: _somitiType!,
          divisionId: _selDivId!,
          divisionName: divName,
          districtId: _selDistId!,
          districtName: distName,
          upazillaId: _selUpazilaId,
          upazillaName: upaName,
        ),
      ),
    );
  }

  String? _nameFrom(List<Map<String, dynamic>> list, String? id) {
    if (id == null) return null;
    try {
      return list.firstWhere((e) => e['id'].toString() == id)['bn_name'] ??
          'অজানা';
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------
  //  ERROR HANDLING
  // --------------------------------------------------------------
  void _handleError(dynamic e, String fallback) {
    String msg = fallback;
    if (e is TimeoutException)
      msg = 'টাইমআউট – আবার চেষ্টা করুন';
    else if (e is HttpException)
      msg = 'সার্ভার ত্রুটি';
    else if (e is SocketException)
      msg = 'ইন্টারনেট সংযোগ নেই';

    setState(() {
      _showError = true;
      _errorMessage = msg;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // --------------------------------------------------------------
  //  REFRESH / CLEAR
  // --------------------------------------------------------------
  Future<void> _refreshAll() async {
    await _prefs.clear();
    final files = ['divisions.json', 'districts.json', 'upazilas.json'];
    for (final f in files) {
      final path = await _localPath(f);
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    setState(() {
      _divisions = _fullDistricts = _fullUpazilas = [];
      _districts = _upazilas = [];
      _selDivId = _selDistId = _selUpazilaId = null;
      _somitiType = null;
      _showError = false;
      _errorMessage = null;
    });
    await _loadAllJson();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ডেটা রিফ্রেশ হয়েছে'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // --------------------------------------------------------------
  //  UI HELPERS
  // --------------------------------------------------------------
  bool get _canProceed {
    if (_somitiType == 'zilla') {
      return _selDivId != null && _selDistId != null;
    }
    return _selDivId != null && _selDistId != null && _selUpazilaId != null;
  }

  // --------------------------------------------------------------
  //  BUILD
  // --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWeb = width > 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RU Connect+'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'রিফ্রেশ',
          ),
        ],
      ),
      body: isWeb ? _webLayout() : _mobileLayout(),
    );
  }

  // ──────────────────────  WEB LAYOUT  ──────────────────────
  Widget _webLayout() => Row(
    children: [
      // Logo
      Expanded(
        flex: 2,
        child: Container(
          color: Colors.blue.shade50,
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
        ),
      ),
      // Form
      Expanded(
        flex: 3,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: _formContent(isWeb: true),
        ),
      ),
    ],
  );

  // ──────────────────────  MOBILE LAYOUT  ──────────────────────
  Widget _mobileLayout() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'কোন সমিতি খুলবেন?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _formContent(isWeb: false),
      ],
    ),
  );

  // ──────────────────────  COMMON FORM  ──────────────────────
  Widget _formContent({required bool isWeb}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Somiti Type ----
        Wrap(
          spacing: isWeb ? 16 : 8,
          children: [
            ChoiceChip(
              label: Text(isWeb ? 'জেলা সমিতি' : 'জেলা'),
              selected: _somitiType == 'zilla',
              onSelected: (s) => _setSomitiType(s ? 'zilla' : null),
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: _somitiType == 'zilla' ? Colors.white : Colors.black,
                fontSize: isWeb ? 16 : 13,
              ),
            ),
            ChoiceChip(
              label: Text(isWeb ? 'উপজেলা সমিতি' : 'উপজেলা'),
              selected: _somitiType == 'upazilla',
              onSelected: (s) => _setSomitiType(s ? 'upazilla' : null),
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: _somitiType == 'upazilla' ? Colors.white : Colors.black,
                fontSize: isWeb ? 16 : 13,
              ),
            ),
          ],
        ),
        SizedBox(height: isWeb ? 24 : 16),

        // ---- Error Box ----
        if (_showError)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: isWeb ? 16 : 12),
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
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

        // ---- Division ----
        _drop(
          label: 'বিভাগ',
          hint: 'নির্বাচন করুন',
          items: _divisions,
          value: _selDivId,
          loading: _loadingDiv,
          onChanged: _selectDivision,
          isWeb: isWeb,
        ),
        const SizedBox(height: 12),

        // ---- District (if division selected) ----
        if (_selDivId != null)
          _drop(
            label: 'জেলা',
            hint: 'নির্বাচন করুন',
            items: _districts,
            value: _selDistId,
            loading: _loadingDist,
            onChanged: _selectDistrict,
            isWeb: isWeb,
          ),

        // ---- Upazila (only for upazilla) ----
        if (_somitiType == 'upazilla' && _selDistId != null) ...[
          const SizedBox(height: 12),
          _drop(
            label: 'উপজেলা',
            hint: 'নির্বাচন করুন',
            items: _upazilas,
            value: _selUpazilaId,
            loading: _loadingUpa,
            onChanged: _selectUpazila,
            isWeb: isWeb,
          ),
        ],

        const SizedBox(height: 24),

        // ---- Confirm Button ----
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canProceed ? _goToDetails : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'নিশ্চিত করুন',
              style: TextStyle(
                fontSize: isWeb ? 18 : 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // ---- Retry (only when error) ----
        if (_showError) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loadAllJson,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('আবার চেষ্টা করুন'),
            ),
          ),
        ],
      ],
    );
  }

  // ──────────────────────  REUSABLE DROPDOWN  ──────────────────────
  Widget _drop({
    required String label,
    required String hint,
    required List<Map<String, dynamic>> items,
    required String? value,
    required bool loading,
    required ValueChanged<String?> onChanged,
    required bool isWeb,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isWeb ? 16 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
            border: Border.all(color: Colors.blue.shade300),
            boxShadow: isWeb
                ? [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: value,
                    hint: Text(
                      hint,
                      style: TextStyle(fontSize: isWeb ? 16 : 13),
                    ),
                    items: items
                        .map(
                          (e) => DropdownMenuItem(
                            value: e['id'].toString(),
                            child: Text(
                              e['bn_name'] ?? e['name'] ?? 'অজানা',
                              style: TextStyle(fontSize: isWeb ? 16 : 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onChanged,
                  ),
                ),
        ),
      ],
    );
  }
}
