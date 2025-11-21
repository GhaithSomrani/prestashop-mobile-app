import 'address.dart';
import 'customer.dart';
import 'dart:io';

class OrderItem {
  final String productId;
  final String? productAttributeId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.productId,
    this.productAttributeId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final qty = int.tryParse(json['product_quantity']?.toString() ?? '1') ?? 1;
    final price = double.tryParse(json['unit_price_tax_incl']?.toString() ??
            json['product_price']?.toString() ??
            '0') ??
        0.0;

    return OrderItem(
      productId: json['product_id']?.toString() ?? '',
      productAttributeId: json['product_attribute_id']?.toString(),
      productName: json['product_name']?.toString() ?? 'Unknown Product',
      quantity: qty,
      unitPrice: price,
      totalPrice: price * qty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_attribute_id': productAttributeId ?? '0',
      'product_name': productName,
      'product_quantity': quantity.toString(),
      'product_price': unitPrice.toStringAsFixed(6),
      'unit_price_tax_incl': unitPrice.toStringAsFixed(6),
    };
  }
}

class Order {
  final String? id;
  final String? reference;
  final Customer customer;
  final Address shippingAddress;
  final Address? billingAddress;
  final List<OrderItem> items;
  final double totalProducts;
  final double totalShipping;
  final double totalDiscount;
  final double totalPaid;
  final String? carrierId;
  final String carrierName;
  final String paymentMethod;
  final String? orderState;
  final String orderStateName;
  final DateTime? dateAdd;
  final DateTime? dateUpd;
  final dynamic orderRows;

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
    this.orderStateName = 'Unknown',
    this.dateAdd,
    this.dateUpd,
    this.orderRows,
  });

  Order copyWith(
      {String? orderStateName,
      Address? shippingAddress,
      List<OrderItem>? items}) {
    return Order(
      id: id,
      reference: reference,
      customer: customer,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      billingAddress: billingAddress,
      items: items ?? this.items,
      totalProducts: totalProducts,
      totalShipping: totalShipping,
      totalDiscount: totalDiscount,
      totalPaid: totalPaid,
      carrierId: carrierId,
      carrierName: carrierName,
      paymentMethod: paymentMethod,
      orderState: orderState,
      orderStateName: orderStateName ?? this.orderStateName,
      dateAdd: dateAdd,
      dateUpd: dateUpd,
      orderRows: orderRows,
    );
  }

  Address get effectiveBillingAddress => billingAddress ?? shippingAddress;

  factory Order.fromJson(Map<String, dynamic> json) {
    final order = json['order'] ?? json;

    // Parse items from associations -> order_rows
    List<OrderItem> items = [];
    try {
      if (order['associations'] != null) {
        // Find order_rows - it might be directly in associations or nested
        final associations = order['associations'];
        dynamic orderRows;
        if (associations is Map) {
          orderRows = associations['order_rows'];
        } else if (associations is List) {
          for (var item in associations) {
            if (item is Map && item.containsKey('order_row')) {
              orderRows = item;
              break;
            }
          }
        }

        if (orderRows != null) {
          if (orderRows is List) {
            // Multiple items returned as direct list
            items = orderRows
                .where((row) => row is Map)
                .map((row) => OrderItem.fromJson(row as Map<String, dynamic>))
                .toList();
          } else if (orderRows is Map) {
            if (orderRows.containsKey('order_row')) {
              final rows = orderRows['order_row'];
              if (rows is List) {
                items = rows
                    .where((row) => row is Map)
                    .map((row) =>
                        OrderItem.fromJson(row as Map<String, dynamic>))
                    .toList();
              } else if (rows is Map) {
                items = [OrderItem.fromJson(rows as Map<String, dynamic>)];
              }
            } else if (orderRows.containsKey('product_id') ||
                orderRows.containsKey('product_name')) {
              items = [OrderItem.fromJson(orderRows as Map<String, dynamic>)];
            }
          }
        }
      }
    } catch (e) {
      // If parsing fails, keep empty items list
      items = [];
    }
    // Create placeholder address if not provided
    final defaultAddress = Address(
      alias: 'Default',
      firstName: '',
      lastName: '',
      address1: '',
      postcode: '',
      city: '',
      country: '',
    );

    return Order(
      id: order['id']?.toString(),
      reference: order['reference']?.toString(),
      customer: Customer(
        id: order['id_customer']?.toString() ?? '',
        email: '',
        firstName: '',
        lastName: '',
      ),
      shippingAddress: defaultAddress,
      billingAddress: null,
      items: items,
      totalProducts:
          double.tryParse(order['total_products']?.toString() ?? '0') ?? 0.0,
      totalShipping:
          double.tryParse(order['total_shipping']?.toString() ?? '0') ?? 0.0,
      totalDiscount:
          double.tryParse(order['total_discounts']?.toString() ?? '0') ?? 0.0,
      totalPaid: double.tryParse(order['total_paid']?.toString() ?? '0') ?? 0.0,
      carrierId: order['id_carrier']?.toString(),
      carrierName: order['carrier_name']?.toString() ?? '',
      paymentMethod: order['payment']?.toString() ?? '',
      orderState: order['current_state']?.toString(),
      orderStateName: order['order_state_name']?.toString() ?? 'Unknown',
      dateAdd: order['date_add'] != null
          ? DateTime.tryParse(order['date_add'].toString())
          : null,
      dateUpd: order['date_upd'] != null
          ? DateTime.tryParse(order['date_upd'].toString())
          : null,
      orderRows: order['associations']?['order_rows'],
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
