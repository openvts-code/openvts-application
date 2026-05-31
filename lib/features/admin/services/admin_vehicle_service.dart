import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../models/admin_vehicle_model.dart';

class AdminVehicleService {
  AdminVehicleService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = normalReadOptions();

  static final Options _mutationOptions = normalWriteOptions();

  static final Options _uploadOptions = uploadOptions().copyWith(
    contentType: Headers.multipartFormDataContentType,
  );

  Future<List<AdminVehicleListItem>> getVehicles({String? refreshKey}) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.vehicles,
      queryParameters: <String, dynamic>{
        if ((refreshKey ?? '').trim().isNotEmpty) 'rk': refreshKey!.trim(),
      },
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleListItem.listFromJson(response.data);
  }

  Future<AdminVehicleDetails> getVehicleById(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.vehicleById(_requireId(id, 'id')),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleDetails.fromJson(response.data, fallbackId: id);
  }

  Future<AdminVehicleDetails> createVehicle(
      AdminCreateVehicleRequest request) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.vehicles,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    return AdminVehicleDetails.fromJson(response.data);
  }

  Future<AdminVehicleDetails> updateVehicle({
    required String id,
    required AdminUpdateVehicleRequest request,
  }) async {
    final normalizedId = _requireId(id, 'id');
    await _apiClient.patch<dynamic>(
      ApiEndpoints.admin.vehicleById(normalizedId),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    return getVehicleById(normalizedId);
  }

  Future<void> updateVehicleStatus({
    required String id,
    required bool isActive,
  }) async {
    await _apiClient.patch<void>(
      ApiEndpoints.admin.vehicleById(_requireId(id, 'id')),
      data: <String, dynamic>{'isActive': isActive},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> deleteVehicle(String id) async {
    await _apiClient.delete<void>(
      ApiEndpoints.admin.vehicleById(_requireId(id, 'id')),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<AdminVehicleDetails> updateVehicleConfig({
    required String id,
    required AdminVehicleConfigUpdateRequest request,
  }) async {
    final normalizedId = _requireId(id, 'id');
    await _apiClient.patch<void>(
      ApiEndpoints.admin.vehicleConfigUpdate(normalizedId),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
    return getVehicleById(normalizedId);
  }

  Future<List<AdminVehicleTypeOption>> getVehicleTypes() async {
    final response = await _apiClient.get<dynamic>(
      '/vehicletypes',
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleTypeOption.listFromJson(response.data);
  }

  Future<List<String>> getTimezones() async {
    final response = await _apiClient.get<dynamic>(
      '/timezones',
      options: _readOptions,
      parser: (json) => json,
    );
    final items =
        response.data is List ? response.data as List : const <dynamic>[];
    return items
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<AdminVehicleUserMini>> getUsers() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.users,
      queryParameters: <String, dynamic>{
        'page': 1,
        'limit': 1000,
      },
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleUserMini.listFromJson(response.data);
  }

  Future<List<AdminQuickDeviceOption>> getQuickDevices() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.quickDevice,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminQuickDeviceOption.listFromJson(response.data);
  }

  Future<List<AdminPricingPlanOption>> getPricingPlans() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.pricingPlans,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminPricingPlanOption.listFromJson(response.data);
  }

  Future<List<AdminVehicleUserMini>> getLinkedUsers(String vehicleId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin
          .linkUsersByVehicleId(_requireId(vehicleId, 'vehicleId')),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleUserMini.listFromJson(response.data);
  }

  Future<List<AdminVehicleUserMini>> getUnlinkedUsers(String vehicleId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin
          .unlinkUsersByVehicleId(_requireId(vehicleId, 'vehicleId')),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleUserMini.listFromJson(response.data);
  }

  Future<void> linkUser(
      {required String vehicleId, required String userId}) async {
    await _apiClient.post<void>(
      ApiEndpoints.admin
          .linkUsersByVehicleId(_requireId(vehicleId, 'vehicleId')),
      data: <String, dynamic>{
        'userId': int.parse(_requireId(userId, 'userId'))
      },
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> unlinkUser(
      {required String vehicleId, required String userId}) async {
    await _apiClient.post<void>(
      ApiEndpoints.admin
          .unlinkUsersByVehicleId(_requireId(vehicleId, 'vehicleId')),
      data: <String, dynamic>{
        'userId': int.parse(_requireId(userId, 'userId'))
      },
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<AdminVehicleLogPage> getVehicleLogsByImei({
    required String imei,
    int limit = 100,
    String? beforeId,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.vehicleLogsByImei(_requireId(imei, 'imei')),
      queryParameters: <String, dynamic>{
        'limit': limit,
        if ((beforeId ?? '').trim().isNotEmpty) 'beforeId': beforeId,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleLogPage.fromJson(response.data);
  }

  Future<AdminVehicleEventPage> getVehicleEventsByImei({
    required String imei,
    int limit = 50,
    String? beforeId,
    DateTime? from,
    DateTime? to,
    String? source,
    String? severity,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.vehicleEventsByImei(_requireId(imei, 'imei')),
      queryParameters: <String, dynamic>{
        'limit': limit,
        if ((beforeId ?? '').trim().isNotEmpty) 'beforeId': beforeId,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        if ((source ?? '').trim().isNotEmpty) 'source': source,
        if ((severity ?? '').trim().isNotEmpty) 'severity': severity,
      },
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleEventPage.fromJson(response.data,
        imei: imei, requestedLimit: limit);
  }

  Future<List<AdminCustomCommand>> getCustomCommands(
      {bool activeOnly = true}) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.customCommands,
      queryParameters: <String, dynamic>{'activeOnly': activeOnly},
      options: _readOptions,
      parser: (json) => json,
    );
    final items =
        response.data is List ? response.data as List : const <dynamic>[];
    return items
        .map(AdminCustomCommand.tryParse)
        .whereType<AdminCustomCommand>()
        .toList(growable: false);
  }

  Future<List<AdminSystemVariable>> getSystemVariables() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.systemVariables,
      options: _readOptions,
      parser: (json) => json,
    );
    final items =
        response.data is List ? response.data as List : const <dynamic>[];
    return items
        .map(AdminSystemVariable.tryParse)
        .whereType<AdminSystemVariable>()
        .toList(growable: false);
  }

  Future<AdminSendCommandResult> sendCommandByImei({
    required String imei,
    required String command,
    String? note,
  }) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.sendCommandByImei(_requireId(imei, 'imei')),
      data: <String, dynamic>{
        'command': command.trim(),
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      },
      options: _mutationOptions,
      parser: (json) => json,
    );
    return AdminSendCommandResult.fromJson(response.data);
  }

  Future<AdminVehicleCommandHistoryPage> getCommandHistoryByImei({
    required String imei,
    int limit = 50,
    String? cursorId,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.commandHistoryByImei(_requireId(imei, 'imei')),
      queryParameters: <String, dynamic>{
        'limit': limit,
        if ((cursorId ?? '').trim().isNotEmpty) 'cursorId': cursorId,
      },
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleCommandHistoryPage.fromJson(response.data);
  }

  Future<AdminCommandStatus?> getCommandStatus(String cmdId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.commandStatus(_requireId(cmdId, 'cmdId')),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminCommandStatus.tryParse(response.data);
  }

  Future<AdminVehicleCommandItem?> getCommandLog(String cmdId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.commandLog(_requireId(cmdId, 'cmdId')),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleCommandItem.tryParse(response.data);
  }

  Future<AdminVehicleSensorPage> getVehicleSensors({
    required String vehicleId,
    String? search,
    int page = 1,
    int limit = 100,
    bool includeLive = true,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.vehicleSensors(_requireId(vehicleId, 'vehicleId')),
      queryParameters: <String, dynamic>{
        if ((search ?? '').trim().isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
        'includeLive': includeLive,
      },
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleSensorPage.fromJson(response.data);
  }

  Future<AdminVehicleSensor> createVehicleSensor({
    required String vehicleId,
    required AdminVehicleSensorUpsertRequest request,
  }) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.vehicleSensors(_requireId(vehicleId, 'vehicleId')),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    final parsed = AdminVehicleSensor.tryParse(response.data);
    if (parsed == null) throw StateError('Invalid sensor payload.');
    return parsed;
  }

  Future<AdminVehicleSensor> updateVehicleSensor({
    required String vehicleId,
    required String sensorId,
    required AdminVehicleSensorUpsertRequest request,
  }) async {
    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.admin.vehicleSensorById(
        vehicleId: _requireId(vehicleId, 'vehicleId'),
        sensorId: _requireId(sensorId, 'sensorId'),
      ),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    final parsed = AdminVehicleSensor.tryParse(response.data);
    if (parsed == null) throw StateError('Invalid sensor payload.');
    return parsed;
  }

  Future<void> deleteVehicleSensor(
      {required String vehicleId, required String sensorId}) async {
    await _apiClient.delete<void>(
      ApiEndpoints.admin.vehicleSensorById(
        vehicleId: _requireId(vehicleId, 'vehicleId'),
        sensorId: _requireId(sensorId, 'sensorId'),
      ),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<AdminVehicleSensorRunResult> runVehicleSensor({
    required String vehicleId,
    String? sensorId,
    AdminVehicleSensorRunRequest? request,
  }) async {
    final data = request?.toJson() ??
        <String, dynamic>{
          if ((sensorId ?? '').trim().isNotEmpty)
            'sensorId': _requireId(sensorId!, 'sensorId'),
        };
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.vehicleSensorsRun(_requireId(vehicleId, 'vehicleId')),
      data: data,
      options: _mutationOptions,
      parser: (json) => json,
    );
    return AdminVehicleSensorRunResult.fromJson(response.data);
  }

  Future<AdminVehicleSensorTelemetry> getVehicleSensorTelemetry(
      String vehicleId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin
          .vehicleSensorsTelemetry(_requireId(vehicleId, 'vehicleId')),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleSensorTelemetry.fromJson(response.data);
  }

  Future<List<AdminVehicleDocument>> getVehicleDocuments(
      String vehicleId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.documentsByVehicle(_requireId(vehicleId, 'vehicleId')),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleDocument.listFromJson(response.data);
  }

  Future<List<AdminVehicleDocumentType>> getVehicleDocumentTypes() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.vehicleDocumentTypes,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminVehicleDocumentType.listFromJson(response.data);
  }

  Future<void> uploadVehicleDocument(
      AdminVehicleDocumentRequest request) async {
    final formData = await _buildDocumentFormData(request, requireFile: true);
    await _apiClient.post<void>(
      ApiEndpoints.admin.uploadDoc,
      data: formData,
      options: _uploadOptions,
      parser: (_) {},
    );
  }

  Future<void> updateVehicleDocument({
    required String docId,
    required AdminVehicleDocumentRequest request,
  }) async {
    final formData = await _buildDocumentFormData(request, requireFile: false);
    await _apiClient.patch<void>(
      ApiEndpoints.admin.uploadDocById(_requireId(docId, 'docId')),
      data: formData,
      options: _uploadOptions,
      parser: (_) {},
    );
  }

  Future<void> deleteVehicleDocument(String docId) async {
    await _apiClient.delete<void>(
      ApiEndpoints.admin.uploadDocById(_requireId(docId, 'docId')),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<FormData> _buildDocumentFormData(
    AdminVehicleDocumentRequest request, {
    required bool requireFile,
  }) async {
    if (requireFile && request.file == null) {
      throw ArgumentError('File is required.');
    }

    MultipartFile? multipart;
    final file = request.file;
    if (file != null) {
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        multipart = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: _mediaType(file.extension),
        );
      } else if ((file.path ?? '').trim().isNotEmpty) {
        multipart = await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
          contentType: _mediaType(file.extension),
        );
      }
    }

    return FormData.fromMap(<String, dynamic>{
      'title': request.title.trim(),
      'docTypeId': request.docTypeId.trim(),
      'AssociateType': 'VEHICLE',
      'associateId': request.vehicleId.trim(),
      'isVisible': request.isVisible,
      'tags': request.tags.trim(),
      'description': request.description.trim(),
      if (request.expiryAt != null)
        'expiryAt': request.expiryAt!.toUtc().toIso8601String(),
      if (multipart != null) 'file': multipart,
    });
  }

  MediaType? _mediaType(String? extension) {
    final ext = (extension ?? '').trim().toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'pdf' => MediaType('application', 'pdf'),
      _ => null,
    };
  }

  String _requireId(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('$field is required.');
    }
    return normalized;
  }
}
