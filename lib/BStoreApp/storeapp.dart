import 'dart:async';
import 'dart:convert';

import 'package:RUConnect_plus/BStoreApp/categorypage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daraz Clone',
      theme: ThemeData(
        primaryColor: Colors.blue, // Changed to blue
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: CategoryPage(),
    );
  }
}

// ---------------- MODELS ----------------
class BannerItem {
  final String imageUrl;
  final String description;
  final bool show;
  BannerItem({
    required this.imageUrl,
    required this.description,
    required this.show,
  });
  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      imageUrl: json['Image URL'] ?? '',
      description: json['Description'] ?? '',
      show: (json['Show'] ?? 'false').toString().toUpperCase() == "TRUE",
    );
  }
  Map<String, dynamic> toJson() {
    return {'Image URL': imageUrl, 'Description': description, 'Show': show};
  }
}

class Category {
  final String id;
  final String name;
  final String iconUrl;
  Category({required this.id, required this.name, required this.iconUrl});
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['CategoryID'] ?? '',
      name: json['Name'] ?? '',
      iconUrl: json['IconURL'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {'CategoryID': id, 'Name': name, 'IconURL': iconUrl};
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final String image;
  final String price;
  final String discount;
  final String stock;
  final String categoryId;
  final String rating;
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.discount,
    required this.stock,
    required this.categoryId,
    required this.rating,
  });
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['ID'] ?? '',
      name: json['Name'] ?? '',
      description: json['Description'] ?? '',
      image: json['Images'] ?? '',
      price: json['Price'] ?? '0',
      discount: json['Discount'] ?? '0',
      stock: json['Stock'] ?? '0',
      categoryId: json['CategoryID'] ?? '',
      rating: json['Rating'] ?? '0',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Name': name,
      'Description': description,
      'Images': image,
      'Price': price,
      'Discount': discount,
      'Stock': stock,
      'CategoryID': categoryId,
      'Rating': rating,
    };
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});

  double get totalPrice {
    double price =
        double.tryParse(product.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    double discount = double.tryParse(product.discount) ?? 0;
    double discountedPrice = price - (price * discount / 100);
    return discountedPrice * quantity;
  }
}

// ---------------- CACHE MANAGER ----------------
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  static const String _categoriesKey = 'cached_categories';
  static const String _productsKey = 'cached_products';
  static const String _bannersKey = 'cached_banners';
  static const String _lastUpdateKey = 'last_update';

  Future<void> saveCategories(List<Category> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = categories.map((cat) => cat.toJson()).toList();
    await prefs.setString(_categoriesKey, json.encode(jsonList));
    await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  Future<List<Category>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_categoriesKey);
    if (jsonString != null) {
      final jsonList = json.decode(jsonString) as List;
      return jsonList.map((item) => Category.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = products.map((prod) => prod.toJson()).toList();
    await prefs.setString(_productsKey, json.encode(jsonList));
    await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  Future<List<Product>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_productsKey);
    if (jsonString != null) {
      final jsonList = json.decode(jsonString) as List;
      return jsonList.map((item) => Product.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> saveBanners(List<BannerItem> banners) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = banners.map((banner) => banner.toJson()).toList();
    await prefs.setString(_bannersKey, json.encode(jsonList));
    await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  Future<List<BannerItem>> getBanners() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_bannersKey);
    if (jsonString != null) {
      final jsonList = json.decode(jsonString) as List;
      return jsonList.map((item) => BannerItem.fromJson(item)).toList();
    }
    return [];
  }

  Future<DateTime?> getLastUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString(_lastUpdateKey);
    if (lastUpdate != null) {
      return DateTime.parse(lastUpdate);
    }
    return null;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_categoriesKey);
    await prefs.remove(_productsKey);
    await prefs.remove(_bannersKey);
    await prefs.remove(_lastUpdateKey);
  }
}
