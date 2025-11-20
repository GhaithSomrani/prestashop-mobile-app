import 'package:flutter/foundation.dart';
import '../models/address.dart';
import '../services/customer_service.dart';

class AddressProvider with ChangeNotifier {
  final CustomerService _customerService;

  AddressProvider(this._customerService);

  List<Address> _addresses = [];
  Address? _selectedAddress;
  Address? _selectedBillingAddress;
  bool _isLoading = false;
  String? _error;

  List<Address> get addresses => _addresses;
  Address? get selectedAddress => _selectedAddress;
  Address? get selectedBillingAddress => _selectedBillingAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasAddresses => _addresses.isNotEmpty;

  Future<void> fetchAddresses(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _addresses = await _customerService.getCustomerAddresses(customerId);

      // Set default selected address if none selected
      if (_selectedAddress == null && _addresses.isNotEmpty) {
        _selectedAddress = _addresses.first;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching addresses: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Address> createAddress(Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newAddress = await _customerService.createAddress(address);
      _addresses.add(newAddress);

      // Set as selected if first address
      if (_addresses.length == 1) {
        _selectedAddress = newAddress;
      }

      _error = null;
      notifyListeners();
      return newAddress;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error creating address: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Address> updateAddress(Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedAddress = await _customerService.updateAddress(address);

      // Update in list
      final index = _addresses.indexWhere((a) => a.id == address.id);
      if (index >= 0) {
        _addresses[index] = updatedAddress;
      }

      // Update selected if same
      if (_selectedAddress?.id == address.id) {
        _selectedAddress = updatedAddress;
      }
      if (_selectedBillingAddress?.id == address.id) {
        _selectedBillingAddress = updatedAddress;
      }

      _error = null;
      notifyListeners();
      return updatedAddress;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating address: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String addressId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _customerService.deleteAddress(addressId);
      _addresses.removeWhere((a) => a.id == addressId);

      // Clear selected if deleted
      if (_selectedAddress?.id == addressId) {
        _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
      }
      if (_selectedBillingAddress?.id == addressId) {
        _selectedBillingAddress = null;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error deleting address: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Address> getAddressById(String addressId) async {
    try {
      // Check local first
      final local = _addresses.firstWhere(
        (a) => a.id == addressId,
        orElse: () => throw Exception('Not found locally'),
      );
      return local;
    } catch (_) {
      // Fetch from API
      return await _customerService.getAddressById(addressId);
    }
  }

  void selectAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void selectBillingAddress(Address? address) {
    _selectedBillingAddress = address;
    notifyListeners();
  }

  void clearSelection() {
    _selectedAddress = null;
    _selectedBillingAddress = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _addresses = [];
    _selectedAddress = null;
    _selectedBillingAddress = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
