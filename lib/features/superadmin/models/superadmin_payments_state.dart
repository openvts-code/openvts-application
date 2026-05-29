import 'superadmin_payments_model.dart';

enum SuperadminPaymentsRangePreset {
  allTime,
  thisMonth,
  last30,
  thisYear,
  custom,
}

class SuperadminPaymentsState {
  const SuperadminPaymentsState({
    required this.admins,
    required this.transactions,
    required this.analytics,
    required this.selectedAdminId,
    required this.selectedStatus,
    required this.searchQuery,
    required this.rangePreset,
    required this.customFrom,
    required this.customTo,
    required this.page,
    required this.limit,
    required this.total,
    required this.isLoadingAdmins,
    required this.isLoadingTransactions,
    required this.isLoadingAnalytics,
    required this.isRecordingPayment,
    required this.errorMessage,
    required this.analyticsErrorMessage,
    required this.refreshKey,
  });

  const SuperadminPaymentsState.initial()
      : admins = const <SuperadminPaymentAdminOption>[],
        transactions = const <SuperadminTransaction>[],
        analytics = null,
        selectedAdminId = null,
        selectedStatus = null,
        searchQuery = '',
        rangePreset = SuperadminPaymentsRangePreset.allTime,
        customFrom = null,
        customTo = null,
        page = 1,
        limit = 100,
        total = 0,
        isLoadingAdmins = false,
        isLoadingTransactions = false,
        isLoadingAnalytics = false,
        isRecordingPayment = false,
        errorMessage = null,
        analyticsErrorMessage = null,
        refreshKey = '';

  static const Object _unset = Object();

  final List<SuperadminPaymentAdminOption> admins;
  final List<SuperadminTransaction> transactions;
  final SuperadminTransactionsAnalytics? analytics;
  final int? selectedAdminId;
  final SuperadminTransactionStatus? selectedStatus;
  final String searchQuery;
  final SuperadminPaymentsRangePreset rangePreset;
  final DateTime? customFrom;
  final DateTime? customTo;
  final int page;
  final int limit;
  final int total;
  final bool isLoadingAdmins;
  final bool isLoadingTransactions;
  final bool isLoadingAnalytics;
  final bool isRecordingPayment;
  final String? errorMessage;
  final String? analyticsErrorMessage;
  final String refreshKey;

  bool get hasTransactions => transactions.isNotEmpty;

  bool get hasMoreTransactions => page * limit < total;

  bool get hasActiveFilters {
    return selectedAdminId != null ||
        selectedStatus != null ||
        searchQuery.trim().isNotEmpty ||
        rangePreset != SuperadminPaymentsRangePreset.allTime;
  }

  SuperadminPaymentsState copyWith({
    List<SuperadminPaymentAdminOption>? admins,
    List<SuperadminTransaction>? transactions,
    Object? analytics = _unset,
    Object? selectedAdminId = _unset,
    Object? selectedStatus = _unset,
    String? searchQuery,
    SuperadminPaymentsRangePreset? rangePreset,
    Object? customFrom = _unset,
    Object? customTo = _unset,
    int? page,
    int? limit,
    int? total,
    bool? isLoadingAdmins,
    bool? isLoadingTransactions,
    bool? isLoadingAnalytics,
    bool? isRecordingPayment,
    Object? errorMessage = _unset,
    Object? analyticsErrorMessage = _unset,
    String? refreshKey,
  }) {
    return SuperadminPaymentsState(
      admins: admins ?? this.admins,
      transactions: transactions ?? this.transactions,
      analytics: identical(analytics, _unset)
          ? this.analytics
          : analytics as SuperadminTransactionsAnalytics?,
      selectedAdminId: identical(selectedAdminId, _unset)
          ? this.selectedAdminId
          : selectedAdminId as int?,
      selectedStatus: identical(selectedStatus, _unset)
          ? this.selectedStatus
          : selectedStatus as SuperadminTransactionStatus?,
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
      isLoadingAdmins: isLoadingAdmins ?? this.isLoadingAdmins,
      isLoadingTransactions:
          isLoadingTransactions ?? this.isLoadingTransactions,
      isLoadingAnalytics: isLoadingAnalytics ?? this.isLoadingAnalytics,
      isRecordingPayment: isRecordingPayment ?? this.isRecordingPayment,
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
