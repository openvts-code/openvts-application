class UserShareTrackVehicle {
  const UserShareTrackVehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.isLicenseBlocked,
  });

  final String id;
  final String name;
  final String? plateNumber;
  final bool isLicenseBlocked;

  bool get isSelectable => !isLicenseBlocked;

  String get displayName {
    final plate = plateNumber?.trim();
    if (plate == null || plate.isEmpty) return name;
    return '$name ($plate)';
  }

  factory UserShareTrackVehicle.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['vehicle', 'details', 'item', 'record'],
    );

    return UserShareTrackVehicle(
      id: _firstString(source, const ['id', '_id', 'vehicleId']) ?? '',
      name: _firstString(source, const [
            'name',
            'vehicleName',
            'displayName',
            'label',
          ]) ??
          'Vehicle',
      plateNumber: _firstString(source, const [
        'plateNumber',
        'plate_number',
        'numberPlate',
        'registrationNumber',
        'vehicleNo',
      ]),
      isLicenseBlocked: _parseBool(_firstValue(source, const [
            'isLicenseBlocked',
            'is_license_blocked',
            'licenseBlocked',
            'license_blocked',
          ])) ??
          false,
    );
  }

  static List<UserShareTrackVehicle> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'vehicles',
      'items',
      'rows',
      'records',
      'data',
    ])
        .map(UserShareTrackVehicle.fromJson)
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class UserShareTrackLink {
  const UserShareTrackLink({
    required this.id,
    required this.uniqueCode,
    required this.expiryAt,
    required this.isActive,
    required this.isGeofence,
    required this.isHistory,
    required this.vehicles,
    required this.vehiclesCount,
    required this.finalUrl,
    required this.createdAt,
  });

  final String id;
  final String uniqueCode;
  final DateTime? expiryAt;
  final bool isActive;
  final bool isGeofence;
  final bool isHistory;
  final List<UserShareTrackVehicle> vehicles;
  final int? vehiclesCount;
  final String? finalUrl;
  final DateTime? createdAt;

  bool get isExpired {
    final expiry = expiryAt;
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  int get vehicleCount => vehiclesCount ?? vehicles.length;

  String get endpointId {
    final normalizedId = id.trim();
    final normalizedCode = uniqueCode.trim();
    return normalizedId.isNotEmpty ? normalizedId : normalizedCode;
  }

  String get statusLabel {
    return isActive ? 'Active' : 'Inactive';
  }

  factory UserShareTrackLink.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['data', 'shareTrackLink', 'link', 'item'],
    );
    final vehicles = UserShareTrackVehicle.listFromJson(source['vehicles']);

    return UserShareTrackLink(
      id: _firstString(source, const [
            '_id',
            'uuid',
            'shareTrackLinkUuid',
            'share_track_link_uuid',
            'shareTrackLinkId',
            'share_track_link_id',
            'sharetracklinkId',
            'sharetracklink_id',
            'trackLinkId',
            'track_link_id',
            'linkId',
            'link_id',
            'shareLinkId',
            'share_link_id',
            'id',
          ]) ??
          '',
      uniqueCode: _firstString(source, const [
            'uniqueCode',
            'unique_code',
            'code',
          ]) ??
          '',
      expiryAt: _firstDate(source, const ['expiryAt', 'expiry_at', 'expiry']),
      isActive: _parseBool(_firstValue(source, const [
            'isActive',
            'is_active',
            'active',
            'status',
          ])) ??
          true,
      isGeofence: _parseBool(_firstValue(source, const [
            'isGeofence',
            'is_geofence',
            'geofence',
          ])) ??
          false,
      isHistory: _parseBool(_firstValue(source, const [
            'isHistory',
            'is_history',
            'history',
          ])) ??
          false,
      vehicles: vehicles,
      vehiclesCount: _firstInt(source, const [
        'vehiclesCount',
        'vehicles_count',
        'vehicleCount',
        'vehicle_count',
      ]),
      finalUrl: _firstString(source, const ['finalUrl', 'final_url', 'url']),
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
    );
  }
}

String resolveShareTrackPublicUrl({
  required UserShareTrackLink link,
  required String apiBaseUrl,
}) {
  final finalUrl = link.finalUrl?.trim();
  if (finalUrl != null && finalUrl.isNotEmpty) {
    return _resolveShareTrackPath(finalUrl, apiBaseUrl);
  }

  final uniqueCode = link.uniqueCode.trim();
  if (uniqueCode.isEmpty) return '';

  final publicBaseUrl = _shareTrackPublicBaseUrl(apiBaseUrl);
  if (publicBaseUrl.isEmpty) return '/track/${Uri.encodeComponent(uniqueCode)}';

  return '$publicBaseUrl/track/${Uri.encodeComponent(uniqueCode)}';
}

String _resolveShareTrackPath(String rawUrl, String apiBaseUrl) {
  final parsedUrl = Uri.tryParse(rawUrl);
  if (parsedUrl != null && parsedUrl.hasScheme) return rawUrl;

  final publicBaseUrl = _shareTrackPublicBaseUrl(apiBaseUrl);
  if (publicBaseUrl.isEmpty) return rawUrl;

  final normalizedPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
  return '$publicBaseUrl$normalizedPath';
}

String _shareTrackPublicBaseUrl(String apiBaseUrl) {
  final normalizedApiBaseUrl = apiBaseUrl.trim().replaceAll(
        RegExp(r'/+$'),
        '',
      );
  if (normalizedApiBaseUrl.isEmpty) return '';

  return normalizedApiBaseUrl.replaceFirst(
    RegExp(r'/api$', caseSensitive: false),
    '',
  );
}

class UserShareTrackLinksPage {
  const UserShareTrackLinksPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final List<UserShareTrackLink> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  factory UserShareTrackLinksPage.fromJson(
    dynamic json, {
    int defaultPage = 1,
    int defaultLimit = 50,
  }) {
    final rawItems = _extractList(json, preferredKeys: const [
      'items',
      'shareTrackLinks',
      'links',
      'rows',
      'records',
      'data',
    ]);
    final items = rawItems
        .map(UserShareTrackLink.fromJson)
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);
    final source = json is List
        ? const <String, dynamic>{}
        : _extractMapPayload(json, preferredKeys: const ['data']);
    final page = _firstInt(source, const ['page', 'currentPage']) ??
        (defaultPage < 1 ? 1 : defaultPage);
    final limit = _firstInt(source, const ['limit', 'pageSize', 'perPage']) ??
        (defaultLimit < 1 ? 50 : defaultLimit);
    final total = _firstInt(source, const ['total', 'count', 'totalCount']) ??
        items.length;
    final explicitHasMore = _parseBool(_firstValue(source, const [
      'hasMore',
      'has_more',
      'hasNext',
      'has_next',
    ]));

    return UserShareTrackLinksPage(
      items: items,
      page: page,
      limit: limit,
      total: total,
      hasMore: explicitHasMore ?? (limit > 0 && page * limit < total),
    );
  }
}

class UserCreateShareTrackLinkRequest {
  const UserCreateShareTrackLinkRequest({
    required this.vehicleIds,
    required this.expiryAt,
    this.isGeofence = false,
    this.isHistory = false,
  });

  final List<int> vehicleIds;
  final DateTime expiryAt;
  final bool isGeofence;
  final bool isHistory;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'vehicleIds': vehicleIds,
      'expiryAt': expiryAt.toUtc().toIso8601String(),
      'isGeofence': isGeofence,
      'isHistory': isHistory,
    };
  }
}

class UserUpdateShareTrackLinkRequest {
  const UserUpdateShareTrackLinkRequest({
    this.vehicleIds,
    this.expiryAt,
    this.isGeofence,
    this.isHistory,
    this.isActive,
  });

  final List<int>? vehicleIds;
  final DateTime? expiryAt;
  final bool? isGeofence;
  final bool? isHistory;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (vehicleIds != null) 'vehicleIds': vehicleIds,
      if (expiryAt != null) 'expiryAt': expiryAt!.toUtc().toIso8601String(),
      if (isGeofence != null) 'isGeofence': isGeofence,
      if (isHistory != null) 'isHistory': isHistory,
      if (isActive != null) 'isActive': isActive,
    };
  }
}

class UserShareTrackLinkFormData {
  const UserShareTrackLinkFormData({
    this.selectedVehicleIds = const <String>[],
    this.expiryAt,
    this.isGeofence = false,
    this.isHistory = false,
    this.isActive = true,
  });

  final List<String> selectedVehicleIds;
  final DateTime? expiryAt;
  final bool isGeofence;
  final bool isHistory;
  final bool isActive;

  UserShareTrackLinkFormData copyWith({
    List<String>? selectedVehicleIds,
    Object? expiryAt = _unset,
    bool? isGeofence,
    bool? isHistory,
    bool? isActive,
  }) {
    return UserShareTrackLinkFormData(
      selectedVehicleIds: selectedVehicleIds ?? this.selectedVehicleIds,
      expiryAt:
          identical(expiryAt, _unset) ? this.expiryAt : expiryAt as DateTime?,
      isGeofence: isGeofence ?? this.isGeofence,
      isHistory: isHistory ?? this.isHistory,
      isActive: isActive ?? this.isActive,
    );
  }
}

Map<String, dynamic> _extractMapPayload(
  dynamic json, {
  List<String> preferredKeys = const ['data', 'result', 'payload', 'response'],
}) {
  final root = _asMap(json);
  if (root.isEmpty) return const <String, dynamic>{};

  for (final key in preferredKeys) {
    final value = _valueForKey(root, key);
    final map = _asMap(value);
    if (map.isNotEmpty) return map;
  }

  for (final key in const ['data', 'result', 'payload', 'response']) {
    final nested = _valueForKey(root, key);
    if (nested == null || identical(nested, json)) continue;
    final map = _extractMapPayload(nested, preferredKeys: preferredKeys);
    if (map.isNotEmpty) return map;
  }

  return root;
}

List<dynamic> _extractList(
  dynamic json, {
  List<String> preferredKeys = const [
    'items',
    'rows',
    'records',
    'list',
    'data',
  ],
}) {
  if (json is List) return json;

  final root = _asMap(json);
  if (root.isEmpty) return const <dynamic>[];

  for (final key in preferredKeys) {
    final value = _valueForKey(root, key);
    if (value is List) return value;
  }

  for (final key in const ['data', 'result', 'payload', 'response']) {
    final nested = _valueForKey(root, key);
    if (nested == null || identical(nested, json)) continue;
    final list = _extractList(nested, preferredKeys: preferredKeys);
    if (list.isNotEmpty) return list;
  }

  return const <dynamic>[];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

dynamic _valueForKey(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  final normalizedKey = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == normalizedKey) return entry.value;
  }
  return null;
}

dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    if (value != null) return value;
  }
  return null;
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final parsed = _parseString(_valueForKey(json, key));
    if (parsed != null) return parsed;
  }
  return null;
}

String? _parseString(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'null') return null;
    return normalized;
  }
  if (value is num || value is bool) return value.toString();
  return null;
}

bool? _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (const {'true', '1', 'yes', 'y', 'active', 'enabled'}
        .contains(normalized)) {
      return true;
    }
    if (const {'false', '0', 'no', 'n', 'inactive', 'disabled'}
        .contains(normalized)) {
      return false;
    }
  }
  return null;
}

int? _firstInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final parsed = _parseInt(_valueForKey(json, key));
    if (parsed != null) return parsed;
  }
  return null;
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

DateTime? _firstDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final parsed = _parseDate(_valueForKey(json, key));
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is num) {
    final millis = value > 1000000000000 ? value.toInt() : value.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
  }
  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == '-') return null;
    final numeric = num.tryParse(normalized);
    if (numeric != null) return _parseDate(numeric);
    return DateTime.tryParse(normalized);
  }
  return null;
}

const Object _unset = Object();
