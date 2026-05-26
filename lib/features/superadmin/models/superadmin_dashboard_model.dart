class SuperadminDashboardModel {
  const SuperadminDashboardModel({
    required this.counts,
    required this.adoptionGrowth,
    required this.vehicleStatus,
    required this.recentVehicles,
    required this.transactions,
    required this.recentUsers,
    required this.activityLogs,
    required this.activityActors,
  });

  final SuperadminDashboardCounts counts;
  final List<SuperadminAdoptionPoint> adoptionGrowth;
  final SuperadminVehicleStatusSummary vehicleStatus;
  final List<SuperadminRecentVehicle> recentVehicles;
  final List<SuperadminTransaction> transactions;
  final List<SuperadminRecentUser> recentUsers;
  final SuperadminActivityLogPage activityLogs;
  final List<SuperadminActorOption> activityActors;

  int get totalVehicles => counts.totalVehicles;
  int get onlineVehicles => vehicleStatus.connectedCount;
  int get totalAdmins => counts.totalAdmins;
  int get alertsToday => activityLogs.items.length;

  SuperadminDashboardModel copyWith({
    SuperadminDashboardCounts? counts,
    List<SuperadminAdoptionPoint>? adoptionGrowth,
    SuperadminVehicleStatusSummary? vehicleStatus,
    List<SuperadminRecentVehicle>? recentVehicles,
    List<SuperadminTransaction>? transactions,
    List<SuperadminRecentUser>? recentUsers,
    SuperadminActivityLogPage? activityLogs,
    List<SuperadminActorOption>? activityActors,
  }) {
    return SuperadminDashboardModel(
      counts: counts ?? this.counts,
      adoptionGrowth: adoptionGrowth ?? this.adoptionGrowth,
      vehicleStatus: vehicleStatus ?? this.vehicleStatus,
      recentVehicles: recentVehicles ?? this.recentVehicles,
      transactions: transactions ?? this.transactions,
      recentUsers: recentUsers ?? this.recentUsers,
      activityLogs: activityLogs ?? this.activityLogs,
      activityActors: activityActors ?? this.activityActors,
    );
  }

  factory SuperadminDashboardModel.fromSources({
    required dynamic overview,
    required dynamic activityLogs,
    required dynamic actors,
  }) {
    final overviewMap = _asMap(overview);
    final parsedCounts = SuperadminDashboardCounts.fromJson(overviewMap);
    final parsedVehicleStatus = SuperadminVehicleStatusSummary.fromJson(
      _firstMap(
            overviewMap,
            const [
              'vehicleStatus',
              'vehicleSummary',
              'deviceStatus',
              'statusSummary',
            ],
          ) ??
          overviewMap,
      fallbackTotalDevices: parsedCounts.totalVehicles,
    );

    return SuperadminDashboardModel(
      counts: parsedCounts,
      adoptionGrowth: _parseAdoptionGrowth(overviewMap),
      vehicleStatus: parsedVehicleStatus,
      recentVehicles: _parseRecentVehicles(overviewMap),
      transactions: _parseTransactions(overviewMap),
      recentUsers: _parseRecentUsers(overviewMap),
      activityLogs: SuperadminActivityLogPage.fromJson(activityLogs),
      activityActors: SuperadminActorOption.listFromJson(actors),
    );
  }

  factory SuperadminDashboardModel.fromJson(Map<String, dynamic> json) {
    return SuperadminDashboardModel.fromSources(
      overview: json,
      activityLogs: const <String, dynamic>{},
      actors: const <dynamic>[],
    );
  }
}

class SuperadminDashboardCounts {
  const SuperadminDashboardCounts({
    required this.totalAdmins,
    required this.totalVehicles,
    required this.activeVehicles,
    required this.totalUsers,
    required this.licensesIssued,
    required this.licensesUsed,
  });

  final int totalAdmins;
  final int totalVehicles;
  final int activeVehicles;
  final int totalUsers;
  final int licensesIssued;
  final int licensesUsed;

  factory SuperadminDashboardCounts.fromJson(Map<String, dynamic> json) {
    final statsMap = _firstMap(
      json,
      const [
        'totalCounts',
        'overview',
        'stats',
        'counts',
        'summary',
        'totals',
      ],
    );
    final source = statsMap ?? json;

    return SuperadminDashboardCounts(
      totalAdmins: _firstInt(
        source,
        const ['allAdmins', 'totalAdmins', 'adminsCount', 'adminCount'],
      ),
      totalVehicles: _firstInt(
        source,
        const ['totalVehicles', 'vehiclesCount', 'vehicleCount'],
      ),
      activeVehicles: _firstInt(
        source,
        const ['activeVehicle', 'activeVehicles', 'onlineVehicles', 'liveVehicles'],
      ),
      totalUsers: _firstInt(
        source,
        const ['totalUsers', 'usersCount', 'userCount'],
      ),
      licensesIssued: _firstInt(
        source,
        const [
          'licenseIssued',
          'licensesIssued',
          'issuedLicenses',
          'licensedCredits',
          'licensesAssigned',
        ],
      ),
      licensesUsed: _firstInt(
        source,
        const [
          'licenseUsed',
          'licensesUsed',
          'usedLicenses',
          'usedCredits',
          'licensesUsedCount',
        ],
      ),
    );
  }
}

class SuperadminAdoptionPoint {
  const SuperadminAdoptionPoint({
    required this.label,
    required this.vehicles,
    required this.users,
    required this.licenses,
  });

  final String label;
  final int vehicles;
  final int users;
  final int licenses;

  factory SuperadminAdoptionPoint.fromJson(Map<String, dynamic> json) {
    final month = _firstString(json, const ['month', 'label', 'name', 'key', 'period']);
    final year = _firstNum(json, const ['year'])?.toInt();

    return SuperadminAdoptionPoint(
      label: _formatAdoptionLabel(month, year),
      vehicles: _firstInt(
        json,
        const ['vehicles', 'vehicleCount', 'vehicle'],
      ),
      users: _firstInt(json, const ['users', 'userCount', 'user']),
      licenses: _firstInt(
        json,
        const [
          'licenses',
          'licenseCount',
          'licenseIssued',
          'license',
          'licensesAssigned',
          'licensedCredits',
        ],
      ),
    );
  }
}

class SuperadminVehicleStatusSummary {
  const SuperadminVehicleStatusSummary({
    required this.totalDevices,
    required this.connectedCount,
    required this.runningCount,
    required this.stopCount,
    required this.inactiveCount,
    required this.noDataCount,
  });

  final int totalDevices;
  final int connectedCount;
  final int runningCount;
  final int stopCount;
  final int inactiveCount;
  final int noDataCount;

  factory SuperadminVehicleStatusSummary.fromJson(
    Map<String, dynamic> json, {
    int fallbackTotalDevices = 0,
  }) {
    final source = _firstMap(
          json,
          const [
            'vehicleStatus',
            'deviceStatus',
            'statusSummary',
            'vehicleLiveStatus',
            'totalCounts',
          ],
        ) ??
        json;

    final liveStatus = _firstMap(
          source,
          const ['vehicleLiveStatus', 'status', 'summary'],
        ) ??
        source;

    final connected = _firstInt(
      liveStatus,
      const ['connected', 'connectedCount', 'online', 'onlineCount'],
    );
    final running = _firstInt(
      liveStatus,
      const ['running', 'runningCount', 'moving', 'movingCount'],
    );
    final stop = _firstInt(
      liveStatus,
      const ['stop', 'stopped', 'stoppedCount', 'stopCount'],
    );
    final inactive = _firstInt(
      liveStatus,
      const ['inactive', 'inactiveCount', 'inactive48h', 'inactive48Hours'],
    );
    final noData = _firstInt(
      liveStatus,
      const ['noData', 'noDataCount', 'unknown', 'unknownCount'],
    );
    final explicitTotal = _firstInt(
      source,
      const ['totalDevices', 'devicesCount', 'totalVehicles', 'total', 'all'],
    );
    final derivedTotal = connected + running + stop + inactive + noData;

    return SuperadminVehicleStatusSummary(
      totalDevices: explicitTotal > 0
          ? explicitTotal
          : fallbackTotalDevices > 0
              ? fallbackTotalDevices
              : derivedTotal,
      connectedCount: connected,
      runningCount: running,
      stopCount: stop,
      inactiveCount: inactive,
      noDataCount: noData,
    );
  }
}

class SuperadminRecentVehicle {
  const SuperadminRecentVehicle({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String subtitle;
  final String status;
  final DateTime? updatedAt;

  factory SuperadminRecentVehicle.fromJson(Map<String, dynamic> json) {
    final vehicleType = _firstMap(json, const ['vehicleType']);

    return SuperadminRecentVehicle(
      id: _firstString(json, const ['id', '_id', 'vehicleId', 'imei']) ?? '',
      name: _firstString(
            json,
            const ['name', 'vehicleName', 'title', 'plateNo', 'plateNumber'],
          ) ??
          'Unnamed vehicle',
      subtitle: _firstString(
            vehicleType ?? json,
            const ['name', 'type', 'vehicleType', 'category', 'subtitle', 'slug'],
          ) ??
          'Vehicle',
      status: _firstString(
            json,
            const ['status', 'state', 'vehicleStatus', 'connectionStatus'],
          ) ??
          'Active',
      updatedAt: _firstDate(
        json,
        const ['updatedAt', 'createdAt', 'lastUpdate', 'date'],
      ),
    );
  }
}

class SuperadminTransaction {
  const SuperadminTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final num amount;
  final String currency;
  final String status;
  final DateTime? createdAt;

  factory SuperadminTransaction.fromJson(Map<String, dynamic> json) {
    final fromUser = _firstMap(json, const ['fromUser', 'user', 'customer']);
    final name = _firstString(
      fromUser ?? json,
      const ['name', 'fullName', 'title', 'customerName', 'userName'],
    );
    final username = _firstString(fromUser ?? json, const ['username']);

    return SuperadminTransaction(
      id: _firstString(json, const ['id', '_id', 'transactionId']) ?? '',
      title: _transactionTitle(name, username),
      subtitle: _firstString(
            json,
            const ['subtitle', 'email', 'description', 'relativeTime'],
          ) ??
          _relativeTimeLabel(
            _firstDate(
              json,
              const ['createdAt', 'updatedAt', 'date', 'paidAt'],
            ),
          ),
      amount: _firstNum(json, const ['amount', 'value', 'total']) ?? 0,
      currency: _firstString(json, const ['currency', 'currencyCode']) ?? 'INR',
      status: _firstString(
            json,
            const ['status', 'paymentStatus', 'state'],
          ) ??
          'Success',
      createdAt: _firstDate(
        json,
        const ['createdAt', 'updatedAt', 'date', 'paidAt'],
      ),
    );
  }
}

class SuperadminRecentUser {
  const SuperadminRecentUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.initials,
  });

  final String id;
  final String name;
  final String email;
  final DateTime? createdAt;
  final String? initials;

  factory SuperadminRecentUser.fromJson(Map<String, dynamic> json) {
    return SuperadminRecentUser(
      id: _firstString(json, const ['id', '_id', 'userId', 'adminId', 'uid']) ?? '',
      name: _firstString(json, const ['name', 'fullName', 'displayName']) ?? 'Unknown',
      email: _firstString(json, const ['email', 'mail']) ?? '—',
      createdAt: _firstDate(
        json,
        const ['createdAt', 'updatedAt', 'date', 'joinedAt'],
      ),
      initials: _firstString(json, const ['initials', 'avatarText']),
    );
  }
}

class SuperadminActivityLogPage {
  const SuperadminActivityLogPage({
    required this.items,
    required this.nextCursorId,
  });

  final List<SuperadminActivityLog> items;
  final int? nextCursorId;

  bool get hasMore => nextCursorId != null && nextCursorId! > 0;

  SuperadminActivityLogPage copyWith({
    List<SuperadminActivityLog>? items,
    Object? nextCursorId = _unsetValue,
  }) {
    return SuperadminActivityLogPage(
      items: items ?? this.items,
      nextCursorId: identical(nextCursorId, _unsetValue)
          ? this.nextCursorId
          : nextCursorId as int?,
    );
  }

  factory SuperadminActivityLogPage.fromJson(dynamic json) {
    final source = _asMap(json);
    final items = _firstList(
          source,
          const ['items', 'activityLogs', 'logs', 'rows', 'data'],
        ) ??
        (json is List ? json : const <dynamic>[]);

    return SuperadminActivityLogPage(
      items: items
          .map(_asMap)
          .where((item) => item.isNotEmpty)
          .map(SuperadminActivityLog.fromJson)
          .toList(growable: false),
      nextCursorId: _firstNum(
        source,
        const ['nextCursorId', 'cursorId', 'nextId', 'nextCursor'],
      )
          ?.toInt(),
    );
  }
}

class SuperadminActivityLog {
  const SuperadminActivityLog({
    required this.id,
    required this.title,
    required this.actorName,
    required this.actorRole,
    required this.createdAt,
    this.actorId,
  });

  final String id;
  final String title;
  final String actorName;
  final String actorRole;
  final DateTime? createdAt;
  final int? actorId;

  factory SuperadminActivityLog.fromJson(Map<String, dynamic> json) {
    return SuperadminActivityLog(
      id: _firstString(json, const ['id', '_id', 'logId']) ?? '',
      title: _firstString(
            json,
            const ['title', 'action', 'message', 'name'],
          ) ??
          'Activity',
      actorName: _firstString(
            json,
            const ['actorName', 'name', 'adminName', 'userName'],
          ) ??
          'Unknown actor',
      actorRole: _firstString(
            json,
            const ['actorRole', 'role', 'userRole'],
          ) ??
          'SUPERADMIN',
      createdAt: _firstDate(
        json,
        const ['createdAt', 'updatedAt', 'date', 'time'],
      ),
      actorId: _firstNum(json, const ['actorId', 'adminId', 'userId'])?.toInt(),
    );
  }
}

class SuperadminActorOption {
  const SuperadminActorOption({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory SuperadminActorOption.fromJson(Map<String, dynamic> json) {
    return SuperadminActorOption(
      id: _firstInt(json, const ['id', 'adminId', 'userId']),
      name: _firstString(json, const ['name', 'fullName', 'displayName']) ?? 'Unknown',
    );
  }

  static List<SuperadminActorOption> listFromJson(dynamic json) {
    final list = json is List
        ? json
        : _firstList(_asMap(json), const ['items', 'rows', 'data']) ??
            const <dynamic>[];

    return list
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(SuperadminActorOption.fromJson)
        .where((item) => item.id > 0)
        .toList(growable: false);
  }
}

List<SuperadminAdoptionPoint> _parseAdoptionGrowth(Map<String, dynamic> json) {
  final list = _firstList(
    json,
    const [
      'adoptionGrowth',
      'adoptionGraph',
      'adoptiongraph',
      'growth',
      'chart',
      'graph',
    ],
  );
  if (list == null) {
    return const <SuperadminAdoptionPoint>[];
  }

  return list
      .map(_asMap)
      .where((item) => item.isNotEmpty)
      .map(SuperadminAdoptionPoint.fromJson)
      .toList(growable: false);
}

List<SuperadminRecentVehicle> _parseRecentVehicles(Map<String, dynamic> json) {
  final list = _firstList(
    json,
    const ['recentVehicles', 'vehicles', 'latestVehicles', 'vehicleList'],
  );
  if (list == null) {
    return const <SuperadminRecentVehicle>[];
  }

  return list
      .map(_asMap)
      .where((item) => item.isNotEmpty)
      .map(SuperadminRecentVehicle.fromJson)
      .toList(growable: false);
}

List<SuperadminTransaction> _parseTransactions(Map<String, dynamic> json) {
  final list = _firstList(
    json,
    const [
      'transactions',
      'recentTransactions',
      'payments',
      'latestTransactions',
    ],
  );
  if (list == null) {
    return const <SuperadminTransaction>[];
  }

  return list
      .map(_asMap)
      .where((item) => item.isNotEmpty)
      .map(SuperadminTransaction.fromJson)
      .toList(growable: false);
}

List<SuperadminRecentUser> _parseRecentUsers(Map<String, dynamic> json) {
  final list = _firstList(
    json,
    const ['recentUsers', 'users', 'latestUsers', 'recentAdmins'],
  );
  if (list == null) {
    return const <SuperadminRecentUser>[];
  }

  return list
      .map(_asMap)
      .where((item) => item.isNotEmpty)
      .map(SuperadminRecentUser.fromJson)
      .toList(growable: false);
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

List<dynamic>? _firstList(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is List) {
      return value;
    }
  }

  return null;
}

num? _firstNum(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is num) {
      return value;
    }

    if (value is String) {
      final normalized = value.replaceAll(',', '').trim();
      if (normalized.isEmpty) {
        continue;
      }

      final parsed = num.tryParse(normalized);
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return null;
}

int _firstInt(Map<String, dynamic> source, List<String> keys) {
  return _firstNum(source, keys)?.toInt() ?? 0;
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

DateTime? _firstDate(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return null;
}

String _formatAdoptionLabel(String? month, int? year) {
  final normalizedMonth = month?.trim();
  if (normalizedMonth == null || normalizedMonth.isEmpty) {
    return '—';
  }
  if (year == null) {
    return normalizedMonth;
  }

  final suffix = (year % 100).toString().padLeft(2, '0');
  return '$normalizedMonth\'$suffix';
}

String _transactionTitle(String? name, String? username) {
  final safeName = name?.trim();
  final safeUsername = username?.trim();

  if (safeName != null && safeName.isNotEmpty) {
    if (safeUsername != null && safeUsername.isNotEmpty) {
      return '$safeName (@$safeUsername)';
    }
    return safeName;
  }

  if (safeUsername != null && safeUsername.isNotEmpty) {
    return '@$safeUsername';
  }

  return 'Transaction';
}

String _relativeTimeLabel(DateTime? date) {
  if (date == null) {
    return '—';
  }

  final difference = DateTime.now().difference(date.toLocal());
  if (difference.inMinutes < 1) {
    return 'just now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }
  if (difference.inDays == 1) {
    return 'yesterday';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }
  return '${difference.inDays}d ago';
}

const Object _unsetValue = Object();
