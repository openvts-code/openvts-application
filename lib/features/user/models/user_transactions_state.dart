import 'user_transactions_model.dart';

enum UserTransactionsRangePreset {
  thisMonth,
  last30Days,
  thisYear,
  custom,
}

class UserTransactionsState {
  const UserTransactionsState({
    required this.transactions,
    required this.selectedTransaction,
    required this.selectedStatus,
    required this.selectedPaymentMode,
    required this.selectedPaymentType,
    required this.searchQuery,
    required this.rangePreset,
    required this.customFrom,
    required this.customTo,
    required this.page,
    required this.limit,
    required this.total,
    required this.isLoading,
    required this.isRefreshing,
    required this.errorMessage,
    required this.refreshKey,
  });

  const UserTransactionsState.initial()
      : transactions = const <UserTransaction>[],
        selectedTransaction = null,
        selectedStatus = null,
        selectedPaymentMode = null,
        selectedPaymentType = null,
        searchQuery = '',
        rangePreset = UserTransactionsRangePreset.thisMonth,
        customFrom = null,
        customTo = null,
        page = 1,
        limit = 100,
        total = 0,
        isLoading = false,
        isRefreshing = false,
        errorMessage = null,
        refreshKey = '';

  static const Object _unset = Object();

  final List<UserTransaction> transactions;
  final UserTransaction? selectedTransaction;
  final UserTransactionStatus? selectedStatus;
  final UserPaymentMode? selectedPaymentMode;
  final String? selectedPaymentType;
  final String searchQuery;
  final UserTransactionsRangePreset rangePreset;
  final DateTime? customFrom;
  final DateTime? customTo;
  final int page;
  final int limit;
  final int total;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final String refreshKey;

  bool get hasTransactions => transactions.isNotEmpty;

  bool get hasMore => page * limit < total;

  bool get hasActiveFilters {
    return selectedStatus != null ||
        selectedPaymentMode != null ||
        (selectedPaymentType?.trim().isNotEmpty ?? false) ||
        searchQuery.trim().isNotEmpty ||
        rangePreset != UserTransactionsRangePreset.thisMonth;
  }

  List<UserTransaction> get filteredTransactions {
    final modeFilter = selectedPaymentMode;
    final typeFilter = selectedPaymentType?.trim().toUpperCase() ?? '';

    if (modeFilter == null && typeFilter.isEmpty) {
      return transactions;
    }

    return transactions.where((transaction) {
      final matchesMode =
          modeFilter == null || transaction.paymentMode == modeFilter;
      if (!matchesMode) {
        return false;
      }

      if (typeFilter.isEmpty) {
        return true;
      }

      return transaction.paymentType.trim().toUpperCase() == typeFilter;
    }).toList(growable: false);
  }

  UserTransactionsState copyWith({
    List<UserTransaction>? transactions,
    Object? selectedTransaction = _unset,
    Object? selectedStatus = _unset,
    Object? selectedPaymentMode = _unset,
    Object? selectedPaymentType = _unset,
    String? searchQuery,
    UserTransactionsRangePreset? rangePreset,
    Object? customFrom = _unset,
    Object? customTo = _unset,
    int? page,
    int? limit,
    int? total,
    bool? isLoading,
    bool? isRefreshing,
    Object? errorMessage = _unset,
    String? refreshKey,
  }) {
    return UserTransactionsState(
      transactions: transactions ?? this.transactions,
      selectedTransaction: identical(selectedTransaction, _unset)
          ? this.selectedTransaction
          : selectedTransaction as UserTransaction?,
      selectedStatus: identical(selectedStatus, _unset)
          ? this.selectedStatus
          : selectedStatus as UserTransactionStatus?,
      selectedPaymentMode: identical(selectedPaymentMode, _unset)
          ? this.selectedPaymentMode
          : selectedPaymentMode as UserPaymentMode?,
      selectedPaymentType: identical(selectedPaymentType, _unset)
          ? this.selectedPaymentType
          : selectedPaymentType as String?,
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
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}
