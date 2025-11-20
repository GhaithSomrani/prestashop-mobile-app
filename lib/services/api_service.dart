import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  final String baseUrl;
  final String apiKey;

  ApiService({
    required this.baseUrl,
    required this.apiKey,
  });

  Map<String, String> get _headers => {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$apiKey:'))}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      // Build query string manually to avoid encoding brackets
      final params = {
        'output_format': ApiConfig.outputFormat,
        if (queryParameters != null) ...queryParameters,
      };

      final queryString = params.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      final url = '$baseUrl$endpoint?$queryString';
      final uri = Uri.parse(url);

      if (ApiConfig.debugMode) {
        print('GET Request: $uri');
      }

      final response = await http.get(uri, headers: _headers);

      if (ApiConfig.debugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: {'output_format': ApiConfig.outputFormat},
      );

      if (ApiConfig.debugMode) {
        print('POST Request: $uri');
        print('POST Data: ${jsonEncode(data)}');
      }

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      );

      if (ApiConfig.debugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: {'output_format': ApiConfig.outputFormat},
      );

      if (ApiConfig.debugMode) {
        print('PUT Request: $uri');
        print('PUT Data: ${jsonEncode(data)}');
      }

      final response = await http.put(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      );

      if (ApiConfig.debugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<void> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: {'output_format': ApiConfig.outputFormat},
      );

      if (ApiConfig.debugMode) {
        print('DELETE Request: $uri');
      }

      final response = await http.delete(uri, headers: _headers);

      if (ApiConfig.debugMode) {
        print('Response Status: ${response.statusCode}');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException('Failed to delete resource: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      try {
        // Return dynamic to support both Map and List responses
        return jsonDecode(response.body);
      } catch (e) {
        throw ApiException('Failed to parse response: $e');
      }
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized: Invalid API key');
    } else if (response.statusCode == 404) {
      throw ApiException('Resource not found');
    } else if (response.statusCode == 500) {
      throw ApiException('Server error');
    } else {
      throw ApiException(
          'Request failed with status: ${response.statusCode}');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
