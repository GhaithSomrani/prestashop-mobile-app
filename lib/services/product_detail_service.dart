import '../models/product_detail.dart';
import '../models/combination.dart';
import '../models/product_option.dart';
import '../config/api_config.dart';
import '../utils/cache_manager.dart';
import '../utils/language_helper.dart';
import 'api_service.dart';
import 'stock_service.dart';
import 'product_option_service.dart';

/// Service for fetching products with full associations including combinations,
/// options, and accurate price calculations.
class ProductDetailService {
  final ApiService _apiService;
  final StockService _stockService;
  final ProductOptionService _optionService;
  final CacheManager _cache = CacheManager();

  ProductDetailService(
    this._apiService,
    this._stockService,
    this._optionService,
  );

  /// Fetch a product with all its combinations and attributes
  Future<ProductDetail> getProductWithCombinations(String productId) async {
    // Check cache first
    final cacheKey = CacheManager.productDetailKey(productId);
    final cached = _cache.get<ProductDetail>(cacheKey);
    if (cached != null) return cached;

    try {
      // Step 1: Fetch product with full display
      final productResponse = await _apiService.get(
        '${ApiConfig.productsEndpoint}/$productId',
        queryParameters: {'display': 'full'},
      );

      if (productResponse['product'] == null) {
        throw Exception('Product not found');
      }

      final productDetail = ProductDetail.fromJson(productResponse);

      // Step 2: If simple product, fetch stock and return
      if (productDetail.isSimpleProduct) {
        final stock = await _stockService.getSimpleProductStock(productId);
        final result = ProductDetail(
          id: productDetail.id,
          name: productDetail.name,
          description: productDetail.description,
          shortDescription: productDetail.shortDescription,
          basePrice: productDetail.basePrice,
          imageUrl: productDetail.imageUrl,
          images: productDetail.images,
          reference: productDetail.reference,
          active: productDetail.active,
          categoryId: productDetail.categoryId,
          manufacturerId: productDetail.manufacturerId,
          manufacturerName: productDetail.manufacturerName,
          defaultCombinationId: productDetail.defaultCombinationId,
          isSimpleProduct: true,
          simpleProductStock: stock?.quantity ?? 0,
          onSale: productDetail.onSale,
          discountPercentage: productDetail.discountPercentage,
          taxRulesGroupId: productDetail.taxRulesGroupId,
        );

        _cache.set(cacheKey, result, duration: CacheManager.mediumDuration);
        return result;
      }

      // Step 3: Fetch combinations
      final combinations = await _fetchCombinationsWithDetails(
        productId,
        productDetail.basePrice,
      );

      final result = productDetail.copyWithCombinations(combinations);
      _cache.set(cacheKey, result, duration: CacheManager.mediumDuration);

      return result;
    } catch (e) {
      throw Exception('Failed to fetch product with combinations: $e');
    }
  }

  /// Fetch combinations with full attribute details
  Future<List<ProductCombination>> _fetchCombinationsWithDetails(
    String productId,
    double basePrice,
  ) async {
    // Fetch all combinations for this product
    final combinationsResponse = await _apiService.get(
      ApiConfig.combinationsEndpoint,
      queryParameters: {
        'filter[id_product]': productId,
        'display': 'full',
      },
    );

    final combinationsData = _parseCombinationsList(combinationsResponse);
    if (combinationsData.isEmpty) return [];

    // Collect all product option value IDs
    final allOptionValueIds = <String>{};
    for (final combo in combinationsData) {
      if (combo.attributes.isNotEmpty) {
        for (final attr in combo.attributes) {
          allOptionValueIds.add(attr.id);
        }
      }
      // Also check associations for product_option_values
      final associations = combo.toJson()['associations'];
      if (associations?['product_option_values'] != null) {
        var optionValues = associations['product_option_values'];
        if (optionValues is Map && optionValues['product_option_value'] != null) {
          optionValues = optionValues['product_option_value'];
        }
        if (optionValues is List) {
          for (final ov in optionValues) {
            final id = ov is Map ? ov['id']?.toString() : ov.toString();
            if (id != null && id.isNotEmpty) allOptionValueIds.add(id);
          }
        } else if (optionValues is Map) {
          final id = optionValues['id']?.toString();
          if (id != null && id.isNotEmpty) allOptionValueIds.add(id);
        }
      }
    }

    // Batch fetch option values
    final optionValues = await _optionService.getProductOptionValues(
      allOptionValueIds.toList(),
    );

    // Get unique option group IDs
    final optionGroupIds = optionValues.values.map((v) => v.optionId).toSet().toList();

    // Batch fetch option groups (attribute groups)
    final optionGroups = await _optionService.getProductOptions(optionGroupIds);

    // Build ProductCombination objects with full details
    final productCombinations = <ProductCombination>[];

    for (final combo in combinationsData) {
      // Get option value IDs for this combination
      final comboOptionValueIds = <String>[];

      // From attributes
      for (final attr in combo.attributes) {
        comboOptionValueIds.add(attr.id);
      }

      // From associations
      final comboJson = combo.toJson();
      if (comboJson['associations']?['product_option_values'] != null) {
        var optionVals = comboJson['associations']['product_option_values'];
        if (optionVals is Map && optionVals['product_option_value'] != null) {
          optionVals = optionVals['product_option_value'];
        }
        if (optionVals is List) {
          for (final ov in optionVals) {
            final id = ov is Map ? ov['id']?.toString() : ov.toString();
            if (id != null && id.isNotEmpty && !comboOptionValueIds.contains(id)) {
              comboOptionValueIds.add(id);
            }
          }
        } else if (optionVals is Map) {
          final id = optionVals['id']?.toString();
          if (id != null && id.isNotEmpty && !comboOptionValueIds.contains(id)) {
            comboOptionValueIds.add(id);
          }
        }
      }

      // Build detailed attributes
      final detailedAttributes = <CombinationAttributeDetail>[];

      for (final valueId in comboOptionValueIds) {
        final optionValue = optionValues[valueId];
        if (optionValue != null) {
          final optionGroup = optionGroups[optionValue.optionId];

          detailedAttributes.add(CombinationAttributeDetail(
            groupId: optionValue.optionId,
            groupName: optionGroup?.publicName ?? optionGroup?.name ?? '',
            valueId: optionValue.id,
            valueName: optionValue.name,
            color: optionValue.color,
          ));
        }
      }

      productCombinations.add(ProductCombination(
        id: combo.id,
        productId: combo.idProduct,
        reference: combo.reference,
        priceImpact: combo.priceImpact,
        finalPrice: basePrice + combo.priceImpact,
        quantity: combo.quantity,
        isDefault: combo.defaultOn,
        attributes: detailedAttributes,
      ));
    }

    return productCombinations;
  }

  /// Fetch multiple products with combinations in batch
  Future<List<ProductDetail>> getProductsWithCombinations(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    final results = <ProductDetail>[];

    // Check cache and identify uncached products
    final uncachedIds = <String>[];
    for (final id in productIds) {
      final cached = _cache.get<ProductDetail>(CacheManager.productDetailKey(id));
      if (cached != null) {
        results.add(cached);
      } else {
        uncachedIds.add(id);
      }
    }

    if (uncachedIds.isEmpty) return results;

    // Batch fetch products
    final idsFilter = uncachedIds.join('|');
    final productsResponse = await _apiService.get(
      ApiConfig.productsEndpoint,
      queryParameters: {
        'filter[id]': '[$idsFilter]',
        'display': 'full',
      },
    );

    final productsData = _parseProductsList(productsResponse);

    // Fetch combinations for all products
    for (final productData in productsData) {
      final productDetail = ProductDetail.fromJson(productData);

      if (productDetail.isSimpleProduct) {
        results.add(productDetail);
        _cache.set(
          CacheManager.productDetailKey(productDetail.id),
          productDetail,
          duration: CacheManager.mediumDuration,
        );
      } else {
        // Fetch combinations
        final combinations = await _fetchCombinationsWithDetails(
          productDetail.id,
          productDetail.basePrice,
        );

        final fullProduct = productDetail.copyWithCombinations(combinations);
        results.add(fullProduct);
        _cache.set(
          CacheManager.productDetailKey(fullProduct.id),
          fullProduct,
          duration: CacheManager.mediumDuration,
        );
      }
    }

    return results;
  }

  /// Get products with stock filtering
  /// Two-stage approach: first get product IDs with stock, then fetch those products
  Future<List<ProductDetail>> getProductsInStock({
    int? limit,
    int? offset,
  }) async {
    // Stage 1: Get product IDs with stock
    final productIdsWithStock = await _stockService.getProductIdsWithStock();

    if (productIdsWithStock.isEmpty) return [];

    // Apply pagination
    var ids = productIdsWithStock.toList();
    if (offset != null && offset > 0) {
      ids = ids.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      ids = ids.take(limit).toList();
    }

    // Stage 2: Fetch products
    return getProductsWithCombinations(ids);
  }

  /// Clear product cache
  void clearCache() {
    _cache.clear();
  }

  /// Clear specific product from cache
  void clearProductCache(String productId) {
    _cache.remove(CacheManager.productDetailKey(productId));
    _cache.remove(CacheManager.combinationsKey(productId));
  }

  List<Combination> _parseCombinationsList(Map<String, dynamic> response) {
    if (response['combinations'] == null) return [];

    var combinationsData = response['combinations'];

    // Handle XML nested structure
    if (combinationsData is Map && combinationsData['combination'] != null) {
      combinationsData = combinationsData['combination'];
    }

    if (combinationsData is List) {
      return combinationsData
          .map((json) => Combination.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (combinationsData is Map) {
      return [Combination.fromJson(combinationsData as Map<String, dynamic>)];
    }

    return [];
  }

  List<Map<String, dynamic>> _parseProductsList(Map<String, dynamic> response) {
    if (response['products'] == null) return [];

    var productsData = response['products'];

    // Handle XML nested structure
    if (productsData is Map && productsData['product'] != null) {
      productsData = productsData['product'];
    }

    if (productsData is List) {
      return productsData.cast<Map<String, dynamic>>();
    } else if (productsData is Map) {
      return [productsData as Map<String, dynamic>];
    }

    return [];
  }
}
