import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../models/user_driver_model.dart';

class UserDriverService {
  UserDriverService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = normalReadOptions();

  static final Options _mutationOptions = normalWriteOptions();

  static final Options _uploadOptions = uploadOptions().copyWith(
    contentType: Headers.multipartFormDataContentType,
  );

  Future<List<UserDriver>> fetchDrivers({String? refreshKey}) async {
    final response = await _apiClient.get<List<UserDriver>>(
      ApiEndpoints.user.drivers,
      queryParameters: _query(<String, dynamic>{'rk': refreshKey}),
      options: _readOptions,
      parser: UserDriver.listFromJson,
    );
    return response.data;
  }

  Future<UserDriver> createDriver(CreateUserDriverRequest request) async {
    final response = await _apiClient.post<UserDriver>(
      ApiEndpoints.user.drivers,
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserDriver.fromJson,
    );

    final created = response.data;
    if (created.id.trim().isNotEmpty) {
      return created;
    }

    // Fallback when backend returns a mutation envelope without full entity.
    final refreshed = await fetchDrivers(refreshKey: _refreshKey());
    final matched = refreshed.where((driver) {
      return driver.username.toLowerCase() ==
              request.username.trim().toLowerCase() ||
          (request.email != null &&
              request.email!.trim().isNotEmpty &&
              driver.email.toLowerCase() ==
                  request.email!.trim().toLowerCase()) ||
          driver.mobile == request.mobile.trim();
    }).toList(growable: false);

    if (matched.isNotEmpty) {
      return matched.first;
    }

    return created;
  }

  Future<UserDriver> fetchDriverById(
    String driverId, {
    String? refreshKey,
  }) async {
    final id = _requireId(driverId, 'driverId');
    final response = await _apiClient.get<UserDriver>(
      ApiEndpoints.user.driverById(id),
      queryParameters: _query(<String, dynamic>{'rk': refreshKey}),
      options: _readOptions,
      parser: UserDriver.fromJson,
    );
    return response.data;
  }

  Future<UserDriver> updateDriver(
    String driverId,
    UpdateUserDriverRequest request,
  ) async {
    final id = _requireId(driverId, 'driverId');
    final response = await _apiClient.patch<UserDriver>(
      ApiEndpoints.user.driverById(id),
      data: request.toJson(),
      options: _mutationOptions,
      parser: UserDriver.fromJson,
    );

    final updated = response.data;
    if (updated.id.trim().isNotEmpty) {
      return updated;
    }

    return fetchDriverById(id, refreshKey: _refreshKey());
  }

  Future<void> deleteDriver(String driverId) async {
    final id = _requireId(driverId, 'driverId');
    await _apiClient.delete<void>(
      ApiEndpoints.user.driverById(id),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> assignVehicle(String driverId, String vehicleId) async {
    final id = _requireId(driverId, 'driverId');
    final request = AssignDriverVehicleRequest(vehicleId: vehicleId);
    await _apiClient.post<void>(
      ApiEndpoints.user.driverAssignVehicle(id),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> unassignVehicle(String driverId) async {
    final id = _requireId(driverId, 'driverId');
    await _apiClient.post<void>(
      ApiEndpoints.user.driverUnassignVehicle(id),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<List<UserDriverLog>> fetchDriverLogs(String driverId) async {
    final id = _requireId(driverId, 'driverId');
    final response = await _apiClient.get<List<UserDriverLog>>(
      ApiEndpoints.user.driverLogs(id),
      options: _readOptions,
      parser: UserDriverLog.listFromJson,
    );
    return response.data;
  }

  Future<List<UserDriverDocument>> fetchDriverDocuments(String driverId) async {
    final id = _requireId(driverId, 'driverId');
    final response = await _apiClient.get<List<UserDriverDocument>>(
      ApiEndpoints.user.driverDocuments(id),
      options: _readOptions,
      parser: UserDriverDocument.listFromJson,
    );
    return response.data;
  }

  Future<List<UserDriverDocumentType>> fetchDriverDocumentTypes() async {
    final response = await _apiClient.get<List<UserDriverDocumentType>>(
      ApiEndpoints.user.driverDocumentTypes,
      options: _readOptions,
      parser: UserDriverDocumentType.listFromJson,
    );
    return response.data;
  }

  Future<UserDriverDocument> uploadDriverDocument({
    required String driverId,
    required UserDriverDocumentMutationRequest request,
  }) async {
    final id = _requireId(driverId, 'driverId');
    _validateDocumentRequest(
      request,
      requireFile: true,
      requireDocType: true,
    );

    final formData = await _buildDocumentFormData(request);
    final response = await _apiClient.post<UserDriverDocument>(
      ApiEndpoints.user.driverDocuments(id),
      data: formData,
      options: _uploadOptions,
      parser: UserDriverDocument.fromJson,
    );

    final uploaded = response.data;
    if (uploaded.id.trim().isNotEmpty) {
      return uploaded;
    }

    final refreshed = await fetchDriverDocuments(id);
    if (refreshed.isNotEmpty) {
      return refreshed.first;
    }

    return uploaded;
  }

  Future<UserDriverDocument> updateDriverDocument({
    required String driverId,
    required String docId,
    required UserDriverDocumentMutationRequest request,
  }) async {
    final id = _requireId(driverId, 'driverId');
    final did = _requireId(docId, 'docId');
    _validateDocumentRequest(
      request,
      requireFile: false,
      requireDocType: false,
    );

    final formData = await _buildDocumentFormData(request);
    final response = await _apiClient.patch<UserDriverDocument>(
      ApiEndpoints.user.driverDocumentById(driverId: id, docId: did),
      data: formData,
      options: _uploadOptions,
      parser: UserDriverDocument.fromJson,
    );

    final updated = response.data;
    if (updated.id.trim().isNotEmpty) {
      return updated;
    }

    final refreshed = await fetchDriverDocuments(id);
    for (final document in refreshed) {
      if (document.id == did) {
        return document;
      }
    }

    if (refreshed.isNotEmpty) {
      return refreshed.first;
    }

    return updated;
  }

  Future<void> deleteDriverDocument({
    required String driverId,
    required String docId,
  }) async {
    final id = _requireId(driverId, 'driverId');
    final did = _requireId(docId, 'docId');

    await _apiClient.delete<void>(
      ApiEndpoints.user.driverDocumentById(driverId: id, docId: did),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<List<UserDriverVehicleMini>> fetchAvailableVehicles({
    String? refreshKey,
  }) async {
    final response = await _apiClient.get<List<UserDriverVehicleMini>>(
      ApiEndpoints.user.vehicles,
      queryParameters: _query(<String, dynamic>{'rk': refreshKey}),
      options: _readOptions,
      parser: UserDriverVehicleMini.listFromJson,
    );
    return response.data;
  }

  Future<List<UserDriverCountryOption>> fetchCountries() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.countries,
      options: _readOptions,
      parser: (json) => json,
    );

    return UserDriverCountryOption.listFromJson(response.data);
  }

  Future<List<UserDriverMobilePrefixOption>> fetchMobilePrefixes() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.mobilePrefix,
      options: _readOptions,
      parser: (json) => json,
    );

    return UserDriverMobilePrefixOption.listFromJson(response.data);
  }

  Future<List<UserDriverStateOption>> fetchStates(String countryCode) async {
    final normalizedCountryCode = countryCode.trim().toUpperCase();
    if (normalizedCountryCode.isEmpty) {
      return const <UserDriverStateOption>[];
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.states(normalizedCountryCode),
      options: _readOptions,
      parser: (json) => json,
    );

    return UserDriverStateOption.listFromJson(response.data);
  }

  Future<List<UserDriverCityOption>> fetchCities(
    String countryCode,
    String stateCode,
  ) async {
    final normalizedCountryCode = countryCode.trim().toUpperCase();
    final normalizedStateCode = stateCode.trim().toUpperCase();
    if (normalizedCountryCode.isEmpty || normalizedStateCode.isEmpty) {
      return const <UserDriverCityOption>[];
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.cities(normalizedCountryCode, normalizedStateCode),
      options: _readOptions,
      parser: (json) => json,
    );

    return UserDriverCityOption.listFromJson(response.data);
  }

  Future<FormData> _buildDocumentFormData(
    UserDriverDocumentMutationRequest request,
  ) async {
    final formData = FormData();

    final resolvedTitle = request.resolvedTitle;
    if (resolvedTitle != null) {
      formData.fields.add(MapEntry('title', resolvedTitle));
      formData.fields.add(MapEntry('name', resolvedTitle));
    }

    final fileName = _optionalString(request.fileName);
    if (fileName != null) {
      formData.fields.add(MapEntry('fileName', fileName));
    }

    final docTypeId = _optionalString(request.docTypeId);
    if (docTypeId != null) {
      formData.fields.add(MapEntry('docTypeId', docTypeId));
    }

    final description = request.resolvedDescription;
    if (description != null) {
      formData.fields.add(MapEntry('description', description));
      formData.fields.add(MapEntry('notes', description));
    }

    final tags = request.tags
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join(',');
    if (tags.isNotEmpty) {
      formData.fields.add(MapEntry('tags', tags));
    }

    final expiry = request.resolvedExpiry;
    if (expiry != null) {
      formData.fields.add(MapEntry('expiryAt', expiry));
      formData.fields.add(MapEntry('expiryDate', expiry));
    }

    if (request.isVisible != null) {
      formData.fields.add(MapEntry('isVisible', request.isVisible.toString()));
    }

    if (request.isVisibleDriver != null) {
      formData.fields
          .add(MapEntry('isVisibleDriver', request.isVisibleDriver.toString()));
    }

    final file = request.file;
    if (file != null) {
      formData.files.add(MapEntry('file', await _toMultipartFile(file)));
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
    UserDriverDocumentMutationRequest request, {
    required bool requireFile,
    required bool requireDocType,
  }) {
    if (requireFile && request.file == null) {
      throw ArgumentError('file is required.');
    }

    if (requireDocType && _optionalString(request.docTypeId) == null) {
      throw ArgumentError('docTypeId is required.');
    }

    if (!requireFile && !request.hasMutationFields) {
      throw ArgumentError('At least one document field or file is required.');
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
      if (value == null) {
        continue;
      }
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      query[entry.key] = value;
    }
    return query.isEmpty ? null : query;
  }

  String _refreshKey() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String? _optionalString(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) {
      return '';
    }
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
