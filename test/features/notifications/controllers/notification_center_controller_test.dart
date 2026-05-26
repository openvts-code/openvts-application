import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/api/api_client.dart';
import 'package:open_vts/features/notifications/controllers/notification_center_controller.dart';
import 'package:open_vts/features/notifications/models/app_notification.dart';
import 'package:open_vts/features/notifications/models/notification_page.dart';
import 'package:open_vts/features/notifications/services/notification_service.dart';

void main() {
  group('NotificationCenterController', () {
    test('loads notifications and exact unread count', () async {
      final service = _FakeNotificationService(
        notifications: [
          _notification(id: 3, isRead: false),
          _notification(id: 2, isRead: true),
          _notification(id: 1, isRead: false),
        ],
        unreadCount: 5,
      );
      final controller = NotificationCenterController(service);

      await controller.load();

      expect(controller.state.items, hasLength(3));
      expect(controller.state.unreadCount, 5);
      expect(controller.state.isInitialLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
    });

    test('marks one notification and then all notifications as read', () async {
      final service = _FakeNotificationService(
        notifications: [
          _notification(id: 3, isRead: false),
          _notification(id: 2, isRead: false),
          _notification(id: 1, isRead: true),
        ],
      );
      final controller = NotificationCenterController(service);
      await controller.load();

      await controller.markAsRead(3);

      expect(controller.state.unreadCount, 1);
      expect(
        controller.state.items.firstWhere((item) => item.id == 3).isRead,
        isTrue,
      );
      expect(service.markedReadIds, [3]);

      await controller.markAllAsRead();

      expect(controller.state.unreadCount, 0);
      expect(controller.state.items.every((item) => item.isRead), isTrue);
      expect(service.markAllReadCalls, 1);
    });

    test('loads more notifications when a cursor is available', () async {
      final service = _FakeNotificationService(
        notifications: [
          _notification(id: 5, isRead: false),
          _notification(id: 4, isRead: false),
          _notification(id: 3, isRead: true),
        ],
      );
      final controller = NotificationCenterController(service);

      await controller.load();
      await controller.loadMore();

      expect(controller.state.items.map((item) => item.id), [5, 4, 3]);
      expect(controller.state.hasMore, isFalse);
    });
  });
}

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService({
    required List<AppNotification> notifications,
    int? unreadCount,
  })  : _notifications = List<AppNotification>.from(notifications)
          ..sort((left, right) => right.id.compareTo(left.id)),
        _unreadCount = unreadCount,
        super(ApiClient(Dio()));

  final List<AppNotification> _notifications;
  final int? _unreadCount;
  final List<int> markedReadIds = <int>[];
  int markAllReadCalls = 0;

  @override
  String get listEndpoint => '/test/notifications';

  @override
  String notificationReadEndpoint(int id) => '/test/notifications/$id/read';

  @override
  String get readAllEndpoint => '/test/notifications/read-all';

  @override
  String get roleLabel => 'Test';

  @override
  Future<NotificationPage> getNotifications({
    int limit = 20,
    int? beforeId,
    bool unreadOnly = false,
    String? category,
  }) async {
    var items = List<AppNotification>.from(_notifications);

    if (beforeId != null) {
      items = items.where((item) => item.id < beforeId).toList();
    }

    if (unreadOnly) {
      items = items.where((item) => !item.isRead).toList();
    }

    final pageItems = items.take(limit).toList(growable: false);
    final hasMore = items.length > limit;

    return NotificationPage(
      items: pageItems,
      hasMore: hasMore,
      nextBeforeId: hasMore && pageItems.isNotEmpty ? pageItems.last.id : null,
      unreadCount: _unreadCount,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    return _unreadCount ?? _notifications.where((item) => !item.isRead).length;
  }

  @override
  Future<void> markAsRead(int id) async {
    markedReadIds.add(id);
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.utc(2026, 5, 14, 10, 30),
      );
    }
  }

  @override
  Future<void> markAllAsRead() async {
    markAllReadCalls += 1;
    for (var index = 0; index < _notifications.length; index += 1) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.utc(2026, 5, 14, 11),
      );
    }
  }
}

AppNotification _notification({required int id, required bool isRead}) {
  return AppNotification(
    id: id,
    title: 'Notification $id',
    message: 'Message $id',
    isRead: isRead,
    category: 'System',
    createdAt: DateTime.utc(2026, 5, 14, 10, id),
    readAt: isRead ? DateTime.utc(2026, 5, 14, 10, id + 1) : null,
  );
}
