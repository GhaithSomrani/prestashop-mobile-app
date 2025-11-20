import '../models/product_detail.dart';
import '../models/product_option.dart';
import '../models/combination.dart';
import '../models/stock_available.dart';
import '../config/api_config.dart';
import '../utils/cache_manager.dart';
import 'api_service.dart';
import 'stock_service.dart';
import 'combination_service.dart';
import 'product_option_service.dart';

/// Comprehensive product fetching service following PrestaShop webservice xlink:href pattern
///
/// Data Flow (following xlink:href references):
/// 1. Fetch Product with display=full
///    - Get base price from product.price
///    - Get default combination ID from cache_default_attribute
///    - Get combination IDs from associations.combinations (just IDs with xlink:href)
///
/// 2. Fetch Combinations (batch by IDs)
///    GET /api/combinations?filter[id]=[1|2|3|4|5]&display=full
///    - Get price impact from combination.price (this is NOT final price!)
///    - Get product_option_value IDs from associations.product_option_values
///
/// 3. Fetch Product Option Values (batch by IDs)
///    GET /api/product_option_values?filter[id]=[1|2|3|4]&display=full
///    - Get attribute value name (e.g., "S", "M", "L", "Red", "Blue")
///    - Get id_attribute_group (points to product_options)
///
/// 4. Fetch Product Options / Attribute Groups (batch by IDs)
///    GET /api/product_options?filter[id]=[1|2]&display=full
///    - Get group name (e.g., "Size", "Color")
///    - Get is_color_group flag
///
/// 5. Calculate Final Prices
///    Final Price = Base Product Price + Combination Price Impact
///
class ComprehensiveProductService {
  final ApiService _apiService;
  late final StockService _stockService;
  late final CombinationService _combinationService;
  late final ProductOptionService _productOptionService;
  final CacheManager _cache = CacheManager();

  ComprehensiveProductService(this._apiService) {
    _stockService = StockService(_apiService);
    _combinationService = CombinationService(_apiService);
    _productOptionService = ProductOptionService(_apiService);
  }

  /// Get a single product with full details including resolved combinations
  ///
  /// This follows the complete xlink:href chain:
  /// Product → Combinations → Product Option Values → Product Options
  Future<ProductDetail> getProductWithFullDetails(String productId) async {
    try {
      // Step 1: Fetch product with full associations
      final response = await _apiService.get(
        '${ApiConfig.productsEndpoint}/$productId',
        queryParameters: {'display': 'full'},
      );

      if (response['product'] == null) {
        throw Exception('Product not found');
      }

      ProductDetail product = ProductDetail.fromJson(response['product']);

      // Step 2: Handle simple products (no combinations)
      if (product.isSimpleProduct) {
        final stock = await _stockService.getSimpleProductStock(productId);
        return product.copyWith(
          simpleProductStock: stock?.quantity ?? 0,
        );
      }

      // Step 3: Fetch all combinations for the product
      final combinations = await _combinationService.getCombinationsByProduct(productId);

      if (combinations.isEmpty) {
        return product;
      }

      // Step 4: Collect all product_option_value IDs from all combinations
      final allOptionValueIds = <String>{};
      for (final combo in combinations) {
        allOptionValueIds.addAll(combo.productOptionValueIds);
      }

      // Step 5: Batch fetch all product option values
      final optionValues = await _productOptionService.getProductOptionValues(
        allOptionValueIds.toList(),
      );

      // Step 6: Collect all attribute group IDs (id_attribute_group)
      final attributeGroupIds = optionValues.values
          .map((v) => v.optionId)
          .toSet()
          .toList();

      // Step 7: Batch fetch all product options (attribute groups)
      final attributeGroups = await _productOptionService.getProductOptions(
        attributeGroupIds,
      );

      // Step 8: Get stock for all combinations
      final stockMap = await _getStockMapForProduct(productId);

      // Step 9: Build complete ProductCombination objects with resolved attributes
      final productCombinations = _buildResolvedCombinations(
        combinations,
        product.basePrice,
        stockMap,
        optionValues,
        attributeGroups,
      );

      // Step 10: Find default combination and calculate price range
      ProductCombination? defaultCombo;
      if (productCombinations.isNotEmpty) {
        defaultCombo = productCombinations.firstWhere(
          (c) => c.id == product.defaultCombinationId || c.isDefault,
          orElse: () => productCombinations.first,
        );
      }

      final priceRange = _calculatePriceRange(product, productCombinations);

      return product.copyWith(
        combinations: productCombinations,
        defaultCombination: defaultCombo,
        priceRange: priceRange,
      );
    } catch (e) {
      throw Exception('Failed to fetch product with full details: $e');
    }
  }

  /// Get multiple products with full details (optimized with batching)
  Future<List<ProductDetail>> getProductsWithFullDetails(
    List<String> productIds, {
    bool resolveAttributes = true,
  }) async {
    if (productIds.isEmpty) return [];

    try {
      // Batch fetch products
      final idsFilter = productIds.join('|');
      final response = await _apiService.get(
        ApiConfig.productsEndpoint,
        queryParameters: {
          'filter[id]': '[$idsFilter]',
          'display': 'full',
        },
      );

      final products = _parseProductList(response);
      if (products.isEmpty) return [];

      // Separate simple and combination products
      final simpleProducts = products.where((p) => p.isSimpleProduct).toList();
      final combinationProducts = products.where((p) => !p.isSimpleProduct).toList();

      // Get stock for simple products
      final simpleProductIds = simpleProducts.map((p) => p.id).toList();
      final simpleStockMap = await _stockService.getStockForProducts(simpleProductIds);

      // Update simple products with stock
      final updatedSimpleProducts = simpleProducts.map((product) {
        final stocks = simpleStockMap[product.id] ?? [];
        final simpleStock = stocks.firstWhere(
          (s) => s.productAttributeId == '0',
          orElse: () => StockAvailable(
            id: '0',
            productId: product.id,
            productAttributeId: '0',
            quantity: 0,
          ),
        );
        return product.copyWith(simpleProductStock: simpleStock.quantity);
      }).toList();

      if (combinationProducts.isEmpty) {
        return updatedSimpleProducts;
      }

      // Get all combinations for all combination products
      final combinationProductIds = combinationProducts.map((p) => p.id).toList();
      final allCombinationsMap = await _combinationService.getCombinationsForProducts(
        combinationProductIds,
      );

      // Collect ALL product_option_value IDs from ALL combinations
      final allOptionValueIds = <String>{};
      for (final combos in allCombinationsMap.values) {
        for (final combo in combos) {
          allOptionValueIds.addAll(combo.productOptionValueIds);
        }
      }

      // Batch fetch option values and groups if needed
      Map<String, ProductOptionValue> optionValues = {};
      Map<String, ProductOption> attributeGroups = {};

      if (resolveAttributes && allOptionValueIds.isNotEmpty) {
        // Batch fetch all product option values
        optionValues = await _productOptionService.getProductOptionValues(
          allOptionValueIds.toList(),
        );

        // Collect and batch fetch all attribute groups
        final attributeGroupIds = optionValues.values
            .map((v) => v.optionId)
            .toSet()
            .toList();
        attributeGroups = await _productOptionService.getProductOptions(
          attributeGroupIds,
        );
      }

      // Get stock for all combination products
      final allStockMap = await _stockService.getStockForProducts(combinationProductIds);

      // Build complete products with resolved combinations
      final updatedCombinationProducts = combinationProducts.map((product) {
        final combinations = allCombinationsMap[product.id] ?? [];
        final stockList = allStockMap[product.id] ?? [];

        // Build stock map for this product
        final stockMap = <String, int>{};
        for (final stock in stockList) {
          if (stock.productAttributeId != '0') {
            stockMap[stock.productAttributeId] = stock.quantity;
          }
        }

        // Build resolved combinations
        final productCombinations = _buildResolvedCombinations(
          combinations,
          product.basePrice,
          stockMap,
          optionValues,
          attributeGroups,
        );

        if (productCombinations.isEmpty) {
          return product;
        }

        // Find default and calculate price range
        final defaultCombo = productCombinations.firstWhere(
          (c) => c.id == product.defaultCombinationId || c.isDefault,
          orElse: () => productCombinations.first,
        );

        final priceRange = _calculatePriceRange(product, productCombinations);

        return product.copyWith(
          combinations: productCombinations,
          defaultCombination: defaultCombo,
          priceRange: priceRange,
        );
      }).toList();

      return [...updatedSimpleProducts, ...updatedCombinationProducts];
    } catch (e) {
      throw Exception('Failed to fetch products with full details: $e');
    }
  }

  /// Get products with stock using two-stage filtering
  ///
  /// Stage 1: GET /api/stock_availables?display=[id_product]&filter[quantity]=[1,]
  /// Stage 2: GET /api/products?filter[id]=[1|5|8|12|15]&display=full
  Future<List<ProductDetail>> getProductsWithStock({
    int? limit,
    int? offset,
    int minQuantity = 1,
    bool resolveAttributes = true,
  }) async {
    try {
      // Stage 1: Get product IDs that have stock
      final productIdsWithStock = await _stockService.getProductIdsWithStock(
        minQuantity: minQuantity,
      );

      if (productIdsWithStock.isEmpty) {
        return [];
      }

      // Stage 2: Fetch only products with stock
      final productIdList = productIdsWithStock.toList();

      // Apply pagination
      final start = offset ?? 0;
      final end = limit != null ? start + limit : productIdList.length;
      final paginatedIds = productIdList.sublist(
        start.clamp(0, productIdList.length),
        end.clamp(0, productIdList.length),
      );

      if (paginatedIds.isEmpty) {
        return [];
      }

      return await getProductsWithFullDetails(
        paginatedIds,
        resolveAttributes: resolveAttributes,
      );
    } catch (e) {
      throw Exception('Failed to fetch products with stock: $e');
    }
  }

  /// Get filtered products with full combination resolution
  Future<List<ProductDetail>> getFilteredProducts({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool inStockOnly = false,
    String? manufacturerId,
    Map<String, String>? attributeFilters,
    int? limit,
    int? offset,
    String? sortBy,
    bool resolveAttributes = true,
  }) async {
    try {
      List<String> productIds;

      // Start with stock filter if needed (most efficient first)
      if (inStockOnly) {
        final stockIds = await _stockService.getProductIdsWithStock();
        productIds = stockIds.toList();

        if (productIds.isEmpty) {
          return [];
        }
      } else {
        // Fetch product IDs with basic filters
        productIds = await _fetchProductIds(
          categoryId: categoryId,
          manufacturerId: manufacturerId,
        );
      }

      if (productIds.isEmpty) {
        return [];
      }

      // Fetch products with full details
      var products = await getProductsWithFullDetails(
        productIds,
        resolveAttributes: resolveAttributes,
      );

      // Apply category filter
      if (categoryId != null) {
        products = products.where((p) => p.categoryId == categoryId).toList();
      }

      // Apply manufacturer filter
      if (manufacturerId != null) {
        products = products.where((p) => p.manufacturerId == manufacturerId).toList();
      }

      // Apply price range filter (accounting for combinations)
      if (minPrice != null || maxPrice != null) {
        products = products.where((product) {
          return _productMatchesPriceRange(product, minPrice, maxPrice);
        }).toList();
      }

      // Apply attribute filters
      if (attributeFilters != null && attributeFilters.isNotEmpty) {
        products = products.where((product) {
          return _productMatchesAttributeFilters(product, attributeFilters);
        }).toList();
      }

      // Apply in-stock filter
      if (inStockOnly) {
        products = products.where((p) => p.hasStock).toList();
      }

      // Sort products
      if (sortBy != null) {
        products = _sortProducts(products, sortBy);
      }

      // Apply pagination
      if (offset != null || limit != null) {
        final start = offset ?? 0;
        final end = limit != null ? start + limit : products.length;
        products = products.sublist(
          start.clamp(0, products.length),
          end.clamp(0, products.length),
        );
      }

      return products;
    } catch (e) {
      throw Exception('Failed to fetch filtered products: $e');
    }
  }

  /// Calculate final price for a combination
  /// Formula: Base Product Price + Combination Price Impact
  double calculateFinalPrice(double basePrice, double priceImpact) {
    return basePrice + priceImpact;
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  List<ProductDetail> _parseProductList(Map<String, dynamic> response) {
    if (response['products'] == null) return [];

    var productsData = response['products'];

    // Handle XML nested structure
    if (productsData is Map && productsData['product'] != null) {
      productsData = productsData['product'];
    }

    if (productsData is List) {
      return productsData
          .map((json) => ProductDetail.fromJson(json))
          .toList();
    } else if (productsData is Map) {
      return [ProductDetail.fromJson(productsData as Map<String, dynamic>)];
    }

    return [];
  }

  Future<Map<String, int>> _getStockMapForProduct(String productId) async {
    final stocks = await _stockService.getStockByProduct(productId);
    final stockMap = <String, int>{};

    for (final stock in stocks) {
      if (stock.productAttributeId != '0') {
        stockMap[stock.productAttributeId] = stock.quantity;
      }
    }

    return stockMap;
  }

  /// Build resolved ProductCombination objects with attribute names
  ///
  /// This takes the raw combinations (with just IDs) and resolves them
  /// to full attribute information using the fetched option values and groups
  List<ProductCombination> _buildResolvedCombinations(
    List<Combination> combinations,
    double basePrice,
    Map<String, int> stockMap,
    Map<String, ProductOptionValue> optionValues,
    Map<String, ProductOption> attributeGroups,
  ) {
    return combinations.map((combo) {
      // Resolve each product_option_value ID to its full attribute info
      final resolvedAttributes = <CombinationAttributeDetail>[];

      for (final valueId in combo.productOptionValueIds) {
        final optionValue = optionValues[valueId];
        if (optionValue != null) {
          final attributeGroup = attributeGroups[optionValue.optionId];

          resolvedAttributes.add(CombinationAttributeDetail(
            groupId: optionValue.optionId,
            groupName: attributeGroup?.publicName ?? attributeGroup?.name ?? '',
            valueId: valueId,
            valueName: optionValue.name,
            color: optionValue.color,
          ));
        }
      }

      // Get stock quantity (from stock_availables or combination's quantity)
      final quantity = stockMap[combo.id] ?? combo.quantity;

      // Calculate final price: Base Price + Price Impact
      final finalPrice = basePrice + combo.priceImpact;

      return ProductCombination(
        id: combo.id,
        productId: combo.idProduct,
        reference: combo.reference,
        priceImpact: combo.priceImpact,
        finalPrice: finalPrice,
        quantity: quantity,
        isDefault: combo.defaultOn,
        attributes: resolvedAttributes,
      );
    }).toList();
  }

  PriceRange _calculatePriceRange(
    ProductDetail product,
    List<ProductCombination> combinations,
  ) {
    if (product.isSimpleProduct || combinations.isEmpty) {
      return PriceRange(min: product.basePrice, max: product.basePrice);
    }

    final prices = combinations.map((c) => c.finalPrice).toList();
    return PriceRange(
      min: prices.reduce((a, b) => a < b ? a : b),
      max: prices.reduce((a, b) => a > b ? a : b),
    );
  }

  Future<List<String>> _fetchProductIds({
    String? categoryId,
    String? manufacturerId,
  }) async {
    try {
      final queryParams = <String, String>{
        'display': '[id]',
        'filter[active]': '1',
        if (categoryId != null) 'filter[id_category_default]': categoryId,
        if (manufacturerId != null) 'filter[id_manufacturer]': manufacturerId,
      };

      final response = await _apiService.get(
        ApiConfig.productsEndpoint,
        queryParameters: queryParams,
      );

      if (response['products'] == null) return [];

      var productsData = response['products'];
      if (productsData is Map && productsData['product'] != null) {
        productsData = productsData['product'];
      }

      if (productsData is List) {
        return productsData
            .map((p) => (p['id'] ?? p).toString())
            .where((id) => id.isNotEmpty)
            .toList();
      } else if (productsData is Map) {
        final id = (productsData['id'] ?? productsData).toString();
        return id.isNotEmpty ? [id] : [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  bool _productMatchesPriceRange(
    ProductDetail product,
    double? minPrice,
    double? maxPrice,
  ) {
    if (product.isSimpleProduct) {
      final price = product.basePrice;
      if (minPrice != null && price < minPrice) return false;
      if (maxPrice != null && price > maxPrice) return false;
      return true;
    }

    // For combination products, check if ANY combination falls within range
    for (final combo in product.combinations) {
      final price = combo.finalPrice;
      final matchesMin = minPrice == null || price >= minPrice;
      final matchesMax = maxPrice == null || price <= maxPrice;
      if (matchesMin && matchesMax) return true;
    }

    return false;
  }

  bool _productMatchesAttributeFilters(
    ProductDetail product,
    Map<String, String> attributeFilters,
  ) {
    if (product.isSimpleProduct || product.combinations.isEmpty) {
      return false;
    }

    // Check if any combination matches ALL attribute filters
    for (final combo in product.combinations) {
      bool allMatch = true;

      for (final entry in attributeFilters.entries) {
        final groupName = entry.key;
        final valueName = entry.value;

        final hasMatch = combo.attributes.any((attr) =>
            attr.groupName.toLowerCase() == groupName.toLowerCase() &&
            attr.valueName.toLowerCase() == valueName.toLowerCase());

        if (!hasMatch) {
          allMatch = false;
          break;
        }
      }

      if (allMatch) return true;
    }

    return false;
  }

  List<ProductDetail> _sortProducts(List<ProductDetail> products, String sortBy) {
    final sorted = List<ProductDetail>.from(products);

    switch (sortBy) {
      case 'price_ASC':
        sorted.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
        break;
      case 'price_DESC':
        sorted.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
        break;
      case 'name_ASC':
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_DESC':
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'id_ASC':
        sorted.sort((a, b) {
          final aId = int.tryParse(a.id) ?? 0;
          final bId = int.tryParse(b.id) ?? 0;
          return aId.compareTo(bId);
        });
        break;
      case 'id_DESC':
        sorted.sort((a, b) {
          final aId = int.tryParse(a.id) ?? 0;
          final bId = int.tryParse(b.id) ?? 0;
          return bId.compareTo(aId);
        });
        break;
    }

    return sorted;
  }
}

/// Extension for ProductDetail with filtering helpers
extension ProductDetailFiltering on ProductDetail {
  /// Get combinations that match specific attribute filters
  List<ProductCombination> getCombinationsWithAttributes(
    Map<String, String> attributeFilters,
  ) {
    if (isSimpleProduct || combinations.isEmpty) return [];

    return combinations.where((combo) {
      for (final entry in attributeFilters.entries) {
        final groupName = entry.key;
        final valueName = entry.value;

        final hasMatch = combo.attributes.any((attr) =>
            attr.groupName.toLowerCase() == groupName.toLowerCase() &&
            attr.valueName.toLowerCase() == valueName.toLowerCase());

        if (!hasMatch) return false;
      }
      return true;
    }).toList();
  }

  /// Get all available attribute values grouped by attribute name
  Map<String, List<String>> get availableAttributes {
    final result = <String, Set<String>>{};

    for (final combo in combinations) {
      for (final attr in combo.attributes) {
        result.putIfAbsent(attr.groupName, () => {}).add(attr.valueName);
      }
    }

    return result.map((key, value) => MapEntry(key, value.toList()..sort()));
  }

  /// Get combinations that are in stock
  List<ProductCombination> get inStockCombinations {
    return combinations.where((c) => c.inStock).toList();
  }
}
