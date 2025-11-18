/// Model for PrestaShop product combination (variants like size, color)
class Combination {
  final String id;
  final String idProduct;
  final String reference;
  final double priceImpact; // Price difference from base product (can be + or -)
  final int quantity;
  final bool defaultOn;
  final List<CombinationAttribute> attributes;

  Combination({
    required this.id,
    required this.idProduct,
    required this.reference,
    required this.priceImpact,
    required this.quantity,
    required this.defaultOn,
    this.attributes = const [],
  });

  bool get inStock => quantity > 0;

  factory Combination.fromJson(Map<String, dynamic> json) {
    double parsePriceImpact(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseQuantity(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return Combination(
      id: json['id']?.toString() ?? '',
      idProduct: json['id_product']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      priceImpact: parsePriceImpact(json['price']),
      quantity: parseQuantity(json['quantity']),
      defaultOn: json['default_on'] == '1' || json['default_on'] == true,
      attributes: json['associations']?['product_option_values'] != null
          ? (json['associations']['product_option_values'] as List)
              .map((attr) => CombinationAttribute.fromJson(attr))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_product': idProduct,
      'reference': reference,
      'price': priceImpact,
      'quantity': quantity,
      'default_on': defaultOn ? '1' : '0',
      'attributes': attributes.map((attr) => attr.toJson()).toList(),
    };
  }
}

/// Attribute associated with a combination (e.g., Color: Red, Size: M)
class CombinationAttribute {
  final String id;
  final String name;
  final String value;

  CombinationAttribute({
    required this.id,
    required this.name,
    required this.value,
  });

  factory CombinationAttribute.fromJson(Map<String, dynamic> json) {
    return CombinationAttribute(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
    };
  }
}
