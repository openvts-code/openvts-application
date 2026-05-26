import 'dart:math' as math;

class VehicleSummary {
  const VehicleSummary({
    required this.id,
    this.imei = '',
    required this.name,
    required this.plateNumber,
    required this.status,
    required this.speed,
    required this.latitude,
    required this.longitude,
    this.deviceTypeId,
    this.hasValidLocation = true,
    this.updatedAt,
    this.distanceKm,
    this.odometerKm,
    this.engineHoursToday,
    this.engineHours,
    this.totalEngineHours,
    this.satellites,
    this.headingDegrees,
    this.ignition,
    this.acc,
    this.deviceConnectionStatus,
    this.lastSeenAt,
  });

  final String id;
  final String imei;
  final String name;
  final String plateNumber;
  final String status;
  final double speed;
  final double latitude;
  final double longitude;
  final int? deviceTypeId;
  final bool hasValidLocation;
  final DateTime? updatedAt;
  final double? distanceKm;
  final double? odometerKm;
  final double? engineHoursToday;
  final double? engineHours;
  final double? totalEngineHours;
  final int? satellites;
  final double? headingDegrees;
  final bool? ignition;
  final bool? acc;
  final String? deviceConnectionStatus;
  final DateTime? lastSeenAt;

  factory VehicleSummary.fromJson(Map<String, dynamic> json) {
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    final hasValidLocation = _isValidCoordinatePair(latitude, longitude);
    final plateNumber = json['plateNumber']?.toString() ??
        json['plate_number']?.toString() ??
        '';
    final name = json['name']?.toString().trim() ?? '';
    final deviceType = json['deviceType'];
    final deviceTypeSnake = json['device_type'];
    final deviceTypeId = _asInt(
      json['deviceTypeId'] ??
          json['device_type_id'] ??
          (deviceType is Map ? deviceType['id'] : null) ??
          (deviceTypeSnake is Map ? deviceTypeSnake['id'] : null),
    );

    return VehicleSummary(
      id: json['id']?.toString() ?? '',
      imei: json['imei']?.toString() ??
          json['deviceImei']?.toString() ??
          json['device_imei']?.toString() ??
          json['trackerImei']?.toString() ??
          json['tracker_imei']?.toString() ??
          '',
      name: name.isNotEmpty ? name : plateNumber,
      plateNumber: plateNumber,
      status: json['status']?.toString() ?? 'unknown',
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      latitude: latitude ?? 28.6139,
      longitude: longitude ?? 77.2090,
      deviceTypeId: deviceTypeId,
      hasValidLocation: hasValidLocation,
      updatedAt: _asDateTime(
        json['updatedAt'] ??
            json['updated_at'] ??
            json['lastUpdate'] ??
            json['last_update'] ??
            json['lastUpdatedAt'] ??
            json['last_updated_at'] ??
            json['lastUpdatedAtMs'] ??
            json['last_updated_at_ms'] ??
            json['timestamp'] ??
            json['deviceTime'] ??
            json['device_time'] ??
            json['gpsTime'] ??
            json['gps_time'] ??
            json['serverTime'] ??
            json['server_time'] ??
            json['serverTimeMs'] ??
            json['server_time_ms'],
      ),
      distanceKm: _asDouble(
        json['distanceToday'] ??
            json['distance_today'] ??
            json['todayDistance'] ??
            json['today_distance'] ??
            json['dailyDistance'] ??
            json['daily_distance'] ??
            json['tripDistance'] ??
            json['trip_distance'] ??
            json['travelDistance'] ??
            json['travel_distance'] ??
            json['coveredDistance'] ??
            json['covered_distance'] ??
            json['distance'] ??
            json['distanceKm'] ??
            json['distance_km'],
      ),
      odometerKm: _firstOdometerKm(json, const [
        'odometer',
        'odometerKm',
        'odometer_km',
        'odometerMeters',
        'odometer_meters',
        'totalOdometer',
        'total_odometer',
        'mileage',
        'mileageKm',
        'mileage_km',
      ]),
      engineHoursToday: _firstEngineHours(json, const [
        'engineHoursToday',
        'engine_hours_today',
        'todayEngineHours',
        'today_engine_hours',
        'engineHours',
        'engine_hours',
      ]),
      engineHours: _firstEngineHours(json, const [
        'engineHours',
        'engine_hours',
      ]),
      totalEngineHours: _firstEngineHours(json, const [
        'totalengineHours',
        'totalEngineHours',
        'total_engine_hours',
        'engineHoursTotal',
        'engine_hours_total',
        'hours',
      ]),
      satellites: _firstInt(json, const [
        'satellites',
        'satelliteCount',
        'satellite_count',
        'gpsSatellites',
        'gps_satellites',
      ]),
      headingDegrees: _normalizeHeadingDegrees(
        _asDouble(
              json['heading'] ??
                  json['bearing'] ??
                  json['course'] ??
                  json['angle'] ??
                  json['direction'] ??
                  json['headingDegrees'] ??
                  json['heading_degrees'] ??
                  json['bearingDegrees'] ??
                  json['bearing_degrees'],
            ) ??
            _radiansToDegrees(
              _asDouble(
                json['headingRadians'] ??
                    json['heading_radians'] ??
                    json['bearingRadians'] ??
                    json['bearing_radians'],
              ),
            ),
      ),
      ignition: _asBool(
        json['ignition'] ??
            json['ignitionStatus'] ??
            json['ignition_status'] ??
            json['engineOn'] ??
            json['engine_on'],
      ),
      acc: _asBool(
        json['acc'] ??
            json['accessory'] ??
            json['accessoryOn'] ??
            json['accessory_on'],
      ),
      deviceConnectionStatus: json['deviceConnectionStatus']?.toString() ??
          json['device_connection_status']?.toString() ??
          json['connectionStatus']?.toString() ??
          json['connection_status']?.toString(),
      lastSeenAt: _asDateTime(
        json['lastSeenAt'] ??
            json['last_seen_at'] ??
            json['lastSeen'] ??
            json['last_seen'] ??
            json['seenAt'] ??
            json['seen_at'],
      ),
    );
  }

  VehicleSummary copyWith({
    String? id,
    String? imei,
    String? name,
    String? plateNumber,
    String? status,
    double? speed,
    double? latitude,
    double? longitude,
    Object? deviceTypeId = _unset,
    bool? hasValidLocation,
    Object? updatedAt = _unset,
    Object? distanceKm = _unset,
    Object? odometerKm = _unset,
    Object? engineHoursToday = _unset,
    Object? engineHours = _unset,
    Object? totalEngineHours = _unset,
    Object? satellites = _unset,
    Object? headingDegrees = _unset,
    Object? ignition = _unset,
    Object? acc = _unset,
    Object? deviceConnectionStatus = _unset,
    Object? lastSeenAt = _unset,
  }) {
    return VehicleSummary(
      id: id ?? this.id,
      imei: imei ?? this.imei,
      name: name ?? this.name,
      plateNumber: plateNumber ?? this.plateNumber,
      status: status ?? this.status,
      speed: speed ?? this.speed,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deviceTypeId: identical(deviceTypeId, _unset)
          ? this.deviceTypeId
          : deviceTypeId as int?,
      hasValidLocation: hasValidLocation ?? this.hasValidLocation,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as DateTime?,
      distanceKm: identical(distanceKm, _unset)
          ? this.distanceKm
          : distanceKm as double?,
      odometerKm: identical(odometerKm, _unset)
          ? this.odometerKm
          : odometerKm as double?,
      engineHoursToday: identical(engineHoursToday, _unset)
          ? this.engineHoursToday
          : engineHoursToday as double?,
      engineHours: identical(engineHours, _unset)
          ? this.engineHours
          : engineHours as double?,
      totalEngineHours: identical(totalEngineHours, _unset)
          ? this.totalEngineHours
          : totalEngineHours as double?,
      satellites:
          identical(satellites, _unset) ? this.satellites : satellites as int?,
      headingDegrees: identical(headingDegrees, _unset)
          ? this.headingDegrees
          : headingDegrees as double?,
      ignition: identical(ignition, _unset) ? this.ignition : ignition as bool?,
      acc: identical(acc, _unset) ? this.acc : acc as bool?,
      deviceConnectionStatus: identical(deviceConnectionStatus, _unset)
          ? this.deviceConnectionStatus
          : deviceConnectionStatus as String?,
      lastSeenAt: identical(lastSeenAt, _unset)
          ? this.lastSeenAt
          : lastSeenAt as DateTime?,
    );
  }
}

const Object _unset = Object();

double? _firstOdometerKm(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = _asDouble(source[key]);
    if (value == null) {
      continue;
    }

    final normalizedValue = _normalizeOdometerKm(key, value);
    if (normalizedValue.isFinite && normalizedValue > 0) {
      return normalizedValue;
    }
  }

  return null;
}

double _normalizeOdometerKm(String key, double value) {
  final normalizedKey = _normalizeTelemetryMetricKey(key);
  if (normalizedKey.endsWith('meters')) {
    return value / 1000;
  }

  return value;
}

double? _firstEngineHours(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = _asEngineHours(source[key]);
    if (value != null) {
      return _normalizeEngineHours(key, value);
    }
  }

  return null;
}

double _normalizeEngineHours(String key, double value) {
  final normalizedKey = _normalizeTelemetryMetricKey(key);
  if (normalizedKey == 'hours' ||
      normalizedKey.contains('millisecond') ||
      normalizedKey.contains('millis')) {
    return value / 3600000;
  }

  if (normalizedKey.contains('second')) {
    return value / 3600;
  }

  if (normalizedKey.contains('minute')) {
    return value / 60;
  }

  return value;
}

double? _asEngineHours(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final hours = _parseEngineHoursDuration(trimmed);
    if (hours != null) {
      return hours;
    }
  }

  return _asDouble(value);
}

double? _parseEngineHoursDuration(String value) {
  final matches = RegExp(
    r'(\d+(?:\.\d+)?)\s*(h|hr|hrs|hour|hours|m|min|mins|minute|minutes|s|sec|secs|second|seconds)\b',
    caseSensitive: false,
  ).allMatches(value);
  var totalHours = 0.0;
  var matched = false;

  for (final match in matches) {
    final amount = double.tryParse(match.group(1)!);
    final unit = match.group(2)!.toLowerCase();
    if (amount == null) {
      continue;
    }

    matched = true;
    if (unit.startsWith('h')) {
      totalHours += amount;
    } else if (unit.startsWith('m')) {
      totalHours += amount / 60;
    } else {
      totalHours += amount / 3600;
    }
  }

  return matched ? totalHours : null;
}

int? _firstInt(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = _asInt(source[key]);
    if (value != null) {
      return value;
    }
  }

  return null;
}

String _normalizeTelemetryMetricKey(String key) {
  return key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

DateTime? _asDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }

  if (value is num) {
    return _dateFromEpoch(value);
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      return parsed;
    }

    final numeric = num.tryParse(trimmed);
    if (numeric != null) {
      return _dateFromEpoch(numeric);
    }
  }

  return null;
}

bool _isValidCoordinatePair(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) {
    return false;
  }

  return latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

DateTime _dateFromEpoch(num value) {
  final raw = value.toInt();
  final milliseconds = raw.abs() < 100000000000 ? raw * 1000 : raw;
  return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
}

double? _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = double.tryParse(trimmed);
    if (parsed != null) {
      return parsed;
    }

    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(trimmed);
    if (match == null) {
      return null;
    }

    return double.tryParse(match.group(0)!);
  }

  return null;
}

bool? _asBool(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    if (const <String>{'true', '1', 'yes', 'on', 'active', 'connected'}
        .contains(normalized)) {
      return true;
    }

    if (const <String>{'false', '0', 'no', 'off', 'inactive', 'disconnected'}
        .contains(normalized)) {
      return false;
    }
  }

  return null;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = int.tryParse(trimmed);
    if (parsed != null) {
      return parsed;
    }

    final numeric = double.tryParse(trimmed);
    return numeric?.round();
  }

  return null;
}

double? _radiansToDegrees(double? radians) {
  if (radians == null) {
    return null;
  }

  return radians * (180 / math.pi);
}

double? _normalizeHeadingDegrees(double? value) {
  if (value == null || !value.isFinite) {
    return null;
  }

  final normalized = value % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}
