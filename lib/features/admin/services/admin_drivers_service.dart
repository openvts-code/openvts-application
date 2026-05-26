import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../models/admin_driver_details_model.dart';
import '../models/admin_drivers_model.dart';

class AdminDriversService {
  AdminDriversService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = normalReadOptions();

  static final Options _mutationOptions = normalWriteOptions();

  static final Options _uploadOptions = uploadOptions().copyWith(
    contentType: Headers.multipartFormDataContentType,
  );

  Future<List<AdminDriverListItem>> getDrivers({String? refreshKey}) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.drivers,
      queryParameters: _queryParameters(refreshKey: refreshKey),
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminDriverListItem.listFromJson(response.data);
  }

  Future<void> createDriver(AdminDriverCreateRequest request) async {
    await _apiClient.post<dynamic>(
      ApiEndpoints.admin.drivers,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
  }

  Future<List<AdminDriverListItem>> getUsersForDriverPrimarySelection({
    String? refreshKey,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.users,
      queryParameters: _queryParameters(refreshKey: refreshKey),
      options: _readOptions,
      parser: (json) => json,
    );
    final list = _extractUsersList(response.data);
    return list
        .map(_toPrimaryUserOption)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<AdminDriverDetails> getDriverById(String id) async {
    final driverId = _requireId(id, 'driverId');
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.driverById(driverId),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminDriverDetails.fromJson(response.data, fallbackId: driverId);
  }

  Future<AdminDriverDetails> updateDriver({
    required String id,
    required AdminDriverUpdateRequest request,
  }) async {
    final driverId = _requireId(id, 'driverId');
    await _apiClient.patch<dynamic>(
      ApiEndpoints.admin.driverById(driverId),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    return getDriverById(driverId);
  }

  Future<void> updateDriverStatus({
    required String id,
    required bool isActive,
  }) async {
    final driverId = _requireId(id, 'driverId');
    await _apiClient.patch<void>(
      ApiEndpoints.admin.driverById(driverId),
      data: <String, dynamic>{'isactive': isActive ? 'true' : 'false'},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> updateDriverPassword({
    required String id,
    required String password,
  }) async {
    final driverId = _requireId(id, 'driverId');
    final pass = password.trim();
    if (pass.isEmpty) {
      throw ArgumentError('password is required');
    }

    await _apiClient.patch<void>(
      ApiEndpoints.admin.driverById(driverId),
      data: <String, dynamic>{'password': pass},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> deleteDriver(String id) async {
    final driverId = _requireId(id, 'driverId');
    await _apiClient.delete<void>(
      ApiEndpoints.admin.driverById(driverId),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<List<AdminDriverDocument>> getDriverDocuments(String driverId) async {
    final id = _requireId(driverId, 'driverId');
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.documentsByDriver(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminDriverDocument.listFromJson(response.data);
  }

  Future<List<AdminDriverDocumentType>> getDriverDocumentTypes() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.driverDocumentTypes,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminDriverDocumentType.listFromJson(response.data);
  }

  Future<void> uploadDriverDocument(
    AdminDriverDocumentUpsertRequest request,
  ) async {
    _validateDocumentRequest(request, requireFile: true);
    final form = await _buildDocumentFormData(
      request: request,
      includeFile: true,
    );
    await _apiClient.post<void>(
      ApiEndpoints.admin.uploadDoc,
      data: form,
      options: _uploadOptions,
      parser: (_) {},
    );
  }

  Future<void> updateDriverDocument({
    required String docId,
    required AdminDriverDocumentUpsertRequest request,
  }) async {
    final id = _requireId(docId, 'docId');
    _validateDocumentRequest(request, requireFile: false);
    final form = await _buildDocumentFormData(
      request: request,
      includeFile: request.file != null,
    );
    await _apiClient.patch<void>(
      ApiEndpoints.admin.uploadDocById(id),
      data: form,
      options: _uploadOptions,
      parser: (_) {},
    );
  }

  Future<void> deleteDriverDocument(String docId) async {
    final id = _requireId(docId, 'docId');
    await _apiClient.delete<void>(
      ApiEndpoints.admin.uploadDocById(id),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<List<AdminDriverLinkedUser>> getLinkedUsers(String driverId) async {
    final id = _requireId(driverId, 'driverId');
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.driverLinkedUsers(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminDriverLinkedUser.listFromJson(response.data);
  }

  Future<List<AdminDriverLinkedUser>> getUnlinkedUsers(String driverId) async {
    final id = _requireId(driverId, 'driverId');
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.driverUnlinkedUsers(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminDriverLinkedUser.listFromJson(response.data);
  }

  Future<void> assignUserToDriver({
    required String driverId,
    required String userId,
  }) async {
    final id = _requireId(driverId, 'driverId');
    await _apiClient.post<void>(
      ApiEndpoints.admin.driverLinkedUsers(id),
      data: <String, dynamic>{'userId': int.parse(userId)},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> unassignUserFromDriver({
    required String driverId,
    required String userId,
  }) async {
    final id = _requireId(driverId, 'driverId');
    await _apiClient.post<void>(
      ApiEndpoints.admin.driverUnlinkedUsers(id),
      data: <String, dynamic>{'userId': int.parse(userId)},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Map<String, dynamic>? _queryParameters({String? refreshKey}) {
    final rk = refreshKey?.trim();
    if (rk == null || rk.isEmpty) {
      return null;
    }

    return <String, dynamic>{'rk': rk};
  }

  List<dynamic> _extractUsersList(dynamic json) {
    if (json is List) return json;
    if (json is Map<String, dynamic>) {
      final usersList = json['userslist'];
      if (usersList is List) return usersList;
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        final nested = data['userslist'];
        if (nested is List) return nested;
      }
    }
    return const <dynamic>[];
  }

  AdminDriverListItem _toPrimaryUserOption(dynamic raw) {
    final map = raw is Map<String, dynamic>
        ? raw
        : raw is Map
            ? raw.map((key, value) => MapEntry(key.toString(), value))
            : const <String, dynamic>{};
    final id = (map['uid'] ?? map['id'] ?? map['_id'] ?? '').toString().trim();
    final name = (map['name'] ?? map['Name'] ?? '').toString().trim();
    final username = (map['username'] ?? '').toString().trim();
    final email = (map['email'] ?? '').toString().trim();
    final mobilePrefix =
        (map['mobilePrefix'] ?? map['mobile_prefix'] ?? '').toString().trim();
    final mobile =
        (map['mobileNumber'] ?? map['mobile'] ?? '').toString().trim();
    final addressMap = map['address'] is Map<String, dynamic>
        ? map['address'] as Map<String, dynamic>
        : map['address'] is Map
            ? (map['address'] as Map)
                .map((key, value) => MapEntry(key.toString(), value))
            : const <String, dynamic>{};
    final fullAddress =
        (addressMap['fullAddress'] ?? addressMap['addressLine'] ?? '')
            .toString();
    final phone =
        '${mobilePrefix.isNotEmpty ? '$mobilePrefix ' : ''}$mobile'.trim();
    return AdminDriverListItem(
      id: id,
      firstName: name.isNotEmpty ? name : username,
      email: email,
      username: username,
      mobilePrefix: mobilePrefix,
      mobile: mobile,
      phone: phone.isEmpty ? '-' : phone,
      address: fullAddress.isEmpty ? '-' : fullAddress,
      fullAddress: fullAddress.isEmpty ? '-' : fullAddress,
      countryCode: (addressMap['countryCode'] ?? '').toString(),
      stateCode: (addressMap['stateCode'] ?? '').toString(),
      city: (addressMap['cityId'] ?? '').toString(),
      pincode: (addressMap['pincode'] ?? '').toString(),
      primaryUserName: '-',
      primaryUserUid: '',
      isVerified: false,
      isActive: true,
      statusLabel: 'Active',
      createdAt: null,
      updatedAt: null,
    );
  }

  String _requireId(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('$field is required');
    }
    return normalized;
  }

  void _validateDocumentRequest(
    AdminDriverDocumentUpsertRequest request, {
    required bool requireFile,
  }) {
    if (request.title.trim().isEmpty) {
      throw ArgumentError('title is required');
    }
    if (request.docTypeId.trim().isEmpty) {
      throw ArgumentError('docTypeId is required');
    }
    if (request.driverId.trim().isEmpty) {
      throw ArgumentError('driverId is required');
    }
    if (requireFile && request.file == null) {
      throw ArgumentError('file is required');
    }
  }

  Future<FormData> _buildDocumentFormData({
    required AdminDriverDocumentUpsertRequest request,
    required bool includeFile,
  }) async {
    final map = <String, dynamic>{
      'title': request.title.trim(),
      'docTypeId': request.docTypeId.trim(),
      'AssociateType': 'DRIVER',
      'associateId': request.driverId.trim(),
      'isVisible': request.isVisible,
      'tags': request.tags.trim(),
      'description': request.description.trim(),
    };

    if (request.expiryAt != null) {
      map['expiryAt'] = request.expiryAt!.toIso8601String();
    }

    if (includeFile && request.file != null) {
      map['File'] = await _multipartFromPlatformFile(request.file!);
    }

    return FormData.fromMap(map);
  }

  Future<MultipartFile> _multipartFromPlatformFile(PlatformFile file) async {
    final bytes = file.bytes;
    final path = file.path;
    final filename = file.name.trim().isEmpty ? 'upload.bin' : file.name.trim();

    final type = _mediaTypeFor(filename);
    if (bytes != null) {
      return MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: type,
      );
    }

    if (path == null || path.trim().isEmpty) {
      throw ArgumentError('Selected file is not accessible.');
    }

    return MultipartFile.fromFile(path, filename: filename, contentType: type);
  }

  MediaType? _mediaTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return MediaType('application', 'pdf');
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.csv')) return MediaType('text', 'csv');
    if (lower.endsWith('.txt')) return MediaType('text', 'plain');
    return null;
  }
}
