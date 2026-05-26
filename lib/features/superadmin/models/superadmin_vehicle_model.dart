import '../../notifications/models/app_notification.dart';

class SuperadminVehiclePage {
  const SuperadminVehiclePage({
    required this.items,
    required this.totalCount,
  });

  final List<SuperadminVehicleRecord> items;
  final int totalCount;

  factory SuperadminVehiclePage.fromJson(dynamic json) {
    if (json is List) {
      final items = json
          .map((item) => SuperadminVehicleRecord.fromJson(_asMap(item)))
          .where((item) => item.hasIdentity)
          .toList();

      return SuperadminVehiclePage(
        items: items,
        totalCount: items.length,
      );
    }

    final source = _asMap(json);
    final rawItems = _firstList(
          source,
          const [
            'items',
            'rows',
            'records',
            'docs',
            'data',
            'results',
            'list',
            'vehicles',
            'vehicle',
          ],
        ) ??
        const <dynamic>[];

    final items = rawItems
        .map((item) => SuperadminVehicleRecord.fromJson(_asMap(item)))
        .where((item) => item.hasIdentity)
        .toList();

    final totalCount = _firstInt(
      source,
      const [
        'count',
        'total',
        'totalCount',
        'recordCount',
        'recordsCount',
        'vehiclesCount',
        'totalVehicles',
      ],
    );

    return SuperadminVehiclePage(
      items: items,
      totalCount: totalCount > 0 ? totalCount : items.length,
    );
  }
}

class SuperadminVehicleRecord {
  const SuperadminVehicleRecord({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.type,
    required this.status,
    required this.imei,
    required this.sim,
    required this.primaryUser,
    required this.addedBy,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String plateNumber;
  final String type;
  final String status;
  final String imei;
  final String sim;
  final String primaryUser;
  final String addedBy;
  final DateTime? createdAt;

  bool get hasIdentity {
    return id.isNotEmpty ||
        name.trim().isNotEmpty ||
        plateNumber.trim().isNotEmpty && plateNumber != '—';
  }

  String get searchContent {
    return [
      name,
      plateNumber,
      type,
      status,
      imei,
      sim,
      primaryUser,
      addedBy,
    ].join(' ').toLowerCase();
  }

  factory SuperadminVehicleRecord.fromJson(Map<String, dynamic> json) {
    final vehicleType = _firstMap(
      json,
      const [
        'vehicleType',
        'vehicle_type',
        'typeDetails',
        'categoryDetails',
        'vehicletype',
      ],
    );
    final device = _firstMap(
      json,
      const ['device', 'tracker', 'unit', 'deviceDetails'],
    );
    final primaryUser = _firstMap(
      json,
      const ['primaryUser', 'primary_user', 'user', 'customer', 'owner'],
    );
    final addedBy = _firstMap(
      json,
      const ['addedBy', 'added_by', 'createdBy', 'created_by', 'admin'],
    );

    final plateNumber = _firstString(
          json,
          const [
            'plateNumber',
            'plate_number',
            'plateNo',
            'plate_no',
            'vehicleNumber',
            'vehicle_number',
            'registrationNo',
            'registration_no',
          ],
        ) ??
        '—';
    final resolvedName = _firstString(
          json,
          const ['name', 'vehicleName', 'label', 'title'],
        ) ??
        (plateNumber == '—' ? 'Vehicle' : plateNumber);
    final typeSource = (vehicleType == null
            ? null
            : _firstString(
                vehicleType,
                const [
                  'name',
                  'type',
                  'vehicleType',
                  'vehicle_type',
                  'category',
                  'subtitle',
                  'slug',
                ],
              )) ??
        _firstString(
          json,
          const [
            'vehicleType',
            'vehicle_type',
            'vehicletype',
            'vehicleTypeName',
            'vehicle_type_name',
            'vehicleCategory',
            'vehicle_category',
            'category',
            'iconType',
            'icon_type',
          ],
        ) ??
        resolvedName;
    final statusFlag = _firstBool(
      json,
      const [
        'activeStatus',
        'active_status',
        'isActive',
        'is_active',
        'connected',
        'isConnected',
      ],
    );
    final statusSource = _firstString(
          json,
          const [
            'status',
            'state',
            'vehicleStatus',
            'vehicle_status',
            'connectionStatus',
            'connection_status',
            'statusText',
            'status_text',
            'liveStatus',
            'live_status',
          ],
        ) ??
        (statusFlag == null
            ? null
            : statusFlag
                ? 'active'
                : 'inactive') ??
        'Unknown';

    return SuperadminVehicleRecord(
      id: _firstString(json, const ['id', '_id', 'vehicleId', 'uid', 'imei']) ??
          '',
      name: resolvedName,
      plateNumber: plateNumber,
      type: _normalizeVehicleType(typeSource),
      status: _normalizeVehicleStatus(statusSource),
      imei: _firstString(
            device ?? json,
            const [
              'imei',
              'deviceImei',
              'deviceIMEI',
              'trackerImei',
              'unitImei',
            ],
          ) ??
          '—',
      sim: _firstString(
            device ?? json,
            const [
              'sim',
              'simNo',
              'simNumber',
              'sim_number',
              'mobile',
              'phone',
            ],
          ) ??
          '—',
      primaryUser: _firstString(
            primaryUser ?? json,
            const [
              'name',
              'fullName',
              'displayName',
              'username',
              'userName',
              'mobile',
            ],
          ) ??
          _firstString(
            json,
            const ['primaryUser', 'primary_user', 'assignedTo', 'assigned_to'],
          ) ??
          '—',
      addedBy: _firstString(
            addedBy ?? json,
            const ['name', 'fullName', 'displayName', 'username', 'userName'],
          ) ??
          _firstString(
            json,
            const [
              'addedBy',
              'added_by',
              'createdBy',
              'created_by',
              'adminName',
              'administratorName',
            ],
          ) ??
          '—',
      createdAt: _firstDate(
            json,
            const [
              'createdAt',
              'updatedAt',
              'addedAt',
              'added_at',
              'date',
              'time',
              'lastUpdate',
              'last_update',
            ],
          ) ??
          _firstDate(device ?? json, const ['updatedAt', 'createdAt']),
    );
  }
}

class SuperadminVehicleReplay {
  const SuperadminVehicleReplay({
    required this.imei,
    required this.from,
    required this.to,
    required this.meta,
    required this.points,
  });

  final String imei;
  final DateTime? from;
  final DateTime? to;
  final SuperadminReplayMeta meta;
  final List<SuperadminReplayPoint> points;

  factory SuperadminVehicleReplay.fromJson(dynamic json) {
    final payload = _resolveReplayPayload(json);
    final payloadMap = _asMap(payload);
    final candidateMaps = _replayCandidateMaps(json);
    final points = _parseReplayPoints(json);

    return SuperadminVehicleReplay(
      imei: _firstStringInMaps(candidateMaps, const ['imei']) ?? '',
      from:
          _firstDateInMaps(candidateMaps, const ['from', 'start', 'startTime']),
      to: _firstDateInMaps(candidateMaps, const ['to', 'end', 'endTime']),
      meta: SuperadminReplayMeta.fromJson(
        _firstMap(payloadMap, const ['meta', 'metadata', 'summary']) ??
            _firstMap(_asMap(json), const ['meta', 'metadata', 'summary']) ??
            const <String, dynamic>{},
      ),
      points: points,
    );
  }
}

class SuperadminReplayMeta {
  const SuperadminReplayMeta({
    this.totalRaw,
    this.returned,
    this.bucketSeconds,
  });

  final int? totalRaw;
  final int? returned;
  final int? bucketSeconds;

  factory SuperadminReplayMeta.fromJson(Map<String, dynamic> json) {
    return SuperadminReplayMeta(
      totalRaw: _firstOptionalInt(json, const [
        'totalRaw',
        'total_raw',
        'rawTotal',
        'raw_total',
        'total',
      ]),
      returned: _firstOptionalInt(json, const [
        'returned',
        'pointsReturned',
        'points_returned',
        'count',
      ]),
      bucketSeconds: _firstOptionalInt(json, const [
        'bucketSeconds',
        'bucket_seconds',
        'bucketSec',
        'bucket_sec',
      ]),
    );
  }
}

class SuperadminReplayPoint {
  const SuperadminReplayPoint({
    required this.serverTime,
    required this.deviceTime,
    required this.latitude,
    required this.longitude,
    required this.speedKph,
    required this.course,
    required this.ignition,
    required this.acc,
    required this.odometer,
    required this.distance,
    required this.engineHours,
    required this.totalengineHours,
    required this.satellites,
    required this.attributes,
  });

  final DateTime? serverTime;
  final DateTime? deviceTime;
  final double latitude;
  final double longitude;
  final double? speedKph;
  final double? course;
  final bool? ignition;
  final bool? acc;
  final double? odometer;
  final double? distance;
  final double? engineHours;
  final double? totalengineHours;
  final int? satellites;
  final Map<String, dynamic> attributes;

  DateTime? get effectiveTime => deviceTime ?? serverTime;

  bool get hasCoordinates => _isValidCoordinatePair(latitude, longitude);

  static SuperadminReplayPoint? tryParse(dynamic raw) {
    final source = _asMap(raw);
    if (source.isEmpty) {
      return null;
    }

    final candidateMaps = <Map<String, dynamic>>[
      source,
      _asMap(source['point']),
      _asMap(source['position']),
      _asMap(source['location']),
      _asMap(source['gps']),
      _asMap(source['telemetry']),
      _asMap(source['data']),
      _asMap(source['attributes']),
    ].where((candidate) => candidate.isNotEmpty).toList(growable: false);
    final coordinates = _extractReplayCoordinates(source);
    if (coordinates == null) {
      return null;
    }

    return SuperadminReplayPoint(
      serverTime: _firstDateInMaps(candidateMaps, const [
        'serverTime',
        'server_time',
        'timestamp',
        'time',
        'recordedAt',
        'recorded_at',
        'createdAt',
        'created_at',
      ]),
      deviceTime: _firstDateInMaps(candidateMaps, const [
        'deviceTime',
        'device_time',
        'gpsTime',
        'gps_time',
        'dateTime',
        'datetime',
        'date',
      ]),
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      speedKph: _firstDoubleInMaps(candidateMaps, const [
        'speedKph',
        'speed_kph',
        'speed',
        'gpsSpeed',
        'gps_speed',
      ]),
      course: _firstDoubleInMaps(candidateMaps, const [
        'course',
        'heading',
        'bearing',
        'angle',
        'direction',
      ]),
      ignition: _firstBoolInMaps(candidateMaps, const [
        'ignition',
        'ignitionStatus',
        'ignition_status',
        'engineOn',
        'engine_on',
      ]),
      acc: _firstBoolInMaps(candidateMaps, const [
        'acc',
        'accessory',
        'accessoryOn',
        'accessory_on',
      ]),
      odometer: _firstReplayOdometerKmInMaps(candidateMaps, const [
        'odometer',
        'odometerKm',
        'odometer_km',
        'odometerMeters',
        'odometer_meters',
        'totalOdometer',
        'total_odometer',
        'mileage',
        'mileageKm',
        'mileage_km',
      ]),
      distance: _firstDoubleInMaps(candidateMaps, const [
        'distance',
        'distanceKm',
        'distance_km',
        'tripDistance',
        'trip_distance',
      ]),
      engineHours: _firstReplayEngineHoursInMaps(candidateMaps, const [
        'engineHours',
        'engine_hours',
        'todayEngineHours',
        'today_engine_hours',
        'engineHoursMinutes',
        'engine_hours_minutes',
        'engineHoursSeconds',
        'engine_hours_seconds',
      ]),
      totalengineHours: _firstReplayEngineHoursInMaps(candidateMaps, const [
        'totalengineHours',
        'totalEngineHours',
        'total_engine_hours',
        'engineHoursTotal',
        'engine_hours_total',
        'totalEngineHoursMinutes',
        'total_engine_hours_minutes',
        'totalEngineHoursSeconds',
        'total_engine_hours_seconds',
        'engineHoursMilliseconds',
        'engine_hours_milliseconds',
        'engineHoursMillis',
        'engine_hours_millis',
        'totalEngineHoursMilliseconds',
        'total_engine_hours_milliseconds',
        'totalEngineHoursMillis',
        'total_engine_hours_millis',
        'hours',
      ]),
      satellites: _firstOptionalIntInMaps(candidateMaps, const [
        'satellites',
        'satelliteCount',
        'satellite_count',
        'gpsSatellites',
        'gps_satellites',
      ]),
      attributes: _asMap(source['attributes']),
    );
  }
}

class SuperadminReplayStopMarker {
  const SuperadminReplayStopMarker({
    required this.startIndex,
    required this.endIndex,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  final int startIndex;
  final int endIndex;
  final double latitude;
  final double longitude;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration duration;
}

enum SuperadminVehicleLogSource { api, live }

class SuperadminVehicleLogPage {
  const SuperadminVehicleLogPage({
    required this.items,
    this.nextCursor,
  });

  final List<SuperadminVehicleLog> items;
  final String? nextCursor;

  factory SuperadminVehicleLogPage.fromJson(
    dynamic json, {
    SuperadminVehicleLogSource source = SuperadminVehicleLogSource.api,
  }) {
    final items = _parseVehicleLogs(json, source: source);
    final cursor = _firstStringInMaps(_vehicleLogPageMaps(json), const [
      'nextCursor',
      'next_cursor',
      'cursor',
      'beforeId',
      'before_id',
      'nextBeforeId',
      'next_before_id',
      'lastId',
      'last_id',
    ]);
    final fallbackCursor = items.isEmpty || items.last.id.trim().isEmpty
        ? null
        : items.last.id.trim();

    return SuperadminVehicleLogPage(
      items: items,
      nextCursor: cursor ?? fallbackCursor,
    );
  }
}

class SuperadminVehicleLog {
  const SuperadminVehicleLog({
    required this.id,
    required this.source,
    required this.imei,
    required this.serverTime,
    required this.deviceTime,
    required this.packetType,
    required this.protocol,
    required this.speedKph,
    required this.course,
    required this.ignition,
    required this.acc,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.satellites,
    required this.valid,
    required this.odometer,
    required this.distance,
    required this.engineHours,
    required this.totalEngineHours,
    required this.rawPacket,
    required this.attributes,
    required this.createdAt,
  });

  final String id;
  final SuperadminVehicleLogSource source;
  final String imei;
  final DateTime? serverTime;
  final DateTime? deviceTime;
  final String packetType;
  final String protocol;
  final double? speedKph;
  final double? course;
  final bool? ignition;
  final bool? acc;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final int? satellites;
  final bool? valid;
  final double? odometer;
  final double? distance;
  final double? engineHours;
  final double? totalEngineHours;
  final String rawPacket;
  final Object? attributes;
  final DateTime? createdAt;

  DateTime? get displayTime => serverTime ?? deviceTime ?? createdAt;

  bool get hasDedupeIdentity {
    return serverTime != null || packetType.trim().isNotEmpty;
  }

  String get dedupeKey {
    final time = serverTime?.toUtc().toIso8601String() ?? '';
    return '$time|${packetType.trim()}';
  }

  String get fallbackKey {
    if (id.trim().isNotEmpty) {
      return '${source.name}:id:${id.trim()}';
    }

    final time = displayTime?.toUtc().toIso8601String() ?? '';
    return '${source.name}:$time:${packetType.trim()}:$rawPacket';
  }

  int get sortMilliseconds {
    return displayTime?.toUtc().millisecondsSinceEpoch ?? 0;
  }

  bool get hasCoordinates {
    return _isValidCoordinatePair(latitude, longitude);
  }

  static SuperadminVehicleLog? tryParse(
    dynamic raw, {
    SuperadminVehicleLogSource source = SuperadminVehicleLogSource.api,
  }) {
    final data = _asMap(raw);
    if (data.isEmpty) {
      return null;
    }

    final candidateMaps = <Map<String, dynamic>>[
      data,
      _asMap(data['log']),
      _asMap(data['point']),
      _asMap(data['position']),
      _asMap(data['location']),
      _asMap(data['gps']),
      _asMap(data['telemetry']),
      _asMap(data['data']),
      _asMap(data['attributes']),
    ].where((candidate) => candidate.isNotEmpty).toList(growable: false);
    final coordinates = _extractReplayCoordinates(data);
    final packetType = _firstStringInMaps(candidateMaps, const [
          'packetType',
          'packet_type',
          'type',
          'event',
          'eventType',
          'event_type',
        ]) ??
        '';
    final serverTime = _firstDateInMaps(candidateMaps, const [
      'serverTime',
      'server_time',
      'timestamp',
      'time',
      'recordedAt',
      'recorded_at',
      'createdAt',
      'created_at',
    ]);
    final deviceTime = _firstDateInMaps(candidateMaps, const [
      'deviceTime',
      'device_time',
      'gpsTime',
      'gps_time',
      'dateTime',
      'datetime',
      'date',
    ]);
    final rawPacket = _firstStringInMaps(candidateMaps, const [
          'raw',
          'rawPacket',
          'raw_packet',
          'rawData',
          'raw_data',
          'packet',
          'payload',
          'hex',
        ]) ??
        '';
    final imei = _firstStringInMaps(candidateMaps, const [
          'imei',
          'deviceImei',
          'device_imei',
          'trackerImei',
          'tracker_imei',
        ]) ??
        '';

    if (imei.isEmpty && serverTime == null && packetType.isEmpty) {
      return null;
    }

    return SuperadminVehicleLog(
      id: _firstStringInMaps(candidateMaps, const [
            'id',
            '_id',
            'logId',
            'log_id',
            'telemetryId',
            'telemetry_id',
          ]) ??
          '',
      source: source,
      imei: imei,
      serverTime: serverTime,
      deviceTime: deviceTime,
      packetType: packetType,
      protocol: _firstStringInMaps(candidateMaps, const [
            'protocol',
            'deviceProtocol',
            'device_protocol',
          ]) ??
          '',
      speedKph: _firstDoubleInMaps(candidateMaps, const [
        'speedKph',
        'speed_kph',
        'speed',
        'vehicleSpeed',
        'vehicle_speed',
        'gpsSpeed',
        'gps_speed',
      ]),
      course: _firstDoubleInMaps(candidateMaps, const [
        'course',
        'heading',
        'bearing',
        'angle',
        'direction',
      ]),
      ignition: _firstBoolInMaps(candidateMaps, const [
        'ignition',
        'ignitionStatus',
        'ignition_status',
        'engineOn',
        'engine_on',
      ]),
      acc: _firstBoolInMaps(candidateMaps, const [
        'acc',
        'accessory',
        'accessoryOn',
        'accessory_on',
      ]),
      latitude: coordinates?.latitude,
      longitude: coordinates?.longitude,
      altitude: _firstDoubleInMaps(candidateMaps, const [
        'altitude',
        'alt',
      ]),
      satellites: _firstOptionalIntInMaps(candidateMaps, const [
        'satellites',
        'satelliteCount',
        'satellite_count',
        'gpsSatellites',
        'gps_satellites',
      ]),
      valid: _firstBoolInMaps(candidateMaps, const [
        'valid',
        'isValid',
        'is_valid',
        'gpsValid',
        'gps_valid',
      ]),
      odometer: _firstReplayOdometerKmInMaps(candidateMaps, const [
        'odometer',
        'odometerKm',
        'odometer_km',
        'odometerMeters',
        'odometer_meters',
        'totalOdometer',
        'total_odometer',
        'mileage',
        'mileageKm',
        'mileage_km',
      ]),
      distance: _firstDoubleInMaps(candidateMaps, const [
        'distance',
        'distanceKm',
        'distance_km',
        'distanceToday',
        'distance_today',
        'todayDistance',
        'today_distance',
        'tripDistance',
        'trip_distance',
      ]),
      engineHours: _firstReplayEngineHoursInMaps(candidateMaps, const [
        'engineHours',
        'engine_hours',
        'todayEngineHours',
        'today_engine_hours',
        'engineHoursToday',
        'engine_hours_today',
      ]),
      totalEngineHours: _firstReplayEngineHoursInMaps(candidateMaps, const [
        'totalengineHours',
        'totalEngineHours',
        'total_engine_hours',
        'engineHoursTotal',
        'engine_hours_total',
        'hours',
      ]),
      rawPacket: rawPacket,
      attributes: _firstExistingValueInMaps(candidateMaps, const [
        'attributes',
        'attrs',
        'attr',
      ]),
      createdAt: _firstDateInMaps(candidateMaps, const [
        'createdAt',
        'created_at',
        'insertedAt',
        'inserted_at',
      ]),
    );
  }
}

List<SuperadminVehicleLog> mergeSuperadminVehicleLogs({
  required List<SuperadminVehicleLog> current,
  required Iterable<SuperadminVehicleLog> incoming,
  String? imei,
  int cap = 500,
  bool incomingFirst = true,
}) {
  final selectedImei = imei?.trim() ?? '';
  final source = incomingFirst
      ? <SuperadminVehicleLog>[...incoming, ...current]
      : <SuperadminVehicleLog>[...current, ...incoming];
  final seen = <String>{};
  final merged = <SuperadminVehicleLog>[];

  for (final log in source) {
    if (selectedImei.isNotEmpty && log.imei.trim() != selectedImei) {
      continue;
    }

    final key = log.hasDedupeIdentity ? log.dedupeKey : log.fallbackKey;
    if (!seen.add(key)) {
      continue;
    }

    merged.add(log);
  }

  merged.sort((left, right) {
    final timeComparison = right.sortMilliseconds.compareTo(
      left.sortMilliseconds,
    );
    if (timeComparison != 0) {
      return timeComparison;
    }

    return right.fallbackKey.compareTo(left.fallbackKey);
  });

  if (merged.length <= cap) {
    return merged;
  }

  return merged.take(cap).toList(growable: false);
}

class SuperadminVehicleEventPage {
  const SuperadminVehicleEventPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });

  final List<AppNotification> items;
  final String? nextCursor;
  final bool hasMore;

  factory SuperadminVehicleEventPage.fromJson(
    dynamic json, {
    String? imei,
    int requestedLimit = 50,
  }) {
    final items = mergeSuperadminVehicleEvents(
      current: const <AppNotification>[],
      incoming: _parseVehicleEvents(json),
      imei: imei,
    );
    final pageMaps = _vehicleEventPageMaps(json);
    final explicitCursor = _firstStringInMaps(pageMaps, const [
      'nextCursor',
      'next_cursor',
      'cursor',
      'beforeId',
      'before_id',
      'nextBeforeId',
      'next_before_id',
      'lastId',
      'last_id',
    ]);
    final explicitHasMore = _firstBoolInMaps(pageMaps, const [
      'hasMore',
      'has_more',
      'more',
    ]);
    final hasMore = explicitHasMore ??
        (requestedLimit > 0 && items.length >= requestedLimit);
    final fallbackCursor =
        hasMore && items.isNotEmpty ? _vehicleEventCursor(items.last) : null;

    return SuperadminVehicleEventPage(
      items: items,
      nextCursor: explicitCursor ?? fallbackCursor,
      hasMore: hasMore,
    );
  }
}

List<AppNotification> mergeSuperadminVehicleEvents({
  required List<AppNotification> current,
  required Iterable<AppNotification> incoming,
  String? imei,
  int cap = 300,
  bool incomingFirst = true,
}) {
  final selectedImei = imei?.trim() ?? '';
  final source = incomingFirst
      ? <AppNotification>[...incoming, ...current]
      : <AppNotification>[...current, ...incoming];
  final seen = <String>{};
  final merged = <AppNotification>[];

  for (final event in source) {
    final eventImei = event.vehicleImei?.trim() ?? '';
    if (selectedImei.isNotEmpty && eventImei != selectedImei) {
      continue;
    }

    final key = event.dedupeIdentity;
    if (!seen.add(key)) {
      continue;
    }

    merged.add(event);
  }

  merged.sort((left, right) {
    final timeComparison = right.sortMilliseconds.compareTo(
      left.sortMilliseconds,
    );
    if (timeComparison != 0) {
      return timeComparison;
    }

    final idComparison = right.id.compareTo(left.id);
    if (idComparison != 0) {
      return idComparison;
    }

    return right.dedupeIdentity.compareTo(left.dedupeIdentity);
  });

  if (merged.length <= cap) {
    return merged;
  }

  return merged.take(cap).toList(growable: false);
}

class SuperadminCustomCommand {
  const SuperadminCustomCommand({
    required this.id,
    required this.command,
    required this.isActive,
    this.deviceTypeId,
    this.commandTypeId,
    this.commandTypeName,
    this.commandTypeDescription,
    this.deviceTypeName,
    String? protocol,
    String? deviceProtocol,
  }) : protocol = protocol ?? deviceProtocol;

  final String id;
  final String command;
  final bool isActive;
  final int? deviceTypeId;
  final int? commandTypeId;
  final String? commandTypeName;
  final String? commandTypeDescription;
  final String? deviceTypeName;
  final String? protocol;

  String? get deviceProtocol => protocol;

  String get displayTitle {
    final type = commandTypeName?.trim() ?? '';
    if (type.isNotEmpty) {
      return type;
    }

    final text = command.trim();
    return text.isEmpty ? 'Command' : text;
  }

  String get displaySubtitle {
    final device = deviceTypeName?.trim() ?? '';
    final protocolValue = protocol?.trim() ?? '';
    final parts = <String>[
      if (device.isNotEmpty) device,
      if (protocolValue.isNotEmpty) protocolValue,
    ];
    return parts.join(' · ');
  }

  static SuperadminCustomCommand? tryParse(dynamic raw) {
    final source = _asMap(raw);
    if (source.isEmpty) {
      return null;
    }

    final command = _firstString(source, const [
          'command',
          'payload',
          'text',
          'template',
          'commandText',
          'command_text',
        ]) ??
        '';
    if (command.trim().isEmpty) {
      return null;
    }

    final commandType = _asMap(source['commandType']);
    final deviceType = _asMap(source['deviceType']);

    return SuperadminCustomCommand(
      id: _firstString(source, const [
            'id',
            '_id',
            'commandId',
            'command_id',
          ]) ??
          command,
      command: command,
      isActive: _firstBool(source, const [
            'isActive',
            'is_active',
            'active',
            'enabled',
          ]) ??
          true,
      deviceTypeId: _firstOptionalInt(source, const [
            'deviceTypeId',
            'device_type_id',
          ]) ??
          _firstOptionalInt(deviceType, const ['id']),
      commandTypeId: _firstOptionalInt(source, const [
            'commandTypeId',
            'command_type_id',
          ]) ??
          _firstOptionalInt(commandType, const ['id']),
      commandTypeName: _firstString(commandType, const [
            'name',
            'title',
            'label',
          ]) ??
          _firstString(source, const [
            'commandTypeName',
            'command_type_name',
            'typeName',
            'type_name',
          ]),
      commandTypeDescription: _firstString(commandType, const [
            'description',
            'details',
          ]) ??
          _firstString(source, const [
            'commandTypeDescription',
            'command_type_description',
          ]),
      deviceTypeName: _firstString(deviceType, const [
            'name',
            'title',
            'label',
          ]) ??
          _firstString(source, const [
            'deviceTypeName',
            'device_type_name',
          ]),
      protocol: _firstString(deviceType, const [
            'protocol',
            'protocolName',
            'protocol_name',
          ]) ??
          _firstString(source, const [
            'protocol',
            'protocolName',
            'protocol_name',
          ]),
    );
  }
}

class SuperadminSystemVariable {
  const SuperadminSystemVariable({
    required this.id,
    required this.key,
    required this.name,
    required this.value,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String key;
  final String name;
  final String value;
  final String? description;
  final bool isActive;

  String get initialValue => value;

  static SuperadminSystemVariable? tryParse(dynamic raw) {
    final source = _asMap(raw);
    if (source.isEmpty) {
      return null;
    }

    final key = _firstString(source, const [
      'key',
      'variableKey',
      'variable_key',
      'code',
      'slug',
    ]);
    final name = _firstString(source, const [
          'name',
          'label',
          'title',
          'variable',
          'variableName',
          'variable_name',
        ]) ??
        key ??
        '';
    if (name.trim().isEmpty && (key?.trim().isEmpty ?? true)) {
      return null;
    }

    return SuperadminSystemVariable(
      id: _firstString(source, const ['id', '_id', 'uid']) ?? key ?? name,
      key: key ?? name,
      name: name,
      value: _firstString(source, const [
            'value',
            'initialValue',
            'initial_value',
            'defaultValue',
            'default_value',
            'displayValue',
            'display_value',
          ]) ??
          '',
      description: _firstString(source, const [
        'description',
        'details',
        'helpText',
        'help_text',
      ]),
      isActive: _firstBool(source, const [
            'isActive',
            'is_active',
            'active',
            'enabled',
          ]) ??
          true,
    );
  }
}

class SuperadminSendCommandResult {
  const SuperadminSendCommandResult({
    this.cmdId,
    this.connected,
    this.queued,
    this.queueId,
    this.requestedAt,
    this.createdAt,
    this.message,
    this.status,
  });

  final String? cmdId;
  final bool? connected;
  final bool? queued;
  final String? queueId;
  final DateTime? requestedAt;
  final DateTime? createdAt;
  final String? message;
  final String? status;

  bool get wasQueued => queued == true || connected == false;

  String get localStatus {
    final explicit = status?.trim() ?? '';
    if (explicit.isNotEmpty) {
      return _normalizeCommandStatus(explicit);
    }

    if (wasQueued) {
      return 'QUEUED';
    }

    if (connected == true) {
      return 'SENT';
    }

    return 'REQUESTED';
  }

  factory SuperadminSendCommandResult.fromJson(dynamic json) {
    final maps = _commandCandidateMaps(json);
    return SuperadminSendCommandResult(
      cmdId: _firstStringInMaps(maps, const [
        'cmdId',
        'cmd_id',
        'commandId',
        'command_id',
      ]),
      connected: _firstBoolInMaps(maps, const [
        'connected',
        'isConnected',
        'is_connected',
      ]),
      queued: _firstBoolInMaps(maps, const [
        'queued',
        'isQueued',
        'is_queued',
      ]),
      queueId: _firstStringInMaps(maps, const [
        'queueId',
        'queue_id',
      ]),
      requestedAt: _firstDateInMaps(maps, const [
        'requestedAt',
        'requested_at',
      ]),
      createdAt: _firstDateInMaps(maps, const [
        'createdAt',
        'created_at',
        'created',
      ]),
      message: _firstStringInMaps(maps, const [
        'message',
        'msg',
      ]),
      status: _firstStringInMaps(maps, const [
        'status',
        'state',
      ]),
    );
  }
}

typedef SuperadminSendCommandResponse = SuperadminSendCommandResult;

class SuperadminCommandHistoryPage {
  const SuperadminCommandHistoryPage({
    required this.items,
    this.nextCursorId,
    this.hasMore = false,
  });

  final List<SuperadminCommandHistoryItem> items;
  final String? nextCursorId;
  final bool hasMore;

  factory SuperadminCommandHistoryPage.fromJson(dynamic json) {
    final items = _parseVehicleCommands(json);
    final pageMaps = _vehicleCommandPageMaps(json);
    final nextCursor = _firstStringInMaps(pageMaps, const [
      'nextCursorId',
      'next_cursor_id',
      'nextCursor',
      'next_cursor',
      'cursorId',
      'cursor_id',
      'cursor',
    ]);

    return SuperadminCommandHistoryPage(
      items: items,
      nextCursorId: nextCursor,
      hasMore: _firstBoolInMaps(pageMaps, const [
            'hasMore',
            'has_more',
            'more',
          ]) ??
          (nextCursor != null && nextCursor.isNotEmpty),
    );
  }
}

typedef SuperadminVehicleCommandPage = SuperadminCommandHistoryPage;

class SuperadminCommandHistoryItem {
  const SuperadminCommandHistoryItem({
    required this.id,
    required this.cmdId,
    required this.imei,
    required this.command,
    required this.status,
    this.vehicleId,
    this.requestedByRole,
    this.transport,
    this.source,
    this.queueId,
    this.connectedAtSend,
    this.requestedAt,
    this.queuedAt,
    this.sentAt,
    this.respondedAt,
    this.failedAt,
    this.timeoutAt,
    this.createdAt,
    this.responseRaw,
    this.responseHex,
    this.errorMessage,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String cmdId;
  final String imei;
  final String command;
  final String status;
  final int? vehicleId;
  final String? requestedByRole;
  final String? transport;
  final String? source;
  final String? queueId;
  final bool? connectedAtSend;
  final DateTime? requestedAt;
  final DateTime? queuedAt;
  final DateTime? sentAt;
  final DateTime? respondedAt;
  final DateTime? failedAt;
  final DateTime? timeoutAt;
  final DateTime? createdAt;
  final String? responseRaw;
  final String? responseHex;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  DateTime? get displayTime {
    return respondedAt ??
        timeoutAt ??
        failedAt ??
        sentAt ??
        queuedAt ??
        requestedAt ??
        createdAt;
  }

  bool get hasDeviceResponse {
    return (responseRaw?.trim().isNotEmpty ?? false) ||
        (responseHex?.trim().isNotEmpty ?? false);
  }

  String get identity {
    final normalizedCmdId = cmdId.trim();
    if (normalizedCmdId.isNotEmpty) {
      return 'cmd:$normalizedCmdId';
    }

    final normalizedId = id.trim();
    if (normalizedId.isNotEmpty) {
      return 'id:$normalizedId';
    }

    return 'local:${command.trim()}:${displayTime?.toUtc().toIso8601String() ?? ''}';
  }

  SuperadminCommandHistoryItem copyWith({
    String? status,
    Object? responseRaw = _commandUnset,
    Object? responseHex = _commandUnset,
    Object? errorMessage = _commandUnset,
    Object? requestedAt = _commandUnset,
    Object? queuedAt = _commandUnset,
    Object? sentAt = _commandUnset,
    Object? respondedAt = _commandUnset,
    Object? failedAt = _commandUnset,
    Object? timeoutAt = _commandUnset,
  }) {
    return SuperadminCommandHistoryItem(
      id: id,
      cmdId: cmdId,
      imei: imei,
      command: command,
      status: status ?? this.status,
      vehicleId: vehicleId,
      requestedByRole: requestedByRole,
      transport: transport,
      source: source,
      queueId: queueId,
      connectedAtSend: connectedAtSend,
      requestedAt: identical(requestedAt, _commandUnset)
          ? this.requestedAt
          : requestedAt as DateTime?,
      queuedAt: identical(queuedAt, _commandUnset)
          ? this.queuedAt
          : queuedAt as DateTime?,
      sentAt:
          identical(sentAt, _commandUnset) ? this.sentAt : sentAt as DateTime?,
      respondedAt: identical(respondedAt, _commandUnset)
          ? this.respondedAt
          : respondedAt as DateTime?,
      failedAt: identical(failedAt, _commandUnset)
          ? this.failedAt
          : failedAt as DateTime?,
      timeoutAt: identical(timeoutAt, _commandUnset)
          ? this.timeoutAt
          : timeoutAt as DateTime?,
      createdAt: createdAt,
      responseRaw: identical(responseRaw, _commandUnset)
          ? this.responseRaw
          : responseRaw as String?,
      responseHex: identical(responseHex, _commandUnset)
          ? this.responseHex
          : responseHex as String?,
      errorMessage: identical(errorMessage, _commandUnset)
          ? this.errorMessage
          : errorMessage as String?,
      metadata: metadata,
    );
  }

  static SuperadminCommandHistoryItem? tryParse(dynamic raw) {
    final source = _asMap(raw);
    if (source.isEmpty) {
      return null;
    }

    final maps = _commandCandidateMaps(raw);
    final command = _firstStringInMaps(maps, const [
          'command',
          'payload',
          'commandText',
          'command_text',
          'text',
        ]) ??
        '';
    final cmdId = _firstStringInMaps(maps, const [
          'cmdId',
          'cmd_id',
          'commandId',
          'command_id',
        ]) ??
        '';
    final id = _firstStringInMaps(maps, const [
          'id',
          '_id',
          'logId',
          'log_id',
        ]) ??
        '';
    final status = _firstStringInMaps(maps, const [
          'status',
          'state',
        ]) ??
        '';

    if (command.trim().isEmpty && cmdId.trim().isEmpty && id.trim().isEmpty) {
      return null;
    }

    final metadata = _asMap(
      _firstExistingValueInMaps(maps, const ['metadata', 'meta']),
    );

    return SuperadminCommandHistoryItem(
      id: id,
      cmdId: cmdId,
      imei: _firstStringInMaps(maps, const [
            'imei',
            'deviceImei',
            'device_imei',
          ]) ??
          '',
      command: command,
      status: _normalizeCommandStatus(status),
      vehicleId: _firstOptionalIntInMaps(maps, const [
        'vehicleId',
        'vehicle_id',
      ]),
      requestedByRole: _firstStringInMaps(maps, const [
        'requestedByRole',
        'requested_by_role',
        'role',
      ]),
      transport: _firstStringInMaps(maps, const ['transport']),
      source: _firstStringInMaps(maps, const ['source']),
      queueId: _firstStringInMaps(maps, const [
        'queueId',
        'queue_id',
      ]),
      connectedAtSend: _firstBoolInMaps(maps, const [
        'connectedAtSend',
        'connected_at_send',
        'connected',
      ]),
      requestedAt: _firstDateInMaps(maps, const [
        'requestedAt',
        'requested_at',
      ]),
      queuedAt: _firstDateInMaps(maps, const [
        'queuedAt',
        'queued_at',
      ]),
      sentAt: _firstDateInMaps(maps, const [
        'sentAt',
        'sent_at',
      ]),
      respondedAt: _firstDateInMaps(maps, const [
        'respondedAt',
        'responded_at',
      ]),
      failedAt: _firstDateInMaps(maps, const [
        'failedAt',
        'failed_at',
      ]),
      timeoutAt: _firstDateInMaps(maps, const [
        'timeoutAt',
        'timeout_at',
      ]),
      createdAt: _firstDateInMaps(maps, const [
        'createdAt',
        'created_at',
        'created',
      ]),
      responseRaw: _firstStringInMaps(maps, const [
        'responseRaw',
        'response_raw',
        'response',
        'responseText',
        'response_text',
      ]),
      responseHex: _firstStringInMaps(maps, const [
        'responseHex',
        'response_hex',
      ]),
      errorMessage: _firstStringInMaps(maps, const [
        'errorMessage',
        'error_message',
        'error',
      ]),
      metadata: metadata,
    );
  }
}

typedef SuperadminVehicleCommandEntry = SuperadminCommandHistoryItem;

class SuperadminCommandStatus extends SuperadminCommandHistoryItem {
  const SuperadminCommandStatus({
    required super.cmdId,
    required super.imei,
    required super.command,
    required super.status,
    super.requestedAt,
    super.queuedAt,
    super.sentAt,
    super.respondedAt,
    super.failedAt,
    super.timeoutAt,
    super.responseRaw,
    super.responseHex,
    super.errorMessage,
    super.queueId,
  }) : super(
          id: '',
        );

  static SuperadminCommandStatus? tryParse(dynamic raw) {
    final item = SuperadminCommandHistoryItem.tryParse(raw);
    if (item == null) {
      return null;
    }

    return SuperadminCommandStatus(
      cmdId: item.cmdId,
      imei: item.imei,
      command: item.command,
      status: item.status,
      requestedAt: item.requestedAt,
      queuedAt: item.queuedAt,
      sentAt: item.sentAt,
      respondedAt: item.respondedAt,
      failedAt: item.failedAt,
      timeoutAt: item.timeoutAt,
      responseRaw: item.responseRaw,
      responseHex: item.responseHex,
      errorMessage: item.errorMessage,
      queueId: item.queueId,
    );
  }
}

const Object _commandUnset = Object();

const Set<String> superadminCommandStatusValues = <String>{
  'REQUESTED',
  'QUEUED',
  'QUEUED_OFFLINE',
  'SENT',
  'DELIVERED',
  'RESPONDED',
  'ENCODE_FAILED',
  'FAILED',
  'TIMEOUT',
  'ERROR',
};

String _normalizeCommandStatus(String? status) {
  final trimmed = status?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'REQUESTED';
  }

  final upper = trimmed.toUpperCase();
  return upper;
}

List<SuperadminCustomCommand> parseSuperadminCustomCommands(dynamic json) {
  final commands = <SuperadminCustomCommand>[];
  for (final candidate in _customCommandListCandidates(json)) {
    final list = _asCustomCommandList(candidate);
    if (list == null || list.isEmpty) {
      continue;
    }

    commands.addAll(
      list
          .map(SuperadminCustomCommand.tryParse)
          .whereType<SuperadminCustomCommand>(),
    );
    if (commands.isNotEmpty) {
      return commands;
    }
  }

  final single = SuperadminCustomCommand.tryParse(json);
  return single == null ? const <SuperadminCustomCommand>[] : [single];
}

List<SuperadminSystemVariable> parseSuperadminSystemVariables(dynamic json) {
  final variables = <SuperadminSystemVariable>[];
  for (final candidate in _systemVariableListCandidates(json)) {
    final list = _asSystemVariableList(candidate);
    if (list == null || list.isEmpty) {
      continue;
    }

    variables.addAll(
      list
          .map(SuperadminSystemVariable.tryParse)
          .whereType<SuperadminSystemVariable>(),
    );
    if (variables.isNotEmpty) {
      return variables;
    }
  }

  final single = SuperadminSystemVariable.tryParse(json);
  return single == null ? const <SuperadminSystemVariable>[] : [single];
}

class SuperadminVehicleSensorPage {
  const SuperadminVehicleSensorPage({
    required this.items,
    required this.totalCount,
    this.truncated = false,
    this.telemetryMeta,
  });

  final List<SuperadminVehicleSensor> items;
  final int totalCount;
  final bool truncated;
  final SuperadminVehicleSensorTelemetryMeta? telemetryMeta;

  factory SuperadminVehicleSensorPage.fromJson(dynamic json) {
    final items = _parseVehicleSensors(json);
    final pageMaps = _vehicleSensorPageMaps(json);
    final totalCount = _firstOptionalIntInMaps(pageMaps, const [
          'totalCount',
          'total_count',
          'count',
          'total',
          'sensorCount',
          'sensor_count',
        ]) ??
        items.length;

    return SuperadminVehicleSensorPage(
      items: items,
      totalCount: totalCount,
      truncated: _firstBoolInMaps(pageMaps, const [
            'truncated',
            'isTruncated',
            'is_truncated',
          ]) ??
          false,
      telemetryMeta: _parseVehicleSensorTelemetryMeta(json),
    );
  }
}

class SuperadminVehicleSensorTelemetryMeta {
  const SuperadminVehicleSensorTelemetryMeta({
    required this.hasTelemetry,
    this.serverTime,
    this.deviceTime,
  });

  final bool hasTelemetry;
  final DateTime? serverTime;
  final DateTime? deviceTime;
}

class SuperadminVehicleSensor {
  const SuperadminVehicleSensor({
    required this.id,
    required this.name,
    required this.type,
    required this.latestValue,
    required this.status,
    required this.isOk,
    this.unit,
    this.sourceKey,
    this.expression,
    this.description,
    this.icon,
    this.lastUpdated,
    this.computeDurationMs,
  });

  final String id;
  final String name;
  final String type;
  final String latestValue;
  final String status;
  final bool isOk;
  final String? unit;
  final String? sourceKey;
  final String? expression;
  final String? description;
  final String? icon;
  final DateTime? lastUpdated;
  final double? computeDurationMs;

  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    final source = sourceKey?.trim() ?? '';
    return source.isEmpty ? 'Sensor' : source;
  }

  String get displayType {
    final trimmed = type.trim();
    return trimmed.isEmpty ? 'sensor' : trimmed;
  }

  String get displayValue {
    final trimmed = latestValue.trim();
    return trimmed.isEmpty ? '--' : trimmed;
  }

  String get displayStatus {
    final trimmed = status.trim();
    return trimmed.isEmpty ? (isOk ? 'OK' : 'Unavailable') : trimmed;
  }

  String? get sourceExpression {
    final source = sourceKey?.trim() ?? '';
    if (source.isNotEmpty) {
      return source;
    }

    final expressionText = expression?.trim() ?? '';
    return expressionText.isEmpty ? null : expressionText;
  }

  SuperadminVehicleSensor copyWith({
    String? latestValue,
    String? status,
    bool? isOk,
    Object? lastUpdated = _sensorUnset,
  }) {
    return SuperadminVehicleSensor(
      id: id,
      name: name,
      type: type,
      latestValue: latestValue ?? this.latestValue,
      status: status ?? this.status,
      isOk: isOk ?? this.isOk,
      unit: unit,
      sourceKey: sourceKey,
      expression: expression,
      description: description,
      icon: icon,
      lastUpdated: identical(lastUpdated, _sensorUnset)
          ? this.lastUpdated
          : lastUpdated as DateTime?,
      computeDurationMs: computeDurationMs,
    );
  }

  static SuperadminVehicleSensor? tryParse(dynamic raw) {
    final source = _asMap(raw);
    if (source.isEmpty) {
      return null;
    }

    final computed = _asMap(source['computed']);
    final config = _asMap(source['config']);
    final metadata = _asMap(source['metadata']);
    final meta = _asMap(source['meta']);
    final candidateMaps = <Map<String, dynamic>>[
      source,
      computed,
      config,
      metadata,
      meta,
    ].where((candidate) => candidate.isNotEmpty).toList(growable: false);
    final name = _firstStringInMaps(candidateMaps, const [
          'name',
          'label',
          'title',
          'sensorName',
          'sensor_name',
        ]) ??
        '';
    final sourceKey = _firstStringInMaps(candidateMaps, const [
      'rawAttribute',
      'raw_attribute',
      'sourceKey',
      'source_key',
      'telemetryKey',
      'telemetry_key',
      'attribute',
      'attributeKey',
      'attribute_key',
      'key',
      'path',
    ]);
    final expression = _firstStringInMaps(candidateMaps, const [
      'expression',
      'formula',
      'sourceExpression',
      'source_expression',
    ]);

    if (name.trim().isEmpty &&
        (sourceKey?.trim().isEmpty ?? true) &&
        (expression?.trim().isEmpty ?? true)) {
      return null;
    }

    final latestValue = _sensorDisplayValue(
      _firstExistingValueInMaps(candidateMaps, const [
        'displayValue',
        'display_value',
        'latestValue',
        'latest_value',
        'currentValue',
        'current_value',
        'rawValue',
        'raw_value',
        'value',
        'result',
      ]),
    );
    final explicitStatus = _firstStringInMaps(candidateMaps, const [
      'status',
      'state',
      'health',
    ]);
    final isOk = _firstBoolInMaps(candidateMaps, const [
          'ok',
          'isOk',
          'is_ok',
          'healthy',
          'active',
          'enabled',
        ]) ??
        !((explicitStatus ?? '').toLowerCase().contains('error'));
    final error = _firstStringInMaps(candidateMaps, const [
      'error',
      'errorMessage',
      'error_message',
    ]);

    return SuperadminVehicleSensor(
      id: _firstStringInMaps(candidateMaps, const [
            'id',
            '_id',
            'sensorId',
            'sensor_id',
            'uid',
          ]) ??
          '',
      name: name,
      type: _firstStringInMaps(candidateMaps, const [
            'type',
            'dataType',
            'data_type',
            'sensorType',
            'sensor_type',
          ]) ??
          '',
      latestValue: latestValue,
      status: explicitStatus ??
          (isOk
              ? 'OK'
              : (error?.trim().isNotEmpty ?? false)
                  ? 'Error'
                  : 'Unavailable'),
      isOk: isOk,
      unit: _firstStringInMaps(candidateMaps, const [
        'unit',
        'units',
        'suffix',
      ]),
      sourceKey: sourceKey,
      expression: expression,
      description: _firstStringInMaps(candidateMaps, const [
        'description',
        'details',
        'note',
      ]),
      icon: _firstStringInMaps(candidateMaps, const [
        'icon',
        'iconKey',
        'icon_key',
      ]),
      lastUpdated: _firstDateInMaps(candidateMaps, const [
        'updatedAt',
        'updated_at',
        'lastUpdated',
        'last_updated',
        'lastUpdatedAt',
        'last_updated_at',
        'serverTime',
        'server_time',
        'timestamp',
      ]),
      computeDurationMs: _firstDoubleInMaps(candidateMaps, const [
        'ms',
        'durationMs',
        'duration_ms',
        'computeMs',
        'compute_ms',
      ]),
    );
  }
}

const Object _sensorUnset = Object();

List<SuperadminVehicleSensor> updateSuperadminVehicleSensorsWithTelemetry({
  required List<SuperadminVehicleSensor> sensors,
  required Map<String, Object?> telemetry,
  DateTime? updatedAt,
}) {
  if (sensors.isEmpty || telemetry.isEmpty) {
    return sensors;
  }

  final normalizedTelemetry = <String, Object?>{};
  for (final entry in telemetry.entries) {
    final normalizedKey = _normalizedTelemetryKey(entry.key);
    if (normalizedKey.isNotEmpty && entry.value != null) {
      normalizedTelemetry[normalizedKey] = entry.value;
    }
  }

  if (normalizedTelemetry.isEmpty) {
    return sensors;
  }

  var changed = false;
  final updatedSensors = <SuperadminVehicleSensor>[];
  for (final sensor in sensors) {
    final value = _telemetryValueForSensor(sensor, normalizedTelemetry);
    if (value == null) {
      updatedSensors.add(sensor);
      continue;
    }

    final displayValue = _sensorDisplayValue(value);
    if (displayValue == sensor.latestValue && updatedAt == sensor.lastUpdated) {
      updatedSensors.add(sensor);
      continue;
    }

    changed = true;
    updatedSensors.add(
      sensor.copyWith(
        latestValue: displayValue,
        status: 'Live',
        isOk: true,
        lastUpdated: updatedAt ?? sensor.lastUpdated,
      ),
    );
  }

  return changed ? updatedSensors : sensors;
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
    final map = _asMap(source[key]);
    if (map.isNotEmpty) {
      return map;
    }
  }

  return null;
}

List<dynamic>? _firstList(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is List) {
      return value;
    }
  }

  return null;
}

String? _firstString(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (value is num) {
      return value.toString();
    }
  }

  return null;
}

bool? _firstBool(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is bool) {
      return value;
    }

    if (value is num) {
      if (value == 1) {
        return true;
      }
      if (value == 0) {
        return false;
      }
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'active' ||
          normalized == 'online') {
        return true;
      }
      if (normalized == 'false' ||
          normalized == '0' ||
          normalized == 'no' ||
          normalized == 'inactive' ||
          normalized == 'offline') {
        return false;
      }
    }
  }

  return null;
}

int _firstInt(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return 0;
}

int? _firstOptionalInt(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final trimmed = value.trim();
      final parsed = int.tryParse(trimmed) ?? double.tryParse(trimmed)?.toInt();
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return null;
}

int? _firstOptionalIntInMaps(
  List<Map<String, dynamic>> sources,
  List<String> keys,
) {
  for (final source in sources) {
    final value = _firstOptionalInt(source, keys);
    if (value != null) {
      return value;
    }
  }

  return null;
}

double? _firstDouble(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = _asDouble(source[key]);
    if (value != null) {
      return value;
    }
  }

  return null;
}

double? _firstDoubleInMaps(
  List<Map<String, dynamic>> sources,
  List<String> keys,
) {
  for (final source in sources) {
    final value = _firstDouble(source, keys);
    if (value != null) {
      return value;
    }
  }

  return null;
}

double? _firstReplayOdometerKmInMaps(
  List<Map<String, dynamic>> sources,
  List<String> keys,
) {
  final candidates = <({double value, int score})>[];
  for (var sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
    final source = sources[sourceIndex];
    for (final key in keys) {
      final value = _asDouble(source[key]);
      if (value != null) {
        final normalizedValue = _normalizeReplayOdometerKm(key, value);
        if (!normalizedValue.isFinite || normalizedValue <= 0) {
          continue;
        }

        candidates.add((
          value: normalizedValue,
          score: _replayOdometerCandidateScore(
            key: key,
            value: normalizedValue,
            sourceIndex: sourceIndex,
          ),
        ));
      }
    }
  }

  if (candidates.isEmpty) {
    return null;
  }

  candidates.sort((left, right) {
    final scoreComparison = right.score.compareTo(left.score);
    if (scoreComparison != 0) {
      return scoreComparison;
    }

    return right.value.compareTo(left.value);
  });

  return candidates.first.value;
}

double _normalizeReplayOdometerKm(String key, double value) {
  final normalizedKey = _normalizedTelemetryKey(key);
  if (normalizedKey.endsWith('meters')) {
    return value / 1000;
  }

  if (normalizedKey.contains('km')) {
    return value;
  }

  return value;
}

int _replayOdometerCandidateScore({
  required String key,
  required double value,
  required int sourceIndex,
}) {
  final normalizedKey = _normalizedTelemetryKey(key);
  var score = 0;

  if (normalizedKey == 'odometer' ||
      normalizedKey == 'odometerkm' ||
      normalizedKey == 'mileage' ||
      normalizedKey == 'mileagekm') {
    score += 30;
  } else if (normalizedKey.contains('odometer') ||
      normalizedKey.contains('mileage')) {
    score += 25;
  }

  if (value < 5) {
    score -= 30;
  } else if (value < 20) {
    score -= 10;
  } else if (value >= 100) {
    score += 12;
  } else {
    score += 4;
  }

  return score - sourceIndex;
}

double? _firstReplayEngineHoursInMaps(
  List<Map<String, dynamic>> sources,
  List<String> keys,
) {
  for (final source in sources) {
    for (final key in keys) {
      final value = _asEngineHours(source[key]);
      if (value != null) {
        return _normalizeReplayEngineHours(key, value);
      }
    }
  }

  return null;
}

double _normalizeReplayEngineHours(String key, double value) {
  final normalizedKey = _normalizedTelemetryKey(key);
  if (normalizedKey == 'hours' ||
      normalizedKey.contains('millisecond') ||
      normalizedKey.contains('millis')) {
    return value / 3600000;
  }

  if (normalizedKey.contains('second')) {
    return value / 3600;
  }

  if (normalizedKey.contains('minute')) {
    return value / 60;
  }

  return value;
}

double? _asEngineHours(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final durationHours = _parseEngineHoursDuration(trimmed);
    if (durationHours != null) {
      return durationHours;
    }
  }

  return _asDouble(value);
}

double? _parseEngineHoursDuration(String value) {
  var totalHours = 0.0;
  var matched = false;
  final pattern = RegExp(
    r'(\d+(?:\.\d+)?)\s*(d|day|days|h|hr|hrs|hour|hours|m|min|mins|minute|minutes|s|sec|secs|second|seconds)',
    caseSensitive: false,
  );
  for (final match in pattern.allMatches(value)) {
    final amount = double.tryParse(match.group(1)!);
    final unit = match.group(2)!.toLowerCase();
    if (amount == null) {
      continue;
    }

    matched = true;
    if (unit.startsWith('d')) {
      totalHours += amount * 24;
    } else if (unit.startsWith('h')) {
      totalHours += amount;
    } else if (unit.startsWith('m')) {
      totalHours += amount / 60;
    } else if (unit.startsWith('s')) {
      totalHours += amount / 3600;
    }
  }

  if (matched) {
    return totalHours;
  }

  if (value.contains(':')) {
    final parts = value.split(':').map((part) {
      return double.tryParse(part.trim());
    }).toList(growable: false);
    if (parts.length >= 2 && parts[0] != null && parts[1] != null) {
      final hours = parts[0]!;
      final minutes = parts[1]!;
      final seconds = parts.length >= 3 ? parts[2] ?? 0 : 0;
      return hours + (minutes / 60) + (seconds / 3600);
    }
  }

  return null;
}

String _normalizedTelemetryKey(String key) {
  return key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

double? _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = double.tryParse(trimmed);
    if (parsed != null) {
      return parsed;
    }

    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(trimmed);
    if (match == null) {
      return null;
    }

    return double.tryParse(match.group(0)!);
  }

  return null;
}

String? _firstStringInMaps(
  List<Map<String, dynamic>> sources,
  List<String> keys,
) {
  for (final source in sources) {
    final value = _firstString(source, keys);
    if (value != null) {
      return value;
    }
  }

  return null;
}

bool? _firstBoolInMaps(
  List<Map<String, dynamic>> sources,
  List<String> keys,
) {
  for (final source in sources) {
    final value = _firstBool(source, keys);
    if (value != null) {
      return value;
    }
  }

  return null;
}

Object? _firstExistingValueInMaps(
  List<Map<String, dynamic>> sources,
  List<String> keys,
) {
  for (final source in sources) {
    for (final key in keys) {
      if (source.containsKey(key) && source[key] != null) {
        return source[key];
      }
    }
  }

  return null;
}

DateTime? _firstDate(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is DateTime) {
      return value;
    }

    if (value is num) {
      return _dateFromEpoch(value);
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        return parsed;
      }

      final numeric = num.tryParse(trimmed);
      if (numeric != null) {
        return _dateFromEpoch(numeric);
      }
    }
  }

  return null;
}

DateTime? _firstDateInMaps(
  List<Map<String, dynamic>> sources,
  List<String> keys,
) {
  for (final source in sources) {
    final value = _firstDate(source, keys);
    if (value != null) {
      return value;
    }
  }

  return null;
}

dynamic _resolveReplayPayload(dynamic json) {
  final root = _asMap(json);
  if (root.isEmpty) {
    return json;
  }

  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);
  if (rootDataData.containsKey('points')) {
    return rootDataData;
  }

  if (rootData.containsKey('points')) {
    return rootData;
  }

  return root;
}

List<Map<String, dynamic>> _replayCandidateMaps(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);
  final payload = _asMap(_resolveReplayPayload(json));

  return <Map<String, dynamic>>[
    payload,
    root,
    rootData,
    rootDataData,
    _asMap(root['replay']),
    _asMap(rootData['replay']),
    _asMap(rootDataData['replay']),
  ].where((source) => source.isNotEmpty).toList(growable: false);
}

List<SuperadminReplayPoint> _parseReplayPoints(dynamic json) {
  for (final candidate in _replayPointListCandidates(json)) {
    final list = _asReplayList(candidate);
    if (list == null || list.isEmpty) {
      continue;
    }

    final points = list
        .map(SuperadminReplayPoint.tryParse)
        .whereType<SuperadminReplayPoint>()
        .where((point) => point.hasCoordinates)
        .toList(growable: false);
    if (points.isNotEmpty) {
      return points;
    }
  }

  return const <SuperadminReplayPoint>[];
}

List<dynamic> _replayPointListCandidates(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);
  final replay = _asMap(root['replay']);
  final rootDataReplay = _asMap(rootData['replay']);
  final payload = _asMap(_resolveReplayPayload(json));

  return <dynamic>[
    json,
    payload['points'],
    payload['items'],
    payload['rows'],
    root['points'],
    root['items'],
    root['rows'],
    root['replay'],
    rootData,
    rootData['points'],
    rootData['items'],
    rootData['rows'],
    rootData['data'],
    rootDataData,
    rootDataData['points'],
    rootDataData['items'],
    rootDataData['rows'],
    replay['points'],
    rootDataReplay['points'],
  ];
}

List<dynamic>? _asReplayList(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }

  if (value is List) {
    return value.toList(growable: false);
  }

  final source = _asMap(value);
  if (source.isEmpty) {
    return null;
  }

  return _firstList(source, const ['points', 'items', 'rows', 'data']);
}

List<SuperadminVehicleLog> _parseVehicleLogs(
  dynamic json, {
  required SuperadminVehicleLogSource source,
}) {
  for (final candidate in _vehicleLogListCandidates(json)) {
    final list = _asVehicleLogList(candidate);
    if (list == null || list.isEmpty) {
      continue;
    }

    final logs = list
        .map(
          (item) => SuperadminVehicleLog.tryParse(
            item,
            source: source,
          ),
        )
        .whereType<SuperadminVehicleLog>()
        .toList(growable: false);
    if (logs.isNotEmpty) {
      return logs;
    }
  }

  final single = SuperadminVehicleLog.tryParse(json, source: source);
  return single == null ? const <SuperadminVehicleLog>[] : [single];
}

List<Map<String, dynamic>> _vehicleLogPageMaps(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);
  final logs = _asMap(root['logs']);
  final rootDataLogs = _asMap(rootData['logs']);
  final telemetry = _asMap(root['telemetry']);
  final rootDataTelemetry = _asMap(rootData['telemetry']);

  return <Map<String, dynamic>>[
    root,
    rootData,
    rootDataData,
    logs,
    rootDataLogs,
    telemetry,
    rootDataTelemetry,
  ].where((source) => source.isNotEmpty).toList(growable: false);
}

List<dynamic> _vehicleLogListCandidates(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);
  final logs = _asMap(root['logs']);
  final rootDataLogs = _asMap(rootData['logs']);
  final telemetry = _asMap(root['telemetry']);
  final rootDataTelemetry = _asMap(rootData['telemetry']);

  return <dynamic>[
    json,
    root['items'],
    root['rows'],
    root['records'],
    root['logs'],
    root['telemetry'],
    root['vehicles'],
    root['data'],
    rootData,
    rootData['items'],
    rootData['rows'],
    rootData['records'],
    rootData['logs'],
    rootData['telemetry'],
    rootData['vehicles'],
    rootData['data'],
    rootDataData,
    rootDataData['items'],
    rootDataData['rows'],
    rootDataData['records'],
    rootDataData['logs'],
    rootDataData['telemetry'],
    rootDataData['vehicles'],
    logs['items'],
    logs['rows'],
    logs['records'],
    rootDataLogs['items'],
    rootDataLogs['rows'],
    rootDataLogs['records'],
    telemetry['items'],
    telemetry['rows'],
    telemetry['records'],
    telemetry['logs'],
    telemetry['vehicles'],
    rootDataTelemetry['items'],
    rootDataTelemetry['rows'],
    rootDataTelemetry['records'],
    rootDataTelemetry['logs'],
    rootDataTelemetry['vehicles'],
  ];
}

List<dynamic>? _asVehicleLogList(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }

  if (value is List) {
    return value.toList(growable: false);
  }

  final source = _asMap(value);
  if (source.isEmpty) {
    return null;
  }

  return _firstList(source, const [
    'items',
    'rows',
    'records',
    'logs',
    'data',
    'telemetry',
    'vehicles',
  ]);
}

List<AppNotification> _parseVehicleEvents(dynamic json) {
  for (final candidate in _vehicleEventListCandidates(json)) {
    final list = _asVehicleEventList(candidate);
    if (list == null || list.isEmpty) {
      continue;
    }

    final events = list
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AppNotification.fromJson)
        .where(_isMeaningfulVehicleEvent)
        .toList(growable: false);
    if (events.isNotEmpty) {
      return events;
    }
  }

  for (final candidate in _vehicleEventSingleCandidates(json)) {
    final single = _asMap(candidate);
    if (single.isEmpty) {
      continue;
    }

    final event = AppNotification.fromJson(single);
    if (_isMeaningfulVehicleEvent(event)) {
      return <AppNotification>[event];
    }
  }

  return const <AppNotification>[];
}

List<Map<String, dynamic>> _vehicleEventPageMaps(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);
  final events = _asMap(root['events']);
  final rootDataEvents = _asMap(rootData['events']);
  final notifications = _asMap(root['notifications']);
  final rootDataNotifications = _asMap(rootData['notifications']);

  return <Map<String, dynamic>>[
    root,
    rootData,
    rootDataData,
    events,
    rootDataEvents,
    notifications,
    rootDataNotifications,
  ].where((source) => source.isNotEmpty).toList(growable: false);
}

List<dynamic> _vehicleEventListCandidates(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);
  final events = _asMap(root['events']);
  final rootDataEvents = _asMap(rootData['events']);
  final notifications = _asMap(root['notifications']);
  final rootDataNotifications = _asMap(rootData['notifications']);

  return <dynamic>[
    json,
    root['items'],
    root['rows'],
    root['records'],
    root['events'],
    root['mapEvents'],
    root['map_events'],
    root['notifications'],
    root['alerts'],
    root['data'],
    rootData,
    rootData['items'],
    rootData['rows'],
    rootData['records'],
    rootData['events'],
    rootData['mapEvents'],
    rootData['map_events'],
    rootData['notifications'],
    rootData['alerts'],
    rootData['data'],
    rootDataData,
    rootDataData['items'],
    rootDataData['rows'],
    rootDataData['records'],
    rootDataData['events'],
    rootDataData['mapEvents'],
    rootDataData['map_events'],
    rootDataData['notifications'],
    rootDataData['alerts'],
    events['items'],
    events['rows'],
    events['records'],
    rootDataEvents['items'],
    rootDataEvents['rows'],
    rootDataEvents['records'],
    notifications['items'],
    notifications['rows'],
    notifications['records'],
    rootDataNotifications['items'],
    rootDataNotifications['rows'],
    rootDataNotifications['records'],
  ];
}

List<dynamic>? _asVehicleEventList(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }

  if (value is List) {
    return value.toList(growable: false);
  }

  final source = _asMap(value);
  if (source.isEmpty) {
    return null;
  }

  return _firstList(source, const [
    'items',
    'rows',
    'records',
    'events',
    'mapEvents',
    'map_events',
    'notifications',
    'alerts',
    'data',
  ]);
}

List<dynamic> _vehicleEventSingleCandidates(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);

  return <dynamic>[
    root['item'],
    root['event'],
    root['mapEvent'],
    root['map_event'],
    root['notification'],
    root['payload'],
    root['data'],
    rootData['item'],
    rootData['event'],
    rootData['mapEvent'],
    rootData['map_event'],
    rootData['notification'],
    rootData['payload'],
    rootData['data'],
    rootDataData,
    rootDataData['item'],
    rootDataData['event'],
    rootDataData['mapEvent'],
    rootDataData['map_event'],
    rootDataData['notification'],
    rootDataData['payload'],
    json,
  ];
}

bool _isMeaningfulVehicleEvent(AppNotification event) {
  final title = event.title.trim().toLowerCase();
  final message = event.message.trim().toLowerCase();
  return event.id > 0 ||
      event.eventId != null ||
      event.readId != null ||
      event.logId != null ||
      event.notificationId != null ||
      (event.dedupeKey?.trim().isNotEmpty ?? false) ||
      (event.vehicleImei?.trim().isNotEmpty ?? false) ||
      title != 'notification' ||
      message != 'openvts sent a new update.';
}

String? _vehicleEventCursor(AppNotification event) {
  if (event.id > 0) {
    return event.id.toString();
  }
  if (event.eventId != null && event.eventId! > 0) {
    return event.eventId.toString();
  }
  if (event.logId != null && event.logId! > 0) {
    return event.logId.toString();
  }
  if (event.notificationId != null && event.notificationId! > 0) {
    return event.notificationId.toString();
  }

  return event.dedupeKey?.trim().isEmpty ?? true
      ? null
      : event.dedupeKey!.trim();
}

List<Map<String, dynamic>> _commandCandidateMaps(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);

  return <Map<String, dynamic>>[
    root,
    _asMap(root['command']),
    _asMap(root['log']),
    _asMap(root['item']),
    _asMap(root['status']),
    rootData,
    _asMap(rootData['command']),
    _asMap(rootData['log']),
    _asMap(rootData['item']),
    _asMap(rootData['status']),
    rootDataData,
    _asMap(rootDataData['command']),
    _asMap(rootDataData['log']),
    _asMap(rootDataData['item']),
    _asMap(rootDataData['status']),
  ].where((source) => source.isNotEmpty).toList(growable: false);
}

List<dynamic> _customCommandListCandidates(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);

  return <dynamic>[
    json,
    root['items'],
    root['commands'],
    root['customCommands'],
    root['custom_commands'],
    root['rows'],
    root['records'],
    root['data'],
    rootData,
    rootData['items'],
    rootData['commands'],
    rootData['customCommands'],
    rootData['custom_commands'],
    rootData['rows'],
    rootData['records'],
    rootData['data'],
    rootDataData,
    rootDataData['items'],
    rootDataData['commands'],
    rootDataData['customCommands'],
    rootDataData['custom_commands'],
    rootDataData['rows'],
    rootDataData['records'],
  ];
}

List<dynamic>? _asCustomCommandList(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }

  if (value is List) {
    return value.toList(growable: false);
  }

  final source = _asMap(value);
  if (source.isEmpty) {
    return null;
  }

  return _firstList(source, const [
    'items',
    'commands',
    'customCommands',
    'custom_commands',
    'rows',
    'records',
    'data',
  ]);
}

List<dynamic> _systemVariableListCandidates(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);

  return <dynamic>[
    json,
    root['items'],
    root['variables'],
    root['systemVariables'],
    root['system_variables'],
    root['rows'],
    root['records'],
    root['data'],
    rootData,
    rootData['items'],
    rootData['variables'],
    rootData['systemVariables'],
    rootData['system_variables'],
    rootData['rows'],
    rootData['records'],
    rootData['data'],
    rootDataData,
    rootDataData['items'],
    rootDataData['variables'],
    rootDataData['systemVariables'],
    rootDataData['system_variables'],
    rootDataData['rows'],
    rootDataData['records'],
  ];
}

List<dynamic>? _asSystemVariableList(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }

  if (value is List) {
    return value.toList(growable: false);
  }

  final source = _asMap(value);
  if (source.isEmpty) {
    return null;
  }

  return _firstList(source, const [
    'items',
    'variables',
    'systemVariables',
    'system_variables',
    'rows',
    'records',
    'data',
  ]);
}

List<SuperadminCommandHistoryItem> _parseVehicleCommands(dynamic json) {
  for (final candidate in _vehicleCommandListCandidates(json)) {
    final list = _asVehicleCommandList(candidate);
    if (list == null || list.isEmpty) {
      continue;
    }

    final commands = list
        .map(SuperadminCommandHistoryItem.tryParse)
        .whereType<SuperadminCommandHistoryItem>()
        .toList(growable: false);
    if (commands.isNotEmpty) {
      return commands;
    }
  }

  final single = SuperadminCommandHistoryItem.tryParse(json);
  return single == null ? const <SuperadminCommandHistoryItem>[] : [single];
}

List<Map<String, dynamic>> _vehicleCommandPageMaps(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);
  final commands = _asMap(root['commands']);
  final rootDataCommands = _asMap(rootData['commands']);

  return <Map<String, dynamic>>[
    root,
    rootData,
    rootDataData,
    commands,
    rootDataCommands,
    _asMap(root['meta']),
    _asMap(root['metadata']),
    _asMap(rootData['meta']),
    _asMap(rootData['metadata']),
  ].where((source) => source.isNotEmpty).toList(growable: false);
}

List<dynamic> _vehicleCommandListCandidates(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);
  final commands = _asMap(root['commands']);
  final rootDataCommands = _asMap(rootData['commands']);

  return <dynamic>[
    json,
    root['items'],
    root['commands'],
    root['history'],
    root['logs'],
    root['rows'],
    root['records'],
    root['data'],
    rootData,
    rootData['items'],
    rootData['commands'],
    rootData['history'],
    rootData['logs'],
    rootData['rows'],
    rootData['records'],
    rootData['data'],
    rootDataData,
    rootDataData['items'],
    rootDataData['commands'],
    rootDataData['history'],
    rootDataData['logs'],
    rootDataData['rows'],
    rootDataData['records'],
    commands['items'],
    commands['rows'],
    commands['records'],
    rootDataCommands['items'],
    rootDataCommands['rows'],
    rootDataCommands['records'],
  ];
}

List<dynamic>? _asVehicleCommandList(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }

  if (value is List) {
    return value.toList(growable: false);
  }

  final source = _asMap(value);
  if (source.isEmpty) {
    return null;
  }

  return _firstList(source, const [
    'items',
    'commands',
    'history',
    'logs',
    'rows',
    'records',
    'data',
  ]);
}

List<SuperadminVehicleSensor> _parseVehicleSensors(dynamic json) {
  for (final candidate in _vehicleSensorListCandidates(json)) {
    final list = _asVehicleSensorList(candidate);
    if (list == null || list.isEmpty) {
      continue;
    }

    final sensors = list
        .map(SuperadminVehicleSensor.tryParse)
        .whereType<SuperadminVehicleSensor>()
        .toList(growable: false);
    if (sensors.isNotEmpty) {
      return sensors;
    }
  }

  final single = SuperadminVehicleSensor.tryParse(json);
  return single == null ? const <SuperadminVehicleSensor>[] : [single];
}

List<Map<String, dynamic>> _vehicleSensorPageMaps(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);
  final sensors = _asMap(root['sensors']);
  final rootDataSensors = _asMap(rootData['sensors']);

  return <Map<String, dynamic>>[
    root,
    rootData,
    rootDataData,
    sensors,
    rootDataSensors,
    _asMap(root['meta']),
    _asMap(root['metadata']),
    _asMap(rootData['meta']),
    _asMap(rootData['metadata']),
  ].where((source) => source.isNotEmpty).toList(growable: false);
}

List<dynamic> _vehicleSensorListCandidates(dynamic json) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);
  final sensors = _asMap(root['sensors']);
  final rootDataSensors = _asMap(rootData['sensors']);

  return <dynamic>[
    json,
    root['sensors'],
    root['items'],
    root['rows'],
    root['records'],
    root['data'],
    rootData,
    rootData['sensors'],
    rootData['items'],
    rootData['rows'],
    rootData['records'],
    rootData['data'],
    rootDataData,
    rootDataData['sensors'],
    rootDataData['items'],
    rootDataData['rows'],
    rootDataData['records'],
    sensors['items'],
    sensors['rows'],
    sensors['records'],
    rootDataSensors['items'],
    rootDataSensors['rows'],
    rootDataSensors['records'],
  ];
}

List<dynamic>? _asVehicleSensorList(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }

  if (value is List) {
    return value.toList(growable: false);
  }

  final source = _asMap(value);
  if (source.isEmpty) {
    return null;
  }

  return _firstList(source, const [
    'sensors',
    'items',
    'rows',
    'records',
    'data',
  ]);
}

SuperadminVehicleSensorTelemetryMeta? _parseVehicleSensorTelemetryMeta(
  dynamic json,
) {
  final root = _asMap(json);
  final rootData = _asMap(root['data']);
  final rootDataData = _asMap(rootData['data']);
  final maps = <Map<String, dynamic>>[
    _asMap(root['telemetryMeta']),
    _asMap(root['telemetry_meta']),
    _asMap(root['telemetry']),
    _asMap(rootData['telemetryMeta']),
    _asMap(rootData['telemetry_meta']),
    _asMap(rootData['telemetry']),
    _asMap(rootDataData['telemetryMeta']),
    _asMap(rootDataData['telemetry_meta']),
    _asMap(rootDataData['telemetry']),
  ].where((source) => source.isNotEmpty).toList(growable: false);
  if (maps.isEmpty) {
    return null;
  }

  final hasTelemetry = _firstBoolInMaps(maps, const [
        'hasTelemetry',
        'has_telemetry',
        'available',
        'isAvailable',
        'is_available',
      ]) ??
      _firstDateInMaps(maps, const [
            'serverTime',
            'server_time',
            'timestamp',
            'updatedAt',
            'updated_at',
          ]) !=
          null;

  return SuperadminVehicleSensorTelemetryMeta(
    hasTelemetry: hasTelemetry,
    serverTime: _firstDateInMaps(maps, const [
      'serverTime',
      'server_time',
      'timestamp',
      'updatedAt',
      'updated_at',
    ]),
    deviceTime: _firstDateInMaps(maps, const [
      'deviceTime',
      'device_time',
      'gpsTime',
      'gps_time',
    ]),
  );
}

Object? _telemetryValueForSensor(
  SuperadminVehicleSensor sensor,
  Map<String, Object?> normalizedTelemetry,
) {
  for (final alias in _sensorTelemetryAliases(sensor)) {
    final value = normalizedTelemetry[alias];
    if (value != null) {
      return value;
    }
  }

  return null;
}

List<String> _sensorTelemetryAliases(SuperadminVehicleSensor sensor) {
  final aliases = <String>[];
  final seen = <String>{};

  void addCandidate(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) {
      return;
    }

    void addAlias(String value) {
      final normalized = _normalizedTelemetryKey(value);
      if (normalized.isNotEmpty && seen.add(normalized)) {
        aliases.add(normalized);
      }
    }

    addAlias(trimmed);
    final dottedParts = trimmed.split('.').where((part) => part.isNotEmpty);
    for (final part in dottedParts) {
      addAlias(part);
    }
    final bracketMatches = RegExp(r'\[([^\]]+)\]').allMatches(trimmed);
    for (final match in bracketMatches) {
      final bracketAlias =
          (match.group(1) ?? '').replaceAll('"', '').replaceAll("'", '').trim();
      addAlias(bracketAlias);
    }
  }

  addCandidate(sensor.sourceKey);
  addCandidate(sensor.expression);
  if ((sensor.sourceKey?.trim().isEmpty ?? true) &&
      (sensor.expression?.trim().isEmpty ?? true)) {
    addCandidate(sensor.name);
  }

  return aliases;
}

String _sensorDisplayValue(Object? value) {
  if (value == null) {
    return '';
  }

  if (value is bool) {
    return value ? 'On' : 'Off';
  }

  if (value is int) {
    return value.toString();
  }

  if (value is double) {
    if (!value.isFinite) {
      return '';
    }

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  if (value is num) {
    return _sensorDisplayValue(value.toDouble());
  }

  if (value is DateTime) {
    return value.toLocal().toIso8601String();
  }

  final text = value.toString().trim();
  return text;
}

_ReplayCoordinatePair? _extractReplayCoordinates(Map<String, dynamic> source) {
  final candidateMaps = <Map<String, dynamic>>[
    source,
    _asMap(source['point']),
    _asMap(source['position']),
    _asMap(source['location']),
    _asMap(source['gps']),
    _asMap(source['telemetry']),
    _asMap(source['data']),
  ].where((candidate) => candidate.isNotEmpty).toList(growable: false);

  final latitude = _firstDoubleInMaps(candidateMaps, const [
    'latitude',
    'lat',
    'y',
  ]);
  final longitude = _firstDoubleInMaps(candidateMaps, const [
    'longitude',
    'lng',
    'lon',
    'long',
    'x',
  ]);

  if (_isValidCoordinatePair(latitude, longitude)) {
    return _ReplayCoordinatePair(latitude!, longitude!);
  }

  final coordinates = source['coordinates'];
  if (coordinates is List && coordinates.length >= 2) {
    final first = _asDouble(coordinates[0]);
    final second = _asDouble(coordinates[1]);
    if (_isValidCoordinatePair(second, first)) {
      return _ReplayCoordinatePair(second!, first!);
    }
    if (_isValidCoordinatePair(first, second)) {
      return _ReplayCoordinatePair(first!, second!);
    }
  }

  return null;
}

bool _isValidCoordinatePair(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) {
    return false;
  }

  return latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

class _ReplayCoordinatePair {
  const _ReplayCoordinatePair(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

DateTime _dateFromEpoch(num value) {
  final raw = value.toInt();
  final milliseconds = raw.abs() < 100000000000 ? raw * 1000 : raw;
  return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
}

String _normalizeVehicleType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'Vehicle';
  }

  if (normalized.contains('bike') ||
      normalized.contains('cycle') ||
      normalized.contains('motor') ||
      normalized.contains('scooty') ||
      normalized.contains('scooter') ||
      normalized.contains('2 wheel') ||
      normalized.contains('2wheel')) {
    return 'Bike';
  }

  if (normalized.contains('truck') ||
      normalized.contains('tempo') ||
      normalized.contains('tractor') ||
      normalized.contains('tanker') ||
      normalized.contains('container')) {
    return 'Truck';
  }

  if (normalized.contains('bus')) {
    return 'Bus';
  }

  if (normalized.contains('van')) {
    return 'Van';
  }

  if (normalized.contains('car') ||
      normalized.contains('sedan') ||
      normalized.contains('jeep') ||
      normalized.contains('suv')) {
    return 'Car';
  }

  return _titleCase(value);
}

String _normalizeVehicleStatus(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'Unknown';
  }

  if (normalized.contains('active') ||
      normalized.contains('online') ||
      normalized.contains('running') ||
      normalized.contains('connect') ||
      normalized == 'true' ||
      normalized == '1' ||
      normalized.contains('enable')) {
    return 'Active';
  }

  if (normalized.contains('idle')) {
    return 'Idle';
  }

  if (normalized.contains('inactive') ||
      normalized == 'stop' ||
      normalized.contains('stopped') ||
      normalized == 'false' ||
      normalized == '0' ||
      normalized.contains('disable')) {
    return 'Inactive';
  }

  if (normalized.contains('offline') || normalized.contains('disconnect')) {
    return 'Offline';
  }

  return _titleCase(value);
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'[\s_-]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}
