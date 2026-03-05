import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class LocalStorageService {
  static const String _productsFileName = 'products.json';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const int _syncIntervalDays = 30; // Aylık güncelleme

  /// Ürünleri yerel dosyaya kaydet
  Future<void> saveProducts(List<Product> products) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_productsFileName');
    
    final jsonList = products.map((p) => p.toFirestore()).toList();
    await file.writeAsString(jsonEncode(jsonList));
    
    // Son senkronizasyon zamanını kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Yerel dosyadan ürünleri oku
  Future<List<Product>> loadProducts() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_productsFileName');
      
      if (!await file.exists()) return [];
      
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      
      return jsonList.map((json) {
        final map = Map<String, dynamic>.from(json);
        return Product.fromFirestore(map, map['id'] ?? '');
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Son senkronizasyon zamanını al
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Güncelleme gerekli mi kontrol et (30 günden eski mi?)
  Future<bool> needsSync() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true; // İlk kullanım
    
    final daysSinceSync = DateTime.now().difference(lastSync).inDays;
    return daysSinceSync >= _syncIntervalDays;
  }

  /// Yerel veriyi sil
  Future<void> clearProducts() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_productsFileName');
    if (await file.exists()) {
      await file.delete();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
  }
}
