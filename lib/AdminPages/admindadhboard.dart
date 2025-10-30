// admin_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ru_family/somitiPage.dart';

class AdminDashboard extends StatefulWidget {
  final String somitiName;

  const AdminDashboard({super.key, required this.somitiName});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Stream<QuerySnapshot> _membersStream;

  @override
  void initState() {
    super.initState();
    _membersStream = FirebaseFirestore.instance
        .collection('members')
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

  // স্ট্যাটাস আপডেট
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
            tooltip: 'লগআ�উট',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ওয়েলকাম কার্ড
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

            // স্ট্যাটিস্টিক্স
            StreamBuilder<QuerySnapshot>(
              stream: _membersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'ত্রুটি: ডেটা লোড করা যায়নি।',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final total = docs.length;

                // status না থাকলে → false (নিষ্ক্রিয়)
                final active = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  return data?['status'] == true;
                }).length;

                final inactive = total - active;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'মোট মেম্বার',
                            total.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'সক্রিয়',
                            active.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'নিষ্ক্রিয়',
                            inactive.toString(),
                            Icons.cancel,
                            Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'পেন্ডিং',
                            '0',
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
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

            // মেম্বার লিস্ট + টগল
            StreamBuilder<QuerySnapshot>(
              stream: _membersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'ডেটা লোড করা যায়নি।',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'কোনো সদস্য পাওয়া যায়নি।',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};

                    final name = data['name']?.toString() ?? 'নাম নেই';
                    final mobile =
                        data['mobileNumber']?.toString() ?? 'নম্বর নেই';
                    final blood = data['bloodGroup']?.toString() ?? '-';
                    final dept = data['department']?.toString() ?? 'বিভাগ নেই';

                    // status না থাকলে → false (নিষ্ক্রিয়)
                    final bool isActive = data['status'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: isActive ? Colors.green : Colors.red,
                          child: Text(
                            name.isNotEmpty ? name[0] : '?',
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                        trailing: Switch(
                          value: isActive,
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          onChanged: (value) => _updateStatus(doc, value),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                name,
                                style: const TextStyle(fontSize: 16),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('মোবাইল: $mobile'),
                                  Text('রক্তের গ্রুপ: $blood'),
                                  Text('বিভাগ: $dept'),
                                  Text(
                                    'স্ট্যাটাস: ${isActive ? 'সক্রিয়' : 'নিষ্ক্রিয়'}',
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('বন্ধ করুন'),
                                ),
                              ],
                            ),
                          );
                        },
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            // style: TextStyle(fontSize: 14, color: color.shade700),
            textAlign: TextAlign.center,
          ),
        ],
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
