import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_store.dart';

/// App-wide preferences: theme, language, notifications and onboarding flag.
/// All values are persisted to the Hive `settings` box and applied live
/// (no restart required).
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.locale = const Locale('en'),
    this.notificationsEnabled = true,
    this.reminderDays = 7,
    this.onboardingComplete = false,
    this.reminderToggles = const {
      'oil': true,
      'maintenance': true,
      'insurance': true,
      'license': true,
      'battery': true,
      'tires': true,
    },
  });

  final ThemeMode themeMode;
  final Locale locale;
  final bool notificationsEnabled;
  final int reminderDays;
  final bool onboardingComplete;
  final Map<String, bool> reminderToggles;

  bool get isArabic => locale.languageCode == 'ar';

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? notificationsEnabled,
    int? reminderDays,
    bool? onboardingComplete,
    Map<String, bool>? reminderToggles,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        reminderDays: reminderDays ?? this.reminderDays,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        reminderToggles: reminderToggles ?? this.reminderToggles,
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _kTheme = 'theme_mode';
  static const _kLocale = 'locale';
  static const _kNotif = 'notifications_enabled';
  static const _kReminderDays = 'reminder_days';
  static const _kOnboarding = 'onboarding_complete';

  LocalStore get _store => LocalStore.instance;

  @override
  SettingsState build() {
    final themeName = _store.setting<String>(_kTheme, fallback: 'dark');
    final localeCode = _store.setting<String>(_kLocale, fallback: 'en');
    return SettingsState(
      themeMode: _themeFromName(themeName),
      locale: Locale(localeCode ?? 'en'),
      notificationsEnabled: _store.setting<bool>(_kNotif, fallback: true) ?? true,
      reminderDays: _store.setting<int>(_kReminderDays, fallback: 7) ?? 7,
      onboardingComplete: _store.setting<bool>(_kOnboarding, fallback: false) ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _store.setSetting(_kTheme, mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _store.setSetting(_kLocale, locale.languageCode);
  }

  Future<void> toggleLanguage() async {
    await setLocale(Locale(state.isArabic ? 'en' : 'ar'));
  }

  Future<void> setNotificationsEnabled(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _store.setSetting(_kNotif, value);
  }

  Future<void> setReminderDays(int days) async {
    state = state.copyWith(reminderDays: days);
    await _store.setSetting(_kReminderDays, days);
  }

  Future<void> setReminderToggle(String key, bool value) async {
    final map = Map<String, bool>.from(state.reminderToggles)..[key] = value;
    state = state.copyWith(reminderToggles: map);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingComplete: true);
    await _store.setSetting(_kOnboarding, true);
  }

  ThemeMode _themeFromName(String? name) => switch (name) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

/// Convenience selectors.
final localeProvider = Provider<Locale>((ref) => ref.watch(settingsProvider).locale);
final themeModeProvider = Provider<ThemeMode>((ref) => ref.watch(settingsProvider).themeMode);
