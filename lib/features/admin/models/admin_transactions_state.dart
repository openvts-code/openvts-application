import 'admin_transactions_model.dart';

enum AdminTransactionsRangePreset { thisMonth, last30, thisYear, custom }

class AdminTransactionsState {
  const AdminTransactionsState({
    required this.transactions,
    required this.selectedStatus,
    required this.selectedMode,
    required this.selectedType,
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
    required this.errorMessage,
    required this.refreshKey,
  });

  const AdminTransactionsState.initial()
      : transactions = const <AdminTransaction>[],
        selectedStatus = null,
        selectedMode = null,
        selectedType = null,
        searchQuery = '',
        rangePreset = AdminTransactionsRangePreset.thisMonth,
        customFrom = null,
        customTo = null,
        page = 1,
        limit = 100,
        total = 0,
        isLoading = true,
        isRefreshing = false,
        isLoadingMore = false,
        errorMessage = null,
        refreshKey = 0;

  static const _unset = Object();

  final List<AdminTransaction> transactions;
  final AdminTransactionStatus? selectedStatus;
  final AdminPaymentMode? selectedMode;
  final AdminPaymentType? selectedType;
  final String searchQuery;
  final AdminTransactionsRangePreset rangePreset;
  final DateTime? customFrom;
  final DateTime? customTo;
  final int page;
  final int limit;
  final int total;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;
  final int refreshKey;

  bool get hasTransactions => transactions.isNotEmpty;
  bool get hasMoreTransactions => page * limit < total;

  bool get hasActiveFilters {
    return selectedStatus != null ||
        selectedMode != null ||
        selectedType != null ||
        searchQuery.trim().isNotEmpty ||
        rangePreset != AdminTransactionsRangePreset.thisMonth;
  }

  AdminTransactionsState copyWith({
    List<AdminTransaction>? transactions,
    Object? selectedStatus = _unset,
    Object? selectedMode = _unset,
    Object? selectedType = _unset,
    String? searchQuery,
    AdminTransactionsRangePreset? rangePreset,
    Object? customFrom = _unset,
    Object? customTo = _unset,
    int? page,
    int? limit,
    int? total,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    Object? errorMessage = _unset,
    int? refreshKey,
  }) {
    return AdminTransactionsState(
      transactions: transactions ?? this.transactions,
      selectedStatus: identical(selectedStatus, _unset)
          ? this.selectedStatus
          : selectedStatus as AdminTransactionStatus?,
      selectedMode: identical(selectedMode, _unset)
          ? this.selectedMode
          : selectedMode as AdminPaymentMode?,
      selectedType: identical(selectedType, _unset)
          ? this.selectedType
          : selectedType as AdminPaymentType?,
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
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}
