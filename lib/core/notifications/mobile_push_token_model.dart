import 'mobile_push_platform.dart';

class RegisterPushTokenRequest {
  const RegisterPushTokenRequest({
    required this.token,
    required this.platform,
    this.deviceId,
    this.userAgent,
  });

  final String token;
  final MobilePushPlatform platform;
  final String? deviceId;
  final String? userAgent;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token.trim(),
      'platform': platform.apiValue,
      'deviceId': _emptyToNull(deviceId),
      'userAgent': _emptyToNull(userAgent),
    };
  }
}

class RemovePushTokenRequest {
  const RemovePushTokenRequest({
    this.token,
    this.deviceId,
  });

  final String? token;
  final String? deviceId;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    final normalizedToken = _emptyToNull(token);
    final normalizedDeviceId = _emptyToNull(deviceId);

    if (normalizedToken != null) {
      data['token'] = normalizedToken;
    }
    if (normalizedDeviceId != null) {
      data['deviceId'] = normalizedDeviceId;
    }

    return data;
  }
}

class MobilePushTokenDiagnostics {
  const MobilePushTokenDiagnostics({
    required this.activeCount,
    required this.currentTokenRegistered,
    required this.platform,
    required this.tokenLast10List,
    this.updatedAt,
  });

  final int activeCount;
  final bool currentTokenRegistered;
  final MobilePushPlatform platform;
  final List<String> tokenLast10List;
  final DateTime? updatedAt;

  factory MobilePushTokenDiagnostics.empty({
    required MobilePushPlatform platform,
  }) {
    return MobilePushTokenDiagnostics(
      activeCount: 0,
      currentTokenRegistered: false,
      platform: platform,
      tokenLast10List: const <String>[],
    );
  }

  factory MobilePushTokenDiagnostics.fromDynamic(
    dynamic source, {
    required MobilePushPlatform platform,
    String? currentRegisteredTokenLast10,
  }) {
    final payload = _extractDiagnosticsPayload(source);
    final tokenItems = _extractTokenItems(payload);
    final tokenLast10List = _extractTokenLast10List(tokenItems);
    final activeCount = _readActiveCount(payload) ??
        _countActiveTokenItems(tokenItems) ??
        tokenLast10List.length;
    final currentLast10 = _last10(currentRegisteredTokenLast10);
    final explicitlyVerified = _readBool(
      payload,
      const <String>[
        'currentTokenRegistered',
        'current_token_registered',
        'currentTokenVerified',
        'current_token_verified',
      ],
    );
    final currentTokenRegistered = explicitlyVerified == true ||
        (currentLast10 != null && tokenLast10List.contains(currentLast10));

    return MobilePushTokenDiagnostics(
      activeCount: activeCount < 0 ? 0 : activeCount,
      currentTokenRegistered: currentTokenRegistered,
      platform: platform,
      tokenLast10List: tokenLast10List,
      updatedAt: _readUpdatedAt(payload) ?? _latestTokenUpdatedAt(tokenItems),
    );
  }
}

String? _emptyToNull(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return normalized;
}

dynamic _extractDiagnosticsPayload(dynamic source) {
  if (source is List) {
    return source;
  }

  final root = _asMap(source);
  if (root.isEmpty) {
    return source;
  }

  if (_hasAnyKey(root, const <String>[
    'tokens',
    'pushTokens',
    'items',
    'results',
    'counts',
    'activeCount',
    'active_count',
  ])) {
    return root;
  }

  for (final key in const <String>['data', 'payload', 'result', 'response']) {
    final nested = root[key];
    if (nested == null || identical(nested, source)) {
      continue;
    }

    final extracted = _extractDiagnosticsPayload(nested);
    if (_hasDiagnosticsPayload(extracted)) {
      return extracted;
    }
  }

  return root;
}

bool _hasDiagnosticsPayload(dynamic source) {
  if (source is List) {
    return true;
  }

  final map = _asMap(source);
  return map.isNotEmpty;
}

List<dynamic> _extractTokenItems(dynamic source) {
  if (source is List) {
    return source;
  }

  final root = _asMap(source);
  if (root.isEmpty) {
    return const <dynamic>[];
  }

  for (final key in const <String>[
    'tokens',
    'pushTokens',
    'push_tokens',
    'items',
    'results',
    'devices',
  ]) {
    final value = root[key];
    if (value is List) {
      return value;
    }
  }

  final nestedData = root['data'];
  if (nestedData is List) {
    return nestedData;
  }

  if (_looksLikeTokenItem(root)) {
    return <dynamic>[root];
  }

  return const <dynamic>[];
}

List<String> _extractTokenLast10List(List<dynamic> items) {
  final values = <String>[];
  for (final item in items) {
    final last10 = _extractTokenLast10(item);
    if (last10 == null || values.contains(last10)) {
      continue;
    }

    values.add(last10);
  }

  return List<String>.unmodifiable(values);
}

String? _extractTokenLast10(dynamic item) {
  if (item is String) {
    return _last10(item);
  }

  final map = _asMap(item);
  if (map.isEmpty) {
    return null;
  }

  for (final key in const <String>[
    'tokenLast10',
    'token_last_10',
    'last10',
    'last_10',
    'tokenSuffix',
    'token_suffix',
    'fcmTokenLast10',
    'registeredTokenLast10',
  ]) {
    final last10 = _last10(map[key]);
    if (last10 != null) {
      return last10;
    }
  }

  for (final key in const <String>[
    'token',
    'fcmToken',
    'fcm_token',
    'pushToken',
    'push_token',
    'deviceToken',
    'device_token',
    'value',
  ]) {
    final last10 = _last10(map[key]);
    if (last10 != null) {
      return last10;
    }
  }

  return null;
}

int? _readActiveCount(dynamic source) {
  final root = _asMap(source);
  if (root.isEmpty) {
    return null;
  }

  for (final key in const <String>[
    'activeCount',
    'active_count',
    'registeredTokenCount',
    'registered_token_count',
    'totalActive',
    'total_active',
  ]) {
    final count = _asInt(root[key]);
    if (count != null) {
      return count;
    }
  }

  final counts = _asMap(root['counts']);
  for (final key in const <String>[
    'active',
    'activeCount',
    'active_count',
    'total',
    'count',
  ]) {
    final count = _asInt(counts[key]);
    if (count != null) {
      return count;
    }
  }

  return null;
}

int? _countActiveTokenItems(List<dynamic> items) {
  if (items.isEmpty) {
    return null;
  }

  var count = 0;
  for (final item in items) {
    if (_isActiveTokenItem(item)) {
      count += 1;
    }
  }

  return count;
}

bool _isActiveTokenItem(dynamic item) {
  if (item is String) {
    return item.trim().isNotEmpty;
  }

  final map = _asMap(item);
  if (map.isEmpty) {
    return false;
  }

  for (final key in const <String>['active', 'isActive', 'enabled']) {
    final active = _readBool(map, <String>[key]);
    if (active != null) {
      return active;
    }
  }

  final status = map['status']?.toString().trim().toLowerCase();
  if (status == 'inactive' ||
      status == 'disabled' ||
      status == 'revoked' ||
      status == 'deleted') {
    return false;
  }

  for (final key in const <String>['deletedAt', 'deleted_at', 'revokedAt']) {
    final value = map[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return false;
    }
  }

  return _extractTokenLast10(map) != null;
}

DateTime? _readUpdatedAt(dynamic source) {
  final root = _asMap(source);
  if (root.isEmpty) {
    return null;
  }

  for (final key in const <String>[
    'updatedAt',
    'updated_at',
    'lastUpdatedAt',
    'last_updated_at',
    'checkedAt',
    'checked_at',
  ]) {
    final value = _asDateTime(root[key]);
    if (value != null) {
      return value;
    }
  }

  return null;
}

DateTime? _latestTokenUpdatedAt(List<dynamic> items) {
  DateTime? latest;
  for (final item in items) {
    final updatedAt = _readUpdatedAt(item);
    if (updatedAt == null) {
      continue;
    }

    if (latest == null || updatedAt.isAfter(latest)) {
      latest = updatedAt;
    }
  }

  return latest;
}

bool _looksLikeTokenItem(Map<String, dynamic> map) {
  return _hasAnyKey(map, const <String>[
    'token',
    'fcmToken',
    'fcm_token',
    'pushToken',
    'push_token',
    'tokenLast10',
    'last10',
  ]);
}

bool _hasAnyKey(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map.containsKey(key)) {
      return true;
    }
  }

  return false;
}

bool? _readBool(dynamic source, List<String> keys) {
  final map = _asMap(source);
  for (final key in keys) {
    final value = map[key];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      continue;
    }
    if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == 'no' || normalized == '0') {
      return false;
    }
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

  return int.tryParse(value?.toString().trim() ?? '');
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is num) {
    final timestamp = value.toInt();
    if (timestamp <= 0) {
      return null;
    }
    final isMilliseconds = timestamp > 9999999999;
    return DateTime.fromMillisecondsSinceEpoch(
      isMilliseconds ? timestamp : timestamp * 1000,
    );
  }

  return DateTime.tryParse(value.toString().trim());
}

String? _last10(dynamic value) {
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized.length <= 10) {
    return normalized;
  }

  return normalized.substring(normalized.length - 10);
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
