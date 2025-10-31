// ---------------- PAYMENT PAGE (NO LOGIN, NO FIREBASE) ----------------
import 'dart:convert';
import 'package:RUConnect_plus/BStoreApp/cardManager.dart';
import 'package:RUConnect_plus/BStoreApp/categorypage.dart';
import 'package:RUConnect_plus/BStoreApp/shippingrules.dart' show ShippingRule;
import 'package:RUConnect_plus/BStoreApp/storeapp.dart';
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

  // FIXED: proper lowerCamelCase name and correct parameters
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
      trailing: Radio(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
        activeColor: const Color(0xFFF85606),
      ),
      onTap: () => setState(() => _selectedPaymentMethod = value),
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
  // ========================= CONFIRM PAYMENT (NO LOGIN, NO FIREBASE) =========================
  // ===================================================================
  void _confirmPayment() async {
    // ---- Validation ----
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

    setState(() => _isProcessing = true);

    // Small fake delay (optional)
    await Future.delayed(const Duration(milliseconds: 800));

    // Clear cart locally
    if (widget.products != null) {
      CartManager().clearCart();
    }

    setState(() => _isProcessing = false);

    // Show success dialog
    _showOrderSuccessDialog();
  }

  // ===================================================================
  // ========================= SUCCESS DIALOG (SMART UI + MESSAGING) =========================
  // ===================================================================
  // ===================================================================
  // ========================= SUCCESS DIALOG (PROFESSIONAL CARD + DATE + NAV TO CategoryPage) =========================
  // ===================================================================
  // ===================================================================
  // ========================= SUCCESS DIALOG (WITH TRANSACTION ID + DATE + NAV TO CategoryPage) =========================
  // ===================================================================
  // ===================================================================
  // ========================= SUCCESS DIALOG (ক্লোজ বাটন + সব ক্লিকে মেসেজ + CategoryPage) =========================
  // ===================================================================
  void _showOrderSuccessDialog() {
    final now = DateTime.now();
    final formattedDate = '${now.day}/${now.month}/${now.year}';

    final itemsText = widget.product != null
        ? '${widget.product!.name} × ${widget.quantity ?? 1}'
        : widget.products!
              .map((e) => '${e.product.name} × ${e.quantity}')
              .join(', ');

    final transactionLine =
        (_selectedPaymentMethod != 'cod' && _selectedPaymentMethod != 'card')
        ? _transactionController.text.trim().isNotEmpty
              ? '\n*ট্রানজেকশন আইডি:* ${_transactionController.text.trim()}'
              : ''
        : '';

    final orderMessage =
        '''
*নতুন অর্ডার!*

*তারিখ:* $formattedDate
*পণ্য:* $itemsText
*মোট টাকা:* ৳${widget.totalPrice.toStringAsFixed(2)}$transactionLine
*ডেলিভারি এরিয়া:* ${widget.shippingArea}
*পুরো ঠিকানা:* ${_streetController.text.trim()}
*ফোন নম্বর:* +880 ${_phoneController.text.trim()}
*পেমেন্ট মেথড:* ${_getPaymentMethodName(_selectedPaymentMethod)}
'''
            .trim();

    final encodedMsg = Uri.encodeComponent(orderMessage);

    // সব ক্লিকে মেসেজ পাঠানো + CategoryPage এ যাওয়া
    void _sendAndNavigate(String url) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pop(context); // ডায়লগ বন্ধ
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => CategoryPage()),
          );
        }
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // হেডার + ক্লোজ বাটন
              Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF85606),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'অর্ডার সফল!',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                  // ক্লোজ বাটন (X)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => _sendAndNavigate(
                        'https://m.me/prodhan2?text=$encodedMsg',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // সারাংশ কার্ড
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryRow('তারিখ', formattedDate),
                    _summaryRow('পণ্য', itemsText),
                    _summaryRow(
                      'মোট টাকা',
                      '৳${widget.totalPrice.toStringAsFixed(2)}',
                      valueStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF85606),
                      ),
                    ),
                    if (_selectedPaymentMethod != 'cod' &&
                        _selectedPaymentMethod != 'card' &&
                        _transactionController.text.trim().isNotEmpty)
                      _summaryRow(
                        'ট্রানজেকশন আইডি',
                        _transactionController.text.trim(),
                      ),
                    _summaryRow('ডেলিভারি', _areaController.text),
                    _summaryRow('ঠিকানা', _streetController.text.trim()),
                    _summaryRow('ফোন', '+880 ${_phoneController.text.trim()}'),
                    _summaryRow(
                      'পেমেন্ট',
                      _getPaymentMethodName(_selectedPaymentMethod),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // মেসেজ পাঠানোর বাটন
              _contactButton(
                label: 'মেসেঞ্জারে পাঠান',
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/Facebook_Messenger_logo_2020.svg/512px-Facebook_Messenger_logo_2020.svg.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: () =>
                    _sendAndNavigate('https://m.me/prodhan2?text=$encodedMsg'),
              ),
              const SizedBox(height: 10),
              _contactButton(
                label: 'হোয়াটসঅ্যাপে পাঠান',
                icon: const Icon(Icons.message, color: Colors.white),
                onPressed: () => _sendAndNavigate(
                  'https://wa.me/8801902383808?text=$encodedMsg',
                ),
              ),
              const SizedBox(height: 10),
              _contactButton(
                label: 'টেলিগ্রামে পাঠান',
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendAndNavigate(
                  'https://t.me/Sujanprodhan?text=$encodedMsg',
                ),
              ),
              const SizedBox(height: 24),

              // অ্যাকশন বাটন
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1565C0),
                        side: const BorderSide(color: Color(0xFF1565C0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _sendAndNavigate(
                        'https://m.me/prodhan2?text=$encodedMsg',
                      ),
                      child: const Text(
                        'হোম',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF85606),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _sendAndNavigate(
                        'https://m.me/prodhan2?text=$encodedMsg',
                      ),
                      child: const Text(
                        'ট্র্যাক অর্ডার',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  // Helper: Navigate to CategoryPage and close dialog
  void _navigateToCategoryPage() {
    Navigator.pop(context); // close dialog
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CategoryPage()),
    );
  }

  // Helper widgets for dialog
  Widget _summaryRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  valueStyle ??
                  GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactButton({
    required String label,
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: icon,
        label: Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
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
