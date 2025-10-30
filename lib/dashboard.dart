// lib/SomitiDashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ru_family/Images/ImageGlarry.dart'; // ImageGalleryPageview
import 'package:ru_family/Teacher/TeachersDisplay.dart'; // TeachersBySomitiPage
import 'package:ru_family/main.dart';
import 'package:ru_family/Student/studentlist.dart';

class SomitiDashboard extends StatelessWidget {
  const SomitiDashboard({super.key});

  /// Safe first character extractor
  String getFirstChar(dynamic input) {
    final str = input?.toString().trim() ?? '';
    return str.isNotEmpty ? str[0].toUpperCase() : '?';
  }

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
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 3,
              ),
            ),
          );
        }

        final String somitiName = snapshot.data ?? 'Somiti Dashboard';

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Text(
                    getFirstChar(somitiName),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(somitiName, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MyApp()),
                    );
                  }
                },
                tooltip: 'Logout',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              children: [
                _buildDashboardButton(
                  context,
                  'Student List',
                  Icons.people,
                  const MySomitiMembersNameList(),
                  Colors.blue.shade600,
                ),
                _buildDashboardButton(
                  context,
                  'Teacher List',
                  Icons.person,
                  const TeachersBySomitiPage(),
                  Colors.blue.shade700,
                ),
                _buildDashboardButton(
                  context,
                  'Image Gallery',
                  Icons.photo_library,
                  ImageGalleryPageview(somitiName: somitiName),
                  Colors.blue.shade800,
                ),
                _buildDashboardButton(
                  context,
                  'Notice',
                  Icons.notifications,
                  const NoticePage(),
                  Colors.blue.shade900,
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
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
    appBar: AppBar(
      title: const Text('Notice'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    body: const Center(
      child: Text(
        'This is the Notice page.\nComing soon!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    ),
  );
}
