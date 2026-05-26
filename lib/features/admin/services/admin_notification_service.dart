import '../../../core/api/api_endpoints.dart';
import '../../notifications/services/notification_service.dart';

class AdminNotificationService extends NotificationService {
  AdminNotificationService(super.apiClient);

  @override
  String get listEndpoint => ApiEndpoints.admin.notifications;

  @override
  String notificationReadEndpoint(int id) {
    return ApiEndpoints.admin.notificationRead(id.toString());
  }

  @override
  String get readAllEndpoint => ApiEndpoints.admin.notificationsReadAll;

  @override
  String get roleLabel => 'Admin';
}
