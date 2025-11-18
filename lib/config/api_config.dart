import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.env['PRESTASHOP_BASE_URL'] ?? '';
  static String get apiKey => dotenv.env['PRESTASHOP_API_KEY'] ?? '';
  static bool get debugMode => dotenv.env['DEBUG_MODE'] == 'true';

  // API Endpoints
  static const String productsEndpoint = 'api/products';
  static const String categoriesEndpoint = 'api/categories';
  static const String ordersEndpoint = 'api/orders';
  static const String customersEndpoint = 'api/customers';
  static const String cartsEndpoint = 'api/carts';
  static const String addressesEndpoint = 'api/addresses';
  static const String carriersEndpoint = 'api/carriers';
  static const String orderCarriersEndpoint = 'api/order_carriers';
  static const String orderStatesEndpoint = 'api/order_states';
  static const String imagesEndpoint = 'api/images';
  static const String stockAvailablesEndpoint = 'api/stock_availables';
  static const String combinationsEndpoint = 'api/combinations';
  static const String productOptionsEndpoint = 'api/product_options';
  static const String productOptionValuesEndpoint = 'api/product_option_values';
  static const String featuresEndpoint = 'api/features';
  static const String featureValuesEndpoint = 'api/feature_values';
  static const String manufacturersEndpoint = 'api/manufacturers';
  static const String specificPricesEndpoint = 'api/specific_prices';
  static const String searchEndpoint = 'api/search';

  // Request parameters
  static const String outputFormat = 'JSON'; // or 'XML'
  static const String language = 'en';
  static const int defaultLimit = 20;
}
