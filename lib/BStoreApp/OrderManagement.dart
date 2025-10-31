// modern_order_management_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModernOrderManagementPage extends StatefulWidget {
  const ModernOrderManagementPage({Key? key}) : super(key: key);

  @override
  _ModernOrderManagementPageState createState() =>
      _ModernOrderManagementPageState();
}

class _ModernOrderManagementPageState extends State<ModernOrderManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _refreshOrders() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  bool _matchesSearch(Map<String, dynamic> order) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    final name = (order['userName'] ?? '').toLowerCase();
    final phone = (order['userPhone'] ?? '').toLowerCase();
    final items = order['items'] as List?;
    final hasProductMatch =
        items?.any(
          (item) =>
              (item['name'] as String?)?.toLowerCase().contains(query) ?? false,
        ) ??
        false;

    return name.contains(query) || phone.contains(query) || hasProductMatch;
  }

  // 🔥 Bangla Date Formatter
  String _formatDateTimeBangla(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    // Helper: 24h to 12h + AM/PM
    String _formatTime(DateTime dt) {
      int hour = dt.hour;
      String ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      String minute = dt.minute.toString().padLeft(2, '0');
      return '${_toBanglaDigits(hour.toString())}:${_toBanglaDigits(minute)} $ampm';
    }

    // Less than 1 hour
    if (diff.inMinutes < 60) {
      return '${_toBanglaDigits(diff.inMinutes.toString())} মিনিট আগে • ${_formatTime(dateTime)}';
    }

    // Less than 24 hours
    if (diff.inHours < 24) {
      return '${_toBanglaDigits(diff.inHours.toString())} ঘণ্টা আগে • ${_formatTime(dateTime)}';
    }

    // Yesterday
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (dateTime.day == yesterday.day &&
        dateTime.month == yesterday.month &&
        dateTime.year == yesterday.year) {
      return 'গতকাল • ${_formatTime(dateTime)}';
    }

    // Today
    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return 'আজ • ${_formatTime(dateTime)}';
    }

    // Days ago < 7
    if (diff.inDays < 7) {
      return '${_toBanglaDigits(diff.inDays.toString())} দিন আগে • ${_formatTime(dateTime)}';
    }

    // Full Bangla date
    final months = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ];
    return '${_toBanglaDigits(dateTime.day.toString())} ${months[dateTime.month - 1]}, ${_toBanglaDigits(dateTime.year.toString())} • ${_formatTime(dateTime)}';
  }

  // 🔥 Convert English digits to Bangla
  String _toBanglaDigits(String input) {
    final english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    final bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var result = input;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], bangla[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFFF85606),
        elevation: 0,
        title: Text(
          'অর্ডার ম্যানেজমেন্ট',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshOrders,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'নাম, ফোন বা প্রোডাক্ট দিয়ে খুঁজুন...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: Color(0xFFF85606)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                ),
              ),
            ),
            // Orders List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'কোনো অর্ডার নেই',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  final allOrders = snapshot.data!.docs;
                  final filteredOrders = allOrders
                      .where(
                        (doc) =>
                            _matchesSearch(doc.data() as Map<String, dynamic>),
                      )
                      .toList();

                  if (filteredOrders.isEmpty) {
                    return Center(
                      child: Text(
                        'কোনো অর্ডার পাওয়া যায়নি',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final orderDoc = filteredOrders[index];
                      final order = orderDoc.data() as Map<String, dynamic>;
                      final orderId = orderDoc.id;
                      final status = order['status'] ?? 'pending';
                      final timestamp = order['createdAt'] as Timestamp?;

                      return _buildOrderCard(
                        context,
                        order,
                        orderId,
                        timestamp,
                        status,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    Map<String, dynamic> order,
    String orderId,
    Timestamp? timestamp,
    String status,
  ) {
    final items = (order['items'] as List?) ?? [];
    final total = (order['totalPrice'] ?? 0.0) as double;
    final shippingCharge =
        double.tryParse(order['shippingCharge'] ?? '0') ?? 0.0;
    final subtotal = total - shippingCharge;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID + Time + Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'অর্ডার #${orderId.substring(0, 6).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF85606),
                        ),
                      ),
                      if (timestamp != null)
                        Text(
                          _formatDateTimeBangla(timestamp),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            Divider(height: 20, color: Colors.grey[300]),

            // Customer Info
            Text(
              'গ্রাহকের তথ্য:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${order['userName'] ?? 'N/A'}\n',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text:
                        'ফোন: +880 ${order['userPhone']?.replaceAll(RegExp(r'^0'), '') ?? 'N/A'}\n',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  TextSpan(
                    text: 'ঠিকানা: ${order['userAddress'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Area & Shipping
            Row(
              children: [
                Text('এলাকা: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${order['area'] ?? 'N/A'}'),
                Spacer(),
                Text('শিপিং: '),
                Text('৳${_toBanglaDigits(shippingCharge.toStringAsFixed(2))}'),
              ],
            ),
            SizedBox(height: 12),

            // Items List
            Text(
              'প্রোডাক্ট (${items.length}):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            ...List.generate(items.length, (i) {
              final item = items[i] as Map<String, dynamic>;
              final name = item['name'] ?? 'Unknown';
              final qty = item['quantity'] ?? 1;
              final price = (item['price'] ?? 0.0) as double;
              return Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('• $name', style: TextStyle(fontSize: 14)),
                    ),
                    Text('x$qty', style: TextStyle(color: Colors.grey[700])),
                    SizedBox(width: 12),
                    Text(
                      '৳${_toBanglaDigits(price.toStringAsFixed(2))}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF85606),
                      ),
                    ),
                  ],
                ),
              );
            }),
            Divider(height: 20, color: Colors.grey[300]),

            // Payment Details
            Text(
              'পেমেন্ট তথ্য:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'মেথড: ${order['paymentMethodName'] ?? 'N/A'}\n',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (order['mobileNumber'] != null)
                    TextSpan(
                      text: 'মোবাইল: +880 ${order['mobileNumber']}\n',
                      style: TextStyle(color: Colors.blue),
                    ),
                  if (order['transactionId'] != null)
                    TextSpan(
                      text: 'ট্রানজেকশন ID: ${order['transactionId']}\n',
                      style: TextStyle(color: Colors.purple),
                    ),
                ],
              ),
            ),
            SizedBox(height: 10),

            // Total
            Row(
              children: [
                Text(
                  'মোট: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '৳${_toBanglaDigits(total.toStringAsFixed(2))}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFF85606),
                  ),
                ),
                Spacer(),
                // Action Buttons
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _editOrderStatus(context, orderId, status),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteOrder(context, orderId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        label = 'অপেক্ষারত';
        break;
      case 'confirmed':
        color = Colors.blue;
        label = 'নিশ্চিত';
        break;
      case 'shipped':
        color = Colors.purple;
        label = 'পাঠানো হয়েছে';
        break;
      case 'delivered':
        color = Colors.green;
        label = 'ডেলিভারি হয়েছে';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'বাতিল';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _editOrderStatus(
    BuildContext context,
    String orderId,
    String currentStatus,
  ) {
    final options = [
      {'key': 'pending', 'label': 'অপেক্ষারত'},
      {'key': 'confirmed', 'label': 'নিশ্চিত'},
      {'key': 'shipped', 'label': 'পাঠানো হয়েছে'},
      {'key': 'delivered', 'label': 'ডেলিভারি হয়েছে'},
      {'key': 'cancelled', 'label': 'বাতিল'},
    ];
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'স্ট্যাটাস আপডেট করুন',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...options.map((opt) {
              return ListTile(
                title: Text(opt['label']!),
                trailing: currentStatus.toLowerCase() == opt['key']
                    ? Icon(Icons.check, color: Color(0xFFF85606))
                    : null,
                onTap: () {
                  if (opt['key'] != currentStatus.toLowerCase()) {
                    FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId)
                        .update({'status': opt['key']});
                  }
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _deleteOrder(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('অর্ডার মুছে ফেলুন?'),
        content: Text('এই অর্ডারটি মুছে ফেললে তা পুনরুদ্ধার করা যাবে না।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('orders')
                  .doc(orderId)
                  .delete();
              Navigator.pop(ctx);
            },
            child: Text('মুছুন'),
          ),
        ],
      ),
    );
  }
}
