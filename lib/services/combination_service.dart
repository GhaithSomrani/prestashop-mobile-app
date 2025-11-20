import '../models/combination.dart';
import '../config/api_config.dart';
import '../utils/cache_manager.dart';
import 'api_service.dart';

/// Service for managing product combinations (variants)
class CombinationService {
  final ApiService _apiService;
  final CacheManager _cache = CacheManager();

  CombinationService(this._apiService);

  /// Get all combinations for a specific product
  Future<List<Combination>> getCombinationsByProduct(String productId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.combinationsEndpoint,
        queryParameters: {
          'filter[id_product]': productId,
          'display': 'full',
        },
      );

      List<Combination> combinations = [];
      if (response['combinations'] != null) {
        var combinationsData = response['combinations'];

        // Handle XML structure: {combinations: {combination: {...}}} or {combinations: {combination: [...]}}
        if (combinationsData is Map && combinationsData['combination'] != null) {
          combinationsData = combinationsData['combination'];
        }

        if (combinationsData is List) {
          combinations = combinationsData
              .map((combinationJson) => Combination.fromJson(combinationJson))
              .toList();
        } else if (combinationsData is Map) {
          combinations = [Combination.fromJson(combinationsData as Map<String, dynamic>)];
        }
      }

      return combinations;
    } catch (e) {
      throw Exception('Failed to fetch combinations: $e');
    }
  }

  /// Get a specific combination by ID
  Future<Combination> getCombinationById(String combinationId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.combinationsEndpoint}/$combinationId',
        queryParameters: {'display': 'full'},
      );

      if (response['combination'] != null) {
        return Combination.fromJson(response['combination']);
      }

      throw Exception('Combination not found');
    } catch (e) {
      throw Exception('Failed to fetch combination: $e');
    }
  }

  /// Get default combination for a product
  Future<Combination?> getDefaultCombination(String productId) async {
    try {
      final combinations = await getCombinationsByProduct(productId);

      // Find default combination
      final defaultCombination = combinations.firstWhere(
        (c) => c.defaultOn,
        orElse: () => combinations.isNotEmpty ? combinations.first : throw Exception('No combinations found'),
      );

      return defaultCombination;
    } catch (e) {
      return null;
    }
  }

  /// Get combinations with stock information
  Future<List<Combination>> getCombinationsWithStock(String productId) async {
    try {
      final combinations = await getCombinationsByProduct(productId);

      // Stock is already included in combination quantity field
      // But we could fetch from stock_availables for more detailed info
      return combinations;
    } catch (e) {
      throw Exception('Failed to fetch combinations with stock: $e');
    }
  }

  /// Batch fetch combinations by IDs
  /// Uses pipe-separated IDs for efficiency
  Future<List<Combination>> getCombinationsByIds(List<String> combinationIds) async {
    if (combinationIds.isEmpty) return [];

    try {
      // Batch request using pipe-separated IDs
      final idsFilter = combinationIds.join('|');
      final response = await _apiService.get(
        ApiConfig.combinationsEndpoint,
        queryParameters: {
          'filter[id]': '[$idsFilter]',
          'display': 'full',
        },
      );

      List<Combination> combinations = [];
      if (response['combinations'] != null) {
        var combinationsData = response['combinations'];

        // Handle XML structure
        if (combinationsData is Map && combinationsData['combination'] != null) {
          combinationsData = combinationsData['combination'];
        }

        if (combinationsData is List) {
          combinations = combinationsData
              .map((json) => Combination.fromJson(json))
              .toList();
        } else if (combinationsData is Map) {
          combinations = [Combination.fromJson(combinationsData as Map<String, dynamic>)];
        }
      }

      return combinations;
    } catch (e) {
      throw Exception('Failed to batch fetch combinations: $e');
    }
  }

  /// Get combinations for multiple products
  Future<Map<String, List<Combination>>> getCombinationsForProducts(List<String> productIds) async {
    if (productIds.isEmpty) return {};

    try {
      // Batch request using pipe-separated IDs
      final idsFilter = productIds.join('|');
      final response = await _apiService.get(
        ApiConfig.combinationsEndpoint,
        queryParameters: {
          'filter[id_product]': '[$idsFilter]',
          'display': 'full',
        },
      );

      List<Combination> allCombinations = [];
      if (response['combinations'] != null) {
        var combinationsData = response['combinations'];

        // Handle XML structure
        if (combinationsData is Map && combinationsData['combination'] != null) {
          combinationsData = combinationsData['combination'];
        }

        if (combinationsData is List) {
          allCombinations = combinationsData
              .map((json) => Combination.fromJson(json))
              .toList();
        } else if (combinationsData is Map) {
          allCombinations = [Combination.fromJson(combinationsData as Map<String, dynamic>)];
        }
      }

      // Group by product ID
      final Map<String, List<Combination>> result = {};
      for (final combo in allCombinations) {
        result.putIfAbsent(combo.idProduct, () => []).add(combo);
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch combinations for products: $e');
    }
  }
}
