import '../utils/language_helper.dart';
import 'combination.dart';

/// Enhanced product model with full combination and pricing data
class ProductDetail {
  final String id;
  final String name;
  final String description;
  final String shortDescription;
  final double basePrice;
  final String? imageUrl;
  final List<String> images;
  final String? reference;
  final bool active;
  final String categoryId;
  final String? manufacturerId;
  final String? manufacturerName;
  final String defaultCombinationId;
  final bool isSimpleProduct;
  final List<ProductCombination> combinations;
  final int simpleProductStock;
  final bool onSale;
  final double? discountPercentage;
  final String? taxRulesGroupId;

  ProductDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.basePrice,
    this.imageUrl,
    this.images = const [],
    this.reference,
    this.active = true,
    required this.categoryId,
    this.manufacturerId,
    this.manufacturerName,
    required this.defaultCombinationId,
    required this.isSimpleProduct,
    this.combinations = const [],
    this.simpleProductStock = 0,
    this.onSale = false,
    this.discountPercentage,
    this.taxRulesGroupId,
  });

  /// Get the default combination
  ProductCombination? get defaultCombination {
    if (isSimpleProduct || combinations.isEmpty) return null;
    return combinations.firstWhere(
      (c) => c.id == defaultCombinationId || c.isDefault,
      orElse: () => combinations.first,
    );
  }

  /// Get the display price (default combination price or base price)
  double get displayPrice {
    if (isSimpleProduct) return basePrice;
    final defaultCombo = defaultCombination;
    return defaultCombo?.finalPrice ?? basePrice;
  }

  /// Get price range across all combinations
  PriceRange get priceRange {
    if (isSimpleProduct || combinations.isEmpty) {
      return PriceRange(min: basePrice, max: basePrice);
    }
    final prices = combinations.map((c) => c.finalPrice).toList();
    return PriceRange(
      min: prices.reduce((a, b) => a < b ? a : b),
      max: prices.reduce((a, b) => a > b ? a : b),
    );
  }

  /// Check if any combination is in stock
  bool get hasStock {
    if (isSimpleProduct) return simpleProductStock > 0;
    return combinations.any((c) => c.inStock);
  }

  /// Check if all combinations are in stock
  bool get allInStock {
    if (isSimpleProduct) return simpleProductStock > 0;
    return combinations.every((c) => c.inStock);
  }

  /// Get total stock across all combinations
  int get totalStock {
    if (isSimpleProduct) return simpleProductStock;
    return combinations.fold(0, (sum, c) => sum + c.quantity);
  }

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? json;

    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseQuantity(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    final defaultCombinationId = product['cache_default_attribute']?.toString() ?? '0';
    final isSimple = defaultCombinationId == '0' || defaultCombinationId.isEmpty;

    // Extract combination IDs from associations
    List<String> combinationIds = [];
    if (product['associations']?['combinations'] != null) {
      var combos = product['associations']['combinations'];
      // Handle XML nested structure
      if (combos is Map && combos['combination'] != null) {
        combos = combos['combination'];
      }
      if (combos is List) {
        combinationIds = combos.map((c) {
          if (c is Map) return c['id']?.toString() ?? '';
          return c.toString();
        }).where((id) => id.isNotEmpty).toList();
      } else if (combos is Map) {
        final id = combos['id']?.toString() ?? '';
        if (id.isNotEmpty) combinationIds.add(id);
      }
    }

    return ProductDetail(
      id: product['id']?.toString() ?? '',
      name: LanguageHelper.extractValueOrEmpty(product['name']),
      description: LanguageHelper.extractValueOrEmpty(product['description']),
      shortDescription: LanguageHelper.extractValueOrEmpty(product['description_short']),
      basePrice: parsePrice(product['price']),
      imageUrl: product['id_default_image'] != null
          ? product['image_url']?.toString()
          : null,
      images: product['images'] != null
          ? List<String>.from((product['images'] as List).map((img) => img.toString()))
          : [],
      reference: product['reference']?.toString(),
      active: product['active'] == '1' || product['active'] == true,
      categoryId: product['id_category_default']?.toString() ?? '0',
      manufacturerId: product['id_manufacturer']?.toString(),
      manufacturerName: product['manufacturer_name']?.toString(),
      defaultCombinationId: defaultCombinationId,
      isSimpleProduct: isSimple,
      simpleProductStock: parseQuantity(product['quantity']),
      onSale: product['on_sale'] == '1' || product['on_sale'] == true,
      discountPercentage: product['discount_percentage'] != null
          ? parsePrice(product['discount_percentage'])
          : null,
      taxRulesGroupId: product['id_tax_rules_group']?.toString(),
    );
  }

  /// Create a copy with combinations populated
  ProductDetail copyWithCombinations(List<ProductCombination> newCombinations) {
    return ProductDetail(
      id: id,
      name: name,
      description: description,
      shortDescription: shortDescription,
      basePrice: basePrice,
      imageUrl: imageUrl,
      images: images,
      reference: reference,
      active: active,
      categoryId: categoryId,
      manufacturerId: manufacturerId,
      manufacturerName: manufacturerName,
      defaultCombinationId: defaultCombinationId,
      isSimpleProduct: isSimpleProduct,
      combinations: newCombinations,
      simpleProductStock: simpleProductStock,
      onSale: onSale,
      discountPercentage: discountPercentage,
      taxRulesGroupId: taxRulesGroupId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'description_short': shortDescription,
      'price': basePrice,
      'image_url': imageUrl,
      'images': images,
      'reference': reference,
      'active': active,
      'id_category_default': categoryId,
      'id_manufacturer': manufacturerId,
      'manufacturer_name': manufacturerName,
      'cache_default_attribute': defaultCombinationId,
      'is_simple_product': isSimpleProduct,
      'combinations': combinations.map((c) => c.toJson()).toList(),
      'simple_product_stock': simpleProductStock,
      'on_sale': onSale,
      'discount_percentage': discountPercentage,
      'id_tax_rules_group': taxRulesGroupId,
    };
  }
}

/// Product combination with full attribute and pricing data
class ProductCombination {
  final String id;
  final String productId;
  final String reference;
  final double priceImpact;
  final double finalPrice;
  final int quantity;
  final bool isDefault;
  final List<CombinationAttributeDetail> attributes;

  ProductCombination({
    required this.id,
    required this.productId,
    required this.reference,
    required this.priceImpact,
    required this.finalPrice,
    required this.quantity,
    required this.isDefault,
    this.attributes = const [],
  });

  bool get inStock => quantity > 0;

  factory ProductCombination.fromCombination(
    Combination combination,
    double basePrice,
    List<CombinationAttributeDetail> attributes,
  ) {
    return ProductCombination(
      id: combination.id,
      productId: combination.idProduct,
      reference: combination.reference,
      priceImpact: combination.priceImpact,
      finalPrice: basePrice + combination.priceImpact,
      quantity: combination.quantity,
      isDefault: combination.defaultOn,
      attributes: attributes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_product': productId,
      'reference': reference,
      'price_impact': priceImpact,
      'final_price': finalPrice,
      'quantity': quantity,
      'is_default': isDefault,
      'in_stock': inStock,
      'attributes': attributes.map((a) => a.toJson()).toList(),
    };
  }
}

/// Detailed attribute information for a combination
class CombinationAttributeDetail {
  final String groupId;
  final String groupName;
  final String valueId;
  final String valueName;
  final String? color;

  CombinationAttributeDetail({
    required this.groupId,
    required this.groupName,
    required this.valueId,
    required this.valueName,
    this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'group_name': groupName,
      'value_id': valueId,
      'value_name': valueName,
      'color': color,
    };
  }
}

/// Price range model
class PriceRange {
  final double min;
  final double max;

  PriceRange({required this.min, required this.max});

  bool get hasRange => min != max;

  String format() {
    if (hasRange) {
      return '${min.toStringAsFixed(2)} - ${max.toStringAsFixed(2)} TND';
    }
    return '${min.toStringAsFixed(2)} TND';
  }
}
