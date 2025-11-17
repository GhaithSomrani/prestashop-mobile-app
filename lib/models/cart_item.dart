import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  final String? variantId;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.variantId,
  });

  double get totalPrice => product.finalPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] ?? 1,
      variantId: json['variant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'variant_id': variantId,
    };
  }

  CartItem copyWith({
    Product? product,
    int? quantity,
    String? variantId,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      variantId: variantId ?? this.variantId,
    );
  }
}
