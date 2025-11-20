import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/address.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'cart_service.dart';

class OrderService {
  final ApiService _apiService;
  final CartService _cartService;

  OrderService(this._apiService, this._cartService);

  /// Creates an order following PrestaShop webservice workflow:
  /// 1. Create cart with products
  /// 2. Create order from cart
  Future<Order> createOrder({
    required Customer customer,
    required Address shippingAddress,
    Address? billingAddress,
    required List<CartItem> items,
    required String carrierId,
    required String paymentMethod,
    String currencyId = '1',
    String langId = '1',
    String shopGroupId = '1',
    String shopId = '1',
    double shippingCost = 0.0,
  }) async {
    try {
      if (customer.id == null) {
        throw Exception('Customer ID is required');
      }
      if (shippingAddress.id == null) {
        throw Exception('Shipping address ID is required');
      }

      final billingAddressId = billingAddress?.id ?? shippingAddress.id;

      // Step 1: Create cart in PrestaShop
      final cartResponse = await _cartService.createCart(
        customerId: customer.id!,
        addressDeliveryId: shippingAddress.id!,
        addressInvoiceId: billingAddressId!,
        carrierId: carrierId,
        items: items,
        currencyId: currencyId,
        langId: langId,
        shopGroupId: shopGroupId,
        shopId: shopId,
      );

      final cartId = cartResponse['id']?.toString();
      if (cartId == null) {
        throw Exception('Failed to get cart ID');
      }

      // Step 2: Calculate totals
      final totalProducts = items.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );
      final totalPaid = totalProducts + shippingCost;

      // Calculate tax (assuming 20% VAT as example)
      const taxRate = 0.20;
      final totalProductsTaxExcl = totalProducts / (1 + taxRate);
      final totalShippingTaxExcl = shippingCost / (1 + taxRate);
      final totalPaidTaxExcl = totalPaid / (1 + taxRate);

      // Build order rows with complete product details
      final orderRows = items.map((item) {
        final unitPrice = item.product.finalPrice;
        final unitPriceTaxExcl = unitPrice / (1 + taxRate);

        return {
          'product_id': item.product.id,
          'product_attribute_id': item.variantId ?? '0',
          'product_quantity': item.quantity.toString(),
          'product_name': item.product.name,
          'product_reference': item.product.reference ?? '',
          'product_ean13': item.product.ean13 ?? '',
          'product_isbn': '',
          'product_upc': '',
          'product_price': unitPrice.toStringAsFixed(6),
          'unit_price_tax_incl': unitPrice.toStringAsFixed(6),
          'unit_price_tax_excl': unitPriceTaxExcl.toStringAsFixed(6),
        };
      }).toList();

      // Get current datetime
      final now = DateTime.now();
      final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      // Step 3: Create order with complete PrestaShop fields
      final orderData = {
        'order': {
          'id_address_delivery': shippingAddress.id,
          'id_address_invoice': billingAddressId,
          'id_cart': cartId,
          'id_currency': currencyId,
          'id_lang': langId,
          'id_customer': customer.id,
          'id_carrier': carrierId,
          'current_state': '1', // 1 = Awaiting payment
          'module': _getPaymentModule(paymentMethod),
          'invoice_number': '0',
          'invoice_date': '0000-00-00 00:00:00',
          'delivery_number': '0',
          'delivery_date': '0000-00-00 00:00:00',
          'valid': '0',
          'date_add': dateString,
          'date_upd': dateString,
          'shipping_number': '',
          'note': '',
          'id_shop_group': shopGroupId,
          'id_shop': shopId,
          'secure_key': customer.secureKey ?? '',
          'payment': paymentMethod,
          'recyclable': '0',
          'gift': '0',
          'gift_message': '',
          'mobile_theme': '0',
          'total_discounts': '0.000000',
          'total_discounts_tax_incl': '0.000000',
          'total_discounts_tax_excl': '0.000000',
          'total_paid': totalPaid.toStringAsFixed(6),
          'total_paid_tax_incl': totalPaid.toStringAsFixed(6),
          'total_paid_tax_excl': totalPaidTaxExcl.toStringAsFixed(6),
          'total_paid_real': '0.000000',
          'total_products': totalProducts.toStringAsFixed(6),
          'total_products_wt': totalProducts.toStringAsFixed(6),
          'total_shipping': shippingCost.toStringAsFixed(6),
          'total_shipping_tax_incl': shippingCost.toStringAsFixed(6),
          'total_shipping_tax_excl': totalShippingTaxExcl.toStringAsFixed(6),
          'carrier_tax_rate': (taxRate * 100).toStringAsFixed(3),
          'total_wrapping': '0.000000',
          'total_wrapping_tax_incl': '0.000000',
          'total_wrapping_tax_excl': '0.000000',
          'round_mode': '2',
          'round_type': '1',
          'conversion_rate': '1.000000',
          'reference': '',
          'associations': {
            'order_rows': orderRows,
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

  /// Returns the payment module name for PrestaShop
  String _getPaymentModule(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'bank wire':
      case 'bank transfer':
        return 'ps_wirepayment';
      case 'check':
        return 'ps_checkpayment';
      case 'cash on delivery':
      case 'cod':
        return 'ps_cashondelivery';
      case 'credit card':
      case 'card':
        return 'ps_creditcard';
      default:
        return 'ps_wirepayment';
    }
  }

  /// Updates order status by creating an order history entry
  Future<void> updateOrderStatus({
    required String orderId,
    required String orderStateId,
  }) async {
    try {
      final now = DateTime.now();
      final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final historyData = {
        'order_history': {
          'id_order': orderId,
          'id_employee': '0',
          'id_order_state': orderStateId,
          'date_add': dateString,
        },
      };

      await _apiService.post(
        ApiConfig.orderHistoriesEndpoint,
        historyData,
      );
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Records a payment for an order
  Future<void> addOrderPayment({
    required String orderReference,
    required double amount,
    required String paymentMethod,
    String currencyId = '1',
    String? transactionId,
  }) async {
    try {
      final now = DateTime.now();
      final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final paymentData = {
        'order_payment': {
          'order_reference': orderReference,
          'id_currency': currencyId,
          'amount': amount.toStringAsFixed(6),
          'payment_method': paymentMethod,
          'conversion_rate': '1.000000',
          'transaction_id': transactionId ?? '',
          'card_number': '',
          'card_brand': '',
          'card_expiration': '',
          'card_holder': '',
          'date_add': dateString,
        },
      };

      await _apiService.post(
        ApiConfig.orderPaymentsEndpoint,
        paymentData,
      );
    } catch (e) {
      throw Exception('Failed to add order payment: $e');
    }
  }

  /// Fetches all orders for a customer
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

  /// Fetches a single order by ID
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

  /// Fetches order states for displaying order status
  Future<Map<String, String>> getOrderStates() async {
    try {
      final response = await _apiService.get(
        ApiConfig.orderStatesEndpoint,
        queryParameters: {'display': 'full'},
      );

      final states = <String, String>{};

      if (response['order_states'] != null) {
        final statesData = response['order_states'];
        if (statesData is List) {
          for (final state in statesData) {
            final id = state['id']?.toString();
            final name = state['name']?.toString() ?? '';
            if (id != null) {
              states[id] = name;
            }
          }
        }
      }

      return states;
    } catch (e) {
      throw Exception('Failed to fetch order states: $e');
    }
  }
}
