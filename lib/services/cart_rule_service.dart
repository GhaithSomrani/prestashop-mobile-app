import '../models/cart_rule.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class CartRuleService {
  final ApiService _apiService;

  CartRuleService(this._apiService);

  Future<CartRule?> getCartRuleByCode(String code) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        'filter[code]': code,
        'filter[active]': '1',
      };

      final response = await _apiService.get(
        ApiConfig.cartRulesEndpoint,
        queryParameters: queryParams,
      );

      if (response['cart_rules'] != null) {
        final rulesData = response['cart_rules'];
        if (rulesData is List && rulesData.isNotEmpty) {
          return CartRule.fromJson(rulesData.first);
        } else if (rulesData is Map) {
          return CartRule.fromJson(rulesData as Map<String, dynamic>);
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch cart rule: $e');
    }
  }

  Future<List<CartRule>> getCustomerCartRules(String customerId) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        'filter[id_customer]': customerId,
        'filter[active]': '1',
      };

      final response = await _apiService.get(
        ApiConfig.cartRulesEndpoint,
        queryParameters: queryParams,
      );

      if (response['cart_rules'] != null) {
        final rulesData = response['cart_rules'];
        if (rulesData is List) {
          return rulesData
              .map((json) => CartRule.fromJson(json))
              .where((rule) => rule.isValid)
              .toList();
        } else if (rulesData is Map) {
          final rule = CartRule.fromJson(rulesData as Map<String, dynamic>);
          return rule.isValid ? [rule] : [];
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch customer cart rules: $e');
    }
  }

  Future<bool> validateCartRule(String code, double cartTotal, String? customerId) async {
    try {
      final cartRule = await getCartRuleByCode(code);
      if (cartRule == null) return false;

      if (!cartRule.isValid) return false;
      if (cartTotal < cartRule.minimumAmount) return false;

      return true;
    } catch (e) {
      return false;
    }
  }
}
