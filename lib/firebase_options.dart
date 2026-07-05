// GENERATED FILE — DO NOT EDIT MANUALLY
//
// Run `flutterfire configure` to regenerate this file with real values.
// See: https://firebase.google.com/docs/flutter/setup

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web is not supported.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Replace these placeholder values by running `flutterfire configure` ──

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDfbhavfcCR8eCAVVda3rGx8L9n_xKLguo',
    appId: '1:801409654516:android:b9a39f7a4c8602b13008a1',
    messagingSenderId: '801409654516',
    projectId: 'peaklog-79450',
    storageBucket: 'peaklog-79450.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUjAxFqeqZgmBTSp6RmAGWYq8Yi_TUQfs',
    appId: '1:801409654516:ios:a7f5f1314074051c3008a1',
    messagingSenderId: '801409654516',
    projectId: 'peaklog-79450',
    storageBucket: 'peaklog-79450.firebasestorage.app',
    iosBundleId: 'com.pyraworks.peaklog',
  );
}
