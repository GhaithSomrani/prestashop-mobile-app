import '../models/attribute.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Service for managing product attributes (Size, Color, etc.)
class AttributeService {
  final ApiService _apiService;

  AttributeService(this._apiService);

  /// Get all attribute groups (e.g., Size, Color)
  Future<List<AttributeGroup>> getAttributeGroups() async {
    try {
      final response = await _apiService.get(
        ApiConfig.productOptionsEndpoint,
        queryParameters: {'display': 'full'},
      );

      List<AttributeGroup> groups = [];
      if (response['product_options'] != null) {
        final groupsData = response['product_options'];
        if (groupsData is List) {
          groups = groupsData
              .map((groupJson) => AttributeGroup.fromJson(groupJson))
              .toList();
        } else if (groupsData is Map) {
          groups = [AttributeGroup.fromJson(groupsData as Map<String, dynamic>)];
        }
      }

      return groups;
    } catch (e) {
      throw Exception('Failed to fetch attribute groups: $e');
    }
  }

  /// Get all values for a specific attribute group
  Future<List<AttributeValue>> getAttributeValues(String groupId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.productOptionValuesEndpoint,
        queryParameters: {
          'filter[id_attribute_group]': groupId,
          'display': 'full',
        },
      );

      List<AttributeValue> values = [];
      if (response['product_option_values'] != null) {
        final valuesData = response['product_option_values'];
        if (valuesData is List) {
          values = valuesData
              .map((valueJson) => AttributeValue.fromJson(valueJson))
              .toList();
        } else if (valuesData is Map) {
          values = [AttributeValue.fromJson(valuesData as Map<String, dynamic>)];
        }
      }

      return values;
    } catch (e) {
      throw Exception('Failed to fetch attribute values: $e');
    }
  }

  /// Get all attribute groups with their values
  Future<List<AttributeGroup>> getAttributeGroupsWithValues() async {
    try {
      final groups = await getAttributeGroups();

      // Fetch values for each group
      for (var group in groups) {
        final values = await getAttributeValues(group.id);
        group.values.clear();
        group.values.addAll(values);
      }

      return groups;
    } catch (e) {
      throw Exception('Failed to fetch attributes with values: $e');
    }
  }

  /// Get color attributes for filtering
  Future<List<AttributeValue>> getColorAttributes() async {
    try {
      final groups = await getAttributeGroups();
      final colorGroup = groups.firstWhere(
        (g) => g.name.toLowerCase().contains('color') ||
               g.name.toLowerCase().contains('colour') ||
               g.groupType == 'color',
        orElse: () => throw Exception('Color group not found'),
      );

      return await getAttributeValues(colorGroup.id);
    } catch (e) {
      return [];
    }
  }

  /// Get size attributes for filtering
  Future<List<AttributeValue>> getSizeAttributes() async {
    try {
      final groups = await getAttributeGroups();
      final sizeGroup = groups.firstWhere(
        (g) => g.name.toLowerCase().contains('size') ||
               g.name.toLowerCase().contains('taille'),
        orElse: () => throw Exception('Size group not found'),
      );

      return await getAttributeValues(sizeGroup.id);
    } catch (e) {
      return [];
    }
  }
}
