import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/user_vehicle_model.dart';

class UserVehicleService {
  UserVehicleService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );

  static final Options _mutationOptions = Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  );

  static final Options _uploadOptions = Options(
    sendTimeout: const Duration(minutes: 5),
    receiveTimeout: const Duration(minutes: 5),
    contentType: Headers.multipartFormDataContentType,
  );

  Future<List<UserVehicleListItem>> getVehicles({String? refreshKey}) async {
    final response = await _apiClient.get<List<UserVehicleListItem>>(
      ApiEndpoints.user.vehicles,
      queryParameters: _query(<String, dynamic>{'rk': refreshKey}),
      options: _readOptions,
      parser: UserVehicleListItem.listFromJson,
    );
    return response.data;
  }

  Future<UserVehicleDetails> getVehicleById(String id) async {
    final vehicleId = _requireId(id, 'vehicleId');
    final response = await _apiClient.get<UserVehicleDetails>(
      ApiEndpoints.user.vehicleById(vehicleId),
      options: _readOptions,
      parser: UserVehicleDetails.fromJson,
    );
    return response.data;
  }

  Future<UserVehicleDetails> updateVehicle({
    required String id,
    required UserVehicleUpdateRequest request,
  }) async {
    final vehicleId = _requireId(id, 'vehicleId');
    await _apiClient.patch<void>(
      ApiEndpoints.user.vehicleUpdate(vehicleId),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
    return getVehicleById(vehicleId);
  }

  Future<UserVehicleDetails> updateVehicleConfig({
    required String id,
    required UserVehicleConfigUpdateRequest request,
  }) async {
    final vehicleId = _requireId(id, 'vehicleId');
    await _apiClient.patch<void>(
      ApiEndpoints.user.vehicleConfigUpdate(vehicleId),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
    return getVehicleById(vehicleId);
  }

  Future<List<UserVehicleTypeOption>> getVehicleTypes() async {
    final response = await _apiClient.get<List<UserVehicleTypeOption>>(
      ApiEndpoints.public.vehicleTypes,
      options: _readOptions,
      parser: UserVehicleTypeOption.listFromJson,
    );
    return response.data;
  }

  Future<List<String>> getTimezones() async {
    final response = await _apiClient.get<List<String>>(
      ApiEndpoints.public.timezones,
      options: _readOptions,
      parser: _parseTimezones,
    );
    return response.data;
  }

  Future<UserVehicleSensorPage> getVehicleSensors({
    required String vehicleId,
    String? search,
    int page = 1,
    int limit = 100,
    bool includeLive = true,
  }) async {
    final id = _requireId(vehicleId, 'vehicleId');
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedLimit = limit < 1 ? 100 : limit;
    final response = await _apiClient.get<UserVehicleSensorPage>(
      ApiEndpoints.user.vehicleSensors(id),
      queryParameters: _query(<String, dynamic>{
        'search': search,
        'page': normalizedPage,
        'limit': normalizedLimit,
        'includeLive': includeLive,
      }),
      options: _readOptions,
      parser: (json) => UserVehicleSensorPage.fromJson(
        json,
        defaultPage: normalizedPage,
        defaultLimit: normalizedLimit,
      ),
    );
    return response.data;
  }

  Future<UserVehicleSensor> createVehicleSensor({
    required String vehicleId,
    required String name,
    String? unit,
    String? icon,
    required String code,
    bool isActive = true,
  }) async {
    final id = _requireId(vehicleId, 'vehicleId');
    final response = await _apiClient.post<UserVehicleSensor>(
      ApiEndpoints.user.vehicleSensors(id),
      data: _sensorPayload(
        name: name,
        unit: unit,
        icon: icon,
        code: code,
        isActive: isActive,
      ),
      options: _mutationOptions,
      parser: UserVehicleSensor.fromJson,
    );
    return response.data;
  }

  Future<UserVehicleSensor> updateVehicleSensor({
    required String vehicleId,
    required String sensorId,
    required String name,
    String? unit,
    String? icon,
    required String code,
    bool isActive = true,
  }) async {
    final id = _requireId(vehicleId, 'vehicleId');
    final sid = _requireId(sensorId, 'sensorId');
    final response = await _apiClient.patch<UserVehicleSensor>(
      ApiEndpoints.user.vehicleSensorById(vehicleId: id, sensorId: sid),
      data: _sensorPayload(
        name: name,
        unit: unit,
        icon: icon,
        code: code,
        isActive: isActive,
      ),
      options: _mutationOptions,
      parser: UserVehicleSensor.fromJson,
    );
    return response.data;
  }

  Future<void> deleteVehicleSensor({
    required String vehicleId,
    required String sensorId,
  }) async {
    final id = _requireId(vehicleId, 'vehicleId');
    final sid = _requireId(sensorId, 'sensorId');
    await _apiClient.delete<void>(
      ApiEndpoints.user.vehicleSensorById(vehicleId: id, sensorId: sid),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<UserVehicleSensorRunResult> runVehicleSensor({
    required String vehicleId,
    required String code,
    required Map<String, dynamic> payload,
  }) async {
    final id = _requireId(vehicleId, 'vehicleId');
    final normalizedCode = _requireText(code, 'code');
    final response = await _apiClient.post<UserVehicleSensorRunResult>(
      ApiEndpoints.user.vehicleSensorsRun(id),
      data: <String, dynamic>{
        'code': normalizedCode,
        'payload': payload,
      },
      options: _mutationOptions,
      parser: UserVehicleSensorRunResult.fromJson,
    );
    return response.data;
  }

  Future<UserVehicleSensorTelemetry> getVehicleSensorTelemetry(
    String vehicleId,
  ) async {
    final id = _requireId(vehicleId, 'vehicleId');
    final response = await _apiClient.get<UserVehicleSensorTelemetry>(
      ApiEndpoints.user.vehicleSensorsTelemetry(id),
      options: _readOptions,
      parser: UserVehicleSensorTelemetry.fromJson,
    );
    return response.data;
  }

  Future<UserVehicleSensorHistory> getVehicleSensorHistory({
    required String vehicleId,
    required String sensorId,
    required DateTime from,
    required DateTime to,
    int maxPoints = 500,
  }) async {
    final id = _requireId(vehicleId, 'vehicleId');
    final sid = _requireId(sensorId, 'sensorId');
    final normalizedFrom = from.isAfter(to) ? to : from;
    final normalizedTo = to.isBefore(from) ? from : to;
    final response = await _apiClient.get<UserVehicleSensorHistory>(
      ApiEndpoints.user.vehicleSensorHistory(
        vehicleId: id,
        sensorId: sid,
      ),
      queryParameters: _query(<String, dynamic>{
        'from': normalizedFrom.toUtc().toIso8601String(),
        'to': normalizedTo.toUtc().toIso8601String(),
        'maxPoints': maxPoints < 1 ? 1 : maxPoints,
      }),
      options: _readOptions,
      parser: UserVehicleSensorHistory.fromJson,
    );
    return response.data;
  }

  Future<List<UserVehicleDocument>> getVehicleDocuments(
    String vehicleId,
  ) async {
    final id = _requireId(vehicleId, 'vehicleId');
    final response = await _apiClient.get<List<UserVehicleDocument>>(
      ApiEndpoints.user.vehicleDocuments(id),
      options: _readOptions,
      parser: UserVehicleDocument.listFromJson,
    );
    return response.data;
  }

  Future<List<UserVehicleDocumentType>> getVehicleDocumentTypes() async {
    final response = await _apiClient.get<List<UserVehicleDocumentType>>(
      ApiEndpoints.user.vehicleDocumentTypes,
      options: _readOptions,
      parser: UserVehicleDocumentType.listFromJson,
    );
    return response.data;
  }

  Future<void> uploadVehicleDocument({
    required String vehicleId,
    required UserVehicleDocumentRequest request,
  }) async {
    final id = _requireId(vehicleId, 'vehicleId');
    _validateDocumentRequest(request, requireFile: true);
    final formData = await _buildDocumentFormData(request);
    await _apiClient.post<void>(
      ApiEndpoints.user.vehicleDocuments(id),
      data: formData,
      options: _uploadOptions,
      parser: (_) {},
    );
  }

  Future<void> updateVehicleDocument({
    required String vehicleId,
    required String docId,
    required UserVehicleDocumentRequest request,
  }) async {
    final id = _requireId(vehicleId, 'vehicleId');
    final did = _requireId(docId, 'docId');
    _validateDocumentRequest(request, requireFile: false);
    final formData = await _buildDocumentFormData(request);
    await _apiClient.patch<void>(
      ApiEndpoints.user.vehicleDocumentById(vehicleId: id, docId: did),
      data: formData,
      options: _uploadOptions,
      parser: (_) {},
    );
  }

  Future<void> deleteVehicleDocument({
    required String vehicleId,
    required String docId,
  }) async {
    final id = _requireId(vehicleId, 'vehicleId');
    final did = _requireId(docId, 'docId');
    await _apiClient.delete<void>(
      ApiEndpoints.user.vehicleDocumentById(vehicleId: id, docId: did),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Map<String, dynamic> _sensorPayload({
    required String name,
    String? unit,
    String? icon,
    required String code,
    required bool isActive,
  }) {
    return <String, dynamic>{
      'name': _requireText(name, 'name'),
      'code': _requireText(code, 'code'),
      'isActive': isActive,
      if (_optionalString(unit) != null) 'unit': _optionalString(unit),
      if (_optionalString(icon) != null) 'icon': _optionalString(icon),
    };
  }

  Future<FormData> _buildDocumentFormData(
    UserVehicleDocumentRequest request,
  ) async {
    final formData = FormData();
    formData.fields.addAll(<MapEntry<String, String>>[
      MapEntry('title', request.title.trim()),
      MapEntry('docTypeId', request.docTypeId.trim()),
      MapEntry('isVisible', request.isVisible.toString()),
      MapEntry('description', request.description.trim()),
    ]);

    final tags = request.tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .join(',');
    if (tags.isNotEmpty) {
      formData.fields.add(MapEntry('tags', tags));
    }

    final expiry = request.expiryAt?.trim();
    if (expiry != null && expiry.isNotEmpty) {
      formData.fields.add(MapEntry('expiryAt', expiry));
    }

    final file = request.file;
    if (file != null) {
      formData.files.add(MapEntry('File', await _toMultipartFile(file)));
    }

    return formData;
  }

  Future<MultipartFile> _toMultipartFile(PlatformFile file) async {
    final fileName = file.name.trim().isEmpty ? 'attachment' : file.name.trim();
    final contentType = _contentTypeForExtension(_extension(fileName));

    if (file.bytes != null) {
      return MultipartFile.fromBytes(
        file.bytes!,
        filename: fileName,
        contentType: contentType,
      );
    }

    final path = file.path?.trim();
    if (path != null && path.isNotEmpty) {
      return MultipartFile.fromFile(
        path,
        filename: fileName,
        contentType: contentType,
      );
    }

    throw ArgumentError('Unable to read file "$fileName".');
  }

  void _validateDocumentRequest(
    UserVehicleDocumentRequest request, {
    required bool requireFile,
  }) {
    _requireText(request.title, 'title');
    _requireText(request.docTypeId, 'docTypeId');
    if (requireFile && request.file == null) {
      throw ArgumentError('file is required.');
    }
  }

  String _requireId(String value, String fieldName) {
    return _requireText(value, fieldName);
  }

  String _requireText(String value, String fieldName) {
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

  List<String> _parseTimezones(dynamic json) {
    final list = _extractList(json, preferredKeys: const [
      'timezones',
      'items',
      'rows',
      'list',
      'data',
    ]);
    return list
        .map(_timezoneLabel)
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<dynamic> _extractList(
    dynamic json, {
    required List<String> preferredKeys,
  }) {
    if (json is List) return json;
    final root = _asMap(json);
    for (final key in preferredKeys) {
      final value = _valueForKey(root, key);
      if (value is List) return value;
    }
    for (final key in const ['data', 'result', 'payload', 'response']) {
      final nested = _valueForKey(root, key);
      if (nested == null || identical(nested, json)) continue;
      final list = _extractList(nested, preferredKeys: preferredKeys);
      if (list.isNotEmpty) return list;
    }
    return const <dynamic>[];
  }

  String? _timezoneLabel(dynamic value) {
    if (value is String) return value.trim();
    final source = _asMap(value);
    for (final key in const [
      'value',
      'name',
      'label',
      'timezone',
      'gmtOffset'
    ]) {
      final raw = _valueForKey(source, key);
      if (raw == null) continue;
      final normalized = raw.toString().trim();
      if (normalized.isNotEmpty) return normalized;
    }
    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  dynamic _valueForKey(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) return json[key];
    final normalizedKey = key.toLowerCase();
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() == normalizedKey) return entry.value;
    }
    return null;
  }

  String? _optionalString(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  String _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  MediaType _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType(
          'application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      case 'xls':
        return MediaType('application', 'vnd.ms-excel');
      case 'xlsx':
        return MediaType(
          'application',
          'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      case 'csv':
        return MediaType('text', 'csv');
      case 'txt':
        return MediaType('text', 'plain');
      case 'zip':
        return MediaType('application', 'zip');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
