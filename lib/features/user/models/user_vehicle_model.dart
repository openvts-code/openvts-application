import 'package:file_picker/file_picker.dart';

class UserVehicleListItem {
  const UserVehicleListItem({
    required this.id,
    required this.name,
    required this.vin,
    required this.plateNumber,
    required this.isActive,
    required this.isLicenseBlocked,
    required this.licenseBlockedAt,
    required this.licenseBlockReason,
    required this.createdAt,
    required this.imei,
    required this.simNumber,
    required this.vehicleType,
    required this.device,
  });

  final String id;
  final String name;
  final String vin;
  final String plateNumber;
  final bool isActive;
  final bool isLicenseBlocked;
  final DateTime? licenseBlockedAt;
  final String? licenseBlockReason;
  final DateTime? createdAt;
  final String imei;
  final String simNumber;
  final UserVehicleTypeMini? vehicleType;
  final UserVehicleDeviceMini? device;

  String get vehicleTypeName => vehicleType?.name ?? '';

  String get statusLabel {
    if (isLicenseBlocked) return 'License blocked';
    return isActive ? 'Active' : 'Inactive';
  }

  String get searchContent {
    return [
      name,
      plateNumber,
      vin,
      imei,
      simNumber,
      vehicleTypeName,
    ].join(' ').toLowerCase();
  }

  factory UserVehicleListItem.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['vehicle', 'details', 'item', 'record'],
    );
    final vehicleType = _parseVehicleTypeMini(source);
    final device = _parseVehicleDeviceMini(source);
    final simMap =
        _firstMap(_asMap(source['device']), const ['sim', 'simCard']);

    return UserVehicleListItem(
      id: _firstString(source, const ['id', '_id', 'vehicleId', 'uid']) ?? '',
      name: _firstString(source, const [
            'name',
            'vehicleName',
            'vehicle_name',
            'displayName',
            'label',
          ]) ??
          '',
      vin: _firstString(source, const ['vin', 'VIN', 'chassisNo']) ?? '',
      plateNumber: _firstString(source, const [
            'plateNumber',
            'plate_number',
            'numberPlate',
            'registrationNumber',
            'registration_no',
            'vehicleNo',
          ]) ??
          '',
      isActive: _parseBool(_firstValue(source, const [
            'isActive',
            'is_active',
            'active',
            'activeStatus',
            'status',
          ])) ??
          true,
      isLicenseBlocked: _parseBool(_firstValue(source, const [
            'isLicenseBlocked',
            'is_license_blocked',
            'licenseBlocked',
            'license_blocked',
          ])) ??
          false,
      licenseBlockedAt: _firstDate(source, const [
        'licenseBlockedAt',
        'license_blocked_at',
        'blockedAt',
      ]),
      licenseBlockReason: _firstString(source, const [
        'licenseBlockReason',
        'license_block_reason',
        'blockReason',
        'reason',
      ]),
      createdAt: _firstDate(source, const [
        'createdAt',
        'created_at',
        'addedAt',
        'added_at',
      ]),
      imei: _firstString(source, const [
            'imei',
            'IMEI',
            'deviceImei',
            'deviceIMEI',
          ]) ??
          device?.imei ??
          '',
      simNumber: _firstString(source, const [
            'simNumber',
            'sim_number',
            'simno',
            'simNo',
            'sim',
          ]) ??
          _firstString(simMap ?? const <String, dynamic>{}, const [
            'simNumber',
            'sim_number',
            'number',
            'mobile',
          ]) ??
          device?.simNumber ??
          '',
      vehicleType: vehicleType,
      device: device,
    );
  }

  static List<UserVehicleListItem> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'vehicles',
      'items',
      'rows',
      'records',
      'docs',
      'data',
    ])
        .map(UserVehicleListItem.fromJson)
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class UserVehicleTypeMini {
  const UserVehicleTypeMini({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  bool get hasContent => id.isNotEmpty || name.isNotEmpty || slug.isNotEmpty;

  factory UserVehicleTypeMini.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserVehicleTypeMini(
      id: _firstString(source, const ['id', '_id', 'typeId']) ?? '',
      name: _firstString(source, const [
            'name',
            'vehicleType',
            'vehicle_type',
            'type',
            'label',
          ]) ??
          '',
      slug: _firstString(source, const ['slug', 'key', 'code']) ?? '',
    );
  }
}

class UserVehicleDeviceMini {
  const UserVehicleDeviceMini({
    required this.id,
    required this.imei,
    required this.simNumber,
    required this.speedVariation,
    required this.distanceVariation,
    required this.odometer,
    required this.engineHours,
    required this.ignitionSource,
    required this.liveOdometer,
    required this.liveEngineHours,
  });

  final String id;
  final String imei;
  final String simNumber;
  final num? speedVariation;
  final num? distanceVariation;
  final num? odometer;
  final num? engineHours;
  final String? ignitionSource;
  final num? liveOdometer;
  final num? liveEngineHours;

  bool get hasContent {
    return id.isNotEmpty ||
        imei.isNotEmpty ||
        simNumber.isNotEmpty ||
        speedVariation != null ||
        distanceVariation != null ||
        odometer != null ||
        engineHours != null ||
        ignitionSource != null ||
        liveOdometer != null ||
        liveEngineHours != null;
  }

  factory UserVehicleDeviceMini.fromJson(dynamic json) {
    final source = _asMap(json);
    final simMap = _firstMap(source, const ['sim', 'simCard']);
    return UserVehicleDeviceMini(
      id: _firstString(source, const ['id', '_id', 'deviceId']) ?? '',
      imei: _firstString(source, const [
            'imei',
            'IMEI',
            'deviceImei',
            'deviceIMEI',
          ]) ??
          '',
      simNumber: _firstString(source, const [
            'simNumber',
            'sim_number',
            'simno',
            'simNo',
            'sim',
          ]) ??
          _firstString(simMap ?? const <String, dynamic>{}, const [
            'simNumber',
            'sim_number',
            'number',
            'mobile',
          ]) ??
          '',
      speedVariation: _firstNum(source, const [
        'speedVariation',
        'speed_variation',
      ]),
      distanceVariation: _firstNum(source, const [
        'distanceVariation',
        'distance_variation',
      ]),
      odometer: _firstNum(source, const ['odometer', 'odometerKm']),
      engineHours: _firstNum(source, const [
        'engineHours',
        'engine_hours',
      ]),
      ignitionSource: _firstString(source, const [
        'ignitionSource',
        'ignition_source',
      ]),
      liveOdometer: _firstNum(source, const [
        'liveOdometer',
        'live_odometer',
      ]),
      liveEngineHours: _firstNum(source, const [
        'liveEngineHours',
        'live_engine_hours',
      ]),
    );
  }
}

class UserVehiclePlanMini {
  const UserVehiclePlanMini({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
  });

  final String id;
  final String name;
  final num? price;
  final String currency;

  bool get hasContent {
    return id.isNotEmpty ||
        name.isNotEmpty ||
        price != null ||
        currency.isNotEmpty;
  }

  factory UserVehiclePlanMini.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserVehiclePlanMini(
      id: _firstString(source, const ['id', '_id', 'planId']) ?? '',
      name: _firstString(source, const ['name', 'title', 'label']) ?? '',
      price: _firstNum(source, const ['price', 'amount', 'value']),
      currency: _firstString(source, const ['currency', 'currencyCode']) ?? '',
    );
  }
}

class UserVehicleDetails {
  const UserVehicleDetails({
    required this.id,
    required this.name,
    required this.vin,
    required this.plateNumber,
    required this.isActive,
    required this.isLicenseBlocked,
    required this.licenseBlockedAt,
    required this.licenseBlockReason,
    required this.createdAt,
    required this.imei,
    required this.simNumber,
    required this.vehicleType,
    required this.vehicleMeta,
    required this.gmtOffset,
    required this.device,
    required this.plan,
  });

  final String id;
  final String name;
  final String vin;
  final String plateNumber;
  final bool isActive;
  final bool isLicenseBlocked;
  final DateTime? licenseBlockedAt;
  final String? licenseBlockReason;
  final DateTime? createdAt;
  final String imei;
  final String simNumber;
  final UserVehicleTypeMini? vehicleType;
  final Map<String, dynamic> vehicleMeta;
  final String? gmtOffset;
  final UserVehicleDeviceMini? device;
  final UserVehiclePlanMini? plan;

  String get title {
    final normalizedName = name.trim();
    if (normalizedName.isNotEmpty) return normalizedName;
    final normalizedPlate = plateNumber.trim();
    if (normalizedPlate.isNotEmpty) return normalizedPlate;
    return 'Vehicle';
  }

  factory UserVehicleDetails.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['vehicle', 'details', 'item', 'record'],
    );
    final vehicleType = _parseVehicleTypeMini(source);
    final device = _parseVehicleDeviceMini(source);
    final plan = _parseVehiclePlanMini(source);
    final simMap =
        _firstMap(_asMap(source['device']), const ['sim', 'simCard']);

    return UserVehicleDetails(
      id: _firstString(source, const ['id', '_id', 'vehicleId', 'uid']) ?? '',
      name: _firstString(source, const [
            'name',
            'vehicleName',
            'vehicle_name',
            'displayName',
            'label',
          ]) ??
          '',
      vin: _firstString(source, const ['vin', 'VIN', 'chassisNo']) ?? '',
      plateNumber: _firstString(source, const [
            'plateNumber',
            'plate_number',
            'numberPlate',
            'registrationNumber',
            'registration_no',
            'vehicleNo',
          ]) ??
          '',
      isActive: _parseBool(_firstValue(source, const [
            'isActive',
            'is_active',
            'active',
            'activeStatus',
            'status',
          ])) ??
          true,
      isLicenseBlocked: _parseBool(_firstValue(source, const [
            'isLicenseBlocked',
            'is_license_blocked',
            'licenseBlocked',
            'license_blocked',
          ])) ??
          false,
      licenseBlockedAt: _firstDate(source, const [
        'licenseBlockedAt',
        'license_blocked_at',
        'blockedAt',
      ]),
      licenseBlockReason: _firstString(source, const [
        'licenseBlockReason',
        'license_block_reason',
        'blockReason',
        'reason',
      ]),
      createdAt: _firstDate(source, const [
        'createdAt',
        'created_at',
        'addedAt',
        'added_at',
      ]),
      imei: _firstString(source, const [
            'imei',
            'IMEI',
            'deviceImei',
            'deviceIMEI',
          ]) ??
          device?.imei ??
          '',
      simNumber: _firstString(source, const [
            'simNumber',
            'sim_number',
            'simno',
            'simNo',
            'sim',
          ]) ??
          _firstString(simMap ?? const <String, dynamic>{}, const [
            'simNumber',
            'sim_number',
            'number',
            'mobile',
          ]) ??
          device?.simNumber ??
          '',
      vehicleType: vehicleType,
      vehicleMeta: _firstMap(source, const [
            'vehicleMeta',
            'vehicle_meta',
            'meta',
            'metadata',
          ]) ??
          const <String, dynamic>{},
      gmtOffset: _firstString(source, const [
        'gmtOffset',
        'gmt_offset',
        'timezone',
        'timeZone',
      ]),
      device: device,
      plan: plan,
    );
  }
}

class UserVehicleUpdateRequest {
  const UserVehicleUpdateRequest({
    this.name,
    this.plateNumber,
    this.vin,
    this.vehicleTypeId,
    this.gmtOffset,
    this.vehicleMeta,
  });

  final String? name;
  final String? plateNumber;
  final String? vin;
  final Object? vehicleTypeId;
  final String? gmtOffset;
  final Map<String, dynamic>? vehicleMeta;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};
    _putIfNotNull(payload, 'name', _optionalString(name));
    _putIfNotNull(payload, 'plateNumber', _optionalNullableString(plateNumber));
    _putIfNotNull(payload, 'vin', _optionalNullableString(vin));
    _putIfNotNull(payload, 'vehicleTypeId', _idPayloadValue(vehicleTypeId));
    _putIfNotNull(payload, 'gmtOffset', _optionalNullableString(gmtOffset));
    final meta = vehicleMeta;
    if (meta != null) {
      payload['vehicleMeta'] = Map<String, dynamic>.from(meta);
    }
    return payload;
  }
}

class UserVehicleConfigUpdateRequest {
  const UserVehicleConfigUpdateRequest({
    this.speedVariation,
    this.distanceVariation,
    this.odometer,
    this.engineHours,
    this.ignitionSource,
  });

  static const allowedIgnitionSources = <String>{'ACC', 'MOTION'};

  final num? speedVariation;
  final num? distanceVariation;
  final num? odometer;
  final num? engineHours;
  final String? ignitionSource;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};
    _putIfNotNull(payload, 'speedVariation', speedVariation);
    _putIfNotNull(payload, 'distanceVariation', distanceVariation);
    _putIfNotNull(payload, 'odometer', odometer);
    _putIfNotNull(payload, 'engineHours', engineHours);
    final normalizedIgnitionSource = ignitionSource?.trim().toUpperCase();
    if (normalizedIgnitionSource != null &&
        normalizedIgnitionSource.isNotEmpty) {
      if (!allowedIgnitionSources.contains(normalizedIgnitionSource)) {
        throw ArgumentError('Unsupported ignitionSource.');
      }
      payload['ignitionSource'] = normalizedIgnitionSource;
    }
    return payload;
  }
}

class UserVehicleSensor {
  const UserVehicleSensor({
    required this.id,
    required this.name,
    required this.unit,
    required this.icon,
    required this.code,
    required this.value,
    required this.liveValue,
    required this.displayValue,
    required this.dataType,
    required this.isActive,
    required this.lastUpdated,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? unit;
  final String? icon;
  final String code;
  final dynamic value;
  final dynamic liveValue;
  final String displayValue;
  final String? dataType;
  final bool isActive;
  final DateTime? lastUpdated;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get title => name.trim().isEmpty ? 'Sensor' : name.trim();

  factory UserVehicleSensor.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['sensor', 'item', 'record'],
    );
    final liveValue = _firstValue(source, const [
      'liveValue',
      'live_value',
      'telemetryValue',
      'telemetry_value',
    ]);
    final value =
        _firstValue(source, const ['value', 'lastValue', 'last_value']);
    return UserVehicleSensor(
      id: _firstString(source, const ['id', '_id', 'sensorId']) ?? '',
      name: _firstString(source, const ['name', 'title', 'label']) ?? '',
      unit: _firstString(source, const ['unit', 'suffix']),
      icon: _firstString(source, const ['icon', 'iconName', 'icon_name']),
      code: _firstString(source, const [
            'code',
            'sourceExpression',
            'source_expression',
            'expression',
          ]) ??
          '',
      value: value,
      liveValue: liveValue,
      displayValue: _firstString(source, const [
            'displayValue',
            'display_value',
            'formattedValue',
            'formatted_value',
          ]) ??
          _formatDynamicValue(liveValue ?? value),
      dataType: _firstString(source, const [
        'dataType',
        'data_type',
        'type',
        'kind',
      ]),
      isActive: _parseBool(
            _firstValue(source, const [
              'isActive',
              'is_active',
              'active',
              'enabled',
            ]),
          ) ??
          true,
      lastUpdated: _firstDate(source, const [
        'lastUpdated',
        'last_updated',
        'updatedAt',
        'updated_at',
        'serverTime',
        'server_time',
      ]),
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(source, const ['updatedAt', 'updated_at']),
    );
  }
}

class UserVehicleSensorPage {
  const UserVehicleSensorPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    this.telemetryMeta,
  });

  final List<UserVehicleSensor> items;
  final int page;
  final int limit;
  final int total;
  final Map<String, dynamic>? telemetryMeta;

  factory UserVehicleSensorPage.fromJson(
    dynamic json, {
    int defaultPage = 1,
    int defaultLimit = 100,
  }) {
    if (json is List) {
      final items =
          json.map(UserVehicleSensor.fromJson).toList(growable: false);
      return UserVehicleSensorPage(
        items: items,
        page: defaultPage,
        limit: defaultLimit,
        total: items.length,
      );
    }

    final source = _extractMapPayload(json);
    final items = _extractList(source, preferredKeys: const [
      'sensors',
      'items',
      'rows',
      'records',
      'data',
    ]).map(UserVehicleSensor.fromJson).toList(growable: false);

    return UserVehicleSensorPage(
      items: items,
      page: _firstInt(source, const ['page', 'currentPage', 'current_page']) ??
          defaultPage,
      limit: _firstInt(source, const ['limit', 'pageSize', 'perPage']) ??
          defaultLimit,
      total: _firstInt(source, const ['total', 'totalCount', 'count']) ??
          items.length,
      telemetryMeta: _firstMap(source, const [
        'telemetryMeta',
        'telemetry_meta',
        'meta',
      ]),
    );
  }
}

class UserVehicleSensorTelemetry {
  const UserVehicleSensorTelemetry({
    required this.payload,
    required this.updatedAt,
    required this.imei,
  });

  final Map<String, dynamic> payload;
  final DateTime? updatedAt;
  final String imei;

  factory UserVehicleSensorTelemetry.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['telemetry', 'data', 'payload'],
    );
    final payload = _firstMap(source, const [
          'payload',
          'values',
          'telemetry',
          'data',
        ]) ??
        source;
    return UserVehicleSensorTelemetry(
      payload: payload,
      updatedAt: _firstDate(source, const [
        'updatedAt',
        'updated_at',
        'serverTime',
        'server_time',
        'time',
      ]),
      imei: _firstString(source, const ['imei', 'IMEI']) ?? '',
    );
  }
}

class UserVehicleSensorHistory {
  const UserVehicleSensorHistory({
    required this.supported,
    required this.reason,
    required this.sensor,
    required this.range,
    required this.sampling,
    required this.points,
    required this.stats,
  });

  final bool supported;
  final String? reason;
  final UserVehicleSensor? sensor;
  final Map<String, dynamic>? range;
  final Map<String, dynamic>? sampling;
  final List<UserVehicleSensorHistoryPoint> points;
  final Map<String, dynamic>? stats;

  factory UserVehicleSensorHistory.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['history', 'data', 'result'],
    );
    final points = _extractList(source, preferredKeys: const [
      'points',
      'items',
      'rows',
      'data',
    ]).map(UserVehicleSensorHistoryPoint.fromJson).toList(growable: false);
    final sensorMap = _firstMap(source, const ['sensor']);

    return UserVehicleSensorHistory(
      supported: _parseBool(
            _firstValue(source, const ['supported', 'isSupported']),
          ) ??
          true,
      reason: _firstString(source, const ['reason', 'message', 'error']),
      sensor: sensorMap == null ? null : UserVehicleSensor.fromJson(sensorMap),
      range: _firstMap(source, const ['range', 'dateRange', 'date_range']),
      sampling: _firstMap(source, const ['sampling', 'sample']),
      points: points,
      stats: _firstMap(source, const ['stats', 'statistics', 'summary']),
    );
  }
}

class UserVehicleSensorHistoryPoint {
  const UserVehicleSensorHistoryPoint({
    required this.time,
    required this.value,
    required this.raw,
  });

  final DateTime? time;
  final dynamic value;
  final Map<String, dynamic> raw;

  factory UserVehicleSensorHistoryPoint.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserVehicleSensorHistoryPoint(
      time: _firstDate(source, const [
        'time',
        'timestamp',
        'serverTime',
        'server_time',
        'createdAt',
        'created_at',
      ]),
      value: _firstValue(source, const ['value', 'y', 'reading']),
      raw: source,
    );
  }
}

class UserVehicleSensorRunResult {
  const UserVehicleSensorRunResult({
    required this.value,
    required this.output,
    required this.error,
    required this.payload,
  });

  final dynamic value;
  final String? output;
  final String? error;
  final Map<String, dynamic> payload;

  factory UserVehicleSensorRunResult.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['result', 'run', 'data', 'payload'],
    );
    return UserVehicleSensorRunResult(
      value: _firstValue(source, const ['value', 'result', 'reading']),
      output: _firstString(source, const ['output', 'stdout', 'message']),
      error: _firstString(source, const ['error', 'stderr']),
      payload: source,
    );
  }
}

class UserVehicleDocument {
  const UserVehicleDocument({
    required this.id,
    required this.title,
    required this.docTypeId,
    required this.docTypeName,
    required this.description,
    required this.tags,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    required this.fileUrl,
    required this.expiryAt,
    required this.isVisible,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String docTypeId;
  final String docTypeName;
  final String description;
  final List<String> tags;
  final String fileName;
  final String fileType;
  final String filePath;
  final String fileUrl;
  final DateTime? expiryAt;
  final bool isVisible;
  final DateTime? createdAt;

  factory UserVehicleDocument.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['document', 'doc', 'item'],
    );
    final docType = _firstMap(source, const [
          'docType',
          'doc_type',
          'documentType',
        ]) ??
        const <String, dynamic>{};
    final filePath = _firstString(source, const [
          'filePath',
          'file_path',
          'path',
        ]) ??
        '';
    final fileUrl = _firstString(source, const [
          'fileUrl',
          'file_url',
          'url',
        ]) ??
        filePath;

    return UserVehicleDocument(
      id: _firstString(source, const ['id', '_id', 'docId', 'documentId']) ??
          '',
      title: _firstString(source, const ['title', 'name']) ?? '',
      docTypeId: _firstString(source, const [
            'docTypeId',
            'doc_type_id',
            'documentTypeId',
          ]) ??
          _firstString(docType, const ['id', '_id']) ??
          '',
      docTypeName: _firstString(source, const [
            'docTypeName',
            'doc_type_name',
            'documentTypeName',
          ]) ??
          _firstString(docType, const ['name', 'label', 'title']) ??
          '',
      description: _firstString(source, const ['description', 'desc']) ?? '',
      tags: _parseStringList(_firstValue(source, const ['tags', 'tagList'])),
      fileName: _firstString(source, const ['fileName', 'file_name']) ?? '',
      fileType:
          _firstString(source, const ['fileType', 'file_type', 'mime']) ?? '',
      filePath: filePath,
      fileUrl: fileUrl,
      expiryAt: _firstDate(source, const ['expiryAt', 'expiry_at', 'expiry']),
      isVisible: _parseBool(_firstValue(source, const [
            'isVisible',
            'is_visible',
            'visible',
          ])) ??
          true,
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
    );
  }

  static List<UserVehicleDocument> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'documents',
      'docs',
      'items',
      'rows',
      'data',
    ]).map(UserVehicleDocument.fromJson).toList(growable: false);
  }
}

class UserVehicleDocumentType {
  const UserVehicleDocumentType({
    required this.id,
    required this.name,
    required this.docFor,
  });

  final String id;
  final String name;
  final String docFor;

  bool get isForVehicle => docFor.toUpperCase() == 'VEHICLE';

  factory UserVehicleDocumentType.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserVehicleDocumentType(
      id: _firstString(source, const ['id', '_id', 'typeId']) ?? '',
      name: _firstString(source, const ['name', 'label', 'title']) ?? '',
      docFor: (_firstString(source, const ['docFor', 'doc_for', 'for']) ?? '')
          .toUpperCase(),
    );
  }

  static List<UserVehicleDocumentType> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'documentTypes',
      'docTypes',
      'types',
      'items',
      'rows',
      'data',
    ]).map(UserVehicleDocumentType.fromJson).where((item) {
      return item.id.isNotEmpty && (item.docFor.isEmpty || item.isForVehicle);
    }).toList(growable: false);
  }
}

class UserVehicleTypeOption {
  const UserVehicleTypeOption({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory UserVehicleTypeOption.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserVehicleTypeOption(
      id: _firstString(source, const ['id', '_id', 'typeId']) ?? '',
      name: _firstString(source, const ['name', 'label', 'title']) ?? '',
      slug: _firstString(source, const ['slug', 'key', 'code']) ?? '',
    );
  }

  static List<UserVehicleTypeOption> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'vehicleTypes',
      'vehicletypes',
      'types',
      'items',
      'rows',
      'data',
    ]).map(UserVehicleTypeOption.fromJson).where((item) {
      return item.id.isNotEmpty || item.name.isNotEmpty;
    }).toList(growable: false);
  }
}

class UserVehicleDocumentRequest {
  const UserVehicleDocumentRequest({
    required this.title,
    required this.docTypeId,
    this.isVisible = true,
    this.tags = const <String>[],
    this.description = '',
    this.expiryAt,
    this.file,
  });

  final String title;
  final String docTypeId;
  final bool isVisible;
  final List<String> tags;
  final String description;
  final String? expiryAt;
  final PlatformFile? file;
}

UserVehicleTypeMini? _parseVehicleTypeMini(Map<String, dynamic> source) {
  final typeMap = _firstMap(source, const [
    'vehicleType',
    'vehicle_type',
    'vehicletype',
    'typeDetails',
    'categoryDetails',
  ]);
  if (typeMap != null) {
    final type = UserVehicleTypeMini.fromJson(typeMap);
    if (type.hasContent) return type;
  }

  final name = _firstString(source, const [
        'vehicleTypeName',
        'vehicle_type_name',
        'vehicleType',
        'vehicle_type',
        'type',
        'category',
      ]) ??
      '';
  final slug = _firstString(source, const [
        'vehicleTypeSlug',
        'vehicle_type_slug',
        'typeSlug',
      ]) ??
      '';
  if (name.isEmpty && slug.isEmpty) return null;

  return UserVehicleTypeMini(id: '', name: name, slug: slug);
}

UserVehicleDeviceMini? _parseVehicleDeviceMini(Map<String, dynamic> source) {
  final deviceMap = _firstMap(source, const [
    'device',
    'gpsDevice',
    'tracker',
    'unit',
    'deviceDetails',
  ]);
  if (deviceMap != null) {
    final device = UserVehicleDeviceMini.fromJson(deviceMap);
    if (device.hasContent) return device;
  }

  final device = UserVehicleDeviceMini.fromJson(source);
  return device.hasContent ? device : null;
}

UserVehiclePlanMini? _parseVehiclePlanMini(Map<String, dynamic> source) {
  final planMap = _firstMap(source, const [
    'plan',
    'subscriptionPlan',
    'package',
  ]);
  if (planMap == null) return null;
  final plan = UserVehiclePlanMini.fromJson(planMap);
  return plan.hasContent ? plan : null;
}

void _putIfNotNull(Map<String, dynamic> payload, String key, Object? value) {
  if (value != null) {
    payload[key] = value;
  }
}

String? _optionalString(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}

String? _optionalNullableString(String? value) {
  final normalized = value?.trim();
  if (normalized == null) return null;
  return normalized.isEmpty ? null : normalized;
}

Object? _idPayloadValue(Object? value) {
  if (value == null) return null;
  if (value is num) return value;
  final normalized = value.toString().trim();
  if (normalized.isEmpty) return null;
  return int.tryParse(normalized) ?? normalized;
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

  for (final key in const [
    'vehicle',
    'data',
    'result',
    'payload',
    'response'
  ]) {
    final nested = _valueForKey(root, key);
    if (nested == null || identical(nested, json)) continue;
    final nestedMap = _extractMapPayload(nested, preferredKeys: preferredKeys);
    if (nestedMap.isNotEmpty) return nestedMap;
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

Map<String, dynamic>? _firstMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    final map = _asMap(value);
    if (map.isNotEmpty) return map;
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
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;
    return trimmed;
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
    if (const {'true', '1', 'yes', 'y', 'active', 'enabled', 'online'}
        .contains(normalized)) {
      return true;
    }
    if (const {'false', '0', 'no', 'n', 'inactive', 'disabled', 'offline'}
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

num? _firstNum(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final parsed = _parseNum(_valueForKey(json, key));
    if (parsed != null) return parsed;
  }
  return null;
}

num? _parseNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim());
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

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value
        .map(_parseString)
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

String _formatDynamicValue(dynamic value) {
  if (value == null) return '-';
  final normalized = value.toString().trim();
  return normalized.isEmpty ? '-' : normalized;
}
