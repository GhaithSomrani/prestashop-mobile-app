class Country {
  final String id;
  final String name;
  final String isoCode;
  final bool containsStates;
  final bool needZipCode;
  final String? zipCodeFormat;
  final bool active;

  Country({
    required this.id,
    required this.name,
    required this.isoCode,
    this.containsStates = false,
    this.needZipCode = true,
    this.zipCodeFormat,
    this.active = true,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id']?.toString() ?? '',
      name: _extractName(json['name']),
      isoCode: json['iso_code']?.toString() ?? '',
      containsStates: json['contains_states'] == '1' || json['contains_states'] == true,
      needZipCode: json['need_zip_code'] == '1' || json['need_zip_code'] == true,
      zipCodeFormat: json['zip_code_format']?.toString(),
      active: json['active'] == '1' || json['active'] == true,
    );
  }

  static String _extractName(dynamic name) {
    if (name == null) return '';
    if (name is String) return name;
    if (name is Map) {
      // Handle PrestaShop multilingual format
      if (name['language'] != null) {
        final lang = name['language'];
        if (lang is List && lang.isNotEmpty) {
          return lang.first['value']?.toString() ?? '';
        }
        if (lang is Map) {
          return lang['value']?.toString() ?? '';
        }
      }
    }
    return name.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iso_code': isoCode,
      'contains_states': containsStates ? '1' : '0',
      'need_zip_code': needZipCode ? '1' : '0',
      'zip_code_format': zipCodeFormat,
      'active': active ? '1' : '0',
    };
  }
}
