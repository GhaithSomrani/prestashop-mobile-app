import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/wishlist_item.dart';
import '../models/product.dart';

class WishlistProvider with ChangeNotifier {
  List<WishlistItem> _items = [];
  bool _isLoading = false;
  static const String _storageKey = 'wishlist_items';

  List<WishlistItem> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  WishlistProvider() {
    _loadFromStorage();
  }

  /// Check if product is in wishlist
  bool isInWishlist(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  /// Add product to wishlist
  Future<void> addToWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      return; // Already in wishlist
    }

    final wishlistItem = WishlistItem.fromProduct(product);
    _items.add(wishlistItem);
    notifyListeners();

    await _saveToStorage();
  }

  /// Remove product from wishlist
  Future<void> removeFromWishlist(String productId) async {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();

    await _saveToStorage();
  }

  /// Toggle product in wishlist
  Future<void> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      await removeFromWishlist(product.id);
    } else {
      await addToWishlist(product);
    }
  }

  /// Clear all wishlist items
  Future<void> clearWishlist() async {
    _items.clear();
    notifyListeners();

    await _saveToStorage();
  }

  /// Get wishlist item by product ID
  WishlistItem? getItem(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Load wishlist from local storage
  Future<void> _loadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _items = jsonList
            .map((json) => WishlistItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading wishlist: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save wishlist to local storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving wishlist: $e');
      }
    }
  }

  /// Refresh wishlist (reload from storage)
  Future<void> refresh() async {
    await _loadFromStorage();
  }

  /// Sort wishlist by different criteria
  void sortByName({bool ascending = true}) {
    _items.sort((a, b) {
      return ascending
          ? a.name.compareTo(b.name)
          : b.name.compareTo(a.name);
    });
    notifyListeners();
  }

  void sortByPrice({bool ascending = true}) {
    _items.sort((a, b) {
      return ascending
          ? a.finalPrice.compareTo(b.finalPrice)
          : b.finalPrice.compareTo(a.finalPrice);
    });
    notifyListeners();
  }

  void sortByDateAdded({bool ascending = true}) {
    _items.sort((a, b) {
      return ascending
          ? a.addedAt.compareTo(b.addedAt)
          : b.addedAt.compareTo(a.addedAt);
    });
    notifyListeners();
  }

  /// Get total value of wishlist
  double get totalValue {
    return _items.fold(0, (sum, item) => sum + item.finalPrice);
  }

  /// Get count of in-stock items
  int get inStockCount {
    return _items.where((item) => item.inStock).length;
  }

  /// Get count of on-sale items
  int get onSaleCount {
    return _items.where((item) => item.isOnSale).length;
  }
}
