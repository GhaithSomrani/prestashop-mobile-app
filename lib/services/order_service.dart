import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/address.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _apiService;

  OrderService(this._apiService);

  // Cache for order state names
  final Map<String, String> _orderStateCache = {};

  Future<String> getOrderStateName(String stateId) async {
    if (_orderStateCache.containsKey(stateId)) {
      return _orderStateCache[stateId]!;
    }

    try {
      final response = await _apiService.get(
        'api/order_states/$stateId',
      );

      String stateName = 'Unknown';
      if (response['order_state'] != null) {
        final name = response['order_state']['name'];
        if (name['language'] is List && (name['language'] as List).isNotEmpty) {
          stateName = name['language'][0]['value']?.toString() ?? 'Unknown';
        }
      }

      _orderStateCache[stateId] = stateName;
      return stateName;
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<Order> createOrder({
    required Customer customer,
    required Address shippingAddress,
    Address? billingAddress,
    required List<CartItem> items,
    required String carrierId,
    required String paymentMethod,
    double shippingCost = 0.0,
    double discount = 0.0,
  }) async {
    try {
      // Step 1: Create a cart in PrestaShop
      final cartData = {
        'cart': {
          'id_address_delivery': shippingAddress.id,
          'id_address_invoice': billingAddress?.id ?? shippingAddress.id,
          'id_currency': '1',
          'associations': {
            'cart_rows': {
              'cart_row': items.map((item) {
                return {
                  'id_product': item.product.id,
                  'id_product_attribute': item.variantId ?? '0',
                  'quantity': item.quantity.toString(),
                  'id_address_delivery': shippingAddress.id,
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
      final totalDiscount = discount;
      final totalPaid = totalProducts + totalShipping - totalDiscount;

      // Get current date/time for order timestamps
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

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
          'secure_key': customer.secureKey ?? '',
          'payment': paymentMethod == 'ps_checkpayment'
              ? 'Chèque'
              : 'Paiement comptant à la livraison',
          'module': paymentMethod == 'ps_checkpayment'
              ? 'ps_checkpayment'
              : 'ps_cashondelivery',
          'current_state': '1',
          'recyclable': '0',
          'gift': '0',
          'gift_message': '',
          'mobile_theme': '0',
          'shipping_number': '',
          'note': '',
          'invoice_number': '0',
          'invoice_date': '0000-00-00 00:00:00',
          'delivery_number': '0',
          'delivery_date': '0000-00-00 00:00:00',
          'valid': '0',
          'date_add': dateStr,
          'date_upd': dateStr,
          'total_discounts': totalDiscount.toStringAsFixed(6),
          'total_discounts_tax_incl': totalDiscount.toStringAsFixed(6),
          'total_discounts_tax_excl': totalDiscount.toStringAsFixed(6),
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
          'total_paid': totalPaid.toStringAsFixed(6),
          'total_paid_tax_incl': totalPaid.toStringAsFixed(6),
          'total_paid_tax_excl': totalPaid.toStringAsFixed(6),
          'total_paid_real': '0.000000',
          'conversion_rate': '1.000000',
          'reference': '',
          'reference': '',
          'associations': {
            'order_rows': items.map((item) {
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
                'unit_price_tax_incl':
                    item.product.finalPrice.toStringAsFixed(6),
                'unit_price_tax_excl':
                    item.product.finalPrice.toStringAsFixed(6),
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

  Future<Address> getAddressById(String addressId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.addressesEndpoint}/$addressId',
      );

      if (response['address'] != null) {
        return Address.fromJson(response['address']);
      }

      throw Exception('Address not found');
    } catch (e) {
      throw Exception('Failed to fetch address: $e');
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

      List<Order> orders = [];

      if (response['orders'] != null) {
        var ordersData = response['orders'];
        List<Map<String, dynamic>> ordersList = [];

        // Handle different response structures
        if (ordersData is List) {
          ordersList = ordersData
              .where((item) => item is Map)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else if (ordersData is Map) {
          // Single order or nested structure
          if (ordersData.containsKey('order')) {
            var orderData = ordersData['order'];
            if (orderData is List) {
              ordersList = orderData
                  .where((item) => item is Map)
                  .map((item) => item as Map<String, dynamic>)
                  .toList();
            } else if (orderData is Map) {
              ordersList = [orderData as Map<String, dynamic>];
            }
          } else {
            ordersList = [ordersData as Map<String, dynamic>];
          }
        }

        for (var orderJson in ordersList) {
          Order order = Order.fromJson(orderJson);

          // Fetch state name
          if (order.orderState != null) {
            final stateName = await getOrderStateName(order.orderState!);
            order = order.copyWith(orderStateName: stateName);
          }

          // Fetch shipping address
          final addressId = orderJson['id_address_delivery']?.toString();
          if (addressId != null && addressId.isNotEmpty) {
            try {
              final address = await getAddressById(addressId);
              order = order.copyWith(shippingAddress: address);
            } catch (e) {
              // Keep default address if fetch fails
            }
          }

          orders.add(order);
        }
      }

      return orders;
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
