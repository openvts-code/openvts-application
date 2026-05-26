import 'package:flutter/foundation.dart';

enum UserNotificationGroup { basic, overspeed, geofence }

enum UserNotificationChannel { webPush, mobilePush, whatsapp, email }

class UserNotificationChannelFlags {
  const UserNotificationChannelFlags({
    this.notifyWebPush = false,
    this.notifyMobilePush = false,
    this.notifyWhatsapp = false,
    this.notifyEmail = false,
  });

  final bool notifyWebPush;
  final bool notifyMobilePush;
  final bool notifyWhatsapp;
  final bool notifyEmail;

  factory UserNotificationChannelFlags.fromJson(dynamic json) {
    final map = _asMap(json);
    return UserNotificationChannelFlags(
      notifyWebPush: _asBool(map['notifyWebPush']),
      notifyMobilePush: _asBool(map['notifyMobilePush']),
      notifyWhatsapp: _asBool(map['notifyWhatsapp']),
      notifyEmail: _asBool(map['notifyEmail']),
    );
  }

  int get activeCount {
    var count = 0;
    if (notifyWebPush) count += 1;
    if (notifyMobilePush) count += 1;
    if (notifyWhatsapp) count += 1;
    if (notifyEmail) count += 1;
    return count;
  }

  bool valueFor(UserNotificationChannel channel) {
    switch (channel) {
      case UserNotificationChannel.webPush:
        return notifyWebPush;
      case UserNotificationChannel.mobilePush:
        return notifyMobilePush;
      case UserNotificationChannel.whatsapp:
        return notifyWhatsapp;
      case UserNotificationChannel.email:
        return notifyEmail;
    }
  }

  UserNotificationChannelFlags updateChannel(
    UserNotificationChannel channel,
    bool value,
  ) {
    switch (channel) {
      case UserNotificationChannel.webPush:
        return copyWith(notifyWebPush: value);
      case UserNotificationChannel.mobilePush:
        return copyWith(notifyMobilePush: value);
      case UserNotificationChannel.whatsapp:
        return copyWith(notifyWhatsapp: value);
      case UserNotificationChannel.email:
        return copyWith(notifyEmail: value);
    }
  }

  UserNotificationChannelFlags copyWith({
    bool? notifyWebPush,
    bool? notifyMobilePush,
    bool? notifyWhatsapp,
    bool? notifyEmail,
  }) {
    return UserNotificationChannelFlags(
      notifyWebPush: notifyWebPush ?? this.notifyWebPush,
      notifyMobilePush: notifyMobilePush ?? this.notifyMobilePush,
      notifyWhatsapp: notifyWhatsapp ?? this.notifyWhatsapp,
      notifyEmail: notifyEmail ?? this.notifyEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'notifyWebPush': notifyWebPush,
      'notifyMobilePush': notifyMobilePush,
      'notifyWhatsapp': notifyWhatsapp,
      'notifyEmail': notifyEmail,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is UserNotificationChannelFlags &&
        other.notifyWebPush == notifyWebPush &&
        other.notifyMobilePush == notifyMobilePush &&
        other.notifyWhatsapp == notifyWhatsapp &&
        other.notifyEmail == notifyEmail;
  }

  @override
  int get hashCode {
    return Object.hash(
      notifyWebPush,
      notifyMobilePush,
      notifyWhatsapp,
      notifyEmail,
    );
  }
}

class UserNotificationChannels {
  const UserNotificationChannels({
    this.basic = const UserNotificationChannelFlags(),
    this.overspeed = const UserNotificationChannelFlags(),
    this.geofence = const UserNotificationChannelFlags(),
  });

  final UserNotificationChannelFlags basic;
  final UserNotificationChannelFlags overspeed;
  final UserNotificationChannelFlags geofence;

  factory UserNotificationChannels.fromJson(dynamic json) {
    final map = _asMap(json);
    return UserNotificationChannels(
      basic: UserNotificationChannelFlags.fromJson(
        _firstByKeys(map, const ['BASIC', 'basic']),
      ),
      overspeed: UserNotificationChannelFlags.fromJson(
        _firstByKeys(map, const ['OVERSPEED', 'overspeed']),
      ),
      geofence: UserNotificationChannelFlags.fromJson(
        _firstByKeys(map, const ['GEOFENCE', 'geofence']),
      ),
    );
  }

  int get activeCount {
    return basic.activeCount + overspeed.activeCount + geofence.activeCount;
  }

  UserNotificationChannelFlags flagsFor(UserNotificationGroup group) {
    switch (group) {
      case UserNotificationGroup.basic:
        return basic;
      case UserNotificationGroup.overspeed:
        return overspeed;
      case UserNotificationGroup.geofence:
        return geofence;
    }
  }

  UserNotificationChannels updateFlags(
    UserNotificationGroup group,
    UserNotificationChannelFlags flags,
  ) {
    switch (group) {
      case UserNotificationGroup.basic:
        return copyWith(basic: flags);
      case UserNotificationGroup.overspeed:
        return copyWith(overspeed: flags);
      case UserNotificationGroup.geofence:
        return copyWith(geofence: flags);
    }
  }

  UserNotificationChannels updateChannel(
    UserNotificationGroup group,
    UserNotificationChannel channel,
    bool value,
  ) {
    final flags = flagsFor(group).updateChannel(channel, value);
    return updateFlags(group, flags);
  }

  UserNotificationChannels copyWith({
    UserNotificationChannelFlags? basic,
    UserNotificationChannelFlags? overspeed,
    UserNotificationChannelFlags? geofence,
  }) {
    return UserNotificationChannels(
      basic: basic ?? this.basic,
      overspeed: overspeed ?? this.overspeed,
      geofence: geofence ?? this.geofence,
    );
  }

  Map<String, dynamic> toSaveJson() {
    return <String, dynamic>{
      'BASIC': basic.toJson(),
      'OVERSPEED': overspeed.toJson(),
      'GEOFENCE': geofence.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is UserNotificationChannels &&
        other.basic == basic &&
        other.overspeed == overspeed &&
        other.geofence == geofence;
  }

  @override
  int get hashCode => Object.hash(basic, overspeed, geofence);
}

class UserNotificationVehicle {
  const UserNotificationVehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
  });

  final int id;
  final String name;
  final String plateNumber;

  factory UserNotificationVehicle.fromJson(dynamic json) {
    final map = _asMap(json);
    return UserNotificationVehicle(
      id: _asInt(map['id']),
      name: _asString(map['name']),
      plateNumber: _asString(map['plateNumber']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserNotificationVehicle &&
        other.id == id &&
        other.name == name &&
        other.plateNumber == plateNumber;
  }

  @override
  int get hashCode => Object.hash(id, name, plateNumber);
}

class UserBasicNotificationRow {
  const UserBasicNotificationRow({
    required this.vehicleId,
    this.ignitionEnabled = false,
    this.alarmEnabled = false,
  });

  final int vehicleId;
  final bool ignitionEnabled;
  final bool alarmEnabled;

  factory UserBasicNotificationRow.fromJson(dynamic json) {
    final map = _asMap(json);
    return UserBasicNotificationRow(
      vehicleId: _asInt(map['vehicleId']),
      ignitionEnabled: _asBool(map['ignitionEnabled']),
      alarmEnabled: _asBool(map['alarmEnabled']),
    );
  }

  UserBasicNotificationRow copyWith({
    int? vehicleId,
    bool? ignitionEnabled,
    bool? alarmEnabled,
  }) {
    return UserBasicNotificationRow(
      vehicleId: vehicleId ?? this.vehicleId,
      ignitionEnabled: ignitionEnabled ?? this.ignitionEnabled,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
    );
  }

  Map<String, dynamic> toSaveJson() {
    return <String, dynamic>{
      'vehicleId': vehicleId,
      'ignitionEnabled': ignitionEnabled,
      'alarmEnabled': alarmEnabled,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is UserBasicNotificationRow &&
        other.vehicleId == vehicleId &&
        other.ignitionEnabled == ignitionEnabled &&
        other.alarmEnabled == alarmEnabled;
  }

  @override
  int get hashCode => Object.hash(vehicleId, ignitionEnabled, alarmEnabled);
}

class UserOverspeedNotificationRow {
  const UserOverspeedNotificationRow({
    required this.vehicleId,
    this.enabled = false,
    this.speedLimitKph,
  });

  final int vehicleId;
  final bool enabled;
  final int? speedLimitKph;

  factory UserOverspeedNotificationRow.fromJson(dynamic json) {
    final map = _asMap(json);
    return UserOverspeedNotificationRow(
      vehicleId: _asInt(map['vehicleId']),
      enabled: _asBool(map['enabled']),
      speedLimitKph: _asNullableInt(map['speedLimitKph']),
    );
  }

  UserOverspeedNotificationRow copyWith({
    int? vehicleId,
    bool? enabled,
    Object? speedLimitKph = _unset,
  }) {
    return UserOverspeedNotificationRow(
      vehicleId: vehicleId ?? this.vehicleId,
      enabled: enabled ?? this.enabled,
      speedLimitKph: identical(speedLimitKph, _unset)
          ? this.speedLimitKph
          : speedLimitKph as int?,
    );
  }

  Map<String, dynamic> toSaveJson() {
    return <String, dynamic>{
      'vehicleId': vehicleId,
      'enabled': enabled,
      'speedLimitKph': speedLimitKph,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is UserOverspeedNotificationRow &&
        other.vehicleId == vehicleId &&
        other.enabled == enabled &&
        other.speedLimitKph == speedLimitKph;
  }

  @override
  int get hashCode => Object.hash(vehicleId, enabled, speedLimitKph);
}

class UserNotificationGeofence {
  const UserNotificationGeofence({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = false,
  });

  final int id;
  final String name;
  final String type;
  final bool isActive;

  factory UserNotificationGeofence.fromJson(dynamic json) {
    final map = _asMap(json);
    return UserNotificationGeofence(
      id: _asInt(map['id']),
      name: _asString(map['name']),
      type: _asString(map['type']),
      isActive: _asBool(map['isActive']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserNotificationGeofence &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(id, name, type, isActive);
}

class UserGeofenceMatrixEntry {
  const UserGeofenceMatrixEntry({
    required this.vehicleId,
    required this.geofenceId,
    this.enabled = false,
  });

  final int vehicleId;
  final int geofenceId;
  final bool enabled;

  factory UserGeofenceMatrixEntry.fromJson(dynamic json) {
    final map = _asMap(json);
    return UserGeofenceMatrixEntry(
      vehicleId: _asInt(map['vehicleId']),
      geofenceId: _asInt(map['geofenceId']),
      enabled: _asBool(map['enabled']),
    );
  }

  UserGeofenceMatrixEntry copyWith({
    int? vehicleId,
    int? geofenceId,
    bool? enabled,
  }) {
    return UserGeofenceMatrixEntry(
      vehicleId: vehicleId ?? this.vehicleId,
      geofenceId: geofenceId ?? this.geofenceId,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toSaveJson() {
    return <String, dynamic>{
      'vehicleId': vehicleId,
      'geofenceId': geofenceId,
      'enabled': enabled,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is UserGeofenceMatrixEntry &&
        other.vehicleId == vehicleId &&
        other.geofenceId == geofenceId &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(vehicleId, geofenceId, enabled);
}

class UserNotificationPreferences {
  const UserNotificationPreferences({
    this.channels = const UserNotificationChannels(),
    this.vehicles = const <UserNotificationVehicle>[],
    this.basic = const <UserBasicNotificationRow>[],
    this.overspeed = const <UserOverspeedNotificationRow>[],
    this.geofences = const <UserNotificationGeofence>[],
    this.geofenceMatrix = const <UserGeofenceMatrixEntry>[],
  });

  final UserNotificationChannels channels;
  final List<UserNotificationVehicle> vehicles;
  final List<UserBasicNotificationRow> basic;
  final List<UserOverspeedNotificationRow> overspeed;
  final List<UserNotificationGeofence> geofences;
  final List<UserGeofenceMatrixEntry> geofenceMatrix;

  factory UserNotificationPreferences.fromDynamic(dynamic json) {
    final payload = _extractPreferencesPayload(json);

    return UserNotificationPreferences(
      channels: UserNotificationChannels.fromJson(payload['channels']),
      vehicles: _asList(payload['vehicles'])
          .map(UserNotificationVehicle.fromJson)
          .where((item) => item.id > 0)
          .toList(growable: false),
      basic: _asList(payload['basic'])
          .map(UserBasicNotificationRow.fromJson)
          .where((item) => item.vehicleId > 0)
          .toList(growable: false),
      overspeed: _asList(payload['overspeed'])
          .map(UserOverspeedNotificationRow.fromJson)
          .where((item) => item.vehicleId > 0)
          .toList(growable: false),
      geofences: _asList(payload['geofences'])
          .map(UserNotificationGeofence.fromJson)
          .where((item) => item.id > 0)
          .toList(growable: false),
      geofenceMatrix: _asList(payload['geofenceMatrix'])
          .map(UserGeofenceMatrixEntry.fromJson)
          .where((item) => item.vehicleId > 0 && item.geofenceId > 0)
          .toList(growable: false),
    );
  }

  UserNotificationPreferences copyWith({
    UserNotificationChannels? channels,
    List<UserNotificationVehicle>? vehicles,
    List<UserBasicNotificationRow>? basic,
    List<UserOverspeedNotificationRow>? overspeed,
    List<UserNotificationGeofence>? geofences,
    List<UserGeofenceMatrixEntry>? geofenceMatrix,
  }) {
    return UserNotificationPreferences(
      channels: channels ?? this.channels,
      vehicles: vehicles ?? this.vehicles,
      basic: basic ?? this.basic,
      overspeed: overspeed ?? this.overspeed,
      geofences: geofences ?? this.geofences,
      geofenceMatrix: geofenceMatrix ?? this.geofenceMatrix,
    );
  }

  Map<String, dynamic> toSavePayload() {
    return <String, dynamic>{
      'channels': channels.toSaveJson(),
      'basic': basic.map((item) => item.toSaveJson()).toList(growable: false),
      'overspeed':
          overspeed.map((item) => item.toSaveJson()).toList(growable: false),
      // Backend expects this key to be `geofences` for matrix updates.
      'geofences': geofenceMatrix
          .map((item) => item.toSaveJson())
          .toList(growable: false),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is UserNotificationPreferences &&
        other.channels == channels &&
        listEquals(other.vehicles, vehicles) &&
        listEquals(other.basic, basic) &&
        listEquals(other.overspeed, overspeed) &&
        listEquals(other.geofences, geofences) &&
        listEquals(other.geofenceMatrix, geofenceMatrix);
  }

  @override
  int get hashCode {
    return Object.hash(
      channels,
      Object.hashAll(vehicles),
      Object.hashAll(basic),
      Object.hashAll(overspeed),
      Object.hashAll(geofences),
      Object.hashAll(geofenceMatrix),
    );
  }
}

const Object _unset = Object();

Map<String, dynamic> _extractPreferencesPayload(dynamic source) {
  final root = _asMap(source);
  if (root.isEmpty) {
    return const <String, dynamic>{};
  }

  if (_looksLikePreferencesPayload(root)) {
    return root;
  }

  for (final key in const ['data', 'payload', 'result', 'response']) {
    final nested = _asMap(root[key]);
    if (nested.isEmpty || identical(nested, root)) {
      continue;
    }

    final resolved = _extractPreferencesPayload(nested);
    if (resolved.isNotEmpty || _looksLikePreferencesPayload(nested)) {
      return resolved;
    }
  }

  return root;
}

bool _looksLikePreferencesPayload(Map<String, dynamic> map) {
  return map.containsKey('channels') ||
      map.containsKey('vehicles') ||
      map.containsKey('basic') ||
      map.containsKey('overspeed') ||
      map.containsKey('geofences') ||
      map.containsKey('geofenceMatrix');
}

dynamic _firstByKeys(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map.containsKey(key)) {
      return map[key];
    }
  }
  return null;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  return const <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

String _asString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }

  return 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  final parsed = _asInt(value);
  if (value is String && parsed == 0 && value.trim() != '0') {
    return null;
  }
  return parsed;
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return false;
  }

  switch (normalized) {
    case '1':
    case 'true':
    case 'yes':
    case 'on':
      return true;
    default:
      return false;
  }
}
