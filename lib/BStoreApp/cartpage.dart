import 'dart:convert';
import 'package:RUConnect_plus/BStoreApp/cardManager.dart';
import 'package:RUConnect_plus/BStoreApp/paymentpage.dart';
import 'package:RUConnect_plus/BStoreApp/shippingrules.dart';
import 'package:RUConnect_plus/BStoreApp/storeapp.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// ---------------- MAIN CART PAGE ----------------
class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartManager _cartManager = CartManager();
  List<ShippingRule> _shippingRules = [];
  ShippingRule? _selectedRule;
  bool _isLoadingRules = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cartManager.addListener(_onCartUpdated);
    _fetchShippingRules();
  }

  @override
  void dispose() {
    _cartManager.removeListener(_onCartUpdated);
    super.dispose();
  }

  // === FETCH SHIPPING RULES FROM API ===
  Future<void> _fetchShippingRules() async {
    try {
      setState(() => _isLoadingRules = true);
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
          _selectedRule = rules.isNotEmpty ? rules.first : null;
          _isLoadingRules = false;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load delivery options. Please try again.';
        _isLoadingRules = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!), backgroundColor: Colors.red),
      );
    }
  }

  void _onCartUpdated() => setState(() {});

  double get _shippingCharge => _selectedRule != null
      ? double.tryParse(_selectedRule!.charge) ?? 60.0
      : 60.0;

  double get _total => _cartManager.totalPrice + _shippingCharge;

  // === QUANTITY & CART ACTIONS ===
  void _updateQuantity(String id, int qty) =>
      _cartManager.updateQuantity(id, qty);

  void _removeItem(String id) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Remove Item',
        content: 'Are you sure you want to remove this item?',
        onConfirm: () {
          _cartManager.removeFromCart(id);
          _showSnack('Item removed', Colors.red);
        },
      ),
    );
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Clear Cart',
        content: 'Remove all items from your cart?',
        onConfirm: () {
          _cartManager.clearCart();
          _showSnack('Cart cleared', Colors.green);
        },
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get _isWide => MediaQuery.of(context).size.width > 900;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(isDark),
      body: _cartManager.cartItems.isEmpty ? _buildEmpty() : _buildBody(isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: const Color(0xFF1565C0),
      elevation: 0,
      title: Text(
        'Shopping Cart',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_cartManager.cartItems.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: 'Clear Cart',
            onPressed: _clearCart,
          ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some awesome products and come back!',
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF85606),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue Shopping',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoadingRules) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchShippingRules,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_shippingRules.isEmpty) {
      return const Center(child: Text('No delivery areas available.'));
    }

    return _isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _CartItemList(
                  onQtyChange: _updateQuantity,
                  onRemove: _removeItem,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _CheckoutPanel(
                  selectedRule: _selectedRule,
                  onRuleChanged: (rule) => setState(() => _selectedRule = rule),
                  shippingRules: _shippingRules,
                  shippingCharge: _shippingCharge,
                  total: _total,
                  cartManager: _cartManager,
                ),
              ),
            ],
          )
        : Column(
            children: [
              Expanded(
                child: _CartItemList(
                  onQtyChange: _updateQuantity,
                  onRemove: _removeItem,
                ),
              ),
              _CheckoutPanel(
                selectedRule: _selectedRule,
                onRuleChanged: (rule) => setState(() => _selectedRule = rule),
                shippingRules: _shippingRules,
                shippingCharge: _shippingCharge,
                total: _total,
                cartManager: _cartManager,
                isSticky: true,
              ),
            ],
          );
  }
}

// ---------------- CART ITEM LIST ----------------
class _CartItemList extends StatelessWidget {
  final void Function(String id, int qty) onQtyChange;
  final void Function(String id) onRemove;
  const _CartItemList({required this.onQtyChange, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final manager = CartManager();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isWide(context))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cart Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${manager.totalItems} ${manager.totalItems == 1 ? 'item' : 'items'}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: manager.cartItems.length,
            itemBuilder: (context, i) => _CartTile(
              item: manager.cartItems[i],
              onQtyChange: onQtyChange,
              onRemove: onRemove,
            ),
          ),
        ),
      ],
    );
  }

  bool _isWide(BuildContext context) => MediaQuery.of(context).size.width > 900;
}

// ---------------- CART TILE ----------------
class _CartTile extends StatefulWidget {
  final CartItem item;
  final void Function(String id, int qty) onQtyChange;
  final void Function(String id) onRemove;
  const _CartTile({
    required this.item,
    required this.onQtyChange,
    required this.onRemove,
  });

  @override
  State<_CartTile> createState() => __CartTileState();
}

class __CartTileState extends State<_CartTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wide = MediaQuery.of(context).size.width > 900;

    final original =
        double.tryParse(
          widget.item.product.price.replaceAll(RegExp(r'[৳,]'), ''),
        ) ??
        0;
    final discount = double.tryParse(widget.item.product.discount) ?? 0;
    final hasDiscount = discount > 0;
    final priceAfter = original * (1 - discount / 100);
    final lineTotal = priceAfter * widget.item.quantity;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.item.product.image.split(',').first.trim(),
                  width: wide ? 100 : 80,
                  height: wide ? 100 : 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: wide ? 17 : 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '৳${priceAfter.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF85606),
                            fontSize: wide ? 17 : 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hasDiscount)
                          Text(
                            '৳${original.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                              fontSize: wide ? 13 : 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _QtyButton(
                          icon: Icons.remove,
                          onTap: widget.item.quantity > 1
                              ? () => widget.onQtyChange(
                                  widget.item.product.id,
                                  widget.item.quantity - 1,
                                )
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${widget.item.quantity}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _QtyButton(
                          icon: Icons.add,
                          onTap: () => widget.onQtyChange(
                            widget.item.product.id,
                            widget.item.quantity + 1,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '৳${lineTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF85606),
                            fontSize: wide ? 17 : 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Remove',
                onPressed: () => widget.onRemove(widget.item.product.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.grey[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? Colors.black87 : Colors.grey[500],
        ),
      ),
    );
  }
}

// ---------------- CHECKOUT PANEL (PASS FULL RULE) ----------------
class _CheckoutPanel extends StatelessWidget {
  final ShippingRule? selectedRule;
  final void Function(ShippingRule? rule) onRuleChanged;
  final List<ShippingRule> shippingRules;
  final double shippingCharge;
  final double total;
  final CartManager cartManager;
  final bool isSticky;

  const _CheckoutPanel({
    this.selectedRule,
    required this.onRuleChanged,
    required this.shippingRules,
    required this.shippingCharge,
    required this.total,
    required this.cartManager,
    this.isSticky = false,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = cartManager.totalPrice;

    final child = Container(
      margin: EdgeInsets.all(isSticky ? 0 : 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Delivery Area',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ShippingRule>(
            value: selectedRule,
            decoration: InputDecoration(
              hintText: 'Select your area',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: shippingRules
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(
                      '${r.areaName} (+৳${r.charge})',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                )
                .toList(),
            onChanged: onRuleChanged,
          ),
          const SizedBox(height: 16),

          // Price Breakdown
          _PriceRow('Subtotal', subtotal),
          const SizedBox(height: 8),
          _PriceRow('Shipping', shippingCharge),
          const Divider(height: 24),
          _PriceRow('Total', total, isTotal: true),
          const SizedBox(height: 20),

          // Checkout Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF85606),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            onPressed: () {
              if (selectedRule == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a delivery area'),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentPage(
                    products: cartManager.cartItems,
                    totalPrice: total,
                    productId: '',
                    shippingArea: selectedRule!.areaName,
                    shippingCharge: shippingCharge,
                    shippingRule: selectedRule!, // FULL RULE PASSED
                  ),
                ),
              );
            },
            child: Text(
              'Proceed to Checkout',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue Shopping',
              style: GoogleFonts.poppins(
                color: const Color(0xFFF85606),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    return isSticky
        ? Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(top: false, child: child),
          )
        : child;
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;
  const _PriceRow(this.label, this.amount, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
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
          '৳${amount.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFFF85606) : null,
          ),
        ),
      ],
    );
  }
}

// ---------------- CONFIRM DIALOG ----------------
class _ConfirmDialog extends StatelessWidget {
  final String title, content;
  final VoidCallback onConfirm;
  const _ConfirmDialog({
    required this.title,
    required this.content,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Text(content, style: GoogleFonts.poppins()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: Text('Confirm', style: TextStyle(color: Colors.red[600])),
        ),
      ],
    );
  }
}
