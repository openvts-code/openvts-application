class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.category,
    this.contextLabel,
    this.vehicleImei,
    this.createdAt,
    this.readAt,
    this.severity,
    this.eventId,
    this.readId,
    this.logId,
    this.notificationId,
    this.dedupeKey,
    this.metadata = const <String, dynamic>{},
  });

  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String? category;
  final String? contextLabel;
  final String? vehicleImei;
  final DateTime? createdAt;
  final DateTime? readAt;
  final String? severity;
  final int? eventId;
  final int? readId;
  final int? logId;
  final int? notificationId;
  final String? dedupeKey;
  final Map<String, dynamic> metadata;

  String get dedupeIdentity {
    if (id > 0) {
      return 'id:$id';
    }

    final explicitDedupeKey = dedupeKey?.trim();
    if (explicitDedupeKey != null && explicitDedupeKey.isNotEmpty) {
      return 'dedupe:${explicitDedupeKey.toLowerCase()}';
    }

    if (eventId != null && eventId! > 0) {
      return 'event:$eventId';
    }
    if (readId != null && readId! > 0) {
      return 'read:$readId';
    }
    if (logId != null && logId! > 0) {
      return 'log:$logId';
    }
    if (notificationId != null && notificationId! > 0) {
      return 'notification:$notificationId';
    }

    return [
      'fallback',
      title.trim(),
      message.trim(),
      category?.trim() ?? '',
      vehicleImei?.trim() ?? '',
      createdAt?.toUtc().toIso8601String() ?? '',
    ].join(':').toLowerCase();
  }

  int get sortMilliseconds {
    return createdAt?.toUtc().millisecondsSinceEpoch ?? 0;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final vehicle = _asMap(json['vehicle']);
    final associate = _asMap(json['associate']);
    final notification = _asMap(json['notification']);
    final payload = _asMap(json['payload']);
    final data = _asMap(json['data']);
    final metadata = _asMap(json['metadata']) ??
        _asMap(json['meta']) ??
        payload ??
        data ??
        const <String, dynamic>{};
    final metadataVehicle = _asMap(metadata['vehicle']);
    final payloadVehicle = _asMap(payload?['vehicle']);
    final dataVehicle = _asMap(data?['vehicle']);
    final notificationVehicle = _asMap(notification?['vehicle']);
    final readAt = _asDateTime(json['readAt']) ??
        _asDateTime(json['read_at']) ??
        _asDateTime(json['seenAt']) ??
        _asDateTime(json['seen_at']);
    final readId = _asInt(json['readId']) ??
        _asInt(json['read_id']) ??
        _asInt(json['userNotificationId']) ??
        _asInt(json['user_notification_id']);
    final eventId = _asInt(json['eventId']) ?? _asInt(json['event_id']);
    final logId = _asInt(json['logId']) ?? _asInt(json['log_id']);
    final notificationId = _asInt(json['notificationId']) ??
        _asInt(json['notification_id']) ??
        _asInt(json['notifId']) ??
        _asInt(notification?['id']) ??
        _asInt(notification?['notificationId']) ??
        _asInt(notification?['notification_id']);

    return AppNotification(
      id: readId ??
          eventId ??
          logId ??
          _asInt(json['id']) ??
          notificationId ??
          0,
      title: _firstNonEmpty([
            json['title'],
            json['heading'],
            json['subject'],
            json['eventTitle'],
            json['event_title'],
            json['eventName'],
            json['event_name'],
            json['event'],
            json['type'],
            json['source'],
            json['category'],
            notification?['title'],
            notification?['heading'],
            notification?['subject'],
          ]) ??
          'Notification',
      message: _firstNonEmpty([
            json['message'],
            json['body'],
            json['content'],
            json['description'],
            json['details'],
            json['eventMessage'],
            json['event_message'],
            json['summary'],
            json['note'],
            notification?['message'],
            notification?['body'],
            notification?['content'],
            metadata['message'],
            metadata['body'],
          ]) ??
          'OpenVTS sent a new update.',
      isRead: _asBool(json['isRead']) ??
          _asBool(json['is_read']) ??
          _asBool(json['read']) ??
          readAt != null ||
              ((_firstNonEmpty([json['status'], json['state']]) ?? '')
                      .toLowerCase() ==
                  'read'),
      category: _firstNonEmpty([
        json['category'],
        json['type'],
        json['source'],
        json['notificationType'],
        json['notification_type'],
        json['eventType'],
        json['event_type'],
        notification?['category'],
        notification?['type'],
      ]),
      contextLabel: _firstNonEmpty([
        json['vehicleName'],
        json['vehicleLabel'],
        json['vehicle_number'],
        json['vehicleNumber'],
        json['plateNumber'],
        json['plate_number'],
        json['deviceName'],
        json['device_name'],
        json['associateName'],
        json['associate_name'],
        json['imei'],
        vehicle?['name'],
        vehicle?['label'],
        vehicle?['plateNumber'],
        vehicle?['plate_number'],
        associate?['name'],
        associate?['label'],
        metadata['vehicleName'],
        metadata['vehicleLabel'],
        metadata['imei'],
        metadataVehicle?['name'],
        metadataVehicle?['label'],
        metadataVehicle?['plateNumber'],
        metadataVehicle?['plate_number'],
      ]),
      vehicleImei: _firstNonEmpty([
        json['imei'],
        json['vehicleImei'],
        json['vehicle_imei'],
        json['deviceImei'],
        json['device_imei'],
        json['trackerImei'],
        json['tracker_imei'],
        metadata['imei'],
        metadata['vehicleImei'],
        metadata['vehicle_imei'],
        metadata['deviceImei'],
        metadata['device_imei'],
        payload?['imei'],
        payload?['vehicleImei'],
        payload?['vehicle_imei'],
        payload?['deviceImei'],
        payload?['device_imei'],
        data?['imei'],
        data?['vehicleImei'],
        data?['vehicle_imei'],
        data?['deviceImei'],
        data?['device_imei'],
        vehicle?['imei'],
        vehicle?['vehicleImei'],
        vehicle?['deviceImei'],
        vehicle?['device_imei'],
        metadataVehicle?['imei'],
        metadataVehicle?['vehicleImei'],
        metadataVehicle?['deviceImei'],
        payloadVehicle?['imei'],
        payloadVehicle?['vehicleImei'],
        payloadVehicle?['deviceImei'],
        dataVehicle?['imei'],
        dataVehicle?['vehicleImei'],
        dataVehicle?['deviceImei'],
        notificationVehicle?['imei'],
        notificationVehicle?['vehicleImei'],
        notificationVehicle?['deviceImei'],
      ]),
      createdAt: _asDateTime(json['createdAt']) ??
          _asDateTime(json['created_at']) ??
          _asDateTime(json['occurredAt']) ??
          _asDateTime(json['occurred_at']) ??
          _asDateTime(json['eventAt']) ??
          _asDateTime(json['event_at']) ??
          _asDateTime(json['timestamp']) ??
          _asDateTime(json['time']) ??
          _asDateTime(json['date']) ??
          _asDateTime(notification?['createdAt']) ??
          _asDateTime(notification?['created_at']) ??
          _asDateTime(notification?['timestamp']),
      readAt: readAt,
      severity: _firstNonEmpty([
        json['severity'],
        json['level'],
        json['priority'],
        notification?['severity'],
        notification?['level'],
      ]),
      eventId: eventId,
      readId: readId,
      logId: logId,
      notificationId: notificationId,
      dedupeKey: _firstNonEmpty([
        json['dedupeKey'],
        json['dedupe_key'],
        metadata['dedupeKey'],
        metadata['dedupe_key'],
      ]),
      metadata: metadata,
    );
  }

  AppNotification copyWith({
    int? id,
    String? title,
    String? message,
    bool? isRead,
    Object? category = _unset,
    Object? contextLabel = _unset,
    Object? vehicleImei = _unset,
    Object? createdAt = _unset,
    Object? readAt = _unset,
    Object? severity = _unset,
    Object? eventId = _unset,
    Object? readId = _unset,
    Object? logId = _unset,
    Object? notificationId = _unset,
    Object? dedupeKey = _unset,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      category:
          identical(category, _unset) ? this.category : category as String?,
      contextLabel: identical(contextLabel, _unset)
          ? this.contextLabel
          : contextLabel as String?,
      vehicleImei: identical(vehicleImei, _unset)
          ? this.vehicleImei
          : vehicleImei as String?,
      createdAt: identical(createdAt, _unset)
          ? this.createdAt
          : createdAt as DateTime?,
      readAt: identical(readAt, _unset) ? this.readAt : readAt as DateTime?,
      severity:
          identical(severity, _unset) ? this.severity : severity as String?,
      eventId: identical(eventId, _unset) ? this.eventId : eventId as int?,
      readId: identical(readId, _unset) ? this.readId : readId as int?,
      logId: identical(logId, _unset) ? this.logId : logId as int?,
      notificationId: identical(notificationId, _unset)
          ? this.notificationId
          : notificationId as int?,
      dedupeKey:
          identical(dedupeKey, _unset) ? this.dedupeKey : dedupeKey as String?,
      metadata: metadata ?? this.metadata,
    );
  }
}

const Object _unset = Object();

String? _firstNonEmpty(Iterable<dynamic> values) {
  for (final value in values) {
    final normalized = value?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }

  return null;
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '');
}

bool? _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  switch (normalized) {
    case '1':
    case 'true':
    case 'yes':
    case 'read':
      return true;
    case '0':
    case 'false':
    case 'no':
    case 'unread':
      return false;
    default:
      return null;
  }
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  if (value is num) {
    final timestamp = value.toInt();
    if (timestamp <= 0) {
      return null;
    }

    final isMilliseconds = timestamp > 9999999999;
    return DateTime.fromMillisecondsSinceEpoch(
      isMilliseconds ? timestamp : timestamp * 1000,
    );
  }

  return DateTime.tryParse(value.toString());
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, innerValue) => MapEntry(key.toString(), innerValue),
    );
  }

  return null;
}
