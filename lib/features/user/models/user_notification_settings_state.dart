import 'user_notification_settings_model.dart';

class UserNotificationSettingsState {
  const UserNotificationSettingsState({
    required this.preferences,
    required this.draftPreferences,
    required this.selectedTab,
    required this.isLoading,
    required this.isRefreshing,
    required this.isSaving,
    required this.isTesting,
    required this.errorMessage,
    required this.lastSavedAt,
    required this.refreshKey,
  });

  const UserNotificationSettingsState.initial()
      : preferences = null,
        draftPreferences = null,
        selectedTab = UserNotificationGroup.basic,
        isLoading = false,
        isRefreshing = false,
        isSaving = false,
        isTesting = false,
        errorMessage = null,
        lastSavedAt = null,
        refreshKey = '';

  static const Object _unset = Object();

  final UserNotificationPreferences? preferences;
  final UserNotificationPreferences? draftPreferences;
  final UserNotificationGroup selectedTab;
  final bool isLoading;
  final bool isRefreshing;
  final bool isSaving;
  final bool isTesting;
  final String? errorMessage;
  final DateTime? lastSavedAt;
  final String refreshKey;

  bool get hasData => draftPreferences != null;

  bool get isDirty {
    final current = draftPreferences;
    final original = preferences;

    if (current == null && original == null) {
      return false;
    }

    if (current == null || original == null) {
      return true;
    }

    return current != original;
  }

  bool get hasVehicles => vehicleCount > 0;

  bool get hasGeofences => geofenceCount > 0;

  int get vehicleCount => draftPreferences?.vehicles.length ?? 0;

  int get geofenceCount => draftPreferences?.geofences.length ?? 0;

  int get activeChannelCount => draftPreferences?.channels.activeCount ?? 0;

  int get enabledBasicCount {
    final rows = draftPreferences?.basic;
    if (rows == null) {
      return 0;
    }

    return rows
        .where((item) => item.ignitionEnabled || item.alarmEnabled)
        .length;
  }

  int get enabledOverspeedCount {
    final rows = draftPreferences?.overspeed;
    if (rows == null) {
      return 0;
    }

    return rows.where((item) => item.enabled).length;
  }

  int get enabledGeofenceMatrixCount {
    final entries = draftPreferences?.geofenceMatrix;
    if (entries == null) {
      return 0;
    }

    return entries.where((item) => item.enabled).length;
  }

  UserNotificationSettingsState copyWith({
    Object? preferences = _unset,
    Object? draftPreferences = _unset,
    UserNotificationGroup? selectedTab,
    bool? isLoading,
    bool? isRefreshing,
    bool? isSaving,
    bool? isTesting,
    Object? errorMessage = _unset,
    Object? lastSavedAt = _unset,
    String? refreshKey,
  }) {
    return UserNotificationSettingsState(
      preferences: identical(preferences, _unset)
          ? this.preferences
          : preferences as UserNotificationPreferences?,
      draftPreferences: identical(draftPreferences, _unset)
          ? this.draftPreferences
          : draftPreferences as UserNotificationPreferences?,
      selectedTab: selectedTab ?? this.selectedTab,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSaving: isSaving ?? this.isSaving,
      isTesting: isTesting ?? this.isTesting,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      lastSavedAt: identical(lastSavedAt, _unset)
          ? this.lastSavedAt
          : lastSavedAt as DateTime?,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}
