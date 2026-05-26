import 'user_dashboard_model.dart';

class UserDashboardState {
  const UserDashboardState({
    this.dashboards = const <UserDashboardListItem>[],
    this.selectedDashboardId,
    this.selectedDashboard,
    this.orderedWidgets = const <UserDashboardWidgetConfig>[],
    this.isLoadingDashboards = false,
    this.isLoadingSelectedDashboard = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.selectedDashboardError,
  });

  const UserDashboardState.initial()
      : this(
          isLoadingDashboards: true,
        );

  final List<UserDashboardListItem> dashboards;
  final String? selectedDashboardId;
  final UserDashboardDetail? selectedDashboard;
  final List<UserDashboardWidgetConfig> orderedWidgets;
  final bool isLoadingDashboards;
  final bool isLoadingSelectedDashboard;
  final bool isRefreshing;
  final String? errorMessage;
  final String? selectedDashboardError;

  bool get hasDashboards => dashboards.isNotEmpty;
  bool get hasSelectedDashboard => selectedDashboard != null;
  bool get hasOrderedWidgets => orderedWidgets.isNotEmpty;

  UserDashboardState copyWith({
    List<UserDashboardListItem>? dashboards,
    Object? selectedDashboardId = _unsetUserDashboardStateValue,
    Object? selectedDashboard = _unsetUserDashboardStateValue,
    List<UserDashboardWidgetConfig>? orderedWidgets,
    bool? isLoadingDashboards,
    bool? isLoadingSelectedDashboard,
    bool? isRefreshing,
    Object? errorMessage = _unsetUserDashboardStateValue,
    Object? selectedDashboardError = _unsetUserDashboardStateValue,
  }) {
    return UserDashboardState(
      dashboards: dashboards ?? this.dashboards,
      selectedDashboardId:
          identical(selectedDashboardId, _unsetUserDashboardStateValue)
              ? this.selectedDashboardId
              : selectedDashboardId as String?,
      selectedDashboard:
          identical(selectedDashboard, _unsetUserDashboardStateValue)
              ? this.selectedDashboard
              : selectedDashboard as UserDashboardDetail?,
      orderedWidgets: orderedWidgets ?? this.orderedWidgets,
      isLoadingDashboards: isLoadingDashboards ?? this.isLoadingDashboards,
      isLoadingSelectedDashboard:
          isLoadingSelectedDashboard ?? this.isLoadingSelectedDashboard,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: identical(errorMessage, _unsetUserDashboardStateValue)
          ? this.errorMessage
          : errorMessage as String?,
      selectedDashboardError:
          identical(selectedDashboardError, _unsetUserDashboardStateValue)
              ? this.selectedDashboardError
              : selectedDashboardError as String?,
    );
  }
}

const Object _unsetUserDashboardStateValue = Object();
