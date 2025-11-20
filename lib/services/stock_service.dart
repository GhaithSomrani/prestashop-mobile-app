import '../models/stock_available.dart';
import '../config/api_config.dart';
import '../utils/cache_manager.dart';
import 'api_service.dart';

/// Service for managing stock availability
class StockService {
  final ApiService _apiService;
  final CacheManager _cache = CacheManager();

  StockService(this._apiService);

  /// Get stock for a specific product (simple product or all combinations)
  Future<List<StockAvailable>> getStockByProduct(String productId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.stockAvailablesEndpoint,
        queryParameters: {
          'filter[id_product]': productId,
          'display': 'full',
        },
      );

      return _parseStockList(response);
    } catch (e) {
      throw Exception('Failed to fetch stock for product $productId: $e');
    }
  }

  /// Get stock for a simple product (id_product_attribute = 0)
  Future<StockAvailable?> getSimpleProductStock(String productId) async {
    final cacheKey = CacheManager.stockKey(productId, '0');
    final cached = _cache.get<StockAvailable>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _apiService.get(
        ApiConfig.stockAvailablesEndpoint,
        queryParameters: {
          'filter[id_product]': productId,
          'filter[id_product_attribute]': '0',
          'display': 'full',
        },
      );

      final stocks = _parseStockList(response);
      if (stocks.isNotEmpty) {
        _cache.set(cacheKey, stocks.first, duration: CacheManager.shortDuration);
        return stocks.first;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch simple product stock: $e');
    }
  }

  /// Get stock for a specific combination
  Future<StockAvailable?> getCombinationStock(String productId, String combinationId) async {
    final cacheKey = CacheManager.stockKey(productId, combinationId);
    final cached = _cache.get<StockAvailable>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _apiService.get(
        ApiConfig.stockAvailablesEndpoint,
        queryParameters: {
          'filter[id_product]': productId,
          'filter[id_product_attribute]': combinationId,
          'display': 'full',
        },
      );

      final stocks = _parseStockList(response);
      if (stocks.isNotEmpty) {
        _cache.set(cacheKey, stocks.first, duration: CacheManager.shortDuration);
        return stocks.first;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch combination stock: $e');
    }
  }

  /// Get all products with stock > 0 (for filtering)
  /// Returns a set of product IDs that have stock available
  Future<Set<String>> getProductIdsWithStock({int minQuantity = 1}) async {
    try {
      final response = await _apiService.get(
        ApiConfig.stockAvailablesEndpoint,
        queryParameters: {
          'display': '[id_product,id_product_attribute,quantity]',
          'filter[quantity]': '[$minQuantity,]', // minimum quantity filter
        },
      );

      final stocks = _parseStockList(response);
      return stocks.map((s) => s.productId).toSet();
    } catch (e) {
      throw Exception('Failed to fetch products with stock: $e');
    }
  }

  /// Get stock for multiple products in batch
  Future<Map<String, List<StockAvailable>>> getStockForProducts(List<String> productIds) async {
    if (productIds.isEmpty) return {};

    try {
      // Batch request using pipe-separated IDs
      final idsFilter = productIds.join('|');
      final response = await _apiService.get(
        ApiConfig.stockAvailablesEndpoint,
        queryParameters: {
          'filter[id_product]': '[$idsFilter]',
          'display': 'full',
        },
      );

      final stocks = _parseStockList(response);

      // Group by product ID
      final Map<String, List<StockAvailable>> result = {};
      for (final stock in stocks) {
        result.putIfAbsent(stock.productId, () => []).add(stock);
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch stock for products: $e');
    }
  }

  /// Legacy method for backwards compatibility
  Future<Map<String, dynamic>> getStockByProductId(String productId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.stockAvailablesEndpoint,
        queryParameters: {
          'display': 'full',
          'filter[id_product]': productId,
        },
      );

      if (response['stock_availables'] != null) {
        var stockData = response['stock_availables'];
        // Handle XML nested structure
        if (stockData is Map && stockData['stock_available'] != null) {
          stockData = stockData['stock_available'];
        }
        if (stockData is List && stockData.isNotEmpty) {
          return stockData[0] as Map<String, dynamic>;
        } else if (stockData is Map) {
          return stockData as Map<String, dynamic>;
        }
      }

      return {};
    } catch (e) {
      throw Exception('Failed to fetch stock: $e');
    }
  }

  /// Check if a product has any stock available
  Future<bool> hasStock(String productId) async {
    final stocks = await getStockByProduct(productId);
    return stocks.any((s) => s.inStock);
  }

  /// Get total stock quantity for a product
  Future<int> getTotalStock(String productId) async {
    final stocks = await getStockByProduct(productId);
    return stocks.fold<int>(0, (sum, stock) => sum + stock.quantity);
  }

  List<StockAvailable> _parseStockList(Map<String, dynamic> response) {
    if (response['stock_availables'] == null) return [];

    var stockData = response['stock_availables'];

    // Handle XML nested structure
    if (stockData is Map && stockData['stock_available'] != null) {
      stockData = stockData['stock_available'];
    }

    if (stockData is List) {
      return stockData
          .map((json) => StockAvailable.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (stockData is Map) {
      return [StockAvailable.fromJson(stockData as Map<String, dynamic>)];
    }

    return [];
  }
}
