/// Model for PrestaShop product attribute group (e.g., Size, Color)
class AttributeGroup {
  final String id;
  final String name;
  final String groupType; // radio, select, color
  final int position;
  final List<AttributeValue> values;

  AttributeGroup({
    required this.id,
    required this.name,
    required this.groupType,
    required this.position,
    this.values = const [],
  });

  factory AttributeGroup.fromJson(Map<String, dynamic> json) {
    return AttributeGroup(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      groupType: json['group_type']?.toString() ?? 'select',
      position: json['position'] is int
          ? json['position']
          : int.tryParse(json['position']?.toString() ?? '0') ?? 0,
      values: json['values'] != null
          ? (json['values'] as List)
              .map((v) => AttributeValue.fromJson(v))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'group_type': groupType,
      'position': position,
      'values': values.map((v) => v.toJson()).toList(),
    };
  }
}

/// Model for PrestaShop attribute value (e.g., Red, Blue, Small, Large)
class AttributeValue {
  final String id;
  final String idAttributeGroup;
  final String name;
  final String? color; // Hex color code if applicable
  final int position;

  AttributeValue({
    required this.id,
    required this.idAttributeGroup,
    required this.name,
    this.color,
    required this.position,
  });

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      id: json['id']?.toString() ?? '',
      idAttributeGroup: json['id_attribute_group']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      color: json['color']?.toString(),
      position: json['position'] is int
          ? json['position']
          : int.tryParse(json['position']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_attribute_group': idAttributeGroup,
      'name': name,
      'color': color,
      'position': position,
    };
  }
}
