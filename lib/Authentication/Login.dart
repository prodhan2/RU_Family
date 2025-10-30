// login_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ru_family/AdminPages/admindadhboard.dart';
import 'package:ru_family/passwordreset.dart';

import 'package:ru_family/dashboard.dart' show SomitiDashboard;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final user = userCredential.user;
      if (user == null) {
        setState(() {
          _errorMessage = 'লগইন ব্যর্থ। আবার চেষ্টা করুন।';
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('somitis')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // মেম্বার
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SomitiDashboard()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('মেম্বার লগইন সফল!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      final doc = snapshot.docs.first;
      final somitiName = doc['somitiName'] as String?;

      if (somitiName == null || somitiName.isEmpty) {
        setState(() {
          _errorMessage = 'অ্যাডমিন অ্যাকাউন্টে সমিতির নাম পাওয়া যায়নি।';
          _isLoading = false;
        });
        return;
      }

      // অ্যাডমিন → somitiName সহ
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboard(somitiName: somitiName),
          ),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('অ্যাডমিন লগইন সফল! সমিতি: $somitiName'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getAuthErrorMessage(e.code);
      });
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'ডাটাবেস ত্রুটি: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'কোনো অজানা ত্রুটি ঘটেছে।';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'কোনো অ্যাকাউন্ট এই ইমেইলে পাওয়া যায়নি।';
      case 'wrong-password':
        return 'ভুল পাসওয়ার্ড।';
      case 'invalid-email':
        return 'অবৈধ ইমেইল ঠিকানা।';
      case 'user-disabled':
        return 'এই অ্যাকাউন্ট নিষ্ক্রিয়।';
      case 'too-many-requests':
        return 'অনেকগুলি অনুরোধ। কিছুক্ষণ পর চেষ্টা করুন।';
      default:
        return 'লগইন ত্রুটি: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('লগইন', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'আপনার অ্যাকাউন্টে লগইন করুন',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'লগইন নির্দেশনা',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstruction(
                      'অ্যাডমিন হলে → অ্যাডমিনের ইমেইল ও পাসওয়ার্ড দিন',
                    ),
                    const SizedBox(height: 6),
                    _buildInstruction(
                      'মেম্বার হলে → মেম্বারের ইমেইল ও পাসওয়ার্ড দিন',
                    ),
                    const SizedBox(height: 6),
                    _buildInstruction(
                      'সিস্টেম স্বয়ংক্রিয়ভাবে চেক করবে → সঠিক ড্যাশবোর্ডে নিয়ে যাবে',
                      color: Colors.blue.shade700,
                      bold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'ইমেইল',
                  prefixIcon: const Icon(Icons.email, color: Colors.blue),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(
                      color: Colors.blue.shade600,
                      width: 2,
                    ),
                  ),
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'ইমেইল প্রয়োজনীয়।';
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'অবৈধ ইমেইল ঠিকানা।';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'পাসওয়ার্ড',
                  prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(
                      color: Colors.blue.shade600,
                      width: 2,
                    ),
                  ),
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'পাসওয়ার্ড প্রয়োজনীয়।';
                  if (value.length < 6)
                    return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।';
                  return null;
                },
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasswordResetPage(),
                      ),
                    );
                  },
                  child: Text(
                    'পাসওয়ার্ড ভুলে গেছেন?',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.blue.shade800),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),

              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'লগইন করুন',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'অ্যাডমিন/মেম্বার স্বয়ংক্রিয়ভাবে চিহ্নিত হবে',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String text, {Color? color, bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(fontSize: 16, color: color ?? Colors.black87),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.black87,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
