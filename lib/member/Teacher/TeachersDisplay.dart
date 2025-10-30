// lib/Teacher/teachers_by_somiti.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:RUConnect_plus/member/Teacher/AddTeacher.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------- NEW DETAILS PAGE ----------
class TeacherDetailsPage extends StatelessWidget {
  final Map<String, dynamic> teacher;
  const TeacherDetailsPage({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    final name = teacher['name'] ?? 'N/A';
    final dept = teacher['department'] ?? 'N/A';
    final mobile = teacher['mobile'] ?? 'N/A';
    final blood = teacher['bloodGroup'] ?? 'N/A';
    final address = teacher['address'] ?? 'N/A';
    final addedBy = teacher['addedByEmail'] ?? 'N/A';
    final somiti = teacher['somitiName'] ?? 'N/A';
    final List<dynamic> social = teacher['socialMedia'] ?? [];
    final Timestamp? ts = teacher['createdAt'];
    final date = ts != null
        ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}"
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
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
                    if (mobile.isNotEmpty && mobile != 'N/A')
                      ElevatedButton.icon(
                        onPressed: () => _makeCall(mobile),
                        icon: const Icon(Icons.call),
                        label: const Text('কল'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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
                const Divider(height: 32, color: Colors.blue),
                _infoRow('মোবাইল', mobile),
                _infoRow('রক্তের গ্রুপ', blood),
                _infoRow('ঠিকানা', address),
                _infoRow('যোগ করেছেন', addedBy),
                _infoRow('সমিতি', somiti),
                _infoRow('যোগের তারিখ', date),
                if (social.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'সোশ্যাল মিডিয়া:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
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

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    ),
  );

  void _makeCall(String mobile) async {
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ---------- MAIN PAGE ----------
class TeachersBySomitiPage extends StatefulWidget {
  final String? somitiName;
  const TeachersBySomitiPage({Key? key, this.somitiName}) : super(key: key);

  @override
  State<TeachersBySomitiPage> createState() => _TeachersBySomitiPageState();
}

class _TeachersBySomitiPageState extends State<TeachersBySomitiPage> {
  String? _cachedSomiti;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('লগইন করুন')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('আমার সমিতির শিক্ষক'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTeacherInfoPage()),
        ),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: FutureBuilder<String>(
        future: _getSomitiName(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('সমিতি পাওয়া যায়নি'));
          }

          final somiti = snapshot.data!;
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('teachers')
                .where('somitiName', isEqualTo: somiti)
                .snapshots(includeMetadataChanges: true),
            builder: (context, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());

              final docs = snap.data!.docs;
              final filtered = docs.where((doc) {
                final data = doc.data();
                final name = (data['name'] ?? '').toString().toLowerCase();
                final dept = (data['department'] ?? '')
                    .toString()
                    .toLowerCase();
                return name.contains(_searchQuery) ||
                    dept.contains(_searchQuery);
              }).toList();

              final count = filtered.length;

              return Column(
                children: [
                  // Search
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'নাম / বিভাগ অনুসন্ধান করুন',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                  ),
                  // Count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$count টি শিক্ষক পাওয়া গেছে',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // List
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('কোনো শিক্ষক মিলেনি'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final doc = filtered[i];
                              final data = doc.data();
                              final name = data['name'] ?? 'N/A';
                              final dept = data['department'] ?? 'N/A';
                              final mobile = data['mobile'] ?? '';

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TeacherDetailsPage(teacher: data),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.blue.shade100,
                                          child: Text(
                                            '${i + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.blue.shade50,
                                          child: Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                        if (mobile.isNotEmpty)
                                          ElevatedButton.icon(
                                            onPressed: () => _makeCall(mobile),
                                            icon: const Icon(
                                              Icons.call,
                                              size: 18,
                                            ),
                                            label: const Text('কল'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ---------- SOMITI NAME ----------
  Future<String> _getSomitiName(String uid) async {
    if (widget.somitiName != null && widget.somitiName!.isNotEmpty)
      return widget.somitiName!;
    if (_cachedSomiti != null) return _cachedSomiti!;

    final cache = await FirebaseFirestore.instance
        .collection('members')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get(const GetOptions(source: Source.cache));

    if (cache.docs.isNotEmpty) {
      _cachedSomiti = cache.docs.first['somitiName']?.toString() ?? '';
      return _cachedSomiti!;
    }

    final server = await FirebaseFirestore.instance
        .collection('members')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get(const GetOptions(source: Source.server));

    _cachedSomiti = server.docs.isNotEmpty
        ? server.docs.first['somitiName']?.toString() ?? ''
        : '';
    return _cachedSomiti!;
  }

  void _makeCall(String mobile) async {
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
