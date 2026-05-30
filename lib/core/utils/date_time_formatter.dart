import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/app_preferences_provider.dart';

// ---------------------------------------------------------------------------
// Global date format config — updated by AppLocalizationPreferencesController
// so that ALL existing DateTimeFormatter usages automatically pick up the
// user's selected format without per-screen migration.
// ---------------------------------------------------------------------------

String _globalDatePattern = 'dd MMM yyyy';
String _globalTimePattern = 'hh:mm a';

/// Called by the preferences controller whenever localization settings change.
/// This updates the format used by every [DateTimeFormatter] instance in the app.
void updateGlobalDateFormatConfig({
  required String datePattern,
  required bool use24Hour,
}) {
  _globalDatePattern = _toIntlPattern(datePattern);
  _globalTimePattern = use24Hour ? 'HH:mm' : 'hh:mm a';
}

// ---------------------------------------------------------------------------
// DateTimeFormatter — now reads from global config instead of hardcoded values.
// All 85+ existing usages automatically get the user's preferred format.
// ---------------------------------------------------------------------------

class DateTimeFormatter {
  const DateTimeFormatter();

  String formatDateTime(DateTime value) {
    try {
      return DateFormat('$_globalDatePattern, $_globalTimePattern')
          .format(value);
    } catch (_) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(value);
    }
  }

  String formatDate(DateTime value) {
    try {
      return DateFormat(_globalDatePattern).format(value);
    } catch (_) {
      return DateFormat('dd MMM yyyy').format(value);
    }
  }

  String formatTime(DateTime value) {
    try {
      return DateFormat(_globalTimePattern).format(value);
    } catch (_) {
      return DateFormat('hh:mm a').format(value);
    }
  }
}

// ---------------------------------------------------------------------------
// AppDateFormatter — provider-aware, null-safe, with relative time support.
// Preferred for new code: ref.watch(appDateFormatterProvider).formatDate(value)
// ---------------------------------------------------------------------------

class AppDateFormatter {
  const AppDateFormatter({
    required this.datePattern,
    required this.use24Hour,
  });

  final String datePattern;
  final bool use24Hour;

  String get _intlDatePattern => _toIntlPattern(datePattern);

  String get _timePattern => use24Hour ? 'HH:mm' : 'hh:mm a';

  String formatDateTime(DateTime? value) {
    if (value == null) return '';
    try {
      return DateFormat('$_intlDatePattern, $_timePattern').format(value);
    } catch (_) {
      return _fallbackDateTime(value);
    }
  }

  String formatDate(DateTime? value) {
    if (value == null) return '';
    try {
      return DateFormat(_intlDatePattern).format(value);
    } catch (_) {
      return _fallbackDate(value);
    }
  }

  String formatTime(DateTime? value) {
    if (value == null) return '';
    try {
      return DateFormat(_timePattern).format(value);
    } catch (_) {
      return _fallbackTime(value);
    }
  }

  String formatRelativeOrDate(DateTime? value) {
    if (value == null) return '';
    final now = DateTime.now();
    final diff = now.difference(value);
    if (diff.inSeconds < 60 && diff.inSeconds >= 0) return 'just now';
    if (diff.inMinutes < 60 && diff.inMinutes >= 0) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24 && diff.inHours >= 0) return '${diff.inHours}h ago';
    if (diff.inDays < 7 && diff.inDays >= 0) return '${diff.inDays}d ago';
    return formatDate(value);
  }

  static String _fallbackDateTime(DateTime value) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(value);
  }

  static String _fallbackDate(DateTime value) {
    return DateFormat('dd MMM yyyy').format(value);
  }

  static String _fallbackTime(DateTime value) {
    return DateFormat('hh:mm a').format(value);
  }
}

// ---------------------------------------------------------------------------
// Shared pattern converter
// ---------------------------------------------------------------------------

/// Converts backend/web date pattern tokens to Dart intl tokens.
/// Backend uses Moment.js-style: YYYY, YY, MM, DD, HH, mm, ss, A
/// Dart intl uses: yyyy, yy, MM, dd, HH, mm, ss, a
String _toIntlPattern(String pattern) {
  if (pattern.trim().isEmpty) return 'dd MMM yyyy';
  return pattern
      .replaceAll('YYYY', 'yyyy')
      .replaceAll('YY', 'yy')
      .replaceAll('DD', 'dd')
      .replaceAll('D', 'd');
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final appDateFormatterProvider = Provider<AppDateFormatter>((ref) {
  final prefs = ref.watch(appLocalizationPreferencesProvider);
  return AppDateFormatter(
    datePattern: prefs.dateFormat,
    use24Hour: prefs.use24Hour,
  );
});
