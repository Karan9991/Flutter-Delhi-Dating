import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// TODO: Replace these options by running:
/// flutterfire configure --project flutter-delhi-dating --platforms web
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'This admin panel is intended for Flutter web only.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBpsUO1PyR6acOabyg6vMB7HB5ZNPE7XbY',
    appId: '1:49793172042:web:65072ede38fe6627245cb3',
    messagingSenderId: '49793172042',
    projectId: 'flutter-delhi-dating',
    authDomain: 'flutter-delhi-dating.firebaseapp.com',
    storageBucket: 'flutter-delhi-dating.firebasestorage.app',
    measurementId: 'G-YY6QJSEGSX',
  );

}