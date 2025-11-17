import '../models/carrier.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class CarrierService {
  final ApiService _apiService;

  CarrierService(this._apiService);

  Future<List<Carrier>> getCarriers() async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        'filter[active]': '1',
      };

      final response = await _apiService.get(
        ApiConfig.carriersEndpoint,
        queryParameters: queryParams,
      );

      if (response['carriers'] != null) {
        final carriersData = response['carriers'];
        if (carriersData is List) {
          return carriersData
              .map((carrierJson) => Carrier.fromJson(carrierJson))
              .toList();
        } else if (carriersData is Map) {
          return [Carrier.fromJson(carriersData)];
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch carriers: $e');
    }
  }

  Future<Carrier> getCarrierById(String id) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.carriersEndpoint}/$id',
        queryParameters: {'display': 'full'},
      );

      if (response['carrier'] != null) {
        return Carrier.fromJson(response['carrier']);
      }

      throw Exception('Carrier not found');
    } catch (e) {
      throw Exception('Failed to fetch carrier: $e');
    }
  }
}
