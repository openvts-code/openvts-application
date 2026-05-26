import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

class MobilePushMessage {
  const MobilePushMessage({
    this.id,
    this.messageId,
    this.title,
    this.body,
    this.data = const <String, String>{},
    this.type,
    this.category,
    this.notificationId,
    this.route,
    this.vehicleId,
    this.vehicleImei,
    this.createdAt,
  });

  final String? id;
  final String? messageId;
  final String? title;
  final String? body;
  final Map<String, String> data;
  final String? type;
  final String? category;
  final String? notificationId;
  final String? route;
  final String? vehicleId;
  final String? vehicleImei;
  final DateTime? createdAt;

  int get localNotificationId {
    final parsed = int.tryParse(notificationId ?? id ?? messageId ?? '');
    if (parsed != null && parsed > 0) {
      return parsed & 0x7fffffff;
    }

    final source = messageId ??
        id ??
        notificationId ??
        title ??
        body ??
        createdAt?.toUtc().toIso8601String() ??
        'openvts-push';
    return _stablePositiveHash(source);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (messageId != null) 'messageId': messageId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      'data': data,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (notificationId != null) 'notificationId': notificationId,
      if (route != null) 'route': route,
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (vehicleImei != null) 'vehicleImei': vehicleImei,
      if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
    };
  }

  String toLocalNotificationPayload() {
    return jsonEncode(toJson());
  }

  factory MobilePushMessage.fromJson(Map<String, dynamic> json) {
    final data = _normalizeData(json['data']);
    return MobilePushMessage(
      id: _firstNonEmpty([json['id'], data['id']]),
      messageId: _firstNonEmpty([json['messageId'], data['messageId']]),
      title: _firstNonEmpty([json['title'], data['title']]),
      body: _firstNonEmpty([json['body'], data['body']]),
      data: data,
      type: _firstNonEmpty([json['type'], data['type'], data['eventType']]),
      category: _firstNonEmpty([json['category'], data['category']]),
      notificationId: _firstNonEmpty([
        json['notificationId'],
        data['notificationId'],
        data['notification_id'],
      ]),
      route: _firstNonEmpty([json['route'], data['route'], data['path']]),
      vehicleId: _firstNonEmpty([
        json['vehicleId'],
        data['vehicleId'],
        data['vehicle_id'],
      ]),
      vehicleImei: _firstNonEmpty([
        json['vehicleImei'],
        data['vehicleImei'],
        data['vehicle_imei'],
        data['imei'],
      ]),
      createdAt: _asDateTime(json['createdAt']) ??
          _asDateTime(data['createdAt']) ??
          _asDateTime(data['created_at']),
    );
  }
}

class MobilePushMessageMapper {
  const MobilePushMessageMapper._();

  static MobilePushMessage fromRemoteMessage(RemoteMessage message) {
    final data = _normalizeData(message.data);
    final notification = message.notification;
    final createdAt = message.sentTime ??
        _asDateTime(data['createdAt']) ??
        _asDateTime(data['created_at']) ??
        _asDateTime(data['timestamp']);

    return MobilePushMessage(
      id: _firstNonEmpty([
        data['id'],
        data['readId'],
        data['read_id'],
        data['notificationId'],
        data['notification_id'],
        message.messageId,
      ]),
      messageId: message.messageId ?? data['messageId'] ?? data['message_id'],
      title: notification?.title ??
          _firstNonEmpty([
            data['title'],
            data['heading'],
            data['subject'],
          ]),
      body: notification?.body ??
          _firstNonEmpty([
            data['body'],
            data['message'],
            data['content'],
            data['description'],
          ]),
      data: data,
      type: _firstNonEmpty([
        data['type'],
        data['eventType'],
        data['event_type'],
      ]),
      category: _firstNonEmpty([
        data['category'],
        data['source'],
        data['notificationType'],
        data['notification_type'],
      ]),
      notificationId: _firstNonEmpty([
        data['notificationId'],
        data['notification_id'],
        data['readId'],
        data['read_id'],
        data['id'],
      ]),
      route: _firstNonEmpty([
        data['route'],
        data['path'],
        data['deepLink'],
        data['deeplink'],
        data['link'],
      ]),
      vehicleId: _firstNonEmpty([
        data['vehicleId'],
        data['vehicle_id'],
      ]),
      vehicleImei: _firstNonEmpty([
        data['vehicleImei'],
        data['vehicle_imei'],
        data['deviceImei'],
        data['device_imei'],
        data['imei'],
      ]),
      createdAt: createdAt,
    );
  }

  static MobilePushMessage? fromLocalNotificationPayload(String? payload) {
    final normalized = payload?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(normalized);
      if (decoded is Map<String, dynamic>) {
        return MobilePushMessage.fromJson(decoded);
      }
      if (decoded is Map) {
        return MobilePushMessage.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}

Map<String, String> _normalizeData(dynamic value) {
  if (value is Map<String, String>) {
    return Map<String, String>.unmodifiable(value);
  }

  if (value is Map) {
    return Map<String, String>.unmodifiable(
      value.map(
        (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
      ),
    );
  }

  return const <String, String>{};
}

String? _firstNonEmpty(Iterable<dynamic> values) {
  for (final value in values) {
    final normalized = value?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }

  return null;
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

  return DateTime.tryParse(value.toString().trim());
}

int _stablePositiveHash(String source) {
  var hash = 0;
  for (final codeUnit in source.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}
