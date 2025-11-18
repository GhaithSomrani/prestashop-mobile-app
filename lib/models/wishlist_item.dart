import 'product.dart';

/// Model for wishlist item
class WishlistItem {
  final String productId;
  final String name;
  final String? imageUrl;
  final double price;
  final double? reducedPrice;
  final DateTime addedAt;
  final bool inStock;

  WishlistItem({
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.price,
    this.reducedPrice,
    required this.addedAt,
    this.inStock = true,
  });

  double get finalPrice => reducedPrice ?? price;
  bool get isOnSale => reducedPrice != null && reducedPrice! < price;

  factory WishlistItem.fromProduct(Product product) {
    return WishlistItem(
      productId: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      price: product.price,
      reducedPrice: product.reducedPrice,
      addedAt: DateTime.now(),
      inStock: product.inStock,
    );
  }

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      productId: json['productId'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      price: (json['price'] as num).toDouble(),
      reducedPrice: json['reducedPrice'] != null
          ? (json['reducedPrice'] as num).toDouble()
          : null,
      addedAt: DateTime.parse(json['addedAt'] as String),
      inStock: json['inStock'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'reducedPrice': reducedPrice,
      'addedAt': addedAt.toIso8601String(),
      'inStock': inStock,
    };
  }
}
