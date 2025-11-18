import '../models/product.dart';
import '../models/attribute.dart';
import '../models/manufacturer.dart';
import '../models/feature.dart';
import 'api_service.dart';
import 'attribute_service.dart';
import 'manufacturer_service.dart';
import 'feature_service.dart';

/// Model for dynamic filter data extracted from products
class DynamicFilterData {
  final List<String> brands;
  final List<ColorFilterOption> colors;
  final List<String> sizes;
  final double minPrice;
  final double maxPrice;
  final Map<String, List<String>> features; // Feature name -> values

  DynamicFilterData({
    this.brands = const [],
    this.colors = const [],
    this.sizes = const [],
    required this.minPrice,
    required this.maxPrice,
    this.features = const {},
  });

  bool get hasFilters =>
      brands.isNotEmpty ||
      colors.isNotEmpty ||
      sizes.isNotEmpty ||
      features.isNotEmpty;
}

/// Color filter option with name and hex code
class ColorFilterOption {
  final String name;
  final String? hexColor;

  ColorFilterOption({
    required this.name,
    this.hexColor,
  });
}

/// Service for dynamically generating filters from products and PrestaShop data
class FilterService {
  final ApiService _apiService;
  late final AttributeService _attributeService;
  late final ManufacturerService _manufacturerService;
  late final FeatureService _featureService;

  FilterService(this._apiService) {
    _attributeService = AttributeService(_apiService);
    _manufacturerService = ManufacturerService(_apiService);
    _featureService = FeatureService(_apiService);
  }

  /// Generate dynamic filters from a list of products
  Future<DynamicFilterData> generateFiltersFromProducts(
    List<Product> products,
  ) async {
    if (products.isEmpty) {
      return DynamicFilterData(minPrice: 0, maxPrice: 1000);
    }

    // Extract unique manufacturer IDs
    final manufacturerIds = products
        .where((p) => p.manufacturerId != null)
        .map((p) => p.manufacturerId!)
        .toSet()
        .toList();

    // Get manufacturer names
    List<String> brands = [];
    try {
      final manufacturers = await _manufacturerService.getManufacturers();
      brands = manufacturers
          .where((m) => manufacturerIds.contains(m.id))
          .map((m) => m.name)
          .toList();
    } catch (e) {
      // Fallback to manufacturer names from products
      brands = products
          .where((p) => p.manufacturerName != null)
          .map((p) => p.manufacturerName!)
          .toSet()
          .toList();
    }

    // Calculate price range
    final prices = products.map((p) => p.finalPrice).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    // Get color and size attributes
    List<ColorFilterOption> colors = [];
    List<String> sizes = [];

    try {
      // Fetch attribute groups
      final attributeGroups = await _attributeService.getAttributeGroupsWithValues();

      // Find color group
      final colorGroup = attributeGroups.firstWhere(
        (g) =>
            g.name.toLowerCase().contains('color') ||
            g.name.toLowerCase().contains('colour') ||
            g.groupType == 'color',
        orElse: () => AttributeGroup(id: '', name: '', groupType: '', position: 0),
      );

      if (colorGroup.id.isNotEmpty && colorGroup.values.isNotEmpty) {
        colors = colorGroup.values
            .map((v) => ColorFilterOption(
                  name: v.name,
                  hexColor: v.color,
                ))
            .toList();
      }

      // Find size group
      final sizeGroup = attributeGroups.firstWhere(
        (g) =>
            g.name.toLowerCase().contains('size') ||
            g.name.toLowerCase().contains('taille'),
        orElse: () => AttributeGroup(id: '', name: '', groupType: '', position: 0),
      );

      if (sizeGroup.id.isNotEmpty && sizeGroup.values.isNotEmpty) {
        sizes = sizeGroup.values.map((v) => v.name).toList();
      }
    } catch (e) {
      print('Warning: Could not fetch attributes: $e');
    }

    // Get features from products
    Map<String, Set<String>> featuresMap = {};
    try {
      for (var product in products.take(20)) {
        // Limit to avoid too many requests
        try {
          final productFeatures = await _featureService.getProductFeatures(product.id);
          for (var feature in productFeatures) {
            if (!featuresMap.containsKey(feature.featureName)) {
              featuresMap[feature.featureName] = {};
            }
            featuresMap[feature.featureName]!.add(feature.value);
          }
        } catch (e) {
          // Skip products with errors
        }
      }
    } catch (e) {
      print('Warning: Could not fetch features: $e');
    }

    // Convert features Set to List
    final features = featuresMap.map((key, value) => MapEntry(key, value.toList()));

    return DynamicFilterData(
      brands: brands,
      colors: colors,
      sizes: sizes,
      minPrice: minPrice.floorToDouble(),
      maxPrice: maxPrice.ceilToDouble(),
      features: features,
    );
  }

  /// Generate filters for a specific category
  Future<DynamicFilterData> generateFiltersForCategory(
    String categoryId,
    List<Product> categoryProducts,
  ) async {
    return generateFiltersFromProducts(categoryProducts);
  }

  /// Generate filters for search results
  Future<DynamicFilterData> generateFiltersForSearch(
    List<Product> searchResults,
  ) async {
    return generateFiltersFromProducts(searchResults);
  }

  /// Apply filters to product list (client-side filtering)
  List<Product> applyFilters(
    List<Product> products, {
    List<String>? selectedBrands,
    List<String>? selectedColors,
    List<String>? selectedSizes,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    bool? onSaleOnly,
  }) {
    var filtered = products;

    // Filter by brand
    if (selectedBrands != null && selectedBrands.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.manufacturerName != null &&
              selectedBrands.contains(p.manufacturerName!))
          .toList();
    }

    // Filter by price range
    if (minPrice != null) {
      filtered = filtered.where((p) => p.finalPrice >= minPrice).toList();
    }
    if (maxPrice != null) {
      filtered = filtered.where((p) => p.finalPrice <= maxPrice).toList();
    }

    // Filter by stock
    if (inStockOnly == true) {
      filtered = filtered.where((p) => p.inStock).toList();
    }

    // Filter by sale
    if (onSaleOnly == true) {
      filtered = filtered.where((p) => p.isOnSale).toList();
    }

    // Note: Color and size filtering would require combination data
    // which is not included in the basic product list
    // For full color/size filtering, you'd need to fetch combinations for each product

    return filtered;
  }

  /// Sort products based on sort option
  List<Product> sortProducts(
    List<Product> products,
    String sortBy,
  ) {
    final sorted = List<Product>.from(products);

    switch (sortBy) {
      case 'price_asc':
        sorted.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
        break;
      case 'name_asc':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'newest':
        // Assuming higher ID = newer product
        sorted.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'popular':
        // This would require sales data or view count
        // Fallback to newest for now
        sorted.sort((a, b) => b.id.compareTo(a.id));
        break;
      default:
        // Keep original order
        break;
    }

    return sorted;
  }

  /// Get all available manufacturers for filtering
  Future<List<String>> getAvailableManufacturers() async {
    try {
      final manufacturers = await _manufacturerService.getManufacturers();
      return manufacturers.map((m) => m.name).toList();
    } catch (e) {
      throw Exception('Failed to fetch manufacturers: $e');
    }
  }

  /// Get all available colors for filtering
  Future<List<ColorFilterOption>> getAvailableColors() async {
    try {
      final colors = await _attributeService.getColorAttributes();
      return colors
          .map((c) => ColorFilterOption(
                name: c.name,
                hexColor: c.color,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch colors: $e');
    }
  }

  /// Get all available sizes for filtering
  Future<List<String>> getAvailableSizes() async {
    try {
      final sizes = await _attributeService.getSizeAttributes();
      return sizes.map((s) => s.name).toList();
    } catch (e) {
      throw Exception('Failed to fetch sizes: $e');
    }
  }

  /// Get filter summary text
  String getFilterSummary({
    List<String>? selectedBrands,
    List<String>? selectedColors,
    List<String>? selectedSizes,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    bool? onSaleOnly,
  }) {
    List<String> summaryParts = [];

    if (selectedBrands != null && selectedBrands.isNotEmpty) {
      summaryParts.add('${selectedBrands.length} brand(s)');
    }
    if (selectedColors != null && selectedColors.isNotEmpty) {
      summaryParts.add('${selectedColors.length} color(s)');
    }
    if (selectedSizes != null && selectedSizes.isNotEmpty) {
      summaryParts.add('${selectedSizes.length} size(s)');
    }
    if (minPrice != null || maxPrice != null) {
      summaryParts.add('price range');
    }
    if (inStockOnly == true) {
      summaryParts.add('in stock');
    }
    if (onSaleOnly == true) {
      summaryParts.add('on sale');
    }

    if (summaryParts.isEmpty) {
      return 'No filters applied';
    }

    return summaryParts.join(', ');
  }
}
