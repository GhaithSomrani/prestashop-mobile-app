import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  final CustomerService _customerService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthProvider(this._customerService);

  Customer? _currentCustomer;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  Customer? get currentCustomer => _currentCustomer;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  static const String _customerKey = 'customer_data';

  Future<void> checkAuthentication() async {
    try {
      final customerData = await _secureStorage.read(key: _customerKey);
      if (customerData != null) {
        _currentCustomer = Customer.fromJson(jsonDecode(customerData));
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking authentication: $e');
      }
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final customer = Customer(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );

      _currentCustomer = await _customerService.createCustomer(
        customer,
        password,
      );
      _isAuthenticated = true;

      await _secureStorage.write(
        key: _customerKey,
        value: jsonEncode(_currentCustomer!.toJson()),
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error during registration: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Note: PrestaShop API doesn't have built-in authentication endpoint
      // This is a simplified version - you may need to implement custom authentication
      _currentCustomer = await _customerService.getCustomerByEmail(email);
      _isAuthenticated = true;

      await _secureStorage.write(
        key: _customerKey,
        value: jsonEncode(_currentCustomer!.toJson()),
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error during login: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentCustomer = null;
    _isAuthenticated = false;
    await _secureStorage.delete(key: _customerKey);
    notifyListeners();
  }

  Future<void> updateProfile(Customer customer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentCustomer = await _customerService.updateCustomer(customer);

      await _secureStorage.write(
        key: _customerKey,
        value: jsonEncode(_currentCustomer!.toJson()),
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
