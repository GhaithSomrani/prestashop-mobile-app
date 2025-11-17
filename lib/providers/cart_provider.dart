import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  static const String _cartKey = 'cart_items';

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      _items.fold(0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => _items.isEmpty;

  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString(_cartKey);
      if (cartData != null) {
        final List<dynamic> decodedData = jsonDecode(cartData);
        _items = decodedData.map((item) => CartItem.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cart: $e');
      }
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartData);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving cart: $e');
      }
    }
  }

  void addItem(Product product, {int quantity = 1, String? variantId}) {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          (variantId == null || item.variantId == variantId),
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product,
        quantity: quantity,
        variantId: variantId,
      ));
    }

    _saveCart();
    notifyListeners();
  }

  void removeItem(String productId, {String? variantId}) {
    _items.removeWhere(
      (item) =>
          item.product.id == productId &&
          (variantId == null || item.variantId == variantId),
    );
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity, {String? variantId}) {
    final index = _items.indexWhere(
      (item) =>
          item.product.id == productId &&
          (variantId == null || item.variantId == variantId),
    );

    if (index >= 0) {
      if (quantity > 0) {
        _items[index].quantity = quantity;
      } else {
        _items.removeAt(index);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void incrementQuantity(String productId, {String? variantId}) {
    final index = _items.indexWhere(
      (item) =>
          item.product.id == productId &&
          (variantId == null || item.variantId == variantId),
    );

    if (index >= 0) {
      _items[index].quantity++;
      _saveCart();
      notifyListeners();
    }
  }

  void decrementQuantity(String productId, {String? variantId}) {
    final index = _items.indexWhere(
      (item) =>
          item.product.id == productId &&
          (variantId == null || item.variantId == variantId),
    );

    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  bool isInCart(String productId, {String? variantId}) {
    return _items.any(
      (item) =>
          item.product.id == productId &&
          (variantId == null || item.variantId == variantId),
    );
  }

  int getQuantity(String productId, {String? variantId}) {
    final index = _items.indexWhere(
      (item) =>
          item.product.id == productId &&
          (variantId == null || item.variantId == variantId),
    );
    return index >= 0 ? _items[index].quantity : 0;
  }
}
