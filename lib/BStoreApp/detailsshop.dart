// ---------------- PRODUCT DETAILS PAGE (FULLY UPDATED - API ONLY) ----------------
import 'dart:convert';
import 'dart:math';

import 'package:RUConnect_plus/BStoreApp/cardManager.dart';
import 'package:RUConnect_plus/BStoreApp/cartpage.dart';
import 'package:RUConnect_plus/BStoreApp/imageview.dart';
import 'package:RUConnect_plus/BStoreApp/paymentpage.dart';
import 'package:RUConnect_plus/BStoreApp/shippingrules.dart';
import 'package:RUConnect_plus/BStoreApp/storeapp.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  const ProductDetailsPage({required this.product, Key? key}) : super(key: key);

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;
  late PageController _imagePageController;
  int _currentImageIndex = 0;
  bool isFavorite = false;
  final CartManager _cartManager = CartManager();
  bool _isInCart = false;
  CartItem? _cartItem;
  final Random _random = Random();

  // Shipping
  List<ShippingRule> _shippingRules = [];
  ShippingRule? _selectedShippingRule;
  bool _isLoadingShipping = true;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _checkIfInCart();
    _cartManager.addListener(_onCartUpdated);
    _loadShippingRules();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _cartManager.removeListener(_onCartUpdated);
    super.dispose();
  }

  void _onCartUpdated() => _checkIfInCart();

  void _checkIfInCart() {
    setState(() {
      _isInCart = _cartManager.isProductInCart(widget.product);
      _cartItem = _cartManager.getCartItem(widget.product);
      if (_cartItem != null) quantity = _cartItem!.quantity;
    });
  }

  // === FETCH SHIPPING RULES FROM API ONLY ===
  Future<void> _loadShippingRules() async {
    setState(() => _isLoadingShipping = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://opensheet.elk.sh/14GLDraTX_xFp5XG-YBRE9Bmj4meQBk85qbVnMAuFVR0/4',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final rules = data.map((e) => ShippingRule.fromJson(e)).toList();

        setState(() {
          _shippingRules = rules;
          _selectedShippingRule = rules.isNotEmpty ? rules.first : null;
          _isLoadingShipping = false;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _shippingRules = [];
        _selectedShippingRule = null;
        _isLoadingShipping = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load delivery options. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addToCart() {
    if (!_isInCart) {
      _cartManager.addToCart(widget.product, quantity: quantity);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} added to cart!'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} is already in cart!'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showFullScreenImage(int initialIndex) {
    final images = widget.product.image
        .split(',')
        .map((e) => e.trim())
        .toList();
    if (images.isEmpty || images[0].isEmpty) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black,
              child: Center(
                child: Image.asset(
                  _random.nextBool()
                      ? 'assets/images/shop1.png'
                      : 'assets/images/shop2.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) =>
          FullScreenImageView(images: images, initialIndex: initialIndex),
    );
  }

  void _navigateToPaymentPage() {
    if (_selectedShippingRule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery area')),
      );
      return;
    }

    final shippingCharge =
        double.tryParse(_selectedShippingRule!.charge) ?? 60.0;
    final productPrice = _calculateProductPrice();
    final totalPrice = productPrice + shippingCharge;

    if (!_isInCart) {
      _cartManager.addToCart(widget.product, quantity: quantity);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          product: widget.product,
          quantity: quantity,
          totalPrice: totalPrice,
          shippingArea: _selectedShippingRule!.areaName,
          shippingCharge: shippingCharge,
          productId: widget.product.id,
          shippingRule: _selectedShippingRule!, // Pass full rule
        ),
      ),
    );
  }

  double _calculateProductPrice() {
    final original =
        double.tryParse(
          widget.product.price.replaceAll(RegExp(r'[^\d.]'), ''),
        ) ??
        0;
    final disc = double.tryParse(widget.product.discount) ?? 0;
    final priceAfter = original * (1 - disc / 100);
    return priceAfter * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final originalPrice =
        double.tryParse(
          widget.product.price.replaceAll(RegExp(r'[^\d.]'), ''),
        ) ??
        0;
    final discount = double.tryParse(widget.product.discount) ?? 0;
    final hasDiscount = discount > 0;
    final discountedPrice = originalPrice * (1 - discount / 100);
    final finalPrice = hasDiscount ? discountedPrice : originalPrice;
    final totalProductPrice = finalPrice * quantity;
    final shippingCharge =
        double.tryParse(_selectedShippingRule?.charge ?? '60') ?? 60.0;
    final total = totalProductPrice + shippingCharge;
    final savings = originalPrice - discountedPrice;
    final stock = int.tryParse(widget.product.stock) ?? 0;

    final rawImages = widget.product.image
        .split(',')
        .map((e) => e.trim())
        .toList();
    final images = rawImages.isEmpty || rawImages[0].isEmpty ? [''] : rawImages;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartPage()),
                ),
              ),
              if (_cartManager.totalItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_cartManager.totalItems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: () => setState(() => isFavorite = !isFavorite),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWeb = constraints.maxWidth > 800;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 32 : 16,
                    vertical: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: isWeb
                          ? _buildWebLayout(
                              images: images,
                              hasDiscount: hasDiscount,
                              discount: discount,
                              originalPrice: originalPrice,
                              finalPrice: finalPrice,
                              savings: savings,
                              stock: stock,
                              totalProductPrice: totalProductPrice,
                              shippingCharge: shippingCharge,
                              total: total,
                            )
                          : _buildMobileLayout(
                              images: images,
                              hasDiscount: hasDiscount,
                              discount: discount,
                              originalPrice: originalPrice,
                              finalPrice: finalPrice,
                              savings: savings,
                              stock: stock,
                              totalProductPrice: totalProductPrice,
                              shippingCharge: shippingCharge,
                              total: total,
                            ),
                    ),
                  ),
                ),
              ),
              _buildBottomBar(isWeb: isWeb),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------------
  // UI BUILDERS (unchanged – only type references use the shared model)
  // ----------------------------------------------------------------------
  Widget _buildWebLayout({
    required List<String> images,
    required bool hasDiscount,
    required double discount,
    required double originalPrice,
    required double finalPrice,
    required double savings,
    required int stock,
    required double totalProductPrice,
    required double shippingCharge,
    required double total,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _buildImageSection(images, hasDiscount, discount, isWeb: true),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 5,
          child: _buildDetailsSection(
            hasDiscount: hasDiscount,
            originalPrice: originalPrice,
            finalPrice: finalPrice,
            savings: savings,
            stock: stock,
            totalProductPrice: totalProductPrice,
            shippingCharge: shippingCharge,
            total: total,
            isWeb: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout({
    required List<String> images,
    required bool hasDiscount,
    required double discount,
    required double originalPrice,
    required double finalPrice,
    required double savings,
    required int stock,
    required double totalProductPrice,
    required double shippingCharge,
    required double total,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageSection(images, hasDiscount, discount, isWeb: false),
        const SizedBox(height: 20),
        _buildDetailsSection(
          hasDiscount: hasDiscount,
          originalPrice: originalPrice,
          finalPrice: finalPrice,
          savings: savings,
          stock: stock,
          totalProductPrice: totalProductPrice,
          shippingCharge: shippingCharge,
          total: total,
          isWeb: false,
        ),
      ],
    );
  }

  Widget _buildImageSection(
    List<String> images,
    bool hasDiscount,
    double discount, {
    required bool isWeb,
  }) {
    return SizedBox(
      height: isWeb ? 500 : 300,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imagePageController,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (context, index) {
              final url = images[index];
              return GestureDetector(
                onTap: () => _showFullScreenImage(index),
                child: Container(
                  margin: EdgeInsets.all(isWeb ? 8 : 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[100],
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: url.isEmpty
                        ? _buildFallbackImage()
                        : CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _buildFallbackImage(),
                            errorWidget: (_, __, ___) => _buildFallbackImage(),
                          ),
                  ),
                ),
              );
            },
          ),
          if (hasDiscount)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${discount.toStringAsFixed(0)}% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          if (_isInCart)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'In Cart',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentImageIndex == i ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentImageIndex == i
                          ? Colors.blue
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection({
    required bool hasDiscount,
    required double originalPrice,
    required double finalPrice,
    required double savings,
    required int stock,
    required double totalProductPrice,
    required double shippingCharge,
    required double total,
    required bool isWeb,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.product.name,
                style: TextStyle(
                  fontSize: isWeb ? 28 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    widget.product.rating,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: [
            Text(
              'ID: ${widget.product.id}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            Text(
              'Category: ${widget.product.categoryId}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildPriceCard(
          hasDiscount,
          originalPrice,
          finalPrice,
          savings,
          stock,
          isWeb,
        ),
        const SizedBox(height: 20),

        Text(
          'Description',
          style: TextStyle(
            fontSize: isWeb ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.description,
          style: TextStyle(
            fontSize: isWeb ? 16 : 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        _buildQuantityAndTotal(
          hasDiscount,
          originalPrice,
          finalPrice,
          totalProductPrice,
          stock,
          isWeb,
        ),
        const SizedBox(height: 20),

        // SHIPPING SELECTOR
        _buildShippingSelector(isWeb),
        const SizedBox(height: 20),

        // TOTAL WITH SHIPPING
        _buildFinalTotalCard(totalProductPrice, shippingCharge, total, isWeb),
      ],
    );
  }

  Widget _buildPriceCard(
    bool hasDiscount,
    double originalPrice,
    double finalPrice,
    double savings,
    int stock,
    bool isWeb,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDiscount)
                Text(
                  '৳${originalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                '৳${finalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isWeb ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              if (hasDiscount)
                Text(
                  'Save ৳${savings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'In Stock',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('$stock items', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityAndTotal(
    bool hasDiscount,
    double originalPrice,
    double finalPrice,
    double totalProductPrice,
    int stock,
    bool isWeb,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isWeb ? 20 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Text(
                'Quantity:',
                style: TextStyle(
                  fontSize: isWeb ? 18 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: quantity > 1
                          ? () {
                              setState(() => quantity--);
                              if (_isInCart)
                                _cartManager.updateQuantity(
                                  widget.product.id,
                                  quantity,
                                );
                            }
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          '$quantity',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: quantity < stock
                          ? () {
                              setState(() => quantity++);
                              if (_isInCart)
                                _cartManager.updateQuantity(
                                  widget.product.id,
                                  quantity,
                                );
                            }
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(isWeb ? 20 : 16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '($quantity × ৳${finalPrice.toStringAsFixed(2)})',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳${totalProductPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isWeb ? 28 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  if (hasDiscount)
                    Text(
                      'Was ৳${(originalPrice * quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // === UPDATED SHIPPING SELECTOR WITH INSTRUCTIONS ===
  Widget _buildShippingSelector(bool isWeb) {
    if (_isLoadingShipping) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading delivery options...'),
            ],
          ),
        ),
      );
    }

    if (_shippingRules.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No delivery options available. Please contact support.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Area',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ShippingRule>(
              value: _selectedShippingRule,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _shippingRules.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text('${r.areaName} (+৳${r.charge})'),
                );
              }).toList(),
              onChanged: (rule) => setState(() => _selectedShippingRule = rule),
            ),
            const SizedBox(height: 12),
            if (_selectedShippingRule != null) ...[
              const Text(
                'Payment Instructions:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedShippingRule!.codInstructions.isNotEmpty
                    ? _selectedShippingRule!.codInstructions
                    : 'Pay via bKash/Nagad/Rocket to ${_selectedShippingRule!.contactNumber}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinalTotalCard(
    double productTotal,
    double shippingCharge,
    double grandTotal,
    bool isWeb,
  ) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Product: ৳${productTotal.toStringAsFixed(2)} + Shipping: ৳${shippingCharge.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Text(
            '৳${grandTotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isWeb ? 28 : 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF85606),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({required bool isWeb}) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addToCart,
                  icon: Icon(
                    _isInCart
                        ? Icons.check_circle
                        : Icons.shopping_cart_outlined,
                    size: 20,
                  ),
                  label: Text(
                    _isInCart ? 'In Cart' : 'Add to Cart',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isInCart ? Colors.red : Colors.blue,
                    side: BorderSide(
                      color: _isInCart ? Colors.red : Colors.blue,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToPaymentPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF85606),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      _random.nextBool()
          ? 'assets/images/shop1.png'
          : 'assets/images/shop2.png',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, color: Colors.grey, size: 40),
      ),
    );
  }
}
