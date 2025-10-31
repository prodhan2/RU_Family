// lib/SomitiDashboard.dart
import 'package:RUConnect_plus/member/Images/ImageGlarry.dart';
import 'package:RUConnect_plus/member/Student/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:RUConnect_plus/member/Teacher/TeachersDisplay.dart';
import 'package:RUConnect_plus/main.dart';
import 'package:RUConnect_plus/member/Student/studentlist.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this);
    _shimmerController.repeat(
      min: -0.5,
      max: 1.5,
      period: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.transparent, Colors.white60, Colors.transparent],
              stops: [
                (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                _shimmerController.value.clamp(0.0, 1.0),
                (_shimmerController.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class SomitiDashboard extends StatefulWidget {
  const SomitiDashboard({super.key});

  @override
  State<SomitiDashboard> createState() => _SomitiDashboardState();
}

class _SomitiDashboardState extends State<SomitiDashboard>
    with SingleTickerProviderStateMixin {
  // ----------  MEMORY CACHE ----------
  String? _cachedSomitiName;
  String? _cachedUserName;
  bool _isLoading = true; // Kept for skeleton control, but UI shows instantly
  double _drawerWidth = 280.0;
  int _currentIndex = 0;
  int _memberCount = 0;
  int _teacherCount = 0;
  int _imageCount = 0;
  int _somitiCount = 0;
  bool _isGridView = true;

  // Marquee animation
  late AnimationController _marqueeController;
  late Animation<double> _marqueeAnimation;
  late ScrollController _marqueeScrollController;

  // Indices for navigation
  static const int dashboardIndex = 0;
  static const int studentsIndex = 1;
  static const int teachersIndex = 2;
  static const int galleryIndex = 3;
  static const int noticesIndex = 4;
  static const int profileIndex = 5;

  @override
  void initState() {
    super.initState();
    _marqueeController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _marqueeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _marqueeController, curve: Curves.linear),
    );
    _marqueeController.addListener(_updateMarqueeScroll);
    _marqueeScrollController = ScrollController();
    _marqueeController.repeat();

    // Show UI immediately with skeleton placeholders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoading =
              false; // Instantly hide any potential loader, show skeleton
          _cachedSomitiName = 'Somiti Dashboard';
          _cachedUserName = 'User';
        });
        _loadCountsInBackground();
        _updateUserDataInBackground();
      }
    });
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    _marqueeScrollController.dispose();
    super.dispose();
  }

  void _updateMarqueeScroll() {
    if (_marqueeScrollController.hasClients) {
      final maxScrollExtent = _marqueeScrollController.position.maxScrollExtent;
      final scrollPosition = (maxScrollExtent / 2) * _marqueeAnimation.value;
      _marqueeScrollController.jumpTo(scrollPosition);
    }
  }

  // -----------------------------------------------------------------
  //  Background update for user data – no blocking
  // -----------------------------------------------------------------
  Future<void> _updateUserDataInBackground() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Try Firestore local cache
    final cacheSnap = await FirebaseFirestore.instance
        .collection('members')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get(const GetOptions(source: Source.cache));

    if (cacheSnap.docs.isNotEmpty) {
      final doc = cacheSnap.docs.first;
      final somitiName = doc['somitiName']?.toString() ?? 'Somiti Dashboard';
      final userName = doc['name']?.toString() ?? 'User';
      if (mounted &&
          (somitiName != _cachedSomitiName || userName != _cachedUserName)) {
        setState(() {
          _cachedSomitiName = somitiName;
          _cachedUserName = userName;
        });
        _loadCountsInBackground(); // Reload counts if somiti changed
      }
      return;
    }

    // 2. Fallback to server (will also fill cache)
    try {
      final serverSnap = await FirebaseFirestore.instance
          .collection('members')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get(const GetOptions(source: Source.server));

      final doc = serverSnap.docs.isNotEmpty ? serverSnap.docs.first : null;
      final somitiName = doc?['somitiName']?.toString() ?? 'Somiti Dashboard';
      final userName = doc?['name']?.toString() ?? 'User';

      if (mounted &&
          (somitiName != _cachedSomitiName || userName != _cachedUserName)) {
        setState(() {
          _cachedSomitiName = somitiName;
          _cachedUserName = userName;
        });
        _loadCountsInBackground(); // Reload counts if somiti changed
      }
    } catch (e) {
      debugPrint('User data error: $e');
    }
  }

  // -----------------------------------------------------------------
  //  Background load counts for collections matching somitiName
  // -----------------------------------------------------------------
  Future<void> _loadCountsInBackground() async {
    if (_cachedSomitiName == null || _cachedSomitiName == 'Somiti Dashboard')
      return;

    try {
      final somitiName = _cachedSomitiName!;

      // Future.wait for parallel queries
      final results = await Future.wait([
        // Members count
        FirebaseFirestore.instance
            .collection('members')
            .where('somitiName', isEqualTo: somitiName)
            .count()
            .get(),
        // Teachers count
        FirebaseFirestore.instance
            .collection('teachers')
            .where('somitiName', isEqualTo: somitiName)
            .count()
            .get(),
        // Images count
        FirebaseFirestore.instance
            .collection('images')
            .where('somitiName', isEqualTo: somitiName)
            .count()
            .get(),
        // Somitis count (for notices)
        FirebaseFirestore.instance
            .collection('somitis')
            .where('somitiName', isEqualTo: somitiName)
            .count()
            .get(),
      ]);

      if (mounted) {
        setState(() {
          _memberCount = results[0].count ?? 0;
          _teacherCount = results[1].count ?? 0;
          _imageCount = results[2].count ?? 0;
          _somitiCount = results[3].count ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Counts load error: $e');
    }
  }

  String getFirstChar(dynamic input) {
    final str = input?.toString().trim() ?? '';
    return str.isNotEmpty ? str[0].toUpperCase() : '?';
  }

  // -----------------------------------------------------------------
  //  Responsive Grid Delegate - For web/desktop only
  // -----------------------------------------------------------------
  SliverGridDelegate _getGridDelegate(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 4 : 3;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: screenWidth > 600 ? 1.2 : 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
    );
  }

  // -----------------------------------------------------------------
  //  Resize Handler
  // -----------------------------------------------------------------
  void _onDrawerResize(DragUpdateDetails details) {
    setState(() {
      _drawerWidth += details.delta.dx;
      _drawerWidth = _drawerWidth.clamp(200.0, 400.0);
    });
  }

  // -----------------------------------------------------------------
  //  Navigation Helper
  // -----------------------------------------------------------------
  void _navigateToPage(int index, BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    if (isWide) {
      setState(() => _currentIndex = index);
    } else {
      Widget page;
      switch (index) {
        case studentsIndex:
          page = const MySomitiMembersNameList();
          break;
        case teachersIndex:
          page = const TeachersBySomitiPage();
          break;
        case galleryIndex:
          page = ImageGalleryPageview(
            somitiName: _cachedSomitiName ?? 'Somiti Dashboard',
          );
          break;
        case noticesIndex:
          page = const NoticePage();
          break;
        case profileIndex:
          page = const ProfilePage();
          break;
        default:
          return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _OfflinePageWrapper(child: page)),
      );
    }
  }

  Widget _getBodyWidget(int index) {
    switch (index) {
      case studentsIndex:
        return const MySomitiMembersNameList(); // Assume body-only; adjust if needed
      case teachersIndex:
        return const TeachersBySomitiPage(); // Assume body-only
      case galleryIndex:
        return ImageGalleryPageview(
          somitiName: _cachedSomitiName ?? 'Somiti Dashboard',
        );
      case noticesIndex:
        return const NoticeBody();
      case profileIndex:
        return const ProfilePage(); // Assume body-only
      default:
        return const SizedBox();
    }
  }

  void _handleDrawerNavigation(int index, BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    if (index == dashboardIndex) {
      if (!isWide) {
        Navigator.pop(context);
      } else {
        setState(() => _currentIndex = dashboardIndex);
      }
      return;
    }
    if (!isWide) {
      Navigator.pop(context);
    }
    _navigateToPage(index, context);
  }

  // -----------------------------------------------------------------
  //  Shimmer Line for Skeleton
  // -----------------------------------------------------------------
  Widget _buildShimmerLine(
    BuildContext context, {
    double? width,
    double height = 14,
  }) {
    return ShimmerLoading(
      child: Container(
        height: height,
        width: width ?? MediaQuery.of(context).size.width * 0.4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  //  UI - Always show skeleton instantly, no loading spinner
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Always show UI with skeleton placeholders instantly, no full loading screen
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  getFirstChar(_cachedSomitiName),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _cachedSomitiName!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // Placeholder for notifications
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: MediaQuery.of(context).size.width <= 800
          ? _buildDrawer(context)
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // Web/Desktop: Fixed adjustable drawer on left, content on right
            return Row(
              children: [
                SizedBox(
                  width: _drawerWidth,
                  child: _buildFixedDrawer(context),
                ),
                // Resizer
                MouseRegion(
                  cursor: SystemMouseCursors.resizeRow,
                  child: GestureDetector(
                    onHorizontalDragUpdate: _onDrawerResize,
                    child: Container(
                      width: 4,
                      height: double.infinity,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _buildDashboardContent(context),
                      _getBodyWidget(studentsIndex),
                      _getBodyWidget(teachersIndex),
                      _getBodyWidget(galleryIndex),
                      _getBodyWidget(noticesIndex),
                      _getBodyWidget(profileIndex),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Mobile: Standard body with drawer
            return _buildDashboardContent(context);
          }
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth <= 800;
    final String marqueeText =
        _cachedSomitiName != null && _cachedSomitiName != 'Somiti Dashboard'
        ? 'Welcome to $_cachedSomitiName! Manage your somiti members, teachers, gallery, and notices effortlessly. Stay tuned for updates. '
        : 'Welcome! Manage your somiti dashboard.';

    final bool isUserLoading = _cachedUserName == 'User';
    final bool isCountsLoading =
        _memberCount == 0 &&
        _teacherCount == 0 &&
        _imageCount == 0 &&
        _somitiCount == 0;

    return Padding(
      padding: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with welcome or skeleton (professional touch)
          Card(
            elevation: 4,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.blue.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.dashboard,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUserLoading)
                          ShimmerLoading(
                            child: Container(
                              height: 22,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          )
                        else
                          Text(
                            'Welcome $_cachedUserName',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your somiti members and resources',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Marquee Notice Scrollbar (auto-scroll left to right effect via animation)
          if (_cachedSomitiName != null)
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  controller: _marqueeScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          marqueeText,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ),
                      // Duplicate for seamless loop
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          marqueeText,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Header for Quick Access
          Text(
            'Quick Access',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(height: 16),
            // Toggle for Grid/List View (only on web/desktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    _isGridView ? Icons.view_list_outlined : Icons.grid_view,
                    color: Colors.blue,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  tooltip: _isGridView
                      ? 'Switch to List View'
                      : 'Switch to Grid View',
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: isMobile
                ? ListView(
                    children: [
                      _modernListTile(
                        context,
                        'Student List',
                        Icons.people_outline,
                        Colors.blue,
                        studentsIndex,
                        countText: _memberCount > 0
                            ? '$_memberCount Students'
                            : null,
                        showSkeleton: _memberCount == 0,
                      ),
                      _modernListTile(
                        context,
                        'Teacher List',
                        Icons.school_outlined,
                        Colors.indigo,
                        teachersIndex,
                        countText: _teacherCount > 0
                            ? '$_teacherCount Teachers'
                            : null,
                        showSkeleton: _teacherCount == 0,
                      ),
                      _modernListTile(
                        context,
                        'Image Gallery',
                        Icons.photo_library_outlined,
                        Colors.green,
                        galleryIndex,
                        countText: _imageCount > 0
                            ? '$_imageCount Images'
                            : null,
                        showSkeleton: _imageCount == 0,
                      ),
                      _modernListTile(
                        context,
                        'Notice',
                        Icons.campaign_outlined,
                        Colors.orange,
                        noticesIndex,
                        countText: _somitiCount > 0
                            ? '$_somitiCount Notices'
                            : null,
                        showSkeleton: _somitiCount == 0,
                      ),
                    ],
                  )
                : _isGridView
                ? GridView(
                    gridDelegate: _getGridDelegate(context),
                    children: [
                      // ----------  Student List ----------
                      _modernButton(
                        context,
                        'Student List',
                        Icons.people_outline,
                        Colors.blue,
                        studentsIndex,
                        countText: _memberCount > 0
                            ? '$_memberCount Students'
                            : null,
                        showSkeleton: _memberCount == 0,
                      ),

                      // ----------  Teacher List ----------
                      _modernButton(
                        context,
                        'Teacher List',
                        Icons.school_outlined,
                        Colors.indigo,
                        teachersIndex,
                        countText: _teacherCount > 0
                            ? '$_teacherCount Teachers'
                            : null,
                        showSkeleton: _teacherCount == 0,
                      ),

                      // ----------  Image Gallery ----------
                      _modernButton(
                        context,
                        'Image Gallery',
                        Icons.photo_library_outlined,
                        Colors.green,
                        galleryIndex,
                        countText: _imageCount > 0
                            ? '$_imageCount Images'
                            : null,
                        showSkeleton: _imageCount == 0,
                      ),

                      // ----------  Notice ----------
                      _modernButton(
                        context,
                        'Notice',
                        Icons.campaign_outlined,
                        Colors.orange,
                        noticesIndex,
                        countText: _somitiCount > 0
                            ? '$_somitiCount Notices'
                            : null,
                        showSkeleton: _somitiCount == 0,
                      ),
                    ],
                  )
                : ListView(
                    children: [
                      _modernListTile(
                        context,
                        'Student List',
                        Icons.people_outline,
                        Colors.blue,
                        studentsIndex,
                        countText: _memberCount > 0
                            ? '$_memberCount Students'
                            : null,
                        showSkeleton: _memberCount == 0,
                      ),
                      _modernListTile(
                        context,
                        'Teacher List',
                        Icons.school_outlined,
                        Colors.indigo,
                        teachersIndex,
                        countText: _teacherCount > 0
                            ? '$_teacherCount Teachers'
                            : null,
                        showSkeleton: _teacherCount == 0,
                      ),
                      _modernListTile(
                        context,
                        'Image Gallery',
                        Icons.photo_library_outlined,
                        Colors.green,
                        galleryIndex,
                        countText: _imageCount > 0
                            ? '$_imageCount Images'
                            : null,
                        showSkeleton: _imageCount == 0,
                      ),
                      _modernListTile(
                        context,
                        'Notice',
                        Icons.campaign_outlined,
                        Colors.orange,
                        noticesIndex,
                        countText: _somitiCount > 0
                            ? '$_somitiCount Notices'
                            : null,
                        showSkeleton: _somitiCount == 0,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  //  Modern List Tile for List View
  // -----------------------------------------------------------------
  Widget _modernListTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    int targetIndex, {
    String? countText,
    bool showSkeleton = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => _navigateToPage(targetIndex, context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!showSkeleton && countText != null)
                      Text(
                        countText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (showSkeleton)
                      _buildShimmerLine(context, height: 14),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  //  Modern re-usable button with gradient and animation (for Grid)
  // -----------------------------------------------------------------
  Widget _modernButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    int targetIndex, {
    String? countText,
    bool showSkeleton = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: 6,
        shadowColor: color.withOpacity(0.2),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _navigateToPage(targetIndex, context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                if (!showSkeleton && countText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    countText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else if (showSkeleton) ...[
                  const SizedBox(height: 4),
                  _buildShimmerLine(context, height: 12, width: 60),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  //  Fixed Drawer for Web
  // -----------------------------------------------------------------
  Widget _buildFixedDrawer(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: _buildDrawerContent(context),
    );
  }

  // -----------------------------------------------------------------
  //  Drawer Content (shared between mobile and web)
  // -----------------------------------------------------------------
  Widget _buildDrawerContent(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'user@example.com';
    final photoUrl = user?.photoURL;
    final bool isUserLoading = _cachedUserName == 'User';

    return Column(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue, Colors.indigo],
            ),
            borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: photoUrl != null
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildAvatarFallback(),
                              )
                            : _buildAvatarFallback(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isUserLoading)
                            ShimmerLoading(
                              child: Container(
                                height: 18,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            )
                          else
                            Text(
                              _cachedUserName!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildDrawerTile(
                context,
                Icons.dashboard_outlined,
                'Dashboard',
                () => _handleDrawerNavigation(dashboardIndex, context),
                iconColor: Colors.blue,
                isSelected: _currentIndex == dashboardIndex,
              ),
              _buildDrawerTile(
                context,
                Icons.people_outline,
                'Members',
                () => _handleDrawerNavigation(studentsIndex, context),
                iconColor: Colors.blue,
                isSelected: _currentIndex == studentsIndex,
              ),
              _buildDrawerTile(
                context,
                Icons.photo_library_outlined,
                'Gallery',
                () => _handleDrawerNavigation(galleryIndex, context),
                iconColor: Colors.blue,
                isSelected: _currentIndex == galleryIndex,
              ),
              _buildDrawerTile(
                context,
                Icons.notifications_outlined,
                'Notices',
                () => _handleDrawerNavigation(noticesIndex, context),
                iconColor: Colors.blue,
                isSelected: _currentIndex == noticesIndex,
              ),
              const Divider(height: 1, thickness: 1),
              _buildDrawerTile(
                context,
                Icons.person_outline,
                'My Profile',
                () => _handleDrawerNavigation(profileIndex, context),
                iconColor: Colors.blue,
                isSelected: _currentIndex == profileIndex,
              ),
              _buildDrawerTile(
                context,
                Icons.logout_outlined,
                'Logout',
                () async {
                  final isWide = MediaQuery.of(context).size.width > 800;
                  if (!isWide) {
                    Navigator.pop(context);
                  }
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MyApp()),
                    );
                  }
                },
                iconColor: Colors.red,
                isSelected: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------
  //  Modern Drawer for Mobile
  // -----------------------------------------------------------------
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: _buildDrawerContent(context),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? iconColor,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor?.withOpacity(isSelected ? 0.15 : 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.blue, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.blue, size: 20)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.transparent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      tileColor: isSelected
          ? Colors.blue.withOpacity(0.05)
          : Colors.transparent,
      hoverColor: Colors.blue.withOpacity(0.05),
      selectedTileColor: Colors.blue.withOpacity(0.05),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Text(
          getFirstChar(_cachedUserName),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
//  Modernized Notice Page (full page for mobile)
// ---------------------------------------------------------------------
class NoticePage extends StatelessWidget {
  const NoticePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey[50],
    appBar: AppBar(
      title: const Text('Notices', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            // Placeholder for refresh
          },
        ),
      ],
    ),
    body: const NoticeBody(),
  );
}

// ---------------------------------------------------------------------
//  Notice Body (for web content area, without Scaffold/AppBar)
// ---------------------------------------------------------------------
class NoticeBody extends StatelessWidget {
  const NoticeBody({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      margin: const EdgeInsets.all(24),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign, size: 64, color: Colors.blue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Notices Coming Soon!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Stay tuned for upcoming announcements and updates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
