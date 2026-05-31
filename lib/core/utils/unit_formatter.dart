import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_preferences_provider.dart';

class UnitFormatter {
  const UnitFormatter({required this.units});

  final String units;

  bool get _usesMiles => units.toUpperCase() == 'MILES';

  String get distanceSuffix => _usesMiles ? 'mi' : 'km';

  String get speedSuffix => _usesMiles ? 'mph' : 'km/h';

  double distanceFromKm(double km) {
    if (_usesMiles) return km * 0.621371;
    return km;
  }

  double speedFromKph(double kph) {
    if (_usesMiles) return kph * 0.621371;
    return kph;
  }

  String distance(double km, {int decimals = 1}) {
    final value = distanceFromKm(km);
    return '${value.toStringAsFixed(decimals)} $distanceSuffix';
  }

  String speed(double kph, {int decimals = 0}) {
    final value = speedFromKph(kph);
    return '${value.toStringAsFixed(decimals)} $speedSuffix';
  }
}

final unitFormatterProvider = Provider<UnitFormatter>((ref) {
  final prefs = ref.watch(appLocalizationPreferencesProvider);
  return UnitFormatter(units: prefs.units);
});
