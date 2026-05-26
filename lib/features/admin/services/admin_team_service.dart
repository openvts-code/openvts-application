import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/admin_team_model.dart';

class AdminTeamService {
  AdminTeamService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );

  static final Options _mutationOptions = Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  );

  Future<List<AdminTeamListItem>> getTeams({String? refreshKey}) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.teams,
      queryParameters: _queryParameters(refreshKey: refreshKey),
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminTeamListItem.listFromJson(response.data);
  }

  Future<AdminTeamListItem> createTeam(AdminCreateTeamRequest request) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.teams,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );

    final createdItems = AdminTeamListItem.listFromJson(response.data);
    if (createdItems.isNotEmpty) {
      return createdItems.first;
    }

    final asMap = _asMap(response.data);
    final fallback = AdminTeamListItem.fromJson(<String, dynamic>{
      ...request.toJson(),
      ...asMap,
    });
    return fallback;
  }

  Future<List<AdminTeamMobilePrefixOption>> getMobilePrefixes() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.mobilePrefix,
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminTeamMobilePrefixOption.listFromJson(response.data);
  }

  Map<String, dynamic>? _queryParameters({String? refreshKey}) {
    final normalizedRefreshKey = refreshKey?.trim();
    if (normalizedRefreshKey == null || normalizedRefreshKey.isEmpty) {
      return null;
    }

    return <String, dynamic>{'rk': normalizedRefreshKey};
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return const <String, dynamic>{};
  }
}
