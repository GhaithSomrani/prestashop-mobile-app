import '../models/product_option.dart';
import '../config/api_config.dart';
import '../utils/cache_manager.dart';
import 'api_service.dart';

/// Service for managing product options (attribute groups) and option values
class ProductOptionService {
  final ApiService _apiService;
  final CacheManager _cache = CacheManager();

  ProductOptionService(this._apiService);

  /// Get a product option (attribute group) by ID
  Future<ProductOption> getProductOption(String id) async {
    final cacheKey = CacheManager.productOptionKey(id);
    final cached = _cache.get<ProductOption>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _apiService.get(
        '${ApiConfig.productOptionsEndpoint}/$id',
        queryParameters: {'display': 'full'},
      );

      if (response['product_option'] != null) {
        final option = ProductOption.fromJson(response['product_option']);
        _cache.set(cacheKey, option, duration: CacheManager.longDuration);
        return option;
      }

      throw Exception('Product option not found');
    } catch (e) {
      throw Exception('Failed to fetch product option $id: $e');
    }
  }

  /// Get multiple product options in batch
  Future<Map<String, ProductOption>> getProductOptions(List<String> ids) async {
    if (ids.isEmpty) return {};

    // Check cache first
    final result = <String, ProductOption>{};
    final uncachedIds = <String>[];

    for (final id in ids) {
      final cached = _cache.get<ProductOption>(CacheManager.productOptionKey(id));
      if (cached != null) {
        result[id] = cached;
      } else {
        uncachedIds.add(id);
      }
    }

    if (uncachedIds.isEmpty) return result;

    try {
      // Batch request for uncached items
      final idsFilter = uncachedIds.join('|');
      final response = await _apiService.get(
        ApiConfig.productOptionsEndpoint,
        queryParameters: {
          'filter[id]': '[$idsFilter]',
          'display': 'full',
        },
      );

      final options = _parseOptionList(response);
      for (final option in options) {
        result[option.id] = option;
        _cache.set(
          CacheManager.productOptionKey(option.id),
          option,
          duration: CacheManager.longDuration,
        );
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch product options: $e');
    }
  }

  /// Get a product option value by ID
  Future<ProductOptionValue> getProductOptionValue(String id) async {
    final cacheKey = CacheManager.productOptionValueKey(id);
    final cached = _cache.get<ProductOptionValue>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _apiService.get(
        '${ApiConfig.productOptionValuesEndpoint}/$id',
        queryParameters: {'display': 'full'},
      );

      if (response['product_option_value'] != null) {
        final value = ProductOptionValue.fromJson(response['product_option_value']);
        _cache.set(cacheKey, value, duration: CacheManager.longDuration);
        return value;
      }

      throw Exception('Product option value not found');
    } catch (e) {
      throw Exception('Failed to fetch product option value $id: $e');
    }
  }

  /// Get multiple product option values in batch
  Future<Map<String, ProductOptionValue>> getProductOptionValues(List<String> ids) async {
    if (ids.isEmpty) return {};

    // Check cache first
    final result = <String, ProductOptionValue>{};
    final uncachedIds = <String>[];

    for (final id in ids) {
      final cached = _cache.get<ProductOptionValue>(CacheManager.productOptionValueKey(id));
      if (cached != null) {
        result[id] = cached;
      } else {
        uncachedIds.add(id);
      }
    }

    if (uncachedIds.isEmpty) return result;

    try {
      // Batch request for uncached items
      final idsFilter = uncachedIds.join('|');
      final response = await _apiService.get(
        ApiConfig.productOptionValuesEndpoint,
        queryParameters: {
          'filter[id]': '[$idsFilter]',
          'display': 'full',
        },
      );

      final values = _parseOptionValueList(response);
      for (final value in values) {
        result[value.id] = value;
        _cache.set(
          CacheManager.productOptionValueKey(value.id),
          value,
          duration: CacheManager.longDuration,
        );
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch product option values: $e');
    }
  }

  /// Get all product options
  Future<List<ProductOption>> getAllProductOptions() async {
    try {
      final response = await _apiService.get(
        ApiConfig.productOptionsEndpoint,
        queryParameters: {'display': 'full'},
      );

      final options = _parseOptionList(response);

      // Cache all options
      for (final option in options) {
        _cache.set(
          CacheManager.productOptionKey(option.id),
          option,
          duration: CacheManager.longDuration,
        );
      }

      return options;
    } catch (e) {
      throw Exception('Failed to fetch all product options: $e');
    }
  }

  List<ProductOption> _parseOptionList(Map<String, dynamic> response) {
    if (response['product_options'] == null) return [];

    var optionData = response['product_options'];

    // Handle XML nested structure
    if (optionData is Map && optionData['product_option'] != null) {
      optionData = optionData['product_option'];
    }

    if (optionData is List) {
      return optionData
          .map((json) => ProductOption.fromJson(json))
          .toList();
    } else if (optionData is Map) {
      return [ProductOption.fromJson(optionData as Map<String, dynamic>)];
    }

    return [];
  }

  List<ProductOptionValue> _parseOptionValueList(Map<String, dynamic> response) {
    if (response['product_option_values'] == null) return [];

    var valueData = response['product_option_values'];

    // Handle XML nested structure
    if (valueData is Map && valueData['product_option_value'] != null) {
      valueData = valueData['product_option_value'];
    }

    if (valueData is List) {
      return valueData
          .map((json) => ProductOptionValue.fromJson(json))
          .toList();
    } else if (valueData is Map) {
      return [ProductOptionValue.fromJson(valueData as Map<String, dynamic>)];
    }

    return [];
  }
}
