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
    this.layoutDirection = 'LTR',
    this.units = 'KM',
  });

  final String languageCode;
  final String dateFormat;
  final String timeFormat;
  final String timezone;
  final ThemeMode themeMode;
  final String layoutDirection;
  final String units;

  bool get use24Hour => timeFormat == '24h';

  bool get isRtl => layoutDirection.toUpperCase() == 'RTL';

  TextDirection get textDirection => isRtl ? TextDirection.rtl : TextDirection.ltr;

  bool get usesMiles => units.toUpperCase() == 'MILES';

  String get distanceLabel => usesMiles ? 'mi' : 'km';

  String get speedLabel => usesMiles ? 'mph' : 'km/h';

  AppLocalizationPreferences copyWith({
    String? languageCode,
    String? dateFormat,
    String? timeFormat,
    String? timezone,
    ThemeMode? themeMode,
    String? layoutDirection,
    String? units,
  }) {
    return AppLocalizationPreferences(
      languageCode: languageCode ?? this.languageCode,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      timezone: timezone ?? this.timezone,
      themeMode: themeMode ?? this.themeMode,
      layoutDirection: layoutDirection ?? this.layoutDirection,
      units: units ?? this.units,
    );
  }
}

class AppLocalizationPreferencesController extends StateNotifier<AppLocalizationPreferences> {
  AppLocalizationPreferencesController(this._localCache, this._themeModeCtrl)
      : super(const AppLocalizationPreferences()) {
    hydrate();
  }

  final LocalCache _localCache;
  final ThemeModeController _themeModeCtrl;

  void hydrate() {
    final languageCode = _localCache.getString(StorageKeys.appLanguageCode) ?? 'en';
    final dateFormat = _localCache.getString(StorageKeys.appDateFormat) ?? 'DD MMM YYYY';
    final timeFormat = _localCache.getString(StorageKeys.appTimeFormat) ?? '12h';
    final timezone = _localCache.getString(StorageKeys.appTimezone) ?? '';
    final themeMode = _readThemeMode();
    final layoutDirection = _localCache.getString(StorageKeys.appLayoutDirection) ?? 'LTR';
    final units = _localCache.getString(StorageKeys.appUnits) ?? 'KM';

    state = AppLocalizationPreferences(
      languageCode: languageCode,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      timezone: timezone,
      themeMode: themeMode,
      layoutDirection: layoutDirection.toUpperCase(),
      units: units.toUpperCase(),
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
    String? layoutDirection,
    String? units,
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
    if (layoutDirection != null) {
      await _localCache.setString(
        StorageKeys.appLayoutDirection,
        layoutDirection.toUpperCase(),
      );
    }
    if (units != null) {
      await _localCache.setString(
        StorageKeys.appUnits,
        units.toUpperCase(),
      );
    }

    state = state.copyWith(
      languageCode: languageCode,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      timezone: timezone,
      themeMode: themeMode,
      layoutDirection: layoutDirection?.toUpperCase(),
      units: units?.toUpperCase(),
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
    String layoutDirection = 'LTR',
    String units = 'KM',
  }) async {
    await apply(
      languageCode: _normalizeLanguageCode(language),
      dateFormat: dateFormat,
      timeFormat: use24Hour ? '24h' : '12h',
      timezone: timezoneOffset,
      themeMode: _parseThemeString(theme),
      layoutDirection: layoutDirection,
      units: units,
    );
  }

  Future<void> applyFromAdminSettings({
    required String language,
    required String dateFormat,
    required bool use24Hour,
    required String theme,
    required String timezoneOffset,
    String layoutDirection = 'LTR',
    String units = 'KM',
  }) async {
    await apply(
      languageCode: _normalizeLanguageCode(language),
      dateFormat: dateFormat,
      timeFormat: use24Hour ? '24h' : '12h',
      timezone: timezoneOffset,
      themeMode: _parseThemeString(theme),
      layoutDirection: layoutDirection,
      units: units,
    );
  }

  Future<void> applyFromUserSettings({
    required String languageCode,
    required String dateFormat,
    required String timeFormat,
    required String theme,
    required String timezone,
    String layoutDirection = 'LTR',
    String units = 'KM',
  }) async {
    await apply(
      languageCode: _normalizeLanguageCode(languageCode),
      dateFormat: dateFormat,
      timeFormat: timeFormat.toUpperCase() == '24H' ? '24h' : '12h',
      timezone: timezone,
      themeMode: _parseThemeString(theme),
      layoutDirection: layoutDirection,
      units: units,
    );
  }

  Future<void> resetToDefaults() async {
    await _localCache.remove(StorageKeys.appLanguageCode);
    await _localCache.remove(StorageKeys.appDateFormat);
    await _localCache.remove(StorageKeys.appTimeFormat);
    await _localCache.remove(StorageKeys.appTimezone);
    await _localCache.remove(StorageKeys.appLayoutDirection);
    await _localCache.remove(StorageKeys.appUnits);
    await _themeModeCtrl.setThemeMode(ThemeMode.light);

    state = const AppLocalizationPreferences();

    updateGlobalDateFormatConfig(
      datePattern: state.dateFormat,
      use24Hour: state.use24Hour,
    );
  }

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

  static String _normalizeLanguageCode(String code) {
    final normalized = code.trim().toLowerCase();
    switch (normalized) {
      case 'english':
      case 'en':
        return 'en';
      case 'hindi':
      case 'hi':
        return 'hi';
      case 'arabic':
      case 'ar':
        return 'ar';
      case 'spanish':
      case 'es':
        return 'es';
      case 'french':
      case 'fr':
        return 'fr';
      case 'portuguese':
      case 'pt':
        return 'pt';
      default:
        return normalized.isNotEmpty ? normalized : 'en';
    }
  }
}

final appLocalizationPreferencesProvider =
    StateNotifierProvider<AppLocalizationPreferencesController, AppLocalizationPreferences>((ref) {
  final localCache = ref.watch(localCacheProvider);
  final themeModeCtrl = ref.watch(themeModeProvider.notifier);
  return AppLocalizationPreferencesController(localCache, themeModeCtrl);
});
