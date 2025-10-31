// ---------------- PAYMENT PAGE (LOGIN REQUIRED → FIREBASE SAVE) ----------------
import 'dart:convert';
import 'package:RUConnect_plus/BStoreApp/cardManager.dart';
import 'package:RUConnect_plus/BStoreApp/login.dart';
import 'package:RUConnect_plus/BStoreApp/shippingrules.dart' show ShippingRule;
import 'package:RUConnect_plus/BStoreApp/storeapp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPage extends StatefulWidget {
  final Product? product;
  final List<CartItem>? products;
  final int? quantity;
  final double totalPrice;
  final String shippingArea;
  final double shippingCharge;
  final String productId;
  final ShippingRule shippingRule;

  const PaymentPage({
    Key? key,
    this.product,
    this.products,
    this.quantity,
    required this.totalPrice,
    required this.shippingArea,
    required this.shippingCharge,
    required this.productId,
    required this.shippingRule,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPaymentMethod = 'bkash';
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _transactionController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _areaController.text = widget.shippingArea;
  }

  bool get _isWide => MediaQuery.of(context).size.width > 900;

  // ===================================================================
  // ============================== BUILD ==============================
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    final subtotal = widget.totalPrice - widget.shippingCharge;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: _isProcessing
          ? _buildProcessingUI()
          : _isWide
          ? _buildWebLayout(subtotal)
          : _buildMobileLayout(subtotal),
    );
  }

  // ============================= WEB LAYOUT =============================
  Widget _buildWebLayout(double subtotal) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(subtotal),
                  const SizedBox(height: 24),
                  _buildAddressCard(),
                  const SizedBox(height: 24),
                  _buildPaymentMethodsCard(),
                  const SizedBox(height: 24),
                  if (_selectedPaymentMethod != 'card' &&
                      _selectedPaymentMethod != 'cod')
                    _buildWalletDetails(),
                  if (_selectedPaymentMethod == 'cod') _buildCODInstructions(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
        Expanded(flex: 2, child: _buildStickyCheckoutPanel(subtotal)),
      ],
    );
  }

  // ============================= MOBILE LAYOUT =============================
  Widget _buildMobileLayout(double subtotal) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(subtotal),
                const SizedBox(height: 20),
                _buildAddressCard(),
                const SizedBox(height: 20),
                _buildPaymentMethodsCard(),
                const SizedBox(height: 20),
                if (_selectedPaymentMethod != 'card' &&
                    _selectedPaymentMethod != 'cod')
                  _buildWalletDetails(),
                if (_selectedPaymentMethod == 'cod') _buildCODInstructions(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        _buildConfirmButton(),
      ],
    );
  }

  // ============================= STICKY CHECKOUT PANEL (WEB) =============================
  Widget _buildStickyCheckoutPanel(double subtotal) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Total',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _priceRow('Subtotal:', '৳${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _priceRow(
            'Shipping (${widget.shippingArea}):',
            '৳${widget.shippingCharge.toStringAsFixed(2)}',
          ),
          const Divider(height: 20),
          _priceRow(
            'Total:',
            '৳${widget.totalPrice.toStringAsFixed(2)}',
            isTotal: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF85606),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: Text(
                'Confirm Payment - ৳${widget.totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================= REUSABLE CARDS =============================
  Widget _buildSummaryCard(double subtotal) {
    return _InfoCard(
      title: 'Order Summary',
      icon: Icons.shopping_bag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.product != null) _buildSingleProductSummary(),
          if (widget.products != null) _buildCartProductsSummary(),
          const Divider(height: 24),
          _priceRow('Subtotal:', '৳${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          _priceRow(
            'Shipping (${widget.shippingArea}):',
            '৳${widget.shippingCharge.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 4),
          _priceRow(
            'Total:',
            '৳${widget.totalPrice.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return _InfoCard(
      title: 'Delivery Address',
      icon: Icons.location_on_outlined,
      child: Column(
        children: [
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '01XXXXXXXXX',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
              prefixText: '+880 ',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _areaController,
            decoration: const InputDecoration(
              labelText: 'Delivery Area',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
            enabled: false,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _streetController,
            decoration: const InputDecoration(
              labelText: 'Full Address (House, Road, etc.)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return _InfoCard(
      title: 'Payment Method',
      icon: Icons.payment,
      child: Column(
        children: [
          _buildPaymentMethod(
            'bkash',
            'bKash',
            Icons.phone_android,
            Colors.pink,
          ),
          _buildPaymentMethod(
            'nagad',
            'Nagad',
            Icons.phone_android,
            Colors.red,
          ),
          _buildPaymentMethod(
            'rocket',
            'Rocket',
            Icons.phone_android,
            Colors.purple,
          ),
          _buildPaymentMethod(
            'card',
            'Credit/Debit Card',
            Icons.credit_card,
            Colors.blue,
          ),
          _buildPaymentMethod(
            'cod',
            'Cash on Delivery',
            Icons.local_shipping,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildWalletDetails() {
    return _InfoCard(
      title: 'Payment Details',
      icon: Icons.account_balance_wallet,
      child: Column(
        children: [
          TextField(
            controller: _transactionController,
            decoration: const InputDecoration(
              labelText: 'Transaction ID',
              hintText: 'Enter transaction ID',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.receipt),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Text(
              _getInstruction(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCODInstructions() {
    return _InfoCard(
      title: 'Cash on Delivery',
      icon: Icons.info_outline,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Text(
          widget.shippingRule.codInstructions.isNotEmpty
              ? widget.shippingRule.codInstructions
              : 'Pay cash when the product is delivered.',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.green[800]),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _confirmPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF85606),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Confirm Payment - ৳${widget.totalPrice.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // ============================== HELPERS ==============================
  // ===================================================================
  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFFF85606) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(
    String value,
    String title,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      trailing: Radio<String>(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
        activeColor: const Color(0xFFF85606),
      ),
      onTap: () => setState(() => _selectedPaymentMethod = value),
    );
  }

  String _getInstruction() {
    return switch (_selectedPaymentMethod) {
      'bkash' =>
        widget.shippingRule.bKashInstructions.isNotEmpty
            ? widget.shippingRule.bKashInstructions
            : 'Send to: ${widget.shippingRule.contactNumber}',
      'nagad' =>
        widget.shippingRule.nagadInstructions.isNotEmpty
            ? widget.shippingRule.nagadInstructions
            : 'Send to: ${widget.shippingRule.contactNumber}',
      'rocket' =>
        widget.shippingRule.rocketInstructions.isNotEmpty
            ? widget.shippingRule.rocketInstructions
            : 'Send to: ${widget.shippingRule.contactNumber}',
      'cod' =>
        widget.shippingRule.codInstructions.isNotEmpty
            ? widget.shippingRule.codInstructions
            : 'Pay cash on delivery.',
      _ => '',
    };
  }

  Widget _buildSingleProductSummary() {
    final p = widget.product!;
    final original =
        double.tryParse(p.price.replaceAll(RegExp(r'[৳,]'), '')) ?? 0;
    final discount = double.tryParse(p.discount) ?? 0;
    final priceAfter = original * (1 - discount / 100);
    final qty = widget.quantity ?? 1;
    return _ProductRow(
      imageUrl: p.image.split(',').first.trim(),
      name: p.name,
      qty: qty,
      price: priceAfter * qty,
      original: original * qty,
      hasDiscount: discount > 0,
    );
  }

  Widget _buildCartProductsSummary() {
    return Column(
      children: widget.products!.map((item) {
        final total = _calculateItemTotal(item);
        return _ProductRow(
          imageUrl: item.product.image.split(',').first.trim(),
          name: item.product.name,
          qty: item.quantity,
          price: total,
          original: 0,
          hasDiscount: false,
        );
      }).toList(),
    );
  }

  double _calculateItemTotal(CartItem item) {
    final original =
        double.tryParse(item.product.price.replaceAll(RegExp(r'[৳,]'), '')) ??
        0;
    final discount = double.tryParse(item.product.discount) ?? 0;
    return original * (1 - discount / 100) * item.quantity;
  }

  Widget _InfoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFF85606), size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _ProductRow({
    required String imageUrl,
    required String name,
    required int qty,
    required double price,
    required double original,
    required bool hasDiscount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: $qty',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '৳${price.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF85606),
                ),
              ),
              if (hasDiscount && original > 0)
                Text(
                  '৳${original.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // ========================= CONFIRM PAYMENT (LOGIN + FIREBASE) =========================
  // ===================================================================
  void _confirmPayment() async {
    // Validation
    if (_phoneController.text.trim().length != 11 ||
        !_phoneController.text.startsWith('01')) {
      _showError('Valid 11-digit phone number required');
      return;
    }
    if (_streetController.text.trim().isEmpty) {
      _showError('Full address is required');
      return;
    }
    if (_selectedPaymentMethod != 'cod' && _selectedPaymentMethod != 'card') {
      if (_transactionController.text.trim().isEmpty) {
        _showError('Transaction ID is required');
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (result != true || FirebaseAuth.instance.currentUser == null) {
        _showError('অর্ডার করতে লগইন প্রয়োজন');
        return;
      }
    }

    setState(() => _isProcessing = true);
    try {
      await _saveToFirebase();
      if (widget.products != null) CartManager().clearCart();
      _showOrderSuccessDialog();
    } catch (e) {
      _showError('অর্ডার সেভ করতে সমস্যা: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ===================================================================
  // ========================= SAVE TO FIREBASE =========================
  // ===================================================================
  Future<void> _saveToFirebase() async {
    final user = FirebaseAuth.instance.currentUser!;
    final items = <Map<String, dynamic>>[];

    if (widget.product != null) {
      final p = widget.product!;
      final price =
          double.tryParse(p.price.replaceAll(RegExp(r'[৳,]'), '')) ?? 0;
      final discount = double.tryParse(p.discount) ?? 0;
      final qty = widget.quantity ?? 1;
      items.add({
        'productId': p.id,
        'name': p.name,
        'quantity': qty,
        'price': price * (1 - discount / 100) * qty,
        'image': p.image,
      });
    } else if (widget.products != null) {
      for (var item in widget.products!) {
        final price =
            double.tryParse(
              item.product.price.replaceAll(RegExp(r'[৳,]'), ''),
            ) ??
            0;
        final discount = double.tryParse(item.product.discount) ?? 0;
        items.add({
          'productId': item.product.id,
          'name': item.product.name,
          'quantity': item.quantity,
          'price': price * (1 - discount / 100) * item.quantity,
          'image': item.product.image,
        });
      }
    }

    final paymentDetails =
        _selectedPaymentMethod != 'cod' && _selectedPaymentMethod != 'card'
        ? {
            'mobileNumber': _phoneController.text.trim(),
            'transactionId': _transactionController.text.trim(),
          }
        : {};

    await FirebaseFirestore.instance.collection('orders').add({
      'userId': user.uid,
      'userEmail': user.email,
      'userPhone': _phoneController.text.trim(),
      'userAddress':
          '${_streetController.text.trim()}, ${_areaController.text.trim()}',
      'deliveryArea': _areaController.text.trim(),
      'shippingCharge': widget.shippingCharge,
      'paymentMethod': _selectedPaymentMethod,
      'paymentMethodName': _getPaymentMethodName(_selectedPaymentMethod),
      'totalPrice': widget.totalPrice,
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
      'items': items,
      ...paymentDetails,
    });
  }

  // ===================================================================
  // ========================= SUCCESS DIALOG ==========================
  // ===================================================================
  void _showOrderSuccessDialog() {
    final itemsText = widget.product != null
        ? '${widget.product!.name} × ${widget.quantity ?? 1}'
        : widget.products!
              .map((e) => '${e.product.name} × ${e.quantity}')
              .join(', ');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'অর্ডার সফল!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'ধন্যবাদ! আপনার অর্ডার Firebase এ সেভ হয়েছে।\n\n',
                      style: TextStyle(fontSize: 14),
                    ),
                    const TextSpan(
                      text: 'পণ্য:\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '$itemsText\n\n',
                      style: const TextStyle(fontSize: 13),
                    ),
                    TextSpan(
                      text: 'মোট: ৳${widget.totalPrice.toStringAsFixed(2)}\n',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF85606),
                      ),
                    ),
                    TextSpan(
                      text: 'ডেলিভারি: ${_areaController.text}\n',
                      style: const TextStyle(fontSize: 13),
                    ),
                    TextSpan(
                      text: 'ঠিকানা: ${_streetController.text}\n',
                      style: const TextStyle(fontSize: 13),
                    ),
                    TextSpan(
                      text: 'ফোন: +880 ${_phoneController.text}\n',
                      style: const TextStyle(fontSize: 13),
                    ),
                    TextSpan(
                      text:
                          'পেমেন্ট: ${_getPaymentMethodName(_selectedPaymentMethod)}\n\n',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const TextSpan(
                      text:
                          'শীঘ্রই যোগাযোগ করা হবে।\nকোনো সমস্যা হলে মেসেজ করুন: ',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/Facebook_Messenger_logo_2020.svg/512px-Facebook_Messenger_logo_2020.svg.png',
                  width: 20,
                  height: 20,
                ),
                label: const Text('মেসেজ করুন'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0084FF),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final url = Uri.parse('https://m.me/prodhan2');
                  if (await canLaunchUrl(url))
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('হোম'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF85606),
            ),
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('ট্র্যাক অর্ডার'),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    return {
          'bkash': 'bKash',
          'nagad': 'Nagad',
          'rocket': 'Rocket',
          'card': 'Card',
          'cod': 'Cash on Delivery',
        }[method] ??
        method;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Widget _buildProcessingUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFF85606)),
          SizedBox(height: 20),
          Text(
            'Processing...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF85606),
            ),
          ),
        ],
      ),
    );
  }
}
