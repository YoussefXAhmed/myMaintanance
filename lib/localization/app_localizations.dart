import 'package:flutter/widgets.dart';

import 'app_strings.dart';

/// Lightweight localization layer (no codegen required). Supports English and
/// Arabic, with `{param}` interpolation and a safe fallback chain.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ar')];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';

  Map<String, String> get _table => isArabic ? AppStrings.ar : AppStrings.en;

  /// Translate [key] with optional `{name}` substitutions.
  String t(String key, {Map<String, Object>? params}) {
    var value = _table[key] ?? AppStrings.en[key] ?? key;
    if (params != null) {
      params.forEach((k, v) => value = value.replaceAll('{$k}', '$v'));
    }
    return value;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Ergonomic access: `context.l10n.t('key')` and `context.tr('key')`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String key, {Map<String, Object>? params}) => AppLocalizations.of(this).t(key, params: params);
}
