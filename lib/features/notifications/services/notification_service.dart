import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_constants.dart';
import '../models/app_notification.dart';
import '../models/notification_page.dart';

abstract class NotificationService {
  NotificationService(this._apiClient);

  final ApiClient _apiClient;
  final Set<int> _mockReadIds = <int>{};

  String get listEndpoint;
  String notificationReadEndpoint(int id);
  String get readAllEndpoint;
  String get roleLabel;

  Future<NotificationPage> getNotifications({
    int limit = AppConstants.defaultPageSize,
    int? beforeId,
    bool unreadOnly = false,
    String? category,
  }) async {
    if (AppConfig.useMockData) {
      return _buildMockPage(
        limit: limit,
        beforeId: beforeId,
        unreadOnly: unreadOnly,
        category: category,
      );
    }

    final response = await _apiClient.get<NotificationPage>(
      listEndpoint,
      queryParameters: <String, dynamic>{
        'limit': limit.toString(),
        if (beforeId != null) 'beforeId': beforeId.toString(),
        if (unreadOnly) 'unreadOnly': 'true',
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
      },
      parser: (json) => NotificationPage.fromDynamic(
        json,
        requestedLimit: limit,
      ),
    );

    return response.data;
  }

  Future<int> getUnreadCount() async {
    if (AppConfig.useMockData) {
      return _buildMockNotifications().where((item) => !item.isRead).length;
    }

    const batchLimit = 100;
    final firstPage = await getNotifications(
      limit: batchLimit,
      unreadOnly: true,
    );

    if (firstPage.unreadCount != null) {
      return firstPage.unreadCount!;
    }

    var total = firstPage.items.length;
    var hasMore = firstPage.hasMore;
    var nextBeforeId = firstPage.nextBeforeId;

    while (hasMore && nextBeforeId != null) {
      final page = await getNotifications(
        limit: batchLimit,
        beforeId: nextBeforeId,
        unreadOnly: true,
      );
      total += page.items.length;
      hasMore = page.hasMore;
      nextBeforeId = page.nextBeforeId;
    }

    return total;
  }

  Future<void> markAsRead(int id) async {
    if (AppConfig.useMockData) {
      _mockReadIds.add(id);
      return;
    }

    if (id <= 0) {
      throw Exception('This notification cannot be marked as read yet.');
    }

    await _apiClient.patch<bool>(
      notificationReadEndpoint(id),
      data: const <String, dynamic>{},
      parser: (_) => true,
    );
  }

  Future<void> markAllAsRead() async {
    if (AppConfig.useMockData) {
      for (final notification in _buildMockNotifications()) {
        _mockReadIds.add(notification.id);
      }
      return;
    }

    await _apiClient.patch<bool>(
      readAllEndpoint,
      data: const <String, dynamic>{},
      parser: (_) => true,
    );
  }

  NotificationPage _buildMockPage({
    required int limit,
    int? beforeId,
    required bool unreadOnly,
    String? category,
  }) {
    var notifications = _buildMockNotifications();
    final normalizedCategory = _normalizeCategory(category);

    if (normalizedCategory != null) {
      notifications = notifications
          .where(
            (item) => _normalizeCategory(item.category) == normalizedCategory,
          )
          .toList(growable: false);
    }

    if (unreadOnly) {
      notifications = notifications
          .where((item) => !item.isRead)
          .toList(growable: false);
    }

    if (beforeId != null) {
      notifications = notifications
          .where((item) => item.id < beforeId)
          .toList(growable: false);
    }

    final unreadCount = _buildMockNotifications().where((item) => !item.isRead).length;
    final hasMore = notifications.length > limit;
    final pageItems = notifications.take(limit).toList(growable: false);

    return NotificationPage(
      items: pageItems,
      unreadCount: unreadCount,
      hasMore: hasMore,
      nextBeforeId: hasMore && pageItems.isNotEmpty ? pageItems.last.id : null,
    );
  }

  List<AppNotification> _buildMockNotifications() {
    final now = DateTime.now();
    final notifications = <AppNotification>[
      AppNotification(
        id: 620,
        title: '$roleLabel alert acknowledged',
        message: 'Daily monitoring summary is ready for review.',
        isRead: true,
        category: 'System',
        contextLabel: 'Operations summary',
        createdAt: now.subtract(const Duration(minutes: 6)),
        readAt: now.subtract(const Duration(minutes: 2)),
        severity: 'info',
      ),
      AppNotification(
        id: 619,
        title: 'Engine idle threshold reached',
        message: 'Vehicle TRK-204 has been idle for 18 minutes.',
        isRead: false,
        category: 'Vehicle',
        contextLabel: 'TRK-204',
        createdAt: now.subtract(const Duration(minutes: 18)),
        severity: 'warning',
      ),
      AppNotification(
        id: 618,
        title: 'Geofence exit detected',
        message: 'Unit VAN-88 exited the South Yard geofence.',
        isRead: false,
        category: 'Security',
        contextLabel: 'VAN-88',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 14)),
        severity: 'warning',
      ),
      AppNotification(
        id: 617,
        title: 'Live telemetry restored',
        message: 'Tracker 359881234567890 is reporting again after a brief outage.',
        isRead: false,
        category: 'Connectivity',
        contextLabel: '359881234567890',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 8)),
        severity: 'info',
      ),
      AppNotification(
        id: 616,
        title: 'Overspeed event',
        message: 'Vehicle BX-110 crossed the configured 90 km/h threshold.',
        isRead: true,
        category: 'Vehicle',
        contextLabel: 'BX-110',
        createdAt: now.subtract(const Duration(hours: 8, minutes: 25)),
        readAt: now.subtract(const Duration(hours: 8, minutes: 12)),
        severity: 'critical',
      ),
      AppNotification(
        id: 615,
        title: 'Maintenance reminder',
        message: 'Vehicle TRK-117 is due for scheduled service in 120 km.',
        isRead: false,
        category: 'Maintenance',
        contextLabel: 'TRK-117',
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
        severity: 'info',
      ),
    ];

    return notifications
        .map((item) {
          if (!_mockReadIds.contains(item.id)) {
            return item;
          }

          return item.copyWith(
            isRead: true,
            readAt: item.readAt ?? now,
          );
        })
        .toList(growable: false)
      ..sort((left, right) => right.id.compareTo(left.id));
  }

  String? _normalizeCategory(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
