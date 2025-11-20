import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/cart_rule.dart';
import '../services/cart_rule_service.dart';

class CartProvider with ChangeNotifier {
  final CartRuleService? _cartRuleService;

  CartProvider({CartRuleService? cartRuleService}) : _cartRuleService = cartRuleService;

  List<CartItem> _items = [];
  List<AppliedVoucher> _appliedVouchers = [];
  static const String _cartKey = 'cart_items';
  static const String _vouchersKey = 'applied_vouchers';

  List<CartItem> get items => _items;
  List<AppliedVoucher> get appliedVouchers => _appliedVouchers;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + item.totalPrice);

  double get totalDiscount =>
      _appliedVouchers.fold(0, (sum, voucher) => sum + voucher.discountAmount);

  double get totalAmount => subtotal - totalDiscount;

  bool get isEmpty => _items.isEmpty;
  bool get hasVouchers => _appliedVouchers.isNotEmpty;
  bool get hasFreeShipping => _appliedVouchers.any((v) => v.cartRule.freeShipping);

  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString(_cartKey);
      if (cartData != null) {
        final List<dynamic> decodedData = jsonDecode(cartData);
        _items = decodedData.map((item) => CartItem.fromJson(item)).toList();
      }

      // Load vouchers
      final vouchersData = prefs.getString(_vouchersKey);
      if (vouchersData != null) {
        final List<dynamic> decodedVouchers = jsonDecode(vouchersData);
        _appliedVouchers = decodedVouchers
            .map((v) => AppliedVoucher.fromJson(v))
            .toList();
        _recalculateDiscounts();
      }
      notifyListeners();
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

      // Save vouchers
      final vouchersData = jsonEncode(_appliedVouchers.map((v) => v.toJson()).toList());
      await prefs.setString(_vouchersKey, vouchersData);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving cart: $e');
      }
    }
  }

  void _recalculateDiscounts() {
    for (int i = 0; i < _appliedVouchers.length; i++) {
      final voucher = _appliedVouchers[i];
      final newDiscount = voucher.cartRule.calculateDiscount(subtotal);
      _appliedVouchers[i] = AppliedVoucher(
        cartRule: voucher.cartRule,
        discountAmount: newDiscount,
      );
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

  // Voucher methods
  Future<bool> addVoucher(String code) async {
    if (_cartRuleService == null) {
      throw Exception('Cart rule service not available');
    }

    try {
      // Check if voucher is already applied
      if (_appliedVouchers.any((v) => v.cartRule.code == code)) {
        throw Exception('Voucher already applied');
      }

      final cartRule = await _cartRuleService!.getCartRuleByCode(code);
      if (cartRule == null) {
        throw Exception('Invalid voucher code');
      }

      if (!cartRule.isValid) {
        throw Exception('Voucher has expired or is no longer valid');
      }

      if (subtotal < cartRule.minimumAmount) {
        throw Exception('Minimum order amount of ${cartRule.minimumAmount.toStringAsFixed(2)} TND required');
      }

      final discount = cartRule.calculateDiscount(subtotal);
      _appliedVouchers.add(AppliedVoucher(
        cartRule: cartRule,
        discountAmount: discount,
      ));

      _saveCart();
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding voucher: $e');
      }
      rethrow;
    }
  }

  void removeVoucher(String code) {
    _appliedVouchers.removeWhere((v) => v.cartRule.code == code);
    _saveCart();
    notifyListeners();
  }

  void clearVouchers() {
    _appliedVouchers.clear();
    _saveCart();
    notifyListeners();
  }

  bool isVoucherApplied(String code) {
    return _appliedVouchers.any((v) => v.cartRule.code == code);
  }

  // Get cart summary for checkout
  Map<String, dynamic> getCartSummary() {
    return {
      'items': _items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'discount': totalDiscount,
      'total': totalAmount,
      'vouchers': _appliedVouchers.map((v) => {
        'code': v.cartRule.code,
        'discount': v.discountAmount,
      }).toList(),
      'free_shipping': hasFreeShipping,
    };
  }
}
