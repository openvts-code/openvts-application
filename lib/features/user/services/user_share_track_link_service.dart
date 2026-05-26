import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/user_share_track_link_model.dart';

class UserShareTrackLinkService {
  UserShareTrackLinkService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );

  static final Options _mutationOptions = Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  );

  Future<UserShareTrackLinksPage> getShareTrackLinks({
    int page = 1,
    int limit = 50,
    String? search,
    String? refreshKey,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedLimit = limit < 1 ? 50 : limit;
    final response = await _apiClient.get<UserShareTrackLinksPage>(
      ApiEndpoints.user.shareTrackLinks,
      queryParameters: _query(<String, dynamic>{
        'page': normalizedPage,
        'limit': normalizedLimit,
        'search': search,
      }),
      options: _readOptions,
      parser: (json) => UserShareTrackLinksPage.fromJson(
        json,
        defaultPage: normalizedPage,
        defaultLimit: normalizedLimit,
      ),
    );
    return response.data;
  }

  Future<UserShareTrackLink> getShareTrackLinkById(String id) async {
    final linkId = _requireId(id, 'id');
    final response = await _apiClient.get<UserShareTrackLink>(
      ApiEndpoints.user.shareTrackLinkById(linkId),
      options: _readOptions,
      parser: UserShareTrackLink.fromJson,
    );
    return response.data;
  }

  Future<UserShareTrackLinkMutationResult> createShareTrackLink(
    UserCreateShareTrackLinkRequest request,
  ) async {
    final response = await _apiClient.post<UserShareTrackLink>(
      ApiEndpoints.user.shareTrackLinks,
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserShareTrackLink.fromJson,
    );
    return UserShareTrackLinkMutationResult(
      link: response.data,
      message: response.message,
    );
  }

  Future<UserShareTrackLinkMutationResult> updateShareTrackLink({
    required String id,
    required UserUpdateShareTrackLinkRequest request,
  }) async {
    final linkId = _requireId(id, 'id');
    final response = await _apiClient.patch<UserShareTrackLink>(
      ApiEndpoints.user.shareTrackLinkById(linkId),
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserShareTrackLink.fromJson,
    );
    return UserShareTrackLinkMutationResult(
      link: response.data,
      message: response.message,
    );
  }

  Future<void> deleteShareTrackLink(UserShareTrackLink link) async {
    final linkId = _requireId(link.id, 'id');
    await _apiClient.delete<void>(
      ApiEndpoints.user.shareTrackLinkById(linkId),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<List<UserShareTrackVehicle>> getVehicles() async {
    final response = await _apiClient.get<List<UserShareTrackVehicle>>(
      ApiEndpoints.user.vehicles,
      options: _readOptions,
      parser: UserShareTrackVehicle.listFromJson,
    );
    return response.data;
  }

  String _requireId(String value, String fieldName) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('$fieldName is required.');
    }
    return normalized;
  }

  Map<String, dynamic>? _query(Map<String, dynamic> values) {
    final query = <String, dynamic>{};
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      query[entry.key] = value;
    }
    return query.isEmpty ? null : query;
  }
}

class UserShareTrackLinkMutationResult {
  const UserShareTrackLinkMutationResult({
    required this.link,
    this.message,
  });

  final UserShareTrackLink link;
  final String? message;
}
