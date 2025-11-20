class CartRule {
  final String id;
  final String name;
  final String description;
  final String code;
  final double reductionPercent;
  final double reductionAmount;
  final bool freeShipping;
  final double minimumAmount;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int quantity;
  final int quantityPerUser;
  final bool active;

  CartRule({
    required this.id,
    required this.name,
    this.description = '',
    required this.code,
    this.reductionPercent = 0,
    this.reductionAmount = 0,
    this.freeShipping = false,
    this.minimumAmount = 0,
    this.dateFrom,
    this.dateTo,
    this.quantity = 0,
    this.quantityPerUser = 1,
    this.active = true,
  });

  bool get isValid {
    final now = DateTime.now();
    if (dateFrom != null && now.isBefore(dateFrom!)) return false;
    if (dateTo != null && now.isAfter(dateTo!)) return false;
    if (quantity <= 0) return false;
    return active;
  }

  bool get isPercentDiscount => reductionPercent > 0;
  bool get isAmountDiscount => reductionAmount > 0;

  double calculateDiscount(double cartTotal) {
    if (cartTotal < minimumAmount) return 0;
    if (isPercentDiscount) {
      return cartTotal * (reductionPercent / 100);
    }
    return reductionAmount;
  }

  factory CartRule.fromJson(Map<String, dynamic> json) {
    final rule = json['cart_rule'] ?? json;

    return CartRule(
      id: rule['id']?.toString() ?? '',
      name: _extractLanguageValue(rule['name']) ?? '',
      description: _extractLanguageValue(rule['description']) ?? '',
      code: rule['code']?.toString() ?? '',
      reductionPercent: _parseDouble(rule['reduction_percent']),
      reductionAmount: _parseDouble(rule['reduction_amount']),
      freeShipping: rule['free_shipping'] == '1' || rule['free_shipping'] == true,
      minimumAmount: _parseDouble(rule['minimum_amount']),
      dateFrom: _parseDate(rule['date_from']),
      dateTo: _parseDate(rule['date_to']),
      quantity: int.tryParse(rule['quantity']?.toString() ?? '0') ?? 0,
      quantityPerUser: int.tryParse(rule['quantity_per_user']?.toString() ?? '1') ?? 1,
      active: rule['active'] == '1' || rule['active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'code': code,
      'reduction_percent': reductionPercent,
      'reduction_amount': reductionAmount,
      'free_shipping': freeShipping ? '1' : '0',
      'minimum_amount': minimumAmount,
      'date_from': dateFrom?.toIso8601String(),
      'date_to': dateTo?.toIso8601String(),
      'quantity': quantity,
      'quantity_per_user': quantityPerUser,
      'active': active ? '1' : '0',
    };
  }

  static String? _extractLanguageValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      if (value['language'] != null) {
        final lang = value['language'];
        if (lang is List && lang.isNotEmpty) {
          return lang.first['value']?.toString();
        }
        if (lang is Map) {
          return lang['value']?.toString();
        }
      }
    }
    return value.toString();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

class AppliedVoucher {
  final CartRule cartRule;
  final double discountAmount;

  AppliedVoucher({
    required this.cartRule,
    required this.discountAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'cart_rule': cartRule.toJson(),
      'discount_amount': discountAmount,
    };
  }

  factory AppliedVoucher.fromJson(Map<String, dynamic> json) {
    return AppliedVoucher(
      cartRule: CartRule.fromJson(json['cart_rule']),
      discountAmount: json['discount_amount']?.toDouble() ?? 0,
    );
  }
}
