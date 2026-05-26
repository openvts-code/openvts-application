class AdminInventoryTab {
  static const devices = 'devices';
  static const simCards = 'simCards';
}

enum AdminInventoryStatus { inStock, inUse, inScrap, unknown }

enum AdminInventoryStatusFilter { all, inStock, inUse, inScrap }

enum AdminInventoryActiveFilter { all, active, inactive }

enum AdminInventoryDeviceSortOption { newest, imeiAsc, typeAsc, activeFirst }

enum AdminInventorySimSortOption {
  newest,
  simNumberAsc,
  providerAsc,
  activeFirst,
}

class AdminInventoryDevice {
  const AdminInventoryDevice({
    required this.id,
    required this.imei,
    required this.deviceType,
    required this.deviceTypeId,
    required this.assignedSimId,
    required this.assignedSimNumber,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String imei;
  final String deviceType;
  final String? deviceTypeId;
  final String? assignedSimId;
  final String assignedSimNumber;
  final AdminInventoryStatus status;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get statusLabel => status.toApiValue().replaceAll('_', ' ');

  factory AdminInventoryDevice.fromJson(Map<String, dynamic> json) {
    final source = _extractMap(json);
    final typeMap = _firstMap(source, const ['type', 'deviceType']) ??
        const <String, dynamic>{};
    final simMap =
        _firstMap(source, const ['sim']) ?? const <String, dynamic>{};

    return AdminInventoryDevice(
      id: _firstString(source, const ['id', '_id']) ?? '',
      imei: _firstString(source, const ['imei']) ?? '-',
      deviceType: _firstString(typeMap, const ['name']) ??
          _firstString(source, const ['deviceType']) ??
          '-',
      deviceTypeId: _firstString(typeMap, const ['id']) ??
          _firstString(source, const ['deviceTypeId']),
      assignedSimId: _firstString(simMap, const ['id']) ??
          _firstString(source, const ['simId']),
      assignedSimNumber:
          _firstString(simMap, const ['simNumber', 'sim_number']) ??
              _firstString(source, const ['simNumber', 'sim_number']) ??
              '',
      status: _parseInventoryStatus(_firstValue(source, const ['status'])),
      isActive: _parseActive(
              _firstValue(source, const ['isActive', 'is_active', 'active'])) ??
          true,
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(source, const ['updatedAt', 'updated_at']),
    );
  }

  static List<AdminInventoryDevice> listFromJson(dynamic json) {
    return _extractList(json, const ['devices'])
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminInventoryDevice.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminInventorySimCard {
  const AdminInventorySimCard({
    required this.id,
    required this.simNumber,
    required this.provider,
    required this.providerId,
    required this.imsi,
    required this.iccid,
    required this.associatedDeviceImei,
    required this.associatedDeviceImeis,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String simNumber;
  final String provider;
  final String? providerId;
  final String imsi;
  final String iccid;
  final String associatedDeviceImei;
  final List<String> associatedDeviceImeis;
  final AdminInventoryStatus status;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get statusLabel => status.toApiValue().replaceAll('_', ' ');

  factory AdminInventorySimCard.fromJson(Map<String, dynamic> json) {
    final source = _extractMap(json);
    final providerMap =
        _firstMap(source, const ['provider']) ?? const <String, dynamic>{};
    final deviceMap =
        _firstMap(source, const ['device']) ?? const <String, dynamic>{};
    final devices = _firstList(source, const ['devices']) ?? const <dynamic>[];
    final deviceImeis = devices
        .map(_asMap)
        .map((item) => _firstString(item, const ['imei']) ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final assocImei = _firstString(deviceMap, const ['imei']) ??
        _firstString(source, const ['associatedDeviceImei']) ??
        (deviceImeis.isNotEmpty ? deviceImeis.first : '');

    return AdminInventorySimCard(
      id: _firstString(source, const ['id', '_id']) ?? '',
      simNumber: _firstString(source, const ['simNumber', 'sim_number']) ?? '-',
      provider: _firstString(providerMap, const ['name']) ?? '-',
      providerId: _firstString(providerMap, const ['id']) ??
          _firstString(source, const ['providerId']),
      imsi: _firstString(source, const ['imsi']) ?? '-',
      iccid: _firstString(source, const ['iccid']) ?? '-',
      associatedDeviceImei: assocImei,
      associatedDeviceImeis: deviceImeis,
      status: _parseInventoryStatus(_firstValue(source, const ['status'])),
      isActive: _parseActive(
              _firstValue(source, const ['isActive', 'is_active', 'active'])) ??
          true,
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(source, const ['updatedAt', 'updated_at']),
    );
  }

  static List<AdminInventorySimCard> listFromJson(dynamic json) {
    return _extractList(json, const ['simcards'])
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminInventorySimCard.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminDeviceTypeOption {
  const AdminDeviceTypeOption({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory AdminDeviceTypeOption.fromJson(Map<String, dynamic> json) {
    final source = _extractMap(json);
    return AdminDeviceTypeOption(
      id: _firstString(source, const ['id']) ?? '',
      name: _firstString(source, const ['name']) ?? '-',
      slug: _firstString(source, const ['slug']) ?? '-',
    );
  }

  static List<AdminDeviceTypeOption> listFromJson(dynamic json) {
    return _extractList(json, const ['items'])
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminDeviceTypeOption.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminSimProviderOption {
  const AdminSimProviderOption({
    required this.id,
    required this.name,
    required this.apnName,
  });

  final String id;
  final String name;
  final String apnName;

  factory AdminSimProviderOption.fromJson(Map<String, dynamic> json) {
    final source = _extractMap(json);
    return AdminSimProviderOption(
      id: _firstString(source, const ['id']) ?? '',
      name: _firstString(source, const ['name']) ?? '-',
      apnName: _firstString(source, const ['apnName', 'apn_name']) ?? '-',
    );
  }

  static List<AdminSimProviderOption> listFromJson(dynamic json) {
    return _extractList(json, const ['items'])
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminSimProviderOption.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminQuickSimCardOption {
  const AdminQuickSimCardOption({required this.id, required this.simNumber});

  final String id;
  final String simNumber;

  factory AdminQuickSimCardOption.fromJson(Map<String, dynamic> json) {
    final source = _extractMap(json);
    return AdminQuickSimCardOption(
      id: _firstString(source, const ['id']) ?? '',
      simNumber: _firstString(source, const ['simNumber', 'sim_number']) ?? '-',
    );
  }

  static List<AdminQuickSimCardOption> listFromJson(dynamic json) {
    return _extractList(json, const ['simcards', 'items'])
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminQuickSimCardOption.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminCreateDeviceRequest {
  const AdminCreateDeviceRequest(
      {required this.imei, required this.deviceTypeId});

  final String imei;
  final int deviceTypeId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'imei': imei.trim(),
        'deviceTypeId': deviceTypeId,
      };
}

class AdminCreateSimCardRequest {
  const AdminCreateSimCardRequest({
    required this.simNumber,
    this.imsi,
    this.iccid,
    this.providerId,
  });

  final String simNumber;
  final String? imsi;
  final String? iccid;
  final String? providerId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'simNumber': simNumber.trim()};
    if ((imsi ?? '').trim().isNotEmpty) {
      map['imsi'] = imsi!.trim();
    }
    if ((iccid ?? '').trim().isNotEmpty) {
      map['iccid'] = iccid!.trim();
    }
    if ((providerId ?? '').trim().isNotEmpty) {
      map['providerId'] = providerId!.trim();
    }
    return map;
  }
}

class AdminCreateDeviceAndSimRequest {
  const AdminCreateDeviceAndSimRequest({
    required this.imei,
    required this.deviceTypeId,
    required this.simNumber,
    this.imsi,
    this.iccid,
    this.providerId,
  });

  final String imei;
  final int deviceTypeId;
  final String simNumber;
  final String? imsi;
  final String? iccid;
  final String? providerId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'imei': imei.trim(),
      'deviceTypeId': deviceTypeId,
      'simNumber': simNumber.trim(),
    };
    if ((imsi ?? '').trim().isNotEmpty) {
      map['imsi'] = imsi!.trim();
    }
    if ((iccid ?? '').trim().isNotEmpty) {
      map['iccid'] = iccid!.trim();
    }
    if ((providerId ?? '').trim().isNotEmpty) {
      map['providerId'] = providerId!.trim();
    }
    return map;
  }
}

class AdminUpdateDeviceRequest {
  const AdminUpdateDeviceRequest({
    this.deviceTypeId,
    this.simId,
    this.status,
    this.isActive,
  });

  final int? deviceTypeId;
  final int? simId;
  final String? status;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (deviceTypeId != null) {
      map['deviceTypeId'] = deviceTypeId;
    }
    if (simId != null) {
      map['simId'] = simId;
    }
    if ((status ?? '').trim().isNotEmpty) {
      map['status'] = status!.trim();
    }
    if (isActive != null) {
      map['isActive'] = isActive;
    }
    return map;
  }
}

class AdminUpdateSimCardRequest {
  const AdminUpdateSimCardRequest({
    this.simNumber,
    this.imsi,
    this.iccid,
    this.providerId,
    this.status,
    this.isActive,
  });

  final String? simNumber;
  final String? imsi;
  final String? iccid;
  final int? providerId;
  final String? status;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if ((simNumber ?? '').trim().isNotEmpty) {
      map['simNumber'] = simNumber!.trim();
    }
    if ((imsi ?? '').trim().isNotEmpty) {
      map['imsi'] = imsi!.trim();
    }
    if ((iccid ?? '').trim().isNotEmpty) {
      map['iccid'] = iccid!.trim();
    }
    if (providerId != null) {
      map['providerId'] = providerId;
    }
    if ((status ?? '').trim().isNotEmpty) {
      map['status'] = status!.trim();
    }
    if (isActive != null) {
      map['isActive'] = isActive;
    }
    return map;
  }
}

extension AdminInventoryStatusX on AdminInventoryStatus {
  String toApiValue() {
    return switch (this) {
      AdminInventoryStatus.inStock => 'IN_STOCK',
      AdminInventoryStatus.inUse => 'IN_USE',
      AdminInventoryStatus.inScrap => 'IN_SCRAP',
      AdminInventoryStatus.unknown => 'UNKNOWN',
    };
  }
}

AdminInventoryStatus _parseInventoryStatus(dynamic value) {
  final normalized = value?.toString().trim().toUpperCase() ?? '';
  if (normalized == 'IN_STOCK') {
    return AdminInventoryStatus.inStock;
  }
  if (normalized == 'IN_USE') {
    return AdminInventoryStatus.inUse;
  }
  if (normalized == 'IN_SCRAP') {
    return AdminInventoryStatus.inScrap;
  }
  return AdminInventoryStatus.unknown;
}

List<dynamic> _extractList(dynamic json, List<String> directKeys) {
  if (json is List) {
    return json;
  }
  if (json is Map<String, dynamic>) {
    final direct = _firstList(json, directKeys);
    if (direct != null) {
      return direct;
    }
    final data = json['data'];
    if (data is List) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final nested = _firstList(data, directKeys);
      if (nested != null) {
        return nested;
      }
      final deepData = data['data'];
      if (deepData is List) {
        return deepData;
      }
    }
  }
  return const <dynamic>[];
}

Map<String, dynamic> _extractMap(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    final nestedData = data['data'];
    if (nestedData is Map<String, dynamic>) {
      return nestedData;
    }
    return data;
  }
  return json;
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

List<dynamic>? _firstList(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is List) {
      return value;
    }
  }
  return null;
}

Map<String, dynamic>? _firstMap(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((nestedKey, nestedValue) =>
          MapEntry(nestedKey.toString(), nestedValue));
    }
  }
  return null;
}

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) {
      continue;
    }
    final asString = value.toString().trim();
    if (asString.isNotEmpty && asString.toLowerCase() != 'null') {
      return asString;
    }
  }
  return null;
}

dynamic _firstValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map.containsKey(key)) {
      return map[key];
    }
  }
  return null;
}

bool? _parseActive(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value == 1;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' ||
        normalized == 'active' ||
        normalized == '1' ||
        normalized == 'enabled') {
      return true;
    }
    if (normalized == 'false' ||
        normalized == 'inactive' ||
        normalized == '0' ||
        normalized == 'disabled') {
      return false;
    }
  }
  return null;
}

DateTime? _firstDate(Map<String, dynamic> map, List<String> keys) {
  final raw = _firstString(map, keys);
  if (raw == null) {
    return null;
  }
  return DateTime.tryParse(raw);
}
