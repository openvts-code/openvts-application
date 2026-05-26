import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/models/notification_page.dart';
import '../../superadmin/services/superadmin_map_events_service.dart';
import '../models/live_map_role_config.dart';

/// Role-aware map alert/event feed.
///
/// Delegates parsing to the proven [SuperadminMapEventsService] but uses
/// [LiveMapRoleConfig.mapEventsEndpoint] so admin/user maps hit their own
/// `/admin/map-events` or `/user/map-events` route instead of leaking into
/// the superadmin scope.
class LiveMapEventsService {
  LiveMapEventsService({
    required ApiClient apiClient,
    required LiveMapRoleConfig config,
  })  : _apiClient = apiClient,
        _config = config,
        _parsers = SuperadminMapEventsService(apiClient);

  final ApiClient _apiClient;
  final LiveMapRoleConfig _config;
  final SuperadminMapEventsService _parsers;

  Future<NotificationPage> getMapEvents({
    int limit = 50,
    String? beforeId,
    String? from,
    String? to,
    String? source,
    String? severity,
  }) async {
    if (AppConfig.useMockData) {
      return _parsers.getMapEvents(
        limit: limit,
        beforeId: beforeId,
        from: from,
        to: to,
        source: source,
        severity: severity,
      );
    }

    final response = await _apiClient.get<NotificationPage>(
      _config.mapEventsEndpoint,
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
      parser: (json) => _parsers.parseMapEventsPagePayload(
        json,
        requestedLimit: limit,
      ),
    );

    return response.data;
  }

  AppNotification? parseMapEventPayload(dynamic payload) {
    return _parsers.parseMapEventPayload(payload);
  }
}
