import 'admin_dashboard_model.dart';

class AdminDashboardState {
  const AdminDashboardState({
    this.dashboard,
    this.selectedCurrency,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  const AdminDashboardState.initial()
      : this(
          isInitialLoading: true,
        );

  final AdminDashboardSummary? dashboard;
  final String? selectedCurrency;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? errorMessage;

  bool get hasData => dashboard != null;

  AdminDashboardState copyWith({
    Object? dashboard = _unsetAdminDashboardStateValue,
    Object? selectedCurrency = _unsetAdminDashboardStateValue,
    bool? isInitialLoading,
    bool? isRefreshing,
    Object? errorMessage = _unsetAdminDashboardStateValue,
  }) {
    return AdminDashboardState(
      dashboard: identical(dashboard, _unsetAdminDashboardStateValue)
          ? this.dashboard
          : dashboard as AdminDashboardSummary?,
      selectedCurrency:
          identical(selectedCurrency, _unsetAdminDashboardStateValue)
              ? this.selectedCurrency
              : selectedCurrency as String?,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: identical(errorMessage, _unsetAdminDashboardStateValue)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _unsetAdminDashboardStateValue = Object();
