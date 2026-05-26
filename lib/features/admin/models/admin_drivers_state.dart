import 'admin_drivers_model.dart';

enum AdminDriverStatusFilter { all, active, inactive }

enum AdminDriverVerifiedFilter { all, verified, unverified }

enum AdminDriversSortOption { newest, nameAsc, activeFirst }

class AdminDriversState {
  const AdminDriversState({
    required this.drivers,
    required this.filteredDrivers,
    required this.searchQuery,
    required this.statusFilter,
    required this.verifiedFilter,
    required this.countryFilter,
    required this.sortOption,
    required this.recordsPerPage,
    required this.currentPage,
    required this.isCreating,
    required this.isLoading,
    required this.isRefreshing,
    required this.errorMessage,
    required this.refreshKey,
  });

  const AdminDriversState.initial()
      : drivers = const <AdminDriverListItem>[],
        filteredDrivers = const <AdminDriverListItem>[],
        searchQuery = '',
        statusFilter = AdminDriverStatusFilter.all,
        verifiedFilter = AdminDriverVerifiedFilter.all,
        countryFilter = null,
        sortOption = AdminDriversSortOption.newest,
        recordsPerPage = 10,
        currentPage = 1,
        isCreating = false,
        isLoading = true,
        isRefreshing = false,
        errorMessage = null,
        refreshKey = 0;

  static const _unset = Object();

  final List<AdminDriverListItem> drivers;
  final List<AdminDriverListItem> filteredDrivers;
  final String searchQuery;
  final AdminDriverStatusFilter statusFilter;
  final AdminDriverVerifiedFilter verifiedFilter;
  final String? countryFilter;
  final AdminDriversSortOption sortOption;
  final int recordsPerPage;
  final int currentPage;
  final bool isCreating;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final int refreshKey;

  bool get hasDrivers => drivers.isNotEmpty;
  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      statusFilter != AdminDriverStatusFilter.all ||
      verifiedFilter != AdminDriverVerifiedFilter.all ||
      (countryFilter?.trim().isNotEmpty ?? false);
  int get filteredCount => filteredDrivers.length;
  int get pageCount {
    final total = filteredCount;
    final pageSize = recordsPerPage <= 0 ? 10 : recordsPerPage;
    if (total <= 0) return 1;
    return ((total - 1) ~/ pageSize) + 1;
  }

  int get safeCurrentPage {
    if (pageCount <= 1) return 1;
    if (currentPage < 1) return 1;
    if (currentPage > pageCount) return pageCount;
    return currentPage;
  }

  List<AdminDriverListItem> get visibleDrivers {
    if (filteredDrivers.isEmpty) return const <AdminDriverListItem>[];
    final page = safeCurrentPage;
    final size = recordsPerPage <= 0 ? 10 : recordsPerPage;
    final start = (page - 1) * size;
    if (start >= filteredDrivers.length) return const <AdminDriverListItem>[];
    final end = (start + size).clamp(0, filteredDrivers.length);
    return filteredDrivers.sublist(start, end);
  }

  int get showingCount => visibleDrivers.length;

  AdminDriversState copyWith({
    List<AdminDriverListItem>? drivers,
    List<AdminDriverListItem>? filteredDrivers,
    String? searchQuery,
    AdminDriverStatusFilter? statusFilter,
    AdminDriverVerifiedFilter? verifiedFilter,
    Object? countryFilter = _unset,
    AdminDriversSortOption? sortOption,
    int? recordsPerPage,
    int? currentPage,
    bool? isCreating,
    bool? isLoading,
    bool? isRefreshing,
    Object? errorMessage = _unset,
    int? refreshKey,
  }) {
    return AdminDriversState(
      drivers: drivers ?? this.drivers,
      filteredDrivers: filteredDrivers ?? this.filteredDrivers,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      verifiedFilter: verifiedFilter ?? this.verifiedFilter,
      countryFilter: identical(countryFilter, _unset)
          ? this.countryFilter
          : countryFilter as String?,
      sortOption: sortOption ?? this.sortOption,
      recordsPerPage: recordsPerPage ?? this.recordsPerPage,
      currentPage: currentPage ?? this.currentPage,
      isCreating: isCreating ?? this.isCreating,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}
