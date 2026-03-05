import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<Product> _products = [];
  List<Product> _searchResults = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FirebaseService get firebaseService => _firebaseService;

  /// Initialize - sign in anonymously and fetch products
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.signInAnonymously();
      await fetchProducts();
    } catch (e) {
      _errorMessage = 'Bağlantı hatası: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all products
  Future<void> fetchProducts() async {
    try {
      _products = await _firebaseService.fetchProducts();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Ürünler yüklenemedi: $e';
    }
    notifyListeners();
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
      await fetchProducts();
      _errorMessage = null;
      return count;
    } catch (e) {
      _errorMessage = 'CSV yükleme hatası: $e';
      rethrow; // Let UI handle the error display
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
