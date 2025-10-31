// login_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RUConnect_plus/AdminPages/admindadhboard.dart';
import 'package:RUConnect_plus/Authentication/passwordreset.dart';
import 'package:RUConnect_plus/member/dashboard.dart' show SomitiDashboard;

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
  bool _obscurePassword = true;

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
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SomitiDashboard()),
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

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(somitiName: somitiName),
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
      setState(() => _errorMessage = _getAuthErrorMessage(e.code));
    } on FirebaseException catch (e) {
      setState(() => _errorMessage = 'ডাটাবেস ত্রুটি: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'অজানা ত্রুটি।');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'ইমেইল দিয়ে কোনো অ্যাকাউন্ট পাওয়া যায়নি।';
      case 'wrong-password':
        return 'ভুল পাসওয়ার্ড।';
      case 'invalid-email':
        return 'অবৈধ ইমেইল।';
      case 'user-disabled':
        return 'অ্যাকাউন্ট নিষ্ক্রিয়।';
      case 'too-many-requests':
        return 'অনেক অনুরোধ। কিছুক্ষণ পর চেষ্টা করুন।';
      default:
        return 'লগইন ত্রুটি: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'লগইন',
          style: GoogleFonts.notoSansBengali(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: isWeb ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  // ==================== WEB LAYOUT – FULL HEIGHT LEFT SIDE ====================
  Widget _buildWebLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;

        // Responsive scaling
        final double scale = (maxHeight < 700 || maxWidth < 1000) ? 0.85 : 1.0;

        return SizedBox(
          width: double.infinity,
          height: double.infinity, // Full height
          child: Row(
            children: [
              // LEFT SIDE – FULL HEIGHT BLUE AREA
              Expanded(
                flex: 2,
                child: Container(
                  height: double.infinity,
                  color: Colors.blue.shade50,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              // RIGHT SIDE – FORM AREA
              Expanded(
                flex: 3,
                child: Center(
                  child: SingleChildScrollView(
                    child: Transform.scale(
                      scale: scale,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: scale < 1 ? 20 : 40,
                          vertical: scale < 1 ? 10 : 20,
                        ),
                        child: _buildFormContent(isWeb: true),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          _buildInstructionCard(isMobile: true),
          const SizedBox(height: 16),
          _buildFormContent(isWeb: false),
        ],
      ),
    );
  }

  // ==================== FORM CONTENT (SHARED) ====================
  Widget _buildFormContent({required bool isWeb}) {
    final double fontSize = isWeb ? 17 : 15;
    final double fieldHeight = isWeb ? 58 : 52;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'লগইন করুন',
            style: GoogleFonts.notoSansBengali(
              fontSize: isWeb ? 34 : 26,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 10),

          // Subtitle
          Text(
            'অ্যাডমিন বা মেম্বার হিসেবে প্রবেশ করুন',
            style: GoogleFonts.notoSansBengali(
              fontSize: isWeb ? 20 : 17,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Instruction Card
          if (isWeb) ...[
            _buildInstructionCard(isMobile: false),
            const SizedBox(height: 20),
          ],

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'ইমেইল',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.isEmpty
                ? 'ইমেইল দিন'
                : !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)
                ? 'অবৈধ ইমেইল'
                : null,
            height: fieldHeight,
            fontSize: fontSize,
          ),
          const SizedBox(height: 14),

          // Password
          _buildTextField(
            controller: _passwordController,
            label: 'পাসওয়ার্ড',
            icon: Icons.lock,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.blue.shade700,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) => v!.isEmpty
                ? 'পাসওয়ার্ড দিন'
                : v!.length < 6
                ? 'কমপক্ষে ৬ অক্ষর'
                : null,
            height: fieldHeight,
            fontSize: fontSize,
          ),
          const SizedBox(height: 8),

          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PasswordResetPage()),
              ),
              child: Text(
                'পাসওয়ার্ড ভুলে গেছেন?',
                style: GoogleFonts.notoSansBengali(
                  color: Colors.blue.shade700,
                  fontSize: fontSize - 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Error
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontSize: fontSize - 1,
                ),
              ),
            ),
          const SizedBox(height: 14),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: isWeb ? 58 : 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 6,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'লগইন করুন',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: fontSize + 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Auto Detect
          Center(
            child: Text(
              'অ্যাডমিন/মেম্বার স্বয়ংক্রিয়ভাবে চিহ্নিত হবে',
              style: GoogleFonts.notoSansBengali(
                fontSize: fontSize - 2,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TEXT FIELD ====================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    required double height,
    required double fontSize,
  }) {
    return SizedBox(
      height: height,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(fontSize: fontSize),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.blue.shade50.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
          ),
          labelStyle: GoogleFonts.notoSansBengali(
            color: Colors.blue.shade700,
            fontSize: fontSize - 1,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
        ),
        validator: validator,
      ),
    );
  }

  // ==================== INSTRUCTION CARD ====================
  Widget _buildInstructionCard({required bool isMobile}) {
    final double fontSize = isMobile ? 12.5 : 14;
    final double iconSize = isMobile ? 17 : 19;

    return Card(
      elevation: isMobile ? 4 : 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  size: iconSize + 3,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'লগইন নির্দেশনা',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: fontSize + 1.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildInstructionItem(
              icon: Icons.admin_panel_settings,
              text: 'অ্যাডমিন → নিজের ইমেইল ও পাসওয়ার্ড',
              fontSize: fontSize,
              iconSize: iconSize,
            ),
            const SizedBox(height: 6),
            _buildInstructionItem(
              icon: Icons.person,
              text: 'মেম্বার → নিজের ইমেইল ও পাসওয়ার্ড',
              fontSize: fontSize,
              iconSize: iconSize,
            ),
            const SizedBox(height: 6),
            _buildInstructionItem(
              icon: Icons.auto_awesome,
              text: 'স্বয়ংক্রিয় চিহ্নিত → সঠিক ড্যাশবোর্ড',
              fontSize: fontSize,
              iconSize: iconSize,
              bold: true,
              color: Colors.blue.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String text,
    required double fontSize,
    required double iconSize,
    Color? color,
    bool bold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: iconSize, color: color ?? Colors.blue.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.notoSansBengali(
              fontSize: fontSize,
              color: color ?? Colors.black87,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
