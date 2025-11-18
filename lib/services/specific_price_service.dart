import '../models/specific_price.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Service for managing specific prices (discounts, special offers)
class SpecificPriceService {
  final ApiService _apiService;

  SpecificPriceService(this._apiService);

  /// Get specific prices for a product
  Future<List<SpecificPrice>> getSpecificPricesForProduct(
    String productId,
  ) async {
    try {
      final response = await _apiService.get(
        ApiConfig.specificPricesEndpoint,
        queryParameters: {
          'filter[id_product]': productId,
          'display': 'full',
        },
      );

      List<SpecificPrice> prices = [];
      if (response['specific_prices'] != null) {
        final pricesData = response['specific_prices'];
        if (pricesData is List) {
          prices = pricesData
              .map((priceJson) => SpecificPrice.fromJson(priceJson))
              .toList();
        } else if (pricesData is Map) {
          prices = [SpecificPrice.fromJson(pricesData as Map<String, dynamic>)];
        }
      }

      // Filter only active prices
      return prices.where((price) => price.isActive).toList();
    } catch (e) {
      throw Exception('Failed to fetch specific prices: $e');
    }
  }

  /// Get specific price for a product combination
  Future<SpecificPrice?> getSpecificPriceForCombination(
    String productId,
    String combinationId,
  ) async {
    try {
      final response = await _apiService.get(
        ApiConfig.specificPricesEndpoint,
        queryParameters: {
          'filter[id_product]': productId,
          'filter[id_product_attribute]': combinationId,
          'display': 'full',
        },
      );

      List<SpecificPrice> prices = [];
      if (response['specific_prices'] != null) {
        final pricesData = response['specific_prices'];
        if (pricesData is List) {
          prices = pricesData
              .map((priceJson) => SpecificPrice.fromJson(priceJson))
              .toList();
        } else if (pricesData is Map) {
          prices = [SpecificPrice.fromJson(pricesData as Map<String, dynamic>)];
        }
      }

      // Return the first active price
      final activePrices = prices.where((price) => price.isActive).toList();
      return activePrices.isNotEmpty ? activePrices.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate final price with discount
  Future<double> calculateFinalPrice(
    String productId,
    double basePrice, {
    String? combinationId,
  }) async {
    try {
      SpecificPrice? specificPrice;

      if (combinationId != null) {
        specificPrice =
            await getSpecificPriceForCombination(productId, combinationId);
      }

      if (specificPrice == null) {
        final prices = await getSpecificPricesForProduct(productId);
        if (prices.isNotEmpty) {
          specificPrice = prices.first;
        }
      }

      if (specificPrice == null) {
        return basePrice;
      }

      return specificPrice.calculateFinalPrice(basePrice);
    } catch (e) {
      return basePrice;
    }
  }

  /// Check if product has active discount
  Future<bool> hasActiveDiscount(String productId) async {
    try {
      final prices = await getSpecificPricesForProduct(productId);
      return prices.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get all products with active discounts
  Future<List<String>> getProductsOnSale() async {
    try {
      final response = await _apiService.get(
        ApiConfig.specificPricesEndpoint,
        queryParameters: {'display': 'full'},
      );

      Set<String> productIds = {};
      if (response['specific_prices'] != null) {
        final pricesData = response['specific_prices'];
        if (pricesData is List) {
          for (var priceJson in pricesData) {
            final price = SpecificPrice.fromJson(priceJson);
            if (price.isActive) {
              productIds.add(price.idProduct);
            }
          }
        }
      }

      return productIds.toList();
    } catch (e) {
      throw Exception('Failed to fetch products on sale: $e');
    }
  }
}
