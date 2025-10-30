// lib/SomitiDashboard.dart
import 'package:RUConnect_plus/member/Student/profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:RUConnect_plus/Images/ImageGlarry.dart';
import 'package:RUConnect_plus/member/Teacher/TeachersDisplay.dart';
import 'package:RUConnect_plus/main.dart';
import 'package:RUConnect_plus/member/Student/studentlist.dart';

class SomitiDashboard extends StatefulWidget {
  const SomitiDashboard({super.key});

  @override
  State<SomitiDashboard> createState() => _SomitiDashboardState();
}

class _SomitiDashboardState extends State<SomitiDashboard> {
  // ----------  MEMORY CACHE ----------
  String? _cachedSomitiName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSomitiName();
  }

  // -----------------------------------------------------------------
  //  Load somitiName – cache first, then server
  // -----------------------------------------------------------------
  Future<void> _loadSomitiName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _cachedSomitiName = 'Somiti Dashboard';
        _isLoading = false;
      });
      return;
    }

    // 1. Try in‑memory cache
    if (_cachedSomitiName != null) {
      setState(() => _isLoading = false);
      return;
    }

    // 2. Try Firestore local cache
    final cacheSnap = await FirebaseFirestore.instance
        .collection('members')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get(const GetOptions(source: Source.cache));

    if (cacheSnap.docs.isNotEmpty) {
      final name =
          cacheSnap.docs.first['somitiName']?.toString() ?? 'Somiti Dashboard';
      setState(() {
        _cachedSomitiName = name;
        _isLoading = false;
      });
      return;
    }

    // 3. Fallback to server (will also fill cache)
    try {
      final serverSnap = await FirebaseFirestore.instance
          .collection('members')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get(const GetOptions(source: Source.server));

      final name = serverSnap.docs.isNotEmpty
          ? serverSnap.docs.first['somitiName']?.toString() ??
                'Somiti Dashboard'
          : 'Somiti Dashboard';

      setState(() {
        _cachedSomitiName = name;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Somiti name error: $e');
      setState(() {
        _cachedSomitiName = 'Somiti Dashboard';
        _isLoading = false;
      });
    }
  }

  String getFirstChar(dynamic input) {
    final str = input?.toString().trim() ?? '';
    return str.isNotEmpty ? str[0].toUpperCase() : '?';
  }

  // -----------------------------------------------------------------
  //  UI
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 3),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Text(
                getFirstChar(_cachedSomitiName),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _cachedSomitiName!,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          children: [
            // ----------  Student List ----------
            _offlineButton(
              context,
              'Student List',
              Icons.people,
              Colors.blue.shade600,
              () => const MySomitiMembersNameList(),
            ),

            // ----------  Teacher List ----------
            _offlineButton(
              context,
              'Teacher List',
              Icons.person,
              Colors.blue.shade700,
              () => const TeachersBySomitiPage(),
            ),

            // ----------  Image Gallery ----------
            _offlineButton(
              context,
              'Image Gallery',
              Icons.photo_library,
              Colors.blue.shade800,
              () => ImageGalleryPageview(somitiName: _cachedSomitiName!),
            ),

            // ----------  Notice ----------
            _offlineButton(
              context,
              'Notice',
              Icons.notifications,
              Colors.blue.shade900,
              () => const NoticePage(),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  //  Re‑usable offline‑first button
  // -----------------------------------------------------------------
  Widget _offlineButton(
    BuildContext ctx,
    String title,
    IconData icon,
    Color color,
    Widget Function() pageBuilder,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => _OfflinePageWrapper(child: pageBuilder()),
        ),
      ),
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

  // -----------------------------------------------------------------
  //  Drawer
  // -----------------------------------------------------------------
  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'user@example.com';
    final photoUrl = user?.photoURL;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              _cachedSomitiName!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      getFirstChar(_cachedSomitiName),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            decoration: const BoxDecoration(color: Colors.blue),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyApp()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  Wrapper that forces every child page to load from cache first
// ---------------------------------------------------------------------
class _OfflinePageWrapper extends StatelessWidget {
  final Widget child;
  const _OfflinePageWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Dummy future – just to trigger cache‑first load on child pages
      future: Future.delayed(Duration.zero),
      builder: (_, __) => child,
    );
  }
}

// ---------------------------------------------------------------------
//  Placeholder Notice Page
// ---------------------------------------------------------------------
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
