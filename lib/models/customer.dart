class Customer {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? birthday;
  final bool newsletter;
  final String? idGender;
  final String? idDefaultGroup;
  final String? idLang;
  final bool active;
  final String? secureKey;

  Customer({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.birthday,
    this.newsletter = false,
    this.idGender,
    this.idDefaultGroup,
    this.idLang,
    this.active = true,
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
      idGender: customer['id_gender']?.toString(),
      idDefaultGroup: customer['id_default_group']?.toString(),
      idLang: customer['id_lang']?.toString(),
      active: customer['active'] == '1' || customer['active'] == true,
      secureKey: customer['secure_key']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_default_group': idDefaultGroup ?? '3',
      'id_lang': idLang ?? '1',
      'id_gender': idGender ?? '1',
      'firstname': firstName,
      'lastname': lastName,
      'email': email,
      if (phone != null) 'phone': phone,
      if (birthday != null) 'birthday': birthday,
      'newsletter': newsletter ? '1' : '0',
      'optin': '0',
      'active': active ? '1' : '0',
      'deleted': '0',
      if (secureKey != null) 'secure_key': secureKey,
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
    String? idGender,
    String? idDefaultGroup,
    String? idLang,
    bool? active,
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
      idGender: idGender ?? this.idGender,
      idDefaultGroup: idDefaultGroup ?? this.idDefaultGroup,
      idLang: idLang ?? this.idLang,
      active: active ?? this.active,
      secureKey: secureKey ?? this.secureKey,
    );
  }
}
