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

  /// Format numeric values as two digits
  String formatProperty(String key, dynamic value) {
    final numericKeys = {'#', 'series', 'pattern', 'model', 'number'};
    if (numericKeys.contains(key.toLowerCase())) {
      final numVal = int.tryParse(value.toString());
      if (numVal != null) {
        return numVal.toString().padLeft(2, '0');
      }
    }
    return value.toString();
  }
}
