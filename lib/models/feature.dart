/// Model for PrestaShop product feature (e.g., Material, Weight)
class Feature {
  final String id;
  final String name;
  final int position;

  Feature({
    required this.id,
    required this.name,
    required this.position,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      position: json['position'] is int
          ? json['position']
          : int.tryParse(json['position']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
    };
  }
}

/// Model for PrestaShop feature value (e.g., Cotton, 500g)
class FeatureValue {
  final String id;
  final String idFeature;
  final String value;
  final bool custom;

  FeatureValue({
    required this.id,
    required this.idFeature,
    required this.value,
    this.custom = false,
  });

  factory FeatureValue.fromJson(Map<String, dynamic> json) {
    return FeatureValue(
      id: json['id']?.toString() ?? '',
      idFeature: json['id_feature']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      custom: json['custom'] == '1' || json['custom'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_feature': idFeature,
      'value': value,
      'custom': custom,
    };
  }
}

/// Product feature association (product has feature with specific value)
class ProductFeature {
  final String featureId;
  final String featureName;
  final String valueId;
  final String value;

  ProductFeature({
    required this.featureId,
    required this.featureName,
    required this.valueId,
    required this.value,
  });

  factory ProductFeature.fromJson(Map<String, dynamic> json) {
    return ProductFeature(
      featureId: json['id_feature']?.toString() ?? '',
      featureName: json['feature_name']?.toString() ?? '',
      valueId: json['id_feature_value']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_feature': featureId,
      'feature_name': featureName,
      'id_feature_value': valueId,
      'value': value,
    };
  }
}
