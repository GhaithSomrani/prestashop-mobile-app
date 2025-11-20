/// Model for PrestaShop stock availability
class StockAvailable {
  final String id;
  final String productId;
  final String productAttributeId; // 0 for simple products
  final int quantity;
  final bool dependsOnStock;
  final int outOfStockBehavior;
  final String? shopId;

  StockAvailable({
    required this.id,
    required this.productId,
    required this.productAttributeId,
    required this.quantity,
    this.dependsOnStock = false,
    this.outOfStockBehavior = 0,
    this.shopId,
  });

  bool get inStock => quantity > 0;
  bool get isSimpleProduct => productAttributeId == '0';

  factory StockAvailable.fromJson(Map<String, dynamic> json) {
    int parseQuantity(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return StockAvailable(
      id: json['id']?.toString() ?? '',
      productId: json['id_product']?.toString() ?? '',
      productAttributeId: json['id_product_attribute']?.toString() ?? '0',
      quantity: parseQuantity(json['quantity']),
      dependsOnStock: json['depends_on_stock'] == '1' || json['depends_on_stock'] == true,
      outOfStockBehavior: parseQuantity(json['out_of_stock']),
      shopId: json['id_shop']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_product': productId,
      'id_product_attribute': productAttributeId,
      'quantity': quantity,
      'depends_on_stock': dependsOnStock ? '1' : '0',
      'out_of_stock': outOfStockBehavior,
      'id_shop': shopId,
    };
  }
}
