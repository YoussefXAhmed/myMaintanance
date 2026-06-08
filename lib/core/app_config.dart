/// Compile-time feature flags & app-wide constants.
class AppConfig {
  AppConfig._();

  static const String appName = 'CarCare Pro';
  static const String version = '1.0.0';

  /// Master switch for Firebase. Ships **off** so the app builds and runs fully
  /// offline (Hive-backed) without any Firebase project. After you run
  /// `flutterfire configure` and add a real `firebase_options.dart`, flip this
  /// to `true` (or pass `--dart-define=ENABLE_FIREBASE=true`).
  static const bool enableFirebase =
      bool.fromEnvironment('ENABLE_FIREBASE', defaultValue: false);

  /// Optional OpenAI key for the AI advisor. When empty, the advisor uses the
  /// built-in rule-based engine (no network).
  static const String openAiApiKey =
      String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  static const Duration splashMinDuration = Duration(milliseconds: 1600);
}
