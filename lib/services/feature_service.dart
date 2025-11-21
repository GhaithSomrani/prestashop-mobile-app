import '../models/feature.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Service for managing product features (Material, Weight, etc.)
class FeatureService {
  final ApiService _apiService;

  FeatureService(this._apiService);

  /// Get all features
  Future<List<Feature>> getFeatures() async {
    try {
      final response = await _apiService.get(
        ApiConfig.featuresEndpoint,
        queryParameters: {'display': 'full'},
      );

      List<Feature> features = [];
      if (response['features'] != null) {
        final featuresData = response['features'];
        if (featuresData is List) {
          features = featuresData
              .map((featureJson) => Feature.fromJson(featureJson))
              .toList();
        } else if (featuresData is Map) {
          features = [Feature.fromJson(featuresData as Map<String, dynamic>)];
        }
      }

      return features;
    } catch (e) {
      throw Exception('Failed to fetch features: $e');
    }
  }

  /// Get all values for a specific feature
  Future<List<FeatureValue>> getFeatureValues(String featureId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.featureValuesEndpoint,
        queryParameters: {
          'filter[id_feature]': featureId,
          'display': 'full',
        },
      );

      List<FeatureValue> values = [];
      if (response['feature_values'] != null) {
        final valuesData = response['feature_values'];
        if (valuesData is List) {
          values = valuesData
              .map((valueJson) => FeatureValue.fromJson(valueJson))
              .toList();
        } else if (valuesData is Map) {
          values = [FeatureValue.fromJson(valuesData as Map<String, dynamic>)];
        }
      }

      return values;
    } catch (e) {
      throw Exception('Failed to fetch feature values: $e');
    }
  }

  /// Get product features with their values for a specific product
  Future<List<ProductFeature>> getProductFeatures(String productId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.productsEndpoint}/$productId',
        queryParameters: {},
      );

      List<ProductFeature> productFeatures = [];

      if (response['product']?['associations']?['product_features'] != null) {
        final featuresData = response['product']['associations']['product_features'];
        if (featuresData is List) {
          productFeatures = featuresData
              .map((featureJson) => ProductFeature.fromJson(featureJson))
              .toList();
        }
      }

      return productFeatures;
    } catch (e) {
      throw Exception('Failed to fetch product features: $e');
    }
  }

  /// Get all unique feature values from multiple products (for filtering)
  Future<Map<String, List<String>>> getUniqueFeatureValues(
    List<String> productIds,
  ) async {
    try {
      Map<String, Set<String>> featureValuesMap = {};

      for (var productId in productIds) {
        final productFeatures = await getProductFeatures(productId);

        for (var feature in productFeatures) {
          if (!featureValuesMap.containsKey(feature.featureName)) {
            featureValuesMap[feature.featureName] = {};
          }
          featureValuesMap[feature.featureName]!.add(feature.value);
        }
      }

      // Convert Set to List
      return featureValuesMap.map((key, value) => MapEntry(key, value.toList()));
    } catch (e) {
      throw Exception('Failed to extract unique feature values: $e');
    }
  }
}
