import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/admin_user_details_model.dart';

class AdminUserDetailsService {
  AdminUserDetailsService(this._apiClient);

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

  Future<AdminUserDetails> getUserDetails(String userId) async {
    final id = _requireUserId(userId);
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.userById(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminUserDetails.fromJson(response.data, fallbackId: id);
  }

  Future<AdminUserDetails> updateUserDetails(
    String userId,
    AdminUpdateUserDetailsRequest request,
  ) async {
    final id = _requireUserId(userId);
    await _apiClient.patch<dynamic>(
      ApiEndpoints.admin.userById(id),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    return getUserDetails(id);
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    final id = _requireUserId(userId);
    await _apiClient.patch<void>(
      ApiEndpoints.admin.userById(id),
      data: <String, dynamic>{'isActive': isActive.toString()},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> updateUserPassword(String userId, String newPassword) async {
    final id = _requireUserId(userId);
    final normalizedPassword = newPassword.trim();
    if (normalizedPassword.isEmpty) {
      throw ArgumentError('Password is required.');
    }
    await _apiClient.post<void>(
      ApiEndpoints.admin.updateUserPassword(id),
      data: AdminUpdateUserPasswordRequest(
        newPassword: normalizedPassword,
      ).toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<AdminUserCompany?> getCompanyDetails(String userId) async {
    final id = _requireUserId(userId);
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.companyDetailsByUserId(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminUserCompany.maybeFromJson(response.data);
  }

  Future<AdminUserDetails> updateCompanyDetails(
    String userId,
    AdminUpdateUserCompanyRequest request,
  ) async {
    final id = _requireUserId(userId);
    _validateCompanyRequest(request);
    await _apiClient.patch<dynamic>(
      ApiEndpoints.admin.companyDetailsByUserId(id),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    return getUserDetails(id);
  }

  Future<List<AdminUserVehicle>> getLinkedVehicles(String userId) async {
    final id = _requireUserId(userId);
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.linkedVehiclesByUserId(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminUserVehicle.listFromJson(response.data);
  }

  Future<List<AdminUserVehicle>> getUnlinkedVehicles(String userId) async {
    final id = _requireUserId(userId);
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.unlinkedVehiclesByUserId(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminUserVehicle.listFromJson(response.data);
  }

  Future<void> linkVehicle(String userId, String vehicleId) async {
    final id = _requireUserId(userId);
    final normalizedVehicleId = _requireId(vehicleId, 'vehicleId');
    await _apiClient.post<void>(
      ApiEndpoints.admin.linkedVehiclesByUserId(id),
      data: <String, dynamic>{'vehicleId': normalizedVehicleId},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> unlinkVehicle(String userId, String vehicleId) async {
    final id = _requireUserId(userId);
    final normalizedVehicleId = _requireId(vehicleId, 'vehicleId');
    await _apiClient.post<void>(
      ApiEndpoints.admin.unlinkedVehiclesByUserId(id),
      data: <String, dynamic>{'vehicleId': normalizedVehicleId},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<List<AdminUserDriver>> getLinkedDrivers(String userId) async {
    final id = _requireUserId(userId);
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.linkedDriversByUserId(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminUserDriver.listFromJson(response.data);
  }

  Future<List<AdminUserDriver>> getUnlinkedDrivers(String userId) async {
    final id = _requireUserId(userId);
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.unlinkedDriversByUserId(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminUserDriver.listFromJson(response.data);
  }

  Future<void> linkDriver(String userId, String driverId) async {
    final id = _requireUserId(userId);
    final normalizedDriverId = _requireId(driverId, 'driverId');
    await _apiClient.post<void>(
      ApiEndpoints.admin.linkedDriversByUserId(id),
      data: <String, dynamic>{'driverId': _idPayloadValue(normalizedDriverId)},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> unlinkDriver(String userId, String driverId) async {
    final id = _requireUserId(userId);
    final normalizedDriverId = _requireId(driverId, 'driverId');
    await _apiClient.post<void>(
      ApiEndpoints.admin.unlinkedDriversByUserId(id),
      data: <String, dynamic>{'driverId': _idPayloadValue(normalizedDriverId)},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<List<AdminUserDocument>> getDocuments(String userId) async {
    final id = _requireUserId(userId);
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.documentsByUser(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminUserDocument.listFromJson(response.data);
  }

  Future<List<AdminDocumentTypeOption>> getDocumentTypes() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.userDocumentTypes,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminDocumentTypeOption.listFromJson(response.data);
  }

  Future<void> uploadDocument(AdminUserDocumentRequest request) async {
    _validateDocumentRequest(request, requireFile: true);
    final formData = await _buildDocumentFormData(request);
    await _apiClient.post<void>(
      ApiEndpoints.admin.uploadDoc,
      data: formData,
      options: _uploadOptions,
      parser: (_) {},
    );
  }

  Future<void> updateDocument({
    required String docId,
    required AdminUserDocumentRequest request,
  }) async {
    final id = _requireId(docId, 'docId');
    _validateDocumentRequest(request, requireFile: false);
    final formData = await _buildDocumentFormData(request);
    await _apiClient.patch<void>(
      ApiEndpoints.admin.uploadDocById(id),
      data: formData,
      options: _uploadOptions,
      parser: (_) {},
    );
  }

  Future<void> deleteDocument(String docId) async {
    final id = _requireId(docId, 'docId');
    await _apiClient.delete<void>(
      ApiEndpoints.admin.uploadDocById(id),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<List<AdminUserTicket>> getTickets(String userId) async {
    final id = _requireUserId(userId);
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.tickets,
      queryParameters: <String, dynamic>{'userId': id},
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminUserTicket.listFromJson(response.data);
  }

  Future<AdminUserTicket> getTicketById(String ticketId) async {
    final id = _requireId(ticketId, 'ticketId');
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.ticketById(id),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminUserTicket.fromJson(response.data);
  }

  Future<AdminUserTicket> createTicket({
    required String userId,
    required String title,
    required String message,
    required String category,
    required String priority,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    final id = _requireUserId(userId);
    final normalizedTitle = _requireId(title, 'title');
    final normalizedMessage = _requireId(message, 'message');
    final normalizedCategory = _requireId(category, 'category');
    final normalizedPriority = _requireId(priority, 'priority');
    final formData = await _buildTicketFormData(
      fields: <String, String>{
        'fromUserId': id,
        'title': normalizedTitle,
        'category': normalizedCategory,
        'priority': normalizedPriority,
        'message': normalizedMessage,
      },
      attachments: attachments,
    );
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.tickets,
      data: formData,
      options: _uploadOptions,
      parser: (json) => json,
    );
    return AdminUserTicket.fromJson(response.data);
  }

  Future<AdminUserTicketMessage> replyTicket({
    required String ticketId,
    required String message,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    final id = _requireId(ticketId, 'ticketId');
    final normalizedMessage = _requireId(message, 'message');
    final formData = await _buildTicketFormData(
      fields: <String, String>{'message': normalizedMessage},
      attachments: attachments,
    );
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.ticketMessages(id),
      data: formData,
      options: _uploadOptions,
      parser: (json) => json,
    );
    return AdminUserTicketMessage.fromJson(response.data);
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    final id = _requireId(ticketId, 'ticketId');
    final normalizedStatus = _requireId(status, 'status').toUpperCase();
    await _apiClient.patch<void>(
      ApiEndpoints.admin.ticketStatus(id),
      data: <String, dynamic>{'status': normalizedStatus},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<AdminUserPaymentPage> getPayments({
    required String userId,
    int page = 1,
    int limit = 100,
    String? status,
    String? from,
    String? to,
    String? q,
  }) async {
    final id = _requireUserId(userId);
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedLimit = limit < 1 ? 100 : (limit > 100 ? 100 : limit);
    final query = <String, dynamic>{
      'userId': id,
      'page': normalizedPage,
      'limit': normalizedLimit,
    };
    _putQuery(query, 'status', status);
    _putQuery(query, 'from', from);
    _putQuery(query, 'to', to);
    _putQuery(query, 'q', q);

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.adminPayments,
      queryParameters: query,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminUserPaymentPage.fromJson(
      response.data,
      defaultPage: normalizedPage,
      defaultLimit: normalizedLimit,
    );
  }

  Future<void> renewVehiclesPayment(
    AdminRenewVehiclesPaymentRequest request,
  ) async {
    if (request.vehicleIds.isEmpty) {
      throw ArgumentError('Select at least one vehicle.');
    }
    await _apiClient.post<void>(
      ApiEndpoints.admin.renewVehiclesPayment,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<AdminUserActivityLogPage> getActivityLogs({
    required String userId,
    int limit = 20,
    int? cursorId,
    String? q,
    String? actionPrefix,
    String? from,
    String? to,
  }) async {
    final id = _requireUserId(userId);
    final normalizedLimit = limit < 1 ? 20 : (limit > 100 ? 100 : limit);
    final query = <String, dynamic>{'limit': normalizedLimit};
    if (cursorId != null && cursorId > 0) {
      query['cursorId'] = cursorId;
    }
    _putQuery(query, 'q', q);
    _putQuery(query, 'actionPrefix', actionPrefix);
    _putQuery(query, 'from', from);
    _putQuery(query, 'to', to);

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.userActivityLogs(id),
      queryParameters: query,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminUserActivityLogPage.fromJson(response.data);
  }

  String _requireUserId(String userId) {
    return _requireId(userId, 'userId');
  }

  String _requireId(String value, String fieldName) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('$fieldName is required.');
    }
    return normalized;
  }

  Object _idPayloadValue(String id) {
    final normalized = id.trim();
    return int.tryParse(normalized) ?? normalized;
  }

  void _validateCompanyRequest(AdminUpdateUserCompanyRequest request) {
    if (request.name.trim().isEmpty) {
      throw ArgumentError('Company name is required.');
    }
    final color = request.primaryColor.trim();
    if (color.isNotEmpty &&
        !AdminUpdateUserCompanyRequest.allowedPrimaryColors.any(
          (item) => item.toLowerCase() == color.toLowerCase(),
        )) {
      throw ArgumentError('Unsupported company color.');
    }
  }

  void _validateDocumentRequest(
    AdminUserDocumentRequest request, {
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
    AdminUserDocumentRequest request,
  ) async {
    final associateType = request.associateType.trim().isEmpty
        ? 'USER'
        : request.associateType.trim().toUpperCase();
    final formData = FormData();
    formData.fields.addAll(<MapEntry<String, String>>[
      MapEntry('title', request.title.trim()),
      MapEntry('docTypeId', request.docTypeId.trim()),
      MapEntry('associateType', associateType),
      MapEntry('associateId', request.associateId.trim()),
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
      formData.files.add(MapEntry('file', await _toMultipartFile(file)));
    }

    return formData;
  }

  Future<FormData> _buildTicketFormData({
    required Map<String, String> fields,
    required List<PlatformFile> attachments,
  }) async {
    final formData = FormData();
    fields.forEach((key, value) {
      formData.fields.add(MapEntry(key, value));
    });
    for (final attachment in attachments) {
      formData.files.add(
        MapEntry('attachments', await _toMultipartFile(attachment)),
      );
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

  void _putQuery(Map<String, dynamic> query, String key, String? value) {
    final normalized = value?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      query[key] = normalized;
    }
  }
}
