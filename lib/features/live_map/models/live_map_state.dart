import '../../notifications/models/app_notification.dart';
import '../services/live_map_vehicle_service.dart';

/// Role-neutral state for the shared live-map engine.
///
/// Mirrors the fields of the working Superadmin map state exactly; the
/// only difference is the role-neutral [LiveMapTelemetry] type (which is a
/// typedef back to `SuperadminMapTelemetry`, so behavior is unchanged).
class LiveMapState {
  const LiveMapState({
    required this.telemetry,
    required this.alerts,
    this.errorMessage,
    this.isInitialLoading = false,
    this.isAlertsLoading = false,
    this.isTelemetryConnected = false,
    this.isNotificationsConnected = false,
  });

  const LiveMapState.initial()
      : this(
          telemetry: const LiveMapTelemetry(
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

  final LiveMapTelemetry telemetry;
  final List<AppNotification> alerts;
  final String? errorMessage;
  final bool isInitialLoading;
  final bool isAlertsLoading;
  final bool isTelemetryConnected;
  final bool isNotificationsConnected;

  LiveMapState copyWith({
    LiveMapTelemetry? telemetry,
    List<AppNotification>? alerts,
    Object? errorMessage = _unset,
    bool? isInitialLoading,
    bool? isAlertsLoading,
    bool? isTelemetryConnected,
    bool? isNotificationsConnected,
  }) {
    return LiveMapState(
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
