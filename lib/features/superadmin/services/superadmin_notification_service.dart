import '../../../core/api/api_endpoints.dart';
import '../../notifications/services/notification_service.dart';

class SuperadminNotificationService extends NotificationService {
  SuperadminNotificationService(super.apiClient);

  @override
  String get listEndpoint => ApiEndpoints.superadmin.notifications;

  @override
  String notificationReadEndpoint(int id) {
    return ApiEndpoints.superadmin.notificationRead(id.toString());
  }

  @override
  String get readAllEndpoint => ApiEndpoints.superadmin.notificationsReadAll;

  @override
  String get roleLabel => 'Superadmin';
}
