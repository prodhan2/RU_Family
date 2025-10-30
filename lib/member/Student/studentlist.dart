// lib/Student/MySomitiMembersNameList.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:RUConnect_plus/member/Student/MemberDetailsPage.dart';
import 'package:url_launcher/url_launcher.dart';

class MySomitiMembersNameList extends StatefulWidget {
  const MySomitiMembersNameList({super.key});

  @override
  State<MySomitiMembersNameList> createState() =>
      _MySomitiMembersNameListState();
}

class _MySomitiMembersNameListState extends State<MySomitiMembersNameList> {
  // ----------  USER & SOMITI ----------
  String? _somitiName;
  bool _isLoading = true;

  // ----------  FILTERS ----------
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedDepartment;
  String? _selectedBloodGroup;
  String? _selectedSession;

  // ----------  DROPDOWN LISTS ----------
  List<String> _departments = ['All'];
  List<String> _bloodGroups = ['All'];
  List<String> _sessions = ['All'];

  // ----------  CACHE ----------
  List<Map<String, dynamic>> _allMembers = []; // Full list from Firestore
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

  // -----------------------------------------------------------------
  //  1. Load Somiti name (cache-first)
  // -----------------------------------------------------------------
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

  // -----------------------------------------------------------------
  //  2. Phone call
  // -----------------------------------------------------------------
  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // -----------------------------------------------------------------
  //  3. Update dropdowns based on current filters
  // -----------------------------------------------------------------
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

    // Base lists
    _departments = ['All', ...deptSet.toList()..sort()];
    _bloodGroups = ['All'];
    _sessions = ['All'];

    // Cascade: Dept → Blood → Session
    if (_selectedDepartment != null && _selectedDepartment != 'All') {
      final filteredBG = <String>{};
      final filteredSess = <String>{};

      for (var m in _allMembers) {
        if (m['department'] == _selectedDepartment) {
          final b = m['bloodGroup']?.toString();
          final s = m['session']?.toString();
          if (b != null && b.isNotEmpty) filteredBG.add(b);
          if (s != null && s.isNotEmpty) filteredSess.add(s);
        }
      }

      _bloodGroups = ['All', ...filteredBG.toList()..sort()];

      if (_selectedBloodGroup != null && _selectedBloodGroup != 'All') {
        final finalSess = <String>{};
        for (var m in _allMembers) {
          if (m['department'] == _selectedDepartment &&
              m['bloodGroup'] == _selectedBloodGroup) {
            final s = m['session']?.toString();
            if (s != null && s.isNotEmpty) finalSess.add(s);
          }
        }
        _sessions = ['All', ...finalSess.toList()..sort()];
      } else {
        _sessions = ['All', ...filteredSess.toList()..sort()];
      }
    } else {
      _bloodGroups = ['All', ...bgSet.toList()..sort()];
      _sessions = ['All', ...sessSet.toList()..sort()];
    }

    // Reset invalid selections
    if (!_departments.contains(_selectedDepartment))
      _selectedDepartment = 'All';
    if (!_bloodGroups.contains(_selectedBloodGroup))
      _selectedBloodGroup = 'All';
    if (!_sessions.contains(_selectedSession)) _selectedSession = 'All';
  }

  // -----------------------------------------------------------------
  //  4. Filter members
  // -----------------------------------------------------------------
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

  // -----------------------------------------------------------------
  //  5. UI
  // -----------------------------------------------------------------
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

                // Update full member list
                _allMembers = snapshot.data!.docs.map((d) => d.data()).toList();

                // Rebuild dropdowns + filters
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

  // -----------------------------------------------------------------
  //  6. Search + Filter UI
  // -----------------------------------------------------------------
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
