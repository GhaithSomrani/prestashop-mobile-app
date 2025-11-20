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
      // Step 1: Create a cart in PrestaShop
      final cartData = {
        'cart': {
          'id_address_delivery': shippingAddress.id,
          'id_address_invoice': billingAddress?.id ?? shippingAddress.id,
          'id_currency': '1',
          'id_customer': customer.id,
          'id_guest': '0',
          'id_lang': '1',
          'id_shop_group': '1',
          'id_shop': '1',
          'id_carrier': carrierId,
          'recyclable': '0',
          'gift': '0',
          'gift_message': '',
          'mobile_theme': '0',
          'delivery_option': '',
          'secure_key': '',
          'allow_seperated_package': '0',
          'associations': {
            'cart_rows': {
              'cart_row': items.map((item) {
                return {
                  'id_product': item.product.id,
                  'id_product_attribute': item.variantId ?? '0',
                  'id_address_delivery': shippingAddress.id,
                  'quantity': item.quantity.toString(),
                };
              }).toList(),
            },
          },
        },
      };

      final cartResponse = await _apiService.post(
        ApiConfig.cartsEndpoint,
        cartData,
      );

      String? cartId;
      if (cartResponse['cart'] != null) {
        cartId = cartResponse['cart']['id']?.toString();
      }

      if (cartId == null) {
        throw Exception('Failed to create cart');
      }

      // Step 2: Create the order with the cart ID
      final totalProducts = items.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );

      final totalProductsWithTax = totalProducts;
      final totalShipping = shippingCost;
      final totalPaid = totalProducts + totalShipping;

      // Get current date/time
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final orderData = {
        'order': {
          'id_address_delivery': shippingAddress.id,
          'id_address_invoice': billingAddress?.id ?? shippingAddress.id,
          'id_cart': cartId,
          'id_currency': '1',
          'id_lang': '1',
          'id_customer': customer.id,
          'id_carrier': carrierId,
          'current_state': '1',
          'module': paymentMethod == 'ps_checkpayment' ? 'ps_checkpayment' : 'ps_cashondelivery',
          'invoice_number': '0',
          'invoice_date': '0000-00-00 00:00:00',
          'delivery_number': '0',
          'delivery_date': '0000-00-00 00:00:00',
          'valid': '0',
          'date_add': dateStr,
          'date_upd': dateStr,
          'shipping_number': '',
          'note': '',
          'id_shop_group': '1',
          'id_shop': '1',
          'secure_key': '',
          'payment': paymentMethod == 'ps_checkpayment' ? 'Chèque' : 'Paiement comptant à la livraison',
          'recyclable': '0',
          'gift': '0',
          'gift_message': '',
          'mobile_theme': '0',
          'total_discounts': '0.000000',
          'total_discounts_tax_incl': '0.000000',
          'total_discounts_tax_excl': '0.000000',
          'total_paid': totalPaid.toStringAsFixed(6),
          'total_paid_tax_incl': totalPaid.toStringAsFixed(6),
          'total_paid_tax_excl': totalPaid.toStringAsFixed(6),
          'total_paid_real': '0.000000',
          'total_products': totalProducts.toStringAsFixed(6),
          'total_products_wt': totalProductsWithTax.toStringAsFixed(6),
          'total_shipping': totalShipping.toStringAsFixed(6),
          'total_shipping_tax_incl': totalShipping.toStringAsFixed(6),
          'total_shipping_tax_excl': totalShipping.toStringAsFixed(6),
          'carrier_tax_rate': '0.000000',
          'total_wrapping': '0.000000',
          'total_wrapping_tax_incl': '0.000000',
          'total_wrapping_tax_excl': '0.000000',
          'round_mode': '2',
          'round_type': '1',
          'conversion_rate': '1.000000',
          'reference': '',
          'associations': {
            'order_rows': {
              'order_row': items.map((item) {
                return {
                  'product_id': item.product.id,
                  'product_attribute_id': item.variantId ?? '0',
                  'product_quantity': item.quantity.toString(),
                  'product_name': item.product.name,
                  'product_reference': item.product.reference ?? '',
                  'product_ean13': '',
                  'product_isbn': '',
                  'product_upc': '',
                  'product_price': item.product.finalPrice.toStringAsFixed(6),
                  'unit_price_tax_incl': item.product.finalPrice.toStringAsFixed(6),
                  'unit_price_tax_excl': item.product.finalPrice.toStringAsFixed(6),
                };
              }).toList(),
            },
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
