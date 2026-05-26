import 'package:file_picker/file_picker.dart';

enum UserSupportTicketStatus { open, inProgress, closed }

enum UserSupportTicketCategory {
  server,
  notifications,
  maps,
  billing,
  installation,
  other,
}

enum UserSupportTicketPriority { low, medium, high }

extension UserSupportTicketStatusX on UserSupportTicketStatus {
  String get apiValue {
    switch (this) {
      case UserSupportTicketStatus.open:
        return 'OPEN';
      case UserSupportTicketStatus.inProgress:
        return 'IN_PROGRESS';
      case UserSupportTicketStatus.closed:
        return 'CLOSED';
    }
  }

  String get label {
    switch (this) {
      case UserSupportTicketStatus.open:
        return 'Open';
      case UserSupportTicketStatus.inProgress:
        return 'In Progress';
      case UserSupportTicketStatus.closed:
        return 'Closed';
    }
  }

  int get sortOrder {
    switch (this) {
      case UserSupportTicketStatus.open:
        return 0;
      case UserSupportTicketStatus.inProgress:
        return 1;
      case UserSupportTicketStatus.closed:
        return 2;
    }
  }
}

extension UserSupportTicketCategoryX on UserSupportTicketCategory {
  String get apiValue {
    switch (this) {
      case UserSupportTicketCategory.server:
        return 'SERVER';
      case UserSupportTicketCategory.notifications:
        return 'NOTIFICATIONS';
      case UserSupportTicketCategory.maps:
        return 'MAPS';
      case UserSupportTicketCategory.billing:
        return 'BILLING';
      case UserSupportTicketCategory.installation:
        return 'INSTALLATION';
      case UserSupportTicketCategory.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case UserSupportTicketCategory.server:
        return 'Server';
      case UserSupportTicketCategory.notifications:
        return 'Notifications';
      case UserSupportTicketCategory.maps:
        return 'Maps';
      case UserSupportTicketCategory.billing:
        return 'Billing';
      case UserSupportTicketCategory.installation:
        return 'Installation';
      case UserSupportTicketCategory.other:
        return 'Other';
    }
  }
}

extension UserSupportTicketPriorityX on UserSupportTicketPriority {
  String get apiValue {
    switch (this) {
      case UserSupportTicketPriority.low:
        return 'LOW';
      case UserSupportTicketPriority.medium:
        return 'MEDIUM';
      case UserSupportTicketPriority.high:
        return 'HIGH';
    }
  }

  String get label {
    switch (this) {
      case UserSupportTicketPriority.low:
        return 'Low';
      case UserSupportTicketPriority.medium:
        return 'Medium';
      case UserSupportTicketPriority.high:
        return 'High';
    }
  }

  int get sortWeight {
    switch (this) {
      case UserSupportTicketPriority.high:
        return 3;
      case UserSupportTicketPriority.medium:
        return 2;
      case UserSupportTicketPriority.low:
        return 1;
    }
  }
}

class UserSupportParticipant {
  const UserSupportParticipant({
    required this.id,
    required this.name,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String role;

  String get displayName {
    for (final value in [name, email, mobileNumber, id]) {
      final normalized = value.trim();
      if (normalized.isNotEmpty && normalized != '-') {
        return normalized;
      }
    }

    return 'Support';
  }

  factory UserSupportParticipant.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserSupportParticipant(
      id:
          _firstId(source, const [
            'id',
            '_id',
            'uid',
            'userId',
            'user_id',
            'senderId',
          ]) ??
          '',
      name:
          _firstString(source, const [
            'name',
            'username',
            'fullName',
            'full_name',
            'displayName',
          ]) ??
          '',
      email: _firstString(source, const ['email', 'emailId', 'email_id']) ?? '',
      mobilePrefix:
          _firstString(source, const [
            'mobilePrefix',
            'mobile_prefix',
            'countryCode',
          ]) ??
          '',
      mobileNumber:
          _firstString(source, const [
            'mobileNumber',
            'mobile_number',
            'phone',
            'mobile',
          ]) ??
          '',
      role: _firstString(source, const ['role', 'type', 'userType']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'mobilePrefix': mobilePrefix,
      'mobileNumber': mobileNumber,
      'role': role,
    };
  }
}

class UserSupportTicketAttachment {
  const UserSupportTicketAttachment({
    required this.id,
    required this.originalName,
    required this.storedName,
    required this.filePath,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    required this.metadata,
  });

  final String id;
  final String originalName;
  final String storedName;
  final String filePath;
  final String mimeType;
  final int sizeBytes;
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;

  String get displayName {
    for (final value in [
      originalName,
      storedName,
      _lastPathSegment(filePath),
    ]) {
      final normalized = value.trim();
      if (normalized.isNotEmpty && normalized != '-') {
        return normalized;
      }
    }

    return 'Attachment';
  }

  factory UserSupportTicketAttachment.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserSupportTicketAttachment(
      id: _firstId(source, const ['id', '_id', 'uid', 'attachmentId']) ?? '',
      originalName:
          _firstString(source, const [
            'originalName',
            'original_name',
            'fileName',
            'file_name',
            'filename',
            'name',
            'title',
          ]) ??
          '',
      storedName:
          _firstString(source, const [
            'storedName',
            'stored_name',
            'storageName',
            'key',
          ]) ??
          '',
      filePath:
          _firstString(source, const [
            'filePath',
            'file_path',
            'fileUrl',
            'file_url',
            'url',
            'path',
          ]) ??
          '',
      mimeType:
          _firstString(source, const [
            'mimeType',
            'mime_type',
            'contentType',
            'content_type',
            'type',
          ]) ??
          '',
      sizeBytes:
          _firstInt(source, const [
            'sizeBytes',
            'size_bytes',
            'size',
            'fileSize',
            'file_size',
          ]) ??
          0,
      createdAt: _firstDate(source, const [
        'createdAt',
        'created_at',
        'uploadedAt',
        'uploaded_at',
      ]),
      metadata: source,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...metadata,
      'id': id,
      'originalName': originalName,
      'storedName': storedName,
      'filePath': filePath,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static List<UserSupportTicketAttachment> listFromJson(dynamic json) {
    final entries = _extractList(
      json,
      keys: const [
        'attachments',
        'files',
        'documents',
        'docs',
        'items',
        'data',
      ],
    );

    return entries
        .map(UserSupportTicketAttachment.fromJson)
        .where(
          (attachment) =>
              attachment.filePath.trim().isNotEmpty ||
              attachment.displayName.trim().isNotEmpty,
        )
        .toList(growable: false);
  }
}

class UserSupportTicketMessage {
  const UserSupportTicketMessage({
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
  final UserSupportParticipant? sender;
  final List<UserSupportTicketAttachment> attachments;

  bool get hasBody => message.trim().isNotEmpty;

  bool isFromCurrentUser(String currentUserId) {
    final normalizedCurrentUserId = currentUserId.trim();
    final normalizedSenderId = senderId.trim();
    if (normalizedCurrentUserId.isNotEmpty &&
        normalizedSenderId == normalizedCurrentUserId) {
      return true;
    }

    final role = sender?.role.trim().toLowerCase() ?? '';
    return role == 'user' || role == 'customer' || role == 'end_user';
  }

  String get identity {
    final normalizedId = id.trim();
    if (normalizedId.isNotEmpty) {
      return 'id:$normalizedId';
    }

    return [
      senderId,
      createdAt?.toIso8601String() ?? '',
      message.trim(),
      attachments.map((attachment) => attachment.displayName).join('|'),
    ].join('::');
  }

  factory UserSupportTicketMessage.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['message', 'reply', 'item', 'record'],
    );
    final senderMap = _firstMap(source, const [
      'sender',
      'fromUser',
      'from_user',
      'user',
      'admin',
      'supportUser',
    ]);
    final sender = senderMap == null
        ? null
        : UserSupportParticipant.fromJson(senderMap);
    final senderId =
        _firstId(source, const [
          'senderId',
          'sender_id',
          'fromUserId',
          'from_user_id',
          'userId',
          'user_id',
          'adminUserId',
        ]) ??
        sender?.id ??
        '';

    return UserSupportTicketMessage(
      id:
          _firstId(source, const ['id', '_id', 'messageId', 'message_id']) ??
          '',
      message:
          _firstString(source, const [
            'message',
            'body',
            'text',
            'content',
            'reply',
          ]) ??
          '',
      senderId: senderId,
      createdAt: _firstDate(source, const [
        'createdAt',
        'created_at',
        'sentAt',
        'sent_at',
        'timestamp',
      ]),
      sender: sender,
      attachments: UserSupportTicketAttachment.listFromJson(
        _firstValue(source, const [
          'attachments',
          'files',
          'documents',
          'docs',
        ]),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'message': message,
      'senderId': senderId,
      'createdAt': createdAt?.toIso8601String(),
      'sender': sender?.toJson(),
      'attachments': attachments
          .map((attachment) => attachment.toJson())
          .toList(),
    };
  }

  static List<UserSupportTicketMessage> listFromJson(dynamic json) {
    final entries = _extractList(
      json,
      keys: const [
        'messages',
        'conversation',
        'replies',
        'ticketMessages',
        'items',
        'rows',
        'data',
      ],
    );

    final messages = entries
        .map(UserSupportTicketMessage.fromJson)
        .where(
          (message) =>
              message.id.trim().isNotEmpty ||
              message.hasBody ||
              message.attachments.isNotEmpty,
        )
        .toList(growable: true);

    messages.sort((left, right) {
      final leftDate = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final byDate = leftDate.compareTo(rightDate);
      if (byDate != 0) {
        return byDate;
      }
      return left.id.compareTo(right.id);
    });

    return _deduplicateMessages(messages);
  }
}

class UserSupportTicketListItem {
  const UserSupportTicketListItem({
    required this.id,
    required this.ticketNo,
    required this.title,
    required this.status,
    required this.category,
    required this.priority,
    required this.messageCount,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    required this.fromUser,
    required this.toUser,
  });

  final String id;
  final String ticketNo;
  final String title;
  final UserSupportTicketStatus status;
  final UserSupportTicketCategory category;
  final UserSupportTicketPriority priority;
  final int messageCount;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserSupportParticipant? fromUser;
  final UserSupportParticipant? toUser;

  bool get isClosed => status == UserSupportTicketStatus.closed;

  String get displayTicketNo {
    final normalized = ticketNo.trim();
    return normalized.isEmpty ? '#$id' : normalized;
  }

  DateTime get sortingDate {
    return lastMessageAt ??
        updatedAt ??
        createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String get searchContent {
    return [
      id,
      ticketNo,
      title,
      status.label,
      status.apiValue,
      category.label,
      category.apiValue,
      priority.label,
      priority.apiValue,
      fromUser?.displayName ?? '',
      toUser?.displayName ?? '',
    ].join(' ').toLowerCase();
  }

  factory UserSupportTicketListItem.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['ticket', 'item', 'record', 'details'],
    );
    final fromUserMap = _firstMap(source, const [
      'fromUser',
      'from_user',
      'user',
      'sender',
      'createdBy',
    ]);
    final toUserMap = _firstMap(source, const [
      'toUser',
      'to_user',
      'assignee',
      'assignedTo',
      'supportUser',
    ]);
    final id =
        _firstId(source, const ['id', '_id', 'ticketId', 'ticket_id', 'uid']) ??
        '';

    return UserSupportTicketListItem(
      id: id,
      ticketNo:
          _firstString(source, const [
            'ticketNo',
            'ticket_no',
            'ticketNumber',
            'ticket_number',
            'number',
          ]) ??
          '',
      title:
          _firstString(source, const ['title', 'subject', 'issue', 'name']) ??
          'Support ticket',
      status: parseUserSupportTicketStatus(
        _firstValue(source, const ['status', 'ticketStatus', 'ticket_status']),
      ),
      category: parseUserSupportTicketCategory(
        _firstValue(source, const ['category', 'ticketCategory', 'type']),
      ),
      priority: parseUserSupportTicketPriority(
        _firstValue(source, const ['priority', 'ticketPriority', 'severity']),
      ),
      messageCount:
          _firstInt(source, const [
            'messageCount',
            'message_count',
            'messagesCount',
            'replyCount',
          ]) ??
          UserSupportTicketMessage.listFromJson(
            _firstValue(source, const ['messages', 'conversation', 'replies']),
          ).length,
      lastMessageAt: _firstDate(source, const [
        'lastMessageAt',
        'last_message_at',
        'lastActivityAt',
        'last_activity_at',
        'lastReplyAt',
        'last_reply_at',
      ]),
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(source, const ['updatedAt', 'updated_at']),
      fromUser: fromUserMap == null
          ? null
          : UserSupportParticipant.fromJson(fromUserMap),
      toUser: toUserMap == null
          ? null
          : UserSupportParticipant.fromJson(toUserMap),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'ticketNo': ticketNo,
      'title': title,
      'status': status.apiValue,
      'category': category.apiValue,
      'priority': priority.apiValue,
      'messageCount': messageCount,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'fromUser': fromUser?.toJson(),
      'toUser': toUser?.toJson(),
    };
  }

  static int compareInboxOrder(
    UserSupportTicketListItem left,
    UserSupportTicketListItem right,
  ) {
    final byDate = right.sortingDate.compareTo(left.sortingDate);
    if (byDate != 0) {
      return byDate;
    }

    final byId = right.id.compareTo(left.id);
    if (byId != 0) {
      return byId;
    }

    return 0;
  }

  static List<UserSupportTicketListItem> listFromJson(dynamic json) {
    final entries = _extractList(
      json,
      keys: const ['tickets', 'items', 'rows', 'records', 'list', 'data'],
    );

    final tickets = entries
        .map(UserSupportTicketListItem.fromJson)
        .where((ticket) => ticket.id.trim().isNotEmpty)
        .toList(growable: true);

    tickets.sort(UserSupportTicketListItem.compareInboxOrder);
    return tickets;
  }
}

class UserSupportTicketDetail {
  const UserSupportTicketDetail({
    required this.id,
    required this.ticketNo,
    required this.title,
    required this.status,
    required this.category,
    required this.priority,
    required this.messageCount,
    required this.lastMessageAt,
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
  final UserSupportTicketStatus status;
  final UserSupportTicketCategory category;
  final UserSupportTicketPriority priority;
  final int messageCount;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final UserSupportParticipant? fromUser;
  final UserSupportParticipant? toUser;
  final List<UserSupportTicketMessage> messages;

  bool get isClosed => status == UserSupportTicketStatus.closed;

  String get displayTicketNo {
    final normalized = ticketNo.trim();
    return normalized.isEmpty ? '#$id' : normalized;
  }

  UserSupportTicketListItem toListItem() {
    return UserSupportTicketListItem(
      id: id,
      ticketNo: ticketNo,
      title: title,
      status: status,
      category: category,
      priority: priority,
      messageCount: messages.isEmpty ? messageCount : messages.length,
      lastMessageAt: lastMessageAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fromUser: fromUser,
      toUser: toUser,
    );
  }

  factory UserSupportTicketDetail.fromJson(dynamic json) {
    final source = _asMap(json);
    final ticketPayload = _extractMapPayload(
      json,
      preferredKeys: const ['ticket', 'details', 'item', 'record', 'data'],
    );
    final payload = ticketPayload.isEmpty ? source : ticketPayload;
    final fromUserMap = _firstMap(payload, const [
      'fromUser',
      'from_user',
      'user',
      'sender',
      'createdBy',
    ]);
    final toUserMap = _firstMap(payload, const [
      'toUser',
      'to_user',
      'assignee',
      'assignedTo',
      'supportUser',
    ]);
    final messagesSource =
        _firstValueDeep(json, const [
          'messages',
          'conversation',
          'replies',
          'ticketMessages',
        ]) ??
        _firstValue(payload, const ['messages', 'conversation', 'replies']);
    final messages = UserSupportTicketMessage.listFromJson(messagesSource);
    final id =
        _firstId(payload, const [
          'id',
          '_id',
          'ticketId',
          'ticket_id',
          'uid',
        ]) ??
        _firstId(source, const ['id', '_id', 'ticketId', 'ticket_id']) ??
        '';

    return UserSupportTicketDetail(
      id: id,
      ticketNo:
          _firstString(payload, const [
            'ticketNo',
            'ticket_no',
            'ticketNumber',
            'ticket_number',
            'number',
          ]) ??
          '',
      title:
          _firstString(payload, const ['title', 'subject', 'issue', 'name']) ??
          'Support ticket',
      status: parseUserSupportTicketStatus(
        _firstValue(payload, const ['status', 'ticketStatus', 'ticket_status']),
      ),
      category: parseUserSupportTicketCategory(
        _firstValue(payload, const ['category', 'ticketCategory', 'type']),
      ),
      priority: parseUserSupportTicketPriority(
        _firstValue(payload, const ['priority', 'ticketPriority', 'severity']),
      ),
      messageCount:
          _firstInt(payload, const [
            'messageCount',
            'message_count',
            'messagesCount',
            'replyCount',
          ]) ??
          messages.length,
      lastMessageAt: _firstDate(payload, const [
        'lastMessageAt',
        'last_message_at',
        'lastActivityAt',
        'last_activity_at',
        'lastReplyAt',
        'last_reply_at',
      ]),
      createdAt: _firstDate(payload, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(payload, const ['updatedAt', 'updated_at']),
      closedAt: _firstDate(payload, const [
        'closedAt',
        'closed_at',
        'resolvedAt',
        'resolved_at',
      ]),
      fromUser: fromUserMap == null
          ? null
          : UserSupportParticipant.fromJson(fromUserMap),
      toUser: toUserMap == null
          ? null
          : UserSupportParticipant.fromJson(toUserMap),
      messages: messages,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'ticketNo': ticketNo,
      'title': title,
      'status': status.apiValue,
      'category': category.apiValue,
      'priority': priority.apiValue,
      'messageCount': messageCount,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'fromUser': fromUser?.toJson(),
      'toUser': toUser?.toJson(),
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }
}

class UserCreateSupportTicketRequest {
  const UserCreateSupportTicketRequest({
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    this.attachments = const <PlatformFile>[],
  });

  final String title;
  final String message;
  final UserSupportTicketCategory category;
  final UserSupportTicketPriority priority;
  final List<PlatformFile> attachments;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title.trim(),
      'message': message.trim(),
      'category': category.apiValue,
      'priority': priority.apiValue,
    };
  }
}

class UserReplySupportTicketRequest {
  const UserReplySupportTicketRequest({
    required this.message,
    this.attachments = const <PlatformFile>[],
  });

  final String message;
  final List<PlatformFile> attachments;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'message': message.trim()};
  }
}

UserSupportTicketStatus parseUserSupportTicketStatus(dynamic value) {
  final normalized = _normalizeEnumValue(value);
  switch (normalized) {
    case 'IN_PROGRESS':
    case 'INPROGRESS':
    case 'PENDING':
      return UserSupportTicketStatus.inProgress;
    case 'CLOSED':
    case 'RESOLVED':
    case 'DONE':
      return UserSupportTicketStatus.closed;
    case 'OPEN':
    default:
      return UserSupportTicketStatus.open;
  }
}

UserSupportTicketCategory parseUserSupportTicketCategory(dynamic value) {
  final normalized = _normalizeEnumValue(value);
  switch (normalized) {
    case 'SERVER':
      return UserSupportTicketCategory.server;
    case 'NOTIFICATIONS':
      return UserSupportTicketCategory.notifications;
    case 'MAPS':
    case 'MAP':
      return UserSupportTicketCategory.maps;
    case 'BILLING':
    case 'PAYMENT':
      return UserSupportTicketCategory.billing;
    case 'INSTALLATION':
      return UserSupportTicketCategory.installation;
    case 'OTHER':
    default:
      return UserSupportTicketCategory.other;
  }
}

UserSupportTicketPriority parseUserSupportTicketPriority(dynamic value) {
  final normalized = _normalizeEnumValue(value);
  switch (normalized) {
    case 'LOW':
      return UserSupportTicketPriority.low;
    case 'HIGH':
    case 'URGENT':
      return UserSupportTicketPriority.high;
    case 'MEDIUM':
    default:
      return UserSupportTicketPriority.medium;
  }
}

List<UserSupportTicketMessage> _deduplicateMessages(
  List<UserSupportTicketMessage> messages,
) {
  final seen = <String>{};
  final unique = <UserSupportTicketMessage>[];
  for (final message in messages) {
    if (seen.add(message.identity)) {
      unique.add(message);
    }
  }
  return unique;
}

Map<String, dynamic> _extractMapPayload(
  dynamic json, {
  required List<String> preferredKeys,
}) {
  final source = _asMap(json);
  if (source.isEmpty) {
    return const <String, dynamic>{};
  }

  for (final key in preferredKeys) {
    final nested = source[key];
    final nestedMap = _asMap(nested);
    if (nestedMap.isNotEmpty) {
      return _extractMapPayload(nestedMap, preferredKeys: preferredKeys);
    }
  }

  return source;
}

List<dynamic> _extractList(dynamic json, {required List<String> keys}) {
  if (json is List) {
    return json;
  }

  final source = _asMap(json);
  if (source.isEmpty) {
    return const <dynamic>[];
  }

  for (final key in keys) {
    final value = source[key];
    if (value is List) {
      return value;
    }
    final nested = _extractList(value, keys: keys);
    if (nested.isNotEmpty) {
      return nested;
    }
  }

  if (_looksLikeSingleTicketOrMessage(source)) {
    return <dynamic>[source];
  }

  return const <dynamic>[];
}

bool _looksLikeSingleTicketOrMessage(Map<String, dynamic> source) {
  return const [
    'id',
    '_id',
    'ticketId',
    'messageId',
    'title',
    'subject',
    'message',
    'body',
  ].any(source.containsKey);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  return const <String, dynamic>{};
}

Map<String, dynamic>? _firstMap(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    final map = _asMap(value);
    if (map.isNotEmpty) {
      return map;
    }
  }
  return null;
}

dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (source.containsKey(key) && source[key] != null) {
      return source[key];
    }
  }
  return null;
}

dynamic _firstValueDeep(dynamic json, List<String> keys, [int depth = 0]) {
  if (depth > 4) {
    return null;
  }

  final source = _asMap(json);
  if (source.isEmpty) {
    return null;
  }

  final direct = _firstValue(source, keys);
  if (direct != null) {
    return direct;
  }

  for (final nestedKey in const [
    'data',
    'ticket',
    'details',
    'item',
    'record',
  ]) {
    final nested = source[nestedKey];
    if (nested == null) {
      continue;
    }
    final nestedValue = _firstValueDeep(nested, keys, depth + 1);
    if (nestedValue != null) {
      return nestedValue;
    }
  }

  return null;
}

String? _firstString(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  final normalized = _stringValue(value);
  return normalized.isEmpty ? null : normalized;
}

String? _firstId(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  final normalized = _stringValue(value);
  return normalized.isEmpty ? null : normalized;
}

int? _firstInt(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

DateTime? _firstDate(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  return _parseDate(value);
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(
      value > 9999999999 ? value : value * 1000,
      isUtc: true,
    );
  }

  if (value is num) {
    final integerValue = value.toInt();
    return DateTime.fromMillisecondsSinceEpoch(
      integerValue > 9999999999 ? integerValue : integerValue * 1000,
      isUtc: true,
    );
  }

  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == '-') {
      return null;
    }
    return DateTime.tryParse(normalized);
  }

  return null;
}

String _normalizeEnumValue(dynamic value) {
  return _stringValue(
    value,
  ).toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
}

String _stringValue(dynamic value) {
  if (value == null) {
    return '';
  }

  if (value is num && value % 1 == 0) {
    return value.toInt().toString();
  }

  return value.toString().trim();
}

String _lastPathSegment(String path) {
  final normalized = path.trim();
  if (normalized.isEmpty) {
    return '';
  }

  final normalizedPath = normalized.replaceAll('\\', '/');
  final segments = normalizedPath.split('/');
  return segments.isEmpty ? normalized : segments.last.trim();
}
