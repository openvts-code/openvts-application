class StorageKeys {
  const StorageKeys._();

  static const apiBaseUrlOverride = 'openvts_api_base_url_override';

  // Legacy global auth keys kept only for migration/fallback.
  static const accessToken = 'openvts_access_token';
  static const refreshToken = 'openvts_refresh_token';
  static const userRole = 'openvts_user_role';
  static const currentUser = 'openvts_current_user';
  static const activeRole = 'openvts_active_role';

  static const mobilePushDeviceId = 'openvts_mobile_push_device_id';
  static const mobilePushFcmToken = 'openvts_mobile_push_fcm_token';
  static const mobilePushRegisteredToken = 'openvts_mobile_push_registered_token';
  static const mobilePushRegisteredUserId = 'openvts_mobile_push_registered_user_id';
  static const mobilePushRegisteredPlatform = 'openvts_mobile_push_registered_platform';
  static const mobilePushFirebaseConfigJson = 'openvts_mobile_push_firebase_config_json';
  static const mobilePushFirebaseConfigVersion = 'openvts_mobile_push_firebase_config_version';
  static const mobilePushLastPermissionStatus = 'openvts_mobile_push_last_permission_status';
  static const mobilePushLastInitError = 'openvts_mobile_push_last_init_error';

  static String accessTokenForRole(String role) {
    return 'openvts_${_normalizedRole(role)}_access_token';
  }

  static String refreshTokenForRole(String role) {
    return 'openvts_${_normalizedRole(role)}_refresh_token';
  }

  static String currentUserForRole(String role) {
    return 'openvts_${_normalizedRole(role)}_current_user';
  }

  static String _normalizedRole(String role) {
    return role.trim().toLowerCase();
  }

  static const themeMode = 'openvts_theme_mode';
  static const locale = 'openvts_locale';

  static const appLanguageCode = 'openvts_app_language_code';
  static const appDateFormat = 'openvts_app_date_format';
  static const appTimeFormat = 'openvts_app_time_format';
  static const appTimezone = 'openvts_app_timezone';
  static const appLayoutDirection = 'openvts_app_layout_direction';
  static const appUnits = 'openvts_app_units';
  static const superadminMapVisualSettings = 'openvts_superadmin_map_visual_settings';
  static const superadminMapLayerId = 'openvts_superadmin_map_layer_id';

  static const adminMapVisualSettings = 'openvts_admin_map_visual_settings';
  static const adminMapLayerId = 'openvts_admin_map_layer_id';

  static const userMapVisualSettings = 'openvts_user_map_visual_settings';
  static const userMapLayerId = 'openvts_user_map_layer_id';
}
