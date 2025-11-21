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
  final String? countryId;
  final String? state;
  final String? stateId;
  final String? phone;
  final String? mobilePhone;
  final String? customerId;

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_customer': customerId ?? '',
      'id_manufacturer': '',
      'id_supplier': '',
      'id_warehouse': '',
      'id_country': countryId ?? '1',
      'id_state': stateId ?? '0',
      'alias': alias,
      'company': '',
      'lastname': lastName,
      'firstname': firstName,
      'vat_number': '',
      'address1': address1,
      'address2': address2 ?? '',
      'postcode': postcode,
      'city': city,
      'other': '',
      'phone': phone ?? '',
      'phone_mobile': mobilePhone ?? '',
      'dni': '',
      'deleted': '0',
    };
  }
}
