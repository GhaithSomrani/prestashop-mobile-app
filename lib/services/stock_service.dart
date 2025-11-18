import '../config/api_config.dart';
import 'api_service.dart';

class StockService {
  final ApiService _apiService;

  StockService(this._apiService);

  /// Get stock availability for a specific product
  Future<Map<String, dynamic>> getStockByProductId(String productId) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        'filter[id_product]': productId,
      };

      final response = await _apiService.get(
        ApiConfig.stockAvailablesEndpoint,
        queryParameters: queryParams,
      );

      if (response['stock_availables'] != null) {
        final stockData = response['stock_availables'];
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

  /// Get stock availability for multiple products
  Future<Map<String, int>> getStockForProducts(List<String> productIds) async {
    final Map<String, int> stockMap = {};

    try {
      for (String productId in productIds) {
        final stock = await getStockByProductId(productId);
        if (stock.isNotEmpty) {
          stockMap[productId] = _parseQuantity(stock['quantity']);
        } else {
          stockMap[productId] = 0;
        }
      }
      return stockMap;
    } catch (e) {
      throw Exception('Failed to fetch stock for products: $e');
    }
  }

  /// Get all stock availables with pagination
  Future<List<Map<String, dynamic>>> getAllStock({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        if (limit != null) 'limit': '$offset,$limit',
      };

      final response = await _apiService.get(
        ApiConfig.stockAvailablesEndpoint,
        queryParameters: queryParams,
      );

      if (response['stock_availables'] != null) {
        final stockData = response['stock_availables'];
        if (stockData is List) {
          return stockData.cast<Map<String, dynamic>>();
        } else if (stockData is Map) {
          return [stockData as Map<String, dynamic>];
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch all stock: $e');
    }
  }

  int _parseQuantity(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
