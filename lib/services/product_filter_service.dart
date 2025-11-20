import '../models/product_detail.dart';
import '../utils/price_calculator.dart';

/// Filter criteria for products
class ProductFilterCriteria {
  final double? minPrice;
  final double? maxPrice;
  final bool? inStockOnly;
  final bool? allCombinationsInStock;
  final List<String>? categoryIds;
  final List<String>? manufacturerIds;
  final Map<String, List<String>>? attributes; // {groupId: [valueIds]}
  final bool? onSaleOnly;
  final String? searchQuery;

  ProductFilterCriteria({
    this.minPrice,
    this.maxPrice,
    this.inStockOnly,
    this.allCombinationsInStock,
    this.categoryIds,
    this.manufacturerIds,
    this.attributes,
    this.onSaleOnly,
    this.searchQuery,
  });

  bool get hasFilters =>
      minPrice != null ||
      maxPrice != null ||
      inStockOnly == true ||
      allCombinationsInStock == true ||
      (categoryIds?.isNotEmpty ?? false) ||
      (manufacturerIds?.isNotEmpty ?? false) ||
      (attributes?.isNotEmpty ?? false) ||
      onSaleOnly == true ||
      (searchQuery?.isNotEmpty ?? false);
}

/// Service for filtering products
class ProductFilterService {
  /// Apply filters to a list of products
  List<ProductDetail> filterProducts(
    List<ProductDetail> products,
    ProductFilterCriteria criteria,
  ) {
    if (!criteria.hasFilters) return products;

    return products.where((product) => _matchesCriteria(product, criteria)).toList();
  }

  /// Check if a product matches the filter criteria
  bool _matchesCriteria(ProductDetail product, ProductFilterCriteria criteria) {
    // Price filter
    if (criteria.minPrice != null || criteria.maxPrice != null) {
      final minPrice = criteria.minPrice ?? 0;
      final maxPrice = criteria.maxPrice ?? double.infinity;

      if (!PriceCalculator.isInPriceRange(product, minPrice, maxPrice)) {
        return false;
      }
    }

    // Stock filter
    if (criteria.inStockOnly == true) {
      if (!product.hasStock) {
        return false;
      }
    }

    // All combinations in stock filter
    if (criteria.allCombinationsInStock == true) {
      if (!product.allInStock) {
        return false;
      }
    }

    // Category filter
    if (criteria.categoryIds?.isNotEmpty ?? false) {
      if (!criteria.categoryIds!.contains(product.categoryId)) {
        return false;
      }
    }

    // Manufacturer filter
    if (criteria.manufacturerIds?.isNotEmpty ?? false) {
      if (product.manufacturerId == null ||
          !criteria.manufacturerIds!.contains(product.manufacturerId)) {
        return false;
      }
    }

    // On sale filter
    if (criteria.onSaleOnly == true) {
      if (!product.onSale) {
        return false;
      }
    }

    // Search query filter
    if (criteria.searchQuery?.isNotEmpty ?? false) {
      final query = criteria.searchQuery!.toLowerCase();
      final matchesName = product.name.toLowerCase().contains(query);
      final matchesDescription = product.description.toLowerCase().contains(query);
      final matchesReference = product.reference?.toLowerCase().contains(query) ?? false;

      if (!matchesName && !matchesDescription && !matchesReference) {
        return false;
      }
    }

    // Attribute filter (combinations)
    if (criteria.attributes?.isNotEmpty ?? false) {
      if (!_matchesAttributes(product, criteria.attributes!)) {
        return false;
      }
    }

    return true;
  }

  /// Check if product has combinations with specific attributes
  bool _matchesAttributes(ProductDetail product, Map<String, List<String>> requiredAttributes) {
    if (product.isSimpleProduct) return false;
    if (product.combinations.isEmpty) return false;

    // Check if any combination matches all required attributes
    return product.combinations.any((combination) {
      return requiredAttributes.entries.every((entry) {
        final groupId = entry.key;
        final requiredValueIds = entry.value;

        // Check if combination has any of the required values for this group
        return combination.attributes.any(
          (attr) => attr.groupId == groupId && requiredValueIds.contains(attr.valueId),
        );
      });
    });
  }

  /// Sort products by various criteria
  List<ProductDetail> sortProducts(
    List<ProductDetail> products,
    ProductSortOption sortOption, {
    bool ascending = true,
  }) {
    final sorted = List<ProductDetail>.from(products);

    sorted.sort((a, b) {
      int comparison;

      switch (sortOption) {
        case ProductSortOption.price:
          comparison = a.displayPrice.compareTo(b.displayPrice);
          break;
        case ProductSortOption.name:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case ProductSortOption.stock:
          comparison = a.totalStock.compareTo(b.totalStock);
          break;
        case ProductSortOption.newest:
          // Assuming higher ID = newer
          comparison = int.parse(a.id).compareTo(int.parse(b.id));
          break;
      }

      return ascending ? comparison : -comparison;
    });

    return sorted;
  }

  /// Get unique attribute values from a list of products
  Map<String, Set<String>> getAvailableAttributes(List<ProductDetail> products) {
    final attributes = <String, Set<String>>{};

    for (final product in products) {
      for (final combination in product.combinations) {
        for (final attr in combination.attributes) {
          attributes.putIfAbsent(attr.groupId, () => {}).add(attr.valueId);
        }
      }
    }

    return attributes;
  }

  /// Get price range from a list of products
  PriceRange getOverallPriceRange(List<ProductDetail> products) {
    if (products.isEmpty) {
      return PriceRange(min: 0, max: 0);
    }

    double minPrice = double.infinity;
    double maxPrice = 0;

    for (final product in products) {
      final range = product.priceRange;
      if (range.min < minPrice) minPrice = range.min;
      if (range.max > maxPrice) maxPrice = range.max;
    }

    return PriceRange(min: minPrice, max: maxPrice);
  }

  /// Filter combinations within a product by attributes
  List<ProductCombination> filterCombinations(
    List<ProductCombination> combinations,
    Map<String, String> selectedAttributes, // {groupId: valueId}
  ) {
    if (selectedAttributes.isEmpty) return combinations;

    return combinations.where((combination) {
      return selectedAttributes.entries.every((entry) {
        return combination.attributes.any(
          (attr) => attr.groupId == entry.key && attr.valueId == entry.value,
        );
      });
    }).toList();
  }

  /// Get available values for an attribute group given current selections
  Set<String> getAvailableAttributeValues(
    List<ProductCombination> combinations,
    String groupId,
    Map<String, String> otherSelections,
  ) {
    // Filter combinations by other selections first
    var filtered = combinations;
    for (final entry in otherSelections.entries) {
      if (entry.key != groupId) {
        filtered = filtered.where((c) {
          return c.attributes.any(
            (a) => a.groupId == entry.key && a.valueId == entry.value,
          );
        }).toList();
      }
    }

    // Get available values for the target group
    final values = <String>{};
    for (final combination in filtered) {
      for (final attr in combination.attributes) {
        if (attr.groupId == groupId) {
          values.add(attr.valueId);
        }
      }
    }

    return values;
  }
}

enum ProductSortOption {
  price,
  name,
  stock,
  newest,
}
