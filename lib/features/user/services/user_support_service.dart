import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/user_support_constraints.dart';
import '../models/user_support_model.dart';

class UserSupportService {
  UserSupportService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );

  static final Options _multipartOptions = Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    contentType: Headers.multipartFormDataContentType,
  );

  Future<List<UserSupportTicketListItem>> fetchTickets({
    UserSupportTicketStatus? status,
    String? search,
    int? page,
    int? limit,
    String? refreshKey,
  }) async {
    final response = await _apiClient.get<List<UserSupportTicketListItem>>(
      ApiEndpoints.user.tickets,
      queryParameters: _query(<String, dynamic>{
        'status': status?.apiValue,
        'search': search,
        'page': page,
        'limit': limit,
        'rk': refreshKey,
      }),
      options: _readOptions,
      parser: UserSupportTicketListItem.listFromJson,
    );

    final tickets = response.data.toList(growable: true);
    tickets.sort(UserSupportTicketListItem.compareInboxOrder);
    return tickets;
  }

  Future<UserSupportTicketDetail> fetchTicketById(String ticketId) async {
    final id = _requireId(ticketId, 'ticketId');
    final response = await _apiClient.get<UserSupportTicketDetail>(
      ApiEndpoints.user.ticketById(id),
      options: _readOptions,
      parser: UserSupportTicketDetail.fromJson,
    );
    return response.data;
  }

  Future<UserSupportTicketDetail> createTicket({
    required String title,
    required String message,
    UserSupportTicketCategory category = UserSupportTicketCategory.other,
    UserSupportTicketPriority priority = UserSupportTicketPriority.medium,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    final request = UserCreateSupportTicketRequest(
      title: _normalizeTitle(title),
      message: _normalizeMessage(message),
      category: category,
      priority: priority,
      attachments: attachments,
    );

    _validateAttachments(request.attachments);

    final formData = await _buildTicketFormData(
      fields: request.toJson(),
      attachments: request.attachments,
    );

    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.user.tickets,
      data: formData,
      options: _multipartOptions,
      parser: (json) => json,
    );

    final createdTicket = UserSupportTicketDetail.fromJson(response.data);
    if (createdTicket.id.trim().isEmpty) {
      return createdTicket;
    }

    try {
      return await fetchTicketById(createdTicket.id);
    } catch (_) {
      return createdTicket;
    }
  }

  Future<UserSupportTicketDetail> replyToTicket({
    required String ticketId,
    required String message,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    final id = _requireId(ticketId, 'ticketId');
    final request = UserReplySupportTicketRequest(
      message: _normalizeMessage(message),
      attachments: attachments,
    );

    _validateAttachments(request.attachments);

    final formData = await _buildTicketFormData(
      fields: request.toJson(),
      attachments: request.attachments,
    );

    await _apiClient.post<dynamic>(
      ApiEndpoints.user.ticketById(id),
      data: formData,
      options: _multipartOptions,
      parser: (json) => json,
    );

    return fetchTicketById(id);
  }

  Future<FormData> _buildTicketFormData({
    required Map<String, dynamic> fields,
    required List<PlatformFile> attachments,
  }) async {
    final formData = FormData();
    for (final entry in fields.entries) {
      final value = entry.value?.toString().trim();
      if (value == null || value.isEmpty) {
        continue;
      }
      formData.fields.add(MapEntry(entry.key, value));
    }

    for (final attachment in attachments) {
      formData.files.add(
        MapEntry('attachments', await _toMultipartFile(attachment)),
      );
    }

    return formData;
  }

  Future<MultipartFile> _toMultipartFile(PlatformFile file) async {
    final fileName = file.name.trim().isEmpty ? 'attachment' : file.name.trim();
    final contentType =
        _contentTypeForExtension(userSupportExtensionFromFileName(fileName));

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

    throw ArgumentError('Unable to read attachment "$fileName".');
  }

  String _normalizeTitle(String title) {
    final normalized = title.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('Title is required.');
    }
    if (normalized.length > userSupportMaxTitleLength) {
      throw ArgumentError(
        'Title must be $userSupportMaxTitleLength characters or less.',
      );
    }
    if (!userSupportContainsLetterOrNumber(normalized)) {
      throw ArgumentError('Title must contain at least one letter or number.');
    }
    return normalized;
  }

  String _normalizeMessage(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('Message is required.');
    }
    if (normalized.length > userSupportMaxMessageLength) {
      throw ArgumentError(
        'Message must be $userSupportMaxMessageLength characters or less.',
      );
    }
    if (!userSupportContainsLetterOrNumber(normalized)) {
      throw ArgumentError(
          'Message must contain at least one letter or number.');
    }
    return normalized;
  }

  void _validateAttachments(List<PlatformFile> attachments) {
    if (attachments.length > userSupportMaxAttachmentCount) {
      throw ArgumentError(
        'You can upload up to $userSupportMaxAttachmentCount files.',
      );
    }

    for (final attachment in attachments) {
      final fileName = attachment.name.trim().isEmpty
          ? 'attachment'
          : attachment.name.trim();
      final extension = userSupportExtensionFromFileName(fileName);
      if (userSupportBlockedAttachmentExtensions.contains(extension)) {
        throw ArgumentError(
          '"$fileName" is blocked. Please remove executable or script-like files.',
        );
      }
      if (!userSupportAllowedAttachmentExtensions.contains(extension)) {
        throw ArgumentError(
          '"$fileName" is not supported. Allowed files: ${userSupportAllowedAttachmentExtensions.join(', ')}.',
        );
      }
      if (attachment.size > userSupportMaxAttachmentBytes) {
        throw ArgumentError('"$fileName" exceeds the 5MB size limit.');
      }
    }
  }

  String _requireId(String value, String fieldName) {
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
