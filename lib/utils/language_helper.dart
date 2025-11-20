/// Helper utility for extracting text values from PrestaShop multilingual fields.
///
/// PrestaShop API returns multilingual fields in this format:
/// ```json
/// {
///   "language": [
///     {"id": "1", "value": "English text"},
///     {"id": "2", "value": "French text"}
///   ]
/// }
/// ```
///
/// This utility extracts the actual text value from these structures.
class LanguageHelper {
  /// Extracts the text value from a PrestaShop multilingual field.
  ///
  /// Handles multiple formats:
  /// - Direct string value
  /// - Map with 'language' key containing a list
  /// - Map with 'language' key containing a single object
  /// - List of language objects
  ///
  /// Returns the extracted string or null if extraction fails.
  static String? extractValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;

    if (value is Map) {
      // Handle {language: [...]} format
      if (value['language'] != null) {
        final lang = value['language'];
        if (lang is List && lang.isNotEmpty) {
          return lang.first['value']?.toString();
        }
        if (lang is Map) {
          return lang['value']?.toString();
        }
      }
      // Handle direct {id: x, value: y} format
      if (value['value'] != null) {
        return value['value'].toString();
      }
    }

    // Handle direct list format [{id: 1, value: "text"}]
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map && first['value'] != null) {
        return first['value'].toString();
      }
    }

    return value.toString();
  }

  /// Extracts value with a default fallback.
  static String extractValueOrDefault(dynamic value, String defaultValue) {
    return extractValue(value) ?? defaultValue;
  }

  /// Extracts value or returns empty string.
  static String extractValueOrEmpty(dynamic value) {
    return extractValue(value) ?? '';
  }
}
