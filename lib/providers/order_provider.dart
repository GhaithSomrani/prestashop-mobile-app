import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/address.dart';
import '../services/prestashops_api.dart';

enum OrderStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  error,
}

class OrderProvider extends ChangeNotifier {
  final PrestaShopAPI _api = prestashopAPI;

  OrderStatus _status = OrderStatus.initial;
  List<Order> _orders = [];
  Order? _selectedOrder;
  String? _errorMessage;
  List<OrderStatus> _availableOrderStatuses = [];

  // Getters
  OrderStatus get status => _status;
  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  String? get errorMessage => _errorMessage;
  List<OrderStatus> get availableOrderStatuses => _availableOrderStatuses;
  bool get isLoading => _status == OrderStatus.loading;
  bool get isCreating => _status == OrderStatus.creating;
  bool get isUpdating => _status == OrderStatus.updating;

  // Load user orders
  Future<void> loadOrders(int customerId, {int page = 1, bool refresh = false}) async {
    if (refresh) {
      _orders.clear();
      _setStatus(OrderStatus.loading);
    }

    _clearError();

    try {
      final newOrders = await _api.getCustomerOrders(customerId, page: page);

      if (refresh) {
        _orders = newOrders;
      } else {
        _orders.addAll(newOrders);
      }

      _setStatus(OrderStatus.loaded);
    } catch (e) {
      _setError('Failed to load orders: ${e.toString()}');
      _setStatus(OrderStatus.error);
    }
  }

  // Get order by ID
  Future<Order?> getOrderById(int orderId) async {
    _setStatus(OrderStatus.loading);
    _clearError();

    try {
      final order = await _api.getOrderById(orderId);
      _selectedOrder = order;

      if (order != null) {
        // Load additional order data if needed
        await _loadOrderDetails(order);
      }

      _setStatus(OrderStatus.loaded);
      return order;
    } catch (e) {
      _setError('Failed to get order: ${e.toString()}');
      _setStatus(OrderStatus.error);
      return null;
    }
  }

  // Create new order
  Future<Order?> createOrder(CreateOrderRequest request) async {
    _setStatus(OrderStatus.creating);
    _clearError();

    try {
      final order = await _api.createOrder(request);

      if (order != null) {
        _orders.insert(0, order); // Add to beginning of list
        _selectedOrder = order;
        notifyListeners();
      }

      _setStatus(OrderStatus.loaded);
      return order;
    } catch (e) {
      _setError('Failed to create order: ${e.toString()}');
      _setStatus(OrderStatus.error);
      return null;
    }
  }

  // Update order status (admin function)
  Future<bool> updateOrderStatus(int orderId, int statusId) async {
    _setStatus(OrderStatus.updating);
    _clearError();

    try {
      // Note: This would require a custom API endpoint in PrestaShop
      // For now, we'll simulate the update

      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        // Update local order status
        // In a real implementation, this would come from the API response
        notifyListeners();
      }

      _setStatus(OrderStatus.loaded);
      return true;
    } catch (e) {
      _setError('Failed to update order status: ${e.toString()}');
      _setStatus(OrderStatus.error);
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(int orderId) async {
    _setStatus(OrderStatus.updating);
    _clearError();

    try {
      // Note: This would require a custom API endpoint in PrestaShop
      // For now, we'll simulate the cancellation

      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        // Update local order status to cancelled
        notifyListeners();
      }

      _setStatus(OrderStatus.loaded);
      return true;
    } catch (e) {
      _setError('Failed to cancel order: ${e.toString()}');
      _setStatus(OrderStatus.error);
      return false;
    }
  }

  // Get orders by status
  List<Order> getOrdersByStatus(String status) {
    return _orders.where((order) =>
      order.status?.name.toLowerCase() == status.toLowerCase()
    ).toList();
  }

  // Get recent orders (last 30 days)
  List<Order> getRecentOrders() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _orders.where((order) =>
      order.orderDate.isAfter(thirtyDaysAgo)
    ).toList();
  }

  // Get pending orders
  List<Order> getPendingOrders() {
    return getOrdersByStatus('pending');
  }

  // Get processing orders
  List<Order> getProcessingOrders() {
    return getOrdersByStatus('processing');
  }

  // Get shipped orders
  List<Order> getShippedOrders() {
    return getOrdersByStatus('shipped');
  }

  // Get delivered orders
  List<Order> getDeliveredOrders() {
    return getOrdersByStatus('delivered');
  }

  // Get cancelled orders
  List<Order> getCancelledOrders() {
    return getOrdersByStatus('cancelled');
  }

  // Set selected order
  void setSelectedOrder(Order? order) {
    _selectedOrder = order;
    notifyListeners();
  }

  // Clear selected order
  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  // Refresh orders
  Future<void> refreshOrders(int customerId) async {
    await loadOrders(customerId, refresh: true);
  }

  // Load order statuses (available order states)
  Future<void> loadOrderStatuses() async {
    try {
      // Note: This would typically come from an API endpoint
      // For now, we'll create default statuses
      _availableOrderStatuses = [
        const OrderStatus(id: 1, name: 'Pending', color: '#FFA500', logable: true),
        const OrderStatus(id: 2, name: 'Processing', color: '#2196F3', logable: true),
        const OrderStatus(id: 3, name: 'Shipped', color: '#9C27B0', logable: true, shipped: true),
        const OrderStatus(id: 4, name: 'Delivered', color: '#4CAF50', logable: true, delivery: true),
        const OrderStatus(id: 5, name: 'Cancelled', color: '#F44336', logable: true, deleted: true),
        const OrderStatus(id: 6, name: 'Refunded', color: '#9E9E9E', logable: true),
      ];
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load order statuses: $e');
    }
  }

  // Get order status by ID
  OrderStatus? getOrderStatusById(int statusId) {
    try {
      return _availableOrderStatuses.firstWhere((status) => status.id == statusId);
    } catch (e) {
      return null;
    }
  }

  // Get order statistics
  OrderStatistics getOrderStatistics() {
    return OrderStatistics(
      totalOrders: _orders.length,
      pendingOrders: getPendingOrders().length,
      processingOrders: getProcessingOrders().length,
      shippedOrders: getShippedOrders().length,
      deliveredOrders: getDeliveredOrders().length,
      cancelledOrders: getCancelledOrders().length,
      totalSpent: _calculateTotalSpent(),
      averageOrderValue: _calculateAverageOrderValue(),
    );
  }

  // Calculate total spent
  double _calculateTotalSpent() {
    return _orders.fold(0.0, (total, order) => total + order.totalPaid);
  }

  // Calculate average order value
  double _calculateAverageOrderValue() {
    if (_orders.isEmpty) return 0.0;
    return _calculateTotalSpent() / _orders.length;
  }

  // Load additional order details
  Future<void> _loadOrderDetails(Order order) async {
    try {
      // Load customer addresses if not already loaded
      if (order.deliveryAddress == null || order.invoiceAddress == null) {
        // In a real implementation, you'd load addresses from the API
        // For now, we'll use placeholder addresses
      }

      // Load order status if not already loaded
      if (order.status == null && order.currentStatusId > 0) {
        order.status = getOrderStatusById(order.currentStatusId);
      }
    } catch (e) {
      debugPrint('Failed to load order details: $e');
    }
  }

  // Get tracking information
  Future<String?> getTrackingInformation(int orderId) async {
    try {
      final order = await _api.getOrderById(orderId);
      return order?.carrierName;
    } catch (e) {
      debugPrint('Failed to get tracking information: $e');
      return null;
    }
  }

  // Request order cancellation
  Future<bool> requestOrderCancellation(int orderId, String reason) async {
    _setStatus(OrderStatus.updating);
    _clearError();

    try {
      // Note: This would require a custom API endpoint
      // For now, we'll simulate the cancellation request

      _setStatus(OrderStatus.loaded);
      return true;
    } catch (e) {
      _setError('Failed to request cancellation: ${e.toString()}');
      _setStatus(OrderStatus.error);
      return false;
    }
  }

  // Reorder items from an order
  Future<List<OrderItem>> getReorderItems(int orderId) async {
    try {
      final order = await _api.getOrderById(orderId);
      return order?.items ?? [];
    } catch (e) {
      debugPrint('Failed to get reorder items: $e');
      return [];
    }
  }

  // Clear error
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Set loading state manually
  void setLoading(bool loading) {
    if (loading) {
      _setStatus(OrderStatus.loading);
    } else {
      _setStatus(OrderStatus.loaded);
    }
  }

  // Private helper methods
  void _setStatus(OrderStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Reset provider
  void reset() {
    _status = OrderStatus.initial;
    _orders.clear();
    _selectedOrder = null;
    _errorMessage = null;
    _availableOrderStatuses.clear();
    notifyListeners();
  }
}

// Order statistics model
class OrderStatistics {
  final int totalOrders;
  final int pendingOrders;
  final int processingOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalSpent;
  final double averageOrderValue;

  const OrderStatistics({
    required this.totalOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalSpent,
    required this.averageOrderValue,
  });

  @override
  String toString() {
    return 'OrderStatistics(totalOrders: $totalOrders, totalSpent: $totalSpent, averageOrderValue: $averageOrderValue)';
  }
}