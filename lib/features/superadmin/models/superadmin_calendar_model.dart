class CalendarEvent {
  final String date;
  final int usersCount;
  final int vehiclesCount;
  final int expiryCount;

  CalendarEvent({
    required this.date,
    this.usersCount = 0,
    this.vehiclesCount = 0,
    this.expiryCount = 0,
  });

  int get totalCount => usersCount + vehiclesCount + expiryCount;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      date: _extractDate(json) ?? '',
      usersCount: _extractTypeCount(json, 'users'),
      vehiclesCount: _extractTypeCount(json, 'vehicle'),
      expiryCount: _extractTypeCount(json, 'expiry'),
    );
  }

  static List<CalendarEvent> listFromPayload(dynamic payload) {
    final eventsByDate = <String, _CalendarEventAccumulator>{};

    void addCounts(
      String? rawDate, {
      int users = 0,
      int vehicles = 0,
      int expiry = 0,
    }) {
      final normalizedDate = _normalizeDate(rawDate);
      if (normalizedDate == null) {
        return;
      }

      final accumulator = eventsByDate.putIfAbsent(
        normalizedDate,
        () => _CalendarEventAccumulator(normalizedDate),
      );
      accumulator.add(
        users: users,
        vehicles: vehicles,
        expiry: expiry,
      );
    }

    void addTypedCount(String? rawDate, String? rawType, int count) {
      final normalizedType = _normalizeCalendarType(rawType);
      final resolvedCount = count > 0 ? count : 1;

      switch (normalizedType) {
        case 'users':
          addCounts(rawDate, users: resolvedCount);
        case 'vehicle':
          addCounts(rawDate, vehicles: resolvedCount);
        case 'expiry':
          addCounts(rawDate, expiry: resolvedCount);
        default:
          break;
      }
    }

    void consumeDateEntry(String dateKey, dynamic value, {String? forcedType}) {
      if (_normalizeDate(dateKey) == null) {
        return;
      }

      if (forcedType != null) {
        addTypedCount(dateKey, forcedType, _countFromAny(value));
        return;
      }

      if (value is Map<String, dynamic>) {
        final usersCount = _extractTypeCount(value, 'users');
        final vehicleCount = _extractTypeCount(value, 'vehicle');
        final expiryCount = _extractTypeCount(value, 'expiry');

        if (usersCount + vehicleCount + expiryCount > 0) {
          addCounts(
            dateKey,
            users: usersCount,
            vehicles: vehicleCount,
            expiry: expiryCount,
          );
          return;
        }

        addTypedCount(
          dateKey,
          _firstString(value, const ['type', 'eventType', 'event_type', 'bucket']),
          _countFromAny(value),
        );
        return;
      }

      addTypedCount(dateKey, forcedType, _countFromAny(value));
    }

    void consumeTypedBucket(String rawType, dynamic source) {
      final normalizedType = _normalizeCalendarType(rawType);
      if (normalizedType == null) {
        return;
      }

      if (source is List<dynamic>) {
        for (final item in source) {
          if (item is Map<String, dynamic>) {
            final date = _extractDate(item);
            if (date != null) {
              addTypedCount(date, normalizedType, _countFromAny(item));
              continue;
            }

            for (final entry in item.entries) {
              consumeDateEntry(entry.key, entry.value, forcedType: normalizedType);
            }
            continue;
          }

          addTypedCount(null, normalizedType, _countFromAny(item));
        }
        return;
      }

      if (source is Map<String, dynamic>) {
        final nestedList = _firstList(
          source,
          const ['items', 'rows', 'records', 'data', 'results', 'list', 'events'],
        );
        if (nestedList != null) {
          consumeTypedBucket(normalizedType, nestedList);
          return;
        }

        final nestedCollection = _firstNestedCollection(
          source,
          const ['data', 'items', 'rows', 'records', 'results', 'list', 'events', 'payload', 'result', 'calendar', 'days'],
        );
        if (nestedCollection != null) {
          consumeTypedBucket(normalizedType, nestedCollection);
          return;
        }

        final date = _extractDate(source);
        if (date != null) {
          addTypedCount(date, normalizedType, _countFromAny(source));
          return;
        }

        for (final entry in source.entries) {
          consumeDateEntry(entry.key, entry.value, forcedType: normalizedType);
        }
        return;
      }

      addTypedCount(null, normalizedType, _countFromAny(source));
    }

    void consumeUngrouped(dynamic source) {
      if (source is List<dynamic>) {
        for (final item in source.whereType<Map<String, dynamic>>()) {
          final date = _extractDate(item);

          if (date == null && item.keys.any(_looksLikeDateKey)) {
            for (final entry in item.entries) {
              consumeDateEntry(entry.key, entry.value);
            }
            continue;
          }

          if (date == null) {
            continue;
          }

          final usersCount = _extractTypeCount(item, 'users');
          final vehicleCount = _extractTypeCount(item, 'vehicle');
          final expiryCount = _extractTypeCount(item, 'expiry');

          if (usersCount + vehicleCount + expiryCount > 0) {
            addCounts(
              date,
              users: usersCount,
              vehicles: vehicleCount,
              expiry: expiryCount,
            );
            continue;
          }

          addTypedCount(
            date,
            _firstString(item, const ['type', 'eventType', 'event_type', 'bucket']),
            _countFromAny(item),
          );
        }
        return;
      }

      final map = _asMap(source);
      if (map.isEmpty) {
        return;
      }

      final nestedList = _firstList(
        map,
        const ['items', 'rows', 'records', 'data', 'results', 'list', 'events', 'calendar', 'days'],
      );
      if (nestedList != null) {
        consumeUngrouped(nestedList);
        return;
      }

      final nestedCollection = _firstNestedCollection(
        map,
        const ['data', 'items', 'rows', 'records', 'results', 'list', 'events', 'calendar', 'days', 'payload', 'result'],
      );
      if (nestedCollection != null) {
        consumeUngrouped(nestedCollection);
        return;
      }

      var handledTypedBucket = false;
      for (final entry in map.entries) {
        if (_normalizeCalendarType(entry.key) != null) {
          handledTypedBucket = true;
          consumeTypedBucket(entry.key, entry.value);
        }
      }
      if (handledTypedBucket) {
        return;
      }

      if (map.keys.every(_looksLikeDateKey)) {
        for (final entry in map.entries) {
          consumeDateEntry(entry.key, entry.value);
        }
        return;
      }

      final date = _extractDate(map);
      if (date != null) {
        consumeUngrouped(<Map<String, dynamic>>[map]);
      }
    }

    consumeUngrouped(payload);

    final items = eventsByDate.values
        .map((accumulator) => CalendarEvent(
              date: accumulator.date,
              usersCount: accumulator.users,
              vehiclesCount: accumulator.vehicles,
              expiryCount: accumulator.expiry,
            ))
        .where((event) => event.totalCount > 0)
        .toList()
      ..sort((left, right) => left.date.compareTo(right.date));

    return items;
  }
}

class CalendarDayDetail {
  final String id;
  final String title;
  final String type;
  final String subtitle;
  final String? userId;
  final String? vehicleId;
  final int count;

  CalendarDayDetail({
    required this.id,
    required this.title,
    required this.type,
    required this.subtitle,
    this.userId,
    this.vehicleId,
    this.count = 1,
  });

  bool get isUser => type == 'users' && userId != null && userId!.isNotEmpty;
  bool get isVehicle => type == 'vehicle' && vehicleId != null && vehicleId!.isNotEmpty;

  factory CalendarDayDetail.fromJson(
    Map<String, dynamic> json, {
    String? fallbackType,
  }) {
    final normalizedType =
        _normalizeCalendarType(_firstString(json, const ['type', 'eventType', 'event_type', 'bucket']) ?? fallbackType) ??
            'users';
    final resolvedId = _firstString(
          json,
          const [
            'id',
            '_id',
            'uid',
            'userId',
            'user_id',
            'vehicleId',
            'vehicle_id',
          ],
        ) ??
        '';
    final resolvedUserId = _firstString(
      json,
      const ['uid', 'userId', 'user_id', 'id', '_id'],
    );
    final resolvedVehicleId = _firstString(
      json,
      const ['vehicleId', 'vehicle_id', 'id', '_id'],
    );
    final resolvedTitle = _firstString(
          json,
          const [
            'title',
            'name',
            'fullName',
            'displayName',
            'username',
            'userName',
            'vehicleName',
            'vehicle_name',
            'plateNumber',
            'plate_number',
            'registrationNo',
            'registration_no',
            'label',
          ],
        ) ??
        _labelForType(normalizedType);

    final resolvedSubtitle = _joinParts(<String?>[
      _firstString(json, const ['plateNumber', 'plate_number', 'registrationNo', 'registration_no']),
      _firstString(json, const ['mobile', 'phone', 'mobileNumber', 'mobile_number']),
      _firstString(json, const ['email']),
      _firstString(json, const ['status', 'state']),
      _firstString(json, const ['expiresAt', 'expiryDate', 'expiry_date', 'date']),
      _firstString(json, const ['vehicleType', 'vehicle_type', 'typeName', 'type_name']),
      _firstString(json, const ['subtitle', 'description']),
    ]);

    return CalendarDayDetail(
      id: resolvedId.isNotEmpty
          ? resolvedId
          : (normalizedType == 'vehicle' ? (resolvedVehicleId ?? '') : (resolvedUserId ?? '')),
      title: resolvedTitle,
      type: normalizedType,
      subtitle: resolvedSubtitle,
      userId: normalizedType == 'users' ? (resolvedUserId ?? resolvedId) : null,
      vehicleId: normalizedType == 'vehicle' ? (resolvedVehicleId ?? resolvedId) : null,
      count: _countFromAny(json),
    );
  }

  static List<CalendarDayDetail> listFromPayload(dynamic payload) {
    final items = <CalendarDayDetail>[];

    void addSummary(String rawType, dynamic value) {
      final normalizedType = _normalizeCalendarType(rawType);
      if (normalizedType == null) {
        return;
      }

      final count = _countFromAny(value);
      if (count <= 0) {
        return;
      }

      items.add(
        CalendarDayDetail(
          id: '$normalizedType-$count',
          title: _labelForType(normalizedType),
          type: normalizedType,
          subtitle: '$count event${count == 1 ? '' : 's'}',
          count: count,
        ),
      );
    }

    void consumeTypedBucket(String rawType, dynamic source) {
      final normalizedType = _normalizeCalendarType(rawType);
      if (normalizedType == null) {
        return;
      }

      if (source is List<dynamic>) {
        for (final item in source.whereType<Map<String, dynamic>>()) {
          items.add(CalendarDayDetail.fromJson(item, fallbackType: normalizedType));
        }
        return;
      }

      if (source is Map<String, dynamic>) {
        final nestedList = _firstList(
          source,
          const ['items', 'rows', 'records', 'data', 'results', 'list', 'events'],
        );
        if (nestedList != null) {
          consumeTypedBucket(normalizedType, nestedList);
          return;
        }

        final nestedCollection = _firstNestedCollection(
          source,
          const ['data', 'items', 'rows', 'records', 'results', 'list', 'events', 'payload', 'result'],
        );
        if (nestedCollection != null) {
          consumeTypedBucket(normalizedType, nestedCollection);
          return;
        }

        if (_looksLikeItemMap(source)) {
          items.add(CalendarDayDetail.fromJson(source, fallbackType: normalizedType));
          return;
        }

        addSummary(normalizedType, source);
        return;
      }

      addSummary(normalizedType, source);
    }

    void consume(dynamic source) {
      if (source is List<dynamic>) {
        for (final item in source.whereType<Map<String, dynamic>>()) {
          items.add(CalendarDayDetail.fromJson(item));
        }
        return;
      }

      final map = _asMap(source);
      if (map.isEmpty) {
        return;
      }

      final nestedList = _firstList(
        map,
        const ['items', 'rows', 'records', 'data', 'results', 'list', 'events'],
      );
      if (nestedList != null) {
        consume(nestedList);
        return;
      }

      final nestedCollection = _firstNestedCollection(
        map,
        const ['data', 'items', 'rows', 'records', 'results', 'list', 'events', 'payload', 'result'],
      );
      if (nestedCollection != null) {
        consume(nestedCollection);
        return;
      }

      var handledTypedBucket = false;
      for (final entry in map.entries) {
        if (_normalizeCalendarType(entry.key) != null) {
          handledTypedBucket = true;
          consumeTypedBucket(entry.key, entry.value);
        }
      }

      if (handledTypedBucket) {
        return;
      }

      if (_looksLikeItemMap(map)) {
        items.add(CalendarDayDetail.fromJson(map));
      }
    }

    consume(payload);
    return items.where((item) => item.title.trim().isNotEmpty).toList();
  }
}

class CalendarLinkedDetail {
  const CalendarLinkedDetail({
    required this.title,
    required this.subtitle,
    required this.metadata,
  });

  final String title;
  final String subtitle;
  final List<String> metadata;

  factory CalendarLinkedDetail.fromUserPayload(dynamic payload) {
    final json = _asMap(payload);
    return CalendarLinkedDetail(
      title: _firstString(
            json,
            const ['name', 'fullName', 'displayName', 'username', 'userName', 'title'],
          ) ??
          'User',
      subtitle: _joinParts(<String?>[
        _firstString(json, const ['email']),
        _firstString(json, const ['mobile', 'phone', 'mobileNumber', 'mobile_number']),
      ]),
      metadata: <String>[
        _joinParts(<String?>[
          _firstString(json, const ['status', 'state']),
          _firstString(json, const ['role', 'userRole', 'user_role']),
        ]),
        _joinParts(<String?>[
          _firstString(json, const ['company', 'companyName', 'company_name']),
          _firstString(json, const ['city', 'location']),
        ]),
      ].where((item) => item.isNotEmpty).toList(),
    );
  }

  factory CalendarLinkedDetail.fromVehiclePayload(dynamic payload) {
    final json = _asMap(payload);
    return CalendarLinkedDetail(
      title: _firstString(
            json,
            const ['name', 'vehicleName', 'vehicle_name', 'plateNumber', 'plate_number'],
          ) ??
          'Vehicle',
      subtitle: _joinParts(<String?>[
        _firstString(json, const ['plateNumber', 'plate_number', 'registrationNo', 'registration_no']),
        _firstString(json, const ['vehicleType', 'vehicle_type', 'type', 'typeName', 'type_name']),
      ]),
      metadata: <String>[
        _joinParts(<String?>[
          _firstString(json, const ['imei', 'deviceImei', 'deviceIMEI']),
          _firstString(json, const ['sim', 'simNumber', 'sim_number']),
        ]),
        _joinParts(<String?>[
          _firstString(json, const ['status', 'state']),
          _firstString(json, const ['primaryUser', 'assignedTo', 'assigned_to', 'userName']),
        ]),
      ].where((item) => item.isNotEmpty).toList(),
    );
  }
}

class _CalendarEventAccumulator {
  _CalendarEventAccumulator(this.date);

  final String date;
  int users = 0;
  int vehicles = 0;
  int expiry = 0;

  void add({int users = 0, int vehicles = 0, int expiry = 0}) {
    this.users += users;
    this.vehicles += vehicles;
    this.expiry += expiry;
  }
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

List<dynamic>? _firstList(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is List<dynamic>) {
      return value;
    }
  }
  return null;
}

dynamic _firstNestedCollection(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is List<dynamic>) {
      return value;
    }

    if (_asMap(value).isNotEmpty) {
      return value;
    }
  }

  return null;
}

String? _firstString(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return null;
}

bool _looksLikeDateKey(String key) => _normalizeDate(key) != null;

bool _looksLikeItemMap(Map<String, dynamic> source) {
  return _firstString(
        source,
        const [
          'id',
          '_id',
          'uid',
          'userId',
          'vehicleId',
          'name',
          'title',
          'fullName',
          'plateNumber',
          'registrationNo',
        ],
      ) !=
      null;
}

String? _extractDate(Map<String, dynamic> source) {
  return _normalizeDate(
    _firstString(
      source,
      const [
        'date',
        'day',
        'eventDate',
        'event_date',
        'calendarDate',
        'calendar_date',
        'expiresAt',
        'expiryDate',
        'expiry_date',
        'createdAt',
      ],
    ),
  );
}

String? _normalizeDate(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  if (text.length < 10) {
    return null;
  }

  final candidate = text.substring(0, 10);
  final parts = candidate.split('-');
  if (parts.length != 3) {
    return null;
  }

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }

  return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

int _parseInt(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is List<dynamic>) {
    return value.length;
  }
  if (_asMap(value).isNotEmpty) {
    return _countFromAny(value);
  }
  return int.tryParse(value.toString()) ?? 0;
}

int _countFromAny(dynamic value) {
  if (value is List<dynamic>) {
    return value.length;
  }

  final map = _asMap(value);
  if (map.isNotEmpty) {
    final directCount = _parseInt(
      map['count'] ??
          map['total'] ??
          map['length'] ??
          map['size'] ??
          map['usersCount'] ??
          map['vehiclesCount'] ??
          map['expiryCount'] ??
          map['value'],
    );
    if (directCount > 0) {
      return directCount;
    }

    final nestedList = _firstList(
      map,
      const ['items', 'rows', 'records', 'data', 'results', 'list', 'events'],
    );
    if (nestedList != null) {
      return nestedList.length;
    }

    final nestedSummary = _firstNestedCollection(
      map,
      const ['summary', 'totals', 'counts', 'stats', 'metrics', 'payload', 'result'],
    );
    if (nestedSummary != null) {
      final nestedCount = _countFromAny(nestedSummary);
      if (nestedCount > 0) {
        return nestedCount;
      }
    }

    var aggregate = 0;
    var sawStructuredKey = false;
    for (final entry in map.entries) {
      if (_normalizeCalendarType(entry.key) != null || _looksLikeDateKey(entry.key)) {
        sawStructuredKey = true;
        aggregate += _countFromAny(entry.value);
      }
    }
    if (sawStructuredKey && aggregate > 0) {
      return aggregate;
    }

    return 0;
  }

  return _parseInt(value);
}

String? _normalizeCalendarType(String? rawType) {
  if (rawType == null) {
    return null;
  }

  final normalized = rawType.toLowerCase().trim();
  if (normalized.contains('expir')) {
    return 'expiry';
  }
  if (normalized.contains('user')) {
    return 'users';
  }
  if (normalized.contains('veh')) {
    return 'vehicle';
  }
  return null;
}

int _extractTypeCount(Map<String, dynamic> source, String rawType) {
  final normalizedType = _normalizeCalendarType(rawType);
  if (normalizedType == null) {
    return 0;
  }

  switch (normalizedType) {
    case 'users':
      return _countFromAny(
        source['usersCount'] ??
            source['users_count'] ??
            source['userCount'] ??
            source['user_count'] ??
            source['users'] ??
            source['user'],
      );
    case 'vehicle':
      return _countFromAny(
        source['vehiclesCount'] ??
            source['vehicles_count'] ??
            source['vehicleCount'] ??
            source['vehicle_count'] ??
            source['vehicles'] ??
            source['vehicle'],
      );
    case 'expiry':
      return _countFromAny(
        source['expiryCount'] ??
            source['expiry_count'] ??
            source['expiriesCount'] ??
            source['expiries_count'] ??
            source['expiry'] ??
            source['expiries'],
      );
    default:
      return 0;
  }
}

String _labelForType(String type) {
  switch (type) {
    case 'vehicle':
      return 'Vehicle';
    case 'expiry':
      return 'Expiry';
    case 'users':
    default:
      return 'Users';
  }
}

String _joinParts(List<String?> parts) {
  return parts
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty && item.toLowerCase() != 'null')
      .join(' • ');
}
