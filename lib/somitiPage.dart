// somiti_page.dart
import 'package:RUConnect_plus/help.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RUConnect_plus/AdminPages/developer.dart';
import 'package:RUConnect_plus/Authentication/Login.dart';
import 'package:RUConnect_plus/MakeSomiti/somitiCreate.dart';
import 'package:RUConnect_plus/UpdatedPages/update.dart';
import 'package:RUConnect_plus/member/memberRegistrationpage.dart';

// 🔧 Demo Page (Replace with your real admin/demo screen later)

class SomitiPage extends StatelessWidget {
  const SomitiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'RUConnect+',
          style: GoogleFonts.notoSansBengali(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: isWeb ? 22 : 20,
          ),
        ),
        centerTitle: !isWeb,
        elevation: 0,
        actions: [
          // ✅ Help button
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelplinePage()),
              );
            },
            child: const Text(
              "Help",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 👉 Admin icon in top-right
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppMakerAdmin()),
              );
            },
            tooltip: 'অ্যাডমিন ডেমো',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWeb ? _buildWebLayout(context) : _buildMobileLayout(context),
    );
  }

  // ==================== WEB LAYOUT ====================
  Widget _buildWebLayout(BuildContext context) {
    return Row(
      children: [
        // Left: Full-height colored sidebar with logo
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(50),
            child: Center(
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
        ),
        // Right: Content
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(60),
            child: _buildContent(context, isWeb: true),
          ),
        ),
      ],
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Logo
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),

          // Welcome Text
          Text(
            'স্বাগতম রাজশাহী ইউনিভার্সিটি ক্যাম্পাসে',
            style: const TextStyle(
              fontFamily: 'CustomBangla2', // ✅ your custom Bangla font
              fontSize: 30,
              color: Colors.black54, // same as Colors.grey[700]
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Buttons
          _buildButtonSection(context, isWeb: false),
        ],
      ),
    );
  }

  // ==================== SHARED CONTENT ====================
  Widget _buildContent(BuildContext context, {required bool isWeb}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'RUconnect+ অ্যাপ',
          style: GoogleFonts.notoSansBengali(
            fontSize: isWeb ? 36 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'স্বাগতম রাজশাহী ইউনিভার্সিটি ক্যাম্পাসে',
          style: const TextStyle(
            fontFamily: 'CustomBangla2', // ✅ your custom Bangla font
            fontSize: 30,
            color: Colors.black54, // same as Colors.grey[700]
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        _buildButtonSection(context, isWeb: isWeb),
      ],
    );
  }

  // ==================== BUTTON SECTION ====================
  Widget _buildButtonSection(BuildContext context, {required bool isWeb}) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 24 : 16,
        vertical: isWeb ? 18 : 14,
      ),
      minimumSize: Size(double.infinity, isWeb ? 64 : 54),
    );

    final textStyle = GoogleFonts.notoSansBengali(
      fontSize: isWeb ? 18 : 15,
      fontWeight: FontWeight.bold,
    );

    final iconSize = isWeb ? 28.0 : 22.0;

    return Column(
      children: [
        _buildStyledButton(
          context: context,
          label: 'Login',
          icon: Icons.login,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          ),
          style: buttonStyle,
          textStyle: textStyle,
          iconSize: iconSize,
        ),
        const SizedBox(height: 14),
        _buildStyledButton(
          context: context,
          label: 'সমিতি তৈরি করুন',
          icon: Icons.add_box_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SomitiChoicePage()),
          ),
          style: buttonStyle,
          textStyle: textStyle,
          iconSize: iconSize,
        ),
        const SizedBox(height: 14),
        _buildStyledButton(
          context: context,
          label: 'জেলা, উপজেলা সমিতিতে যোগদান করুন',
          icon: Icons.person_add_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MemberRegistrationPage()),
          ),
          style: buttonStyle,
          textStyle: textStyle,
          iconSize: iconSize,
        ),
        const SizedBox(height: 14),
        _buildStyledButton(
          context: context,
          label: 'দেখুন কী কী আপডেট আসছে',
          icon: Icons.notifications_active_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RUConnectUpdatesApp()),
          ),
          style: buttonStyle,
          textStyle: textStyle,
          iconSize: iconSize,
        ),
      ],
    );
  }

  Widget _buildStyledButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required ButtonStyle style,
    required TextStyle textStyle,
    required double iconSize,
  }) {
    return ElevatedButton.icon(
      style: style,
      icon: Icon(icon, size: iconSize),
      label: Text(label, style: textStyle, textAlign: TextAlign.center),
      onPressed: onTap,
    );
  }
}
