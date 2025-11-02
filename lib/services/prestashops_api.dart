import 'dart:convert';
import '../config/app_config.dart';
import '../utils/api_client.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../models/address.dart';

class PrestaShopAPI {
  final APIClient _client = apiClient;

  // Product API methods
  Future<List<Product>> getProducts({
    int? categoryId,
    String? search,
    int page = 1,
    int limit = AppConfig.defaultPageSize,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'display': 'full',
        'limit': '$limit',
        'page': '$page',
      };

      if (categoryId != null) {
        queryParameters['filter[id_category_default]'] = '[$categoryId]';
      }

      if (search != null && search.isNotEmpty) {
        queryParameters['filter[name]'] = '[$search]';
      }

      if (sortBy != null) {
        queryParameters['sort'] = '[$sortBy_${sortOrder ?? "ASC"}]';
      }

      if (filters != null) {
        filters.forEach((key, value) {
          queryParameters['filter[$key]'] = value is List ? '[${value.join("|")}]' : '[$value]';
        });
      }

      final response = await _client.get('/products', queryParameters: queryParameters);

      if (response.data['products'] != null) {
        final productsList = response.data['products'] is List
            ? response.data['products']
            : [response.data['products']];

        return productsList.map((json) => Product.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<Product?> getProductById(int productId) async {
    try {
      final response = await _client.get('/products/$productId', queryParameters: {
        'display': 'full',
      });

      if (response.data['product'] != null) {
        return Product.fromJson(response.data['product']);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  Future<List<Product>> searchProducts(
    String query, {
    int page = 1,
    int limit = AppConfig.defaultPageSize,
  }) async {
    try {
      final response = await _client.get('/search', queryParameters: {
        'query': query,
        'display': 'full',
        'limit': '$limit',
        'page': '$page',
      });

      if (response.data['products'] != null) {
        final productsList = response.data['products'] is List
            ? response.data['products']
            : [response.data['products']];

        return productsList.map((json) => Product.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Category API methods
  Future<List<Category>> getCategories({
    int? parentId,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'display': 'full',
        'limit': '$limit',
        'page': '$page',
        'filter[active]': '[1]',
      };

      if (parentId != null) {
        queryParameters['filter[id_parent]'] = '[$parentId]';
      }

      final response = await _client.get('/categories', queryParameters: queryParameters);

      if (response.data['categories'] != null) {
        final categoriesList = response.data['categories'] is List
            ? response.data['categories']
            : [response.data['categories']];

        return categoriesList.map((json) => Category.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<Category?> getCategoryById(int categoryId) async {
    try {
      final response = await _client.get('/categories/$categoryId', queryParameters: {
        'display': 'full',
      });

      if (response.data['category'] != null) {
        return Category.fromJson(response.data['category']);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  // Customer authentication methods
  Future<AuthResponse> login(String email, String password) async {
    try {
      // Note: PrestaShop doesn't have a built-in login API for mobile apps
      // This typically requires a custom module or OAuth implementation
      // For now, we'll simulate with a customer lookup

      final response = await _client.get('/customers', queryParameters: {
        'filter[email]': '[$email]',
        'display': 'full',
      });

      if (response.data['customers'] != null &&
          (response.data['customers'] as List).isNotEmpty) {
        final customerJson = (response.data['customers'] as List).first;
        final customer = Customer.fromJson(customerJson);

        // In a real implementation, you'd verify the password here
        // For now, we'll assume successful authentication

        return AuthResponse(
          customer: customer,
          sessionToken: _generateSessionToken(customer),
          success: true,
          message: 'Login successful',
        );
      } else {
        return const AuthResponse(
          customer: Customer(firstName: '', lastName: '', email: '', defaultGroupId: 1, langId: 1),
          success: false,
          message: 'Invalid email or password',
        );
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _client.post('/customers', data: {
        'customer': request.toJson(),
      });

      if (response.statusCode == 201 && response.data['customer'] != null) {
        final customer = Customer.fromJson(response.data['customer']);

        return AuthResponse(
          customer: customer,
          sessionToken: _generateSessionToken(customer),
          success: true,
          message: 'Registration successful',
        );
      } else {
        return const AuthResponse(
          customer: Customer(firstName: '', lastName: '', email: '', defaultGroupId: 1, langId: 1),
          success: false,
          message: 'Registration failed',
        );
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<Customer?> getCustomerById(int customerId) async {
    try {
      final response = await _client.get('/customers/$customerId', queryParameters: {
        'display': 'full',
      });

      if (response.data['customer'] != null) {
        return Customer.fromJson(response.data['customer']);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch customer: $e');
    }
  }

  Future<Customer?> updateCustomer(int customerId, Customer customer) async {
    try {
      final response = await _client.put('/customers/$customerId', data: {
        'customer': customer.toJson(),
      });

      if (response.data['customer'] != null) {
        return Customer.fromJson(response.data['customer']);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  // Address methods
  Future<List<Address>> getCustomerAddresses(int customerId) async {
    try {
      final response = await _client.get('/addresses', queryParameters: {
        'filter[id_customer]': '[$customerId]',
        'display': 'full',
      });

      if (response.data['addresses'] != null) {
        final addressesList = response.data['addresses'] is List
            ? response.data['addresses']
            : [response.data['addresses']];

        return addressesList.map((json) => Address.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  Future<Address?> createAddress(Address address) async {
    try {
      final response = await _client.post('/addresses', data: {
        'address': address.toJson(),
      });

      if (response.data['address'] != null) {
        return Address.fromJson(response.data['address']);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to create address: $e');
    }
  }

  Future<Address?> updateAddress(int addressId, Address address) async {
    try {
      final response = await _client.put('/addresses/$addressId', data: {
        'address': address.toJson(),
      });

      if (response.data['address'] != null) {
        return Address.fromJson(response.data['address']);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<bool> deleteAddress(int addressId) async {
    try {
      final response = await _client.delete('/addresses/$addressId');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  // Order methods
  Future<List<Order>> getCustomerOrders(int customerId, {int page = 1}) async {
    try {
      final response = await _client.get('/orders', queryParameters: {
        'filter[id_customer]': '[$customerId]',
        'display': 'full',
        'sort': '[date_add_DESC]',
        'limit': '${AppConfig.defaultPageSize}',
        'page': '$page',
      });

      if (response.data['orders'] != null) {
        final ordersList = response.data['orders'] is List
            ? response.data['orders']
            : [response.data['orders']];

        return ordersList.map((json) => Order.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<Order?> getOrderById(int orderId) async {
    try {
      final response = await _client.get('/orders/$orderId', queryParameters: {
        'display': 'full',
      });

      if (response.data['order'] != null) {
        return Order.fromJson(response.data['order']);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  Future<Order?> createOrder(CreateOrderRequest request) async {
    try {
      final response = await _client.post('/orders', data: {
        'order': request.toJson(),
      });

      if (response.data['order'] != null) {
        return Order.fromJson(response.data['order']);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Cart methods (basic implementation - may need custom module)
  Future<Cart?> getCart(int cartId) async {
    try {
      final response = await _client.get('/carts/$cartId', queryParameters: {
        'display': 'full',
      });

      if (response.data['cart'] != null) {
        return Cart.fromJson(response.data['cart']);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch cart: $e');
    }
  }

  Future<Cart?> createCart(Cart cart) async {
    try {
      final response = await _client.post('/carts', data: {
        'cart': cart.toJson(),
      });

      if (response.data['cart'] != null) {
        return Cart.fromJson(response.data['cart']);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to create cart: $e');
    }
  }

  // Countries and states for address forms
  Future<List<Country>> getCountries() async {
    try {
      final response = await _client.get('/countries', queryParameters: {
        'display': 'full',
        'filter[active]': '[1]',
      });

      if (response.data['countries'] != null) {
        final countriesList = response.data['countries'] is List
            ? response.data['countries']
            : [response.data['countries']];

        return countriesList.map((json) => Country.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch countries: $e');
    }
  }

  Future<List<State>> getStates(int countryId) async {
    try {
      final response = await _client.get('/states', queryParameters: {
        'filter[id_country]': '[$countryId]',
        'filter[active]': '[1]',
        'display': 'full',
      });

      if (response.data['states'] != null) {
        final statesList = response.data['states'] is List
            ? response.data['states']
            : [response.data['states']];

        return statesList.map((json) => State.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch states: $e');
    }
  }

  // Utility methods
  String _generateSessionToken(Customer customer) {
    // Generate a simple session token (in production, use proper JWT)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '${customer.id}_${customer.email}_$timestamp';
    return base64.encode(utf8.encode(data));
  }

  // Health check
  Future<bool> checkConnection() async {
    try {
      final response = await _client.get('/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Singleton instance
final prestashopAPI = PrestaShopAPI();