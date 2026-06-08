import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../firebase_options.dart';

/// Initialises Firebase when enabled, and records whether it succeeded so the
/// rest of the app can degrade gracefully to local-only mode.
class FirebaseService {
  FirebaseService._();

  static bool _available = false;
  static bool get isAvailable => _available;

  static Future<void> init() async {
    if (!AppConfig.enableFirebase) {
      _available = false;
      return;
    }
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _available = true;
    } catch (e) {
      _available = false;
      if (kDebugMode) {
        debugPrint('Firebase init failed — running in local mode. ($e)');
      }
    }
  }
}
