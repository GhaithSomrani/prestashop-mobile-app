class Product {
  final String id;
  final String name;
  final String description;
  final String shortDescription;
  final double price;
  final double? reducedPrice;
  final String? imageUrl;
  final List<String> images;
  final int quantity;
  final String? reference;
  final bool active;
  final String categoryId;
  final String? manufacturerId;
  final String? manufacturerName;
  final String? defaultCombinationId;
  final List<ProductVariant>? variants;
  final bool onSale;
  final double? discountPercentage;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.price,
    this.reducedPrice,
    this.imageUrl,
    this.images = const [],
    required this.quantity,
    this.reference,
    this.active = true,
    required this.categoryId,
    this.manufacturerId,
    this.manufacturerName,
    this.defaultCombinationId,
    this.variants,
    this.onSale = false,
    this.discountPercentage,
  });

  bool get isOnSale => onSale || (reducedPrice != null && reducedPrice! < price);
  double get calculatedDiscountPercentage =>
      discountPercentage ?? (isOnSale && reducedPrice != null ? ((price - reducedPrice!) / price * 100) : 0);
  double get finalPrice => reducedPrice ?? price;
  bool get inStock => quantity > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      final product = json['product'] ?? json;

      // Handle price - could be string or number
      double parsePrice(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString()) ?? 0.0;
      }

      // Handle quantity
      int parseQuantity(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        return int.tryParse(value.toString()) ?? 0;
      }

      return Product(
        id: product['id']?.toString() ?? '',
        name: product['name']?.toString() ?? '',
        description: product['description']?.toString() ?? '',
        shortDescription: product['description_short']?.toString() ?? '',
        price: parsePrice(product['price']),
        reducedPrice: product['price_final'] != null
            ? parsePrice(product['price_final'])
            : null,
        imageUrl: product['id_default_image'] != null
            ? product['image_url']?.toString()
            : null,
        images: product['images'] != null
            ? List<String>.from(
                (product['images'] as List).map((img) => img.toString()))
            : [],
        quantity: parseQuantity(product['quantity']),
        reference: product['reference']?.toString(),
        active: product['active'] == '1' || product['active'] == true,
        categoryId: product['id_category_default']?.toString() ?? '0',
        manufacturerId: product['id_manufacturer']?.toString(),
        manufacturerName: product['manufacturer_name']?.toString(),
        defaultCombinationId: product['id_default_combination']?.toString(),
        variants: product['variants'] != null
            ? (product['variants'] as List)
                .map((v) => ProductVariant.fromJson(v))
                .toList()
            : null,
        onSale: product['on_sale'] == '1' || product['on_sale'] == true,
        discountPercentage: product['discount_percentage'] != null
            ? parsePrice(product['discount_percentage'])
            : null,
      );
    } catch (e) {
      throw Exception('Failed to parse product: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'description_short': shortDescription,
      'price': price,
      'price_final': reducedPrice,
      'image_url': imageUrl,
      'images': images,
      'quantity': quantity,
      'reference': reference,
      'active': active,
      'id_category_default': categoryId,
      'id_manufacturer': manufacturerId,
      'manufacturer_name': manufacturerName,
      'id_default_combination': defaultCombinationId,
      'variants': variants?.map((v) => v.toJson()).toList(),
      'on_sale': onSale,
      'discount_percentage': discountPercentage,
    };
  }

  // Copy with method for easier updates
  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? shortDescription,
    double? price,
    double? reducedPrice,
    String? imageUrl,
    List<String>? images,
    int? quantity,
    String? reference,
    bool? active,
    String? categoryId,
    String? manufacturerId,
    String? manufacturerName,
    String? defaultCombinationId,
    List<ProductVariant>? variants,
    bool? onSale,
    double? discountPercentage,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      price: price ?? this.price,
      reducedPrice: reducedPrice ?? this.reducedPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      quantity: quantity ?? this.quantity,
      reference: reference ?? this.reference,
      active: active ?? this.active,
      categoryId: categoryId ?? this.categoryId,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      defaultCombinationId: defaultCombinationId ?? this.defaultCombinationId,
      variants: variants ?? this.variants,
      onSale: onSale ?? this.onSale,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }
}

class ProductVariant {
  final String id;
  final String name;
  final double priceImpact;
  final int quantity;

  ProductVariant({
    required this.id,
    required this.name,
    required this.priceImpact,
    required this.quantity,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      priceImpact: json['price_impact'] is num
          ? (json['price_impact'] as num).toDouble()
          : double.tryParse(json['price_impact']?.toString() ?? '0') ?? 0.0,
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price_impact': priceImpact,
      'quantity': quantity,
    };
  }
}
