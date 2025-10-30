import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:RUConnect_plus/AdminPages/admindadhboard.dart';
import 'dart:async';

import 'package:RUConnect_plus/member/dashboard.dart'; // SomitiDashboard
import 'package:RUConnect_plus/firebase_options.dart';
import 'package:RUConnect_plus/somitiPage.dart'; // মেইন পেজ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialize
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Enable Firestore Offline Persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // <-- Enable offline data
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Optional: unlimited cache
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RUConnect+',
      theme: ThemeData(
        primarySwatch: Colors.blue, // ← নীল থিম
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<User?>? _authSubscription;
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    _listenToAuthChanges();
    _startGlobalVerificationPolling();
  }

  void _listenToAuthChanges() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) async {
      if (!mounted) return;

      if (user != null) {
        await user.reload();
        final isVerified = user.emailVerified;

        if (isVerified) {
          // ইমেইল ভেরিফাইড → অ্যাডমিন চেক + upazillaName
          final adminData = await _checkIfAdmin(user.uid);
          if (adminData != null) {
            // অ্যাডমিন → upazillaName সহ
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AdminDashboard(somitiName: adminData['somitiName']),
              ),
              (route) => false,
            );
          } else {
            // মেম্বার
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SomitiDashboard()),
              (route) => false,
            );
          }
        } else {
          // ভেরিফাইড না
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const VerificationPage()),
            (route) => false,
          );
        }
      } else {
        // লগআউট → মেইন পেজ
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SomitiPage()),
          (route) => false,
        );
      }
    });
  }

  // Firestore চেক + upazillaName রিটার্ন
  Future<Map<String, dynamic>?> _checkIfAdmin(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('somitis')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final somitiName = doc['somitiName'] as String?;
      if (somitiName == null || somitiName.isEmpty) return null;

      return {'somitiName': somitiName};
    } catch (e) {
      debugPrint('Admin check error: $e');
      return null;
    }
  }

  void _startGlobalVerificationPolling() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified && mounted) {
        await user.reload();
        if (user.emailVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ইমেইল যাচাই সফল! ড্যাশবোর্ডে রিডাইরেক্ট হচ্ছে...'),
              backgroundColor: Colors.blue,
            ),
          );

          final adminData = await _checkIfAdmin(user.uid);
          if (adminData != null) {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AdminDashboard(somitiName: adminData['somitiName']),
                ),
                (route) => false,
              );
            }
          } else {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const SomitiDashboard(),
                ),
                (route) => false,
              );
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _verificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const SomitiPage();
        } else if (!user.emailVerified) {
          return const VerificationPage();
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}

// =============== Verification Page ===============
class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkVerification();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkVerification(),
    );
  }

  Future<void> _checkVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified && mounted) {
        // গ্লোবাল হ্যান্ডলার নিয়ে যাবে
      }
    }
  }

  Future<void> _resendVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('যাচাইকরণ ইমেইল পুনরায় পাঠানো হয়েছে!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ত্রুটি: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('ইমেইল যাচাই', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'ইমেইল যাচাই অপেক্ষমাণ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'আপনার ইমেইলে যাচাইকরণ লিঙ্ক পাঠানো হয়েছে। লিঙ্কে ক্লিক করুন। অ্যাপ স্বয়ংক্রিয়ভাবে আপডেট হবে।',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'ইমেইল: ${user?.email ?? ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _resendVerification,
              icon: const Icon(Icons.email),
              label: const Text('আবার ইমেইল পাঠান'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _checkVerification,
              child: const Text(
                'যাচাই স্থিতি চেক করুন',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
