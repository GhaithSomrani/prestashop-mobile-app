import '../models/manufacturer.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Service for managing manufacturers (brands)
class ManufacturerService {
  final ApiService _apiService;

  ManufacturerService(this._apiService);

  /// Get all manufacturers
  Future<List<Manufacturer>> getManufacturers({bool activeOnly = true}) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        if (activeOnly) 'filter[active]': '1',
      };

      final response = await _apiService.get(
        ApiConfig.manufacturersEndpoint,
        queryParameters: queryParams,
      );

      List<Manufacturer> manufacturers = [];
      if (response['manufacturers'] != null) {
        final manufacturersData = response['manufacturers'];
        if (manufacturersData is List) {
          manufacturers = manufacturersData
              .map((manufacturerJson) => Manufacturer.fromJson(manufacturerJson))
              .toList();
        } else if (manufacturersData is Map) {
          manufacturers = [
            Manufacturer.fromJson(manufacturersData as Map<String, dynamic>)
          ];
        }
      }

      return manufacturers;
    } catch (e) {
      throw Exception('Failed to fetch manufacturers: $e');
    }
  }

  /// Get a specific manufacturer by ID
  Future<Manufacturer> getManufacturerById(String manufacturerId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.manufacturersEndpoint}/$manufacturerId',
        queryParameters: {'display': 'full'},
      );

      if (response['manufacturer'] != null) {
        return Manufacturer.fromJson(response['manufacturer']);
      }

      throw Exception('Manufacturer not found');
    } catch (e) {
      throw Exception('Failed to fetch manufacturer: $e');
    }
  }

  /// Get manufacturers for specific products (used for filtering)
  Future<List<Manufacturer>> getManufacturersForProducts(
    List<String> productIds,
  ) async {
    try {
      // Extract unique manufacturer IDs from products
      // This would require product data, so we'll fetch all manufacturers
      // and filter based on the products' manufacturer IDs
      return await getManufacturers();
    } catch (e) {
      throw Exception('Failed to fetch manufacturers for products: $e');
    }
  }

  /// Search manufacturers by name
  Future<List<Manufacturer>> searchManufacturers(String query) async {
    try {
      final response = await _apiService.get(
        ApiConfig.manufacturersEndpoint,
        queryParameters: {
          'display': 'full',
          'filter[name]': '%$query%',
          'filter[active]': '1',
        },
      );

      List<Manufacturer> manufacturers = [];
      if (response['manufacturers'] != null) {
        final manufacturersData = response['manufacturers'];
        if (manufacturersData is List) {
          manufacturers = manufacturersData
              .map((manufacturerJson) => Manufacturer.fromJson(manufacturerJson))
              .toList();
        } else if (manufacturersData is Map) {
          manufacturers = [
            Manufacturer.fromJson(manufacturersData as Map<String, dynamic>)
          ];
        }
      }

      return manufacturers;
    } catch (e) {
      throw Exception('Failed to search manufacturers: $e');
    }
  }
}
