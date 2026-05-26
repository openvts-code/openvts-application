import 'superadmin_dashboard_model.dart';

class SuperadminDashboardState {
  const SuperadminDashboardState({
    this.dashboard,
    this.selectedActorId,
    this.fromDate,
    this.toDate,
    this.errorMessage,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
  });

  const SuperadminDashboardState.initial()
      : this(
          isInitialLoading: true,
        );

  final SuperadminDashboardModel? dashboard;
  final int? selectedActorId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? errorMessage;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;

  bool get hasData => dashboard != null;
  bool get hasActiveFilters =>
      selectedActorId != null || fromDate != null || toDate != null;

  SuperadminDashboardState copyWith({
    Object? dashboard = _unsetDashboardStateValue,
    Object? selectedActorId = _unsetDashboardStateValue,
    Object? fromDate = _unsetDashboardStateValue,
    Object? toDate = _unsetDashboardStateValue,
    Object? errorMessage = _unsetDashboardStateValue,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
  }) {
    return SuperadminDashboardState(
      dashboard: identical(dashboard, _unsetDashboardStateValue)
          ? this.dashboard
          : dashboard as SuperadminDashboardModel?,
      selectedActorId: identical(selectedActorId, _unsetDashboardStateValue)
          ? this.selectedActorId
          : selectedActorId as int?,
      fromDate: identical(fromDate, _unsetDashboardStateValue)
          ? this.fromDate
          : fromDate as DateTime?,
      toDate: identical(toDate, _unsetDashboardStateValue)
          ? this.toDate
          : toDate as DateTime?,
      errorMessage: identical(errorMessage, _unsetDashboardStateValue)
          ? this.errorMessage
          : errorMessage as String?,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

const Object _unsetDashboardStateValue = Object();