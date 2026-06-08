// GENERATED FILE — TEMPLATE.
//
// This is a placeholder so the project compiles without a real Firebase
// project. Replace it by running:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// which regenerates this file with your project's real values. The placeholder
// values below are NEVER used at runtime unless AppConfig.enableFirebase is
// true, and even then initialization fails gracefully into local mode.
//
// ignore_for_file: lines_longer_than_80_chars
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'carcare-pro',
    authDomain: 'carcare-pro.firebaseapp.com',
    storageBucket: 'carcare-pro.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'carcare-pro',
    storageBucket: 'carcare-pro.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'carcare-pro',
    storageBucket: 'carcare-pro.appspot.com',
    iosBundleId: 'com.carcarepro.app',
  );
}
