import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../models/admin_support_model.dart';
import '../models/admin_users_model.dart';

class AdminSupportService {
  AdminSupportService(this._apiClient);

  static const int maxAttachmentCount = 5;
  static const int maxAttachmentBytes = 5 * 1024 * 1024;
  static const int minTitleLength = 3;
  static const int maxTitleLength = 80;
  static const int minMessageLength = 10;
  static const int maxMessageLength = 1000;
  static final RegExp _alphaNum = RegExp(r'[A-Za-z0-9]');

  static const Set<String> allowedExtensions = <String>{
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'doc',
    'docx',
    'txt',
    'zip',
  };

  static const Set<String> blockedExtensions = <String>{
    'svg',
    'html',
    'htm',
    'js',
    'exe',
  };

  static final Options _readOptions = normalReadOptions();

  static final Options _mutationOptions = normalWriteOptions();

  static final Options _multipartOptions = uploadOptions().copyWith(
    contentType: Headers.multipartFormDataContentType,
  );

  final ApiClient _apiClient;

  Future<List<AdminSupportTicketListItem>> getUserTickets({
    String? refreshKey,
    AdminSupportTicketStatus? status,
    String? search,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.tickets,
      queryParameters: <String, dynamic>{
        if (refreshKey != null && refreshKey.trim().isNotEmpty)
          'rk': refreshKey.trim(),
        if (status != null) 'status': status.apiValue,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      options: _readOptions,
      parser: (json) => json,
    );
    final list = AdminSupportTicketListItem.listFromJson(response.data)
        .toList(growable: true)
      ..sort(AdminSupportTicketListItem.compareInboxOrder);
    return list;
  }

  Future<List<AdminSupportTicketListItem>> getMyTickets({
    String? refreshKey,
    AdminSupportTicketStatus? status,
    String? search,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.myTickets,
      queryParameters: <String, dynamic>{
        if (refreshKey != null && refreshKey.trim().isNotEmpty)
          'rk': refreshKey.trim(),
        if (status != null) 'status': status.apiValue,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      options: _readOptions,
      parser: (json) => json,
    );
    final list = AdminSupportTicketListItem.listFromJson(response.data)
        .toList(growable: true)
      ..sort(AdminSupportTicketListItem.compareInboxOrder);
    return list;
  }

  Future<AdminSupportTicketDetails> getUserTicketById(String id,
      {String? refreshKey}) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.ticketById(id),
      queryParameters: <String, dynamic>{
        if (refreshKey != null && refreshKey.trim().isNotEmpty)
          'rk': refreshKey.trim(),
      },
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminSupportTicketDetails.fromJson(response.data);
  }

  Future<AdminSupportTicketDetails> getMyTicketById(String id,
      {String? refreshKey}) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.myTicketById(id),
      queryParameters: <String, dynamic>{
        if (refreshKey != null && refreshKey.trim().isNotEmpty)
          'rk': refreshKey.trim(),
      },
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminSupportTicketDetails.fromJson(response.data);
  }

  Future<void> updateUserTicketStatus(
      {required String id, required AdminSupportTicketStatus status}) async {
    await _apiClient.patch<void>(
      ApiEndpoints.admin.ticketStatus(id),
      data: <String, dynamic>{'status': status.apiValue},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> updateMyTicketStatus(
      {required String id, required AdminSupportTicketStatus status}) async {
    await _apiClient.patch<void>(
      ApiEndpoints.admin.myTicketStatus(id),
      data: <String, dynamic>{'status': status.apiValue},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<AdminSupportTicketCreatedResult> createUserTicket(
      AdminSupportCreateTicketRequest request) async {
    final fromUserId = request.fromUserId?.trim() ?? '';
    if (fromUserId.isEmpty) {
      throw ArgumentError('User is required.');
    }

    _validateTitle(request.title);
    _validateMessage(request.message);
    _validateAttachments(request.attachments);

    final formData = FormData();
    formData.fields.addAll([
      MapEntry('fromUserId', fromUserId),
      MapEntry('title', request.title.trim()),
      MapEntry('category', request.category.apiValue),
      MapEntry('priority', request.priority.apiValue),
      MapEntry('message', request.message.trim()),
    ]);

    final files = await _toMultipartFiles(request.attachments);
    for (final file in files) {
      formData.files.add(MapEntry('attachments', file));
    }

    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.tickets,
      data: formData,
      options: _multipartOptions,
      parser: (json) => json,
    );

    return AdminSupportTicketCreatedResult.fromJson(response.data);
  }

  Future<AdminSupportTicketCreatedResult> createMyTicket(
      AdminSupportCreateTicketRequest request) async {
    _validateTitle(request.title);
    _validateMessage(request.message);
    _validateAttachments(request.attachments);

    final formData = FormData();
    formData.fields.addAll([
      MapEntry('title', request.title.trim()),
      MapEntry('category', request.category.apiValue),
      MapEntry('priority', request.priority.apiValue),
      MapEntry('message', request.message.trim()),
    ]);

    final files = await _toMultipartFiles(request.attachments);
    for (final file in files) {
      formData.files.add(MapEntry('attachments', file));
    }

    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.myTickets,
      data: formData,
      options: _multipartOptions,
      parser: (json) => json,
    );

    return AdminSupportTicketCreatedResult.fromJson(response.data);
  }

  Future<AdminSupportMessageSentResult> sendUserTicketReply({
    required String ticketId,
    required String message,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    _validateMessage(message);
    _validateAttachments(attachments);

    final formData = FormData();
    formData.fields.add(MapEntry('message', message.trim()));
    final files = await _toMultipartFiles(attachments);
    for (final file in files) {
      formData.files.add(MapEntry('attachments', file));
    }

    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.ticketMessages(ticketId),
      data: formData,
      options: _multipartOptions,
      parser: (json) => json,
    );
    return AdminSupportMessageSentResult.fromJson(response.data);
  }

  Future<AdminSupportMessageSentResult> sendMyTicketReply({
    required String ticketId,
    required String message,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    _validateMessage(message);
    _validateAttachments(attachments);

    final formData = FormData();
    formData.fields.add(MapEntry('message', message.trim()));
    final files = await _toMultipartFiles(attachments);
    for (final file in files) {
      formData.files.add(MapEntry('attachments', file));
    }

    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.myTicketMessages(ticketId),
      data: formData,
      options: _multipartOptions,
      parser: (json) => json,
    );
    return AdminSupportMessageSentResult.fromJson(response.data);
  }

  Future<List<AdminSupportUserMini>> getUsers({String? refreshKey}) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.users,
      queryParameters: <String, dynamic>{
        if (refreshKey != null && refreshKey.trim().isNotEmpty)
          'rk': refreshKey.trim(),
      },
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminUserListItem.listFromJson(response.data)
        .map(AdminSupportUserMini.fromAdminUser)
        .toList(growable: false);
  }

  void _validateTitle(String titleRaw) {
    final title = titleRaw.trim();
    if (title.isEmpty) {
      throw ArgumentError('Title is required.');
    }
    if (title.length < minTitleLength || title.length > maxTitleLength) {
      throw ArgumentError(
          'Title must be between $minTitleLength and $maxTitleLength characters.');
    }
    if (!_alphaNum.hasMatch(title)) {
      throw ArgumentError('Title must contain at least one letter or number.');
    }
  }

  void _validateMessage(String messageRaw) {
    final message = messageRaw.trim();
    if (message.isEmpty) {
      throw ArgumentError('Message is required.');
    }
    if (message.length < minMessageLength ||
        message.length > maxMessageLength) {
      throw ArgumentError(
          'Message must be between $minMessageLength and $maxMessageLength characters.');
    }
    if (!_alphaNum.hasMatch(message)) {
      throw ArgumentError(
          'Message must contain at least one letter or number.');
    }
  }

  void _validateAttachments(List<PlatformFile> attachments) {
    if (attachments.length > maxAttachmentCount) {
      throw ArgumentError('You can upload up to $maxAttachmentCount files.');
    }

    for (final file in attachments) {
      final name = file.name.trim().isEmpty ? 'attachment' : file.name.trim();
      final ext = _extension(name);
      if (blockedExtensions.contains(ext)) {
        throw ArgumentError('"$name" is blocked. Remove script-like files.');
      }
      if (!allowedExtensions.contains(ext)) {
        throw ArgumentError('"$name" is not supported.');
      }
      if (file.size > maxAttachmentBytes) {
        throw ArgumentError('"$name" exceeds the 5MB size limit.');
      }
    }
  }

  Future<List<MultipartFile>> _toMultipartFiles(
      List<PlatformFile> files) async {
    if (files.isEmpty) return const <MultipartFile>[];
    final out = <MultipartFile>[];

    for (final file in files) {
      final fileName =
          file.name.trim().isEmpty ? 'attachment' : file.name.trim();
      final contentType = _contentTypeForExtension(_extension(fileName));

      if (file.bytes != null) {
        out.add(
          MultipartFile.fromBytes(
            file.bytes!,
            filename: fileName,
            contentType: contentType,
          ),
        );
        continue;
      }

      final path = file.path?.trim();
      if (path == null || path.isEmpty) {
        throw ArgumentError('Unable to read attachment "$fileName".');
      }

      out.add(
        await MultipartFile.fromFile(
          path,
          filename: fileName,
          contentType: contentType,
        ),
      );
    }

    return out;
  }

  String _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot + 1 >= fileName.length) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  MediaType _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType(
          'application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      case 'txt':
        return MediaType('text', 'plain');
      case 'zip':
        return MediaType('application', 'zip');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
