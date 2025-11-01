// ---------------- RU_SHOP - CATEGORY PAGE (WEB + MOBILE) ----------------
import 'dart:async';
import 'dart:convert';

import 'package:RUConnect_plus/BStoreApp/cardManager.dart';
import 'package:RUConnect_plus/BStoreApp/cartpage.dart';
import 'package:RUConnect_plus/BStoreApp/detailsshop.dart';
import 'package:RUConnect_plus/BStoreApp/storeapp.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:photo_view/photo_view.dart';
import 'package:marquee/marquee.dart';

class CategoryPage extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String selectedCategory = 'all';
  List<Category> categories = [];
  List<Product> products = [];
  List<BannerItem> banners = [];
  bool isOffline = false;
  List<Product> filteredProducts = [];
  TextEditingController searchController = TextEditingController();
  bool showSearchResults = false;
  String searchQuery = '';
  bool dataLoaded = false;
  String noticeText = '';

  // Pagination for Infinite Scroll
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // URLs
  static const String _sheetId = '14GLDraTX_xFp5XG-YBRE9Bmj4meQBk85qbVnMAuFVR0';
  final String categoryUrl = 'https://opensheet.elk.sh/$_sheetId/1';
  final String productUrl = 'https://opensheet.elk.sh/$_sheetId/2';
  final String bannerUrl = 'https://opensheet.elk.sh/$_sheetId/3';
  final String noticeUrl = 'https://opensheet.elk.sh/$_sheetId/5';

  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentBannerPage = 0;
  Timer? _sliderTimer;
  final CacheManager _cacheManager = CacheManager();
  final CartManager _cartManager = CartManager();

  // Responsive
  static const double _kDesktopBreakpoint = 1024;
  static const double _kSidebarWidth = 260;

  @override
  void initState() {
    super.initState();
    _loadFromCache();
    _loadAllData(silent: true);
    searchController.addListener(_onSearchChanged);
    _cartManager.addListener(() => setState(() {}));
    _cartManager.loadCart();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sliderTimer?.cancel();
    searchController.dispose();
    _cartManager.removeListener(() => setState(() {}));
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text;
      if (searchQuery.isEmpty) {
        showSearchResults = false;
        _resetPagination();
        _filterProducts();
      } else {
        showSearchResults = true;
        _resetPagination();
        filteredProducts = products
            .where(
              (p) =>
                  p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  p.description.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  void _resetPagination() {
    setState(() {
      _currentPage = 0;
      _loadingMore = false;
    });
  }

  void _filterProducts() {
    filteredProducts = selectedCategory == 'all'
        ? List.from(products)
        : products.where((p) => p.categoryId == selectedCategory).toList();
    _resetPagination();
  }

  int get _maxPages {
    if (filteredProducts.isEmpty) return 0;
    return (filteredProducts.length / _itemsPerPage).ceil();
  }

  List<Product> _getPaginatedProducts() {
    if (filteredProducts.isEmpty) return [];
    final int effectivePage = _currentPage % _maxPages;
    final int start = effectivePage * _itemsPerPage;
    final int end = start + _itemsPerPage;
    return end > filteredProducts.length
        ? filteredProducts.sublist(start)
        : filteredProducts.sublist(start, end);
  }

  void _loadMoreProducts() {
    if (_loadingMore || filteredProducts.isEmpty) return;
    setState(() => _loadingMore = true);
    Timer(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _currentPage++;
          _loadingMore = false;
        });
      }
    });
  }

  void _onScroll() {
    if (filteredProducts.isEmpty) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  // SCROLL PHYSICS: Always allow scrolling
  ScrollPhysics _getScrollPhysics() {
    return AlwaysScrollableScrollPhysics();
  }

  Future<void> _loadAllData({bool silent = false}) async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse(categoryUrl)),
        http.get(Uri.parse(productUrl)),
        http.get(Uri.parse(bannerUrl)),
        http.get(Uri.parse(noticeUrl)),
      ], eagerError: true);

      bool success = true;

      if (responses[0].statusCode == 200) {
        final data = json.decode(responses[0].body);
        if (data is List && data.isNotEmpty) {
          categories = data.map((c) => Category.fromJson(c)).toList();
          await _cacheManager.saveCategories(categories);
        }
      } else
        success = false;

      if (responses[1].statusCode == 200) {
        final data = json.decode(responses[1].body);
        if (data is List && data.isNotEmpty) {
          products = data.map((p) => Product.fromJson(p)).toList();
          await _cacheManager.saveProducts(products);
          _filterProducts();
        }
      } else
        success = false;

      if (responses[2].statusCode == 200) {
        final data = json.decode(responses[2].body);
        if (data is List) {
          banners = data
              .map((b) => BannerItem.fromJson(b))
              .where(
                (b) =>
                    b.show == true || b.show.toString().toLowerCase() == 'true',
              )
              .toList();
          if (banners.isNotEmpty) await _cacheManager.saveBanners(banners);
        }
      } else
        success = false;

      if (responses[3].statusCode == 200) {
        final data = json.decode(responses[3].body);
        if (data is List && data.isNotEmpty) {
          noticeText = data[0]['title'] ?? '';
        }
      } else
        success = false;

      if (!success) await _loadFromCache();

      setState(() {
        isOffline = !success;
        dataLoaded = true;
      });

      if (banners.isNotEmpty) _startAutoSlider();
    } catch (e) {
      if (!silent || categories.isEmpty || products.isEmpty)
        await _loadFromCache();
      setState(() => dataLoaded = true);
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final c = await _cacheManager.getCategories();
      final p = await _cacheManager.getProducts();
      final b = await _cacheManager.getBanners();

      if (c.isNotEmpty) categories = c;
      if (p.isNotEmpty) {
        products = p;
        _filterProducts();
      }
      if (b.isNotEmpty) banners = b;

      setState(() {
        isOffline = true;
        dataLoaded = true;
      });
      if (banners.isNotEmpty) _startAutoSlider();
    } catch (e) {
      setState(() => dataLoaded = true);
    }
  }

  void _startAutoSlider() {
    _sliderTimer?.cancel();
    _sliderTimer = Timer.periodic(Duration(seconds: 4), (_) {
      if (_pageController.hasClients && banners.isNotEmpty) {
        _currentBannerPage = (_currentBannerPage + 1) % banners.length;
        _pageController.animateToPage(
          _currentBannerPage,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  bool get _isDesktop =>
      MediaQuery.of(context).size.width >= _kDesktopBreakpoint;
  int _gridCount() => _isDesktop ? 4 : 2;

  @override
  Widget build(BuildContext context) {
    final displayed = _getPaginatedProducts();
    final total = filteredProducts.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: _isDesktop
            ? Row(
                children: [
                  Image.asset('assets/images/logo.png', height: 36),
                  SizedBox(width: 12),
                  Text(
                    'RU_SHOP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      height: 30,
                      child: dataLoaded && noticeText.isNotEmpty
                          ? Marquee(
                              text: noticeText,
                              style: TextStyle(
                                color: Colors.yellow[100],
                                fontSize: 14,
                              ),
                              scrollAxis: Axis.horizontal,
                              blankSpace: 100,
                              velocity: 40,
                              pauseAfterRound: Duration(seconds: 2),
                            )
                          : _shimmerMarqueeText(),
                    ),
                  ),
                ],
              )
            : Text(
                'RU_SHOP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
        centerTitle: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, size: 26),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CartPage()),
                ),
              ),
              if (_cartManager.totalItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _cartManager.totalItems > 99
                          ? '99+'
                          : '${_cartManager.totalItems}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(icon: Icon(Icons.notifications_none), onPressed: () {}),
          SizedBox(width: 12),
        ],
      ),
      body: _isDesktop
          ? _buildDesktopLayout(displayed, total)
          : _buildMobileLayout(displayed, total),
    );
  }

  Widget _shimmerMarqueeText() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(height: 20, color: Colors.white),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout(List<Product> items, int total) {
    return Row(
      children: [
        Container(
          width: _kSidebarWidth,
          color: Colors.grey[50],
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Image.asset('assets/images/logo.png', height: 50),
              ),
              Divider(height: 1),
              Expanded(
                child: dataLoaded && categories.isNotEmpty
                    ? ListView(
                        children: [
                          _sidebarTile('All Products', 'all', Icons.store),
                          ...categories.map(
                            (c) => _sidebarTile(c.name, c.id, Icons.category),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: 8,
                        itemBuilder: (_, __) => _shimmerSidebarTile(),
                      ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadAllData(silent: true),
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.all(24),
              physics: _getScrollPhysics(),
              children: [
                _buildSearchBar(),
                if (isOffline) _offlineBanner(),
                if (showSearchResults) _searchHeader(items.length, total),
                if (!showSearchResults && banners.isNotEmpty)
                  _bannerSlider(height: 250),
                SizedBox(height: 16),
                dataLoaded
                    ? items.isEmpty
                          ? _emptyWidget()
                          : _productGrid(items)
                    : _shimmerGrid(),
                if (_loadingMore) _loader(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sidebarTile(String title, String id, IconData icon) {
    final selected = selectedCategory == id;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Color(0xFFF85606) : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedTileColor: Colors.orange[50],
      onTap: () {
        setState(() {
          selectedCategory = id;
          showSearchResults = false;
          searchController.clear();
          _filterProducts();
        });
      },
    );
  }

  Widget _shimmerSidebarTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListTile(
        leading: Container(width: 24, height: 24, color: Colors.white),
        title: Container(
          height: 16,
          width: double.infinity,
          color: Colors.white,
        ),
      ),
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(List<Product> items, int total) {
    return RefreshIndicator(
      onRefresh: () => _loadAllData(silent: true),
      child: Column(
        children: [
          Padding(padding: EdgeInsets.all(16), child: _buildSearchBar()),
          if (isOffline) _offlineBanner(),
          if (showSearchResults) _searchHeader(items.length, total),
          if (!showSearchResults)
            Container(
              height: 56,
              child: dataLoaded && categories.isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      itemCount: categories.length + 1,
                      itemBuilder: (_, i) => i == 0
                          ? _chip('All', 'all')
                          : _chip(categories[i - 1].name, categories[i - 1].id),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      itemCount: 8,
                      itemBuilder: (_, __) => _shimmerChip(),
                    ),
            ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              physics: _getScrollPhysics(),
              children: [
                if (banners.isNotEmpty && !showSearchResults)
                  _bannerSlider(height: 140),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: dataLoaded
                      ? items.isEmpty
                            ? _emptyWidget()
                            : _productGrid(items)
                      : _shimmerGrid(),
                ),
                if (_loadingMore) _loader(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String id) {
    final sel = selectedCategory == id;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 13)),
        selected: sel,
        selectedColor: Color(0xFFF85606),
        checkmarkColor: Colors.white,
        onSelected: (_) {
          setState(() {
            selectedCategory = id;
            showSearchResults = false;
            searchController.clear();
            _filterProducts();
          });
        },
      ),
    );
  }

  Widget _shimmerChip() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 32,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ==================== BANNER SLIDER (CLICK → FULLSCREEN) ====================
  Widget _bannerSlider({required double height}) {
    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: PageView.builder(
        controller: _pageController,
        itemCount: banners.length,
        onPageChanged: (i) => setState(() => _currentBannerPage = i),
        itemBuilder: (_, i) {
          final b = banners[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenBannerPage(imageUrl: b.imageUrl),
              ),
            ),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: b.imageUrl.trim(),
                  fit: BoxFit.cover,
                  memCacheHeight:
                      (height * MediaQuery.of(context).devicePixelRatio)
                          .round(),
                  placeholder: (_, __) =>
                      Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                  errorWidget: (_, __, ___) =>
                      Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    final showing = _getPaginatedProducts().length;
    final total = filteredProducts.length;
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search in RU_SHOP...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            showSearchResults = false;
                            _filterProducts();
                          });
                        },
                      )
                    : null,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (total > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '$showing/$total',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== PRODUCT CARD ====================
  Widget _productCard(Product p) {
    final price =
        double.tryParse(p.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    final discount = double.tryParse(p.discount) ?? 0;
    final hasDiscount = discount > 0;
    final finalPrice = price - (price * discount / 100);
    final img = p.image.split(',').first.trim();
    final imageUrl = img.isNotEmpty ? img : 'invalid';
    final double imageHeight = _isDesktop ? 160 : 100;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailsPage(product: p)),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stack for image with floating badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheHeight:
                        (imageHeight * MediaQuery.of(context).devicePixelRatio)
                            .round(),
                    placeholder: (_, __) => _shimmerImage(height: imageHeight),
                    errorWidget: (_, __, ___) => Image.asset(
                      'assets/images/logo.png',
                      height: imageHeight,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Discount badge - top left (only if hasDiscount)
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isDesktop ? 8 : 6,
                        vertical: _isDesktop ? 4 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${discount.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: _isDesktop ? 12 : 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Rating badge - bottom left
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isDesktop ? 8 : 6,
                      vertical: _isDesktop ? 4 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: _isDesktop ? 16 : 12,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 2),
                        Text(
                          p.rating,
                          style: TextStyle(
                            fontSize: _isDesktop ? 12 : 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Stock badge - top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isDesktop ? 8 : 6,
                      vertical: _isDesktop ? 3 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Stock: ${p.stock}',
                      style: TextStyle(
                        fontSize: _isDesktop ? 11 : 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              p.name,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Row(
              children: [
                if (hasDiscount)
                  Text(
                    '৳${price.toStringAsFixed(0)} ',
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                Text(
                  '৳${finalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF85606),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SHIMMER ====================
  Widget _shimmerImage({double? height}) => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(color: Colors.white, height: height ?? 100),
  );
  Widget _shimmerText({double width = double.infinity, double height = 14}) =>
      Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          color: Colors.white,
          width: width,
          height: height,
          margin: EdgeInsets.only(bottom: 4),
        ),
      );

  Widget _shimmerBadge() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      height: 20,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );

  Widget _shimmerGrid() {
    final double shimmerImageHeight = _isDesktop ? 160 : 100;
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCount(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stack for shimmer image with badge placeholders
            Stack(
              children: [
                _shimmerImage(height: shimmerImageHeight),
                // Discount placeholder - top left
                Positioned(top: 8, left: 8, child: _shimmerBadge()),
                // Rating placeholder - bottom left
                Positioned(bottom: 8, left: 8, child: _shimmerBadge()),
                // Stock placeholder - top right
                Positioned(top: 8, right: 8, child: _shimmerBadge()),
              ],
            ),
            SizedBox(height: 8),
            _shimmerText(width: double.infinity, height: 16),
            _shimmerText(width: 80, height: 14),
            SizedBox(height: 4),
            Row(
              children: [
                _shimmerText(width: 50, height: 12),
                Spacer(),
                _shimmerText(width: 50, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _productGrid(List<Product> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCount(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _productCard(items[i]),
    );
  }

  Widget _loader() => Padding(
    padding: EdgeInsets.all(16),
    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
  Widget _offlineBanner() => Container(
    margin: EdgeInsets.all(16),
    padding: EdgeInsets.all(10),
    color: Colors.orange[50],
    child: Row(
      children: [
        Icon(Icons.wifi_off, size: 16),
        SizedBox(width: 6),
        Text('Offline Mode', style: TextStyle(fontSize: 12)),
      ],
    ),
  );
  Widget _searchHeader(int s, int t) => Padding(
    padding: EdgeInsets.all(16),
    child: Text(
      'Results: $s of $t',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  );
  Widget _emptyWidget() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off, size: 70, color: Colors.grey[400]),
        SizedBox(height: 12),
        Text('No products found', style: TextStyle(color: Colors.grey[600])),
      ],
    ),
  );
}

// ==================== FULL SCREEN BANNER ====================
class FullScreenBannerPage extends StatelessWidget {
  final String imageUrl;
  const FullScreenBannerPage({Key? key, required this.imageUrl})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(imageUrl.trim()),
          loadingBuilder: (context, event) =>
              Center(child: CircularProgressIndicator(color: Colors.white)),
          errorBuilder: (context, obj, stack) =>
              Center(child: Icon(Icons.error, color: Colors.white)),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
      ),
    );
  }
}
