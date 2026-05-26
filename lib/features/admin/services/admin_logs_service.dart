import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/admin_logs_model.dart';

class AdminLogsService {
  AdminLogsService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );

  Future<AdminLogsOptions> getOptions() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.logsOptions,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminLogsOptions.fromJson(response.data);
  }

  Future<AdminActivityLogPage> getActivityLogs({
    int limit = 20,
    String? q,
    String? userId,
    String? actionPrefix,
    String? entity,
    String? from,
    String? to,
    String? cursorId,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.logsActivity,
      queryParameters: <String, dynamic>{
        'limit': limit,
        if (_nz(q)) 'q': q,
        if (_nz(userId)) 'userId': userId,
        if (_nz(actionPrefix)) 'actionPrefix': actionPrefix,
        if (_nz(entity)) 'entity': entity,
        if (_nz(from)) 'from': from,
        if (_nz(to)) 'to': to,
        if (_nz(cursorId)) 'cursorId': cursorId,
      },
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminActivityLogPage.fromJson(response.data);
  }

  Future<AdminVehicleEventLogPage> getVehicleEventLogs({
    int limit = 50,
    String? cursorId,
    String? from,
    String? to,
    String? vehicleId,
    String? userId,
    String? source,
    String? severity,
    bool? isRead,
    String? q,
    bool dedupe = true,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.logsEvents,
      queryParameters: <String, dynamic>{
        'limit': limit,
        'dedupe': dedupe,
        if (_nz(cursorId)) 'cursorId': cursorId,
        if (_nz(from)) 'from': from,
        if (_nz(to)) 'to': to,
        if (_nz(vehicleId)) 'vehicleId': vehicleId,
        if (_nz(userId)) 'userId': userId,
        if (_nz(source)) 'source': source,
        if (_nz(severity)) 'severity': severity,
        if (isRead != null) 'isRead': isRead,
        if (_nz(q)) 'q': q,
      },
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleEventLogPage.fromJson(response.data);
  }

  Future<AdminVehicleEventDetail> getVehicleEventDetail(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.logsEventById(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleEventDetail.fromJson(response.data);
  }

  Future<AdminTelemetryLogPage> getTelemetryLogs({
    int limit = 200,
    String? beforeId,
    String? from,
    String? to,
    String? vehicleId,
    String? imei,
    String? packetType,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.logsTelemetry,
      queryParameters: <String, dynamic>{
        'limit': limit,
        if (_nz(beforeId)) 'beforeId': beforeId,
        if (_nz(from)) 'from': from,
        if (_nz(to)) 'to': to,
        if (_nz(vehicleId)) 'vehicleId': vehicleId,
        if (_nz(imei)) 'imei': imei,
        if (_nz(packetType)) 'packetType': packetType,
      },
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminTelemetryLogPage.fromJson(response.data);
  }

  Future<AdminTelemetryDetail> getTelemetryDetail(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.logsTelemetryById(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminTelemetryDetail.fromJson(response.data);
  }

  bool _nz(String? value) => value != null && value.trim().isNotEmpty;
}
