import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Service to read developer/about info from MyData Firebase project
class MyDataService {
  static const String _projectId = 'mydata-81';
  static const String _apiKey = 'AIzaSyBnPvBqsBUx7dRv04WfF4K-Rd_IvJZr9nE';
  static const String _appId = '1:198931834905:android:8628105a3c51aecf162288';
  static const String _messagingSenderId = '198931834905';
  static const String _storageBucket = 'mydata-81.firebasestorage.app';

  static const String _collectionName = 'mydata';
  static const String _documentId = 'mydata-81';

  FirebaseFirestore? _firestore;
  Map<String, dynamic>? _cachedData;

  /// Initialize the second Firebase app for MyData
  Future<void> initialize() async {
    try {
      // Check if already initialized
      FirebaseApp myDataApp;
      try {
        myDataApp = Firebase.app('mydata');
      } catch (_) {
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
      }
      _firestore = FirebaseFirestore.instanceFor(app: myDataApp);
    } catch (e) {
      // Silently fail - about page will show defaults
    }
  }

  /// Fetch developer data from Firestore
  Future<Map<String, dynamic>> fetchData() async {
    if (_cachedData != null) return _cachedData!;

    try {
      if (_firestore == null) await initialize();
      if (_firestore == null) return {};

      final doc = await _firestore!
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      if (doc.exists && doc.data() != null) {
        _cachedData = doc.data()!;
        return _cachedData!;
      }
    } catch (e) {
      // Offline or error — return empty
    }
    return {};
  }

  /// Clear cache to force refetch
  void clearCache() {
    _cachedData = null;
  }
}
