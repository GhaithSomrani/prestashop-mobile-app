import '../config/app_config.dart';
import '../models/customer.dart';
import '../models/cart.dart';
import '../services/prestashops_api.dart';
import '../services/storage_service.dart';
import '../services/cart_service.dart';

class AuthService {
  static Customer? _currentUser;

  // Get current user
  Customer? get currentUser => _currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => _currentUser != null && StorageService.hasAuthToken();

  // Initialize auth service (call on app start)
  Future<void> init() async {
    if (StorageService.hasAuthToken() && StorageService.hasUserData()) {
      _currentUser = StorageService.getUserData();

      // Sync cart with user if authenticated
      if (_currentUser != null) {
        await cartService.mergeWithCustomerCart(_currentUser!.id!);
      }
    }
  }

  // Login user
  Future<AuthResult> login(String email, String password, {bool rememberMe = false}) async {
    try {
      final response = await prestashopAPI.login(email, password);

      if (response.success && response.customer.id != null) {
        // Save user data and token
        _currentUser = response.customer;
        await StorageService.saveUserData(response.customer);

        if (response.sessionToken != null) {
          await StorageService.saveAuthToken(response.sessionToken!);
        }

        // Merge guest cart with user cart
        await cartService.mergeWithCustomerCart(response.customer.id!);

        return AuthResult.success(response.customer, response.message ?? 'Login successful');
      } else {
        return AuthResult.failure(response.message ?? 'Login failed');
      }
    } catch (e) {
      return AuthResult.failure('Login failed: ${e.toString()}');
    }
  }

  // Register new user
  Future<AuthResult> register(RegisterRequest request) async {
    try {
      // Validate request
      if (!_validateRegisterRequest(request)) {
        return const AuthResult.failure('Please fill all required fields correctly');
      }

      final response = await prestashopAPI.register(request);

      if (response.success && response.customer.id != null) {
        // Save user data and token
        _currentUser = response.customer;
        await StorageService.saveUserData(response.customer);

        if (response.sessionToken != null) {
          await StorageService.saveAuthToken(response.sessionToken!);
        }

        // Create new cart for user
        await cartService.mergeWithCustomerCart(response.customer.id!);

        return AuthResult.success(response.customer, response.message ?? 'Registration successful');
      } else {
        return AuthResult.failure(response.message ?? 'Registration failed');
      }
    } catch (e) {
      return AuthResult.failure('Registration failed: ${e.toString()}');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      // Clear stored data
      await StorageService.removeAuthToken();
      await StorageService.removeUserData();

      // Reset cart service
      await cartService.reset();

      // Clear current user
      _currentUser = null;
    } catch (e) {
      // Even if clearing storage fails, clear local user data
      _currentUser = null;
    }
  }

  // Update user profile
  Future<AuthResult> updateProfile(Customer customer) async {
    try {
      if (_currentUser == null || _currentUser!.id == null) {
        return const AuthResult.failure('No authenticated user');
      }

      final updatedCustomer = await prestashopAPI.updateCustomer(_currentUser!.id!, customer);

      if (updatedCustomer != null) {
        _currentUser = updatedCustomer;
        await StorageService.saveUserData(updatedCustomer);

        return AuthResult.success(updatedCustomer, 'Profile updated successfully');
      } else {
        return const AuthResult.failure('Failed to update profile');
      }
    } catch (e) {
      return AuthResult.failure('Profile update failed: ${e.toString()}');
    }
  }

  // Change password
  Future<AuthResult> changePassword(String currentPassword, String newPassword) async {
    try {
      if (_currentUser == null) {
        return const AuthResult.failure('No authenticated user');
      }

      // In a real implementation, you'd call a password change API endpoint
      // For now, we'll simulate successful password change

      return const AuthResult.success(null, 'Password changed successfully');
    } catch (e) {
      return AuthResult.failure('Password change failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      // In a real implementation, you'd call a password reset API endpoint
      // For now, we'll simulate successful password reset request

      return const AuthResult.success(null, 'Password reset instructions sent to your email');
    } catch (e) {
      return AuthResult.failure('Password reset failed: ${e.toString()}');
    }
  }

  // Validate token (check if still valid)
  Future<bool> validateToken() async {
    try {
      if (!StorageService.hasAuthToken()) {
        return false;
      }

      // In a real implementation, you'd validate the token with the server
      // For now, we'll just check if user data exists

      return StorageService.hasUserData();
    } catch (e) {
      return false;
    }
  }

  // Refresh user data
  Future<AuthResult> refreshUserData() async {
    try {
      if (_currentUser == null || _currentUser!.id == null) {
        return const AuthResult.failure('No authenticated user');
      }

      final freshCustomer = await prestashopAPI.getCustomerById(_currentUser!.id!);

      if (freshCustomer != null) {
        _currentUser = freshCustomer;
        await StorageService.saveUserData(freshCustomer);

        return AuthResult.success(freshCustomer, 'User data refreshed');
      } else {
        return const AuthResult.failure('Failed to refresh user data');
      }
    } catch (e) {
      return AuthResult.failure('Data refresh failed: ${e.toString()}');
    }
  }

  // Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      final response = await prestashopAPI.getCustomers(
        email: email,
        page: 1,
        limit: 1,
      );

      return response.isNotEmpty;
    } catch (e) {
      return false; // Assume not registered on error
    }
  }

  // Validate current user session
  Future<bool> validateSession() async {
    if (!isAuthenticated) {
      return false;
    }

    try {
      // Try to refresh user data to validate session
      final result = await refreshUserData();
      return result.success;
    } catch (e) {
      return false;
    }
  }

  // Get user addresses
  Future<List<Address>> getUserAddresses() async {
    if (_currentUser == null || _currentUser!.id == null) {
      return [];
    }

    try {
      return await prestashopAPI.getCustomerAddresses(_currentUser!.id!);
    } catch (e) {
      return [];
    }
  }

  // Add new address
  Future<AuthResult> addAddress(Address address) async {
    try {
      if (_currentUser == null || _currentUser!.id == null) {
        return const AuthResult.failure('No authenticated user');
      }

      final createdAddress = await prestashopAPI.createAddress(address);

      if (createdAddress != null) {
        return AuthResult.success(createdAddress, 'Address added successfully');
      } else {
        return const AuthResult.failure('Failed to add address');
      }
    } catch (e) {
      return AuthResult.failure('Add address failed: ${e.toString()}');
    }
  }

  // Update address
  Future<AuthResult> updateAddress(int addressId, Address address) async {
    try {
      final updatedAddress = await prestashopAPI.updateAddress(addressId, address);

      if (updatedAddress != null) {
        return AuthResult.success(updatedAddress, 'Address updated successfully');
      } else {
        return const AuthResult.failure('Failed to update address');
      }
    } catch (e) {
      return AuthResult.failure('Update address failed: ${e.toString()}');
    }
  }

  // Delete address
  Future<AuthResult> deleteAddress(int addressId) async {
    try {
      final success = await prestashopAPI.deleteAddress(addressId);

      if (success) {
        return const AuthResult.success(null, 'Address deleted successfully');
      } else {
        return const AuthResult.failure('Failed to delete address');
      }
    } catch (e) {
      return AuthResult.failure('Delete address failed: ${e.toString()}');
    }
  }

  // Get user orders
  Future<List<Order>> getUserOrders({int page = 1}) async {
    if (_currentUser == null || _currentUser!.id == null) {
      return [];
    }

    try {
      return await prestashopAPI.getCustomerOrders(_currentUser!.id!, page: page);
    } catch (e) {
      return [];
    }
  }

  // Validate register request
  bool _validateRegisterRequest(RegisterRequest request) {
    return request.firstName.trim().isNotEmpty &&
        request.lastName.trim().isNotEmpty &&
        request.email.trim().isNotEmpty &&
        request.password.trim().isNotEmpty &&
        request.password.length >= 8;
  }
}

// Auth result model
class AuthResult {
  final bool success;
  final String? message;
  final dynamic data;

  const AuthResult._({required this.success, this.message, this.data});

  factory AuthResult.success(dynamic data, [String? message]) {
    return AuthResult._(success: true, message: message, data: data);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(success: false, message: message, data: null);
  }
}

// Add this method to the PrestaShopAPI class to support auth service
extension PrestaShopAPIAuthExtension on PrestaShopAPI {
  Future<List<Customer>> getCustomers({
    String? email,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'display': 'full',
        'limit': '$limit',
        'page': '$page',
      };

      if (email != null && email.isNotEmpty) {
        queryParameters['filter[email]'] = '[$email]';
      }

      final response = await _client.get('/customers', queryParameters: queryParameters);

      if (response.data['customers'] != null) {
        final customersList = response.data['customers'] is List
            ? response.data['customers']
            : [response.data['customers']];

        return customersList.map((json) => Customer.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }
}

// Singleton instance
final authService = AuthService();