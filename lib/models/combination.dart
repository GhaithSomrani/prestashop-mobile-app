import '../utils/language_helper.dart';

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

    // Parse product option values from associations
    List<CombinationAttribute> attributes = [];
    if (json['associations']?['product_option_values'] != null) {
      var optionValues = json['associations']['product_option_values'];

      // Handle XML nested structure
      if (optionValues is Map && optionValues['product_option_value'] != null) {
        optionValues = optionValues['product_option_value'];
      }

      if (optionValues is List) {
        attributes = optionValues
            .map((attr) => CombinationAttribute.fromJson(attr as Map<String, dynamic>))
            .toList();
      } else if (optionValues is Map) {
        attributes = [CombinationAttribute.fromJson(optionValues as Map<String, dynamic>)];
      }
    }

    return Combination(
      id: json['id']?.toString() ?? '',
      idProduct: json['id_product']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      priceImpact: parsePriceImpact(json['price']),
      quantity: parseQuantity(json['quantity']),
      defaultOn: json['default_on'] == '1' || json['default_on'] == true,
      attributes: attributes,
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
      name: LanguageHelper.extractValueOrEmpty(json['name']),
      value: LanguageHelper.extractValueOrEmpty(json['value']),
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
