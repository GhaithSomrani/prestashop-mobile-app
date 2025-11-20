import '../models/cart_item.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class CartService {
  final ApiService _apiService;

  CartService(this._apiService);

  /// Creates a cart in PrestaShop with products
  /// Returns the cart ID for order creation
  Future<Map<String, dynamic>> createCart({
    required String customerId,
    required String addressDeliveryId,
    required String addressInvoiceId,
    required String carrierId,
    required List<CartItem> items,
    String currencyId = '1',
    String langId = '1',
    String shopGroupId = '1',
    String shopId = '1',
  }) async {
    try {
      // Build cart rows from items
      final cartRows = items.map((item) {
        return {
          'id_product': item.product.id,
          'id_product_attribute': item.variantId ?? '0',
          'id_address_delivery': addressDeliveryId,
          'quantity': item.quantity.toString(),
        };
      }).toList();

      final cartData = {
        'cart': {
          'id_address_delivery': addressDeliveryId,
          'id_address_invoice': addressInvoiceId,
          'id_currency': currencyId,
          'id_customer': customerId,
          'id_guest': '0',
          'id_lang': langId,
          'id_shop_group': shopGroupId,
          'id_shop': shopId,
          'id_carrier': carrierId,
          'recyclable': '0',
          'gift': '0',
          'gift_message': '',
          'mobile_theme': '0',
          'delivery_option': '',
          'secure_key': '',
          'allow_seperated_package': '0',
          'associations': {
            'cart_rows': cartRows,
          },
        },
      };

      final response = await _apiService.post(
        ApiConfig.cartsEndpoint,
        cartData,
      );

      if (response['cart'] != null) {
        return response['cart'];
      }

      throw Exception('Failed to create cart');
    } catch (e) {
      throw Exception('Failed to create cart: $e');
    }
  }

  /// Updates an existing cart with new items
  Future<Map<String, dynamic>> updateCart({
    required String cartId,
    required String customerId,
    required String addressDeliveryId,
    required String addressInvoiceId,
    required String carrierId,
    required List<CartItem> items,
    String currencyId = '1',
    String langId = '1',
    String shopGroupId = '1',
    String shopId = '1',
  }) async {
    try {
      final cartRows = items.map((item) {
        return {
          'id_product': item.product.id,
          'id_product_attribute': item.variantId ?? '0',
          'id_address_delivery': addressDeliveryId,
          'quantity': item.quantity.toString(),
        };
      }).toList();

      final cartData = {
        'cart': {
          'id': cartId,
          'id_address_delivery': addressDeliveryId,
          'id_address_invoice': addressInvoiceId,
          'id_currency': currencyId,
          'id_customer': customerId,
          'id_guest': '0',
          'id_lang': langId,
          'id_shop_group': shopGroupId,
          'id_shop': shopId,
          'id_carrier': carrierId,
          'recyclable': '0',
          'gift': '0',
          'gift_message': '',
          'mobile_theme': '0',
          'delivery_option': '',
          'secure_key': '',
          'allow_seperated_package': '0',
          'associations': {
            'cart_rows': cartRows,
          },
        },
      };

      final response = await _apiService.put(
        '${ApiConfig.cartsEndpoint}/$cartId',
        cartData,
      );

      if (response['cart'] != null) {
        return response['cart'];
      }

      throw Exception('Failed to update cart');
    } catch (e) {
      throw Exception('Failed to update cart: $e');
    }
  }

  /// Gets a cart by ID
  Future<Map<String, dynamic>> getCart(String cartId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.cartsEndpoint}/$cartId',
        queryParameters: {'display': 'full'},
      );

      if (response['cart'] != null) {
        return response['cart'];
      }

      throw Exception('Cart not found');
    } catch (e) {
      throw Exception('Failed to fetch cart: $e');
    }
  }

  /// Deletes a cart
  Future<void> deleteCart(String cartId) async {
    try {
      await _apiService.delete('${ApiConfig.cartsEndpoint}/$cartId');
    } catch (e) {
      throw Exception('Failed to delete cart: $e');
    }
  }
}
