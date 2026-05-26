import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/user_notification_settings_model.dart';

class UserNotificationSettingsService {
  UserNotificationSettingsService(this._apiClient);

  final ApiClient _apiClient;

  Future<UserNotificationPreferences> fetchPreferences({
    String? refreshKey,
  }) async {
    final response = await _apiClient.get<UserNotificationPreferences>(
      ApiEndpoints.user.notificationPreferences,
      queryParameters: _query(refreshKey),
      parser: UserNotificationPreferences.fromDynamic,
    );
    return response.data;
  }

  Future<UserNotificationPreferences> savePreferences(
    UserNotificationPreferences preferences,
  ) async {
    await _apiClient.put<dynamic>(
      ApiEndpoints.user.notificationPreferences,
      data: preferences.toSavePayload(),
      parser: (json) => json,
    );

    return fetchPreferences(
      refreshKey: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Map<String, dynamic>? _query(String? refreshKey) {
    final normalizedKey = refreshKey?.trim();
    if (normalizedKey == null || normalizedKey.isEmpty) {
      return null;
    }

    return <String, dynamic>{'rk': normalizedKey};
  }
}
