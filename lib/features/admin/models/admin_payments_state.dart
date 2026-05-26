import 'admin_payments_model.dart';
import 'admin_users_model.dart';

class AdminPaymentsState {
  const AdminPaymentsState({
    required this.transactions,
    required this.analytics,
    required this.users,
    required this.selectedUserId,
    required this.selectedStatus,
    required this.selectedMode,
    required this.searchQuery,
    required this.rangePreset,
    required this.customFrom,
    required this.customTo,
    required this.page,
    required this.limit,
    required this.total,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.isLoadingAnalytics,
    required this.isRenewing,
    required this.errorMessage,
    required this.analyticsErrorMessage,
    required this.refreshKey,
  });

  const AdminPaymentsState.initial()
      : transactions = const <AdminPaymentTransaction>[],
        analytics = null,
        users = const <AdminUserListItem>[],
        selectedUserId = null,
        selectedStatus = null,
        selectedMode = null,
        searchQuery = '',
        rangePreset = AdminPaymentsRangePreset.thisMonth,
        customFrom = null,
        customTo = null,
        page = 1,
        limit = 100,
        total = 0,
        isLoading = true,
        isRefreshing = false,
        isLoadingMore = false,
        isLoadingAnalytics = false,
        isRenewing = false,
        errorMessage = null,
        analyticsErrorMessage = null,
        refreshKey = 0;

  static const _unset = Object();

  final List<AdminPaymentTransaction> transactions;
  final AdminPaymentsAnalytics? analytics;
  final List<AdminUserListItem> users;
  final String? selectedUserId;
  final AdminPaymentStatus? selectedStatus;
  final AdminPaymentMode? selectedMode;
  final String searchQuery;
  final AdminPaymentsRangePreset rangePreset;
  final DateTime? customFrom;
  final DateTime? customTo;
  final int page;
  final int limit;
  final int total;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isLoadingAnalytics;
  final bool isRenewing;
  final String? errorMessage;
  final String? analyticsErrorMessage;
  final int refreshKey;

  bool get hasTransactions => transactions.isNotEmpty;
  bool get hasMore => page * limit < total;

  bool get hasActiveFilters =>
      (selectedUserId ?? '').trim().isNotEmpty ||
      selectedStatus != null ||
      selectedMode != null ||
      searchQuery.trim().isNotEmpty ||
      rangePreset != AdminPaymentsRangePreset.thisMonth;

  AdminPaymentsState copyWith({
    List<AdminPaymentTransaction>? transactions,
    Object? analytics = _unset,
    List<AdminUserListItem>? users,
    Object? selectedUserId = _unset,
    Object? selectedStatus = _unset,
    Object? selectedMode = _unset,
    String? searchQuery,
    AdminPaymentsRangePreset? rangePreset,
    Object? customFrom = _unset,
    Object? customTo = _unset,
    int? page,
    int? limit,
    int? total,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isLoadingAnalytics,
    bool? isRenewing,
    Object? errorMessage = _unset,
    Object? analyticsErrorMessage = _unset,
    int? refreshKey,
  }) {
    return AdminPaymentsState(
      transactions: transactions ?? this.transactions,
      analytics: identical(analytics, _unset)
          ? this.analytics
          : analytics as AdminPaymentsAnalytics?,
      users: users ?? this.users,
      selectedUserId: identical(selectedUserId, _unset)
          ? this.selectedUserId
          : selectedUserId as String?,
      selectedStatus: identical(selectedStatus, _unset)
          ? this.selectedStatus
          : selectedStatus as AdminPaymentStatus?,
      selectedMode: identical(selectedMode, _unset)
          ? this.selectedMode
          : selectedMode as AdminPaymentMode?,
      searchQuery: searchQuery ?? this.searchQuery,
      rangePreset: rangePreset ?? this.rangePreset,
      customFrom: identical(customFrom, _unset)
          ? this.customFrom
          : customFrom as DateTime?,
      customTo:
          identical(customTo, _unset) ? this.customTo : customTo as DateTime?,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingAnalytics: isLoadingAnalytics ?? this.isLoadingAnalytics,
      isRenewing: isRenewing ?? this.isRenewing,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      analyticsErrorMessage: identical(analyticsErrorMessage, _unset)
          ? this.analyticsErrorMessage
          : analyticsErrorMessage as String?,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}
