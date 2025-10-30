// lib/somiti_details_form.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:RUConnect_plus/AdminPages/admindadhboard.dart';

// ================
// FULL SomitiDetailsForm FROM YOUR FIRST MESSAGE
// ================
class SomitiDetailsForm extends StatefulWidget {
  final String somitiType;
  final String divisionId;
  final String divisionName;
  final String districtId;
  final String districtName;
  final String? upazillaId;
  final String? upazillaName;

  const SomitiDetailsForm({
    super.key,
    required this.somitiType,
    required this.divisionId,
    required this.divisionName,
    required this.districtId,
    required this.districtName,
    this.upazillaId,
    this.upazillaName,
  });

  @override
  State<SomitiDetailsForm> createState() => _SomitiDetailsFormState();
}

class _SomitiDetailsFormState extends State<SomitiDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _somitiNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showVerification = false;
  bool _isVerifying = false;

  Timer? _verificationTimer;
  int _retryCount = 0;
  final int _maxRetries = 40;

  @override
  void initState() {
    super.initState();
    _generateAutoName();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _somitiNameController.dispose();
    super.dispose();
  }

  void _generateAutoName() {
    String autoName;
    if (widget.somitiType == "zilla") {
      autoName = "${widget.districtName} জেলা সমিতি";
    } else {
      autoName = "${widget.upazillaName ?? widget.districtName} উপজেলা সমিতি";
    }
    _somitiNameController.text = autoName;
  }

  Future<String?> _checkIfSomitiExists(String somitiName, String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('somitis')
          .where('somitiName', isEqualTo: somitiName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final existingEmail = data['email'] ?? 'অজানা';
        return 'এই নামে সমিতি আগে থেকেই আছে!\nতৈরি করেছেন: $existingEmail';
      }

      final emailSnapshot = await FirebaseFirestore.instance
          .collection('somitis')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (emailSnapshot.docs.isNotEmpty) {
        final data = emailSnapshot.docs.first.data();
        final existingSomiti = data['somitiName'] ?? 'অজানা';
        return 'এই ইমেইল ইতিমধ্যে ব্যবহৃত!\nসমিতি: $existingSomiti';
      }

      return null;
    } catch (e) {
      return 'চেক করতে সমস্যা: $e';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'পাসওয়ার্ড মিলছে না।');
      return;
    }

    final somitiName = _somitiNameController.text.trim();
    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final conflict = await _checkIfSomitiExists(somitiName, email);
    if (conflict != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = conflict;
      });
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text,
          );

      await _saveSomitiToFirestore(userCredential.user!.uid, somitiName);

      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        setState(() {
          _showVerification = true;
          _isVerifying = true;
          _retryCount = 0;
        });
        _showSnackBar(
          'ভেরিফিকেশন লিঙ্ক পাঠানো হয়েছে!',
          backgroundColor: Colors.green,
        );
        _startVerificationPolling();
      }
    } on FirebaseAuthException catch (e) {
      _handleError(e, _getAuthErrorMessage(e.code));
    } catch (e) {
      _handleError(e, "সমিতি তৈরি করতে সমস্যা");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSomitiToFirestore(String userId, String somitiName) async {
    try {
      await FirebaseFirestore.instance.collection('somitis').add({
        'userId': userId,
        'email': _emailController.text.trim(),
        'somitiName': somitiName,
        'somitiType': widget.somitiType,
        'divisionId': widget.divisionId,
        'divisionName': widget.divisionName,
        'districtId': widget.districtId,
        'districtName': widget.districtName,
        if (widget.upazillaId != null) 'upazillaId': widget.upazillaId,
        if (widget.upazillaName != null) 'upazillaName': widget.upazillaName,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });
    } catch (e) {
      await FirebaseAuth.instance.currentUser?.delete();
      rethrow;
    }
  }

  void _startVerificationPolling() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      if (_retryCount++ >= _maxRetries) {
        timer.cancel();
        if (mounted) {
          setState(() => _isVerifying = false);
          _showSnackBar(
            'সময় শেষ। ম্যানুয়ালি চেক করুন।',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        await user.reload();
        if (user.emailVerified) {
          timer.cancel();
          if (mounted) {
            _showSnackBar(
              'ভেরিফাইড! ড্যাশবোর্ডে যাচ্ছেন...',
              backgroundColor: Colors.green,
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AdminDashboard(
                  somitiName: _somitiNameController.text.trim(),
                ),
              ),
            );
          }
        }
      } catch (e) {
        // ignore
      }
    });
  }

  Future<void> _checkVerificationManually() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        _verificationTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AdminDashboard(somitiName: _somitiNameController.text.trim()),
          ),
        );
      } else {
        _showSnackBar('এখনও ভেরিফাই হয়নি।', backgroundColor: Colors.orange);
      }
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  void _handleError(dynamic error, String defaultMessage) {
    setState(() => _errorMessage = defaultMessage);
    _showSnackBar(defaultMessage, backgroundColor: Colors.red);
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'এই ইমেইল ইতিমধ্যে ব্যবহৃত।';
      case 'weak-password':
        return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।';
      case 'invalid-email':
        return 'অবৈধ ইমেইল।';
      case 'network-request-failed':
        return 'ইন্টারনেট সংযোগ সমস্যা।';
      default:
        return 'ত্রুটি: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.somitiType == "zilla" ? "জেলা" : "উপজেলা"} সমিতি তৈরি করুন',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_showVerification) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'বিভাগ: ${widget.divisionName}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'জেলা: ${widget.districtName}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (widget.upazillaName != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'উপজেলা: ${widget.upazillaName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _somitiNameController,
                    decoration: InputDecoration(
                      labelText: 'সমিতির নাম',
                      prefixIcon: const Icon(Icons.group),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'নাম দিন' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'ইমেইল',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v!.isEmpty) return 'ইমেইল দিন';
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(v))
                        return 'অবৈধ ইমেইল';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'পাসওয়ার্ড',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    obscureText: true,
                    validator: (v) => v!.length < 6 ? 'কমপক্ষে ৬ অক্ষর' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'পাসওয়ার্ড নিশ্চিত করুন',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    obscureText: true,
                    validator: (v) =>
                        v != _passwordController.text ? 'মিলছে না' : null,
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'সমিতি তৈরি করুন',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ] else ...[
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            _isVerifying
                                ? Icons.hourglass_empty
                                : Icons.mark_email_read,
                            size: 80,
                            color: _isVerifying ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isVerifying ? 'চেক হচ্ছে...' : 'ভেরিফাইড!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ইমেইল: ${_emailController.text.trim()}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (_isVerifying) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 12),
                            const Text(
                              'ইনবক্স/স্প্যাম চেক করুন। লিঙ্কে ক্লিক করুন।',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _isVerifying
                                ? null
                                : _checkVerificationManually,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              _isVerifying
                                  ? 'চেক হচ্ছে...'
                                  : 'ম্যানুয়ালি চেক করুন',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () =>
                                setState(() => _showVerification = false),
                            child: const Text('ফর্মে ফিরে যান'),
                          ),
                        ],
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
}
