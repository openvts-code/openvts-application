import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/notifications/models/app_notification.dart';
import 'package:open_vts/features/notifications/models/notification_page.dart';

void main() {
  test('parses nested notifications, counts, and cursor metadata', () {
    final page = NotificationPage.fromDynamic(
      {
        'notifications': [
          {
            'id': 42,
            'title': 'Overspeed event',
            'message': 'Vehicle BX-110 exceeded 90 km/h.',
            'isRead': false,
            'category': 'Vehicle',
            'createdAt': '2026-05-14T10:00:00.000Z',
          },
          {
            'id': 41,
            'title': 'Maintenance reminder',
            'message': 'Service is due in 120 km.',
            'readAt': '2026-05-14T09:45:00.000Z',
            'category': 'Maintenance',
          },
        ],
        'summary': {'unreadCount': 7},
        'pagination': {
          'hasMore': true,
          'nextBeforeId': 41,
        },
      },
      requestedLimit: 20,
    );

    expect(page.items, hasLength(2));
    expect(page.items.first.id, 42);
    expect(page.items.first.isRead, isFalse);
    expect(page.items.last.isRead, isTrue);
    expect(page.unreadCount, 7);
    expect(page.hasMore, isTrue);
    expect(page.nextBeforeId, 41);
  });

  test('prefers wrapped row identifiers for mark-read operations', () {
    final notification = AppNotification.fromJson(
      {
        'userNotificationId': 812,
        'notification': {
          'id': 33,
          'title': 'New login',
          'message': 'A new login was detected on your account.',
          'category': 'SECURITY',
          'createdAt': '2026-05-14T09:12:00.000Z',
        },
      },
    );

    expect(notification.id, 812);
    expect(notification.title, 'New login');
    expect(notification.message, 'A new login was detected on your account.');
    expect(notification.category, 'SECURITY');
    expect(notification.readId, 812);
    expect(notification.notificationId, 33);
  });

  test('preserves map event identifiers for realtime dedupe', () {
    final notification = AppNotification.fromJson(
      {
        'id': 9001,
        'eventId': 77,
        'readId': 812,
        'logId': 43,
        'dedupeKey': 'vehicle:77:overspeed',
        'title': 'Overspeed',
        'message': 'Vehicle crossed the speed threshold.',
        'createdAt': '2026-05-16T10:00:00.000Z',
      },
    );

    expect(notification.id, 812);
    expect(notification.eventId, 77);
    expect(notification.readId, 812);
    expect(notification.logId, 43);
    expect(notification.dedupeKey, 'vehicle:77:overspeed');
  });

  test('extracts vehicle IMEI for per-vehicle event streams', () {
    expect(
      AppNotification.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'Root IMEI',
        'imei': 'imei-root',
      }).vehicleImei,
      'imei-root',
    );
    expect(
      AppNotification.fromJson(<String, dynamic>{
        'id': 2,
        'title': 'Metadata IMEI',
        'metadata': <String, dynamic>{'imei': 'imei-meta'},
      }).vehicleImei,
      'imei-meta',
    );
    expect(
      AppNotification.fromJson(<String, dynamic>{
        'id': 3,
        'title': 'Vehicle IMEI',
        'vehicle': <String, dynamic>{'imei': 'imei-vehicle'},
      }).vehicleImei,
      'imei-vehicle',
    );
    expect(
      AppNotification.fromJson(<String, dynamic>{
        'id': 4,
        'title': 'Nested vehicle IMEI',
        'metadata': <String, dynamic>{
          'vehicle': <String, dynamic>{'imei': 'imei-nested'},
        },
      }).vehicleImei,
      'imei-nested',
    );
    expect(
      AppNotification.fromJson(<String, dynamic>{
        'id': 5,
        'title': 'Payload IMEI',
        'metadata': <String, dynamic>{'source': 'event-stream'},
        'payload': <String, dynamic>{'imei': 'imei-payload'},
      }).vehicleImei,
      'imei-payload',
    );
  });

  test('builds id-first dedupe identity with fallback dedupe key', () {
    final withId = AppNotification.fromJson(<String, dynamic>{
      'id': 77,
      'dedupeKey': 'vehicle:77:overspeed',
      'title': 'Overspeed',
    });
    final withoutId = AppNotification.fromJson(<String, dynamic>{
      'dedupeKey': 'vehicle:imei-1:ignition',
      'title': 'Ignition',
      'metadata': <String, dynamic>{'imei': 'imei-1'},
    });

    expect(withId.dedupeIdentity, 'id:77');
    expect(withoutId.dedupeIdentity, 'dedupe:vehicle:imei-1:ignition');
  });
}
