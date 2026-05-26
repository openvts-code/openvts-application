import '../../notifications/models/app_notification.dart';
import '../services/superadmin_vehicle_service.dart';

class SuperadminMapLiveState {
  const SuperadminMapLiveState({
    required this.telemetry,
    required this.alerts,
    this.errorMessage,
    this.isInitialLoading = false,
    this.isAlertsLoading = false,
    this.isTelemetryConnected = false,
    this.isNotificationsConnected = false,
  });

  const SuperadminMapLiveState.initial()
      : this(
          telemetry: const SuperadminMapTelemetry(
            allCount: 0,
            runningCount: 0,
            stopCount: 0,
            inactiveCount: 0,
            vehicles: <Never>[],
          ),
          alerts: const <AppNotification>[],
          isInitialLoading: true,
          isAlertsLoading: true,
        );

  final SuperadminMapTelemetry telemetry;
  final List<AppNotification> alerts;
  final String? errorMessage;
  final bool isInitialLoading;
  final bool isAlertsLoading;
  final bool isTelemetryConnected;
  final bool isNotificationsConnected;

  SuperadminMapLiveState copyWith({
    SuperadminMapTelemetry? telemetry,
    List<AppNotification>? alerts,
    Object? errorMessage = _unset,
    bool? isInitialLoading,
    bool? isAlertsLoading,
    bool? isTelemetryConnected,
    bool? isNotificationsConnected,
  }) {
    return SuperadminMapLiveState(
      telemetry: telemetry ?? this.telemetry,
      alerts: alerts ?? this.alerts,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isAlertsLoading: isAlertsLoading ?? this.isAlertsLoading,
      isTelemetryConnected: isTelemetryConnected ?? this.isTelemetryConnected,
      isNotificationsConnected:
          isNotificationsConnected ?? this.isNotificationsConnected,
    );
  }
}

const Object _unset = Object();
