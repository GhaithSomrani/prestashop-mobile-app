import '../models/country.dart';
import '../models/ps_state.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class LocationService {
  final ApiService _apiService;

  LocationService(this._apiService);

  Future<List<Country>> getCountries() async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        'filter[active]': '1',
      };

      final response = await _apiService.get(
        ApiConfig.countriesEndpoint,
        queryParameters: queryParams,
      );

      if (response['countries'] != null) {
        final countriesData = response['countries'];
        if (countriesData is List) {
          return countriesData
              .map((json) => Country.fromJson(json))
              .toList();
        } else if (countriesData is Map) {
          return [Country.fromJson(countriesData as Map<String, dynamic>)];
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch countries: $e');
    }
  }

  Future<Country?> getCountryById(String countryId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.countriesEndpoint}/$countryId',
        queryParameters: {'display': 'full'},
      );

      if (response['country'] != null) {
        return Country.fromJson(response['country']);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch country: $e');
    }
  }

  Future<List<PsState>> getStates() async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        'filter[active]': '1',
      };

      final response = await _apiService.get(
        ApiConfig.statesEndpoint,
        queryParameters: queryParams,
      );

      if (response['states'] != null) {
        final statesData = response['states'];
        if (statesData is List) {
          return statesData
              .map((json) => PsState.fromJson(json))
              .toList();
        } else if (statesData is Map) {
          return [PsState.fromJson(statesData as Map<String, dynamic>)];
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch states: $e');
    }
  }

  Future<List<PsState>> getStatesByCountry(String countryId) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        'filter[id_country]': countryId,
        'filter[active]': '1',
      };

      final response = await _apiService.get(
        ApiConfig.statesEndpoint,
        queryParameters: queryParams,
      );

      if (response['states'] != null) {
        final statesData = response['states'];
        if (statesData is List) {
          return statesData
              .map((json) => PsState.fromJson(json))
              .toList();
        } else if (statesData is Map) {
          return [PsState.fromJson(statesData as Map<String, dynamic>)];
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch states: $e');
    }
  }
}
