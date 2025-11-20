class PsState {
  final String id;
  final String name;
  final String isoCode;
  final String countryId;
  final bool active;

  PsState({
    required this.id,
    required this.name,
    required this.isoCode,
    required this.countryId,
    this.active = true,
  });

  factory PsState.fromJson(Map<String, dynamic> json) {
    return PsState(
      id: json['id']?.toString() ?? '',
      name: _extractName(json['name']),
      isoCode: json['iso_code']?.toString() ?? '',
      countryId: json['id_country']?.toString() ?? '',
      active: json['active'] == '1' || json['active'] == true,
    );
  }

  static String _extractName(dynamic name) {
    if (name == null) return '';
    if (name is String) return name;
    if (name is Map) {
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
      'id_country': countryId,
      'active': active ? '1' : '0',
    };
  }
}
