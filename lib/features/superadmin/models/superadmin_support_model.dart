import 'package:file_picker/file_picker.dart';

enum SuperadminSupportTicketStatus {
  open,
  inProgress,
  closed,
}

enum SuperadminSupportTicketCategory {
  server,
  notifications,
  maps,
  billing,
  installation,
  other,
}

enum SuperadminSupportTicketPriority {
  low,
  medium,
  high,
}

extension SuperadminSupportTicketStatusX on SuperadminSupportTicketStatus {
  String get apiValue {
    switch (this) {
      case SuperadminSupportTicketStatus.open:
        return 'OPEN';
      case SuperadminSupportTicketStatus.inProgress:
        return 'IN_PROGRESS';
      case SuperadminSupportTicketStatus.closed:
        return 'CLOSED';
    }
  }

  String get label {
    switch (this) {
      case SuperadminSupportTicketStatus.open:
        return 'Open';
      case SuperadminSupportTicketStatus.inProgress:
        return 'In Progress';
      case SuperadminSupportTicketStatus.closed:
        return 'Closed';
    }
  }

  int get sortOrder {
    switch (this) {
      case SuperadminSupportTicketStatus.open:
        return 0;
      case SuperadminSupportTicketStatus.inProgress:
        return 1;
      case SuperadminSupportTicketStatus.closed:
        return 2;
    }
  }
}

extension SuperadminSupportTicketCategoryX on SuperadminSupportTicketCategory {
  String get apiValue {
    switch (this) {
      case SuperadminSupportTicketCategory.server:
        return 'SERVER';
      case SuperadminSupportTicketCategory.notifications:
        return 'NOTIFICATIONS';
      case SuperadminSupportTicketCategory.maps:
        return 'MAPS';
      case SuperadminSupportTicketCategory.billing:
        return 'BILLING';
      case SuperadminSupportTicketCategory.installation:
        return 'INSTALLATION';
      case SuperadminSupportTicketCategory.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case SuperadminSupportTicketCategory.server:
        return 'Server';
      case SuperadminSupportTicketCategory.notifications:
        return 'Notifications';
      case SuperadminSupportTicketCategory.maps:
        return 'Maps';
      case SuperadminSupportTicketCategory.billing:
        return 'Billing';
      case SuperadminSupportTicketCategory.installation:
        return 'Installation';
      case SuperadminSupportTicketCategory.other:
        return 'Other';
    }
  }
}

extension SuperadminSupportTicketPriorityX on SuperadminSupportTicketPriority {
  String get apiValue {
    switch (this) {
      case SuperadminSupportTicketPriority.low:
        return 'LOW';
      case SuperadminSupportTicketPriority.medium:
        return 'MEDIUM';
      case SuperadminSupportTicketPriority.high:
        return 'HIGH';
    }
  }

  String get label {
    switch (this) {
      case SuperadminSupportTicketPriority.low:
        return 'Low';
      case SuperadminSupportTicketPriority.medium:
        return 'Medium';
      case SuperadminSupportTicketPriority.high:
        return 'High';
    }
  }

  int get sortWeight {
    switch (this) {
      case SuperadminSupportTicketPriority.high:
        return 3;
      case SuperadminSupportTicketPriority.medium:
        return 2;
      case SuperadminSupportTicketPriority.low:
        return 1;
    }
  }
}

class SuperadminSupportAdminMini {
  const SuperadminSupportAdminMini({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
  });

  final int uid;
  final String name;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;

  String get phone {
    final prefix = mobilePrefix.trim();
    final number = mobileNumber.trim();
    if (prefix.isEmpty) {
      return number;
    }
    if (number.isEmpty) {
      return prefix;
    }

    return '$prefix $number';
  }

  String get displayName {
    final normalized = name.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
    if (uid > 0) {
      return 'Admin #$uid';
    }

    return 'Admin';
  }

  factory SuperadminSupportAdminMini.fromJson(dynamic json) {
    final source = _asMap(json);
    final uid = _firstInt(
          source,
          const [
            'uid',
            'id',
            '_id',
            'userId',
            'user_id',
            'adminId',
            'admin_id',
          ],
        ) ??
        0;

    final name = _firstString(
          source,
          const [
            'name',
            'fullName',
            'full_name',
            'displayName',
            'display_name',
            'adminName',
            'admin_name',
          ],
        ) ??
        (uid > 0 ? 'Admin #$uid' : 'Admin');

    return SuperadminSupportAdminMini(
      uid: uid,
      name: name,
      email: _firstString(
            source,
            const [
              'email',
              'mail',
              'primaryEmail',
              'primary_email',
            ],
          ) ??
          '',
      mobilePrefix: _firstString(
            source,
            const [
              'mobilePrefix',
              'mobile_prefix',
              'phonePrefix',
              'phone_prefix',
            ],
          ) ??
          '',
      mobileNumber: _firstString(
            source,
            const [
              'mobileNumber',
              'mobile_number',
              'mobileNo',
              'mobile_no',
              'phoneNumber',
              'phone_number',
              'phoneNo',
              'phone_no',
              'mobile',
              'phone',
            ],
          ) ??
          '',
    );
  }
}

class SuperadminSupportTicketListItem {
  const SuperadminSupportTicketListItem({
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
  });

  final int id;
  final String ticketNo;
  final String title;
  final SuperadminSupportTicketStatus status;
  final SuperadminSupportTicketCategory category;
  final SuperadminSupportTicketPriority priority;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SuperadminSupportAdminMini? fromUser;

  bool get isClosed => status == SuperadminSupportTicketStatus.closed;

  DateTime get sortingDate {
    return lastMessageAt ??
        updatedAt ??
        createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String get displayTicketNo {
    final normalized = ticketNo.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }

    return '#$id';
  }

  String get displayFromName {
    final source = fromUser;
    if (source == null) {
      return 'Admin';
    }

    final name = source.displayName;
    if (name.trim().isNotEmpty) {
      return name;
    }

    if (source.uid > 0) {
      return 'Admin #${source.uid}';
    }

    return 'Admin';
  }

  factory SuperadminSupportTicketListItem.fromJson(dynamic json) {
    final source = _asMap(json);
    final nestedTicket = _firstMap(
          source,
          const ['ticket', 'item', 'record', 'details'],
        ) ??
        const <String, dynamic>{};
    final payload = nestedTicket.isNotEmpty ? nestedTicket : source;

    final id = _firstInt(
          payload,
          const ['id', '_id', 'ticketId', 'ticket_id', 'uid'],
        ) ??
        _firstInt(
          source,
          const ['id', '_id', 'ticketId', 'ticket_id', 'uid'],
        ) ??
        0;

    final fromUserId = _firstInt(
      payload,
      const [
        'fromUserId',
        'from_user_id',
        'userId',
        'user_id',
        'adminUserId',
        'admin_user_id',
        'adminId',
        'admin_id',
      ],
    );

    final fromUserMap = _firstMap(
          payload,
          const [
            'fromUser',
            'from_user',
            'user',
            'admin',
            'adminUser',
            'admin_user',
            'sender',
          ],
        ) ??
        _firstMap(
          source,
          const [
            'fromUser',
            'from_user',
            'user',
            'admin',
            'adminUser',
            'admin_user',
            'sender',
          ],
        );

    final fromUser = _buildAdminMini(
      fromUserMap,
      fallbackUid: fromUserId,
    );

    final ticketNo = _firstString(
          payload,
          const [
            'ticketNo',
            'ticket_no',
            'ticketNumber',
            'ticket_number',
            'ticket',
            'ticketIdLabel',
            'ticket_id_label',
          ],
        ) ??
        '#$id';

    return SuperadminSupportTicketListItem(
      id: id,
      ticketNo: ticketNo,
      title: _firstString(
            payload,
            const [
              'title',
              'subject',
              'issue',
              'name',
            ],
          ) ??
          'Untitled ticket',
      status: _parseTicketStatus(
        _firstValue(
          payload,
          const ['status', 'ticketStatus', 'ticket_status', 'state'],
        ),
      ),
      category: _parseTicketCategory(
        _firstValue(
          payload,
          const [
            'category',
            'ticketCategory',
            'ticket_category',
            'issueCategory',
            'issue_category',
          ],
        ),
      ),
      priority: _parseTicketPriority(
        _firstValue(
          payload,
          const [
            'priority',
            'ticketPriority',
            'ticket_priority',
            'severity',
          ],
        ),
      ),
      lastMessageAt: _firstDate(
            payload,
            const [
              'lastMessageAt',
              'last_message_at',
              'lastActivityAt',
              'last_activity_at',
              'lastReplyAt',
              'last_reply_at',
            ],
          ) ??
          _firstDate(
            source,
            const [
              'lastMessageAt',
              'last_message_at',
              'lastActivityAt',
              'last_activity_at',
              'lastReplyAt',
              'last_reply_at',
            ],
          ),
      createdAt: _firstDate(
            payload,
            const ['createdAt', 'created_at'],
          ) ??
          _firstDate(source, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(
            payload,
            const ['updatedAt', 'updated_at'],
          ) ??
          _firstDate(source, const ['updatedAt', 'updated_at']),
      fromUser: fromUser,
    );
  }

  static int compareInboxOrder(
    SuperadminSupportTicketListItem left,
    SuperadminSupportTicketListItem right,
  ) {
    final byDate = right.sortingDate.compareTo(left.sortingDate);
    if (byDate != 0) {
      return byDate;
    }

    return right.id.compareTo(left.id);
  }
}

class SuperadminSupportAttachment {
  const SuperadminSupportAttachment({
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
    final original = originalName.trim();
    if (original.isNotEmpty) {
      return original;
    }

    final stored = storedName.trim();
    if (stored.isNotEmpty) {
      return stored;
    }

    final path = filePath.trim();
    if (path.isEmpty) {
      return 'Attachment';
    }

    final segments = path.split('/');
    final lastSegment = segments.isEmpty ? path : segments.last.trim();
    return lastSegment.isEmpty ? 'Attachment' : lastSegment;
  }

  factory SuperadminSupportAttachment.fromJson(dynamic json) {
    final source = _asMap(json);
    return SuperadminSupportAttachment(
      id: _firstString(
            source,
            const ['id', '_id', 'uid'],
          ) ??
          '',
      originalName: _firstString(
            source,
            const [
              'originalName',
              'original_name',
              'fileName',
              'file_name',
              'name',
              'filename',
            ],
          ) ??
          '',
      storedName: _firstString(
            source,
            const [
              'storedName',
              'stored_name',
              'storageName',
              'storage_name',
              'key',
            ],
          ) ??
          '',
      filePath: _firstString(
            source,
            const [
              'filePath',
              'file_path',
              'path',
              'url',
              'location',
              'fileUrl',
              'file_url',
            ],
          ) ??
          '',
      mimeType: _firstString(
            source,
            const [
              'mimeType',
              'mime_type',
              'contentType',
              'content_type',
              'type',
            ],
          ) ??
          '',
      sizeBytes: _firstInt(
            source,
            const [
              'sizeBytes',
              'size_bytes',
              'size',
              'fileSize',
              'file_size',
            ],
          ) ??
          0,
      createdAt: _firstDate(
        source,
        const ['createdAt', 'created_at', 'updatedAt', 'updated_at'],
      ),
    );
  }

  static List<SuperadminSupportAttachment> listFromJson(dynamic json) {
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
        .map(SuperadminSupportAttachment.fromJson)
        .where(
          (item) =>
              item.filePath.trim().isNotEmpty ||
              item.displayName.trim().isNotEmpty,
        )
        .toList(growable: false);
  }
}

class SuperadminSupportMessage {
  const SuperadminSupportMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.createdAt,
    required this.sender,
    required this.attachments,
  });

  final int id;
  final String message;
  final String senderId;
  final DateTime? createdAt;
  final SuperadminSupportAdminMini? sender;
  final List<SuperadminSupportAttachment> attachments;

  bool get hasBody => message.trim().isNotEmpty;

  factory SuperadminSupportMessage.fromJson(dynamic json) {
    final source = _asMap(json);
    final senderMap = _firstMap(
          source,
          const ['sender', 'fromUser', 'from_user', 'user', 'admin'],
        ) ??
        const <String, dynamic>{};
    final senderIdValue = _firstValue(
      source,
      const [
        'senderId',
        'sender_id',
        'fromUserId',
        'from_user_id',
        'userId',
        'user_id',
        'adminUserId',
        'admin_user_id',
      ],
    );

    final senderId = _normalizeSenderId(senderIdValue) ??
        _normalizeSenderId(
          _firstValue(
              senderMap, const ['uid', 'id', '_id', 'userId', 'user_id']),
        ) ??
        '';

    return SuperadminSupportMessage(
      id: _firstInt(
            source,
            const ['id', '_id', 'messageId', 'message_id', 'uid'],
          ) ??
          0,
      message: _firstString(
            source,
            const ['message', 'body', 'text', 'content', 'reply'],
          ) ??
          '',
      senderId: senderId,
      createdAt: _firstDate(
        source,
        const ['createdAt', 'created_at', 'sentAt', 'sent_at', 'timestamp'],
      ),
      sender: _buildAdminMini(
        senderMap,
        fallbackUid: _firstInt(
          source,
          const [
            'senderId',
            'sender_id',
            'fromUserId',
            'from_user_id',
            'userId',
            'user_id',
          ],
        ),
      ),
      attachments: SuperadminSupportAttachment.listFromJson(
        _firstValue(
          source,
          const ['attachments', 'files', 'documents', 'docs'],
        ),
      ),
    );
  }

  static List<SuperadminSupportMessage> listFromJson(dynamic json) {
    final entries = _extractList(
      json,
      keys: const [
        'messages',
        'conversation',
        'replies',
        'items',
        'rows',
        'data',
      ],
    );

    final items = entries
        .map(SuperadminSupportMessage.fromJson)
        .where((item) =>
            item.id > 0 || item.hasBody || item.attachments.isNotEmpty)
        .toList(growable: true);

    items.sort((left, right) {
      final leftTime = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightTime =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final byTime = leftTime.compareTo(rightTime);
      if (byTime != 0) {
        return byTime;
      }

      return left.id.compareTo(right.id);
    });

    return items;
  }
}

class SuperadminSupportTicketDetails {
  const SuperadminSupportTicketDetails({
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
    required this.messages,
  });

  final int id;
  final String ticketNo;
  final String title;
  final SuperadminSupportTicketStatus status;
  final SuperadminSupportTicketCategory category;
  final SuperadminSupportTicketPriority priority;
  final int? fromUserId;
  final int? toUserId;
  final int? adminUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final SuperadminSupportAdminMini? fromUser;
  final List<SuperadminSupportMessage> messages;

  String get displayTicketNo {
    final normalized = ticketNo.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }

    return '#$id';
  }

  factory SuperadminSupportTicketDetails.fromJson(dynamic json) {
    final source = _asMap(json);
    final payload = _firstMap(
          source,
          const ['ticket', 'item', 'record', 'details', 'data'],
        ) ??
        source;

    final id = _firstInt(
          payload,
          const ['id', '_id', 'ticketId', 'ticket_id', 'uid'],
        ) ??
        _firstInt(
          source,
          const ['id', '_id', 'ticketId', 'ticket_id', 'uid'],
        ) ??
        0;

    final fromUserId = _firstInt(
      payload,
      const ['fromUserId', 'from_user_id', 'userId', 'user_id'],
    );

    final fromUserMap = _firstMap(
          payload,
          const [
            'fromUser',
            'from_user',
            'user',
            'admin',
            'adminUser',
            'admin_user',
          ],
        ) ??
        _firstMap(
          source,
          const [
            'fromUser',
            'from_user',
            'user',
            'admin',
            'adminUser',
            'admin_user',
          ],
        );

    final fromUser = _buildAdminMini(
      fromUserMap,
      fallbackUid: fromUserId,
    );

    final messages = SuperadminSupportMessage.listFromJson(
      _firstValue(
            payload,
            const ['messages', 'conversation', 'replies'],
          ) ??
          _firstValue(
            source,
            const ['messages', 'conversation', 'replies'],
          ),
    );

    return SuperadminSupportTicketDetails(
      id: id,
      ticketNo: _firstString(
            payload,
            const [
              'ticketNo',
              'ticket_no',
              'ticketNumber',
              'ticket_number',
              'ticket',
              'ticketIdLabel',
            ],
          ) ??
          '#$id',
      title: _firstString(
            payload,
            const ['title', 'subject', 'issue', 'name'],
          ) ??
          'Untitled ticket',
      status: _parseTicketStatus(
        _firstValue(
          payload,
          const ['status', 'ticketStatus', 'ticket_status', 'state'],
        ),
      ),
      category: _parseTicketCategory(
        _firstValue(
          payload,
          const [
            'category',
            'ticketCategory',
            'ticket_category',
            'issueCategory',
          ],
        ),
      ),
      priority: _parseTicketPriority(
        _firstValue(
          payload,
          const ['priority', 'ticketPriority', 'ticket_priority', 'severity'],
        ),
      ),
      fromUserId: fromUserId,
      toUserId: _firstInt(
        payload,
        const ['toUserId', 'to_user_id', 'targetUserId', 'target_user_id'],
      ),
      adminUserId: _firstInt(
        payload,
        const [
          'adminUserId',
          'admin_user_id',
          'assignedAdminId',
          'assigned_admin_id',
        ],
      ),
      createdAt: _firstDate(payload, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(payload, const ['updatedAt', 'updated_at']),
      closedAt: _firstDate(
        payload,
        const ['closedAt', 'closed_at', 'resolvedAt', 'resolved_at'],
      ),
      fromUser: fromUser,
      messages: messages,
    );
  }
}

class SuperadminCreateSupportTicketRequest {
  const SuperadminCreateSupportTicketRequest({
    required this.adminId,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    this.attachments = const <PlatformFile>[],
  });

  final int adminId;
  final String title;
  final String message;
  final SuperadminSupportTicketCategory category;
  final SuperadminSupportTicketPriority priority;
  final List<PlatformFile> attachments;
}

class SuperadminReplySupportTicketRequest {
  const SuperadminReplySupportTicketRequest({
    required this.message,
    this.attachments = const <PlatformFile>[],
  });

  final String message;
  final List<PlatformFile> attachments;
}

class SuperadminSupportTicketCreatedResult {
  const SuperadminSupportTicketCreatedResult({
    required this.ticketId,
    required this.ticketNo,
    required this.message,
  });

  final int ticketId;
  final String ticketNo;
  final String message;

  factory SuperadminSupportTicketCreatedResult.fromJson(dynamic json) {
    final source = _asMap(json);
    final payload = _firstMap(
          source,
          const ['ticket', 'item', 'record', 'data'],
        ) ??
        source;

    final ticketId = _firstInt(
          payload,
          const ['id', '_id', 'ticketId', 'ticket_id', 'uid'],
        ) ??
        _firstInt(
          source,
          const ['id', '_id', 'ticketId', 'ticket_id', 'uid'],
        ) ??
        0;

    return SuperadminSupportTicketCreatedResult(
      ticketId: ticketId,
      ticketNo: _firstString(
            payload,
            const [
              'ticketNo',
              'ticket_no',
              'ticketNumber',
              'ticket_number',
              'ticket',
            ],
          ) ??
          '#$ticketId',
      message: _firstString(
            source,
            const ['message', 'statusMessage', 'status_message'],
          ) ??
          '',
    );
  }
}

class SuperadminSupportMessageSentResult {
  const SuperadminSupportMessageSentResult({
    required this.messageId,
    required this.ticketId,
    required this.message,
  });

  final int messageId;
  final int ticketId;
  final String message;

  factory SuperadminSupportMessageSentResult.fromJson(dynamic json) {
    final source = _asMap(json);
    final payload = _firstMap(
          source,
          const ['message', 'item', 'record', 'data'],
        ) ??
        source;

    return SuperadminSupportMessageSentResult(
      messageId: _firstInt(
            payload,
            const ['id', '_id', 'messageId', 'message_id', 'uid'],
          ) ??
          0,
      ticketId: _firstInt(
            payload,
            const ['ticketId', 'ticket_id'],
          ) ??
          _firstInt(
            source,
            const ['ticketId', 'ticket_id'],
          ) ??
          0,
      message: _firstString(
            payload,
            const ['message', 'body', 'text', 'content'],
          ) ??
          _firstString(
            source,
            const ['message', 'statusMessage', 'status_message'],
          ) ??
          '',
    );
  }
}

List<SuperadminSupportTicketListItem> parseSuperadminSupportTicketList(
  dynamic json,
) {
  final entries = _extractList(
    json,
    keys: const [
      'items',
      'rows',
      'records',
      'tickets',
      'list',
      'data',
    ],
  );

  final items = entries
      .map(SuperadminSupportTicketListItem.fromJson)
      .where((item) => item.id > 0 || item.title.trim().isNotEmpty)
      .toList(growable: true);

  items.sort(SuperadminSupportTicketListItem.compareInboxOrder);
  return items;
}

List<SuperadminSupportAdminMini> parseSuperadminSupportAdminList(dynamic json) {
  final entries = _extractList(
    json,
    keys: const [
      'items',
      'rows',
      'records',
      'admins',
      'users',
      'list',
      'data',
    ],
  );

  final admins = entries
      .map(SuperadminSupportAdminMini.fromJson)
      .where((item) => item.uid > 0 || item.displayName.trim().isNotEmpty)
      .toList(growable: true);

  admins.sort((left, right) {
    final leftName = left.displayName.toLowerCase();
    final rightName = right.displayName.toLowerCase();
    final byName = leftName.compareTo(rightName);
    if (byName != 0) {
      return byName;
    }

    return left.uid.compareTo(right.uid);
  });

  return admins;
}

SuperadminSupportTicketStatus _parseTicketStatus(dynamic value) {
  final normalized = value
      ?.toString()
      .trim()
      .toUpperCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');

  switch (normalized) {
    case 'OPEN':
      return SuperadminSupportTicketStatus.open;
    case 'IN_PROGRESS':
    case 'INPROGRESS':
      return SuperadminSupportTicketStatus.inProgress;
    case 'CLOSED':
    case 'RESOLVED':
    case 'DONE':
      return SuperadminSupportTicketStatus.closed;
    default:
      return SuperadminSupportTicketStatus.open;
  }
}

SuperadminSupportTicketCategory _parseTicketCategory(dynamic value) {
  final normalized = value
      ?.toString()
      .trim()
      .toUpperCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');

  switch (normalized) {
    case 'SERVER':
      return SuperadminSupportTicketCategory.server;
    case 'NOTIFICATIONS':
      return SuperadminSupportTicketCategory.notifications;
    case 'MAPS':
      return SuperadminSupportTicketCategory.maps;
    case 'BILLING':
      return SuperadminSupportTicketCategory.billing;
    case 'INSTALLATION':
      return SuperadminSupportTicketCategory.installation;
    case 'OTHER':
      return SuperadminSupportTicketCategory.other;
    default:
      return SuperadminSupportTicketCategory.other;
  }
}

SuperadminSupportTicketPriority _parseTicketPriority(dynamic value) {
  final normalized = value
      ?.toString()
      .trim()
      .toUpperCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');

  switch (normalized) {
    case 'LOW':
      return SuperadminSupportTicketPriority.low;
    case 'MEDIUM':
      return SuperadminSupportTicketPriority.medium;
    case 'HIGH':
      return SuperadminSupportTicketPriority.high;
    default:
      return SuperadminSupportTicketPriority.medium;
  }
}

SuperadminSupportAdminMini? _buildAdminMini(
  Map<String, dynamic>? source, {
  int? fallbackUid,
}) {
  final map = source ?? const <String, dynamic>{};
  if (map.isEmpty && fallbackUid == null) {
    return null;
  }

  final uid = _firstInt(
        map,
        const [
          'uid',
          'id',
          '_id',
          'userId',
          'user_id',
          'adminId',
          'admin_id',
        ],
      ) ??
      fallbackUid ??
      0;

  final model = SuperadminSupportAdminMini.fromJson(
    map.isEmpty
        ? <String, dynamic>{'uid': uid}
        : <String, dynamic>{
            ...map,
            if (!map.containsKey('uid')) 'uid': uid,
          },
  );

  final normalizedName = model.name.trim();
  if (normalizedName.isEmpty && uid > 0) {
    return SuperadminSupportAdminMini(
      uid: uid,
      name: 'Admin #$uid',
      email: model.email,
      mobilePrefix: model.mobilePrefix,
      mobileNumber: model.mobileNumber,
    );
  }

  return model;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  return const <String, dynamic>{};
}

dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (source.containsKey(key) && source[key] != null) {
      return source[key];
    }
  }

  return null;
}

String? _firstString(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return normalized;
}

int? _firstInt(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  return _asInt(value);
}

DateTime? _firstDate(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  return _asDateTime(value);
}

Map<String, dynamic>? _firstMap(
    Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final nested = _asMap(source[key]);
    if (nested.isNotEmpty) {
      return nested;
    }
  }

  return null;
}

List<dynamic> _extractList(
  dynamic source, {
  required List<String> keys,
  int depth = 0,
}) {
  if (source is List) {
    return source;
  }

  if (depth > 5) {
    return const <dynamic>[];
  }

  final map = _asMap(source);
  if (map.isEmpty) {
    return const <dynamic>[];
  }

  for (final key in keys) {
    final value = map[key];
    if (value is List) {
      return value;
    }
  }

  final nestedCandidates = <dynamic>[
    map['data'],
    map['items'],
    map['rows'],
    map['records'],
    map['result'],
    map['results'],
    map['payload'],
    map['response'],
  ];

  for (final nested in nestedCandidates) {
    final resolved = _extractList(nested, keys: keys, depth: depth + 1);
    if (resolved.isNotEmpty) {
      return resolved;
    }
  }

  return const <dynamic>[];
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString().trim() ?? '');
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  if (value is int) {
    if (value <= 0) {
      return null;
    }

    if (value > 9999999999) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }

    return DateTime.fromMillisecondsSinceEpoch(
      value * 1000,
      isUtc: true,
    );
  }

  if (value is num) {
    return _asDateTime(value.toInt());
  }

  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(raw);
  if (parsed != null) {
    return parsed;
  }

  final asInt = int.tryParse(raw);
  if (asInt != null) {
    return _asDateTime(asInt);
  }

  return null;
}

String? _normalizeSenderId(dynamic value) {
  if (value == null) {
    return null;
  }

  final normalized = value.toString().trim();
  if (normalized.isEmpty) {
    return null;
  }

  return normalized;
}
