import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService;

  OrderProvider(this._orderService);

  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<void> createOrder({
    required Customer customer,
    required Address shippingAddress,
    Address? billingAddress,
    required List<CartItem> items,
    required String carrierId,
    required String paymentMethod,
    double shippingCost = 0.0,
    double discount = 0.0,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentOrder = await _orderService.createOrder(
        customer: customer,
        shippingAddress: shippingAddress,
        billingAddress: billingAddress,
        items: items,
        carrierId: carrierId,
        paymentMethod: paymentMethod,
        shippingCost: shippingCost,
        discount: discount,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error creating order: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCustomerOrders(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderService.getCustomerOrders(customerId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching orders: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrderById(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentOrder = await _orderService.getOrderById(orderId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching order: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
