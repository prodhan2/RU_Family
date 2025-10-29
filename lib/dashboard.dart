import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ru_family/AddTeacher.dart';
import 'package:ru_family/ImageGlarry.dart';
import 'package:ru_family/TeachersDisplay.dart';
import 'package:ru_family/main.dart';
import 'package:ru_family/studentlist.dart';

class SomitiDashboard extends StatelessWidget {
  const SomitiDashboard({super.key});

  /// Fetch the somitiName of the logged-in user from Firestore
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _fetchSomitiName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final String somitiName = snapshot.data ?? 'Somiti Dashboard';

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
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView(
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
                  const TeachersBySomitiPage(),
                  Colors.indigo,
                ),
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
          ),
        );
      },
    );
  }

  /// Helper widget for each dashboard button
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

// ───────────────────────────────
// Placeholder pages
// ───────────────────────────────

class NoticePage extends StatelessWidget {
  const NoticePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notice')),
    body: const Center(child: Text('This is the Notice page.')),
  );
}
