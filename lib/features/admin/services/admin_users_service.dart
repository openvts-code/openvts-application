import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/admin_users_model.dart';

class AdminUsersService {
  AdminUsersService(this._apiClient);

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );

  static final Options _mutationOptions = Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  );

  final ApiClient _apiClient;

  Future<List<AdminUserListItem>> getUsers({
    String? refreshKey,
    String? search,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.users,
      queryParameters: _queryParameters(
        refreshKey: refreshKey,
        search: search,
      ),
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminUserListItem.listFromJson(response.data);
  }

  Future<AdminUserDetails> getUserById(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.userById(id),
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminUserDetails.fromJson(response.data, fallbackId: id);
  }

  Future<List<AdminUserCountryOption>> getCountries() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.countries,
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminUserCountryOption.listFromJson(response.data);
  }

  Future<List<AdminUserMobilePrefixOption>> getMobilePrefixes() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.mobilePrefix,
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminUserMobilePrefixOption.listFromJson(response.data);
  }

  Future<List<AdminUserStateOption>> getStates(String countryCode) async {
    final normalizedCountryCode = countryCode.trim().toUpperCase();
    if (normalizedCountryCode.isEmpty) {
      return const <AdminUserStateOption>[];
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.states(normalizedCountryCode),
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminUserStateOption.listFromJson(response.data);
  }

  Future<List<AdminUserCityOption>> getCities(
    String countryCode,
    String stateCode,
  ) async {
    final normalizedCountryCode = countryCode.trim().toUpperCase();
    final normalizedStateCode = stateCode.trim().toUpperCase();
    if (normalizedCountryCode.isEmpty || normalizedStateCode.isEmpty) {
      return const <AdminUserCityOption>[];
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.cities(
        normalizedCountryCode,
        normalizedStateCode,
      ),
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminUserCityOption.listFromJson(response.data);
  }

  Future<AdminUserDetails> createUser(AdminCreateUserRequest request) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.users,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );

    return AdminUserDetails.fromJson(response.data);
  }

  Future<AdminUserDetails> updateUser({
    required String id,
    required AdminUpdateUserRequest request,
  }) async {
    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.admin.userById(id),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    final patchUser = AdminUserDetails.fromJson(response.data, fallbackId: id);

    try {
      return await getUserById(id);
    } catch (_) {
      return patchUser;
    }
  }

  Future<void> updateUserStatus({
    required String id,
    required bool isActive,
  }) async {
    await _apiClient.patch<void>(
      ApiEndpoints.admin.userById(id),
      data: <String, dynamic>{'isActive': isActive},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> deleteUser(String id) async {
    await _apiClient.delete<void>(
      ApiEndpoints.admin.userById(id),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<AdminUserLoginResult> loginAsUser(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.userLogin(id),
      options: _mutationOptions,
      parser: (json) => json,
    );

    return AdminUserLoginResult.fromJson(response.data);
  }

  Future<void> updateUserPassword({
    required String id,
    required String newPassword,
  }) async {
    await _apiClient.post<void>(
      ApiEndpoints.admin.updateUserPassword(id),
      data: AdminUpdateUserPasswordRequest(newPassword: newPassword).toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Map<String, dynamic>? _queryParameters({
    String? refreshKey,
    String? search,
  }) {
    final query = <String, dynamic>{};
    final normalizedRefreshKey = refreshKey?.trim();
    if (normalizedRefreshKey != null && normalizedRefreshKey.isNotEmpty) {
      query['rk'] = normalizedRefreshKey;
    }

    final normalizedSearch = search?.trim();
    if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }

    return query.isEmpty ? null : query;
  }
}
