import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'services/firebase_service.dart';
import 'services/local_auth_service.dart';
import 'services/local_store.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locale data for intl date formatting (Arabic + English).
  await initializeDateFormatting();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Local persistence first — the app is fully functional offline.
  await LocalStore.instance.init();
  await LocalAuthService.ensureBox();

  // Firebase is optional; this is a no-op (and safe) when disabled.
  await FirebaseService.init();

  // Notifications — best effort; never blocks startup.
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: CarCareApp()));
}
