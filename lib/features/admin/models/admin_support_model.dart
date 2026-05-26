import 'package:file_picker/file_picker.dart';

import 'admin_users_model.dart';

enum AdminSupportTab { userTickets, myTickets }

enum AdminSupportTicketStatus { open, inProgress, closed }

enum AdminSupportTicketCategory {
  server,
  notifications,
  maps,
  billing,
  installation,
  other,
}

enum AdminSupportTicketPriority { low, medium, high }

extension AdminSupportTicketStatusX on AdminSupportTicketStatus {
  String get apiValue {
    switch (this) {
      case AdminSupportTicketStatus.open:
        return 'OPEN';
      case AdminSupportTicketStatus.inProgress:
        return 'IN_PROGRESS';
      case AdminSupportTicketStatus.closed:
        return 'CLOSED';
    }
  }

  String get label {
    switch (this) {
      case AdminSupportTicketStatus.open:
        return 'Open';
      case AdminSupportTicketStatus.inProgress:
        return 'In Progress';
      case AdminSupportTicketStatus.closed:
        return 'Closed';
    }
  }

  static AdminSupportTicketStatus? fromApi(String? value) {
    final normalized = value?.trim().toUpperCase();
    switch (normalized) {
      case 'OPEN':
        return AdminSupportTicketStatus.open;
      case 'IN_PROGRESS':
        return AdminSupportTicketStatus.inProgress;
      case 'CLOSED':
        return AdminSupportTicketStatus.closed;
      default:
        return null;
    }
  }
}

extension AdminSupportTicketCategoryX on AdminSupportTicketCategory {
  String get apiValue {
    switch (this) {
      case AdminSupportTicketCategory.server:
        return 'SERVER';
      case AdminSupportTicketCategory.notifications:
        return 'NOTIFICATIONS';
      case AdminSupportTicketCategory.maps:
        return 'MAPS';
      case AdminSupportTicketCategory.billing:
        return 'BILLING';
      case AdminSupportTicketCategory.installation:
        return 'INSTALLATION';
      case AdminSupportTicketCategory.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case AdminSupportTicketCategory.server:
        return 'Server';
      case AdminSupportTicketCategory.notifications:
        return 'Notifications';
      case AdminSupportTicketCategory.maps:
        return 'Maps';
      case AdminSupportTicketCategory.billing:
        return 'Billing';
      case AdminSupportTicketCategory.installation:
        return 'Installation';
      case AdminSupportTicketCategory.other:
        return 'Other';
    }
  }

  static AdminSupportTicketCategory fromApi(String? value) {
    final normalized = value?.trim().toUpperCase();
    switch (normalized) {
      case 'SERVER':
        return AdminSupportTicketCategory.server;
      case 'NOTIFICATIONS':
        return AdminSupportTicketCategory.notifications;
      case 'MAPS':
        return AdminSupportTicketCategory.maps;
      case 'BILLING':
        return AdminSupportTicketCategory.billing;
      case 'INSTALLATION':
        return AdminSupportTicketCategory.installation;
      default:
        return AdminSupportTicketCategory.other;
    }
  }
}

extension AdminSupportTicketPriorityX on AdminSupportTicketPriority {
  String get apiValue {
    switch (this) {
      case AdminSupportTicketPriority.low:
        return 'LOW';
      case AdminSupportTicketPriority.medium:
        return 'MEDIUM';
      case AdminSupportTicketPriority.high:
        return 'HIGH';
    }
  }

  String get label {
    switch (this) {
      case AdminSupportTicketPriority.low:
        return 'Low';
      case AdminSupportTicketPriority.medium:
        return 'Medium';
      case AdminSupportTicketPriority.high:
        return 'High';
    }
  }

  int get sortWeight {
    switch (this) {
      case AdminSupportTicketPriority.high:
        return 3;
      case AdminSupportTicketPriority.medium:
        return 2;
      case AdminSupportTicketPriority.low:
        return 1;
    }
  }

  static AdminSupportTicketPriority fromApi(String? value) {
    final normalized = value?.trim().toUpperCase();
    switch (normalized) {
      case 'HIGH':
        return AdminSupportTicketPriority.high;
      case 'MEDIUM':
        return AdminSupportTicketPriority.medium;
      default:
        return AdminSupportTicketPriority.low;
    }
  }
}

class AdminSupportUserMini {
  const AdminSupportUserMini({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;

  String get displayName =>
      name.trim().isEmpty ? (username.isEmpty ? id : username) : name;

  String get phone {
    final prefix = mobilePrefix.trim();
    final number = mobileNumber.trim();
    if (prefix.isEmpty && number.isEmpty) return '-';
    if (prefix.isEmpty) return number;
    if (number.isEmpty) return prefix;
    return '$prefix $number';
  }

  factory AdminSupportUserMini.fromJson(dynamic json) {
    final map = _asMap(json);
    return AdminSupportUserMini(
      id: (_firstValue(map, const ['uid', 'id', '_id', 'userId', 'user_id']) ??
              '')
          .toString(),
      name: _firstString(
              map, const ['name', 'fullName', 'full_name', 'displayName']) ??
          '-',
      username:
          _firstString(map, const ['username', 'userName', 'user_name']) ?? '-',
      email: _firstString(map, const ['email']) ?? '-',
      mobilePrefix: _firstString(map, const [
            'mobilePrefix',
            'mobile_prefix',
            'phonePrefix',
            'phone_prefix'
          ]) ??
          '',
      mobileNumber: _firstString(map, const [
            'mobileNumber',
            'mobile_number',
            'mobile',
            'phoneNumber',
            'phone_number',
            'phone'
          ]) ??
          '',
    );
  }

  factory AdminSupportUserMini.fromAdminUser(AdminUserListItem user) {
    return AdminSupportUserMini(
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
      mobilePrefix: user.mobilePrefix,
      mobileNumber: user.mobileNumber,
    );
  }
}

class AdminSupportTicketListItem {
  const AdminSupportTicketListItem({
    required this.id,
    required this.ticketNo,
    required this.title,
    required this.status,
    required this.category,
    required this.priority,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    required this.fromUser,
    required this.toUser,
  });

  final String id;
  final String ticketNo;
  final String title;
  final AdminSupportTicketStatus status;
  final AdminSupportTicketCategory category;
  final AdminSupportTicketPriority priority;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AdminSupportUserMini? fromUser;
  final AdminSupportUserMini? toUser;

  DateTime get sortingDate =>
      lastMessageAt ??
      updatedAt ??
      createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  String get displayTicketNo => ticketNo.trim().isEmpty ? '#$id' : ticketNo;

  bool get isClosed => status == AdminSupportTicketStatus.closed;

  static int compareInboxOrder(
    AdminSupportTicketListItem a,
    AdminSupportTicketListItem b,
  ) {
    final timeDiff = b.sortingDate.compareTo(a.sortingDate);
    if (timeDiff != 0) return timeDiff;

    final aId = int.tryParse(a.id) ?? 0;
    final bId = int.tryParse(b.id) ?? 0;
    return bId.compareTo(aId);
  }

  factory AdminSupportTicketListItem.fromJson(dynamic json) {
    final source = _asMap(json);
    final payload =
        _firstMap(source, const ['ticket', 'item', 'record', 'details']) ??
            source;
    final from = _firstMap(payload, const ['fromUser', 'user', 'customer']) ??
        _firstMap(source, const ['fromUser', 'user', 'customer']);
    final to = _firstMap(payload, const ['toUser', 'admin', 'superadmin']) ??
        _firstMap(source, const ['toUser', 'admin', 'superadmin']);

    return AdminSupportTicketListItem(
      id: (_firstValue(payload,
                  const ['id', '_id', 'ticketId', 'ticket_id', 'uid']) ??
              '')
          .toString(),
      ticketNo: _firstString(payload, const [
            'ticketNo',
            'ticket_no',
            'ticketNumber',
            'ticket_number'
          ]) ??
          '',
      title: _firstString(payload, const ['title', 'subject']) ??
          'Untitled ticket',
      status: AdminSupportTicketStatusX.fromApi(
            _firstString(
                payload, const ['status', 'ticketStatus', 'ticket_status']),
          ) ??
          AdminSupportTicketStatus.open,
      category: AdminSupportTicketCategoryX.fromApi(
        _firstString(
            payload, const ['category', 'ticketCategory', 'ticket_category']),
      ),
      priority: AdminSupportTicketPriorityX.fromApi(
        _firstString(
            payload, const ['priority', 'ticketPriority', 'ticket_priority']),
      ),
      lastMessageAt:
          _firstDate(payload, const ['lastMessageAt', 'last_message_at']),
      createdAt: _firstDate(payload, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(payload, const ['updatedAt', 'updated_at']),
      fromUser: from == null ? null : AdminSupportUserMini.fromJson(from),
      toUser: to == null ? null : AdminSupportUserMini.fromJson(to),
    );
  }

  static List<AdminSupportTicketListItem> listFromJson(dynamic json) {
    final list = _extractList(json);
    return list
        .map(AdminSupportTicketListItem.fromJson)
        .where((e) => e.id.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class AdminSupportAttachment {
  const AdminSupportAttachment({
    required this.id,
    required this.originalName,
    required this.storedName,
    required this.filePath,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String id;
  final String originalName;
  final String storedName;
  final String filePath;
  final String mimeType;
  final int sizeBytes;
  final DateTime? createdAt;

  String get displayName {
    if (originalName.trim().isNotEmpty) return originalName.trim();
    if (storedName.trim().isNotEmpty) return storedName.trim();
    return 'Attachment';
  }

  factory AdminSupportAttachment.fromJson(dynamic json) {
    final map = _asMap(json);
    return AdminSupportAttachment(
      id: (_firstValue(
                  map, const ['id', '_id', 'attachmentId', 'attachment_id']) ??
              '')
          .toString(),
      originalName: _firstString(map, const [
            'originalName',
            'original_name',
            'name',
            'fileName',
            'filename'
          ]) ??
          '',
      storedName: _firstString(map, const ['storedName', 'stored_name']) ?? '',
      filePath:
          _firstString(map, const ['filePath', 'file_path', 'url', 'path']) ??
              '',
      mimeType:
          _firstString(map, const ['mimeType', 'mime_type', 'type']) ?? '',
      sizeBytes: _firstInt(map, const ['sizeBytes', 'size_bytes', 'size']) ?? 0,
      createdAt: _firstDate(map, const ['createdAt', 'created_at']),
    );
  }
}

class AdminSupportMessage {
  const AdminSupportMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.createdAt,
    required this.sender,
    required this.attachments,
  });

  final String id;
  final String message;
  final String senderId;
  final DateTime? createdAt;
  final AdminSupportUserMini? sender;
  final List<AdminSupportAttachment> attachments;

  factory AdminSupportMessage.fromJson(dynamic json) {
    final map = _asMap(json);
    final sender =
        _firstMap(map, const ['sender', 'fromUser', 'user', 'author']);
    final attachmentsRaw =
        _firstList(map, const ['attachments', 'files']) ?? const <dynamic>[];

    return AdminSupportMessage(
      id: (_firstValue(map, const ['id', '_id', 'messageId', 'message_id']) ??
              '')
          .toString(),
      message:
          _firstString(map, const ['message', 'body', 'text', 'content']) ?? '',
      senderId: (_firstValue(map, const [
                'senderId',
                'sender_id',
                'fromUserId',
                'from_user_id',
                'userId',
                'user_id'
              ]) ??
              '')
          .toString(),
      createdAt: _firstDate(map, const ['createdAt', 'created_at']),
      sender: sender == null ? null : AdminSupportUserMini.fromJson(sender),
      attachments: attachmentsRaw
          .map(AdminSupportAttachment.fromJson)
          .toList(growable: false),
    );
  }
}

class AdminSupportTicketDetails {
  const AdminSupportTicketDetails({
    required this.id,
    required this.ticketNo,
    required this.title,
    required this.status,
    required this.category,
    required this.priority,
    required this.fromUserId,
    required this.toUserId,
    required this.adminUserId,
    required this.createdAt,
    required this.updatedAt,
    required this.closedAt,
    required this.fromUser,
    required this.toUser,
    required this.messages,
  });

  final String id;
  final String ticketNo;
  final String title;
  final AdminSupportTicketStatus status;
  final AdminSupportTicketCategory category;
  final AdminSupportTicketPriority priority;
  final String fromUserId;
  final String toUserId;
  final String adminUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final AdminSupportUserMini? fromUser;
  final AdminSupportUserMini? toUser;
  final List<AdminSupportMessage> messages;

  String get displayTicketNo => ticketNo.trim().isNotEmpty ? ticketNo : '#$id';

  factory AdminSupportTicketDetails.fromJson(dynamic json) {
    final source = _asMap(json);
    final data = _extractSingle(source);
    final from = _firstMap(data, const ['fromUser', 'user', 'customer']);
    final to = _firstMap(data, const ['toUser', 'admin', 'superadmin']);
    final messagesRaw = _firstList(data, const ['messages', 'conversation']) ??
        const <dynamic>[];
    final parsedMessages =
        messagesRaw.map(AdminSupportMessage.fromJson).toList(growable: false)
          ..sort((a, b) {
            final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return ad.compareTo(bd);
          });

    return AdminSupportTicketDetails(
      id: (_firstValue(
                  data, const ['id', '_id', 'ticketId', 'ticket_id', 'uid']) ??
              '')
          .toString(),
      ticketNo: _firstString(data, const [
            'ticketNo',
            'ticket_no',
            'ticketNumber',
            'ticket_number'
          ]) ??
          '',
      title:
          _firstString(data, const ['title', 'subject']) ?? 'Untitled ticket',
      status: AdminSupportTicketStatusX.fromApi(
              _firstString(data, const ['status'])) ??
          AdminSupportTicketStatus.open,
      category: AdminSupportTicketCategoryX.fromApi(
          _firstString(data, const ['category'])),
      priority: AdminSupportTicketPriorityX.fromApi(
          _firstString(data, const ['priority'])),
      fromUserId:
          (_firstValue(data, const ['fromUserId', 'from_user_id']) ?? '')
              .toString(),
      toUserId: (_firstValue(data, const ['toUserId', 'to_user_id']) ?? '')
          .toString(),
      adminUserId:
          (_firstValue(data, const ['adminUserId', 'admin_user_id']) ?? '')
              .toString(),
      createdAt: _firstDate(data, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(data, const ['updatedAt', 'updated_at']),
      closedAt: _firstDate(data, const ['closedAt', 'closed_at']),
      fromUser: from == null ? null : AdminSupportUserMini.fromJson(from),
      toUser: to == null ? null : AdminSupportUserMini.fromJson(to),
      messages: parsedMessages,
    );
  }
}

class AdminSupportTicketCreatedResult {
  const AdminSupportTicketCreatedResult({required this.ticketId});

  final String ticketId;

  factory AdminSupportTicketCreatedResult.fromJson(dynamic json) {
    final data = _extractSingle(_asMap(json));
    return AdminSupportTicketCreatedResult(
      ticketId:
          (_firstValue(data, const ['ticketId', 'ticket_id', 'id', '_id']) ??
                  '')
              .toString(),
    );
  }
}

class AdminSupportMessageSentResult {
  const AdminSupportMessageSentResult({required this.messageId});

  final String messageId;

  factory AdminSupportMessageSentResult.fromJson(dynamic json) {
    final data = _extractSingle(_asMap(json));
    return AdminSupportMessageSentResult(
      messageId:
          (_firstValue(data, const ['messageId', 'message_id', 'id', '_id']) ??
                  '')
              .toString(),
    );
  }
}

class AdminSupportCreateTicketRequest {
  const AdminSupportCreateTicketRequest({
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    required this.attachments,
    this.fromUserId,
  });

  final String title;
  final String message;
  final AdminSupportTicketCategory category;
  final AdminSupportTicketPriority priority;
  final String? fromUserId;
  final List<PlatformFile> attachments;
}

List<dynamic> _extractList(dynamic json) {
  if (json is List) return json;
  final map = _asMap(json);
  final nested = _extractSingle(map);

  for (final key in const ['items', 'tickets', 'data', 'rows', 'list']) {
    final candidate = nested[key] ?? map[key];
    if (candidate is List) return candidate;
  }

  return const <dynamic>[];
}

Map<String, dynamic> _extractSingle(Map<String, dynamic> map) {
  dynamic current = map;
  for (var i = 0; i < 5; i++) {
    final asMap = _asMap(current);
    if (asMap.isEmpty) return const <String, dynamic>{};
    final data = asMap['data'];
    if (data is Map) {
      current = data;
      continue;
    }
    if (asMap['action'] != null && asMap['data'] is Map) {
      current = asMap['data'];
      continue;
    }
    return asMap;
  }
  return _asMap(current);
}

Map<String, dynamic>? _firstMap(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    final parsed = _asMap(value);
    if (parsed.isNotEmpty) return parsed;
  }
  return null;
}

List<dynamic>? _firstList(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is List) return value;
  }
  return null;
}

dynamic _firstValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map.containsKey(key)) return map[key];
  }
  return null;
}

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  final value = _firstValue(map, keys);
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _firstInt(Map<String, dynamic> map, List<String> keys) {
  final value = _firstValue(map, keys);
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString().trim());
}

DateTime? _firstDate(Map<String, dynamic> map, List<String> keys) {
  final value = _firstValue(map, keys);
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) {
    if (value <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
  return null;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}
