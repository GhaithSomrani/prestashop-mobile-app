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
  Map<String, String> _orderStates = {};

  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  Map<String, String> get orderStates => _orderStates;

  /// Creates an order following PrestaShop workflow:
  /// 1. Creates cart in PrestaShop
  /// 2. Creates order from cart
  Future<void> createOrder({
    required Customer customer,
    required Address shippingAddress,
    Address? billingAddress,
    required List<CartItem> items,
    required String carrierId,
    required String paymentMethod,
    double shippingCost = 0.0,
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

  /// Updates order status by creating an order history entry
  Future<void> updateOrderStatus({
    required String orderId,
    required String orderStateId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _orderService.updateOrderStatus(
        orderId: orderId,
        orderStateId: orderStateId,
      );

      // Refresh order if it's the current one
      if (_currentOrder?.id == orderId) {
        await fetchOrderById(orderId);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating order status: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Records a payment for an order
  Future<void> addPayment({
    required String orderReference,
    required double amount,
    required String paymentMethod,
    String? transactionId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _orderService.addOrderPayment(
        orderReference: orderReference,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error adding payment: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches all orders for a customer
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

  /// Fetches a single order by ID
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

  /// Fetches order states for displaying status names
  Future<void> fetchOrderStates() async {
    try {
      _orderStates = await _orderService.getOrderStates();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching order states: $e');
      }
    }
  }

  /// Gets the state name for a given state ID
  String getStateName(String? stateId) {
    if (stateId == null) return 'Unknown';
    return _orderStates[stateId] ?? 'State $stateId';
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
