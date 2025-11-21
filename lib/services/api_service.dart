import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
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
        'Content-Type': 'application/xml',
        'Accept': 'application/xml',
      };

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: {
          'output_format': ApiConfig.outputFormat,
          if (queryParameters != null) ...queryParameters,
        },
      );

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
        print('POST Data: $data');
      }

      final xmlBody = _mapToXml(data);
      final response = await http.post(
        uri,
        headers: _headers,
        body: xmlBody,
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
        print('PUT Data: $data');
      }

      // Convert data to XML format for PUT
      final xmlBody = _mapToXml(data);

      final response = await http.put(
        uri,
        headers: _headers,
        body: xmlBody,
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
        // Parse XML response and convert to Map
        return _parseXmlResponse(response.body);
      } catch (e) {
        throw ApiException('Failed to parse XML response: $e');
      }
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized: Invalid API key');
    } else if (response.statusCode == 404) {
      throw ApiException('Resource not found');
    } else if (response.statusCode == 500) {
      throw ApiException('Server error');
    } else {
      throw ApiException('Request failed with status: ${response.statusCode}');
    }
  }

  /// Parse XML response and convert to Map structure
  dynamic _parseXmlResponse(String xmlString) {
    final document = xml.XmlDocument.parse(xmlString);
    final rootElement = document.rootElement;

    // PrestaShop XML has a root element like <prestashop>
    if (rootElement.name.local == 'prestashop') {
      final result = <String, dynamic>{};

      for (final child in rootElement.children) {
        if (child is xml.XmlElement) {
          final key = child.name.local;
          final value = _xmlElementToMap(child);
          result[key] = value;
        }
      }

      return result;
    }

    return _xmlElementToMap(rootElement);
  }

  /// Convert XML element to Map or List
  dynamic _xmlElementToMap(xml.XmlElement element) {
    // Check if element has children elements
    final childElements = element.children.whereType<xml.XmlElement>().toList();

    if (childElements.isEmpty) {
      // Return text content if no child elements
      final text = element.innerText.trim();
      return text.isEmpty ? null : text;
    }

    // Check if all children have the same name (it's a list)
    final childNames = childElements.map((e) => e.name.local).toSet();

    if (childNames.length == 1 && childElements.length > 1) {
      // It's a list of items
      return childElements.map((e) => _xmlElementToMap(e)).toList();
    }

    // Check for PrestaShop's list pattern with single child that contains multiple items
    if (childElements.length == 1) {
      final singleChild = childElements.first;
      final grandChildren =
          singleChild.children.whereType<xml.XmlElement>().toList();

      // If single child has multiple children with same name, treat parent as list container
      if (grandChildren.length > 1) {
        final grandChildNames = grandChildren.map((e) => e.name.local).toSet();
        if (grandChildNames.length == 1) {
          return grandChildren.map((e) => _xmlElementToMap(e)).toList();
        }
      }
    }

    // It's a map
    final result = <String, dynamic>{};

    // Add attributes
    for (final attr in element.attributes) {
      result[attr.name.local] = attr.value;
    }

    // Process child elements
    for (final child in childElements) {
      final key = child.name.local;
      final value = _xmlElementToMap(child);

      // Handle PrestaShop's language array pattern
      if (key == 'language' && child.getAttribute('id') != null) {
        if (!result.containsKey(key)) {
          result[key] = [];
        }
        if (result[key] is List) {
          (result[key] as List).add({
            'id': child.getAttribute('id'),
            'value': child.innerText.trim(),
          });
        }
        continue;
      }

      // Check if this key already exists (multiple children with same name = list)
      if (result.containsKey(key)) {
        if (result[key] is! List) {
          result[key] = [result[key]];
        }
        (result[key] as List).add(value);
      } else {
        result[key] = value;
      }
    }

    // Handle special case where element has both text and attributes
    if (result.isEmpty && element.innerText.trim().isNotEmpty) {
      return element.innerText.trim();
    }

    return result;
  }

  /// Convert Map to XML string for POST/PUT requests
  String _mapToXml(Map<String, dynamic> data) {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('prestashop', nest: () {
      _buildXmlFromMap(builder, data);
    });

    return builder.buildDocument().toXmlString();
  }

  void _buildXmlFromMap(xml.XmlBuilder builder, Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value == null) return;

      if (value is Map<String, dynamic>) {
        builder.element(key, nest: () {
          _buildXmlFromMap(builder, value);
        });
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            builder.element(key, nest: () {
              _buildXmlFromMap(builder, item);
            });
          } else {
            builder.element(key, nest: item.toString());
          }
        }
      } else {
        builder.element(key, nest: value.toString());
      }
    });
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
