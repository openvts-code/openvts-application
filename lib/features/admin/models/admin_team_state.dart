import 'admin_team_model.dart';

enum AdminTeamStatusFilter { all, active, inactive }

enum AdminTeamSortOption { newest, nameAsc, activeFirst }

class AdminTeamState {
  const AdminTeamState({
    required this.teams,
    required this.filteredTeams,
    required this.searchQuery,
    required this.statusFilter,
    required this.sortOption,
    required this.recordsPerPage,
    required this.currentPage,
    required this.isLoading,
    required this.isRefreshing,
    required this.isCreating,
    required this.errorMessage,
    required this.createErrorMessage,
    required this.refreshKey,
  });

  const AdminTeamState.initial()
      : teams = const <AdminTeamListItem>[],
        filteredTeams = const <AdminTeamListItem>[],
        searchQuery = '',
        statusFilter = AdminTeamStatusFilter.all,
        sortOption = AdminTeamSortOption.newest,
        recordsPerPage = 10,
        currentPage = 1,
        isLoading = true,
        isRefreshing = false,
        isCreating = false,
        errorMessage = null,
        createErrorMessage = null,
        refreshKey = 0;

  static const _unset = Object();

  final List<AdminTeamListItem> teams;
  final List<AdminTeamListItem> filteredTeams;
  final String searchQuery;
  final AdminTeamStatusFilter statusFilter;
  final AdminTeamSortOption sortOption;
  final int recordsPerPage;
  final int currentPage;
  final bool isLoading;
  final bool isRefreshing;
  final bool isCreating;
  final String? errorMessage;
  final String? createErrorMessage;
  final int refreshKey;

  bool get hasTeams => teams.isNotEmpty;
  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      statusFilter != AdminTeamStatusFilter.all;
  int get filteredCount => filteredTeams.length;
  int get pageCount {
    if (filteredCount <= 0) return 1;
    return ((filteredCount - 1) ~/ recordsPerPage) + 1;
  }

  int get safeCurrentPage {
    if (currentPage < 1) return 1;
    if (currentPage > pageCount) return pageCount;
    return currentPage;
  }

  List<AdminTeamListItem> get visibleTeams {
    if (filteredTeams.isEmpty) return const <AdminTeamListItem>[];
    final start = (safeCurrentPage - 1) * recordsPerPage;
    if (start >= filteredTeams.length) return const <AdminTeamListItem>[];
    final end = (start + recordsPerPage).clamp(0, filteredTeams.length);
    return filteredTeams.sublist(start, end);
  }

  int get showingCount => visibleTeams.length;

  AdminTeamState copyWith({
    List<AdminTeamListItem>? teams,
    List<AdminTeamListItem>? filteredTeams,
    String? searchQuery,
    AdminTeamStatusFilter? statusFilter,
    AdminTeamSortOption? sortOption,
    int? recordsPerPage,
    int? currentPage,
    bool? isLoading,
    bool? isRefreshing,
    bool? isCreating,
    Object? errorMessage = _unset,
    Object? createErrorMessage = _unset,
    int? refreshKey,
  }) {
    return AdminTeamState(
      teams: teams ?? this.teams,
      filteredTeams: filteredTeams ?? this.filteredTeams,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      sortOption: sortOption ?? this.sortOption,
      recordsPerPage: recordsPerPage ?? this.recordsPerPage,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      createErrorMessage: identical(createErrorMessage, _unset)
          ? this.createErrorMessage
          : createErrorMessage as String?,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}
