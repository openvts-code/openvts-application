import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/admin_users_model.dart';
import '../models/admin_users_state.dart';
import '../services/admin_users_service.dart';

class AdminUsersController extends StateNotifier<AdminUsersState> {
  AdminUsersController({
    required AdminUsersService service,
    required AuthController authController,
  })  : _service = service,
        _authController = authController,
        super(const AdminUsersState.initial());

  final AdminUsersService _service;
  final AuthController _authController;

  Future<void> load() async {
    await _fetchUsers(
      refreshKey: state.refreshKey == 0 ? null : state.refreshKey.toString(),
      refreshing: state.hasUsers,
    );
  }

  Future<void> refresh() async {
    final nextRefreshKey = state.refreshKey + 1;
    state = state.copyWith(refreshKey: nextRefreshKey);
    await _fetchUsers(
      refreshKey: nextRefreshKey.toString(),
      refreshing: true,
    );
  }

  void setSearchQuery(String value) {
    state = _withFilteredUsers(
      state.copyWith(
        searchQuery: value,
        currentPage: 1,
        errorMessage: null,
      ),
    );
  }

  void setStatusFilter(AdminUserStatusFilter value) {
    state = _withFilteredUsers(
      state.copyWith(
        statusFilter: value,
        currentPage: 1,
        errorMessage: null,
      ),
    );
  }

  void setVerifiedFilter(AdminUserVerifiedFilter value) {
    state = _withFilteredUsers(
      state.copyWith(
        verifiedFilter: value,
        currentPage: 1,
        errorMessage: null,
      ),
    );
  }

  void setCountryFilter(String? value) {
    final normalized = value?.trim().toUpperCase();
    state = _withFilteredUsers(
      state.copyWith(
        countryFilter:
            normalized == null || normalized.isEmpty ? null : normalized,
        currentPage: 1,
        errorMessage: null,
      ),
    );
  }

  void setSortOption(AdminUsersSortOption value) {
    state = _withFilteredUsers(
      state.copyWith(
        sortOption: value,
        currentPage: 1,
        errorMessage: null,
      ),
    );
  }

  void setRecordsPerPage(int value) {
    state = state.copyWith(
      recordsPerPage: value,
      currentPage: 1,
    );
  }

  void goToPage(int value) {
    state = state.copyWith(currentPage: value);
  }

  void clearFilters() {
    state = _withFilteredUsers(
      state.copyWith(
        searchQuery: '',
        statusFilter: AdminUserStatusFilter.all,
        verifiedFilter: AdminUserVerifiedFilter.all,
        countryFilter: null,
        currentPage: 1,
        errorMessage: null,
      ),
    );
  }

  Future<AdminUserDetails> getUserDetails(String id) {
    return _service.getUserById(id);
  }

  Future<List<AdminUserCountryOption>> getCountries() {
    return _service.getCountries();
  }

  Future<List<AdminUserMobilePrefixOption>> getMobilePrefixes() {
    return _service.getMobilePrefixes();
  }

  Future<List<AdminUserStateOption>> getStates(String countryCode) {
    return _service.getStates(countryCode);
  }

  Future<List<AdminUserCityOption>> getCities(
    String countryCode,
    String stateCode,
  ) {
    return _service.getCities(countryCode, stateCode);
  }

  Future<void> createUser(AdminCreateUserRequest request) async {
    state = state.copyWith(
      isCreating: true,
      errorMessage: null,
    );

    try {
      await _service.createUser(request);
      if (!mounted) {
        return;
      }

      state = state.copyWith(isCreating: false);
      await refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isCreating: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> updateUser(String id, AdminUpdateUserRequest request) async {
    state = state.copyWith(
      updatingIds: _addId(state.updatingIds, id),
      errorMessage: null,
    );

    try {
      final updatedUser = await _service.updateUser(
        id: id,
        request: request,
      );
      if (!mounted) {
        return;
      }

      state = _withFilteredUsers(
        state.copyWith(
          users: _replaceUser(state.users, updatedUser),
          updatingIds: _removeId(state.updatingIds, id),
          errorMessage: null,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        updatingIds: _removeId(state.updatingIds, id),
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> updateUserStatus(String id, bool isActive) async {
    final previousUsers = state.users;
    state = _withFilteredUsers(
      state.copyWith(
        users: _updateUserStatusLocally(state.users, id, isActive),
        updatingIds: _addId(state.updatingIds, id),
        errorMessage: null,
      ),
    );

    try {
      await _service.updateUserStatus(id: id, isActive: isActive);
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        updatingIds: _removeId(state.updatingIds, id),
        errorMessage: null,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = _withFilteredUsers(
        state.copyWith(
          users: previousUsers,
          updatingIds: _removeId(state.updatingIds, id),
          errorMessage: _toErrorMessage(error),
        ),
      );
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    state = state.copyWith(
      deletingIds: _addId(state.deletingIds, id),
      errorMessage: null,
    );

    try {
      await _service.deleteUser(id);
      if (!mounted) {
        return;
      }

      state = _withFilteredUsers(
        state.copyWith(
          users: _removeUser(state.users, id),
          deletingIds: _removeId(state.deletingIds, id),
          errorMessage: null,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        deletingIds: _removeId(state.deletingIds, id),
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<AdminUserLoginResult> loginAsUser(String id) async {
    state = state.copyWith(
      loggingInIds: _addId(state.loggingInIds, id),
      errorMessage: null,
    );

    try {
      final result = await _service.loginAsUser(id);
      if (!result.hasSession) {
        throw Exception('User login did not return an access token.');
      }

      await _authController.setSession(result.toLoginResponse());
      if (mounted) {
        state = state.copyWith(
          loggingInIds: _removeId(state.loggingInIds, id),
          errorMessage: null,
        );
      }
      return result;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          loggingInIds: _removeId(state.loggingInIds, id),
          errorMessage: _toErrorMessage(error),
        );
      }
      rethrow;
    }
  }

  Future<void> updateUserPassword(String id, String newPassword) async {
    state = state.copyWith(
      updatingIds: _addId(state.updatingIds, id),
      errorMessage: null,
    );

    try {
      await _service.updateUserPassword(
        id: id,
        newPassword: newPassword,
      );
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        updatingIds: _removeId(state.updatingIds, id),
        errorMessage: null,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        updatingIds: _removeId(state.updatingIds, id),
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> _fetchUsers({
    String? refreshKey,
    required bool refreshing,
  }) async {
    final hasExistingUsers = state.hasUsers;
    state = state.copyWith(
      isLoading: !hasExistingUsers && !refreshing,
      isRefreshing: hasExistingUsers || refreshing,
      errorMessage: null,
    );

    try {
      final users = await _service.getUsers(refreshKey: refreshKey);
      if (!mounted) {
        return;
      }

      state = _withFilteredUsers(
        state.copyWith(
          users: users,
          isLoading: false,
          isRefreshing: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  AdminUsersState _withFilteredUsers(AdminUsersState nextState) {
    return nextState.copyWith(filteredUsers: _filterUsers(nextState));
  }

  List<AdminUserListItem> _filterUsers(AdminUsersState nextState) {
    final filteredUsers = nextState.users.where((user) {
      final matchesSearch = user.matchesQuery(nextState.searchQuery);
      final matchesStatus = switch (nextState.statusFilter) {
        AdminUserStatusFilter.all => true,
        AdminUserStatusFilter.active => user.isActive,
        AdminUserStatusFilter.inactive => !user.isActive,
      };
      final matchesVerified = switch (nextState.verifiedFilter) {
        AdminUserVerifiedFilter.all => true,
        AdminUserVerifiedFilter.verified => user.isEmailVerified,
        AdminUserVerifiedFilter.unverified => !user.isEmailVerified,
      };
      final countryFilter = nextState.countryFilter;
      final matchesCountry = countryFilter == null ||
          user.countryCode.trim().toUpperCase() == countryFilter;

      return matchesSearch &&
          matchesStatus &&
          matchesVerified &&
          matchesCountry;
    }).toList(growable: false);

    return _sortUsers(filteredUsers, nextState.sortOption);
  }

  List<AdminUserListItem> _sortUsers(
    List<AdminUserListItem> users,
    AdminUsersSortOption sortOption,
  ) {
    if (users.length < 2) {
      return users;
    }

    final sortedUsers = users.toList(growable: false);
    switch (sortOption) {
      case AdminUsersSortOption.newest:
        if (!sortedUsers.any((user) => user.createdAt != null)) {
          return users;
        }
        sortedUsers.sort((left, right) {
          final leftDate = left.createdAt;
          final rightDate = right.createdAt;
          if (leftDate == null && rightDate == null) {
            return 0;
          }
          if (leftDate == null) {
            return 1;
          }
          if (rightDate == null) {
            return -1;
          }
          return rightDate.compareTo(leftDate);
        });
      case AdminUsersSortOption.nameAz:
        sortedUsers.sort(
          (left, right) => _sortName(left).compareTo(_sortName(right)),
        );
      case AdminUsersSortOption.mostVehicles:
        sortedUsers.sort((left, right) {
          final vehicleCompare = right.vehicleCount.compareTo(
            left.vehicleCount,
          );
          if (vehicleCompare != 0) {
            return vehicleCompare;
          }
          return _sortName(left).compareTo(_sortName(right));
        });
    }

    return sortedUsers;
  }

  String _sortName(AdminUserListItem user) {
    final name = user.name.trim();
    if (name.isNotEmpty) {
      return name.toLowerCase();
    }
    final username = user.username.trim();
    if (username.isNotEmpty) {
      return username.toLowerCase();
    }
    return user.email.trim().toLowerCase();
  }

  List<AdminUserListItem> _replaceUser(
    List<AdminUserListItem> users,
    AdminUserListItem updatedUser,
  ) {
    var found = false;
    final updatedUsers = users.map((user) {
      if (user.id != updatedUser.id) {
        return user;
      }

      found = true;
      return _mergeUser(user, updatedUser);
    }).toList(growable: true);

    if (!found && updatedUser.id.isNotEmpty) {
      updatedUsers.add(updatedUser);
    }

    return updatedUsers;
  }

  AdminUserListItem _mergeUser(
    AdminUserListItem currentUser,
    AdminUserListItem updatedUser,
  ) {
    final raw = updatedUser is AdminUserDetails
        ? updatedUser.raw
        : const <String, dynamic>{};

    return currentUser.copyWith(
      id: updatedUser.id.isEmpty ? currentUser.id : updatedUser.id,
      name: updatedUser.name.isEmpty ? currentUser.name : updatedUser.name,
      username: updatedUser.username.isEmpty
          ? currentUser.username
          : updatedUser.username,
      email: updatedUser.email.isEmpty ? currentUser.email : updatedUser.email,
      mobilePrefix: updatedUser.mobilePrefix.isEmpty
          ? currentUser.mobilePrefix
          : updatedUser.mobilePrefix,
      mobileNumber: updatedUser.mobileNumber.isEmpty
          ? currentUser.mobileNumber
          : updatedUser.mobileNumber,
      mobileDisplay: updatedUser.mobileDisplay.isEmpty
          ? currentUser.mobileDisplay
          : updatedUser.mobileDisplay,
      isEmailVerified: _containsAny(raw, const [
        'isEmailVerified',
        'is_email_verified',
        'isemailvarified',
        'isEmailVarified',
        'emailVerified',
        'email_verified',
        'verified',
        'isVerified',
        'is_verified',
      ])
          ? updatedUser.isEmailVerified
          : currentUser.isEmailVerified,
      isActive: _containsAny(raw, const [
        'isActive',
        'is_active',
        'isactive',
        'active',
        'status',
      ])
          ? updatedUser.isActive
          : currentUser.isActive,
      companyName: updatedUser.companyName == '-'
          ? currentUser.companyName
          : updatedUser.companyName,
      location: updatedUser.location == '-'
          ? currentUser.location
          : updatedUser.location,
      countryCode: updatedUser.countryCode.isEmpty
          ? currentUser.countryCode
          : updatedUser.countryCode,
      stateCode: updatedUser.stateCode.isEmpty
          ? currentUser.stateCode
          : updatedUser.stateCode,
      city: updatedUser.city.isEmpty ? currentUser.city : updatedUser.city,
      pincode: updatedUser.pincode.isEmpty
          ? currentUser.pincode
          : updatedUser.pincode,
      vehicleCount: _containsAny(raw, const [
        'totalvehicles',
        'totalVehicles',
        'vehicleCount',
        'vehiclesCount',
        'vehicles_count',
        'vehicles',
      ])
          ? updatedUser.vehicleCount
          : currentUser.vehicleCount,
      createdAt: updatedUser.createdAt,
      updatedAt: updatedUser.updatedAt,
    );
  }

  List<AdminUserListItem> _updateUserStatusLocally(
    List<AdminUserListItem> users,
    String id,
    bool isActive,
  ) {
    return users
        .map(
          (user) => user.id == id ? user.copyWith(isActive: isActive) : user,
        )
        .toList(growable: false);
  }

  List<AdminUserListItem> _removeUser(
    List<AdminUserListItem> users,
    String id,
  ) {
    return users.where((user) => user.id != id).toList(growable: false);
  }

  Set<String> _addId(Set<String> ids, String id) {
    return <String>{...ids, id};
  }

  Set<String> _removeId(Set<String> ids, String id) {
    return ids.where((value) => value != id).toSet();
  }

  bool _containsAny(Map<String, dynamic> map, List<String> keys) {
    return keys.any(map.containsKey);
  }

  String _toErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is DioException) {
      final responseMessage = _extractResponseMessage(error.response?.data);
      if (responseMessage != null) {
        return responseMessage;
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Please try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server right now.';
      }

      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }

    return raw;
  }

  String? _extractResponseMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in const ['message', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }

        if (value is List) {
          final parts = value
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }

      final nestedData = data['data'];
      if (!identical(nestedData, data)) {
        return _extractResponseMessage(nestedData);
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }
}
