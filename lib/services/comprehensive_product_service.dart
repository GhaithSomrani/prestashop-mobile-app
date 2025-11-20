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

/// Comprehensive product fetching service that handles:
/// - Products with combinations (variations)
/// - Accurate price calculations with combination impacts
/// - Stock availability filtering
/// - Optimized API calls with batching and caching
///
/// PrestaShop API Structure:
/// Product → Combinations → Product Option Values → Product Options
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

  /// Get a single product with full details including combinations and resolved attributes
  ///
  /// This fetches:
  /// 1. Product with display=full
  /// 2. All combinations for the product
  /// 3. Product option values for each combination
  /// 4. Product options (attribute groups) for names
  /// 5. Stock for each combination
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

      // Step 2: If simple product, just get stock
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

      // Step 4: Get stock for all combinations
      final stockMap = await _getStockForCombinations(productId, combinations);

      // Step 5: Collect all option value IDs from combinations
      final optionValueIds = <String>{};
      for (final combo in combinations) {
        for (final attr in combo.attributes) {
          optionValueIds.add(attr.id);
        }
      }

      // Step 6: Batch fetch option values
      final optionValues = await _productOptionService.getProductOptionValues(
        optionValueIds.toList(),
      );

      // Step 7: Get option group IDs and fetch option groups
      final optionGroupIds = optionValues.values
          .map((v) => v.optionId)
          .toSet()
          .toList();
      final optionGroups = await _productOptionService.getProductOptions(optionGroupIds);

      // Step 8: Build complete ProductCombination objects
      final productCombinations = _buildProductCombinations(
        combinations,
        product.basePrice,
        stockMap,
        optionValues,
        optionGroups,
      );

      // Step 9: Find default combination and calculate price range
      final defaultCombo = productCombinations.firstWhere(
        (c) => c.id == product.defaultCombinationId || c.isDefault,
        orElse: () => productCombinations.first,
      );

      final prices = productCombinations.map((c) => c.finalPrice).toList();
      final priceRange = PriceRange(
        min: prices.reduce((a, b) => a < b ? a : b),
        max: prices.reduce((a, b) => a > b ? a : b),
      );

      return product.copyWith(
        combinations: productCombinations,
        defaultCombination: defaultCombo,
        priceRange: priceRange,
      );
    } catch (e) {
      throw Exception('Failed to fetch product with full details: $e');
    }
  }

  /// Get multiple products with full details
  /// Optimized with parallel fetching and batching
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
      final simpleStockMap = await _stockService.getStockForProducts(
        simpleProducts.map((p) => p.id).toList(),
      );

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

      // Get combinations for all combination products
      final combinationProductIds = combinationProducts.map((p) => p.id).toList();
      if (combinationProductIds.isEmpty) {
        return updatedSimpleProducts;
      }

      final allCombinationsMap = await _combinationService.getCombinationsForProducts(
        combinationProductIds,
      );

      // Get stock for all combinations
      final allStockMap = await _stockService.getStockForProducts(combinationProductIds);

      // Collect all option value IDs
      final allOptionValueIds = <String>{};
      for (final combos in allCombinationsMap.values) {
        for (final combo in combos) {
          for (final attr in combo.attributes) {
            allOptionValueIds.add(attr.id);
          }
        }
      }

      // Batch fetch option values and groups if needed
      Map<String, ProductOptionValue> optionValues = {};
      Map<String, ProductOption> optionGroups = {};

      if (resolveAttributes && allOptionValueIds.isNotEmpty) {
        optionValues = await _productOptionService.getProductOptionValues(
          allOptionValueIds.toList(),
        );

        final optionGroupIds = optionValues.values
            .map((v) => v.optionId)
            .toSet()
            .toList();
        optionGroups = await _productOptionService.getProductOptions(optionGroupIds);
      }

      // Build complete products with combinations
      final updatedCombinationProducts = combinationProducts.map((product) {
        final combinations = allCombinationsMap[product.id] ?? [];
        final stockList = allStockMap[product.id] ?? [];

        // Build stock map for this product's combinations
        final stockMap = <String, int>{};
        for (final stock in stockList) {
          if (stock.productAttributeId != '0') {
            stockMap[stock.productAttributeId] = stock.quantity;
          }
        }

        // Build product combinations
        final productCombinations = _buildProductCombinations(
          combinations,
          product.basePrice,
          stockMap,
          optionValues,
          optionGroups,
        );

        if (productCombinations.isEmpty) {
          return product;
        }

        // Find default and calculate price range
        final defaultCombo = productCombinations.firstWhere(
          (c) => c.id == product.defaultCombinationId || c.isDefault,
          orElse: () => productCombinations.first,
        );

        final prices = productCombinations.map((c) => c.finalPrice).toList();
        final priceRange = PriceRange(
          min: prices.reduce((a, b) => a < b ? a : b),
          max: prices.reduce((a, b) => a > b ? a : b),
        );

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

  /// Get products filtered by stock availability
  /// Uses two-stage filtering for efficiency:
  /// 1. Fetch stock records with quantity > 0
  /// 2. Fetch only products that have stock
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

      // Stage 2: Fetch products with those IDs
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

  /// Get products with combined filters
  ///
  /// Filters:
  /// - categoryId: Filter by category
  /// - minPrice/maxPrice: Filter by price range (accounts for combination prices)
  /// - inStockOnly: Filter by stock availability
  /// - manufacturerId: Filter by manufacturer
  /// - attributeFilters: Filter by specific attributes (e.g., {"Size": "L", "Color": "Red"})
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
        // Fetch all product IDs
        productIds = await _fetchAllProductIds(
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

      // Apply filters
      if (categoryId != null) {
        products = products.where((p) => p.categoryId == categoryId).toList();
      }

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

      // Apply in-stock filter again to catch any missed
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

  /// Get products by price range that accounts for combination prices
  Future<List<ProductDetail>> getProductsByPriceRange(
    double minPrice,
    double maxPrice, {
    String? categoryId,
    bool inStockOnly = false,
    int? limit,
    int? offset,
  }) async {
    return getFilteredProducts(
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      inStockOnly: inStockOnly,
      limit: limit,
      offset: offset,
    );
  }

  /// Get products by specific attribute values
  ///
  /// Example: getProductsByAttributes({"Size": "L", "Color": "Red"})
  Future<List<ProductDetail>> getProductsByAttributes(
    Map<String, String> attributeFilters, {
    String? categoryId,
    bool inStockOnly = false,
    int? limit,
    int? offset,
  }) async {
    return getFilteredProducts(
      categoryId: categoryId,
      attributeFilters: attributeFilters,
      inStockOnly: inStockOnly,
      limit: limit,
      offset: offset,
    );
  }

  /// Calculate the final price for a specific combination
  /// Formula: Base Product Price + Combination Price Impact
  double calculateCombinationPrice(double basePrice, double priceImpact) {
    return basePrice + priceImpact;
  }

  // Private helper methods

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

  Future<Map<String, int>> _getStockForCombinations(
    String productId,
    List<Combination> combinations,
  ) async {
    final stocks = await _stockService.getStockByProduct(productId);
    final stockMap = <String, int>{};

    for (final stock in stocks) {
      if (stock.productAttributeId != '0') {
        stockMap[stock.productAttributeId] = stock.quantity;
      }
    }

    return stockMap;
  }

  List<ProductCombination> _buildProductCombinations(
    List<Combination> combinations,
    double basePrice,
    Map<String, int> stockMap,
    Map<String, ProductOptionValue> optionValues,
    Map<String, ProductOption> optionGroups,
  ) {
    return combinations.map((combo) {
      // Resolve attributes
      final attributes = combo.attributes.map((attr) {
        final optionValue = optionValues[attr.id];
        final optionGroup = optionValue != null
            ? optionGroups[optionValue.optionId]
            : null;

        return CombinationAttributeDetail(
          groupId: optionGroup?.id ?? '',
          groupName: optionGroup?.publicName ?? optionGroup?.name ?? '',
          valueId: attr.id,
          valueName: optionValue?.name ?? '',
          color: optionValue?.color,
        );
      }).toList();

      // Get stock quantity
      final quantity = stockMap[combo.id] ?? combo.quantity;

      return ProductCombination(
        id: combo.id,
        productId: combo.idProduct,
        reference: combo.reference,
        priceImpact: combo.priceImpact,
        finalPrice: basePrice + combo.priceImpact,
        quantity: quantity,
        isDefault: combo.defaultOn,
        attributes: attributes,
      );
    }).toList();
  }

  Future<List<String>> _fetchAllProductIds({
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

    // For combination products, check if any combination falls within range
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

    // Check if any combination matches all attribute filters
    for (final combo in product.combinations) {
      bool allMatch = true;

      for (final entry in attributeFilters.entries) {
        final groupName = entry.key;
        final valueName = entry.value;

        final matchingAttr = combo.attributes.firstWhere(
          (attr) =>
              attr.groupName.toLowerCase() == groupName.toLowerCase() &&
              attr.valueName.toLowerCase() == valueName.toLowerCase(),
          orElse: () => CombinationAttributeDetail(
            groupId: '',
            groupName: '',
            valueId: '',
            valueName: '',
          ),
        );

        if (matchingAttr.valueId.isEmpty) {
          allMatch = false;
          break;
        }
      }

      if (allMatch) return true;
    }

    return false;
  }

  List<ProductDetail> _sortProducts(List<ProductDetail> products, String sortBy) {
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
        products.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
        break;
      case 'id_DESC':
        products.sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));
        break;
      default:
        break;
    }
    return products;
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

  /// Get combinations filtered by stock
  List<ProductCombination> get inStockCombinations {
    return combinations.where((c) => c.inStock).toList();
  }
}
