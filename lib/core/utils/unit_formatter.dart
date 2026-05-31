import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_preferences_provider.dart';

/// Formats distance and speed values based on user's unit preference (KM or MILES).
class UnitFormatter {
  const UnitFormatter({required this.units});

  /// Unit preference: 'KM' or 'MILES'
  final String units;

  /// Convert kilometers to the user's preferred unit.
  double distanceFromKm(double km) {
    if (units.toUpperCase() == 'MILES') {
      return km * 0.621371;
    }
    return km;
  }

  /// Format distance value with appropriate unit suffix.
  ///
  /// [km] is assumed to be in kilometers.
  /// Returns formatted string like "10.5 km" or "6.5 mi".
  String distance(double km, {int decimals = 1}) {
    final value = distanceFromKm(km);
    final suffix = units.toUpperCase() == 'MILES' ? 'mi' : 'km';
    return '${value.toStringAsFixed(decimals)} $suffix';
  }

  /// Convert kilometers per hour to the user's preferred speed unit.
  double speedFromKph(double kph) {
    if (units.toUpperCase() == 'MILES') {
      return kph * 0.621371;
    }
    return kph;
  }

  /// Format speed value (kph) with appropriate unit suffix.
  ///
  /// [kph] is assumed to be in kilometers per hour.
  /// Returns formatted string like "50 km/h" or "31 mph".
  String speed(double kph, {int decimals = 0}) {
    final value = speedFromKph(kph);
    final suffix = units.toUpperCase() == 'MILES' ? 'mph' : 'km/h';
    return '${value.toStringAsFixed(decimals)} $suffix';
  }

  /// Get the distance unit label ('km' or 'mi').
  String get distanceLabel => units.toUpperCase() == 'MILES' ? 'mi' : 'km';

  /// Get the speed unit label ('km/h' or 'mph').
  String get speedLabel => units.toUpperCase() == 'MILES' ? 'mph' : 'km/h';

  /// Check if using miles (vs kilometers).
  bool get usesMiles => units.toUpperCase() == 'MILES';
}

/// Provider for [UnitFormatter] that watches localization preferences.
///
/// Automatically updates when user changes unit preference in Settings.
final unitFormatterProvider = Provider<UnitFormatter>((ref) {
  final prefs = ref.watch(appLocalizationPreferencesProvider);
  return UnitFormatter(units: prefs.units);
});
