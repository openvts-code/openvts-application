import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_cache.dart';
import '../storage/storage_keys.dart';
import '../utils/date_time_formatter.dart';
import 'core_providers.dart';

class AppLocalizationPreferences {
  const AppLocalizationPreferences({
    this.languageCode = 'en',
    this.dateFormat = 'DD MMM YYYY',
    this.timeFormat = '12h',
    this.timezone = '',
    this.themeMode = ThemeMode.light,
  });

  final String languageCode;
  final String dateFormat;
  final String timeFormat;
  final String timezone;
  final ThemeMode themeMode;

  bool get use24Hour => timeFormat == '24h';

  AppLocalizationPreferences copyWith({
    String? languageCode,
    String? dateFormat,
    String? timeFormat,
    String? timezone,
    ThemeMode? themeMode,
  }) {
    return AppLocalizationPreferences(
      languageCode: languageCode ?? this.languageCode,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      timezone: timezone ?? this.timezone,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class AppLocalizationPreferencesController
    extends StateNotifier<AppLocalizationPreferences> {
  AppLocalizationPreferencesController(this._localCache, this._themeModeCtrl)
      : super(const AppLocalizationPreferences()) {
    hydrate();
  }

  final LocalCache _localCache;
  final ThemeModeController _themeModeCtrl;

  void hydrate() {
    final languageCode =
        _localCache.getString(StorageKeys.appLanguageCode) ?? 'en';
    final dateFormat =
        _localCache.getString(StorageKeys.appDateFormat) ?? 'DD MMM YYYY';
    final timeFormat =
        _localCache.getString(StorageKeys.appTimeFormat) ?? '12h';
    final timezone = _localCache.getString(StorageKeys.appTimezone) ?? '';
    final themeMode = _readThemeMode();

    state = AppLocalizationPreferences(
      languageCode: languageCode,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      timezone: timezone,
      themeMode: themeMode,
    );

    updateGlobalDateFormatConfig(
      datePattern: dateFormat,
      use24Hour: state.use24Hour,
    );
  }

  Future<void> apply({
    String? languageCode,
    String? dateFormat,
    String? timeFormat,
    String? timezone,
    ThemeMode? themeMode,
  }) async {
    if (languageCode != null) {
      await _localCache.setString(StorageKeys.appLanguageCode, languageCode);
    }
    if (dateFormat != null) {
      await _localCache.setString(StorageKeys.appDateFormat, dateFormat);
    }
    if (timeFormat != null) {
      await _localCache.setString(StorageKeys.appTimeFormat, timeFormat);
    }
    if (timezone != null) {
      await _localCache.setString(StorageKeys.appTimezone, timezone);
    }
    if (themeMode != null) {
      await _themeModeCtrl.setThemeMode(themeMode);
    }

    state = state.copyWith(
      languageCode: languageCode,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      timezone: timezone,
      themeMode: themeMode,
    );

    updateGlobalDateFormatConfig(
      datePattern: state.dateFormat,
      use24Hour: state.use24Hour,
    );
  }

  Future<void> applyFromSuperadminSettings({
    required String language,
    required String dateFormat,
    required bool use24Hour,
    required String theme,
    required String timezoneOffset,
  }) async {
    await apply(
      languageCode: language,
      dateFormat: dateFormat,
      timeFormat: use24Hour ? '24h' : '12h',
      timezone: timezoneOffset,
      themeMode: _parseThemeString(theme),
    );
  }

  Future<void> applyFromAdminSettings({
    required String language,
    required String dateFormat,
    required bool use24Hour,
    required String theme,
    required String timezoneOffset,
  }) async {
    await apply(
      languageCode: language,
      dateFormat: dateFormat,
      timeFormat: use24Hour ? '24h' : '12h',
      timezone: timezoneOffset,
      themeMode: _parseThemeString(theme),
    );
  }

  Future<void> applyFromUserSettings({
    required String languageCode,
    required String dateFormat,
    required String timeFormat,
    required String theme,
    required String timezone,
  }) async {
    await apply(
      languageCode: languageCode,
      dateFormat: dateFormat,
      timeFormat: timeFormat.toUpperCase() == '24H' ? '24h' : '12h',
      timezone: timezone,
      themeMode: _parseThemeString(theme),
    );
  }

  Future<void> resetToDefaults() async {
    await _localCache.remove(StorageKeys.appLanguageCode);
    await _localCache.remove(StorageKeys.appDateFormat);
    await _localCache.remove(StorageKeys.appTimeFormat);
    await _localCache.remove(StorageKeys.appTimezone);
    await _themeModeCtrl.setThemeMode(ThemeMode.light);

    state = const AppLocalizationPreferences();
  }

  /// Loads preferences from LocalCache on app startup.
  /// Called automatically by the controller constructor.
  void rehydrate() {
    hydrate();
  }

  ThemeMode _readThemeMode() {
    final stored = _localCache.getString(StorageKeys.themeMode);
    switch (stored) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  static ThemeMode _parseThemeString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'DARK':
        return ThemeMode.dark;
      case 'SYSTEM':
        return ThemeMode.system;
      case 'LIGHT':
      default:
        return ThemeMode.light;
    }
  }
}

final appLocalizationPreferencesProvider = StateNotifierProvider<
    AppLocalizationPreferencesController, AppLocalizationPreferences>((ref) {
  final localCache = ref.watch(localCacheProvider);
  final themeModeCtrl = ref.watch(themeModeProvider.notifier);
  return AppLocalizationPreferencesController(localCache, themeModeCtrl);
});
