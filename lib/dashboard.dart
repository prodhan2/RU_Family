import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ru_family/ImageGlarry.dart';
import 'package:ru_family/ImagesTake.dart';
import 'package:ru_family/main.dart';
import 'package:ru_family/studentlist.dart';

class SomitiDashboard extends StatelessWidget {
  const SomitiDashboard({super.key});

  /// Returns the somitiName of the logged-in user (from members collection)
  Future<String> _fetchSomitiName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Somiti Dashboard';

    try {
      final snap = await FirebaseFirestore.instance
          .collection('members')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs.first.get('somitiName')?.toString() ??
            'Somiti Dashboard';
      }
    } catch (e) {
      debugPrint('Error fetching somitiName: $e');
    }
    return 'Somiti Dashboard';
  }

  final List<Map<String, dynamic>> somitis = const [
    {'name': 'Somiti A', 'location': 'Dhaka', 'members': 50},
    {'name': 'Somiti B', 'location': 'Chittagong', 'members': 35},
    {'name': 'Somiti C', 'location': 'Rajshahi', 'members': 40},
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _fetchSomitiName(),
      builder: (context, snapshot) {
        // ── Still loading ───────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final String somitiName = snapshot.data ?? 'Somiti Dashboard';

        // ── UI (same as before, only Gallery button changed) ─────
        int totalSomitis = somitis.length;
        int totalMembers = somitis.fold(
          0,
          (sum, s) => sum + (s['members'] as int),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(somitiName),
            backgroundColor: Colors.redAccent,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Summary Cards ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryCard(
                      'Total Somitis',
                      totalSomitis.toString(),
                      Colors.orange,
                    ),
                    _buildSummaryCard(
                      'Total Members',
                      totalMembers.toString(),
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Action Buttons ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Create Somiti
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Somiti'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: View All Somitis
                      },
                      icon: const Icon(Icons.list),
                      label: const Text('View All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Dashboard Grid ─────────────────────────────────────
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  children: [
                    _buildDashboardButton(
                      context,
                      'Student List',
                      Icons.people,
                      const MySomitiMembersNameList(),
                      Colors.teal,
                    ),
                    _buildDashboardButton(
                      context,
                      'Teacher List',
                      Icons.person,
                      const TeacherListPage(),
                      Colors.indigo,
                    ),
                    // ── GALLERY BUTTON – PASS REAL SOMITI NAME ───────
                    _buildDashboardButton(
                      context,
                      'Image Gallery',
                      Icons.account_balance_wallet,
                      ImageGalleryPageview(somitiName: somitiName),
                      Colors.orange,
                    ),
                    _buildDashboardButton(
                      context,
                      'Notice',
                      Icons.notifications,
                      const NoticePage(),
                      Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Somiti List (static demo) ────────────────────────
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: somitis.length,
                  itemBuilder: (context, i) {
                    final s = somitis[i];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Text(
                            s['name'][0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(s['name']),
                        subtitle: Text('Location: ${s['location']}'),
                        trailing: Text('${s['members']} members'),
                        onTap: () {
                          // TODO: Navigate to Somiti detail
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Helper widgets (unchanged)
  // ────────────────────────────────────────────────────────────────
  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      color: color,
      elevation: 4,
      child: SizedBox(
        width: 150,
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardButton(
    BuildContext ctx,
    String title,
    IconData icon,
    Widget page,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => page)),
      child: Card(
        color: color,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Placeholder pages (unchanged)
// ────────────────────────────────────────────────────────────────
class TeacherListPage extends StatelessWidget {
  const TeacherListPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Teacher List')),
    body: const Center(child: Text('This is the Teacher List page.')),
  );
}

class NoticePage extends StatelessWidget {
  const NoticePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notice')),
    body: const Center(child: Text('This is the Notice page.')),
  );
}
