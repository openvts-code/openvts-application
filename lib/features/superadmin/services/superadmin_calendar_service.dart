import 'package:dio/dio.dart';
import '../../../../core/api/api_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../shared/models/api_result.dart';
import '../models/superadmin_calendar_model.dart';

final superadminCalendarServiceProvider =
    Provider<SuperadminCalendarService>((ref) {
  return SuperadminCalendarService(ref.read(apiClientProvider));
});

class SuperadminCalendarService {
  static final Options _readOptions = normalReadOptions();

  static const Map<String, String> _apiTypesByCalendarFilter = {
    'users': 'USER_CREATED',
    'vehicle': 'VEHICLE_CREATED',
    'expiry': 'VEHICLE_EXPIRY',
  };

  final ApiClient _apiClient;

  SuperadminCalendarService(this._apiClient);

  Future<ApiResult<List<CalendarEvent>>> getEvents(
    String from,
    String to,
    List<String> types,
  ) async {
    final rk = DateTime.now().millisecondsSinceEpoch.toString();
    final apiTypes = _resolveApiTypes(types);

    try {
      final response = await _apiClient.get<List<CalendarEvent>>(
        ApiEndpoints.superadmin.calendarEvents,
        queryParameters: <String, dynamic>{
          'from': from,
          'to': to,
          'types': apiTypes.join(','),
          'rk': rk,
        },
        options: _readOptions,
        parser: CalendarEvent.listFromPayload,
      );
      return ApiResult.success(response.data);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<List<CalendarDayDetail>>> getDayDetails(
    String date,
    List<String> types,
  ) async {
    final rk = DateTime.now().millisecondsSinceEpoch.toString();
    final apiTypes = _resolveApiTypes(types);

    try {
      final response = await _apiClient.get<List<CalendarDayDetail>>(
        ApiEndpoints.superadmin.calendarDay,
        queryParameters: <String, dynamic>{
          'date': date,
          'types': apiTypes.join(','),
          'rk': rk,
        },
        options: _readOptions,
        parser: CalendarDayDetail.listFromPayload,
      );
      return ApiResult.success(response.data);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<CalendarLinkedDetail>> getUserDetails(String uid) async {
    try {
      final response = await _apiClient.get<CalendarLinkedDetail>(
        ApiEndpoints.superadmin.calendarUser(uid),
        queryParameters: <String, dynamic>{
          'rk': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        options: _readOptions,
        parser: CalendarLinkedDetail.fromUserPayload,
      );
      return ApiResult.success(response.data);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<CalendarLinkedDetail>> getVehicleDetails(
      String vehicleId) async {
    try {
      final response = await _apiClient.get<CalendarLinkedDetail>(
        ApiEndpoints.superadmin.vehicleDetail(vehicleId),
        queryParameters: <String, dynamic>{
          'rk': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        options: _readOptions,
        parser: CalendarLinkedDetail.fromVehiclePayload,
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
