// lib/Student/MySomitiMembersNameList.dart
import 'dart:typed_data';
import 'package:RUConnect_plus/member/Student/pdfsettingPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:RUConnect_plus/member/Student/MemberDetailsPage.dart';
import 'package:url_launcher/url_launcher.dart';

class MySomitiMembersNameList extends StatefulWidget {
  const MySomitiMembersNameList({super.key});

  @override
  State<MySomitiMembersNameList> createState() =>
      _MySomitiMembersNameListState();
}

class _MySomitiMembersNameListState extends State<MySomitiMembersNameList> {
  String? _somitiName;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDepartment;
  String? _selectedBloodGroup;
  String? _selectedSession;

  List<String> _departments = ['All'];
  List<String> _bloodGroups = ['All'];
  List<String> _sessions = ['All'];

  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _filteredMembers = [];

  @override
  void initState() {
    super.initState();
    _loadSomitiName();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSomitiName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final cacheSnap = await FirebaseFirestore.instance
        .collection('members')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get(const GetOptions(source: Source.cache));

    if (cacheSnap.docs.isNotEmpty) {
      setState(() {
        _somitiName = cacheSnap.docs.first['somitiName']?.toString();
        _isLoading = false;
      });
      return;
    }

    try {
      final serverSnap = await FirebaseFirestore.instance
          .collection('members')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get(const GetOptions(source: Source.server));

      setState(() {
        _somitiName = serverSnap.docs.isNotEmpty
            ? serverSnap.docs.first['somitiName']?.toString()
            : null;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _updateDropdowns() {
    final deptSet = <String>{};
    final bgSet = <String>{};
    final sessSet = <String>{};

    for (var m in _allMembers) {
      final d = m['department']?.toString();
      final b = m['bloodGroup']?.toString();
      final s = m['session']?.toString();

      if (d != null && d.isNotEmpty) deptSet.add(d);
      if (b != null && b.isNotEmpty) bgSet.add(b);
      if (s != null && s.isNotEmpty) sessSet.add(s);
    }

    _departments = ['All', ...deptSet.toList()..sort()];
    _bloodGroups = ['All', ...bgSet.toList()..sort()];
    _sessions = ['All', ...sessSet.toList()..sort()];

    if (!_departments.contains(_selectedDepartment))
      _selectedDepartment = 'All';
    if (!_bloodGroups.contains(_selectedBloodGroup))
      _selectedBloodGroup = 'All';
    if (!_sessions.contains(_selectedSession)) _selectedSession = 'All';
  }

  void _applyFilters() {
    _filteredMembers = _allMembers.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);

      final deptMatch =
          _selectedDepartment == null ||
          _selectedDepartment == 'All' ||
          m['department'] == _selectedDepartment;

      final bgMatch =
          _selectedBloodGroup == null ||
          _selectedBloodGroup == 'All' ||
          m['bloodGroup'] == _selectedBloodGroup;

      final sessMatch =
          _selectedSession == null ||
          _selectedSession == 'All' ||
          m['session'] == _selectedSession;

      return matchesSearch && deptMatch && bgMatch && sessMatch;
    }).toList();
  }

  // Helper: Format Timestamp
  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'N/A';
    if (ts is Timestamp) {
      final date = ts.toDate();
      return DateFormat('MMMM d, yyyy – h:mm a').format(date);
    }
    return ts.toString();
  }

  Future<void> _generatePdf(
    BuildContext context,
    List<String> selectedFields,
    List<Map<String, dynamic>> members,
  ) async {
    final pdf = pw.Document();
    final fieldLabels = {
      'name': 'Name',
      'bloodGroup': 'Blood Group',
      'mobileNumber': 'Mobile',
      'department': 'Department',
      'session': 'Session',
      'email': 'Email',
      'emergencyContact': 'Emergency Contact',
      'hall': 'Hall',
      'permanentAddress': 'Permanent Address',
      'presentAddress': 'Present Address',
      'socialMediaId': 'Social Media',
      'universityId': 'University ID',
      'somitiName': 'Somiti',
      'createdAt': 'Registered At',
    };

    final tableHeaders = <pw.Widget>[];
    final tableData = <List<pw.Widget>>[];

    for (final field in selectedFields) {
      tableHeaders.add(
        pw.Text(
          fieldLabels[field] ?? field,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    for (final member in members) {
      final row = <pw.Widget>[];
      for (final field in selectedFields) {
        String value = 'N/A';
        if (field == 'createdAt') {
          value = _formatTimestamp(member['createdAt']);
        } else {
          value = (member[field]?.toString() ?? 'N/A');
        }
        row.add(pw.Text(value, maxLines: 2));
      }
      tableData.add(row);
    }

    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.all(20),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '$_somitiName Members List',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated on: ${DateFormat('yMMMMd').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
            pw.SizedBox(height: 20),
            // ignore: deprecated_member_use
            pw.Table.fromTextArray(
              headers: tableHeaders.map((e) => e.toString()).toList(),
              data: tableData, // List<List<String>>
              border: pw.TableBorder.all(width: 0.5),
              tableWidth: pw.TableWidth.max,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: pw.TextStyle(fontSize: 12),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      ),
    );

    final output = await pdf.save();
    await Printing.layoutPdf(onLayout: (format) async => output);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_somitiName == null) {
      return const Scaffold(body: Center(child: Text('No Somiti found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$_somitiName Members'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Inside build() → AppBar actions
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfSettingsPage(
                    members: _filteredMembers,
                    somitiName: _somitiName ?? 'Somiti',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('members')
                  .where('somitiName', isEqualTo: _somitiName)
                  .snapshots(includeMetadataChanges: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                _allMembers = snapshot.data!.docs.map((d) => d.data()).toList();
                _updateDropdowns();
                _applyFilters();

                if (_filteredMembers.isEmpty) {
                  return const Center(child: Text('No members found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _filteredMembers.length,
                  itemBuilder: (context, i) {
                    final data = _filteredMembers[i];
                    final name = data['name'] ?? 'Name not found';
                    final blood = data['bloodGroup'] ?? 'N/A';
                    final mobile = data['mobileNumber'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Blood: $blood',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        trailing: mobile.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.phone,
                                  color: Colors.green,
                                ),
                                onPressed: () => _makePhoneCall(mobile),
                              )
                            : null,
                        onTap: () {
                          final details = Map<String, dynamic>.from(data);
                          details['somitiName'] = _somitiName;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MemberDetailsPage(memberData: details),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12, top: 12),
                child: Text(
                  '${_filteredMembers.length} members',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedDepartment,
                  items: _departments,
                  label: 'Department',
                  onChanged: (v) {
                    setState(() {
                      _selectedDepartment = v;
                      _selectedBloodGroup = 'All';
                      _selectedSession = 'All';
                      _applyFilters();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  value: _selectedBloodGroup,
                  items: _bloodGroups,
                  label: 'Blood Group',
                  onChanged: (v) {
                    setState(() {
                      _selectedBloodGroup = v;
                      _selectedSession = 'All';
                      _applyFilters();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  value: _selectedSession,
                  items: _sessions,
                  label: 'Session',
                  onChanged: (v) {
                    setState(() {
                      _selectedSession = v;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
      items: items
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ---------------------------------------------------------------------
// PDF Settings Page – FULL FIELD SUPPORT
// ---------------------------------------------------------------------
