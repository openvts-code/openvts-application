import 'admin_plans_model.dart';

class AdminPlansState {
  const AdminPlansState({
    required this.plans,
    required this.searchQuery,
    required this.isLoading,
    required this.isRefreshing,
    required this.isCreating,
    required this.isUpdating,
    required this.errorMessage,
    required this.submitErrorMessage,
    required this.currencies,
    required this.isLoadingCurrencies,
    required this.refreshKey,
  });

  const AdminPlansState.initial()
      : plans = const <AdminPlan>[],
        searchQuery = '',
        isLoading = true,
        isRefreshing = false,
        isCreating = false,
        isUpdating = false,
        errorMessage = null,
        submitErrorMessage = null,
        currencies = const <AdminCurrencyOption>[],
        isLoadingCurrencies = false,
        refreshKey = 0;

  static const _unset = Object();

  final List<AdminPlan> plans;
  final String searchQuery;
  final bool isLoading;
  final bool isRefreshing;
  final bool isCreating;
  final bool isUpdating;
  final String? errorMessage;
  final String? submitErrorMessage;
  final List<AdminCurrencyOption> currencies;
  final bool isLoadingCurrencies;
  final int refreshKey;

  List<AdminPlan> get filteredPlans {
    final q = searchQuery.trim();
    final list = plans.where((p) => p.matches(q)).toList(growable: false);
    if (list.length < 2) return list;
    list.sort((a, b) {
      final ad = a.createdAt;
      final bd = b.createdAt;
      if (ad == null && bd == null) return a.name.compareTo(b.name);
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return list;
  }

  bool get hasPlans => plans.isNotEmpty;

  AdminPlansState copyWith({
    List<AdminPlan>? plans,
    String? searchQuery,
    bool? isLoading,
    bool? isRefreshing,
    bool? isCreating,
    bool? isUpdating,
    Object? errorMessage = _unset,
    Object? submitErrorMessage = _unset,
    List<AdminCurrencyOption>? currencies,
    bool? isLoadingCurrencies,
    int? refreshKey,
  }) {
    return AdminPlansState(
      plans: plans ?? this.plans,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      submitErrorMessage: identical(submitErrorMessage, _unset)
          ? this.submitErrorMessage
          : submitErrorMessage as String?,
      currencies: currencies ?? this.currencies,
      isLoadingCurrencies: isLoadingCurrencies ?? this.isLoadingCurrencies,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}
