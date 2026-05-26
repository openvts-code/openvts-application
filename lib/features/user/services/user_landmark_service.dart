import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../models/user_landmark_model.dart';

/// Service layer for the user-scope Landmark Studio (geofences, POIs, routes
/// and bulk import jobs). All HTTP traffic goes through [ApiClient]; this
/// service is the only layer permitted to call those endpoints — widgets and
/// controllers must depend on this service, not on Dio directly.
class UserLandmarkService {
  UserLandmarkService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = normalReadOptions();

  static final Options _mutationOptions = normalWriteOptions();

  // ---------------------------------------------------------------------
  // Geofences
  // ---------------------------------------------------------------------

  Future<List<UserGeofence>> fetchGeofences({
    String? search,
    bool? isActive,
    UserGeofenceType? type,
    String? refreshKey,
  }) async {
    final response = await _apiClient.get<List<UserGeofence>>(
      ApiEndpoints.user.geofences,
      queryParameters: _query(<String, dynamic>{
        'q': search,
        'isActive': isActive,
        'type': type?.apiValue,
        'rk': refreshKey,
      }),
      options: _readOptions,
      parser: UserGeofence.listFromJson,
    );
    return response.data;
  }

  Future<UserGeofence> fetchGeofenceById(String id) async {
    final geofenceId = _requireId(id, 'geofenceId');
    final response = await _apiClient.get<UserGeofence>(
      ApiEndpoints.user.geofenceById(geofenceId),
      options: _readOptions,
      parser: UserGeofence.fromJson,
    );
    return response.data;
  }

  Future<UserGeofence> createGeofence(
    CreateUserGeofenceRequest request,
  ) async {
    final response = await _apiClient.post<UserGeofence>(
      ApiEndpoints.user.geofences,
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserGeofence.fromJson,
    );
    return response.data;
  }

  Future<UserGeofence> updateGeofence(
    String id,
    UpdateUserGeofenceRequest request,
  ) async {
    final geofenceId = _requireId(id, 'geofenceId');
    final response = await _apiClient.patch<UserGeofence>(
      ApiEndpoints.user.geofenceById(geofenceId),
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserGeofence.fromJson,
    );
    return response.data;
  }

  Future<void> deleteGeofence(String id) async {
    final geofenceId = _requireId(id, 'geofenceId');
    await _apiClient.delete<void>(
      ApiEndpoints.user.geofenceById(geofenceId),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  // ---------------------------------------------------------------------
  // POIs
  // ---------------------------------------------------------------------

  Future<List<UserPoi>> fetchPois({
    String? search,
    bool? isActive,
    String? refreshKey,
  }) async {
    final response = await _apiClient.get<List<UserPoi>>(
      ApiEndpoints.user.pois,
      queryParameters: _query(<String, dynamic>{
        'q': search,
        'isActive': isActive,
        'rk': refreshKey,
      }),
      options: _readOptions,
      parser: UserPoi.listFromJson,
    );
    return response.data;
  }

  Future<UserPoi> fetchPoiById(String id) async {
    final poiId = _requireId(id, 'poiId');
    final response = await _apiClient.get<UserPoi>(
      ApiEndpoints.user.poiById(poiId),
      options: _readOptions,
      parser: UserPoi.fromJson,
    );
    return response.data;
  }

  Future<UserPoi> createPoi(CreateUserPoiRequest request) async {
    final response = await _apiClient.post<UserPoi>(
      ApiEndpoints.user.pois,
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserPoi.fromJson,
    );
    return response.data;
  }

  Future<UserPoi> updatePoi(String id, UpdateUserPoiRequest request) async {
    final poiId = _requireId(id, 'poiId');
    final response = await _apiClient.patch<UserPoi>(
      ApiEndpoints.user.poiById(poiId),
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserPoi.fromJson,
    );
    return response.data;
  }

  Future<void> deletePoi(String id) async {
    final poiId = _requireId(id, 'poiId');
    await _apiClient.delete<void>(
      ApiEndpoints.user.poiById(poiId),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  // ---------------------------------------------------------------------
  // Routes
  // ---------------------------------------------------------------------

  Future<List<UserRouteLandmark>> fetchRoutes({
    String? search,
    bool? isActive,
    bool includeGeodata = true,
    String? refreshKey,
  }) async {
    final response = await _apiClient.get<List<UserRouteLandmark>>(
      ApiEndpoints.user.routes,
      queryParameters: _query(<String, dynamic>{
        'q': search,
        'isActive': isActive,
        'includeGeodata': includeGeodata,
        'rk': refreshKey,
      }),
      options: _readOptions,
      parser: UserRouteLandmark.listFromJson,
    );
    return response.data;
  }

  Future<UserRouteLandmark> fetchRouteById(String id) async {
    final routeId = _requireId(id, 'routeId');
    final response = await _apiClient.get<UserRouteLandmark>(
      ApiEndpoints.user.routeById(routeId),
      options: _readOptions,
      parser: UserRouteLandmark.fromJson,
    );
    return response.data;
  }

  Future<UserRouteLandmark> createRoute(
    CreateUserRouteRequest request,
  ) async {
    final response = await _apiClient.post<UserRouteLandmark>(
      ApiEndpoints.user.routes,
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserRouteLandmark.fromJson,
    );
    return response.data;
  }

  Future<UserRouteLandmark> updateRoute(
    String id,
    UpdateUserRouteRequest request,
  ) async {
    final routeId = _requireId(id, 'routeId');
    final response = await _apiClient.patch<UserRouteLandmark>(
      ApiEndpoints.user.routeById(routeId),
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserRouteLandmark.fromJson,
    );
    return response.data;
  }

  Future<void> deleteRoute(String id) async {
    final routeId = _requireId(id, 'routeId');
    await _apiClient.delete<void>(
      ApiEndpoints.user.routeById(routeId),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  // ---------------------------------------------------------------------
  // Bulk jobs
  // ---------------------------------------------------------------------

  Future<UserLandmarkBulkJob> createBulkJob(
    CreateUserLandmarkBulkJobRequest request,
  ) async {
    final response = await _apiClient.post<UserLandmarkBulkJob>(
      ApiEndpoints.user.landmarkBulkJobs,
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserLandmarkBulkJob.fromJson,
    );
    return response.data;
  }

  Future<UserLandmarkBulkJob> fetchBulkJob(String id) async {
    final jobId = _requireId(id, 'jobId');
    final response = await _apiClient.get<UserLandmarkBulkJob>(
      ApiEndpoints.user.landmarkBulkJobById(jobId),
      options: _readOptions,
      parser: UserLandmarkBulkJob.fromJson,
    );
    return response.data;
  }

  /// Returns the failed-rows CSV endpoint path. Callers should resolve it
  /// against the configured base URL (the central HTTP client already knows
  /// the host) — exposing the path keeps the service framework-agnostic.
  Future<String> failedCsvUrl(String id) async {
    final jobId = _requireId(id, 'jobId');
    return ApiEndpoints.user.landmarkBulkJobFailedCsv(jobId);
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  Map<String, dynamic>? _query(Map<String, dynamic> source) {
    final result = <String, dynamic>{};
    source.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      result[key] = value;
    });
    return result.isEmpty ? null : result;
  }

  String _requireId(String value, String label) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('$label is required');
    }
    return normalized;
  }
}
