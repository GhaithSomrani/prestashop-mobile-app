import 'package:json_annotation/json_annotation.dart';
import 'product.dart';

part 'cart.g.dart';

@JsonSerializable()
class Cart {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'id_customer')
  final int? customerId;

  @JsonKey(name: 'id_guest', defaultValue: 0)
  final int guestId;

  @JsonKey(name: 'id_currency', defaultValue: 1)
  final int currencyId;

  @JsonKey(name: 'associations', defaultValue: {})
  final CartAssociations associations;

  const Cart({
    this.id,
    this.customerId,
    this.guestId = 0,
    this.currencyId = 1,
    this.associations = const CartAssociations(),
  });

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);
  Map<String, dynamic> toJson() => _$CartToJson(this);

  // Helper methods
  List<CartItem> get items => associations.cartRows ?? [];

  double get subtotal {
    return items.fold(0.0, (total, item) => total + item.totalPrice);
  }

  int get totalItems {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  Cart copyWith({
    int? id,
    int? customerId,
    int? guestId,
    int? currencyId,
    CartAssociations? associations,
  }) {
    return Cart(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      guestId: guestId ?? this.guestId,
      currencyId: currencyId ?? this.currencyId,
      associations: associations ?? this.associations,
    );
  }
}

@JsonSerializable()
class CartAssociations {
  @JsonKey(name: 'cart_rows', defaultValue: [])
  final List<CartItem>? cartRows;

  const CartAssociations({this.cartRows});

  factory CartAssociations.fromJson(Map<String, dynamic> json) => _$CartAssociationsFromJson(json);
  Map<String, dynamic> toJson() => _$CartAssociationsToJson(this);
}

@JsonSerializable()
class CartItem {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'id_product')
  final int productId;

  @JsonKey(name: 'id_product_attribute')
  final int? productAttributeId;

  @JsonKey(name: 'id_address_delivery')
  final int? addressDeliveryId;

  @JsonKey(name: 'quantity', defaultValue: 1)
  final int quantity;

  @JsonKey(name: 'price', defaultValue: 0.0)
  final double unitPrice;

  @JsonKey(name: 'name')
  final String? productName;

  @JsonKey(name: 'image')
  final String? imageUrl;

  @JsonKey(name: 'associations', defaultValue: {})
  final CartItemAssociations associations;

  const CartItem({
    this.id,
    required this.productId,
    this.productAttributeId,
    this.addressDeliveryId,
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.productName,
    this.imageUrl,
    this.associations = const CartItemAssociations(),
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemToJson(this);

  // Helper properties
  double get totalPrice => unitPrice * quantity;

  String get uniqueId {
    final attributeId = productAttributeId ?? 0;
    return '${productId}_$attributeId';
  }

  // For use with Product model from API
  Product? _product;

  Product? get product => _product;

  set product(Product? product) {
    _product = product;
  }

  CartItem copyWith({
    int? id,
    int? productId,
    int? productAttributeId,
    int? addressDeliveryId,
    int? quantity,
    double? unitPrice,
    String? productName,
    String? imageUrl,
    CartItemAssociations? associations,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productAttributeId: productAttributeId ?? this.productAttributeId,
      addressDeliveryId: addressDeliveryId ?? this.addressDeliveryId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      associations: associations ?? this.associations,
    );
  }
}

@JsonSerializable()
class CartItemAssociations {
  @JsonKey(name: 'product', defaultValue: null)
  final ProductRef? product;

  @JsonKey(name: 'product_option_values', defaultValue: [])
  final List<ProductOptionValue>? optionValues;

  const CartItemAssociations({
    this.product,
    this.optionValues,
  });

  factory CartItemAssociations.fromJson(Map<String, dynamic> json) => _$CartItemAssociationsFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemAssociationsToJson(this);
}

@JsonSerializable()
class ProductRef {
  @JsonKey(name: 'id')
  final int id;

  const ProductRef({required this.id});

  factory ProductRef.fromJson(Map<String, dynamic> json) => _$ProductRefFromJson(json);
  Map<String, dynamic> toJson() => _$ProductRefToJson(this);
}

@JsonSerializable()
class ProductOptionValue {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'name')
  final String? name;

  const ProductOptionValue({
    required this.id,
    this.name,
  });

  factory ProductOptionValue.fromJson(Map<String, dynamic> json) => _$ProductOptionValueFromJson(json);
  Map<String, dynamic> toJson() => _$ProductOptionValueToJson(this);
}

// Extension for creating CartItem from Product
extension ProductCartExtension on Product {
  CartItem toCartItem({int quantity = 1, ProductVariant? variant}) {
    return CartItem(
      productId: id,
      quantity: quantity,
      unitPrice: variant?.price ?? effectivePrice,
      productName: name,
      imageUrl: mainImageUrl,
      productAttributeId: variant?.id,
    );
  }
}