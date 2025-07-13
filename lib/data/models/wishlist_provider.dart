import 'package:flutter/material.dart';

class WishlistProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _wishlistItems = [];

  List<Map<String, dynamic>> get wishlistItems => _wishlistItems;

  // 문자열 ID로 처리
  bool isInWishlist(String productId) {
    return _wishlistItems.any((item) => item['id'] == productId);
  }

  void addItem(Map<String, dynamic> productData) {
    if (!isInWishlist(productData['id'])) {
      _wishlistItems.add(productData);
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _wishlistItems.removeWhere((item) => item['id'] == productId);
    notifyListeners();
  }
} 