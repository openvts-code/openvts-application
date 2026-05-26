import 'user_subuser_model.dart';

class UserSubUsersState {
  const UserSubUsersState({
    required this.subUsers,
    required this.searchQuery,
    required this.page,
    required this.limit,
    required this.total,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.isCreating,
    required this.togglingIds,
    required this.errorMessage,
    required this.refreshKey,
  });

  const UserSubUsersState.initial()
      : subUsers = const <UserSubUser>[],
        searchQuery = '',
        page = 1,
        limit = 100,
        total = 0,
        isLoading = false,
        isRefreshing = false,
        isLoadingMore = false,
        isCreating = false,
        togglingIds = const <String>{},
        errorMessage = null,
        refreshKey = null;

  static const Object _unset = Object();

  final List<UserSubUser> subUsers;
  final String searchQuery;
  final int page;
  final int limit;
  final int total;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isCreating;
  final Set<String> togglingIds;
  final String? errorMessage;
  final String? refreshKey;

  bool get hasSubUsers => subUsers.isNotEmpty;

  bool get hasMore {
    if (limit <= 0) {
      return false;
    }
    return page * limit < total;
  }

  int get activeCount => subUsers.where((item) => item.isActive).length;

  int get inactiveCount => subUsers.where((item) => !item.isActive).length;

  bool get hasActiveFilters => searchQuery.trim().isNotEmpty;

  UserSubUsersState copyWith({
    List<UserSubUser>? subUsers,
    String? searchQuery,
    int? page,
    int? limit,
    int? total,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isCreating,
    Set<String>? togglingIds,
    Object? errorMessage = _unset,
    Object? refreshKey = _unset,
  }) {
    return UserSubUsersState(
      subUsers: subUsers ?? this.subUsers,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      togglingIds: togglingIds ?? this.togglingIds,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      refreshKey: identical(refreshKey, _unset)
          ? this.refreshKey
          : refreshKey as String?,
    );
  }
}

class UserSubUserDetailsState {
  const UserSubUserDetailsState({
    required this.subUser,
    required this.assignedVehicles,
    required this.availableVehicles,
    required this.selectedVehicleIds,
    required this.isLoading,
    required this.isSaving,
    required this.isDeleting,
    required this.isTogglingStatus,
    required this.isLoadingVehicles,
    required this.isAssigningVehicles,
    required this.isUnassigningVehicles,
    required this.errorMessage,
  });

  const UserSubUserDetailsState.initial()
      : subUser = null,
        assignedVehicles = const <UserSubUserVehicle>[],
        availableVehicles = const <UserSubUserVehicle>[],
        selectedVehicleIds = const <String>{},
        isLoading = true,
        isSaving = false,
        isDeleting = false,
        isTogglingStatus = false,
        isLoadingVehicles = false,
        isAssigningVehicles = false,
        isUnassigningVehicles = false,
        errorMessage = null;

  static const Object _unset = Object();

  final UserSubUser? subUser;
  final List<UserSubUserVehicle> assignedVehicles;
  final List<UserSubUserVehicle> availableVehicles;
  final Set<String> selectedVehicleIds;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final bool isTogglingStatus;
  final bool isLoadingVehicles;
  final bool isAssigningVehicles;
  final bool isUnassigningVehicles;
  final String? errorMessage;

  UserSubUserDetailsState copyWith({
    Object? subUser = _unset,
    List<UserSubUserVehicle>? assignedVehicles,
    List<UserSubUserVehicle>? availableVehicles,
    Set<String>? selectedVehicleIds,
    bool? isLoading,
    bool? isSaving,
    bool? isDeleting,
    bool? isTogglingStatus,
    bool? isLoadingVehicles,
    bool? isAssigningVehicles,
    bool? isUnassigningVehicles,
    Object? errorMessage = _unset,
  }) {
    return UserSubUserDetailsState(
      subUser:
          identical(subUser, _unset) ? this.subUser : subUser as UserSubUser?,
      assignedVehicles: assignedVehicles ?? this.assignedVehicles,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      selectedVehicleIds: selectedVehicleIds ?? this.selectedVehicleIds,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      isTogglingStatus: isTogglingStatus ?? this.isTogglingStatus,
      isLoadingVehicles: isLoadingVehicles ?? this.isLoadingVehicles,
      isAssigningVehicles: isAssigningVehicles ?? this.isAssigningVehicles,
      isUnassigningVehicles:
          isUnassigningVehicles ?? this.isUnassigningVehicles,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
