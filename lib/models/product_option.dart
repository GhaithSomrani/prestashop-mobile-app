import '../utils/language_helper.dart';

/// Model for PrestaShop product option (attribute group like Size, Color)
class ProductOption {
  final String id;
  final String name;
  final String publicName;
  final String groupType; // radio, select, color
  final int position;
  final bool isColorGroup;

  ProductOption({
    required this.id,
    required this.name,
    required this.publicName,
    required this.groupType,
    required this.position,
    this.isColorGroup = false,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    final option = json['product_option'] ?? json;

    return ProductOption(
      id: option['id']?.toString() ?? '',
      name: LanguageHelper.extractValueOrEmpty(option['name']),
      publicName: LanguageHelper.extractValueOrEmpty(option['public_name']),
      groupType: option['group_type']?.toString() ?? 'select',
      position: option['position'] is int
          ? option['position']
          : int.tryParse(option['position']?.toString() ?? '0') ?? 0,
      isColorGroup: option['is_color_group'] == '1' || option['is_color_group'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'public_name': publicName,
      'group_type': groupType,
      'position': position,
      'is_color_group': isColorGroup,
    };
  }
}

/// Model for PrestaShop product option value (specific attribute like Large, Red)
class ProductOptionValue {
  final String id;
  final String optionId; // id_attribute_group
  final String name;
  final String? color; // Hex color code if applicable
  final int position;

  ProductOptionValue({
    required this.id,
    required this.optionId,
    required this.name,
    this.color,
    required this.position,
  });

  factory ProductOptionValue.fromJson(Map<String, dynamic> json) {
    final value = json['product_option_value'] ?? json;

    return ProductOptionValue(
      id: value['id']?.toString() ?? '',
      optionId: value['id_attribute_group']?.toString() ?? '',
      name: LanguageHelper.extractValueOrEmpty(value['name']),
      color: value['color']?.toString(),
      position: value['position'] is int
          ? value['position']
          : int.tryParse(value['position']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_attribute_group': optionId,
      'name': name,
      'color': color,
      'position': position,
    };
  }
}
