class UserSubUser {
  const UserSubUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.isActive,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final bool isActive;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get searchContent {
    return <String>[
      id,
      name,
      username,
      email,
      mobilePrefix,
      mobileNumber,
      status,
    ].join(' ').toLowerCase();
  }

  UserSubUser copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? mobilePrefix,
    String? mobileNumber,
    bool? isActive,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSubUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      mobilePrefix: mobilePrefix ?? this.mobilePrefix,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserSubUser.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['subuser', 'subUser', 'item', 'record', 'data'],
    );

    final activeFromStatus =
        _parseBool(_firstValue(source, const ['status', 'state']));

    final isActive = _parseBool(_firstValue(source, const [
          'isActive',
          'is_active',
          'active',
          'status',
        ])) ??
        activeFromStatus ??
        true;

    return UserSubUser(
      id: _firstString(source, const ['uid', 'id', '_id', 'userId']) ?? '',
      name:
          _firstString(source, const ['name', 'fullName', 'displayName']) ?? '',
      username: _firstString(source, const ['username', 'userName']) ?? '',
      email: _firstString(source, const ['email']) ?? '',
      mobilePrefix: _firstString(source, const [
            'mobilePrefix',
            'mobile_prefix',
          ]) ??
          '',
      mobileNumber: _firstString(source, const [
            'mobileNumber',
            'mobile_number',
            'mobile',
            'phone',
            'phoneNumber',
          ]) ??
          '',
      isActive: isActive,
      status: _firstString(source, const ['status']) ??
          (isActive ? 'active' : 'inactive'),
      createdAt: _firstDate(source, const [
        'createdAt',
        'created_at',
      ]),
      updatedAt: _firstDate(source, const [
        'updatedAt',
        'updated_at',
      ]),
    );
  }

  static List<UserSubUser> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'items',
      'subusers',
      'subUsers',
      'data',
    ]).map(UserSubUser.fromJson).where((item) {
      return item.id.trim().isNotEmpty;
    }).toList(growable: false);
  }
}

class UserSubUsersPage {
  const UserSubUsersPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<UserSubUser> items;
  final int page;
  final int limit;
  final int total;

  factory UserSubUsersPage.fromJson(
    dynamic json, {
    int defaultPage = 1,
    int defaultLimit = 100,
  }) {
    if (json is List) {
      final items = json.map(UserSubUser.fromJson).toList(growable: false);
      return UserSubUsersPage(
        items: items,
        page: defaultPage,
        limit: defaultLimit,
        total: items.length,
      );
    }

    final root = _asMap(json);
    final payload = _extractMapPayload(json);

    var sourceItems = _extractList(payload, preferredKeys: const [
      'items',
      'subusers',
      'subUsers',
      'data',
    ]);

    if (sourceItems.isEmpty) {
      sourceItems = _extractList(root, preferredKeys: const [
        'items',
        'subusers',
        'subUsers',
        'data',
      ]);
    }

    final items = sourceItems
        .map(UserSubUser.fromJson)
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);

    final page = _firstInt(payload, const [
          'page',
          'currentPage',
          'current_page',
        ]) ??
        _firstInt(root, const ['page', 'currentPage', 'current_page']) ??
        defaultPage;

    final limit = _firstInt(payload, const [
          'limit',
          'pageSize',
          'perPage',
        ]) ??
        _firstInt(root, const ['limit', 'pageSize', 'perPage']) ??
        defaultLimit;

    final total = _firstInt(payload, const [
          'total',
          'totalCount',
          'count',
        ]) ??
        _firstInt(root, const ['total', 'totalCount', 'count']) ??
        items.length;

    return UserSubUsersPage(
      items: items,
      page: page <= 0 ? defaultPage : page,
      limit: limit <= 0 ? defaultLimit : limit,
      total: total < items.length ? items.length : total,
    );
  }
}

class CreateUserSubUserRequest {
  const CreateUserSubUserRequest({
    required this.name,
    this.username,
    this.email,
    this.mobilePrefix,
    this.mobileNumber,
    this.password,
    this.isActive = true,
  });

  final String name;
  final String? username;
  final String? email;
  final String? mobilePrefix;
  final String? mobileNumber;
  final String? password;
  final bool isActive;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'name': _requiredString(name, 'name'),
      'isActive': isActive,
    };

    _putIfNotNull(payload, 'username', _optionalString(username));
    _putIfNotNull(payload, 'email', _optionalString(email));
    _putIfNotNull(payload, 'mobilePrefix', _optionalString(mobilePrefix));
    _putIfNotNull(payload, 'mobileNumber', _optionalString(mobileNumber));
    _putIfNotNull(payload, 'password', _optionalString(password));

    return payload;
  }
}

class UpdateUserSubUserRequest {
  const UpdateUserSubUserRequest({
    this.name,
    this.username,
    this.email,
    this.mobilePrefix,
    this.mobileNumber,
    this.password,
    this.isActive,
  });

  final String? name;
  final String? username;
  final String? email;
  final String? mobilePrefix;
  final String? mobileNumber;
  final String? password;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};

    _putIfNotNull(payload, 'name', _optionalString(name));
    _putIfNotNull(payload, 'username', _optionalString(username));
    _putIfNotNull(payload, 'email', _optionalString(email));
    _putIfNotNull(payload, 'mobilePrefix', _optionalString(mobilePrefix));
    _putIfNotNull(payload, 'mobileNumber', _optionalString(mobileNumber));
    _putIfNotNull(payload, 'password', _optionalString(password));

    if (isActive != null) {
      payload['isActive'] = isActive;
    }

    return payload;
  }
}

class UserSubUserVehicle {
  const UserSubUserVehicle({
    required this.id,
    required this.name,
    required this.vin,
    required this.plateNumber,
    required this.imei,
    required this.simNumber,
    required this.createdAt,
    required this.isBlocked,
    required this.licenseStatus,
  });

  final String id;
  final String name;
  final String vin;
  final String plateNumber;
  final String imei;
  final String simNumber;
  final DateTime? createdAt;
  final bool? isBlocked;
  final String? licenseStatus;

  String get searchContent {
    return <String>[
      id,
      name,
      vin,
      plateNumber,
      imei,
      simNumber,
    ].join(' ').toLowerCase();
  }

  factory UserSubUserVehicle.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['vehicle', 'item', 'record', 'data'],
    );

    final device =
        _firstMap(source, const ['device', 'deviceDetails', 'gpsDevice']) ??
            const <String, dynamic>{};
    final sim = _firstMap(device, const ['sim', 'simCard']) ??
        const <String, dynamic>{};

    return UserSubUserVehicle(
      id: _firstString(source, const ['id', 'uid', '_id', 'vehicleId']) ?? '',
      name: _firstString(source, const ['name', 'vehicleName']) ?? '',
      vin: _firstString(source, const ['vin', 'VIN', 'chassisNo']) ?? '',
      plateNumber: _firstString(source, const [
            'plateNumber',
            'plate_number',
            'numberPlate',
            'registrationNumber',
            'vehicleNo',
          ]) ??
          '',
      imei: _firstString(source, const ['imei', 'IMEI']) ??
          _firstString(device, const ['imei', 'IMEI']) ??
          '',
      simNumber: _firstString(source, const ['simNumber', 'sim_number']) ??
          _firstString(device, const ['simNumber', 'sim_number']) ??
          _firstString(sim, const ['simNumber', 'sim_number']) ??
          '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      isBlocked: _parseBool(_firstValue(source, const [
        'isBlocked',
        'blocked',
        'is_blocked',
      ])),
      licenseStatus: _firstString(source, const [
        'licenseStatus',
        'licenceStatus',
        'license_status',
        'licence_status',
      ]),
    );
  }

  static List<UserSubUserVehicle> listFromJson(dynamic json) {
    final source = _extractVehicleList(json);
    return source
        .map(UserSubUserVehicle.fromJson)
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class UserSubUserVehicleAssignmentPayload {
  const UserSubUserVehicleAssignmentPayload({required this.vehicleIds});

  final List<String> vehicleIds;

  List<int> get normalizedVehicleIds {
    final ordered = <int>[];
    final seen = <int>{};

    for (final value in vehicleIds) {
      final parsed = int.tryParse(value.trim());
      if (parsed == null || parsed <= 0 || seen.contains(parsed)) {
        continue;
      }
      seen.add(parsed);
      ordered.add(parsed);
    }

    return ordered;
  }

  Map<String, dynamic> toJson() {
    final ids = normalizedVehicleIds;
    if (ids.isEmpty) {
      throw ArgumentError('vehicleIds must contain at least one valid id.');
    }

    return <String, dynamic>{'vehicleIds': ids};
  }
}

List<dynamic> _extractVehicleList(dynamic json) {
  if (json is List) {
    return json;
  }

  final root = _asMap(json);
  if (root.isEmpty) {
    return const <dynamic>[];
  }

  final directVehicles = _valueForKey(root, 'vehicles');
  if (directVehicles is List) {
    return directVehicles;
  }

  final dataValue = _valueForKey(root, 'data');
  if (dataValue is List) {
    return dataValue;
  }

  final dataMap = _asMap(dataValue);
  if (dataMap.isNotEmpty) {
    final nestedVehicles = _valueForKey(dataMap, 'vehicles');
    if (nestedVehicles is List) {
      return nestedVehicles;
    }
  }

  return _extractList(root, preferredKeys: const [
    'vehicles',
    'data',
    'items',
    'rows',
  ]);
}

void _putIfNotNull(Map<String, dynamic> payload, String key, Object? value) {
  if (value != null) {
    payload[key] = value;
  }
}

String _requiredString(String value, String fieldName) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError('$fieldName is required.');
  }
  return normalized;
}

String? _optionalString(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

Map<String, dynamic> _extractMapPayload(
  dynamic json, {
  List<String> preferredKeys = const ['data', 'result', 'payload', 'response'],
}) {
  final root = _asMap(json);
  if (root.isEmpty) {
    return const <String, dynamic>{};
  }

  for (final key in preferredKeys) {
    final value = _valueForKey(root, key);
    final map = _asMap(value);
    if (map.isNotEmpty) {
      return map;
    }
  }

  for (final key in const [
    'data',
    'result',
    'payload',
    'response',
    'subuser',
    'subUser',
  ]) {
    final nested = _valueForKey(root, key);
    if (nested == null || identical(nested, json)) {
      continue;
    }

    final nestedMap = _extractMapPayload(
      nested,
      preferredKeys: preferredKeys,
    );
    if (nestedMap.isNotEmpty) {
      return nestedMap;
    }
  }

  return root;
}

List<dynamic> _extractList(
  dynamic json, {
  List<String> preferredKeys = const ['items', 'rows', 'records', 'data'],
}) {
  if (json is List) {
    return json;
  }

  final root = _asMap(json);
  if (root.isEmpty) {
    return const <dynamic>[];
  }

  for (final key in preferredKeys) {
    final value = _valueForKey(root, key);
    if (value is List) {
      return value;
    }
  }

  for (final key in const ['data', 'result', 'payload', 'response']) {
    final nested = _valueForKey(root, key);
    if (nested == null || identical(nested, json)) {
      continue;
    }

    final list = _extractList(
      nested,
      preferredKeys: preferredKeys,
    );
    if (list.isNotEmpty) {
      return list;
    }
  }

  return const <dynamic>[];
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

dynamic _valueForKey(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) {
    return json[key];
  }

  final normalized = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == normalized) {
      return entry.value;
    }
  }
  return null;
}

dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    if (value != null) {
      return value;
    }
  }
  return null;
}

Map<String, dynamic>? _firstMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final map = _asMap(_valueForKey(json, key));
    if (map.isNotEmpty) {
      return map;
    }
  }
  return null;
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final parsed = _parseString(_valueForKey(json, key));
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

String? _parseString(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'null') {
      return null;
    }
    return normalized;
  }

  if (value is num || value is bool) {
    return value.toString();
  }

  return null;
}

bool? _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    if (const {
      'true',
      '1',
      'yes',
      'y',
      'active',
      'enabled',
      'online',
    }.contains(normalized)) {
      return true;
    }

    if (const {
      'false',
      '0',
      'no',
      'n',
      'inactive',
      'disabled',
      'offline',
    }.contains(normalized)) {
      return false;
    }
  }

  return null;
}

int? _firstInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final parsed = _parseInt(_valueForKey(json, key));
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

int? _parseInt(dynamic value) {
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

DateTime? _firstDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final parsed = _parseDate(_valueForKey(json, key));
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  if (value is num) {
    final millis = value > 1000000000000 ? value.toInt() : value.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
  }

  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == '-') {
      return null;
    }

    final numeric = num.tryParse(normalized);
    if (numeric != null) {
      return _parseDate(numeric);
    }

    return DateTime.tryParse(normalized);
  }

  return null;
}
