// main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const RUConnectUpdatesApp());
}

class RUConnectUpdatesApp extends StatelessWidget {
  const RUConnectUpdatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RU Connect+ Updates',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: GoogleFonts.notoSansBengali().fontFamily,
      ),
      home: const UpdatesPage(),
    );
  }
}

// ==================== MODEL ====================
class UpdateItem {
  final String title;
  final String description;
  final String icon;
  final String color;
  final double progress;

  UpdateItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.progress,
  });

  factory UpdateItem.fromJson(Map<String, dynamic> json) {
    return UpdateItem(
      title: json['Title'] ?? 'অজানা',
      description: json['Description'] ?? 'বিবরণ নেই',
      icon: json['Icon'] ?? 'info',
      color: json['Color'] ?? 'blue',
      progress: double.tryParse(json['Progress']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'Title': title,
    'Description': description,
    'Icon': icon,
    'Color': color,
    'Progress': progress,
  };
}

// ==================== MAIN PAGE ====================
class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  List<UpdateItem> updates = [];
  bool loading = true;
  String? error;
  bool _isRefreshing = false;

  final String apiUrl =
      'https://opensheet.elk.sh/1uFl4IR4mFtO7rwT8aTnnWzw4EKpiSdb5plUedQZ9P18/1';
  static const String _cacheKey = 'cached_updates';
  static const String _lastUpdateKey = 'last_update_time';

  @override
  void initState() {
    super.initState();
    _loadCachedData(); // প্রথমে ক্যাশ লোড
    fetchUpdates(); // তারপর API থেকে
  }

  // ==================== CACHING ====================
  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);

    if (cachedJson != null) {
      try {
        final List data = json.decode(cachedJson);
        setState(() {
          updates = data.map((e) => UpdateItem.fromJson(e)).toList();
          loading = false;
        });
      } catch (e) {
        debugPrint('ক্যাশ পার্স করতে সমস্যা: $e');
      }
    }
  }

  Future<void> _saveToCache(List<UpdateItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = json.encode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheKey, jsonData);
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ==================== FETCH FROM API ====================
  Future<void> fetchUpdates({bool isPullToRefresh = false}) async {
    if (!isPullToRefresh && !_isRefreshing) {
      setState(() => _isRefreshing = true);
    }

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final newUpdates = data.map((e) => UpdateItem.fromJson(e)).toList();

        // ক্যাশে সেভ করুন
        await _saveToCache(newUpdates);

        if (mounted) {
          setState(() {
            updates = newUpdates;
            error = null;
          });
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (updates.isEmpty) {
        setState(() {
          error = 'ইন্টারনেট সংযোগ নেই। ক্যাশ থেকে দেখানো হচ্ছে।';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('আপডেট চেক করতে ব্যর্থ। ক্যাশ দেখানো হচ্ছে।'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'রিফ্রেশ',
              onPressed: () => fetchUpdates(isPullToRefresh: true),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  // ==================== ICON & COLOR MAPPING ====================
  IconData getIcon(String name) {
    final map = {
      'local_hospital': Icons.local_hospital,
      'favorite': Icons.favorite,
      'payment': Icons.payment,
      'store': Icons.store,
      'info': Icons.info,
      'menu_book': Icons.menu_book,
      'home': Icons.home,
      'directions_bus': Icons.directions_bus,
      'notifications_active': Icons.notifications_active,
      'school': Icons.school,
      'bloodtype': Icons.bloodtype,
      'account_balance': Icons.account_balance,
      'shopping_cart': Icons.shopping_cart,
      'wifi': Icons.wifi,
      'event': Icons.event,
      'security': Icons.security,
    };
    return map[name.toLowerCase().trim()] ?? Icons.info;
  }

  Color getColor(String name) {
    final map = {
      'red': Colors.red,
      'green': Colors.green,
      'orange': Colors.orange,
      'blue': Colors.blue,
      'indigo': Colors.indigo,
      'brown': Colors.brown,
      'teal': Colors.teal,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'red.shade400': Colors.red.shade400,
    };
    return map[name.toLowerCase().trim()] ?? Colors.blue;
  }

  // ==================== UI BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Text(
          'RU Connect+ আপডেটস',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing
                ? null
                : () => fetchUpdates(isPullToRefresh: true),
            tooltip: 'রিফ্রেশ',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => fetchUpdates(isPullToRefresh: true),
        child: loading
            ? _buildLoading()
            : error != null && updates.isEmpty
            ? _buildError()
            : _buildUpdateList(isWeb),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 16),
          Text('আপডেট লোড হচ্ছে...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => fetchUpdates(isPullToRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('আবার চেষ্টা করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateList(bool isWeb) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isWeb ? 40 : 20),
            child: Column(
              children: [
                Text(
                  'কী কী নতুন ফিচার আসছে?',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: isWeb ? 34 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'RUconnect+ এর সর্বশেষ আপডেট ও ভবিষ্যৎ পরিকল্পনা',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // ক্যাশ টাইম দেখানো
                FutureBuilder<String>(
                  future: _getLastUpdateTime(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        'শেষ আপডেট: ${snapshot.data}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      );
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 16),
          sliver: isWeb
              ? SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 1.4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildUpdateCard(updates[index]),
                    childCount: updates.length,
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildUpdateCard(updates[index]),
                    ),
                    childCount: updates.length,
                  ),
                ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Future<String> _getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastUpdateKey);
    if (timestamp == null) return 'কখনো আপডেট হয়নি';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'এইমাত্র';
    if (diff.inHours < 1) return '${diff.inMinutes} মিনিট আগে';
    if (diff.inDays < 1) return '${diff.inHours} ঘণ্টা আগে';
    return '${diff.inDays} দিন আগে';
  }

  Widget _buildUpdateCard(UpdateItem u) {
    final color = getColor(u.color);
    final icon = getIcon(u.icon);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 8,
        shadowColor: color.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.08), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      u.title,
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                u.description,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: u.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(u.progress * 100).toInt()}% সম্পন্ন',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'শীঘ্রই আসছে',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
