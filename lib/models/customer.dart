class Customer {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? birthday;
  final bool newsletter;
  final String? genderId; // 1 = Mr, 2 = Mrs
  final String? defaultGroupId;
  final String? langId;
  final bool active;
  final bool optin;
  final String? secureKey;

  Customer({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.birthday,
    this.newsletter = false,
    this.genderId,
    this.defaultGroupId,
    this.langId,
    this.active = true,
    this.optin = false,
    this.secureKey,
  });

  String get fullName => '$firstName $lastName';

  factory Customer.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] ?? json;

    return Customer(
      id: customer['id']?.toString(),
      firstName: customer['firstname']?.toString() ?? '',
      lastName: customer['lastname']?.toString() ?? '',
      email: customer['email']?.toString() ?? '',
      phone: customer['phone']?.toString(),
      birthday: customer['birthday']?.toString(),
      newsletter: customer['newsletter'] == '1' || customer['newsletter'] == true,
      genderId: customer['id_gender']?.toString(),
      defaultGroupId: customer['id_default_group']?.toString(),
      langId: customer['id_lang']?.toString(),
      active: customer['active'] == '1' || customer['active'] == true,
      optin: customer['optin'] == '1' || customer['optin'] == true,
      secureKey: customer['secure_key']?.toString(),
    );
  }

  /// Converts to JSON for PrestaShop API
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_default_group': defaultGroupId ?? '3', // Customer group
      'id_lang': langId ?? '1',
      'id_gender': genderId ?? '1',
      'firstname': firstName,
      'lastname': lastName,
      'email': email,
      'birthday': birthday ?? '0000-00-00',
      'newsletter': newsletter ? '1' : '0',
      'optin': optin ? '1' : '0',
      'active': active ? '1' : '0',
      'deleted': '0',
      'associations': {
        'groups': [
          {'id': defaultGroupId ?? '3'}
        ],
      },
    };
  }

  Customer copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? birthday,
    bool? newsletter,
    String? genderId,
    String? defaultGroupId,
    String? langId,
    bool? active,
    bool? optin,
    String? secureKey,
  }) {
    return Customer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      newsletter: newsletter ?? this.newsletter,
      genderId: genderId ?? this.genderId,
      defaultGroupId: defaultGroupId ?? this.defaultGroupId,
      langId: langId ?? this.langId,
      active: active ?? this.active,
      optin: optin ?? this.optin,
      secureKey: secureKey ?? this.secureKey,
    );
  }
}
