class Carrier {
  final String id;
  final String name;
  final String? delay;
  final double price;
  final String? description;
  final bool active;
  final int? grade;

  Carrier({
    required this.id,
    required this.name,
    this.delay,
    required this.price,
    this.description,
    this.active = true,
    this.grade,
  });

  String get deliveryTime => delay ?? 'Standard delivery';

  factory Carrier.fromJson(Map<String, dynamic> json) {
    final carrier = json['carrier'] ?? json;

    // Handle delay which can be a language array or string
    String? delayValue;
    final delayData = carrier['delay'];
    if (delayData is String) {
      delayValue = delayData;
    } else if (delayData is Map && delayData['language'] != null) {
      final lang = delayData['language'];
      if (lang is List && lang.isNotEmpty) {
        delayValue = lang.first['value']?.toString();
      } else if (lang is Map) {
        delayValue = lang['value']?.toString();
      }
    }

    return Carrier(
      id: carrier['id']?.toString() ?? '',
      name: _extractLanguageValue(carrier['name']) ?? '',
      delay: delayValue,
      price: carrier['price'] is num
          ? (carrier['price'] as num).toDouble()
          : double.tryParse(carrier['price']?.toString() ?? '0') ?? 0.0,
      description: _extractLanguageValue(carrier['description']),
      active: carrier['active'] == '1' || carrier['active'] == true,
      grade: int.tryParse(carrier['grade']?.toString() ?? '0'),
    );
  }

  static String? _extractLanguageValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      if (value['language'] != null) {
        final lang = value['language'];
        if (lang is List && lang.isNotEmpty) {
          return lang.first['value']?.toString();
        }
        if (lang is Map) {
          return lang['value']?.toString();
        }
      }
    }
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (delay != null) 'delay': delay,
      'price': price,
      if (description != null) 'description': description,
      'active': active,
      if (grade != null) 'grade': grade,
    };
  }
}
