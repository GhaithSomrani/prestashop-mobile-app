import '../models/product_detail.dart';

/// Comprehensive filter engine for products
/// Supports price, stock, attributes, and combined filtering
class ProductFilterEngine {
  /// Apply multiple filters to a list of products
  ///
  /// Filters are applied in optimal order:
  /// 1. Stock filter (quick elimination)
  /// 2. Category/Manufacturer filter
  /// 3. Price range filter
  /// 4. Attribute filter (most expensive)
  static List<ProductDetail> applyFilters(
    List<ProductDetail> products, {
    ProductFilters? filters,
  }) {
    if (filters == null) return products;

    var result = products;

    // 1. Apply stock filter first (cheap check)
    if (filters.inStockOnly) {
      result = result.where((p) => p.hasStock).toList();
    }

    // 2. Apply category filter
    if (filters.categoryId != null) {
      result = result.where((p) => p.categoryId == filters.categoryId).toList();
    }

    // 3. Apply manufacturer filter
    if (filters.manufacturerId != null) {
      result = result.where((p) => p.manufacturerId == filters.manufacturerId).toList();
    }

    // 4. Apply price range filter
    if (filters.minPrice != null || filters.maxPrice != null) {
      result = _filterByPriceRange(result, filters.minPrice, filters.maxPrice);
    }

    // 5. Apply attribute filters (most expensive)
    if (filters.attributeFilters.isNotEmpty) {
      result = _filterByAttributes(result, filters.attributeFilters);
    }

    // 6. Apply sort
    if (filters.sortBy != null) {
      result = _sortProducts(result, filters.sortBy!);
    }

    // 7. Apply pagination
    if (filters.offset != null || filters.limit != null) {
      final start = filters.offset ?? 0;
      final end = filters.limit != null ? start + filters.limit! : result.length;
      result = result.sublist(
        start.clamp(0, result.length),
        end.clamp(0, result.length),
      );
    }

    return result;
  }

  /// Filter products by price range, accounting for combinations
  static List<ProductDetail> filterByPriceRange(
    List<ProductDetail> products,
    double minPrice,
    double maxPrice,
  ) {
    return _filterByPriceRange(products, minPrice, maxPrice);
  }

  /// Filter products by stock availability
  static List<ProductDetail> filterByStock(
    List<ProductDetail> products, {
    bool anyInStock = true,
    bool allInStock = false,
  }) {
    if (allInStock) {
      return products.where((p) => p.allInStock).toList();
    }
    if (anyInStock) {
      return products.where((p) => p.hasStock).toList();
    }
    return products;
  }

  /// Filter products by attribute combinations
  ///
  /// Example: filterByAttributes(products, {"Size": "L", "Color": "Red"})
  /// Returns products that have at least one combination matching all filters
  static List<ProductDetail> filterByAttributes(
    List<ProductDetail> products,
    Map<String, String> attributeFilters,
  ) {
    return _filterByAttributes(products, attributeFilters);
  }

  /// Filter products by specific attribute values (OR logic within same group)
  ///
  /// Example: filterByAttributeValues(products, {"Color": ["Red", "Blue"]})
  /// Returns products that have combinations with Color = Red OR Color = Blue
  static List<ProductDetail> filterByAttributeValues(
    List<ProductDetail> products,
    Map<String, List<String>> attributeFilters,
  ) {
    return products.where((product) {
      if (product.isSimpleProduct || product.combinations.isEmpty) {
        return false;
      }

      // Product matches if any combination matches all attribute groups
      return product.combinations.any((combo) {
        for (final entry in attributeFilters.entries) {
          final groupName = entry.key;
          final acceptableValues = entry.value;

          // Check if this combination has any of the acceptable values for this group
          final hasMatchingAttribute = combo.attributes.any((attr) =>
              attr.groupName.toLowerCase() == groupName.toLowerCase() &&
              acceptableValues.any(
                  (v) => v.toLowerCase() == attr.valueName.toLowerCase()));

          if (!hasMatchingAttribute) return false;
        }
        return true;
      });
    }).toList();
  }

  /// Get unique attribute values from products
  ///
  /// Returns a map of attribute group names to available values
  /// Example: {"Size": ["S", "M", "L", "XL"], "Color": ["Red", "Blue", "Green"]}
  static Map<String, List<String>> getAvailableAttributes(
    List<ProductDetail> products,
  ) {
    final result = <String, Set<String>>{};

    for (final product in products) {
      for (final combo in product.combinations) {
        for (final attr in combo.attributes) {
          result.putIfAbsent(attr.groupName, () => {}).add(attr.valueName);
        }
      }
    }

    return result.map((key, value) => MapEntry(key, value.toList()..sort()));
  }

  /// Get price range across all products
  static PriceRange getPriceRange(List<ProductDetail> products) {
    if (products.isEmpty) {
      return PriceRange(min: 0, max: 0);
    }

    double minPrice = double.infinity;
    double maxPrice = 0;

    for (final product in products) {
      if (product.isSimpleProduct) {
        if (product.basePrice < minPrice) minPrice = product.basePrice;
        if (product.basePrice > maxPrice) maxPrice = product.basePrice;
      } else {
        for (final combo in product.combinations) {
          if (combo.finalPrice < minPrice) minPrice = combo.finalPrice;
          if (combo.finalPrice > maxPrice) maxPrice = combo.finalPrice;
        }
      }
    }

    return PriceRange(
      min: minPrice == double.infinity ? 0 : minPrice,
      max: maxPrice,
    );
  }

  /// Get stock statistics for products
  static StockStatistics getStockStatistics(List<ProductDetail> products) {
    int totalProducts = products.length;
    int inStockProducts = 0;
    int outOfStockProducts = 0;
    int totalStock = 0;

    for (final product in products) {
      if (product.hasStock) {
        inStockProducts++;
        totalStock += product.totalStock;
      } else {
        outOfStockProducts++;
      }
    }

    return StockStatistics(
      totalProducts: totalProducts,
      inStockProducts: inStockProducts,
      outOfStockProducts: outOfStockProducts,
      totalStock: totalStock,
    );
  }

  /// Sort products by various criteria
  static List<ProductDetail> sortProducts(
    List<ProductDetail> products,
    String sortBy,
  ) {
    return _sortProducts(List.from(products), sortBy);
  }

  // Private implementation methods

  static List<ProductDetail> _filterByPriceRange(
    List<ProductDetail> products,
    double? minPrice,
    double? maxPrice,
  ) {
    return products.where((product) {
      if (product.isSimpleProduct) {
        final price = product.basePrice;
        if (minPrice != null && price < minPrice) return false;
        if (maxPrice != null && price > maxPrice) return false;
        return true;
      }

      if (product.combinations.isEmpty) {
        final price = product.basePrice;
        if (minPrice != null && price < minPrice) return false;
        if (maxPrice != null && price > maxPrice) return false;
        return true;
      }

      // Check if any combination falls within range
      for (final combo in product.combinations) {
        final price = combo.finalPrice;
        final matchesMin = minPrice == null || price >= minPrice;
        final matchesMax = maxPrice == null || price <= maxPrice;
        if (matchesMin && matchesMax) return true;
      }

      return false;
    }).toList();
  }

  static List<ProductDetail> _filterByAttributes(
    List<ProductDetail> products,
    Map<String, String> attributeFilters,
  ) {
    if (attributeFilters.isEmpty) return products;

    return products.where((product) {
      if (product.isSimpleProduct || product.combinations.isEmpty) {
        return false;
      }

      // Check if any combination matches all attribute filters
      return product.combinations.any((combo) {
        for (final entry in attributeFilters.entries) {
          final groupName = entry.key;
          final valueName = entry.value;

          final hasMatch = combo.attributes.any((attr) =>
              attr.groupName.toLowerCase() == groupName.toLowerCase() &&
              attr.valueName.toLowerCase() == valueName.toLowerCase());

          if (!hasMatch) return false;
        }
        return true;
      });
    }).toList();
  }

  static List<ProductDetail> _sortProducts(
    List<ProductDetail> products,
    String sortBy,
  ) {
    switch (sortBy) {
      case 'price_ASC':
        products.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
        break;
      case 'price_DESC':
        products.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
        break;
      case 'name_ASC':
        products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_DESC':
        products.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'id_ASC':
        products.sort((a, b) {
          final aId = int.tryParse(a.id) ?? 0;
          final bId = int.tryParse(b.id) ?? 0;
          return aId.compareTo(bId);
        });
        break;
      case 'id_DESC':
        products.sort((a, b) {
          final aId = int.tryParse(a.id) ?? 0;
          final bId = int.tryParse(b.id) ?? 0;
          return bId.compareTo(aId);
        });
        break;
      case 'stock_ASC':
        products.sort((a, b) => a.totalStock.compareTo(b.totalStock));
        break;
      case 'stock_DESC':
        products.sort((a, b) => b.totalStock.compareTo(a.totalStock));
        break;
      default:
        break;
    }
    return products;
  }
}

/// Filter configuration for products
class ProductFilters {
  final String? categoryId;
  final String? manufacturerId;
  final double? minPrice;
  final double? maxPrice;
  final bool inStockOnly;
  final Map<String, String> attributeFilters;
  final String? sortBy;
  final int? limit;
  final int? offset;

  const ProductFilters({
    this.categoryId,
    this.manufacturerId,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
    this.attributeFilters = const {},
    this.sortBy,
    this.limit,
    this.offset,
  });

  ProductFilters copyWith({
    String? categoryId,
    String? manufacturerId,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    Map<String, String>? attributeFilters,
    String? sortBy,
    int? limit,
    int? offset,
  }) {
    return ProductFilters(
      categoryId: categoryId ?? this.categoryId,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      attributeFilters: attributeFilters ?? this.attributeFilters,
      sortBy: sortBy ?? this.sortBy,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Check if any filters are active
  bool get hasActiveFilters =>
      categoryId != null ||
      manufacturerId != null ||
      minPrice != null ||
      maxPrice != null ||
      inStockOnly ||
      attributeFilters.isNotEmpty;

  /// Reset all filters
  ProductFilters reset() {
    return const ProductFilters();
  }
}

/// Stock statistics for a list of products
class StockStatistics {
  final int totalProducts;
  final int inStockProducts;
  final int outOfStockProducts;
  final int totalStock;

  StockStatistics({
    required this.totalProducts,
    required this.inStockProducts,
    required this.outOfStockProducts,
    required this.totalStock,
  });

  double get inStockPercentage =>
      totalProducts > 0 ? (inStockProducts / totalProducts * 100) : 0;
}
