import '../models/product.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'stock_service.dart';

class ProductService {
  final ApiService _apiService;
  late final StockService _stockService;

  ProductService(this._apiService) {
    _stockService = StockService(_apiService);
  }

  Future<List<Product>> getProducts({
    int? limit,
    int? offset,
    String? categoryId,
    String? searchQuery,
    bool filterInStock = false, // Changed default to false to show all products initially
  }) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        if (limit != null) 'limit': '${offset ?? 0},$limit',
        if (categoryId != null) 'filter[id_category_default]': categoryId,
        if (searchQuery != null) 'filter[name]': '%$searchQuery%',
        'filter[active]': '1', // Only active products
      };

      final response = await _apiService.get(
        ApiConfig.productsEndpoint,
        queryParameters: queryParams,
      );

      // Handle both single product and array of products
      List<Product> products = [];
      if (response['products'] != null) {
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

      // Fetch stock data for all products from stock_availables endpoint
      if (products.isNotEmpty) {
        final productIds = products.map((p) => p.id).toList();
        try {
          final stockMap = await _stockService.getStockForProducts(productIds);

          // Update product quantities with stock data
          products = products.map((product) {
            final stockQuantity = stockMap[product.id] ?? product.quantity;
            return Product(
              id: product.id,
              name: product.name,
              description: product.description,
              shortDescription: product.shortDescription,
              price: product.price,
              reducedPrice: product.reducedPrice,
              imageUrl: product.imageUrl,
              images: product.images,
              quantity: stockQuantity,
              reference: product.reference,
              active: product.active,
              categoryId: product.categoryId,
              variants: product.variants,
            );
          }).toList();
        } catch (e) {
          print('Warning: Could not fetch stock data: $e');
          // Continue with product data as is
        }
      }

      // Filter out-of-stock products if requested
      if (filterInStock) {
        products = products.where((product) => product.inStock).toList();
      }

      return products;
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.productsEndpoint}/$id',
        queryParameters: {},
      );

      if (response['product'] != null) {
        return Product.fromJson(response['product']);
      }

      throw Exception('Product not found');
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  Future<List<Product>> searchProducts(String query, {bool filterInStock = true}) async {
    return getProducts(searchQuery: query, filterInStock: filterInStock);
  }

  Future<List<Product>> getProductsByCategory(String categoryId, {bool filterInStock = true}) async {
    return getProducts(categoryId: categoryId, filterInStock: filterInStock);
  }

  Future<List<Product>> getFeaturedProducts({bool filterInStock = true}) async {
    // Assuming featured products can be filtered by a specific attribute
    // This implementation may vary based on PrestaShop configuration
    return getProducts(limit: 10, filterInStock: filterInStock);
  }
}
