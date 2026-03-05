import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import '../models/product_model.dart';

class FirebaseService {
  static const String collectionName = 'smartqrflutter';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAdminLoggedIn =>
      currentUser != null &&
      currentUser!.providerData.any((p) => p.providerId == 'password');

  /// Sign in anonymously for read-only access
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Admin login with email/password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    // Re-login anonymously
    await signInAnonymously();
  }

  /// Fetch all products from Firestore
  Future<List<Product>> fetchProducts() async {
    final snapshot = await _firestore.collection(collectionName).get();
    return snapshot.docs
        .map((doc) => Product.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Upload products to Firestore from CSV string
  Future<int> uploadCsvToFirestore(String csvContent) async {
    // Strip UTF-8 BOM (EF BB BF) — multiple approaches for safety
    csvContent = csvContent.replaceAll('\uFEFF', '');
    csvContent = csvContent.replaceAll('\uFFFE', '');
    
    // Remove any non-printable characters from the first line (header)
    final lines = csvContent.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) throw Exception('CSV dosyası boş.');
    
    // Clean the header line character by character
    final cleanHeader = String.fromCharCodes(
      lines[0].codeUnits.where((c) => c >= 32 && c != 65279 && c != 65534),
    );
    lines[0] = cleanHeader;
    
    // Rejoin and parse
    csvContent = lines.join('\n');

    // Parse CSV with ; as delimiter
    final rows = const CsvToListConverter(
      fieldDelimiter: ';',
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csvContent);

    if (rows.isEmpty) throw Exception('CSV dosyası boş.');

    // Clean all headers
    final headers = rows.first.map((e) => e.toString().trim()).toList();
    
    // Find id column (case-insensitive)
    final idIndex = headers.indexWhere(
      (h) => h.toLowerCase() == 'id',
    );
    
    if (idIndex == -1) {
      // Fallback: try manual split
      final manualHeaders = cleanHeader.split(';').map((e) => e.trim()).toList();
      final manualIdIndex = manualHeaders.indexWhere((h) => h.toLowerCase() == 'id');
      
      if (manualIdIndex == -1) {
        throw Exception(
          'CSV başlıklarında "id" sütunu bulunamadı.\n'
          'Başlıklar (${headers.length} adet): ${headers.join(" | ")}\n'
          'İlk karakter kodu: ${cleanHeader.isNotEmpty ? cleanHeader.codeUnitAt(0) : "boş"}'
        );
      }
      
      // Use manual parsing
      return _uploadWithManualParsing(lines, manualHeaders);
    }

    int uploadedCount = 0;

    // Process in batches of 500
    final dataRows = rows.skip(1).where((row) {
      return row.any((cell) => cell.toString().trim().isNotEmpty);
    }).toList();

    if (dataRows.isEmpty) throw Exception('CSV dosyasında veri satırı bulunamadı.');

    for (var i = 0; i < dataRows.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 > dataRows.length) ? dataRows.length : i + 500;

      for (var j = i; j < end; j++) {
        final values = dataRows[j].map((e) => e.toString()).toList();
        final product = Product.fromCsvRow(headers, values);

        if (product.id.isNotEmpty) {
          final docRef = _firestore.collection(collectionName).doc(product.id);
          batch.set(docRef, product.toFirestore());
          uploadedCount++;
        }
      }

      await batch.commit();
    }

    return uploadedCount;
  }

  /// Fallback: manual CSV parsing with split
  Future<int> _uploadWithManualParsing(List<String> lines, List<String> headers) async {
    int uploadedCount = 0;
    
    final dataLines = lines.skip(1).where((l) => l.trim().isNotEmpty).toList();
    if (dataLines.isEmpty) throw Exception('CSV dosyasında veri satırı bulunamadı.');

    for (var i = 0; i < dataLines.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 > dataLines.length) ? dataLines.length : i + 500;

      for (var j = i; j < end; j++) {
        final values = dataLines[j].split(';').map((e) => e.trim()).toList();
        final product = Product.fromCsvRow(headers, values);

        if (product.id.isNotEmpty) {
          final docRef = _firestore.collection(collectionName).doc(product.id);
          batch.set(docRef, product.toFirestore());
          uploadedCount++;
        }
      }

      await batch.commit();
    }

    return uploadedCount;
  }

  /// Search products by name or QR text
  Future<List<Product>> searchProducts(String query) async {
    final snapshot = await _firestore.collection(collectionName).get();
    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) => Product.fromFirestore(doc.data(), doc.id))
        .where((product) =>
            product.itemName.toLowerCase().contains(lowerQuery) ||
            product.qrText.toLowerCase().contains(lowerQuery) ||
            product.id.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Find product by QR code
  Future<Product?> findByQrCode(String qrCode) async {
    // Try direct document lookup first
    final doc = await _firestore.collection(collectionName).doc(qrCode).get();
    if (doc.exists) {
      return Product.fromFirestore(doc.data()!, doc.id);
    }

    // Otherwise search by qrText field
    final snapshot = await _firestore
        .collection(collectionName)
        .where('qrText', isEqualTo: qrCode)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Product.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    }

    return null;
  }
}
