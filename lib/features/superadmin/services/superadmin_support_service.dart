import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/superadmin_support_model.dart';

class SuperadminSupportService {
  SuperadminSupportService(this._apiClient);

  static const int _maxAttachmentCount = 5;
  static const int _maxAttachmentBytes = 5 * 1024 * 1024;
  static const int _maxTitleLength = 120;
  static const int _maxMessageLength = 5000;
  static final RegExp _alphaNumericPattern = RegExp(r'[A-Za-z0-9]');

  static const Set<String> _allowedExtensions = <String>{
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

  static const Set<String> _blockedExtensions = <String>{
    'svg',
    'html',
    'htm',
    'js',
    'exe',
  };

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );

  static final Options _mutationOptions = Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  );

  static final Options _multipartOptions = Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    contentType: Headers.multipartFormDataContentType,
  );

  final ApiClient _apiClient;

  Future<List<SuperadminSupportTicketListItem>> getTickets({
    SuperadminSupportTicketStatus? status,
    String? search,
    String? priority,
    String? category,
    String? refreshKey,
  }) async {
    final normalizedSearch = search?.trim() ?? '';
    final normalizedPriority = _normalizeEnumQuery(priority);
    final normalizedCategory = _normalizeEnumQuery(category);

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.supportTickets,
      queryParameters: <String, dynamic>{
        'rk': _resolveRefreshKey(refreshKey),
        if (status != null) 'status': status.apiValue,
        if (normalizedSearch.isNotEmpty) 'search': normalizedSearch,
        if (normalizedPriority.isNotEmpty) 'priority': normalizedPriority,
        if (normalizedCategory.isNotEmpty) 'category': normalizedCategory,
      },
      options: _readOptions,
      parser: (json) => json,
    );

    final tickets = parseSuperadminSupportTicketList(response.data);
    tickets.sort(SuperadminSupportTicketListItem.compareInboxOrder);
    return tickets;
  }

  Future<SuperadminSupportTicketDetails> getTicketById(
    int id, {
    String? refreshKey,
  }) async {
    if (id <= 0) {
      throw ArgumentError('A valid ticket id is required.');
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.supportTicketById(id.toString()),
      queryParameters: <String, dynamic>{
        'rk': _resolveRefreshKey(refreshKey),
      },
      options: _readOptions,
      parser: (json) => json,
    );

    return SuperadminSupportTicketDetails.fromJson(response.data);
  }

  Future<void> updateTicketStatus({
    required int id,
    required SuperadminSupportTicketStatus status,
  }) async {
    if (id <= 0) {
      throw ArgumentError('A valid ticket id is required.');
    }

    await _apiClient.patch<void>(
      ApiEndpoints.superadmin.supportTicketStatus(id.toString()),
      data: <String, dynamic>{
        'status': status.apiValue,
      },
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<SuperadminSupportTicketCreatedResult> createTicket({
    required int adminId,
    required String title,
    required String message,
    required SuperadminSupportTicketCategory category,
    required SuperadminSupportTicketPriority priority,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    if (adminId <= 0) {
      throw ArgumentError('Please select an administrator.');
    }

    final normalizedTitle = title.trim();
    final normalizedMessage = message.trim();

    _validateTitle(normalizedTitle);
    _validateMessage(normalizedMessage);
    _validateAttachments(attachments);

    final formData = await _buildCreateTicketFormData(
      adminId: adminId,
      title: normalizedTitle,
      message: normalizedMessage,
      category: category,
      priority: priority,
      attachments: attachments,
    );

    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.superadmin.supportTickets,
      data: formData,
      options: _multipartOptions,
      parser: (json) => json,
    );

    return SuperadminSupportTicketCreatedResult.fromJson(response.data);
  }

  Future<SuperadminSupportMessageSentResult> sendReply({
    required int ticketId,
    required String message,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    if (ticketId <= 0) {
      throw ArgumentError('A valid ticket id is required.');
    }

    final normalizedMessage = message.trim();
    _validateMessage(normalizedMessage);
    _validateAttachments(attachments);

    final formData = await _buildReplyFormData(
      message: normalizedMessage,
      attachments: attachments,
    );

    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.superadmin.supportTicketMessages(ticketId.toString()),
      data: formData,
      options: _multipartOptions,
      parser: (json) => json,
    );

    return SuperadminSupportMessageSentResult.fromJson(response.data);
  }

  Future<List<SuperadminSupportAdminMini>> getAdminsForCreateTicket({
    String? refreshKey,
    String? search,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.adminList,
      queryParameters: <String, dynamic>{
        'rk': _resolveRefreshKey(refreshKey),
      },
      options: _readOptions,
      parser: (json) => json,
    );

    final admins = parseSuperadminSupportAdminList(response.data);
    final query = search?.trim().toLowerCase() ?? '';
    if (query.isEmpty) {
      return admins;
    }

    return admins.where((admin) {
      final haystack = [
        admin.displayName,
        admin.email,
        admin.phone,
        admin.uid.toString(),
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList(growable: false);
  }

  Future<FormData> _buildCreateTicketFormData({
    required int adminId,
    required String title,
    required String message,
    required SuperadminSupportTicketCategory category,
    required SuperadminSupportTicketPriority priority,
    required List<PlatformFile> attachments,
  }) async {
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('adminId', adminId.toString()),
      MapEntry('title', title),
      MapEntry('category', category.apiValue),
      MapEntry('priority', priority.apiValue),
      MapEntry('message', message),
    ]);

    final multipartFiles = await _toMultipartFiles(attachments);
    for (final file in multipartFiles) {
      formData.files.add(MapEntry('attachments', file));
    }

    return formData;
  }

  Future<FormData> _buildReplyFormData({
    required String message,
    required List<PlatformFile> attachments,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('message', message));

    final multipartFiles = await _toMultipartFiles(attachments);
    for (final file in multipartFiles) {
      formData.files.add(MapEntry('attachments', file));
    }

    return formData;
  }

  Future<List<MultipartFile>> _toMultipartFiles(
    List<PlatformFile> attachments,
  ) async {
    if (attachments.isEmpty) {
      return const <MultipartFile>[];
    }

    final files = <MultipartFile>[];
    for (final attachment in attachments) {
      final fileName = attachment.name.trim().isEmpty
          ? 'attachment'
          : attachment.name.trim();
      final contentType = _contentTypeForExtension(
        _extensionFromFileName(fileName),
      );

      if (attachment.bytes != null) {
        files.add(
          MultipartFile.fromBytes(
            attachment.bytes!,
            filename: fileName,
            contentType: contentType,
          ),
        );
        continue;
      }

      final path = attachment.path?.trim();
      if (path != null && path.isNotEmpty) {
        files.add(
          await MultipartFile.fromFile(
            path,
            filename: fileName,
            contentType: contentType,
          ),
        );
        continue;
      }

      throw ArgumentError('Unable to read attachment "$fileName".');
    }

    return files;
  }

  void _validateTitle(String title) {
    if (title.isEmpty) {
      throw ArgumentError('Title is required.');
    }

    if (title.length > _maxTitleLength) {
      throw ArgumentError('Title must be $_maxTitleLength characters or less.');
    }

    if (!_alphaNumericPattern.hasMatch(title)) {
      throw ArgumentError('Title must contain at least one letter or number.');
    }
  }

  void _validateMessage(String message) {
    if (message.isEmpty) {
      throw ArgumentError('Message is required.');
    }

    if (message.length > _maxMessageLength) {
      throw ArgumentError(
        'Message must be $_maxMessageLength characters or less.',
      );
    }

    if (!_alphaNumericPattern.hasMatch(message)) {
      throw ArgumentError(
        'Message must contain at least one letter or number.',
      );
    }
  }

  void _validateAttachments(List<PlatformFile> attachments) {
    if (attachments.length > _maxAttachmentCount) {
      throw ArgumentError('You can upload up to $_maxAttachmentCount files.');
    }

    for (final attachment in attachments) {
      final fileName = attachment.name.trim();
      final extension = _extensionFromFileName(fileName);
      if (_blockedExtensions.contains(extension)) {
        throw ArgumentError(
          '"$fileName" is blocked. Please remove executable or script-like files.',
        );
      }

      if (!_allowedExtensions.contains(extension)) {
        throw ArgumentError(
          '"$fileName" is not supported. Allowed files: ${_allowedExtensions.join(', ')}.',
        );
      }

      if (attachment.size > _maxAttachmentBytes) {
        throw ArgumentError(
          '"$fileName" exceeds the 5MB size limit.',
        );
      }
    }
  }

  String _resolveRefreshKey(String? refreshKey) {
    final normalized = refreshKey?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }

    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String _normalizeEnumQuery(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '';
    }

    return normalized.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
  }

  String _extensionFromFileName(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    final index = normalized.lastIndexOf('.');
    if (index < 0 || index == normalized.length - 1) {
      return '';
    }

    return normalized.substring(index + 1);
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
