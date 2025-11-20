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
    double shippingCost = 0.0,
  }) async {
    try {
      // Calculate totals
      final totalProducts = items.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );

      final totalProductsWithTax = totalProducts;
      final totalShipping = shippingCost;
      final totalPaid = totalProducts + totalShipping;

      final orderData = {
        'order': {
          'id_customer': customer.id,
          'id_address_delivery': shippingAddress.id,
          'id_address_invoice': billingAddress?.id ?? shippingAddress.id,
          'id_carrier': carrierId,
          'id_lang': '1',
          'id_currency': '1',
          'id_shop': '1',
          'id_shop_group': '1',
          'payment': paymentMethod,
          'module': paymentMethod == 'ps_checkpayment' ? 'ps_checkpayment' : 'ps_cashondelivery',
          'current_state': '1',
          'total_products': totalProducts.toStringAsFixed(6),
          'total_products_wt': totalProductsWithTax.toStringAsFixed(6),
          'total_shipping': totalShipping.toStringAsFixed(6),
          'total_shipping_tax_incl': totalShipping.toStringAsFixed(6),
          'total_shipping_tax_excl': totalShipping.toStringAsFixed(6),
          'total_paid': totalPaid.toStringAsFixed(6),
          'total_paid_tax_incl': totalPaid.toStringAsFixed(6),
          'total_paid_tax_excl': totalPaid.toStringAsFixed(6),
          'total_paid_real': '0.000000',
          'conversion_rate': '1.000000',
          'associations': {
            'order_rows': items.map((item) {
              return {
                'product_id': item.product.id,
                'product_attribute_id': item.variantId ?? '0',
                'product_quantity': item.quantity.toString(),
                'product_name': item.product.name,
                'product_price': item.product.finalPrice.toStringAsFixed(6),
                'unit_price_tax_incl': item.product.finalPrice.toStringAsFixed(6),
                'unit_price_tax_excl': item.product.finalPrice.toStringAsFixed(6),
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
