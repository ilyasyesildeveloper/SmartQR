import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final LocalStorageService _localStorage = LocalStorageService();

  List<Product> _products = [];
  List<Product> _searchResults = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastSyncTime;

  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FirebaseService get firebaseService => _firebaseService;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initialize - load local data first, then sync if needed
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Önce yerel veriyi yükle (anında göster)
      _products = await _localStorage.loadProducts();
      _lastSyncTime = await _localStorage.getLastSyncTime();
      notifyListeners();

      // 2. Firebase'e anonim giriş yap
      await _firebaseService.signInAnonymously();

      // 3. Güncelleme gerekli mi kontrol et (ilk kullanım veya 30 gün geçmiş)
      if (await _localStorage.needsSync()) {
        await _syncFromFirebase();
      }
    } catch (e) {
      _errorMessage = 'Bağlantı hatası: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Firebase'den veri çek ve yerele kaydet
  Future<void> _syncFromFirebase() async {
    try {
      final firebaseProducts = await _firebaseService.fetchProducts();
      if (firebaseProducts.isNotEmpty) {
        _products = firebaseProducts;
        await _localStorage.saveProducts(_products);
        _lastSyncTime = DateTime.now();
      }
    } catch (e) {
      // Offline ise yerel veri ile devam et
      if (_products.isEmpty) {
        _errorMessage = 'Veri yüklenemedi: $e';
      }
    }
  }

  /// Manuel güncelleme (Settings ekranından)
  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseProducts = await _firebaseService.fetchProducts();
      _products = firebaseProducts;
      await _localStorage.saveProducts(_products);
      _lastSyncTime = DateTime.now();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Ürünler yüklenemedi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search products locally (from already-loaded products)
  void searchProducts(String query) {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    final lowerQuery = query.toLowerCase();
    _searchResults = _products
        .where((product) =>
            product.itemName.toLowerCase().contains(lowerQuery) ||
            product.qrText.toLowerCase().contains(lowerQuery) ||
            product.id.toLowerCase().contains(lowerQuery))
        .toList();
    notifyListeners();
  }

  /// Select a product (by QR scan or manual search)
  void selectProduct(Product product) {
    _selectedProduct = product;
    notifyListeners();
  }

  /// Find product by QR code
  Future<Product?> findByQrCode(String qrCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Önce yerelde ara
      final localMatch = _products.firstWhere(
        (p) => p.qrText == qrCode || p.id == qrCode,
        orElse: () => Product(id: '', type: '', series: '', itemName: '', qrText: '', imageUrl: ''),
      );

      if (localMatch.id.isNotEmpty) {
        _selectedProduct = localMatch;
        _errorMessage = null;
        return localMatch;
      }

      // Yerelde bulamazsa Firebase'den ara
      final product = await _firebaseService.findByQrCode(qrCode);
      if (product != null) {
        _selectedProduct = product;
      }
      _errorMessage = null;
      return product;
    } catch (e) {
      _errorMessage = 'QR arama hatası: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload CSV to Firestore (admin only)
  Future<int> uploadCsv(String csvContent) async {
    _isLoading = true;
    notifyListeners();

    try {
      final count = await _firebaseService.uploadCsvToFirestore(csvContent);
      // Yükleme sonrası yereli de güncelle
      await fetchProducts();
      _errorMessage = null;
      return count;
    } catch (e) {
      _errorMessage = 'CSV yükleme hatası: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear selected product
  void clearSelection() {
    _selectedProduct = null;
    notifyListeners();
  }
}
