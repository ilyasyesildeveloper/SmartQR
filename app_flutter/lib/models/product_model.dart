import 'dart:convert';

class Product {
  final String id;
  final String type;
  final String series;
  final String itemName;
  final String qrText;
  final String imageUrl;
  final Map<String, dynamic> properties;

  Product({
    required this.id,
    required this.type,
    required this.series,
    required this.itemName,
    required this.qrText,
    required this.imageUrl,
    this.properties = const {},
  });

  factory Product.fromCsvRow(List<String> headers, List<String> values) {
    final map = <String, String>{};
    for (var i = 0; i < headers.length && i < values.length; i++) {
      map[headers[i].trim()] = values[i].trim();
    }

    // Extract known fields
    final id = map['id'] ?? '';
    final type = map['type'] ?? '';
    final series = map['series'] ?? '';
    final itemName = map['itemName'] ?? '';
    final qrText = map['qrText'] ?? '';
    final imageUrl = map['imageUrl'] ?? '';

    // Everything else goes into properties
    final knownKeys = {'#', 'id', 'type', 'series', 'itemName', 'qrText', 'imageUrl'};
    final properties = <String, dynamic>{};
    for (final entry in map.entries) {
      if (!knownKeys.contains(entry.key) && entry.value.isNotEmpty) {
        properties[entry.key] = entry.value;
      }
    }

    // Also add # if present
    if (map['#'] != null && map['#']!.isNotEmpty) {
      properties['#'] = map['#'];
    }

    return Product(
      id: id,
      type: type,
      series: series,
      itemName: itemName,
      qrText: qrText,
      imageUrl: imageUrl,
      properties: properties,
    );
  }

  factory Product.fromFirestore(Map<String, dynamic> data, String docId) {
    return Product(
      id: data['id'] ?? docId,
      type: data['type'] ?? '',
      series: data['series'] ?? '',
      itemName: data['itemName'] ?? '',
      qrText: data['qrText'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      properties: data['propertiesJson'] != null
          ? (data['propertiesJson'] is String
              ? jsonDecode(data['propertiesJson']) as Map<String, dynamic>
              : data['propertiesJson'] as Map<String, dynamic>)
          : {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type,
      'series': series,
      'itemName': itemName,
      'qrText': qrText,
      'imageUrl': imageUrl,
      'propertiesJson': properties,
    };
  }

  /// Format property values: single-digit numbers become 2-digit (1→01, 2→02)
  String formatProperty(String key, dynamic value) {
    final str = value.toString().trim();
    if (str.isEmpty) return str;
    
    // If value is a single character and it's a digit, pad to 2 digits
    if (str.length == 1) {
      final numVal = int.tryParse(str);
      if (numVal != null) {
        return numVal.toString().padLeft(2, '0');
      }
    }
    
    // For dot-separated values like "2707.XW" or "05.XW", pad the numeric parts
    if (str.contains('.')) {
      final parts = str.split('.');
      final formatted = parts.map((p) {
        if (p.length == 1) {
          final n = int.tryParse(p);
          if (n != null) return n.toString().padLeft(2, '0');
        }
        return p;
      }).join('.');
      return formatted;
    }
    
    return str;
  }
}
