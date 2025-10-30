// admin_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:RUConnect_plus/Images/ImageGlarry.dart';
import 'package:RUConnect_plus/member/Student/MemberDetailsPage.dart';
import 'package:RUConnect_plus/member/Teacher/TeachersDisplay.dart';
import 'package:RUConnect_plus/somitiPage.dart';

class AdminDashboard extends StatefulWidget {
  final String somitiName;

  const AdminDashboard({super.key, required this.somitiName});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Stream<QuerySnapshot> _membersStream;
  late Stream<QuerySnapshot> _teachersStream;

  @override
  void initState() {
    super.initState();
    _membersStream = FirebaseFirestore.instance
        .collection('members')
        .where('somitiName', isEqualTo: widget.somitiName)
        .snapshots();

    _teachersStream = FirebaseFirestore.instance
        .collection('teachers')
        .where('somitiName', isEqualTo: widget.somitiName)
        .snapshots();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SomitiPage()),
        (route) => false,
      );
    }
  }

  Future<void> _updateStatus(DocumentSnapshot doc, bool newValue) async {
    try {
      await doc.reference.set({'status': newValue}, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newValue ? 'সক্রিয় করা হয়েছে' : 'নিষ্ক্রিয় করা হয়েছে',
            ),
            backgroundColor: newValue ? Colors.green : Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('স্ট্যাটাস আপডেট করতে ব্যর্থ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openImageGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ImageGalleryPageview(somitiName: widget.somitiName),
      ),
    );
  }

  void _openTeachersPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeachersBySomitiPage(somitiName: widget.somitiName),
      ),
    );
  }

  void _openMemberDetails(Map<String, dynamic> data, String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemberDetailsPage(memberData: data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Text(
          widget.somitiName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'লগআউট',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'স্বাগতম, অ্যাডমিন!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'সমিতি: ${widget.somitiName}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ৪টি কার্ড – ২টি আলাদা StreamBuilder
            Row(
              children: [
                // Members Stream
                Expanded(
                  flex: 3,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _membersStream,
                    builder: (context, memberSnap) {
                      if (memberSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final memberDocs = memberSnap.data?.docs ?? [];
                      final totalMembers = memberDocs.length;
                      final activeMembers = memberDocs
                          .where((d) => (d.data() as Map?)?['status'] == true)
                          .length;
                      final inactiveMembers = totalMembers - activeMembers;

                      return Row(
                        children: [
                          _buildCompactStatCard(
                            'মোট মেম্বার',
                            totalMembers.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildCompactStatCard(
                            'সক্রিয়',
                            activeMembers.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _buildCompactStatCard(
                            'নিষ্ক্রিয়',
                            inactiveMembers.toString(),
                            Icons.cancel,
                            Colors.red,
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Teachers Stream
                Expanded(
                  flex: 2,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _teachersStream,
                    builder: (context, teacherSnap) {
                      if (teacherSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final teacherCount = teacherSnap.data?.docs.length ?? 0;

                      return Row(
                        children: [
                          const SizedBox(width: 8),
                          _buildCompactActionCard(
                            'শিক্ষক',
                            teacherCount.toString(),
                            Icons.school,
                            Colors.purple,
                            _openTeachersPage,
                          ),
                          const SizedBox(width: 8),
                          _buildCompactActionCard(
                            'ইমেজ গ্যালারি',
                            '',
                            Icons.photo_library,
                            Colors.orange,
                            _openImageGallery,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'দ্রুত কার্যক্রম',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'নতুন মেম্বার যোগ করুন',
                    Icons.person_add,
                    Colors.blue,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('নতুন মেম্বার যোগ করার ফর্ম খুলবে...'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'রিপোর্ট দেখুন',
                    Icons.bar_chart,
                    Colors.purple,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('মাসিক রিপোর্ট দেখানো হচ্ছে...'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'সদস্য তালিকা',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Member List – Click to Details
            StreamBuilder<QuerySnapshot>(
              stream: _membersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(
                    child: Text(
                      'ডেটা লোড করা যায়নি।',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  );

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty)
                  return const Center(
                    child: Text(
                      'কোনো সদস্য পাওয়া যায়নি।',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final String docId = doc.id;
                    final name = data['name']?.toString() ?? 'নাম নেই';
                    final mobile =
                        data['mobileNumber']?.toString() ?? 'নম্বর নেই';
                    final blood = data['bloodGroup']?.toString() ?? '-';
                    final dept = data['department']?.toString() ?? 'বিভাগ নেই';
                    final bool isActive = data['status'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openMemberDetails(data, docId),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isActive
                                ? Colors.green
                                : Colors.red,
                            child: Text(
                              name.isNotEmpty ? name[0] : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'মোবাইল: $mobile',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'রক্ত: $blood',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'বিভাগ: $dept',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: isActive,
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                              onChanged: (v) => _updateStatus(doc, v),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionCard(
    String title,
    String? value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              if (value != null && value.isNotEmpty)
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              Text(
                title,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
