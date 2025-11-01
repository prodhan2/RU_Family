// somiti_page.dart
import 'package:RUConnect_plus/AdminPages/AdminPro.dart';
import 'package:RUConnect_plus/BStoreApp/categorypage.dart';
import 'package:RUConnect_plus/Pdf_resources.dart';
import 'package:RUConnect_plus/RUPaymentPage.dart';
import 'package:RUConnect_plus/RU_Medical.dart';
import 'package:RUConnect_plus/RU_info.dart';
import 'package:RUConnect_plus/ResourcesLibrary/GoogeDriveLibrary/drive.dart';
import 'package:RUConnect_plus/Ru_blood.dart';
import 'package:RUConnect_plus/ShimmerImagePlaceholder.dart';
import 'package:RUConnect_plus/help.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RUConnect_plus/AdminPages/developer.dart';
import 'package:RUConnect_plus/Authentication/Login.dart';
import 'package:RUConnect_plus/MakeSomiti/somitiCreate.dart';
import 'package:RUConnect_plus/UpdatedPages/update.dart';
import 'package:RUConnect_plus/member/memberRegistrationpage.dart';

// ==================== SHIMMER WIDGETS ====================
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

class ShimmerButton extends StatelessWidget {
  final double height;
  const ShimmerButton({Key? key, required this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ShimmerLine(height: 20, widthFactor: 0.6),
        ),
      ),
    );
  }
}

// ==================== SEPARATE PAGES ====================

// 1. Home Page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.sizeOf(context).width > 768;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'RUConnect+',
          style: GoogleFonts.notoSansBengali(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: !isWeb,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelplinePage()),
              );
            },
            child: const Text(
              'Help',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppMakerAdmin()),
              );
            },
            tooltip: 'অ্যাডমিন',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWeb ? _buildWebHome(context) : _buildMobileHome(context),
    );
  }

  Widget _buildWebHome(BuildContext context) {
    return Row(
      children: [
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

  Widget _buildMobileHome(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'স্বাগতম রাজশাহী ইউনিভার্সিটি ক্যাম্পাসে',
            style: const TextStyle(
              fontFamily: 'CustomBangla2',
              fontSize: 30,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildButtons(context, isWeb: false),
        ],
      ),
    );
  }

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
            fontFamily: 'CustomBangla2',
            fontSize: 30,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        _buildButtons(context, isWeb: isWeb),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, {required bool isWeb}) {
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
        ElevatedButton.icon(
          style: buttonStyle,
          icon: Icon(Icons.login, size: iconSize),
          label: Text('Login', style: textStyle),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: buttonStyle,
          icon: Icon(Icons.add_box_outlined, size: iconSize),
          label: Text('সমিতি তৈরি করুন', style: textStyle),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SomitiChoicePage()),
            );
          },
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: buttonStyle,
          icon: Icon(Icons.person_add_outlined, size: iconSize),
          label: Text('জেলা, উপজেলা সমিতিতে যোগদান করুন', style: textStyle),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemberRegistrationPage()),
            );
          },
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: buttonStyle,
          icon: Icon(Icons.notifications_active_outlined, size: iconSize),
          label: Text('দেখুন কী কী আপডেট আসছে', style: textStyle),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RUConnectUpdatesApp()),
            );
          },
        ),
      ],
    );
  }
}

// 2. RU_Shop → Opens RUStore

// 8. About
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About RUConnect+')),
      body: const Center(
        child: Text('Official App of Rajshahi University\nMade with Flutter'),
      ),
    );
  }
}

// ==================== MAIN SOMITI PAGE ====================
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
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWeb = size.width > 768;

    return Scaffold(
      drawer: !isWeb ? _buildDrawer(context) : null,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'RUConnect+',
          style: GoogleFonts.notoSansBengali(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: !isWeb,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelplinePage()),
              );
            },
            child: const Text(
              'Help',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppMakerAdmin()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isWeb)
            Container(
              width: 260,
              color: Colors.blue.shade50,
              child: _buildDrawer(context),
            ),
          Expanded(
            child: _isLoading
                ? isWeb
                      ? _buildWebShimmer()
                      : _buildMobileShimmer()
                : isWeb
                ? _buildWebHome(context)
                : _buildMobileHome(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isWeb = MediaQuery.sizeOf(context).width > 768;

    final List<_DrawerItem> items = [
      _DrawerItem(title: 'Home', icon: Icons.home, page: const HomePage()),
      _DrawerItem(
        title: 'RU_Shop',
        icon: Icons.shopping_cart,
        page: CategoryPage(),
      ),
      _DrawerItem(
        title: 'PDF_Resources',
        icon: Icons.picture_as_pdf,
        page: const DriveExplorerScreen(),
      ),
      _DrawerItem(
        title: 'RU_Payment',
        icon: Icons.payment,
        page: const RUPaymentPage(),
      ),
      _DrawerItem(
        title: 'RU_Medical',
        icon: Icons.local_hospital,
        page: const RUMedicalPage(),
      ),
      _DrawerItem(title: 'RU_Info', icon: Icons.info, page: RUInfoPage()),
      _DrawerItem(
        title: 'RU_Blood',
        icon: Icons.bloodtype,
        page: const RUBloodPage(),
      ),
      _DrawerItem(
        title: 'About',
        icon: Icons.people,
        page: const AppMakerAdmin(),
      ),
      _DrawerItem(title: 'Login', icon: Icons.login, page: const LoginPage()),
      _DrawerItem(title: 'Logout', icon: Icons.logout, page: null),
    ];

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
          ...items.map(
            (item) => ListTile(
              leading: Icon(item.icon, color: Colors.blue.shade700),
              title: Text(
                item.title,
                style: GoogleFonts.notoSansBengali(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                if (!isWeb) Navigator.pop(context);
                if (item.page != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item.page!),
                  );
                } else if (item.title == 'Logout') {
                  _showLogoutDialog();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Logged out!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Shimmer
  Widget _buildWebShimmer() => Row(
    children: [
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
      Expanded(
        flex: 3,
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: _shimmerContent(true),
        ),
      ),
    ],
  );

  Widget _buildMobileShimmer() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        const Center(child: ShimmerImagePlaceholder()),
        const SizedBox(height: 16),
        const ShimmerLine(height: 24, widthFactor: 0.8),
        const SizedBox(height: 24),
        _shimmerButtons(false),
      ],
    ),
  );

  Widget _shimmerContent(bool isWeb) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ShimmerLine(height: 40, widthFactor: 0.6),
      const SizedBox(height: 12),
      ShimmerLine(height: 24, widthFactor: 0.8),
      const SizedBox(height: 40),
      _shimmerButtons(isWeb),
    ],
  );

  Widget _shimmerButtons(bool isWeb) => Column(
    children: List.generate(
      4,
      (_) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ShimmerButton(height: isWeb ? 64 : 54),
      ),
    ),
  );

  // Reuse HomePage layouts
  Widget _buildWebHome(BuildContext context) =>
      HomePage()._buildWebHome(context);
  Widget _buildMobileHome(BuildContext context) =>
      HomePage()._buildMobileHome(context);
}

class _DrawerItem {
  final String title;
  final IconData icon;
  final Widget? page;

  _DrawerItem({required this.title, required this.icon, this.page});
}
