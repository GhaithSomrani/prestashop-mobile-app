import 'product_detail.dart';

/// Model for PrestaShop product combination (variants like size, color)
///
/// According to PrestaShop webservice:
/// - The `price` field is the price IMPACT (not final price)
/// - Final Price = Base Product Price + Combination Price Impact
/// - The associations.product_option_values only contain IDs (with xlink:href)
/// - To get actual attribute names, you must fetch product_option_values/{id}
/// - To get group names (Size, Color), you must fetch product_options/{id}
class Combination {
  final String id;
  final String idProduct;
  final String reference;
  final double priceImpact; // Price difference from base product (can be + or -)
  final int quantity;
  final bool defaultOn;
  final List<String> productOptionValueIds; // Just IDs from associations
  final List<CombinationAttributeDetail> attributes; // Resolved attribute details

  Combination({
    required this.id,
    required this.idProduct,
    required this.reference,
    required this.priceImpact,
    required this.quantity,
    required this.defaultOn,
    this.productOptionValueIds = const [],
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

    // Extract product option value IDs from associations
    // These are just IDs - actual names must be fetched via product_option_values endpoint
    List<String> optionValueIds = [];
    if (json['associations']?['product_option_values'] != null) {
      var optionValues = json['associations']['product_option_values'];

      // Handle XML nested structure
      if (optionValues is Map && optionValues['product_option_value'] != null) {
        optionValues = optionValues['product_option_value'];
      }

      if (optionValues is List) {
        optionValueIds = optionValues
            .map((item) {
              if (item is Map) {
                return item['id']?.toString() ?? '';
              }
              return item.toString();
            })
            .where((id) => id.isNotEmpty)
            .toList();
      } else if (optionValues is Map) {
        final id = optionValues['id']?.toString() ?? '';
        if (id.isNotEmpty) optionValueIds.add(id);
      }
    }

    return Combination(
      id: json['id']?.toString() ?? '',
      idProduct: json['id_product']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      priceImpact: parsePriceImpact(json['price']),
      quantity: parseQuantity(json['quantity']),
      defaultOn: json['default_on'] == '1' || json['default_on'] == true,
      productOptionValueIds: optionValueIds,
    );
  }

  Combination copyWithAttributeDetails(List<CombinationAttributeDetail> details) {
    return Combination(
      id: id,
      idProduct: idProduct,
      reference: reference,
      priceImpact: priceImpact,
      quantity: quantity,
      defaultOn: defaultOn,
      productOptionValueIds: productOptionValueIds,
      attributes: details,
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
      'product_option_value_ids': productOptionValueIds,
    };
  }
}
