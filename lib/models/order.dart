import 'cart_item.dart';
import 'address.dart';
import 'customer.dart';

class Order {
  final String? id;
  final String? reference;
  final Customer customer;
  final Address shippingAddress;
  final Address? billingAddress;
  final List<CartItem> items;
  final double totalProducts;
  final double totalShipping;
  final double totalDiscount;
  final double totalPaid;
  final String? carrierId;
  final String carrierName;
  final String paymentMethod;
  final String? orderState;
  final DateTime? dateAdd;
  final DateTime? dateUpd;

  Order({
    this.id,
    this.reference,
    required this.customer,
    required this.shippingAddress,
    this.billingAddress,
    required this.items,
    required this.totalProducts,
    required this.totalShipping,
    this.totalDiscount = 0,
    required this.totalPaid,
    this.carrierId,
    required this.carrierName,
    required this.paymentMethod,
    this.orderState,
    this.dateAdd,
    this.dateUpd,
  });

  Address get effectiveBillingAddress => billingAddress ?? shippingAddress;

  factory Order.fromJson(Map<String, dynamic> json) {
    final order = json['order'] ?? json;

    return Order(
      id: order['id']?.toString(),
      reference: order['reference']?.toString(),
      customer: Customer.fromJson(order['customer'] ?? {}),
      shippingAddress: Address.fromJson(order['shipping_address'] ?? {}),
      billingAddress: order['billing_address'] != null
          ? Address.fromJson(order['billing_address'])
          : null,
      items: order['items'] != null
          ? (order['items'] as List).map((i) => CartItem.fromJson(i)).toList()
          : [],
      totalProducts: order['total_products'] is num
          ? (order['total_products'] as num).toDouble()
          : double.tryParse(order['total_products']?.toString() ?? '0') ?? 0.0,
      totalShipping: order['total_shipping'] is num
          ? (order['total_shipping'] as num).toDouble()
          : double.tryParse(order['total_shipping']?.toString() ?? '0') ?? 0.0,
      totalDiscount: order['total_discounts'] is num
          ? (order['total_discounts'] as num).toDouble()
          : double.tryParse(order['total_discounts']?.toString() ?? '0') ?? 0.0,
      totalPaid: order['total_paid'] is num
          ? (order['total_paid'] as num).toDouble()
          : double.tryParse(order['total_paid']?.toString() ?? '0') ?? 0.0,
      carrierId: order['id_carrier']?.toString(),
      carrierName: order['carrier_name']?.toString() ?? '',
      paymentMethod: order['payment']?.toString() ?? '',
      orderState: order['current_state']?.toString(),
      dateAdd: order['date_add'] != null
          ? DateTime.tryParse(order['date_add'].toString())
          : null,
      dateUpd: order['date_upd'] != null
          ? DateTime.tryParse(order['date_upd'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (reference != null) 'reference': reference,
      'customer': customer.toJson(),
      'shipping_address': shippingAddress.toJson(),
      if (billingAddress != null) 'billing_address': billingAddress!.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
      'total_products': totalProducts,
      'total_shipping': totalShipping,
      'total_discounts': totalDiscount,
      'total_paid': totalPaid,
      if (carrierId != null) 'id_carrier': carrierId,
      'carrier_name': carrierName,
      'payment': paymentMethod,
      if (orderState != null) 'current_state': orderState,
      if (dateAdd != null) 'date_add': dateAdd!.toIso8601String(),
      if (dateUpd != null) 'date_upd': dateUpd!.toIso8601String(),
    };
  }
}
