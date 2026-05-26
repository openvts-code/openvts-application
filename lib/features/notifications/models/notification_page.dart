import 'app_notification.dart';

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.hasMore,
    this.nextBeforeId,
    this.unreadCount,
  });

  final List<AppNotification> items;
  final bool hasMore;
  final int? nextBeforeId;
  final int? unreadCount;

  factory NotificationPage.fromDynamic(
    dynamic json, {
    required int requestedLimit,
  }) {
    final root = _asMap(json);
    final rawItems = _extractItems(json);
    final items = rawItems
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList(growable: false);
    final explicitHasMore = _extractBool(root, const [
      'hasMore',
      'has_more',
    ]);
    final hasMore = explicitHasMore ??
        (requestedLimit > 0 && items.length >= requestedLimit);

    return NotificationPage(
      items: items,
      hasMore: hasMore,
      nextBeforeId: _extractInt(root, const [
            'nextBeforeId',
            'next_before_id',
            'nextCursor',
            'next_cursor',
            'cursor',
          ]) ??
          (hasMore && items.isNotEmpty ? items.last.id : null),
      unreadCount: _extractInt(root, const [
        'unreadCount',
        'unread_count',
        'totalUnread',
        'total_unread',
        'notificationsUnread',
        'notifications_unread',
      ]),
    );
  }
}

List<dynamic> _extractItems(dynamic source) {
  if (source is List) {
    return source;
  }

  final map = _asMap(source);
  if (map == null) {
    return const <dynamic>[];
  }

  for (final key in const [
    'notifications',
    'items',
    'rows',
    'results',
    'list',
    'entries',
    'data',
  ]) {
    final candidate = map[key];
    if (candidate is List) {
      return candidate;
    }

    final nested = _extractItems(candidate);
    if (nested.isNotEmpty) {
      return nested;
    }
  }

  return const <dynamic>[];
}

int? _extractInt(Map<String, dynamic>? root, List<String> keys) {
  if (root == null) {
    return null;
  }

  for (final key in keys) {
    final value = root[key];
    final normalized = _asInt(value);
    if (normalized != null) {
      return normalized;
    }
  }

  for (final nestedKey in const [
    'summary',
    'counts',
    'meta',
    'pagination',
    'stats',
    'totals',
  ]) {
    final nested = _extractInt(_asMap(root[nestedKey]), keys);
    if (nested != null) {
      return nested;
    }
  }

  return null;
}

bool? _extractBool(Map<String, dynamic>? root, List<String> keys) {
  if (root == null) {
    return null;
  }

  for (final key in keys) {
    final normalized = _asBool(root[key]);
    if (normalized != null) {
      return normalized;
    }
  }

  for (final nestedKey in const ['meta', 'pagination']) {
    final nested = _extractBool(_asMap(root[nestedKey]), keys);
    if (nested != null) {
      return nested;
    }
  }

  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, innerValue) => MapEntry(key.toString(), innerValue),
    );
  }

  return null;
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '');
}

bool? _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  switch (normalized) {
    case '1':
    case 'true':
    case 'yes':
      return true;
    case '0':
    case 'false':
    case 'no':
      return false;
    default:
      return null;
  }
}
