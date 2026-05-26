import 'dart:convert';

enum AdminLogsTab { activity, vehicle, telemetry }

enum AdminVehicleSeverity { info, warning, critical }

enum AdminReadFilter { all, read, unread }

enum AdminTelemetryPacketType { location, history, event, unknown }

class AdminLogsOptions {
  const AdminLogsOptions({
    required this.users,
    required this.vehicles,
    required this.sources,
    required this.packetTypes,
  });

  final List<AdminLogsUserOption> users;
  final List<AdminLogsVehicleOption> vehicles;
  final List<String> sources;
  final List<String> packetTypes;

  factory AdminLogsOptions.empty() => const AdminLogsOptions(
      users: <AdminLogsUserOption>[],
      vehicles: <AdminLogsVehicleOption>[],
      sources: <String>[],
      packetTypes: <String>[]);

  factory AdminLogsOptions.fromJson(dynamic json) {
    final source = _asMap(_extractSingle(json));
    return AdminLogsOptions(
      users: (_firstList(source, const ['users']) ?? const <dynamic>[])
          .map(AdminLogsUserOption.fromJson)
          .toList(growable: false),
      vehicles: (_firstList(source, const ['vehicles']) ?? const <dynamic>[])
          .map(AdminLogsVehicleOption.fromJson)
          .toList(growable: false),
      sources: (_firstList(source, const ['sources']) ?? const <dynamic>[])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      packetTypes: (_firstList(source, const ['packetTypes', 'packet_types']) ??
              const <dynamic>[])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class AdminLogsUserOption {
  const AdminLogsUserOption({
    required this.uid,
    required this.name,
    required this.username,
    required this.loginType,
  });

  final String uid;
  final String name;
  final String username;
  final String loginType;

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    if (username.trim().isNotEmpty) return username.trim();
    return uid;
  }

  factory AdminLogsUserOption.fromJson(dynamic json) {
    final m = _asMap(json);
    return AdminLogsUserOption(
      uid: (_firstValue(m, const ['uid', 'id', '_id', 'userId', 'user_id']) ??
              '')
          .toString(),
      name: _firstString(m, const ['name', 'fullName', 'full_name']) ?? '',
      username:
          _firstString(m, const ['username', 'userName', 'user_name']) ?? '',
      loginType:
          _firstString(m, const ['loginType', 'login_type', 'role']) ?? '',
    );
  }
}

class AdminLogsVehicleOption {
  const AdminLogsVehicleOption({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.imei,
  });

  final String id;
  final String name;
  final String plateNumber;
  final String imei;

  String get displayName {
    final base = name.trim().isNotEmpty ? name.trim() : 'Vehicle $id';
    final plate = plateNumber.trim();
    return plate.isNotEmpty ? '$base ($plate)' : base;
  }

  factory AdminLogsVehicleOption.fromJson(dynamic json) {
    final m = _asMap(json);
    return AdminLogsVehicleOption(
      id: (_firstValue(m, const ['id', '_id', 'vehicleId', 'vehicle_id']) ?? '')
          .toString(),
      name:
          _firstString(m, const ['name', 'vehicleName', 'vehicle_name']) ?? '',
      plateNumber: _firstString(m, const ['plateNumber', 'plate_number']) ?? '',
      imei: _firstString(m, const ['imei']) ?? '',
    );
  }
}

class AdminActivityLogItem {
  const AdminActivityLogItem({
    required this.id,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.meta,
    required this.ip,
    required this.browser,
    required this.platform,
    required this.createdAt,
    required this.userUid,
    required this.userName,
    required this.userUsername,
    required this.userLoginType,
  });

  final String id;
  final String action;
  final String entity;
  final String entityId;
  final Map<String, dynamic> meta;
  final String ip;
  final String browser;
  final String platform;
  final DateTime? createdAt;
  final String userUid;
  final String userName;
  final String userUsername;
  final String userLoginType;

  String get actorDisplay {
    if (userName.trim().isNotEmpty) return userName.trim();
    if (userUsername.trim().isNotEmpty) return userUsername.trim();
    return userUid.trim().isNotEmpty ? userUid : '-';
  }

  String get humanAction {
    final s = action.trim();
    if (s.isEmpty) return '-';
    return s
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  factory AdminActivityLogItem.fromJson(dynamic json) {
    final m = _asMap(json);
    final user = _firstMap(m, const ['user']) ?? const <String, dynamic>{};
    return AdminActivityLogItem(
      id: (_firstValue(m, const ['id', '_id', 'logId', 'log_id']) ?? '')
          .toString(),
      action: _firstString(m, const ['action']) ?? '',
      entity: _firstString(m, const ['entity']) ?? '',
      entityId:
          (_firstValue(m, const ['entityId', 'entity_id']) ?? '').toString(),
      meta: _asMap(_firstValue(m, const ['meta', 'metadata'])),
      ip: _firstString(m, const ['ip', 'ipAddress', 'ip_address']) ?? '',
      browser: _firstString(m, const ['browser']) ?? '',
      platform: _firstString(m, const ['platform']) ?? '',
      createdAt: _firstDate(m, const ['createdAt', 'created_at']),
      userUid: (_firstValue(user, const ['uid', 'id', '_id']) ?? '').toString(),
      userName:
          _firstString(user, const ['name', 'fullName', 'full_name']) ?? '',
      userUsername:
          _firstString(user, const ['username', 'userName', 'user_name']) ?? '',
      userLoginType:
          _firstString(user, const ['loginType', 'login_type']) ?? '',
    );
  }
}

class AdminActivityLogPage {
  const AdminActivityLogPage({
    required this.items,
    required this.nextCursorId,
    required this.hasMore,
  });

  final List<AdminActivityLogItem> items;
  final String? nextCursorId;
  final bool hasMore;

  factory AdminActivityLogPage.fromJson(dynamic json) {
    final source = _asMap(_extractSingle(json));
    final itemsRaw =
        _extractItems(json, preferredKeys: const ['items', 'logs']);
    return AdminActivityLogPage(
      items:
          itemsRaw.map(AdminActivityLogItem.fromJson).toList(growable: false),
      nextCursorId: _firstString(source,
          const ['nextCursorId', 'next_cursor_id', 'cursorId', 'cursor_id']),
      hasMore: _firstBool(source, const ['hasMore', 'has_more']) ??
          (_firstString(source, const [
                'nextCursorId',
                'next_cursor_id',
                'cursorId',
                'cursor_id'
              ])?.isNotEmpty ==
              true),
    );
  }
}

class AdminVehicleEventLogItem {
  const AdminVehicleEventLogItem({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.plateNumber,
    required this.imei,
    required this.userId,
    required this.userName,
    required this.source,
    required this.severity,
    required this.title,
    required this.message,
    required this.meta,
    required this.isRead,
    required this.createdAt,
    required this.dedupeKey,
  });

  final String id;
  final String vehicleId;
  final String vehicleName;
  final String plateNumber;
  final String imei;
  final String userId;
  final String userName;
  final String source;
  final String severity;
  final String title;
  final String message;
  final Map<String, dynamic> meta;
  final bool isRead;
  final DateTime? createdAt;
  final String dedupeKey;

  factory AdminVehicleEventLogItem.fromJson(dynamic json) {
    final m = _asMap(json);
    return AdminVehicleEventLogItem(
      id: (_firstValue(m, const ['id', '_id', 'eventId', 'event_id']) ?? '')
          .toString(),
      vehicleId:
          (_firstValue(m, const ['vehicleId', 'vehicle_id']) ?? '').toString(),
      vehicleName:
          _firstString(m, const ['vehicleName', 'vehicle_name', 'name']) ?? '',
      plateNumber: _firstString(m, const ['plateNumber', 'plate_number']) ?? '',
      imei: _firstString(m, const ['imei']) ?? '',
      userId: (_firstValue(m, const ['userId', 'user_id']) ?? '').toString(),
      userName:
          _firstString(m, const ['userName', 'user_name', 'username']) ?? '',
      source: _firstString(m, const ['source']) ?? '',
      severity: (_firstString(m, const ['severity']) ?? 'INFO').toUpperCase(),
      title: _firstString(m, const ['title']) ?? '',
      message: _firstString(m, const ['message']) ?? '',
      meta: _asMap(_firstValue(m, const ['meta', 'metadata'])),
      isRead: _firstBool(m, const ['isRead', 'is_read']) ?? false,
      createdAt: _firstDate(m, const ['createdAt', 'created_at']),
      dedupeKey: _firstString(m, const ['dedupeKey', 'dedupe_key']) ?? '',
    );
  }
}

class AdminVehicleEventLogPage {
  const AdminVehicleEventLogPage(
      {required this.items, required this.nextCursorId});

  final List<AdminVehicleEventLogItem> items;
  final String? nextCursorId;

  factory AdminVehicleEventLogPage.fromJson(dynamic json) {
    final source = _asMap(_extractSingle(json));
    final itemsRaw =
        _extractItems(json, preferredKeys: const ['items', 'events']);
    return AdminVehicleEventLogPage(
      items: itemsRaw
          .map(AdminVehicleEventLogItem.fromJson)
          .toList(growable: false),
      nextCursorId: _firstString(source,
          const ['nextCursorId', 'next_cursor_id', 'cursorId', 'cursor_id']),
    );
  }
}

class AdminVehicleEventDelivery {
  const AdminVehicleEventDelivery({
    required this.channel,
    required this.status,
    required this.sentAt,
    required this.deliveredAt,
    required this.failureReason,
    required this.retryCount,
    required this.createdAt,
  });

  final String channel;
  final String status;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final String failureReason;
  final int retryCount;
  final DateTime? createdAt;

  factory AdminVehicleEventDelivery.fromJson(dynamic json) {
    final m = _asMap(json);
    return AdminVehicleEventDelivery(
      channel: _firstString(m, const ['channel']) ?? '',
      status: _firstString(m, const ['status']) ?? '',
      sentAt: _firstDate(m, const ['sentAt', 'sent_at']),
      deliveredAt: _firstDate(m, const ['deliveredAt', 'delivered_at']),
      failureReason:
          _firstString(m, const ['failureReason', 'failure_reason']) ?? '',
      retryCount: _firstInt(m, const ['retryCount', 'retry_count']) ?? 0,
      createdAt: _firstDate(m, const ['createdAt', 'created_at']),
    );
  }
}

class AdminVehicleEventDetail {
  const AdminVehicleEventDetail({
    required this.id,
    required this.title,
    required this.message,
    required this.source,
    required this.isRead,
    required this.createdAt,
    required this.meta,
    required this.vehicleName,
    required this.plateNumber,
    required this.imei,
    required this.userName,
    required this.userUsername,
    required this.deliveries,
  });

  final String id;
  final String title;
  final String message;
  final String source;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> meta;
  final String vehicleName;
  final String plateNumber;
  final String imei;
  final String userName;
  final String userUsername;
  final List<AdminVehicleEventDelivery> deliveries;

  factory AdminVehicleEventDetail.fromJson(dynamic json) {
    final m = _asMap(_extractSingle(json));
    final vehicle =
        _firstMap(m, const ['vehicle']) ?? const <String, dynamic>{};
    final user = _firstMap(m, const ['user']) ?? const <String, dynamic>{};
    final deliveriesRaw =
        _firstList(m, const ['deliveries']) ?? const <dynamic>[];
    return AdminVehicleEventDetail(
      id: (_firstValue(m, const ['id', '_id']) ?? '').toString(),
      title: _firstString(m, const ['title']) ?? '',
      message: _firstString(m, const ['message']) ?? '',
      source: _firstString(m, const ['source']) ?? '',
      isRead: _firstBool(m, const ['isRead', 'is_read']) ?? false,
      createdAt: _firstDate(m, const ['createdAt', 'created_at']),
      meta: _asMap(_firstValue(m, const ['meta', 'metadata'])),
      vehicleName: _firstString(vehicle, const ['name', 'vehicleName']) ??
          _firstString(m, const ['vehicleName']) ??
          '',
      plateNumber:
          _firstString(vehicle, const ['plateNumber', 'plate_number']) ??
              _firstString(m, const ['plateNumber']) ??
              '',
      imei: _firstString(vehicle, const ['imei']) ??
          _firstString(m, const ['imei']) ??
          '',
      userName: _firstString(user, const ['name']) ??
          _firstString(m, const ['userName']) ??
          '',
      userUsername: _firstString(user, const ['username']) ?? '',
      deliveries: deliveriesRaw
          .map(AdminVehicleEventDelivery.fromJson)
          .toList(growable: false),
    );
  }
}

class AdminTelemetryLogItem {
  const AdminTelemetryLogItem({
    required this.id,
    required this.imei,
    required this.protocol,
    required this.packetType,
    required this.deviceTime,
    required this.serverTime,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speedKph,
    required this.course,
    required this.satellites,
    required this.acc,
    required this.ignition,
    required this.valid,
    required this.raw,
    required this.attributes,
    required this.distance,
    required this.engineHours,
    required this.odometer,
    required this.totalEngineHours,
    required this.createdAt,
  });

  final String id;
  final String imei;
  final String protocol;
  final String packetType;
  final DateTime? deviceTime;
  final DateTime? serverTime;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? speedKph;
  final double? course;
  final int? satellites;
  final bool? acc;
  final bool? ignition;
  final bool? valid;
  final String raw;
  final Map<String, dynamic> attributes;
  final double? distance;
  final double? engineHours;
  final double? odometer;
  final double? totalEngineHours;
  final DateTime? createdAt;

  factory AdminTelemetryLogItem.fromJson(dynamic json) {
    final m = _asMap(json);
    return AdminTelemetryLogItem(
      id: (_firstValue(m, const ['id', '_id']) ?? '').toString(),
      imei: _firstString(m, const ['imei']) ?? '',
      protocol: _firstString(m, const ['protocol']) ?? '',
      packetType:
          (_firstString(m, const ['packetType', 'packet_type']) ?? 'UNKNOWN')
              .toUpperCase(),
      deviceTime: _firstDate(m, const ['deviceTime', 'device_time']),
      serverTime: _firstDate(m, const ['serverTime', 'server_time']),
      latitude: _firstDouble(m, const ['latitude', 'lat']),
      longitude: _firstDouble(m, const ['longitude', 'lng', 'lon']),
      altitude: _firstDouble(m, const ['altitude']),
      speedKph: _firstDouble(m, const ['speedKph', 'speed_kph', 'speed']),
      course: _firstDouble(m, const ['course']),
      satellites: _firstInt(m, const ['satellites']),
      acc: _firstBool(m, const ['acc']),
      ignition: _firstBool(m, const ['ignition']),
      valid: _firstBool(m, const ['valid']),
      raw: _firstString(m, const ['raw']) ?? '',
      attributes: _asMap(_firstValue(m, const ['attributes', 'attrs'])),
      distance: _firstDouble(m, const ['distance']),
      engineHours: _firstDouble(m, const ['engineHours', 'engine_hours']),
      odometer: _firstDouble(m, const ['odometer']),
      totalEngineHours:
          _firstDouble(m, const ['totalengineHours', 'totalEngineHours']),
      createdAt: _firstDate(m, const ['createdAt', 'created_at']),
    );
  }
}

class AdminTelemetryLogPage {
  const AdminTelemetryLogPage({required this.items, required this.nextCursor});

  final List<AdminTelemetryLogItem> items;
  final String? nextCursor;

  factory AdminTelemetryLogPage.fromJson(dynamic json) {
    final source = _asMap(_extractSingle(json));
    final itemsRaw =
        _extractItems(json, preferredKeys: const ['items', 'telemetry']);
    return AdminTelemetryLogPage(
      items:
          itemsRaw.map(AdminTelemetryLogItem.fromJson).toList(growable: false),
      nextCursor:
          _firstString(source, const ['nextCursor', 'next_cursor', 'cursor']),
    );
  }
}

class AdminTelemetryDetail {
  const AdminTelemetryDetail({required this.item});

  final AdminTelemetryLogItem item;

  factory AdminTelemetryDetail.fromJson(dynamic json) {
    return AdminTelemetryDetail(
        item: AdminTelemetryLogItem.fromJson(_extractSingle(json)));
  }
}

String prettyJson(Object? value) {
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value?.toString() ?? '{}';
  }
}

List<dynamic> _extractItems(dynamic json,
    {List<String> preferredKeys = const ['items']}) {
  if (json is List) return json;
  final root = _asMap(json);
  final single = _asMap(_extractSingle(json));

  for (final key in preferredKeys) {
    final v = single[key] ?? root[key];
    if (v is List) return v;
  }

  for (final key in const ['data', 'rows', 'logs', 'events']) {
    final v = single[key] ?? root[key];
    if (v is List) return v;
  }

  return const <dynamic>[];
}

dynamic _extractSingle(dynamic json) {
  if (json is! Map) return json;
  dynamic current = json;
  for (var i = 0; i < 4; i++) {
    final map = _asMap(current);
    final data = map['data'];
    if (data is Map) {
      current = data;
      continue;
    }
    return map;
  }
  return current;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return const <String, dynamic>{};
}

String? _firstString(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (source.containsKey(key)) return source[key];
  }
  return null;
}

int? _firstInt(Map<String, dynamic> source, List<String> keys) {
  final v = _firstValue(source, keys);
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double? _firstDouble(Map<String, dynamic> source, List<String> keys) {
  final v = _firstValue(source, keys);
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

bool? _firstBool(Map<String, dynamic> source, List<String> keys) {
  final v = _firstValue(source, keys);
  if (v == null) return null;
  if (v is bool) return v;
  final t = v.toString().trim().toLowerCase();
  if (t == 'true' || t == '1' || t == 'yes') return true;
  if (t == 'false' || t == '0' || t == 'no') return false;
  return null;
}

DateTime? _firstDate(Map<String, dynamic> source, List<String> keys) {
  final v = _firstValue(source, keys);
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) {
    if (v <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(v);
  }
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t);
  }
  return null;
}

Map<String, dynamic>? _firstMap(
    Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final m = _asMap(source[key]);
    if (m.isNotEmpty) return m;
  }
  return null;
}

List<dynamic>? _firstList(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final v = source[key];
    if (v is List) return v;
  }
  return null;
}
