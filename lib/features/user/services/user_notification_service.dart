import '../../../core/api/api_endpoints.dart';
import '../../notifications/services/notification_service.dart';

class UserNotificationService extends NotificationService {
  UserNotificationService(super.apiClient);

  @override
  String get listEndpoint => ApiEndpoints.user.notifications;

  @override
  String notificationReadEndpoint(int id) {
    return ApiEndpoints.user.notificationRead(id.toString());
  }

  @override
  String get readAllEndpoint => ApiEndpoints.user.notificationsReadAll;

  @override
  String get roleLabel => 'User';
}
