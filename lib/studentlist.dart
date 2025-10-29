import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ru_family/MemberDetailsPage.dart';
import 'package:url_launcher/url_launcher.dart';

class MySomitiMembersNameList extends StatefulWidget {
  const MySomitiMembersNameList({super.key});

  @override
  State<MySomitiMembersNameList> createState() =>
      _MySomitiMembersNameListState();
}

class _MySomitiMembersNameListState extends State<MySomitiMembersNameList> {
  String? somitiName;
  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedDepartment;
  String? _selectedBloodGroup;
  String? _selectedSession;

  List<String> _departments = [];
  List<String> _bloodGroups = [];
  List<String> _sessions = [];

  List<Map<String, dynamic>> _allMembers = [];

  @override
  void initState() {
    super.initState();
    _loadSomitiName();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSomitiName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        somitiName = null;
        isLoading = false;
      });
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          somitiName = querySnapshot.docs.first['somitiName'];
          isLoading = false;
        });
      } else {
        setState(() {
          somitiName = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        somitiName = null;
        isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _updateFilters() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (somitiName == null) {
      return const Scaffold(
        body: Center(child: Text('No Somiti found for this user')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$somitiName সদস্যদের তথ্য'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Search Box with Count
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('members')
                      .where('somitiName', isEqualTo: somitiName)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int totalFiltered = 0;

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      _allMembers = snapshot.data!.docs
                          .map((doc) => doc.data() as Map<String, dynamic>)
                          .toList();

                      // Extract unique values
                      final Set<String> deptSet = {}, bgSet = {}, sessSet = {};
                      for (var m in _allMembers) {
                        final d = m['department']?.toString();
                        final b = m['bloodGroup']?.toString();
                        final s = m['session']?.toString();
                        if (d != null && d.isNotEmpty) deptSet.add(d);
                        if (b != null && b.isNotEmpty) bgSet.add(b);
                        if (s != null && s.isNotEmpty) sessSet.add(s);
                      }

                      _departments = ['সব'] + deptSet.toList()
                        ..sort();
                      _bloodGroups = ['সব'];
                      _sessions = ['সব'];

                      // Cascading logic (same as before)
                      if (_selectedDepartment != null &&
                          _selectedDepartment != 'সব') {
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
                        _bloodGroups = ['সব'] + filteredBG.toList()
                          ..sort();
                        if (_selectedBloodGroup != null &&
                            _selectedBloodGroup != 'সব') {
                          final sessFinal = <String>{};
                          for (var m in _allMembers) {
                            if (m['department'] == _selectedDepartment &&
                                m['bloodGroup'] == _selectedBloodGroup) {
                              final s = m['session']?.toString();
                              if (s != null && s.isNotEmpty) sessFinal.add(s);
                            }
                          }
                          _sessions = ['সব'] + sessFinal.toList()
                            ..sort();
                        } else {
                          _sessions = ['সব'] + filteredSess.toList()
                            ..sort();
                        }
                      } else {
                        _bloodGroups = ['সব'] + bgSet.toList()
                          ..sort();
                        _sessions = ['সব'] + sessSet.toList()
                          ..sort();
                      }

                      // Final filtered list
                      totalFiltered = _allMembers
                          .where((m) {
                            final name = (m['name'] ?? '')
                                .toString()
                                .toLowerCase();
                            final matchesSearch =
                                _searchQuery.isEmpty ||
                                name.contains(_searchQuery);
                            final deptMatch =
                                _selectedDepartment == null ||
                                _selectedDepartment == 'সব' ||
                                m['department'] == _selectedDepartment;
                            final bgMatch =
                                _selectedBloodGroup == null ||
                                _selectedBloodGroup == 'সব' ||
                                m['bloodGroup'] == _selectedBloodGroup;
                            final sessMatch =
                                _selectedSession == null ||
                                _selectedSession == 'সব' ||
                                m['session'] == _selectedSession;
                            return matchesSearch &&
                                deptMatch &&
                                bgMatch &&
                                sessMatch;
                          })
                          .toList()
                          .length;
                    }

                    return TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'সদস্যের নাম দিয়ে সার্চ করুন...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(
                            right: 12.0,
                            top: 12.0,
                          ),
                          child: Text(
                            '$totalFiltered জন',
                            style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Dropdown Row
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('members')
                      .where('somitiName', isEqualTo: somitiName)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    _allMembers = snapshot.data!.docs
                        .map((doc) => doc.data() as Map<String, dynamic>)
                        .toList();

                    // Rebuild dropdowns (same logic as above)
                    final Set<String> deptSet = {}, bgSet = {}, sessSet = {};
                    for (var m in _allMembers) {
                      final d = m['department']?.toString();
                      final b = m['bloodGroup']?.toString();
                      final s = m['session']?.toString();
                      if (d != null && d.isNotEmpty) deptSet.add(d);
                      if (b != null && b.isNotEmpty) bgSet.add(b);
                      if (s != null && s.isNotEmpty) sessSet.add(s);
                    }

                    _departments = ['সব'] + deptSet.toList()
                      ..sort();
                    _bloodGroups = ['সব'];
                    _sessions = ['সব'];

                    if (_selectedDepartment != null &&
                        _selectedDepartment != 'সব') {
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
                      _bloodGroups = ['সব'] + filteredBG.toList()
                        ..sort();
                      if (_selectedBloodGroup != null &&
                          _selectedBloodGroup != 'সব') {
                        final sessFinal = <String>{};
                        for (var m in _allMembers) {
                          if (m['department'] == _selectedDepartment &&
                              m['bloodGroup'] == _selectedBloodGroup) {
                            final s = m['session']?.toString();
                            if (s != null && s.isNotEmpty) sessFinal.add(s);
                          }
                        }
                        _sessions = ['সব'] + sessFinal.toList()
                          ..sort();
                      } else {
                        _sessions = ['সব'] + filteredSess.toList()
                          ..sort();
                      }
                    } else {
                      _bloodGroups = ['সব'] + bgSet.toList()
                        ..sort();
                      _sessions = ['সব'] + sessSet.toList()
                        ..sort();
                    }

                    // Filtered Members
                    final filteredMembers = _allMembers.where((m) {
                      final name = (m['name'] ?? '').toString().toLowerCase();
                      final matchesSearch =
                          _searchQuery.isEmpty || name.contains(_searchQuery);
                      final deptMatch =
                          _selectedDepartment == null ||
                          _selectedDepartment == 'সব' ||
                          m['department'] == _selectedDepartment;
                      final bgMatch =
                          _selectedBloodGroup == null ||
                          _selectedBloodGroup == 'সব' ||
                          m['bloodGroup'] == _selectedBloodGroup;
                      final sessMatch =
                          _selectedSession == null ||
                          _selectedSession == 'সব' ||
                          m['session'] == _selectedSession;
                      return matchesSearch && deptMatch && bgMatch && sessMatch;
                    }).toList();

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedDepartment,
                                decoration: InputDecoration(
                                  labelText: 'বিভাগ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _departments
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(d),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedDepartment = val;
                                    _selectedBloodGroup = 'সব';
                                    _selectedSession = 'সব';
                                  });
                                  _updateFilters();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedBloodGroup,
                                decoration: InputDecoration(
                                  labelText: 'রক্তের গ্রুপ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _bloodGroups
                                    .map(
                                      (bg) => DropdownMenuItem(
                                        value: bg,
                                        child: Text(bg),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedBloodGroup = val;
                                    _selectedSession = 'সব';
                                  });
                                  _updateFilters();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedSession,
                                decoration: InputDecoration(
                                  labelText: 'সেশন',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _sessions
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedSession = val;
                                  });
                                  _updateFilters();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // List with Serial Number
                        filteredMembers.isEmpty
                            ? const Center(child: Text('কোন সদস্য মিলেনি'))
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredMembers.length,
                                itemBuilder: (context, index) {
                                  final member = filteredMembers[index];
                                  final name =
                                      member['name'] ?? 'নাম পাওয়া যায়নি';
                                  final bloodGroup =
                                      member['bloodGroup'] ?? 'N/A';
                                  final mobileNumber =
                                      member['mobileNumber'] ?? '';

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                      horizontal: 8.0,
                                    ),
                                    child: ListTile(
                                      // Serial Number
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.teal,
                                        radius: 16,
                                        child: Text(
                                          '${index + 1}',
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
                                        'Blood Group: $bloodGroup',
                                      ),
                                      trailing: mobileNumber.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.phone,
                                                color: Colors.green,
                                              ),
                                              onPressed: () =>
                                                  _makePhoneCall(mobileNumber),
                                            )
                                          : null,
                                      onTap: () {
                                        final detailsData =
                                            Map<String, dynamic>.from(member);
                                        detailsData['somitiName'] = somitiName;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MemberDetailsPage(
                                                  memberData: detailsData,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
