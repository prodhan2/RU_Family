// ---------------- CART MANAGER ----------------
import 'dart:ui';

import 'package:RUConnect_plus/BStoreApp/storeapp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.from(_cartItems);

  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  // NEW METHOD: Check if product is in cart
  bool isProductInCart(Product product) {
    return _cartItems.any((item) => item.product.id == product.id);
  }

  // NEW METHOD: Get cart item by product
  CartItem? getCartItem(Product product) {
    try {
      return _cartItems.firstWhere((item) => item.product.id == product.id);
    } catch (e) {
      return null;
    }
  }

  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += quantity;
    } else {
      _cartItems.add(CartItem(product: product, quantity: quantity));
    }

    _saveCart();
    _notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    _saveCart();
    _notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
      }
      _saveCart();
      _notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _saveCart();
    _notifyListeners();
  }

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = _cartItems
        .map(
          (item) => {
            'product': item.product.toJson(),
            'quantity': item.quantity,
          },
        )
        .toList();
    await prefs.setString('cart', json.encode(cartJson));
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('cart');
    if (cartJson != null) {
      final List<dynamic> cartData = json.decode(cartJson);
      _cartItems = cartData.map((item) {
        return CartItem(
          product: Product.fromJson(item['product']),
          quantity: item['quantity'],
        );
      }).toList();
      _notifyListeners();
    }
  }
}
