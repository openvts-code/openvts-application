import 'dart:math' as math;

import 'admin_users_model.dart';

enum AdminUserStatusFilter {
  all,
  active,
  inactive;

  String get label {
    switch (this) {
      case AdminUserStatusFilter.all:
        return 'All statuses';
      case AdminUserStatusFilter.active:
        return 'Active';
      case AdminUserStatusFilter.inactive:
        return 'Inactive';
    }
  }
}

enum AdminUserVerifiedFilter {
  all,
  verified,
  unverified;

  String get label {
    switch (this) {
      case AdminUserVerifiedFilter.all:
        return 'All users';
      case AdminUserVerifiedFilter.verified:
        return 'Verified';
      case AdminUserVerifiedFilter.unverified:
        return 'Unverified';
    }
  }
}

enum AdminUsersSortOption {
  newest,
  nameAz,
  mostVehicles;

  String get label {
    switch (this) {
      case AdminUsersSortOption.newest:
        return 'Newest';
      case AdminUsersSortOption.nameAz:
        return 'Name A-Z';
      case AdminUsersSortOption.mostVehicles:
        return 'Most Vehicles';
    }
  }
}

class AdminUsersState {
  const AdminUsersState({
    required this.users,
    required this.filteredUsers,
    required this.searchQuery,
    required this.statusFilter,
    required this.verifiedFilter,
    required this.countryFilter,
    required this.sortOption,
    required this.recordsPerPage,
    required this.currentPage,
    required this.isLoading,
    required this.isRefreshing,
    required this.isCreating,
    required this.updatingIds,
    required this.deletingIds,
    required this.loggingInIds,
    required this.errorMessage,
    required this.refreshKey,
  });

  const AdminUsersState.initial()
      : users = const <AdminUserListItem>[],
        filteredUsers = const <AdminUserListItem>[],
        searchQuery = '',
        statusFilter = AdminUserStatusFilter.all,
        verifiedFilter = AdminUserVerifiedFilter.all,
        countryFilter = null,
        sortOption = AdminUsersSortOption.newest,
        recordsPerPage = 10,
        currentPage = 1,
        isLoading = true,
        isRefreshing = false,
        isCreating = false,
        updatingIds = const <String>{},
        deletingIds = const <String>{},
        loggingInIds = const <String>{},
        errorMessage = null,
        refreshKey = 0;

  static const _unset = Object();

  final List<AdminUserListItem> users;
  final List<AdminUserListItem> filteredUsers;
  final String searchQuery;
  final AdminUserStatusFilter statusFilter;
  final AdminUserVerifiedFilter verifiedFilter;
  final String? countryFilter;
  final AdminUsersSortOption sortOption;
  final int recordsPerPage;
  final int currentPage;
  final bool isLoading;
  final bool isRefreshing;
  final bool isCreating;
  final Set<String> updatingIds;
  final Set<String> deletingIds;
  final Set<String> loggingInIds;
  final String? errorMessage;
  final int refreshKey;

  bool get hasUsers => users.isNotEmpty;
  bool get hasFilteredUsers => filteredUsers.isNotEmpty;
  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      statusFilter != AdminUserStatusFilter.all ||
      verifiedFilter != AdminUserVerifiedFilter.all ||
      countryFilter != null;

  int get filteredCount => filteredUsers.length;

  int get pageCount => math.max<int>(1, (filteredCount / recordsPerPage).ceil());

  int get safeCurrentPage => currentPage.clamp(1, pageCount);

  List<AdminUserListItem> get visibleUsers {
    final start = (safeCurrentPage - 1) * recordsPerPage;
    if (start >= filteredCount) {
      return const <AdminUserListItem>[];
    }
    return filteredUsers
        .skip(start)
        .take(recordsPerPage)
        .toList(growable: false);
  }

  int get showingCount => visibleUsers.length;

  bool isUpdating(String id) => updatingIds.contains(id);
  bool isDeleting(String id) => deletingIds.contains(id);
  bool isLoggingIn(String id) => loggingInIds.contains(id);

  AdminUsersState copyWith({
    List<AdminUserListItem>? users,
    List<AdminUserListItem>? filteredUsers,
    String? searchQuery,
    AdminUserStatusFilter? statusFilter,
    AdminUserVerifiedFilter? verifiedFilter,
    Object? countryFilter = _unset,
    AdminUsersSortOption? sortOption,
    int? recordsPerPage,
    int? currentPage,
    bool? isLoading,
    bool? isRefreshing,
    bool? isCreating,
    Set<String>? updatingIds,
    Set<String>? deletingIds,
    Set<String>? loggingInIds,
    Object? errorMessage = _unset,
    int? refreshKey,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      verifiedFilter: verifiedFilter ?? this.verifiedFilter,
      countryFilter: identical(countryFilter, _unset)
          ? this.countryFilter
          : countryFilter as String?,
      sortOption: sortOption ?? this.sortOption,
      recordsPerPage: recordsPerPage ?? this.recordsPerPage,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCreating: isCreating ?? this.isCreating,
      updatingIds: updatingIds ?? this.updatingIds,
      deletingIds: deletingIds ?? this.deletingIds,
      loggingInIds: loggingInIds ?? this.loggingInIds,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}
