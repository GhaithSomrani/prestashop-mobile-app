/// Model for PrestaShop specific price (discounts, special offers)
class SpecificPrice {
  final String id;
  final String idProduct;
  final String? idProductAttribute; // null means applies to all variants
  final String idCustomer; // 0 = all customers
  final String idGroup; // Customer group
  final double reduction;
  final String reductionType; // 'amount' or 'percentage'
  final double price; // -1 means use base price
  final DateTime? from;
  final DateTime? to;
  final int fromQuantity;

  SpecificPrice({
    required this.id,
    required this.idProduct,
    this.idProductAttribute,
    this.idCustomer = '0',
    this.idGroup = '0',
    required this.reduction,
    required this.reductionType,
    this.price = -1,
    this.from,
    this.to,
    this.fromQuantity = 1,
  });

  bool get isActive {
    final now = DateTime.now();
    if (from != null && now.isBefore(from!)) return false;
    if (to != null && now.isAfter(to!)) return false;
    return true;
  }

  /// Calculate final price based on reduction
  double calculateFinalPrice(double basePrice) {
    if (price != -1 && price > 0) {
      return price; // Fixed price
    }

    if (reductionType == 'percentage') {
      return basePrice * (1 - reduction);
    } else {
      // Amount reduction
      return basePrice - reduction;
    }
  }

  /// Get discount percentage for display
  double get discountPercentage {
    if (reductionType == 'percentage') {
      return reduction * 100;
    }
    return 0; // Can't calculate percentage for amount reduction without base price
  }

  factory SpecificPrice.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null || value == '0000-00-00 00:00:00') return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    return SpecificPrice(
      id: json['id']?.toString() ?? '',
      idProduct: json['id_product']?.toString() ?? '',
      idProductAttribute: json['id_product_attribute']?.toString() != '0'
          ? json['id_product_attribute']?.toString()
          : null,
      idCustomer: json['id_customer']?.toString() ?? '0',
      idGroup: json['id_group']?.toString() ?? '0',
      reduction: parseDouble(json['reduction']),
      reductionType: json['reduction_type']?.toString() ?? 'percentage',
      price: parseDouble(json['price']),
      from: parseDate(json['from']),
      to: parseDate(json['to']),
      fromQuantity: json['from_quantity'] is int
          ? json['from_quantity']
          : int.tryParse(json['from_quantity']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_product': idProduct,
      'id_product_attribute': idProductAttribute,
      'id_customer': idCustomer,
      'id_group': idGroup,
      'reduction': reduction,
      'reduction_type': reductionType,
      'price': price,
      'from': from?.toIso8601String(),
      'to': to?.toIso8601String(),
      'from_quantity': fromQuantity,
    };
  }
}
