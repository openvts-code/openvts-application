import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../models/user_subuser_model.dart';

class UserSubUserService {
  UserSubUserService(this._apiClient);

  final ApiClient _apiClient;

  static const int _maxLimit = 100;

  static final Options _readOptions = normalReadOptions();

  static final Options _mutationOptions = normalWriteOptions();

  Future<UserSubUsersPage> fetchSubUsers({
    String? search,
    int page = 1,
    int limit = 100,
    String? refreshKey,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedLimit = _normalizeLimit(limit);
    final normalizedSearch = search?.trim() ?? '';

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.user.subusers,
      queryParameters: <String, dynamic>{
        'page': normalizedPage,
        'limit': normalizedLimit,
        'rk': _resolveRefreshKey(refreshKey),
        if (normalizedSearch.isNotEmpty) 'search': normalizedSearch,
      },
      options: _readOptions,
      parser: (json) => json,
    );

    return UserSubUsersPage.fromJson(
      response.data,
      defaultPage: normalizedPage,
      defaultLimit: normalizedLimit,
    );
  }

  Future<UserSubUser> createSubUser(CreateUserSubUserRequest request) async {
    final response = await _apiClient.post<UserSubUser>(
      ApiEndpoints.user.subusers,
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserSubUser.fromJson,
    );

    final created = response.data;
    if (created.id.trim().isNotEmpty) {
      return created;
    }

    final probe = _firstNonEmpty(<String?>[
      request.username,
      request.email,
      request.mobileNumber,
      request.name,
    ]);

    final page = await fetchSubUsers(
      search: probe,
      page: 1,
      limit: _maxLimit,
      refreshKey: _resolveRefreshKey(null),
    );

    for (final item in page.items) {
      if (_matchesCreateCandidate(item, request)) {
        return item;
      }
    }

    return created;
  }

  Future<UserSubUser> fetchSubUserById(
    String id, {
    String? refreshKey,
  }) async {
    final subUserId = _requireId(id, 'id');
    final response = await _apiClient.get<UserSubUser>(
      ApiEndpoints.user.subuserById(subUserId),
      queryParameters: <String, dynamic>{
        'rk': _resolveRefreshKey(refreshKey),
      },
      options: _readOptions,
      parser: UserSubUser.fromJson,
    );
    return response.data;
  }

  Future<UserSubUser> updateSubUser(
    String id,
    UpdateUserSubUserRequest request,
  ) async {
    final subUserId = _requireId(id, 'id');

    final response = await _apiClient.patch<UserSubUser>(
      ApiEndpoints.user.subuserById(subUserId),
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserSubUser.fromJson,
    );

    final updated = response.data;
    if (updated.id.trim().isNotEmpty) {
      return updated;
    }

    return fetchSubUserById(subUserId, refreshKey: _resolveRefreshKey(null));
  }

  Future<void> deleteSubUser(String id) async {
    final subUserId = _requireId(id, 'id');
    await _apiClient.delete<void>(
      ApiEndpoints.user.subuserById(subUserId),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<List<UserSubUserVehicle>> fetchSubUserVehicles(String id) async {
    final subUserId = _requireId(id, 'id');
    final response = await _apiClient.get<List<UserSubUserVehicle>>(
      ApiEndpoints.user.subuserVehicles(subUserId),
      options: _readOptions,
      parser: UserSubUserVehicle.listFromJson,
    );
    return response.data;
  }

  Future<List<UserSubUserVehicle>> fetchAvailableVehicles() async {
    final response = await _apiClient.get<List<UserSubUserVehicle>>(
      ApiEndpoints.user.vehicles,
      options: _readOptions,
      parser: UserSubUserVehicle.listFromJson,
    );
    return response.data;
  }

  Future<void> assignVehicles(String subUserId, List<String> vehicleIds) async {
    final id = _requireId(subUserId, 'subUserId');
    final payload =
        UserSubUserVehicleAssignmentPayload(vehicleIds: vehicleIds).toJson();

    await _apiClient.post<void>(
      ApiEndpoints.user.assignSubuserVehicles(id),
      data: payload,
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> unassignVehicles(
    String subUserId,
    List<String> vehicleIds,
  ) async {
    final id = _requireId(subUserId, 'subUserId');
    final payload =
        UserSubUserVehicleAssignmentPayload(vehicleIds: vehicleIds).toJson();

    await _apiClient.post<void>(
      ApiEndpoints.user.unassignSubuserVehicles(id),
      data: payload,
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  int _normalizeLimit(int value) {
    if (value <= 0) {
      return _maxLimit;
    }

    if (value > _maxLimit) {
      return _maxLimit;
    }

    return value;
  }

  String _resolveRefreshKey(String? refreshKey) {
    final normalized = refreshKey?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }

    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String _requireId(String value, String fieldName) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('$fieldName is required.');
    }
    return normalized;
  }

  bool _matchesCreateCandidate(
    UserSubUser item,
    CreateUserSubUserRequest request,
  ) {
    final username = request.username?.trim().toLowerCase();
    final email = request.email?.trim().toLowerCase();
    final mobile = request.mobileNumber?.trim();

    if (username != null && username.isNotEmpty) {
      if (item.username.trim().toLowerCase() == username) {
        return true;
      }
    }

    if (email != null && email.isNotEmpty) {
      if (item.email.trim().toLowerCase() == email) {
        return true;
      }
    }

    if (mobile != null && mobile.isNotEmpty) {
      if (item.mobileNumber.trim() == mobile) {
        return true;
      }
    }

    final normalizedName = request.name.trim().toLowerCase();
    if (normalizedName.isNotEmpty &&
        item.name.trim().toLowerCase() == normalizedName) {
      return true;
    }

    return false;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }
}
