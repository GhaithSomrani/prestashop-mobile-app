import '../models/customer.dart';
import '../models/address.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class CustomerService {
  final ApiService _apiService;

  CustomerService(this._apiService);

  Future<Customer> createCustomer(Customer customer, String password) async {
    try {
      final customerData = {
        'customer': {
          ...customer.toJson(),
          'passwd': password,
        },
      };

      final response = await _apiService.post(
        ApiConfig.customersEndpoint,
        customerData,
      );

      if (response['customer'] != null) {
        return Customer.fromJson(response['customer']);
      }

      throw Exception('Failed to create customer');
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  Future<Customer> getCustomerByEmail(String email) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        'filter[email]': email,
      };

      final response = await _apiService.get(
        ApiConfig.customersEndpoint,
        queryParameters: queryParams,
      );

      if (response['customers'] != null) {
        final customersData = response['customers'];
        if (customersData is List && customersData.isNotEmpty) {
          return Customer.fromJson(customersData.first);
        } else if (customersData is Map) {
          return Customer.fromJson(customersData as Map<String, dynamic>);
        }
      }

      throw Exception('Customer not found');
    } catch (e) {
      throw Exception('Failed to fetch customer: $e');
    }
  }

  Future<Customer> updateCustomer(Customer customer) async {
    try {
      if (customer.id == null) {
        throw Exception('Customer ID is required for update');
      }

      final customerData = {
        'customer': customer.toJson(),
      };

      final response = await _apiService.put(
        '${ApiConfig.customersEndpoint}/${customer.id}',
        customerData,
      );

      if (response['customer'] != null) {
        return Customer.fromJson(response['customer']);
      }

      throw Exception('Failed to update customer');
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  Future<Address> createAddress(Address address) async {
    try {
      final addressData = {
        'address': address.toJson(),
      };

      final response = await _apiService.post(
        ApiConfig.addressesEndpoint,
        addressData,
      );

      if (response['address'] != null) {
        return Address.fromJson(response['address']);
      }

      throw Exception('Failed to create address');
    } catch (e) {
      throw Exception('Failed to create address: $e');
    }
  }

  Future<List<Address>> getCustomerAddresses(String customerId) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        'filter[id_customer]': customerId,
      };

      final response = await _apiService.get(
        ApiConfig.addressesEndpoint,
        queryParameters: queryParams,
      );

      if (response['addresses'] != null) {
        final addressesData = response['addresses'];
        if (addressesData is List) {
          return addressesData
              .map((addressJson) => Address.fromJson(addressJson))
              .toList();
        } else if (addressesData is Map) {
          return [Address.fromJson(addressesData as Map<String, dynamic>)];
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  Future<Address> getAddressById(String addressId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.addressesEndpoint}/$addressId',
        queryParameters: {'display': 'full'},
      );

      if (response['address'] != null) {
        return Address.fromJson(response['address']);
      }

      throw Exception('Address not found');
    } catch (e) {
      throw Exception('Failed to fetch address: $e');
    }
  }

  Future<Address> updateAddress(Address address) async {
    try {
      if (address.id == null) {
        throw Exception('Address ID is required for update');
      }

      final addressData = {
        'address': address.toJson(),
      };

      final response = await _apiService.put(
        '${ApiConfig.addressesEndpoint}/${address.id}',
        addressData,
      );

      if (response['address'] != null) {
        return Address.fromJson(response['address']);
      }

      throw Exception('Failed to update address');
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _apiService.delete(
        '${ApiConfig.addressesEndpoint}/$addressId',
      );
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  Future<void> updatePassword(String customerId, String newPassword) async {
    try {
      final passwordData = {
        'customer': {
          'id': customerId,
          'passwd': newPassword,
        },
      };

      await _apiService.put(
        '${ApiConfig.customersEndpoint}/$customerId',
        passwordData,
      );
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    try {
      // Check if customer exists
      final customer = await getCustomerByEmail(email);
      if (customer.id == null) {
        throw Exception('Customer not found');
      }
      // In a real implementation, this would trigger an email
      // For now, we just verify the customer exists
      return true;
    } catch (e) {
      throw Exception('Failed to request password reset: $e');
    }
  }

  Future<Customer> getCustomerById(String customerId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.customersEndpoint}/$customerId',
        queryParameters: {'display': 'full'},
      );

      if (response['customer'] != null) {
        return Customer.fromJson(response['customer']);
      }

      throw Exception('Customer not found');
    } catch (e) {
      throw Exception('Failed to fetch customer: $e');
    }
  }
}
