class Customer {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? birthday;
  final bool newsletter;

  Customer({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.birthday,
    this.newsletter = false,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'firstname': firstName,
      'lastname': lastName,
      'email': email,
      if (phone != null) 'phone': phone,
      if (birthday != null) 'birthday': birthday,
      'newsletter': newsletter ? '1' : '0',
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
  }) {
    return Customer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      newsletter: newsletter ?? this.newsletter,
    );
  }
}
