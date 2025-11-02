import 'package:json_annotation/json_annotation.dart';

part 'address.g.dart';

@JsonSerializable()
class Address {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'id_customer')
  final int customerId;

  @JsonKey(name: 'id_manufacturer')
  final int manufacturerId;

  @JsonKey(name: 'id_supplier')
  final int supplierId;

  @JsonKey(name: 'id_country')
  final int countryId;

  @JsonKey(name: 'id_state')
  final int? stateId;

  @JsonKey(name: 'alias')
  final String alias;

  @JsonKey(name: 'company')
  final String? company;

  @JsonKey(name: 'lastname')
  final String lastName;

  @JsonKey(name: 'firstname')
  final String firstName;

  @JsonKey(name: 'address1')
  final String address1;

  @JsonKey(name: 'address2')
  final String? address2;

  @JsonKey(name: 'postcode')
  final String postcode;

  @JsonKey(name: 'city')
  final String city;

  @JsonKey(name: 'phone')
  final String? phone;

  @JsonKey(name: 'phone_mobile')
  final String? mobilePhone;

  @JsonKey(name: 'vat_number')
  final String? vatNumber;

  @JsonKey(name: 'dni')
  final String? dni;

  @JsonKey(name: 'active', defaultValue: true)
  final bool active;

  @JsonKey(name: 'deleted', defaultValue: false)
  final bool deleted;

  @JsonKey(name: 'date_add')
  final String? dateAdded;

  @JsonKey(name: 'date_upd')
  final String? dateUpdated;

  const Address({
    this.id,
    required this.customerId,
    required this.manufacturerId,
    required this.supplierId,
    required this.countryId,
    this.stateId,
    required this.alias,
    this.company,
    required this.lastName,
    required this.firstName,
    required this.address1,
    this.address2,
    required this.postcode,
    required this.city,
    this.phone,
    this.mobilePhone,
    this.vatNumber,
    this.dni,
    this.active = true,
    this.deleted = false,
    this.dateAdded,
    this.dateUpdated,
  });

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);

  // Helper methods
  String get fullName => '$firstName $lastName';

  String get fullAddress {
    final parts = <String>[];
    if (address1.isNotEmpty) parts.add(address1);
    if (address2?.isNotEmpty == true) parts.add(address2!);
    if (city.isNotEmpty) parts.add(city);
    if (postcode.isNotEmpty) parts.add(postcode);
    return parts.join(', ');
  }

  String get displayName {
    if (company?.isNotEmpty == true) {
      return '$company ($alias)';
    }
    return alias;
  }

  bool get isComplete {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        address1.isNotEmpty &&
        city.isNotEmpty &&
        postcode.isNotEmpty;
  }

  // For creating new addresses
  Address copyWith({
    int? id,
    int? customerId,
    int? manufacturerId,
    int? supplierId,
    int? countryId,
    int? stateId,
    String? alias,
    String? company,
    String? lastName,
    String? firstName,
    String? address1,
    String? address2,
    String? postcode,
    String? city,
    String? phone,
    String? mobilePhone,
    String? vatNumber,
    String? dni,
    bool? active,
    bool? deleted,
    String? dateAdded,
    String? dateUpdated,
  }) {
    return Address(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      supplierId: supplierId ?? this.supplierId,
      countryId: countryId ?? this.countryId,
      stateId: stateId ?? this.stateId,
      alias: alias ?? this.alias,
      company: company ?? this.company,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
      postcode: postcode ?? this.postcode,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      vatNumber: vatNumber ?? this.vatNumber,
      dni: dni ?? this.dni,
      active: active ?? this.active,
      deleted: deleted ?? this.deleted,
      dateAdded: dateAdded ?? this.dateAdded,
      dateUpdated: dateUpdated ?? this.dateUpdated,
    );
  }

  // Factory constructor for creating new addresses
  factory Address.create({
    required int customerId,
    required String alias,
    required String firstName,
    required String lastName,
    required String address1,
    required String city,
    required String postcode,
    required int countryId,
    String? company,
    String? address2,
    String? phone,
    String? mobilePhone,
  }) {
    return Address(
      customerId: customerId,
      manufacturerId: 0,
      supplierId: 0,
      countryId: countryId,
      alias: alias,
      company: company,
      lastName: lastName,
      firstName: firstName,
      address1: address1,
      address2: address2,
      postcode: postcode,
      city: city,
      phone: phone,
      mobilePhone: mobilePhone,
    );
  }
}

// Country and State models for address forms
@JsonSerializable()
class Country {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'iso_code')
  final String isoCode;

  @JsonKey(name: 'call_prefix')
  final String callPrefix;

  @JsonKey(name: 'contains_states', defaultValue: false)
  final bool containsStates;

  @JsonKey(name: 'need_identification_number', defaultValue: false)
  final bool needIdentificationNumber;

  @JsonKey(name: 'need_zip_code', defaultValue: true)
  final bool needZipCode;

  const Country({
    required this.id,
    required this.name,
    required this.isoCode,
    required this.callPrefix,
    this.containsStates = false,
    this.needIdentificationNumber = false,
    this.needZipCode = true,
  });

  factory Country.fromJson(Map<String, dynamic> json) => _$CountryFromJson(json);
  Map<String, dynamic> toJson() => _$CountryToJson(this);
}

@JsonSerializable()
class State {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'id_country')
  final int countryId;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'iso_code')
  final String isoCode;

  @JsonKey(name: 'active', defaultValue: true)
  final bool active;

  const State({
    required this.id,
    required this.countryId,
    required this.name,
    required this.isoCode,
    this.active = true,
  });

  factory State.fromJson(Map<String, dynamic> json) => _$StateFromJson(json);
  Map<String, dynamic> toJson() => _$StateToJson(this);
}