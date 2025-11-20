class Address {
  final String? id;
  final String alias;
  final String firstName;
  final String lastName;
  final String address1;
  final String? address2;
  final String postcode;
  final String city;
  final String country;
  final String? countryId; // PrestaShop id_country
  final String? state;
  final String? stateId; // PrestaShop id_state
  final String? phone;
  final String? mobilePhone;
  final String? customerId;
  final String? company;
  final String? vatNumber;
  final String? dni;

  Address({
    this.id,
    required this.alias,
    required this.firstName,
    required this.lastName,
    required this.address1,
    this.address2,
    required this.postcode,
    required this.city,
    required this.country,
    this.countryId,
    this.state,
    this.stateId,
    this.phone,
    this.mobilePhone,
    this.customerId,
    this.company,
    this.vatNumber,
    this.dni,
  });

  String get fullAddress {
    final parts = [
      address1,
      if (address2 != null && address2!.isNotEmpty) address2,
      city,
      if (state != null && state!.isNotEmpty) state,
      postcode,
      country,
    ];
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    final address = json['address'] ?? json;

    return Address(
      id: address['id']?.toString(),
      alias: address['alias']?.toString() ?? 'Home',
      firstName: address['firstname']?.toString() ?? '',
      lastName: address['lastname']?.toString() ?? '',
      address1: address['address1']?.toString() ?? '',
      address2: address['address2']?.toString(),
      postcode: address['postcode']?.toString() ?? '',
      city: address['city']?.toString() ?? '',
      country: address['country']?.toString() ?? '',
      countryId: address['id_country']?.toString(),
      state: address['state']?.toString(),
      stateId: address['id_state']?.toString(),
      phone: address['phone']?.toString(),
      mobilePhone: address['phone_mobile']?.toString(),
      customerId: address['id_customer']?.toString(),
      company: address['company']?.toString(),
      vatNumber: address['vat_number']?.toString(),
      dni: address['dni']?.toString(),
    );
  }

  /// Converts to JSON for PrestaShop API
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'alias': alias,
      'firstname': firstName,
      'lastname': lastName,
      'address1': address1,
      'address2': address2 ?? '',
      'postcode': postcode,
      'city': city,
      'id_country': countryId ?? '1', // Default to country ID 1
      'id_state': stateId ?? '0',
      if (phone != null) 'phone': phone,
      if (mobilePhone != null) 'phone_mobile': mobilePhone,
      if (customerId != null) 'id_customer': customerId,
      'company': company ?? '',
      'vat_number': vatNumber ?? '',
      'dni': dni ?? '',
      'deleted': '0',
    };
  }

  /// Creates a copy with modified fields
  Address copyWith({
    String? id,
    String? alias,
    String? firstName,
    String? lastName,
    String? address1,
    String? address2,
    String? postcode,
    String? city,
    String? country,
    String? countryId,
    String? state,
    String? stateId,
    String? phone,
    String? mobilePhone,
    String? customerId,
    String? company,
    String? vatNumber,
    String? dni,
  }) {
    return Address(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
      postcode: postcode ?? this.postcode,
      city: city ?? this.city,
      country: country ?? this.country,
      countryId: countryId ?? this.countryId,
      state: state ?? this.state,
      stateId: stateId ?? this.stateId,
      phone: phone ?? this.phone,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      customerId: customerId ?? this.customerId,
      company: company ?? this.company,
      vatNumber: vatNumber ?? this.vatNumber,
      dni: dni ?? this.dni,
    );
  }
}
