import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/models/notification_page.dart';

class SuperadminMapEventsService {
  SuperadminMapEventsService(this._apiClient);

  final ApiClient _apiClient;

  Future<NotificationPage> getMapEvents({
    int limit = 50,
    String? beforeId,
    String? from,
    String? to,
    String? source,
    String? severity,
  }) async {
    if (AppConfig.useMockData) {
      return _buildMockPage(limit: limit);
    }

    final response = await _apiClient.get<NotificationPage>(
      ApiEndpoints.superadmin.mapEvents,
      queryParameters: <String, dynamic>{
        'limit': limit.toString(),
        if (beforeId != null && beforeId.trim().isNotEmpty)
          'beforeId': beforeId.trim(),
        if (from != null && from.trim().isNotEmpty) 'from': from.trim(),
        if (to != null && to.trim().isNotEmpty) 'to': to.trim(),
        if (source != null && source.trim().isNotEmpty) 'source': source.trim(),
        if (severity != null && severity.trim().isNotEmpty)
          'severity': severity.trim(),
      },
      parser: (json) => _parseMapEventsPage(
        json,
        requestedLimit: limit,
      ),
    );

    return response.data;
  }

  AppNotification? parseMapEventPayload(dynamic payload) {
    for (final source in _mapEventPayloadCandidates(payload)) {
      final event = AppNotification.fromJson(source);
      if (_isMeaningfulMapEvent(event)) {
        return event;
      }
    }

    return null;
  }

  NotificationPage parseMapEventsPagePayload(
    dynamic json, {
    required int requestedLimit,
  }) {
    return _parseMapEventsPage(json, requestedLimit: requestedLimit);
  }

  NotificationPage _buildMockPage({required int limit}) {
    final now = DateTime.now();
    final items = <AppNotification>[
      AppNotification(
        id: 9403,
        title: 'Overspeed',
        message: 'Vehicle TRK-204 crossed the configured speed threshold.',
        isRead: false,
        category: 'OVERSPEED',
        contextLabel: 'TRK-204',
        createdAt: now.subtract(const Duration(minutes: 4)),
        severity: 'CRITICAL',
      ),
      AppNotification(
        id: 9402,
        title: 'Geofence',
        message: 'VAN-88 exited the South Yard geofence.',
        isRead: false,
        category: 'GEOFENCE',
        contextLabel: 'VAN-88',
        createdAt: now.subtract(const Duration(minutes: 17)),
        severity: 'WARNING',
      ),
      AppNotification(
        id: 9401,
        title: 'Ignition',
        message: 'Ignition turned on for BX-110.',
        isRead: false,
        category: 'IGNITION',
        contextLabel: 'BX-110',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 6)),
        severity: 'INFO',
      ),
    ];

    final visibleItems = items.take(limit).toList(growable: false);
    return NotificationPage(
      items: visibleItems,
      hasMore: items.length > limit,
      nextBeforeId: items.length > limit && visibleItems.isNotEmpty
          ? visibleItems.last.id
          : null,
    );
  }

  NotificationPage _parseMapEventsPage(
    dynamic json, {
    required int requestedLimit,
  }) {
    final page = NotificationPage.fromDynamic(
      _normalizeMapEventsPayload(json),
      requestedLimit: requestedLimit,
    );

    return NotificationPage(
      items: page.items.where(_isMeaningfulMapEvent).toList(growable: false),
      hasMore: page.hasMore,
      nextBeforeId: page.nextBeforeId,
      unreadCount: page.unreadCount,
    );
  }

  dynamic _normalizeMapEventsPayload(dynamic source) {
    if (source is List) {
      return source;
    }

    final root = _asMap(source);
    if (root == null || root.isEmpty) {
      return source;
    }

    final normalized = <String, dynamic>{
      for (final entry in root.entries)
        entry.key: _normalizeMapEventsPayload(entry.value),
    };

    if (!normalized.containsKey('items')) {
      for (final key in const [
        'events',
        'mapEvents',
        'map_events',
        'alerts',
        'logs',
      ]) {
        final candidate = normalized[key];
        if (candidate is List) {
          normalized['items'] = candidate;
          break;
        }
      }
    }

    return normalized;
  }

  bool _isMeaningfulMapEvent(AppNotification event) {
    final title = event.title.trim().toLowerCase();
    final message = event.message.trim().toLowerCase();
    return event.id > 0 ||
        event.eventId != null ||
        event.readId != null ||
        event.logId != null ||
        (event.dedupeKey?.trim().isNotEmpty ?? false) ||
        event.contextLabel != null ||
        title != 'notification' ||
        message != 'openvts sent a new update.';
  }

  List<Map<String, dynamic>> _mapEventPayloadCandidates(dynamic payload) {
    final direct = _asMap(payload);
    if (direct == null || direct.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final candidates = <Map<String, dynamic>>[];
    final seen = <Map<String, dynamic>>{};

    void addCandidate(dynamic value) {
      final map = _asMap(value);
      if (map == null || map.isEmpty || seen.contains(map)) {
        return;
      }

      seen.add(map);
      candidates.add(map);
    }

    addCandidate(direct);
    for (final key in const [
      'item',
      'event',
      'mapEvent',
      'map_event',
      'notification',
      'payload',
      'data',
    ]) {
      addCandidate(direct[key]);
    }

    final data = _asMap(direct['data']);
    if (data != null) {
      for (final key in const [
        'item',
        'event',
        'mapEvent',
        'map_event',
        'notification',
        'payload',
        'data',
      ]) {
        addCandidate(data[key]);
      }
    }

    return candidates;
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
}
