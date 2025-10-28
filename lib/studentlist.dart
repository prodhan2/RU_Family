import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

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

  /// 🔹 Step 1: Load current user's Somiti name from members collection
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
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
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

  /// 🔹 Launch phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
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

    /// 🔹 Step 2: Query members collection matching somitiName
    return Scaffold(
      appBar: AppBar(
        title: Text('$somitiName সদস্যদের তথ্য'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // 🔹 Search Filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'সদস্যের নাম দিয়ে সার্চ করুন...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('members')
                  .where('somitiName', isEqualTo: somitiName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('কোন সদস্য পাওয়া যায়নি'));
                }

                final allMembers = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();

                // 🔹 Filter members based on search query
                final filteredMembers = allMembers.where((member) {
                  final name = (member['name'] ?? '').toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredMembers.isEmpty && _searchQuery.isNotEmpty) {
                  return const Center(child: Text('কোন সদস্য মিলেনি'));
                }

                /// 🔹 Step 3: Compact list showing name, bloodGroup, and call button
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    final name = member['name'] ?? 'নাম পাওয়া যায়নি';
                    final bloodGroup = member['bloodGroup'] ?? 'N/A';
                    final mobileNumber = member['mobileNumber'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.teal),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text('Blood Group: $bloodGroup'),
                        trailing: mobileNumber.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.phone,
                                  color: Colors.green,
                                ),
                                onPressed: () => _makePhoneCall(mobileNumber),
                              )
                            : null,
                        onTap: () {
                          final detailsData = Map<String, dynamic>.from(member);
                          detailsData['somitiName'] = somitiName;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MemberDetailsPage(memberData: detailsData),
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
}

/// 🔹 Details Page for full member information
class MemberDetailsPage extends StatelessWidget {
  final Map<String, dynamic> memberData;

  const MemberDetailsPage({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    final name = memberData['name'] ?? 'নাম পাওয়া যায়নি';
    final bloodGroup = memberData['bloodGroup'] ?? 'N/A';
    final email = memberData['email'] ?? 'N/A';
    final hall = memberData['hall'] ?? 'N/A';
    final emergencyContact = memberData['emergencyContact'] ?? 'N/A';
    final mobileNumber = memberData['mobileNumber'] ?? 'N/A';
    final socialMediaId = memberData['socialMediaId'] ?? 'N/A';
    final permanentAddress = memberData['permanentAddress'] ?? 'N/A';
    final presentAddress = memberData['presentAddress'] ?? 'N/A';
    final universityId = memberData['universityId'] ?? 'N/A';
    final somitiName = memberData['somitiName'] ?? 'N/A';
    final createdAtRaw = memberData['createdAt'];
    String createdAt = 'N/A';
    if (createdAtRaw != null) {
      if (createdAtRaw is Timestamp) {
        createdAt = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(createdAtRaw.toDate());
      } else if (createdAtRaw is DateTime) {
        createdAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAtRaw);
      } else {
        createdAt = createdAtRaw.toString();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.teal, size: 50),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Blood Group: $bloodGroup',
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                const Divider(),
                _buildInfoRow('Somiti Name', somitiName),
                _buildInfoRow('Created At', createdAt),
                _buildInfoRow('Email', email),
                _buildInfoRow('University ID', universityId),
                _buildInfoRow('Hall', hall),
                _buildInfoRow('Mobile Number', mobileNumber),
                _buildInfoRow('Emergency Contact', emergencyContact),
                _buildInfoRow('Social Media ID', socialMediaId),
                _buildInfoRow('Permanent Address', permanentAddress),
                _buildInfoRow('Present Address', presentAddress),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
