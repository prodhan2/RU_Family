// somiti_page.dart
import 'package:RUConnect_plus/BStoreApp/categorypage.dart';
import 'package:RUConnect_plus/help.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RUConnect_plus/AdminPages/developer.dart';
import 'package:RUConnect_plus/Authentication/Login.dart';
import 'package:RUConnect_plus/MakeSomiti/somitiCreate.dart';
import 'package:RUConnect_plus/UpdatedPages/update.dart';
import 'package:RUConnect_plus/member/memberRegistrationpage.dart';

// Custom Shimmer Widget for fast perceived loading
class ShimmerLine extends StatefulWidget {
  final double widthFactor;
  final double height;

  const ShimmerLine({Key? key, this.widthFactor = 1.0, this.height = 16.0})
    : super(key: key);

  @override
  State<ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<ShimmerLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -0.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final shimmerPosition = _animation.value * constraints.maxWidth;
            return Container(
              width: double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: widget.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[100]!,
                          Colors.grey[300]!,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: shimmerPosition,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ShimmerImagePlaceholder extends StatefulWidget {
  final double width;
  final double height;

  const ShimmerImagePlaceholder({Key? key, this.width = 140, this.height = 140})
    : super(key: key);

  @override
  State<ShimmerImagePlaceholder> createState() =>
      _ShimmerImagePlaceholderState();
}

class _ShimmerImagePlaceholderState extends State<ShimmerImagePlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -0.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[100]!,
                      Colors.grey[300]!,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: _animation.value * widget.width,
                top: _animation.value * widget.height,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ShimmerButton extends StatefulWidget {
  final double height;
  final double widthFactor;

  const ShimmerButton({Key? key, this.height = 54, this.widthFactor = 1.0})
    : super(key: key);

  @override
  State<ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<ShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -0.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final shimmerPosition = _animation.value * constraints.maxWidth;
            return Container(
              width: double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[100]!,
                          Colors.grey[300]!,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: shimmerPosition,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// 🔧 Demo Page (Replace with your real admin/demo screen later)

class SomitiPage extends StatefulWidget {
  const SomitiPage({super.key});

  @override
  State<SomitiPage> createState() => _SomitiPageState();
}

class _SomitiPageState extends State<SomitiPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate fast load with short delay for shimmer effect (adjust as needed)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

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

          // 🛍️ RUStore button
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CategoryPage()),
              );
            },
            child: const Text(
              "RUStore",
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

      body: _isLoading
          ? isWeb
                ? _buildWebShimmerLayout(context)
                : _buildMobileShimmerLayout(context)
          : isWeb
          ? _buildWebLayout(context)
          : _buildMobileLayout(context),
    );
  }

  // ==================== SHIMMER LAYOUTS ====================
  Widget _buildWebShimmerLayout(BuildContext context) {
    return Row(
      children: [
        // Left: Shimmer for logo
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(50),
            child: const Center(
              child: ShimmerImagePlaceholder(width: 200, height: 200),
            ),
          ),
        ),
        // Right: Shimmer content
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(60),
            child: _buildShimmerContent(context, isWeb: true),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileShimmerLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Shimmer Logo
          const Center(child: ShimmerImagePlaceholder()),
          const SizedBox(height: 16),

          // Shimmer Welcome Text
          const ShimmerLine(height: 24, widthFactor: 0.8),
          const SizedBox(height: 24),

          // Shimmer Buttons
          _buildShimmerButtonSection(context, isWeb: false),
        ],
      ),
    );
  }

  Widget _buildShimmerContent(BuildContext context, {required bool isWeb}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShimmerLine(height: 40, widthFactor: 0.6),
        const SizedBox(height: 12),
        ShimmerLine(height: 24, widthFactor: 0.8),
        const SizedBox(height: 40),
        _buildShimmerButtonSection(context, isWeb: isWeb),
      ],
    );
  }

  Widget _buildShimmerButtonSection(
    BuildContext context, {
    required bool isWeb,
  }) {
    return Column(
      children: [
        ShimmerButton(height: isWeb ? 64 : 54),
        const SizedBox(height: 14),
        ShimmerButton(height: isWeb ? 64 : 54),
        const SizedBox(height: 14),
        ShimmerButton(height: isWeb ? 64 : 54),
        const SizedBox(height: 14),
        ShimmerButton(height: isWeb ? 64 : 54),
      ],
    );
  }

  // ==================== ORIGINAL LAYOUTS (Non-Shimmer) ====================
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
