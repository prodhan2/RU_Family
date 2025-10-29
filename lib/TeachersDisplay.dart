// lib/teachers_by_somiti.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ru_family/AddTeacher.dart';
import 'package:url_launcher/url_launcher.dart';

/// ---------------------------------------------------------------
///  Main Page – List of teachers + FAB to add new teacher
/// ---------------------------------------------------------------
class TeachersBySomitiPage extends StatelessWidget {
  const TeachersBySomitiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('লগইন করুন')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('আমার সমিতির শিক্ষক'),
        backgroundColor: Colors.deepPurple,
      ),
      // FAB Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTeacherInfoPage()),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Find member's somitiName
        stream: FirebaseFirestore.instance
            .collection('members')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .snapshots(),
        builder: (context, memberSnap) {
          if (memberSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!memberSnap.hasData || memberSnap.data!.docs.isEmpty) {
            return const Center(child: Text('সমিতি পাওয়া যায়নি'));
          }

          final String somitiName =
              memberSnap.data!.docs.first['somitiName'] ?? '';

          // 2. Get teachers with same somitiName
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('teachers')
                .where('somitiName', isEqualTo: somitiName)
                .snapshots(),
            builder: (context, teacherSnap) {
              if (teacherSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!teacherSnap.hasData || teacherSnap.data!.docs.isEmpty) {
                return Center(child: Text('\'$somitiName\' এ কোনো শিক্ষক নেই'));
              }

              final docs = teacherSnap.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data()! as Map<String, dynamic>;
                  final String name = data['name'] ?? 'N/A';
                  final String dept = data['department'] ?? 'N/A';
                  final String mobile = data['mobile'] ?? '';

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherDetailsPage(
                            teacherData: data,
                            docId: docs[i].id,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.deepPurple.shade100,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Name & Dept
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    dept,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Call button
                            if (mobile.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: () => _makeCall(mobile),
                                icon: const Icon(Icons.call, size: 18),
                                label: const Text('কল'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _makeCall(String mobile) async {
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

/// ---------------------------------------------------------------
class TeacherDetailsPage extends StatelessWidget {
  final Map<String, dynamic> teacherData;
  final String docId;

  const TeacherDetailsPage({
    Key? key,
    required this.teacherData,
    required this.docId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String name = teacherData['name'] ?? 'N/A';
    final String dept = teacherData['department'] ?? 'N/A';
    final String mobile = teacherData['mobile'] ?? 'N/A';
    final String blood = teacherData['bloodGroup'] ?? 'N/A';
    final String address = teacherData['address'] ?? 'N/A';
    final String addedBy = teacherData['addedByEmail'] ?? 'N/A';
    final String somitiName = teacherData['somitiName'] ?? 'N/A'; // NEW FIELD
    final List<dynamic> social = teacherData['socialMedia'] ?? [];
    final Timestamp? ts = teacherData['createdAt'];
    final String date = ts != null
        ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}"
        : 'N/A';

    return Scaffold(
      appBar: AppBar(title: Text(name), backgroundColor: Colors.deepPurple),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dept,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (mobile.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => _makeCall(mobile),
                        icon: const Icon(Icons.call),
                        label: const Text('কল'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                  ],
                ),
                const Divider(height: 32),

                // Info rows
                _infoRow('মোবাইল', mobile),
                _infoRow('রক্তের গ্রুপ', blood),
                _infoRow('ঠিকানা', address),
                _infoRow('যোগ করেছেন', addedBy),
                _infoRow('সমিতি', somitiName), // NEW ROW
                _infoRow('যোগের তারিখ', date),

                if (social.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'সোশ্যাল মিডিয়া:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...social.map(
                    (link) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () => _openLink(link),
                        child: Text(
                          link,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _makeCall(String mobile) async {
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
