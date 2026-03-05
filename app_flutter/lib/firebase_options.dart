import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for '
          '${defaultTargetPlatform.name} - '
          'you need to add Firebase support for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMW5FcLjEZmDxH--VJP7W3QgeQ5JpjlJM',
    appId: '1:183099303019:android:f5aa8ecfc441b04b357d2e',
    messagingSenderId: '183099303019',
    projectId: 'smartqr-flutterapp',
    storageBucket: 'smartqr-flutterapp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAKywdSux0OjxsGpvrGx5jh20k-IA8tZ3Q',
    appId: '1:183099303019:ios:6848ecd54f16e9d4357d2e',
    messagingSenderId: '183099303019',
    projectId: 'smartqr-flutterapp',
    storageBucket: 'smartqr-flutterapp.firebasestorage.app',
    iosBundleId: 'com.smartqr.smartQr',
  );
}
