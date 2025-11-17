class Carrier {
  final String id;
  final String name;
  final double delay;
  final double price;
  final String? description;
  final bool active;

  Carrier({
    required this.id,
    required this.name,
    required this.delay,
    required this.price,
    this.description,
    this.active = true,
  });

  factory Carrier.fromJson(Map<String, dynamic> json) {
    final carrier = json['carrier'] ?? json;

    return Carrier(
      id: carrier['id']?.toString() ?? '',
      name: carrier['name']?.toString() ?? '',
      delay: carrier['delay'] is num
          ? (carrier['delay'] as num).toDouble()
          : double.tryParse(carrier['delay']?.toString() ?? '0') ?? 0.0,
      price: carrier['price'] is num
          ? (carrier['price'] as num).toDouble()
          : double.tryParse(carrier['price']?.toString() ?? '0') ?? 0.0,
      description: carrier['description']?.toString(),
      active: carrier['active'] == '1' || carrier['active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'delay': delay,
      'price': price,
      if (description != null) 'description': description,
      'active': active,
    };
  }
}
