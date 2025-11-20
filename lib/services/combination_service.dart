import '../models/combination.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Service for managing product combinations (variants)
class CombinationService {
  final ApiService _apiService;

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
        final combinationsData = response['combinations'];
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

      // Fetch stock data from stock_availables for accurate quantities
      final stockResponse = await _apiService.get(
        ApiConfig.stockAvailablesEndpoint,
        queryParameters: {
          'display': '[id_product_attribute,quantity]',
          'filter[id_product]': productId,
        },
      );

      // Map combination IDs to quantities
      final Map<String, int> stockMap = {};
      if (stockResponse['stock_availables'] != null) {
        final stockData = stockResponse['stock_availables'];
        if (stockData is List) {
          for (var stock in stockData) {
            final combinationId = stock['id_product_attribute']?.toString();
            final quantity = _parseQuantity(stock['quantity']);
            if (combinationId != null && combinationId != '0') {
              stockMap[combinationId] = quantity;
            }
          }
        }
      }

      // Update combinations with stock data
      return combinations.map((combination) {
        final stockQuantity = stockMap[combination.id];
        if (stockQuantity != null) {
          return combination.copyWith(quantity: stockQuantity);
        }
        return combination;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch combinations with stock: $e');
    }
  }

  /// Get only in-stock combinations for a product
  Future<List<Combination>> getInStockCombinations(String productId) async {
    try {
      final combinations = await getCombinationsWithStock(productId);
      return combinations.where((c) => c.quantity > 0).toList();
    } catch (e) {
      throw Exception('Failed to fetch in-stock combinations: $e');
    }
  }

  /// Parse quantity from dynamic value
  int _parseQuantity(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
