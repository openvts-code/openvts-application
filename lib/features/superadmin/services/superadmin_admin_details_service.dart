import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../models/superadmin_admin_details_model.dart';

class SuperadminAdminDetailsService {
  SuperadminAdminDetailsService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = normalReadOptions();

  static final Options _mutationOptions = normalWriteOptions();

  static final Options _uploadOptions = uploadOptions().copyWith(
    contentType: Headers.multipartFormDataContentType,
  );

  String _requireAdminId(String adminId) {
    final normalized = adminId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('adminId is required.');
    }
    return normalized;
  }

  Future<SuperadminAdminDetails> getAdminDetails(String adminId) async {
    final id = _requireAdminId(adminId);
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.adminDetail(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return SuperadminAdminDetails.fromJson(response.data);
  }

  Future<SuperadminAdminDetails> updateAdminDetails({
    required String adminId,
    required SuperadminUpdateAdminRequest request,
  }) async {
    final id = _requireAdminId(adminId);
    await _apiClient.post<dynamic>(
      ApiEndpoints.superadmin.updateAdmin(id),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    return getAdminDetails(id);
  }

  Future<void> setAdminActive({
    required String adminId,
    required bool isActive,
  }) async {
    final id = _requireAdminId(adminId);
    await _apiClient.post<dynamic>(
      ApiEndpoints.superadmin.activateAdmin(id),
      data: <String, dynamic>{'isActive': isActive},
      options: _mutationOptions,
      parser: (json) => json,
    );
  }

  Future<void> updateAdminPassword({
    required String adminId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final id = _requireAdminId(adminId);
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      throw ArgumentError('Password fields are required.');
    }
    if (newPassword != confirmPassword) {
      throw ArgumentError('Passwords do not match.');
    }
    final request = SuperadminAdminPasswordUpdateRequest(
      adminId: id,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    await _apiClient.post<dynamic>(
      ApiEndpoints.superadmin.adminPasswordUpdate,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
  }

  Future<SuperadminAdminDetails> updateAdminCompany({
    required String adminId,
    required SuperadminAdminCompanyUpdateRequest request,
  }) async {
    final id = _requireAdminId(adminId);
    await _apiClient.patch<dynamic>(
      ApiEndpoints.superadmin.companyConfig(id),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    return getAdminDetails(id);
  }

  Future<void> deleteAdmin(String adminId) async {
    final id = _requireAdminId(adminId);
    await _apiClient.delete<dynamic>(
      ApiEndpoints.superadmin.deleteAdmin(id),
      options: _mutationOptions,
      parser: (json) => json,
    );
  }

  Future<List<SuperadminCreditLog>> getCreditLogs(String adminId) async {
    final id = _requireAdminId(adminId);
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.creditLogs(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return SuperadminCreditLog.listFromJson(response.data);
  }

  Future<void> updateCredits({
    required String adminId,
    required SuperadminCreditUpdateRequest request,
  }) async {
    final id = _requireAdminId(adminId);
    final credits = request.credits.trim();
    if (credits.isEmpty) {
      throw ArgumentError('Credits value is required.');
    }
    final parsed = int.tryParse(credits);
    if (parsed == null || parsed <= 0) {
      throw ArgumentError('Credits must be a positive integer.');
    }
    if (request.activity == SuperadminCreditActivity.unknown) {
      throw ArgumentError('Credit activity is required.');
    }
    await _apiClient.post<dynamic>(
      ApiEndpoints.superadmin.assignCredits(id),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
  }

  Future<List<SuperadminAdminVehicle>> getAdminVehicles(String adminId) async {
    final id = _requireAdminId(adminId);
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.adminVehicles(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return SuperadminAdminVehicle.listFromJson(response.data);
  }

  Future<List<SuperadminAdminDocument>> getAdminDocuments(String adminId) async {
    final id = _requireAdminId(adminId);
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.documentsByAdmin(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return SuperadminAdminDocument.listFromJson(response.data);
  }

  Future<List<SuperadminDocumentTypeOption>> getDocumentTypes() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.documentTypes,
      options: _readOptions,
      parser: (json) => json,
    );
    final all = SuperadminDocumentTypeOption.listFromJson(response.data);
    return all.where((item) => item.isForUser).toList(growable: false);
  }

  Future<void> uploadAdminDocument(
    SuperadminAdminDocumentRequest request,
  ) async {
    _validateDocumentRequest(request, requireFile: true);
    final formData = await _buildDocumentFormData(request);
    await _apiClient.post<dynamic>(
      ApiEndpoints.superadmin.uploadDoc,
      data: formData,
      options: _uploadOptions,
      parser: (json) => json,
    );
  }

  Future<void> updateAdminDocument({
    required String docId,
    required SuperadminAdminDocumentRequest request,
  }) async {
    final id = docId.trim();
    if (id.isEmpty) {
      throw ArgumentError('docId is required.');
    }
    _validateDocumentRequest(request, requireFile: false);
    final formData = await _buildDocumentFormData(request);
    await _apiClient.patch<dynamic>(
      ApiEndpoints.superadmin.uploadDocById(id),
      data: formData,
      options: _uploadOptions,
      parser: (json) => json,
    );
  }

  Future<void> deleteAdminDocument(String docId) async {
    final id = docId.trim();
    if (id.isEmpty) {
      throw ArgumentError('docId is required.');
    }
    await _apiClient.delete<dynamic>(
      ApiEndpoints.superadmin.uploadDocById(id),
      options: _mutationOptions,
      parser: (json) => json,
    );
  }

  Future<SuperadminAdminActivityLogPage> getAdminActivityLogs({
    required String adminId,
    int limit = 20,
    String? q,
    String? actionPrefix,
    String? from,
    String? to,
    int? cursorId,
    String? refreshKey,
  }) async {
    final id = _requireAdminId(adminId);
    final normalizedLimit = limit < 1 ? 1 : (limit > 100 ? 100 : limit);

    final query = <String, dynamic>{
      'limit': normalizedLimit,
    };

    final normalizedQ = q?.trim() ?? '';
    if (normalizedQ.isNotEmpty) query['q'] = normalizedQ;

    final normalizedPrefix = actionPrefix?.trim() ?? '';
    if (normalizedPrefix.isNotEmpty) query['actionPrefix'] = normalizedPrefix;

    final normalizedFrom = from?.trim() ?? '';
    if (normalizedFrom.isNotEmpty) query['from'] = normalizedFrom;

    final normalizedTo = to?.trim() ?? '';
    if (normalizedTo.isNotEmpty) query['to'] = normalizedTo;

    if (cursorId != null && cursorId > 0) query['cursorId'] = cursorId;

    final normalizedRk = refreshKey?.trim();
    if (normalizedRk != null && normalizedRk.isNotEmpty) {
      query['rk'] = normalizedRk;
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.adminActivityLogs(id),
      queryParameters: query,
      options: _readOptions,
      parser: (json) => json,
    );
    return SuperadminAdminActivityLogPage.fromJson(response.data);
  }

  void _validateDocumentRequest(
    SuperadminAdminDocumentRequest request, {
    required bool requireFile,
  }) {
    if (request.title.trim().isEmpty) {
      throw ArgumentError('Document title is required.');
    }
    if (request.docTypeId.trim().isEmpty) {
      throw ArgumentError('Document type is required.');
    }
    if (request.associateId.trim().isEmpty) {
      throw ArgumentError('Associate id is required.');
    }
    if (requireFile && request.file == null) {
      throw ArgumentError('File is required.');
    }
  }

  Future<FormData> _buildDocumentFormData(
    SuperadminAdminDocumentRequest request,
  ) async {
    final formData = FormData();
    formData.fields.addAll(<MapEntry<String, String>>[
      MapEntry('title', request.title.trim()),
      MapEntry('docTypeId', request.docTypeId.trim()),
      const MapEntry('AssociateType', 'USER'),
      MapEntry('associateId', request.associateId.trim()),
      MapEntry('isVisible', request.isVisible.toString()),
      MapEntry('description', request.description.trim()),
    ]);

    if (request.tags.isNotEmpty) {
      final tags = request.tags
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .join(',');
      if (tags.isNotEmpty) {
        formData.fields.add(MapEntry('tags', tags));
      }
    }

    final expiry = request.expiryAt?.trim();
    if (expiry != null && expiry.isNotEmpty) {
      formData.fields.add(MapEntry('expiryAt', expiry));
    }

    final file = request.file;
    if (file != null) {
      final multipart = await _toMultipartFile(file);
      formData.files.add(MapEntry('File', multipart));
    }

    return formData;
  }

  Future<MultipartFile> _toMultipartFile(PlatformFile file) async {
    final fileName = file.name.trim().isEmpty ? 'document' : file.name.trim();
    final contentType = _contentTypeForExtension(_extension(fileName));

    if (file.bytes != null) {
      return MultipartFile.fromBytes(
        file.bytes!,
        filename: fileName,
        contentType: contentType,
      );
    }

    final path = file.path;
    if (path == null || path.isEmpty) {
      throw ArgumentError('File has no readable content.');
    }
    final bytes = await File(path).readAsBytes();
    return MultipartFile.fromBytes(
      bytes,
      filename: fileName,
      contentType: contentType,
    );
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
      case 'png':
        return MediaType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
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
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
