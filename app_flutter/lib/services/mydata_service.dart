import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Service to read developer/about info from MyData Firebase project
class MyDataService {
  static const String _projectId = 'mydata-81';
  static const String _apiKey = 'AIzaSyBnPvBqsBUx7dRv04WfF4K-Rd_IvJZr9nE';
  static const String _appId = '1:198931834905:android:8628105a3c51aecf162288';
  static const String _messagingSenderId = '198931834905';
  static const String _storageBucket = 'mydata-81.firebasestorage.app';

  static const String _collectionName = 'MyData';
  static const String _documentId = 'mydata-81';

  FirebaseFirestore? _firestore;
  Map<String, dynamic>? _cachedData;
  String? lastError; // Debug için

  /// Initialize the second Firebase app for MyData
  Future<void> initialize() async {
    try {
      FirebaseApp myDataApp;
      try {
        myDataApp = Firebase.app('mydata');
        debugPrint('[MyData] Using existing Firebase app');
      } catch (_) {
        debugPrint('[MyData] Initializing new Firebase app...');
        myDataApp = await Firebase.initializeApp(
          name: 'mydata',
          options: const FirebaseOptions(
            apiKey: _apiKey,
            appId: _appId,
            messagingSenderId: _messagingSenderId,
            projectId: _projectId,
            storageBucket: _storageBucket,
          ),
        );
        debugPrint('[MyData] Firebase app initialized successfully');
      }
      _firestore = FirebaseFirestore.instanceFor(app: myDataApp);
      debugPrint('[MyData] Firestore instance ready');
    } catch (e, stackTrace) {
      lastError = 'Init error: $e';
      debugPrint('[MyData] ERROR initializing: $e');
      debugPrint('[MyData] Stack: $stackTrace');
    }
  }

  /// Fetch developer data from Firestore
  Future<Map<String, dynamic>> fetchData() async {
    if (_cachedData != null) return _cachedData!;

    try {
      if (_firestore == null) await initialize();
      if (_firestore == null) {
        debugPrint('[MyData] Firestore is null after init');
        return {};
      }

      debugPrint('[MyData] Fetching $_collectionName/$_documentId ...');
      final doc = await _firestore!
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      debugPrint('[MyData] Doc exists: ${doc.exists}');
      if (doc.exists && doc.data() != null) {
        _cachedData = doc.data()!;
        debugPrint('[MyData] Got ${_cachedData!.length} fields: ${_cachedData!.keys.toList()}');
        return _cachedData!;
      } else {
        lastError = 'Document does not exist or is empty';
        debugPrint('[MyData] Document not found');
      }
    } catch (e, stackTrace) {
      lastError = 'Fetch error: $e';
      debugPrint('[MyData] ERROR fetching: $e');
      debugPrint('[MyData] Stack: $stackTrace');
    }
    return {};
  }

  /// Clear cache to force refetch
  void clearCache() {
    _cachedData = null;
  }
}
