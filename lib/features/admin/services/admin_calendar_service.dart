import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../../../shared/models/api_result.dart';
import '../models/admin_calendar_model.dart';

class AdminCalendarService {
  AdminCalendarService(this._apiClient);

  static final Options _readOptions = normalReadOptions();

  static const Map<String, String> _apiTypesByCalendarFilter = {
    'users': 'USER_CREATED',
    'vehicle': 'VEHICLE_CREATED',
    'expiry': 'VEHICLE_EXPIRY',
  };

  final ApiClient _apiClient;

  Future<ApiResult<List<AdminCalendarEvent>>> getEvents(
    String from,
    String to,
    List<String> types,
  ) async {
    try {
      final response = await _apiClient.get<List<AdminCalendarEvent>>(
        ApiEndpoints.admin.calendarEvents,
        queryParameters: <String, dynamic>{
          'from': from,
          'to': to,
          'types': _resolveApiTypes(types).join(','),
          'rk': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        options: _readOptions,
        parser: AdminCalendarEvent.listFromPayload,
      );
      return ApiResult.success(response.data);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<List<AdminCalendarDayDetail>>> getDayDetails(
    String date,
    List<String> types,
  ) async {
    try {
      final response = await _apiClient.get<List<AdminCalendarDayDetail>>(
        ApiEndpoints.admin.calendarDay,
        queryParameters: <String, dynamic>{
          'date': date,
          'types': _resolveApiTypes(types).join(','),
          'rk': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        options: _readOptions,
        parser: AdminCalendarDayDetail.listFromPayload,
      );
      return ApiResult.success(response.data);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AdminCalendarLinkedDetail>> getUserDetails(
      String uid) async {
    try {
      final response = await _apiClient.get<AdminCalendarLinkedDetail>(
        ApiEndpoints.admin.calendarUser(uid),
        queryParameters: <String, dynamic>{
          'rk': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        options: _readOptions,
        parser: AdminCalendarLinkedDetail.fromUserPayload,
      );
      return ApiResult.success(response.data);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AdminCalendarLinkedDetail>> getVehicleDetails(
      String vehicleId) async {
    try {
      final response = await _apiClient.get<AdminCalendarLinkedDetail>(
        ApiEndpoints.admin.vehicleDetail(vehicleId),
        queryParameters: <String, dynamic>{
          'rk': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        options: _readOptions,
        parser: AdminCalendarLinkedDetail.fromVehiclePayload,
      );
      return ApiResult.success(response.data);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  List<String> _resolveApiTypes(List<String> types) {
    final normalized = types
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .map((type) => _apiTypesByCalendarFilter[type] ?? type)
        .toList(growable: false);

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return _apiTypesByCalendarFilter.values.toList(growable: false);
  }
}
