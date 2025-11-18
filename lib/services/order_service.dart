import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/address.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _apiService;

  OrderService(this._apiService);

  Future<Order> createOrder({
    required Customer customer,
    required Address shippingAddress,
    Address? billingAddress,
    required List<CartItem> items,
    required String carrierId,
    required String paymentMethod,
  }) async {
    try {
      // Calculate totals
      final totalProducts = items.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );

      // Note: Shipping cost should be fetched from carrier
      const totalShipping = 0.0; // This should be calculated based on carrier

      final orderData = {
        'order': {
          'id_customer': customer.id,
          'id_address_delivery': shippingAddress.id,
          'id_address_invoice': billingAddress?.id ?? shippingAddress.id,
          'id_carrier': carrierId,
          'payment': paymentMethod,
          'total_products': totalProducts,
          'total_shipping': totalShipping,
          'total_paid': totalProducts + totalShipping,
          'associations': {
            'order_rows': items.map((item) {
              return {
                'product_id': item.product.id,
                'product_quantity': item.quantity,
                'product_price': item.product.finalPrice,
              };
            }).toList(),
          },
        },
      };

      final response = await _apiService.post(
        ApiConfig.ordersEndpoint,
        orderData,
      );

      if (response['order'] != null) {
        return Order.fromJson(response['order']);
      }

      throw Exception('Failed to create order');
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<Order>> getCustomerOrders(String customerId) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        'filter[id_customer]': customerId,
        'sort': '[id_DESC]',
      };

      final response = await _apiService.get(
        ApiConfig.ordersEndpoint,
        queryParameters: queryParams,
      );

      if (response['orders'] != null) {
        final ordersData = response['orders'];
        if (ordersData is List) {
          return ordersData
              .map((orderJson) => Order.fromJson(orderJson))
              .toList();
        } else if (ordersData is Map) {
          return [Order.fromJson(ordersData as Map<String, dynamic>)];
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.ordersEndpoint}/$orderId',
        queryParameters: {'display': 'full'},
      );

      if (response['order'] != null) {
        return Order.fromJson(response['order']);
      }

      throw Exception('Order not found');
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }
}
