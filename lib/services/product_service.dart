import '../models/product.dart';
import '../models/combination.dart';
import '../models/specific_price.dart';
import '../models/feature.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'stock_service.dart';
import 'combination_service.dart';
import 'manufacturer_service.dart';
import 'specific_price_service.dart';
import 'feature_service.dart';

class ProductService {
  final ApiService _apiService;
  late final StockService _stockService;
  late final CombinationService _combinationService;
  late final ManufacturerService _manufacturerService;
  late final SpecificPriceService _specificPriceService;
  late final FeatureService _featureService;

  ProductService(this._apiService) {
    _stockService = StockService(_apiService);
    _combinationService = CombinationService(_apiService);
    _manufacturerService = ManufacturerService(_apiService);
    _specificPriceService = SpecificPriceService(_apiService);
    _featureService = FeatureService(_apiService);
  }

  /// Get products with pagination support for infinite scroll
  Future<List<Product>> getProducts({
    int? limit,
    int? offset,
    String? categoryId,
    String? searchQuery,
    String? manufacturerId,
    double? minPrice,
    double? maxPrice,
    bool filterInStock = false,
    String? sortBy, // id_DESC, price_ASC, price_DESC, name_ASC, name_DESC
  }) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        if (limit != null) 'limit': '${offset ?? 0},$limit',
        if (categoryId != null) 'filter[id_category_default]': categoryId,
        if (searchQuery != null) 'filter[name]': '%$searchQuery%',
        if (manufacturerId != null) 'filter[id_manufacturer]': manufacturerId,
        if (minPrice != null) 'filter[price]': '[$minPrice,${maxPrice ?? 999999}]',
        'filter[active]': '1', // Only active products
        if (sortBy != null) 'sort': '[$sortBy]',
      };

      final response = await _apiService.get(
        ApiConfig.productsEndpoint,
        queryParameters: queryParams,
      );

      // Handle different response formats from PrestaShop API
      List<Product> products = [];

      // Case 1: Empty array response []
      if (response is List) {
        if (response.isEmpty) {
          return []; // No products found
        }
        // Case 2: Direct array of products (without wrapper)
        products = response
            .map((productJson) => Product.fromJson(productJson))
            .toList();
      }
      // Case 3: Response is a Map with 'products' key
      else if (response is Map && response['products'] != null) {
        final productsData = response['products'];
        if (productsData is List) {
          products = productsData
              .map((productJson) => Product.fromJson(productJson))
              .toList();
        } else if (productsData is Map) {
          // Single product wrapped in products key
          products = [Product.fromJson(productsData as Map<String, dynamic>)];
        }
      }
      // Case 4: Empty result
      else {
        return [];
      }

      // Enrich products with additional data
      products = await _enrichProducts(products);

      // Filter out-of-stock products if requested
      if (filterInStock) {
        products = products.where((product) => product.inStock).toList();
      }

      return products;
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Enrich products with stock, manufacturer, and discount data
  Future<List<Product>> _enrichProducts(List<Product> products) async {
    if (products.isEmpty) return products;

    try {
      // Fetch stock data
      final productIds = products.map((p) => p.id).toList();
      final stockDataMap = await _stockService.getStockForProducts(productIds);

      // Convert to quantity map
      final stockMap = <String, int>{};
      for (final entry in stockDataMap.entries) {
        final stocks = entry.value;
        stockMap[entry.key] = stocks.fold<int>(0, (sum, stock) => sum + stock.quantity);
      }

      // Fetch manufacturer names
      Map<String, String> manufacturerNames = {};
      try {
        final manufacturers = await _manufacturerService.getManufacturers();
        for (var manufacturer in manufacturers) {
          manufacturerNames[manufacturer.id] = manufacturer.name;
        }
      } catch (e) {
        print('Warning: Could not fetch manufacturers: $e');
      }

      // Check for specific prices (discounts)
      Map<String, SpecificPrice?> specificPrices = {};
      for (var product in products) {
        try {
          final prices = await _specificPriceService.getSpecificPricesForProduct(product.id);
          if (prices.isNotEmpty) {
            specificPrices[product.id] = prices.first;
          }
        } catch (e) {
          // Continue without discount data
        }
      }

      // Update products with enriched data
      return products.map((product) {
        final stockQuantity = stockMap[product.id] ?? product.quantity;
        final manufacturerName = product.manufacturerId != null
            ? manufacturerNames[product.manufacturerId]
            : null;
        final specificPrice = specificPrices[product.id];

        double? finalPrice;
        double? discountPercent;
        bool onSale = false;

        if (specificPrice != null) {
          finalPrice = specificPrice.calculateFinalPrice(product.price);
          discountPercent = specificPrice.discountPercentage;
          onSale = true;
        }

        return product.copyWith(
          quantity: stockQuantity,
          manufacturerName: manufacturerName,
          reducedPrice: finalPrice,
          onSale: onSale,
          discountPercentage: discountPercent,
        );
      }).toList();
    } catch (e) {
      print('Warning: Could not enrich products: $e');
      return products;
    }
  }

  /// Get single product with full details (combinations, features, etc.)
  Future<Product> getProductById(String id) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.productsEndpoint}/$id',
        queryParameters: {},
      );

      if (response['product'] == null) {
        throw Exception('Product not found');
      }

      Product product = Product.fromJson(response['product']);

      // Enrich with additional data
      final enrichedProducts = await _enrichProducts([product]);
      return enrichedProducts.first;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Get product combinations (variants)
  Future<List<Combination>> getProductCombinations(String productId) async {
    return await _combinationService.getCombinationsByProduct(productId);
  }

  /// Get product features
  Future<List<ProductFeature>> getProductFeatures(String productId) async {
    return await _featureService.getProductFeatures(productId);
  }

  /// Get related products (same category, different product)
  Future<List<Product>> getRelatedProducts(
    String productId,
    String categoryId, {
    int limit = 10,
  }) async {
    try {
      final products = await getProducts(
        categoryId: categoryId,
        limit: limit + 5, // Fetch extra in case current product is included
      );

      // Filter out current product
      final relatedProducts = products.where((p) => p.id != productId).toList();

      // Return only requested limit
      return relatedProducts.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch related products: $e');
    }
  }

  /// Search products with pagination
  Future<List<Product>> searchProducts(
    String query, {
    int? limit,
    int? offset,
    bool filterInStock = false,
  }) async {
    return getProducts(
      searchQuery: query,
      limit: limit,
      offset: offset,
      filterInStock: filterInStock,
    );
  }

  /// Get products by category with pagination
  Future<List<Product>> getProductsByCategory(
    String categoryId, {
    int? limit,
    int? offset,
    bool filterInStock = false,
    String? sortBy,
  }) async {
    return getProducts(
      categoryId: categoryId,
      limit: limit,
      offset: offset,
      filterInStock: filterInStock,
      sortBy: sortBy,
    );
  }

  /// Get featured products (first X products or by specific logic)
  Future<List<Product>> getFeaturedProducts({
    int limit = 10,
    bool filterInStock = false,
  }) async {
    // Implementation can vary based on PrestaShop configuration
    // Option 1: Get first N products (newest)
    // Option 2: Get products with specific feature/tag
    // Option 3: Get products from featured category
    return getProducts(
      limit: limit,
      filterInStock: filterInStock,
      sortBy: 'id_DESC',
    );
  }

  /// Get latest products
  Future<List<Product>> getLatestProducts({
    int limit = 10,
    bool filterInStock = false,
  }) async {
    return getProducts(
      limit: limit,
      filterInStock: filterInStock,
      sortBy: 'id_DESC',
    );
  }

  /// Get products on sale
  Future<List<Product>> getProductsOnSale({
    int? limit,
    int? offset,
  }) async {
    try {
      // Get products with active specific prices
      final productsOnSaleIds = await _specificPriceService.getProductsOnSale();

      if (productsOnSaleIds.isEmpty) {
        return [];
      }

      // Fetch products (PrestaShop might not support filtering by array of IDs directly)
      // So we fetch products and filter them
      final allProducts = await getProducts(limit: 100);
      final onSaleProducts = allProducts
          .where((p) => productsOnSaleIds.contains(p.id))
          .toList();

      return onSaleProducts;
    } catch (e) {
      throw Exception('Failed to fetch products on sale: $e');
    }
  }

  /// Get products by manufacturer
  Future<List<Product>> getProductsByManufacturer(
    String manufacturerId, {
    int? limit,
    int? offset,
  }) async {
    return getProducts(
      manufacturerId: manufacturerId,
      limit: limit,
      offset: offset,
    );
  }

  /// Get products by price range
  Future<List<Product>> getProductsByPriceRange(
    double minPrice,
    double maxPrice, {
    String? categoryId,
    int? limit,
    int? offset,
  }) async {
    return getProducts(
      minPrice: minPrice,
      maxPrice: maxPrice,
      categoryId: categoryId,
      limit: limit,
      offset: offset,
    );
  }

  /// Get best selling products
  /// Note: PrestaShop tracks sales in orders, this is a simplified version
  /// In production, you'd query order_detail and aggregate by product_id
  Future<List<Product>> getBestSellingProducts({
    int limit = 10,
    bool filterInStock = false,
  }) async {
    try {
      // Get products sorted by sales (position in PrestaShop often reflects popularity)
      final queryParams = <String, String>{
        'display': 'full',
        'limit': '$limit',
        'filter[active]': '1',
        'sort': '[position_ASC]', // Products with better position are often best sellers
      };

      final response = await _apiService.get(
        ApiConfig.productsEndpoint,
        queryParameters: queryParams,
      );

      List<Product> products = [];

      if (response is List) {
        if (response.isEmpty) return [];
        products = response
            .map((productJson) => Product.fromJson(productJson))
            .toList();
      } else if (response is Map && response['products'] != null) {
        final productsData = response['products'];
        if (productsData is List) {
          products = productsData
              .map((productJson) => Product.fromJson(productJson))
              .toList();
        } else if (productsData is Map) {
          products = [Product.fromJson(productsData as Map<String, dynamic>)];
        }
      }

      products = await _enrichProducts(products);

      if (filterInStock) {
        products = products.where((product) => product.inStock).toList();
      }

      return products;
    } catch (e) {
      throw Exception('Failed to fetch best selling products: $e');
    }
  }

  /// Get products with price drops (on sale with significant discount)
  Future<List<Product>> getPricesDropProducts({
    int limit = 10,
    double minimumDiscount = 10.0, // Minimum discount percentage
  }) async {
    try {
      // Get all products on sale
      final onSaleProducts = await getProductsOnSale(limit: 100);

      // Filter by minimum discount
      final pricesDropProducts = onSaleProducts
          .where((p) => (p.discountPercentage ?? 0) >= minimumDiscount)
          .toList();

      // Sort by discount percentage (highest first)
      pricesDropProducts.sort((a, b) =>
          (b.discountPercentage ?? 0).compareTo(a.discountPercentage ?? 0));

      return pricesDropProducts.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch prices drop products: $e');
    }
  }
}
