import 'package:json_annotation/json_annotation.dart';
import 'category.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'description')
  final String description;

  @JsonKey(name: 'price')
  final double price;

  @JsonKey(name: 'images', defaultValue: [])
  final List<String> images;

  @JsonKey(name: 'id_category_default')
  final int categoryId;

  @JsonKey(name: 'category', defaultValue: null)
  final Category? category;

  @JsonKey(name: 'quantity', defaultValue: 0)
  final int quantity;

  @JsonKey(name: 'out_of_stock', defaultValue: false)
  final bool outOfStock;

  @JsonKey(name: 'on_sale', defaultValue: false)
  final bool onSale;

  @JsonKey(name: 'reduction_price', defaultValue: null)
  final double? discountPrice;

  @JsonKey(name: 'reference')
  final String? reference;

  @JsonKey(name: 'manufacturer_name', defaultValue: null)
  final String? brand;

  @JsonKey(name: 'condition', defaultValue: 'new')
  final String condition;

  @JsonKey(name: 'features', defaultValue: [])
  final List<ProductFeature> features;

  @JsonKey(name: 'associations', defaultValue: {})
  final ProductAssociations associations;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.images = const [],
    required this.categoryId,
    this.category,
    this.quantity = 0,
    this.outOfStock = false,
    this.onSale = false,
    this.discountPrice,
    this.reference,
    this.brand,
    this.condition = 'new',
    this.features = const [],
    this.associations = const ProductAssociations(),
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  // Helper methods
  bool get inStock => quantity > 0 && !outOfStock;

  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  double get effectivePrice => hasDiscount ? discountPrice! : price;

  double get discountPercentage {
    if (!hasDiscount) return 0.0;
    return ((price - discountPrice!) / price * 100);
  }

  String get mainImageUrl => images.isNotEmpty ? images.first : '';

  List<ProductVariant> get variants => associations.combinations?.map((combo) {
        return ProductVariant(
          id: combo.id,
          productId: id,
          name: _buildVariantName(combo.attributes),
          price: combo.price ?? price,
          imageUrl: mainImageUrl,
          attributes: combo.attributes,
        );
      }).toList() ?? [];

  String _buildVariantName(List<VariantAttribute> attributes) {
    if (attributes.isEmpty) return '';
    return attributes.map((attr) => '${attr.name}: ${attr.value}').join(', ');
  }
}

@JsonSerializable()
class ProductFeature {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'value')
  final String value;

  const ProductFeature({
    required this.id,
    required this.name,
    required this.value,
  });

  factory ProductFeature.fromJson(Map<String, dynamic> json) => _$ProductFeatureFromJson(json);
  Map<String, dynamic> toJson() => _$ProductFeatureToJson(this);
}

@JsonSerializable()
class ProductAssociations {
  @JsonKey(name: 'categories', defaultValue: [])
  final List<CategoryRef>? categories;

  @JsonKey(name: 'images', defaultValue: [])
  final List<ProductImage>? images;

  @JsonKey(name: 'combinations', defaultValue: [])
  final List<ProductCombination>? combinations;

  const ProductAssociations({
    this.categories,
    this.images,
    this.combinations,
  });

  factory ProductAssociations.fromJson(Map<String, dynamic> json) => _$ProductAssociationsFromJson(json);
  Map<String, dynamic> toJson() => _$ProductAssociationsToJson(this);
}

@JsonSerializable()
class CategoryRef {
  @JsonKey(name: 'id')
  final int id;

  const CategoryRef({required this.id});

  factory CategoryRef.fromJson(Map<String, dynamic> json) => _$CategoryRefFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryRefToJson(this);
}

@JsonSerializable()
class ProductImage {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'src')
  final String src;

  const ProductImage({
    required this.id,
    required this.src,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) => _$ProductImageFromJson(json);
  Map<String, dynamic> toJson() => _$ProductImageToJson(this);
}

@JsonSerializable()
class ProductCombination {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'price', defaultValue: null)
  final double? price;

  @JsonKey(name: 'attributes', defaultValue: [])
  final List<VariantAttribute> attributes;

  const ProductCombination({
    required this.id,
    this.price,
    this.attributes = const [],
  });

  factory ProductCombination.fromJson(Map<String, dynamic> json) => _$ProductCombinationFromJson(json);
  Map<String, dynamic> toJson() => _$ProductCombinationToJson(this);
}

@JsonSerializable()
class VariantAttribute {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'value')
  final String value;

  const VariantAttribute({
    required this.id,
    required this.name,
    required this.value,
  });

  factory VariantAttribute.fromJson(Map<String, dynamic> json) => _$VariantAttributeFromJson(json);
  Map<String, dynamic> toJson() => _$VariantAttributeToJson(this);
}

class ProductVariant {
  final int id;
  final int productId;
  final String name;
  final double price;
  final String imageUrl;
  final List<VariantAttribute> attributes;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.attributes,
  });
}