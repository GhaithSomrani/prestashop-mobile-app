# API Documentation

Comprehensive guide for integrating with PrestaShop Webservice API in the mobile application.

---

## Table of Contents

1. [Authentication](#authentication)
2. [API Service Architecture](#api-service-architecture)
3. [Product Endpoints](#product-endpoints)
4. [Category Endpoints](#category-endpoints)
5. [Cart & Checkout Endpoints](#cart--checkout-endpoints)
6. [Customer Endpoints](#customer-endpoints)
7. [Order Endpoints](#order-endpoints)
8. [Error Handling](#error-handling)
9. [Best Practices](#best-practices)

---

## Authentication

All API requests use **HTTP Basic Authentication** with the PrestaShop API key.

### Implementation

```dart
// lib/services/api_service.dart
Map<String, String> get _headers => {
  'Authorization': 'Basic ${base64Encode(utf8.encode('$apiKey:'))}',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};
```

### PrestaShop API Key Setup

1. Login to PrestaShop admin panel
2. Navigate to: **Advanced Parameters** > **Webservice**
3. Enable webservice
4. Click "Add new webservice key"
5. Set permissions for endpoints:
   - Products: `GET`
   - Categories: `GET`
   - Customers: `GET`, `POST`, `PUT`
   - Orders: `GET`, `POST`
   - Carts: `GET`, `POST`, `PUT`
   - Addresses: `GET`, `POST`, `PUT`
   - Carriers: `GET`
   - Stock: `GET`
   - Manufacturers: `GET`
   - Specific Prices: `GET`
   - Combinations: `GET`
   - Attributes: `GET`
   - Features: `GET`
6. Copy the generated API key to `.env` file

---

## API Service Architecture

### Base API Service

**File**: `lib/services/api_service.dart`

Provides low-level HTTP methods with authentication and error handling.

#### Methods

**GET Request:**
```dart
Future<dynamic> get(
  String endpoint, {
  Map<String, String>? queryParameters,
}) async
```

**POST Request:**
```dart
Future<Map<String, dynamic>> post(
  String endpoint,
  Map<String, dynamic> data,
) async
```

**PUT Request:**
```dart
Future<Map<String, dynamic>> put(
  String endpoint,
  Map<String, dynamic> data,
) async
```

**DELETE Request:**
```dart
Future<void> delete(String endpoint) async
```

### Response Format Handling

PrestaShop API can return different formats. The app handles:

1. **Empty Array**: `[]`
2. **Single Wrapped**: `{"product": {...}}`
3. **Multiple Wrapped**: `{"products": [{...}, {...}]}`
4. **Direct Array**: `[{...}, {...}]`

```dart
// Handling in ProductService
if (response is List) {
  if (response.isEmpty) return [];
  return response.map((json) => Product.fromJson(json)).toList();
} else if (response is Map && response['products'] != null) {
  final productsData = response['products'];
  if (productsData is List) {
    return productsData.map((json) => Product.fromJson(json)).toList();
  } else if (productsData is Map) {
    return [Product.fromJson(productsData as Map<String, dynamic>)];
  }
}
```

---

## Product Endpoints

**Base Endpoint**: `/api/products`

**Service**: `lib/services/product_service.dart`

### Get All Products (with Pagination)

**Method**: `GET /api/products`

**Query Parameters:**
- `output_format=JSON` - Response format
- `display=full` - Full product details
- `limit=offset,count` - Pagination (e.g., `0,20` for first 20 products)
- `filter[active]=1` - Only active products
- `sort=[field_DIRECTION]` - Sort (e.g., `[price_ASC]`, `[id_DESC]`)

**Example Request:**
```
GET /api/products?output_format=JSON&display=full&limit=0,20&filter[active]=1&sort=[id_DESC]
```

**Code:**
```dart
Future<List<Product>> getProducts({
  int? limit,
  int? offset,
  String? sortBy,
}) async {
  final queryParams = <String, String>{
    'display': 'full',
    if (limit != null) 'limit': '${offset ?? 0},$limit',
    'filter[active]': '1',
    if (sortBy != null) 'sort': '[$sortBy]',
  };

  final response = await _apiService.get(
    ApiConfig.productsEndpoint,
    queryParameters: queryParams,
  );

  // Parse response...
  return products;
}
```

**Response:**
```json
{
  "products": [
    {
      "id": "123",
      "name": "Product Name",
      "description": "Product description",
      "price": "99.99",
      "id_manufacturer": "5",
      "id_category_default": "10",
      "active": "1",
      "quantity": "50"
    }
  ]
}
```

### Get Products by Category

**Method**: `GET /api/products?filter[id_category_default]=ID`

**Code:**
```dart
Future<List<Product>> getProductsByCategory(
  String categoryId, {
  int? limit,
  int? offset,
  String? sortBy,
}) async {
  return getProducts(
    categoryId: categoryId,
    limit: limit,
    offset: offset,
    sortBy: sortBy,
  );
}
```

**Example Request:**
```
GET /api/products?output_format=JSON&display=full&filter[id_category_default]=663&filter[active]=1&limit=0,20
```

### Get Single Product

**Method**: `GET /api/products/{id}`

**Code:**
```dart
Future<Product> getProductById(String id) async {
  final response = await _apiService.get(
    '${ApiConfig.productsEndpoint}/$id',
    queryParameters: {'display': 'full'},
  );

  if (response['product'] == null) {
    throw Exception('Product not found');
  }

  Product product = Product.fromJson(response['product']);
  final enrichedProducts = await _enrichProducts([product]);
  return enrichedProducts.first;
}
```

### Search Products

**Method**: `GET /api/products?filter[name]=%keyword%`

**Code:**
```dart
Future<List<Product>> searchProducts(
  String query, {
  int? limit,
  int? offset,
}) async {
  return getProducts(
    searchQuery: query,
    limit: limit,
    offset: offset,
  );
}
```

**Example Request:**
```
GET /api/products?output_format=JSON&display=full&filter[name]=%shirt%&filter[active]=1
```

### Get Products by Manufacturer

**Method**: `GET /api/products?filter[id_manufacturer]=ID`

**Code:**
```dart
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
```

### Get Products by Price Range

**Method**: `GET /api/products?filter[price]=[min,max]`

**Code:**
```dart
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
```

---

## Category Endpoints

**Base Endpoint**: `/api/categories`

**Service**: `lib/services/category_service.dart`

### Get All Categories

**Method**: `GET /api/categories`

**Code:**
```dart
Future<List<Category>> getCategories({
  int? limit,
  int? offset,
}) async {
  final queryParams = <String, String>{
    'display': 'full',
    if (limit != null) 'limit': '$offset,$limit',
  };

  final response = await _apiService.get(
    ApiConfig.categoriesEndpoint,
    queryParameters: queryParams,
  );

  // Handle different response formats
  if (response is List) {
    if (response.isEmpty) return [];
    return response.map((json) => Category.fromJson(json)).toList();
  } else if (response is Map && response['categories'] != null) {
    // Parse categories...
  }

  return [];
}
```

### Get Root Categories

**Method**: `GET /api/categories?filter[id_parent]=2`

**Code:**
```dart
Future<List<Category>> getRootCategories() async {
  final queryParams = <String, String>{
    'display': 'full',
    'filter[id_parent]': '2', // PrestaShop root parent ID
  };

  final response = await _apiService.get(
    ApiConfig.categoriesEndpoint,
    queryParameters: queryParams,
  );

  // Parse response...
  return categories;
}
```

### Get Subcategories

**Method**: `GET /api/categories?filter[id_parent]=ID`

**Code:**
```dart
Future<List<Category>> getSubcategories(String parentId) async {
  final queryParams = <String, String>{
    'display': 'full',
    'filter[id_parent]': parentId,
    'filter[active]': '1',
  };

  final response = await _apiService.get(
    ApiConfig.categoriesEndpoint,
    queryParameters: queryParams,
  );

  // Parse response...
  return subcategories;
}
```

### Get Category by ID

**Method**: `GET /api/categories/{id}`

**Code:**
```dart
Future<Category> getCategoryById(String id) async {
  final response = await _apiService.get(
    '${ApiConfig.categoriesEndpoint}/$id',
    queryParameters: {'display': 'full'},
  );

  if (response['category'] != null) {
    return Category.fromJson(response['category']);
  }

  throw Exception('Category not found');
}
```

---

## Cart & Checkout Endpoints

### Stock Availability

**Endpoint**: `/api/stock_availables`

**Service**: `lib/services/stock_service.dart`

**Method**: `GET /api/stock_availables?filter[id_product]=ID`

**Code:**
```dart
Future<int> getProductStock(String productId) async {
  final queryParams = <String, String>{
    'display': 'full',
    'filter[id_product]': productId,
  };

  final response = await _apiService.get(
    ApiConfig.stocksEndpoint,
    queryParameters: queryParams,
  );

  // Parse stock quantity from response
  return quantity;
}
```

### Combinations (Product Variants)

**Endpoint**: `/api/combinations`

**Service**: `lib/services/combination_service.dart`

**Method**: `GET /api/combinations?filter[id_product]=ID`

**Code:**
```dart
Future<List<Combination>> getCombinationsByProduct(String productId) async {
  final queryParams = <String, String>{
    'display': 'full',
    'filter[id_product]': productId,
  };

  final response = await _apiService.get(
    ApiConfig.combinationsEndpoint,
    queryParameters: queryParams,
  );

  // Parse combinations...
  return combinations;
}
```

---

## Customer Endpoints

**Base Endpoint**: `/api/customers`

**Service**: `lib/services/customer_service.dart`

### Register Customer

**Method**: `POST /api/customers`

**Payload:**
```json
{
  "customer": {
    "email": "user@example.com",
    "firstname": "John",
    "lastname": "Doe",
    "passwd": "securepassword123",
    "active": "1"
  }
}
```

**Code:**
```dart
Future<Customer> registerCustomer({
  required String email,
  required String firstname,
  required String lastname,
  required String password,
}) async {
  final data = {
    'customer': {
      'email': email,
      'firstname': firstname,
      'lastname': lastname,
      'passwd': password,
      'active': '1',
    },
  };

  final response = await _apiService.post(
    ApiConfig.customersEndpoint,
    data,
  );

  return Customer.fromJson(response['customer']);
}
```

### Get Customer by Email

**Method**: `GET /api/customers?filter[email]=email@example.com`

**Code:**
```dart
Future<Customer?> getCustomerByEmail(String email) async {
  final queryParams = <String, String>{
    'display': 'full',
    'filter[email]': email,
  };

  final response = await _apiService.get(
    ApiConfig.customersEndpoint,
    queryParameters: queryParams,
  );

  // Parse customer...
  return customer;
}
```

---

## Order Endpoints

**Base Endpoint**: `/api/orders`

**Service**: `lib/services/order_service.dart`

### Create Order

**Method**: `POST /api/orders`

**Payload:**
```json
{
  "order": {
    "id_customer": "123",
    "id_cart": "456",
    "id_carrier": "2",
    "payment": "Credit Card",
    "total_paid": "150.00",
    "total_products": "140.00",
    "total_shipping": "10.00"
  }
}
```

**Code:**
```dart
Future<Order> createOrder({
  required String customerId,
  required String cartId,
  required String carrierId,
  required String payment,
  required double totalPaid,
  required double totalProducts,
  required double totalShipping,
}) async {
  final data = {
    'order': {
      'id_customer': customerId,
      'id_cart': cartId,
      'id_carrier': carrierId,
      'payment': payment,
      'total_paid': totalPaid.toStringAsFixed(2),
      'total_products': totalProducts.toStringAsFixed(2),
      'total_shipping': totalShipping.toStringAsFixed(2),
    },
  };

  final response = await _apiService.post(
    ApiConfig.ordersEndpoint,
    data,
  );

  return Order.fromJson(response['order']);
}
```

### Get Customer Orders

**Method**: `GET /api/orders?filter[id_customer]=ID`

**Code:**
```dart
Future<List<Order>> getCustomerOrders(String customerId) async {
  final queryParams = <String, String>{
    'display': 'full',
    'filter[id_customer]': customerId,
    'sort': '[id_DESC]', // Newest first
  };

  final response = await _apiService.get(
    ApiConfig.ordersEndpoint,
    queryParameters: queryParams,
  );

  // Parse orders...
  return orders;
}
```

---

## Error Handling

### API Exception Class

```dart
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
```

### Error Response Handling

```dart
dynamic _handleResponse(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body);
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
```

### Provider Error Handling

```dart
// In ProductProvider
try {
  final products = await _productService.getProducts();
  _products = products;
  _error = null;
} catch (e) {
  _error = e.toString();
  if (kDebugMode) {
    print('Error fetching products: $e');
  }
} finally {
  _isLoading = false;
  notifyListeners();
}
```

---

## Best Practices

### 1. Always Use Pagination

❌ **Bad:**
```dart
// Loads all products at once (slow, memory intensive)
GET /api/products?output_format=JSON&display=full
```

✅ **Good:**
```dart
// Load 20 products at a time
GET /api/products?output_format=JSON&display=full&limit=0,20
```

### 2. Filter Active Products Only

❌ **Bad:**
```dart
GET /api/products?output_format=JSON&display=full
```

✅ **Good:**
```dart
GET /api/products?output_format=JSON&display=full&filter[active]=1
```

### 3. Handle Empty Responses

❌ **Bad:**
```dart
final products = response['products'] as List; // May crash
```

✅ **Good:**
```dart
if (response is List && response.isEmpty) return [];
if (response is Map && response['products'] != null) {
  // Safe parsing
}
```

### 4. Use Debug Mode for Development

```dart
// lib/config/api_config.dart
static const bool debugMode = true; // Enable during development
```

This logs all API requests and responses:
```
GET Request: https://store.com/api/products?output_format=JSON&limit=0,20
Response Status: 200
Response Body: {"products": [...]}
```

### 5. Enrich Product Data

Combine multiple endpoints for complete product information:

```dart
Future<List<Product>> _enrichProducts(List<Product> products) async {
  // Fetch stock data
  final stockMap = await _stockService.getStockForProducts(productIds);

  // Fetch manufacturer names
  final manufacturers = await _manufacturerService.getManufacturers();

  // Fetch discounts
  final specificPrices = await _specificPriceService.getSpecificPricesForProduct(id);

  // Combine all data into Product model
  return enrichedProducts;
}
```

### 6. Implement Retry Logic

```dart
Future<dynamic> _getWithRetry(String endpoint, {int retries = 3}) async {
  for (int i = 0; i < retries; i++) {
    try {
      return await _apiService.get(endpoint);
    } catch (e) {
      if (i == retries - 1) rethrow;
      await Future.delayed(Duration(seconds: pow(2, i).toInt()));
    }
  }
}
```

### 7. Cache Frequently Used Data

```dart
class CategoryProvider with ChangeNotifier {
  List<Category>? _cachedCategories;
  DateTime? _lastFetch;

  Future<void> fetchCategories({bool forceRefresh = false}) async {
    // Use cache if available and less than 5 minutes old
    if (!forceRefresh && _cachedCategories != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!) < Duration(minutes: 5)) {
        return;
      }
    }

    // Fetch fresh data
    _cachedCategories = await _categoryService.getCategories();
    _lastFetch = DateTime.now();
    notifyListeners();
  }
}
```

---

## API Rate Limiting

PrestaShop doesn't enforce strict rate limiting, but follow these guidelines:

- **Limit**: ~100 requests per minute recommended
- **Pagination**: Always use pagination to reduce load
- **Caching**: Cache static data (categories, manufacturers)
- **Batch Requests**: Combine related data fetches when possible

---

## Testing API Integration

### Manual Testing with cURL

```bash
# Test authentication
curl -X GET \
  "https://your-store.com/api/products?output_format=JSON&display=full&limit=0,5" \
  -H "Authorization: Basic $(echo -n 'YOUR_API_KEY:' | base64)"

# Test product search
curl -X GET \
  "https://your-store.com/api/products?output_format=JSON&filter[name]=%shirt%" \
  -H "Authorization: Basic $(echo -n 'YOUR_API_KEY:' | base64)"
```

### Unit Testing

```dart
// test/services/product_service_test.dart
void main() {
  group('ProductService', () {
    late MockApiService mockApiService;
    late ProductService productService;

    setUp(() {
      mockApiService = MockApiService();
      productService = ProductService(mockApiService);
    });

    test('handles empty array response', () async {
      when(mockApiService.get(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => []);

      final products = await productService.getProducts();

      expect(products, isEmpty);
    });

    test('parses products from Map response', () async {
      when(mockApiService.get(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => {
            'products': [
              {'id': '1', 'name': 'Test Product', 'price': '99.99'}
            ]
          });

      final products = await productService.getProducts();

      expect(products.length, equals(1));
      expect(products.first.id, equals('1'));
    });
  });
}
```

---

**Last Updated:** 2025-01-18
**Version:** 1.0.0
