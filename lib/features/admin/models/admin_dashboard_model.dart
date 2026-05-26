class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.generatedAt,
    required this.selectedCurrency,
    required this.defaultCurrency,
    required this.availableCurrencies,
    required this.currency,
    required this.totals,
    required this.revenue,
    required this.expiry,
    required this.installs,
    required this.vehicleLiveStatus,
    required this.graph,
    required this.graphMeta,
    required this.topClients,
    required this.recent,
  });

  final DateTime? generatedAt;
  final String selectedCurrency;
  final String defaultCurrency;
  final List<String> availableCurrencies;
  final String currency;
  final AdminDashboardTotals totals;
  final AdminDashboardRevenue revenue;
  final AdminDashboardExpiry expiry;
  final AdminDashboardInstalls installs;
  final AdminVehicleLiveStatus vehicleLiveStatus;
  final List<AdminMonthGraphPoint> graph;
  final AdminGraphMeta graphMeta;
  final List<AdminTopClient> topClients;
  final AdminDashboardRecent recent;

  int get totalVehicles => totals.totalVehicles;
  int get onlineVehicles => vehicleLiveStatus.connected;
  int get totalUsers => totals.totalUsers;
  int get alertsToday => expiry.thisWeek;

  factory AdminDashboardSummary.fromJson(dynamic json) {
    final source = _dashboardObject(json);
    final totals = AdminDashboardTotals.fromJson(
      _firstMap(
            source,
            const ['totals', 'totalCounts', 'overview', 'stats', 'counts'],
          ) ??
          source,
    );
    final selectedCurrency = _normalizeCurrency(
      _firstString(source, const ['selectedCurrency', 'currency']) ??
          _firstString(source, const ['defaultCurrency']) ??
          'USD',
    );

    return AdminDashboardSummary(
      generatedAt: _firstDate(source, const ['generatedAt', 'updatedAt']),
      selectedCurrency: selectedCurrency,
      defaultCurrency: _normalizeCurrency(
        _firstString(source, const ['defaultCurrency']) ?? selectedCurrency,
      ),
      availableCurrencies: _parseCurrencies(source, selectedCurrency),
      currency: _normalizeCurrency(
        _firstString(source, const ['currency']) ?? selectedCurrency,
      ),
      totals: totals,
      revenue: AdminDashboardRevenue.fromJson(
        _firstMap(source, const ['revenue', 'payments']) ?? source,
      ),
      expiry: AdminDashboardExpiry.fromJson(
        _firstMap(source, const ['expiry', 'vehicleExpiry']) ?? source,
      ),
      installs: AdminDashboardInstalls.fromJson(
        _firstMap(source, const ['installs', 'deviceInstalls']) ?? source,
      ),
      vehicleLiveStatus: AdminVehicleLiveStatus.fromJson(
        _firstMap(source, const ['vehicleLiveStatus', 'vehicleStatus']) ??
            source,
        totalVehicles: totals.totalVehicles,
      ),
      graph: AdminMonthGraphPoint.listFromJson(
        _firstList(source, const ['graph', 'monthGraph', 'growth']) ??
            const <dynamic>[],
      ),
      graphMeta: AdminGraphMeta.fromJson(
        _firstMap(source, const ['graphMeta']) ?? const <String, dynamic>{},
      ),
      topClients: AdminTopClient.listFromJson(
        _firstList(source, const ['topClients', 'clients']) ??
            const <dynamic>[],
      ),
      recent: AdminDashboardRecent.fromJson(
        _firstMap(source, const ['recent']) ?? source,
      ),
    );
  }
}

class AdminDashboardTotals {
  const AdminDashboardTotals({
    required this.totalVehicles,
    required this.totalUsers,
  });

  final int totalVehicles;
  final int totalUsers;

  factory AdminDashboardTotals.fromJson(Map<String, dynamic> json) {
    return AdminDashboardTotals(
      totalVehicles: _firstInt(
        json,
        const ['totalVehicles', 'vehiclesCount', 'vehicleCount'],
      ),
      totalUsers:
          _firstInt(json, const ['totalUsers', 'usersCount', 'userCount']),
    );
  }
}

class AdminDashboardRevenue {
  const AdminDashboardRevenue({
    required this.lastMonthRevenue,
    required this.thisMonthRevenue,
    required this.pendingAmount,
    required this.pendingCount,
    required this.expectedRenewalRevenue,
    required this.projectedThisMonth,
  });

  final double lastMonthRevenue;
  final double thisMonthRevenue;
  final double pendingAmount;
  final int pendingCount;
  final double expectedRenewalRevenue;
  final double projectedThisMonth;

  factory AdminDashboardRevenue.fromJson(Map<String, dynamic> json) {
    return AdminDashboardRevenue(
      lastMonthRevenue: _firstDouble(json, const ['lastMonthRevenue']),
      thisMonthRevenue: _firstDouble(json, const ['thisMonthRevenue']),
      pendingAmount: _firstDouble(json, const ['pendingAmount']),
      pendingCount: _firstInt(json, const ['pendingCount']),
      expectedRenewalRevenue:
          _firstDouble(json, const ['expectedRenewalRevenue']),
      projectedThisMonth: _firstDouble(json, const ['projectedThisMonth']),
    );
  }
}

class AdminDashboardExpiry {
  const AdminDashboardExpiry({
    required this.thisWeek,
    required this.thisMonth,
    required this.preview,
  });

  final int thisWeek;
  final int thisMonth;
  final List<AdminExpiryPreviewVehicle> preview;

  factory AdminDashboardExpiry.fromJson(Map<String, dynamic> json) {
    return AdminDashboardExpiry(
      thisWeek: _firstInt(json, const ['thisWeek', 'expiryThisWeek']),
      thisMonth: _firstInt(json, const ['thisMonth', 'expiryThisMonth']),
      preview: AdminExpiryPreviewVehicle.listFromJson(
        _firstList(json, const ['preview', 'vehicles']) ?? const <dynamic>[],
      ),
    );
  }
}

class AdminExpiryPreviewVehicle {
  const AdminExpiryPreviewVehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.imei,
    required this.secondaryExpiry,
    required this.primaryUserId,
    required this.userPrimary,
    required this.plan,
  });

  final int id;
  final String name;
  final String? plateNumber;
  final String? imei;
  final DateTime? secondaryExpiry;
  final int? primaryUserId;
  final AdminExpiryUserMini? userPrimary;
  final AdminExpiryPlanMini? plan;

  String? get primaryUserName => userPrimary?.name;
  String? get planName => plan?.name;
  double get planPrice => plan?.price ?? 0;
  String? get planCurrency => plan?.currency;

  int? daysLeft(DateTime now) {
    if (secondaryExpiry == null) {
      return null;
    }

    final difference = secondaryExpiry!.difference(now);
    return difference.inHours <= 0 ? 0 : (difference.inHours / 24).ceil();
  }

  factory AdminExpiryPreviewVehicle.fromJson(Map<String, dynamic> json) {
    return AdminExpiryPreviewVehicle(
      id: _firstInt(json, const ['id', '_id', 'vehicleId']),
      name: _firstString(json, const ['name', 'vehicleName']) ?? 'Vehicle',
      plateNumber: _firstString(json, const ['plateNumber', 'plateNo']),
      imei: _firstString(json, const ['imei']),
      secondaryExpiry: _firstDate(
        json,
        const ['secondaryExpiry', 'expiry', 'expiresAt'],
      ),
      primaryUserId: _firstIntOrNull(json, const ['primaryUserId', 'userId']),
      userPrimary: AdminExpiryUserMini.tryFromJson(
        _firstMap(json, const ['userPrimary', 'user', 'owner']),
      ),
      plan: AdminExpiryPlanMini.tryFromJson(
        _firstMap(json, const ['plan', 'pricingPlan']),
      ),
    );
  }

  static List<AdminExpiryPreviewVehicle> listFromJson(List<dynamic> list) {
    return list
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminExpiryPreviewVehicle.fromJson)
        .toList(growable: false);
  }
}

class AdminExpiryUserMini {
  const AdminExpiryUserMini({
    required this.uid,
    required this.name,
  });

  final int uid;
  final String name;

  static AdminExpiryUserMini? tryFromJson(dynamic json) {
    final source = _asMap(json);
    if (source.isEmpty) {
      return null;
    }

    return AdminExpiryUserMini(
      uid: _firstInt(source, const ['uid', 'id', 'userId']),
      name: _firstString(source, const ['name', 'username']) ?? 'Unknown',
    );
  }
}

class AdminExpiryPlanMini {
  const AdminExpiryPlanMini({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
  });

  final int id;
  final String name;
  final double price;
  final String currency;

  static AdminExpiryPlanMini? tryFromJson(dynamic json) {
    final source = _asMap(json);
    if (source.isEmpty) {
      return null;
    }

    return AdminExpiryPlanMini(
      id: _firstInt(source, const ['id', 'planId']),
      name: _firstString(source, const ['name', 'planName']) ?? 'Plan',
      price: _firstDouble(source, const ['price', 'amount']),
      currency: _normalizeCurrency(
        _firstString(source, const ['currency']) ?? 'USD',
      ),
    );
  }
}

class AdminDashboardInstalls {
  const AdminDashboardInstalls({required this.thisMonth});

  final int thisMonth;

  factory AdminDashboardInstalls.fromJson(Map<String, dynamic> json) {
    return AdminDashboardInstalls(
      thisMonth:
          _firstInt(json, const ['thisMonth', 'deviceInstallsThisMonth']),
    );
  }
}

class AdminVehicleLiveStatus {
  const AdminVehicleLiveStatus({
    required this.all,
    required this.connected,
    required this.running,
    required this.stop,
    required this.inactive,
    required this.noData,
    required this.noDevice,
    this.notInstalled,
  });

  final int all;
  final int connected;
  final int running;
  final int stop;
  final int inactive;
  final int noData;
  final int noDevice;
  final int? notInstalled;

  int get installedDevices => all;

  factory AdminVehicleLiveStatus.fromJson(
    Map<String, dynamic> json, {
    int totalVehicles = 0,
  }) {
    final connected = _firstInt(json, const ['connected', 'online']);
    final running = _firstInt(json, const ['running', 'moving']);
    final stop = _firstInt(json, const ['stop', 'stopped']);
    final inactive = _firstInt(json, const ['inactive']);
    final noData = _firstInt(json, const ['noData', 'noDataCount', 'unknown']);
    final explicitAll = _firstIntOrNull(
      json,
      const ['all', 'totalDevices', 'devicesInstalled'],
    );
    final notInstalled = _firstIntOrNull(json, const ['notInstalled']);
    final noDevice = _firstIntOrNull(json, const ['noDevice']) ?? notInstalled;
    final derivedAll = connected + running + stop + inactive + noData;
    final all = explicitAll ?? derivedAll;
    final derivedNoDevice = totalVehicles - all;

    return AdminVehicleLiveStatus(
      all: all < 0 ? 0 : all,
      connected: connected,
      running: running,
      stop: stop,
      inactive: inactive,
      noData: noData,
      noDevice: noDevice ?? (derivedNoDevice > 0 ? derivedNoDevice : 0),
      notInstalled: notInstalled,
    );
  }
}

class AdminMonthGraphPoint {
  const AdminMonthGraphPoint({
    required this.month,
    required this.year,
    required this.userCount,
    required this.vehicleCount,
  });

  final String month;
  final int year;
  final int userCount;
  final int vehicleCount;

  String get label {
    if (month.isEmpty || year <= 0) {
      return month;
    }
    return '$month\'${(year % 100).toString().padLeft(2, '0')}';
  }

  factory AdminMonthGraphPoint.fromJson(Map<String, dynamic> json) {
    return AdminMonthGraphPoint(
      month: _firstString(json, const ['month', 'label']) ?? '',
      year: _firstInt(json, const ['year']),
      userCount: _firstInt(json, const ['userCount', 'users']),
      vehicleCount: _firstInt(json, const ['vehicleCount', 'vehicles']),
    );
  }

  static List<AdminMonthGraphPoint> listFromJson(List<dynamic> list) {
    return list
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminMonthGraphPoint.fromJson)
        .toList(growable: false);
  }
}

class AdminGraphMeta {
  const AdminGraphMeta({
    required this.months,
    required this.rangeStartISO,
    required this.rangeEndISO,
  });

  final int months;
  final DateTime? rangeStartISO;
  final DateTime? rangeEndISO;

  factory AdminGraphMeta.fromJson(Map<String, dynamic> json) {
    return AdminGraphMeta(
      months: _firstInt(json, const ['months']),
      rangeStartISO: _firstDate(json, const ['rangeStartISO', 'rangeStart']),
      rangeEndISO: _firstDate(json, const ['rangeEndISO', 'rangeEnd']),
    );
  }
}

class AdminTopClient {
  const AdminTopClient({
    required this.userId,
    required this.name,
    required this.revenue,
    required this.due,
    required this.vehicles,
    required this.lastPaymentAt,
  });

  final int userId;
  final String name;
  final double revenue;
  final double due;
  final int vehicles;
  final DateTime? lastPaymentAt;

  factory AdminTopClient.fromJson(Map<String, dynamic> json) {
    return AdminTopClient(
      userId: _firstInt(json, const ['userId', 'id', 'uid']),
      name: _firstString(json, const ['name', 'username']) ?? 'Unknown',
      revenue: _firstDouble(json, const ['revenue', 'amount']),
      due: _firstDouble(json, const ['due', 'pending']),
      vehicles: _firstInt(json, const ['vehicles', 'vehicleCount']),
      lastPaymentAt: _firstDate(json, const ['lastPaymentAt', 'createdAt']),
    );
  }

  static List<AdminTopClient> listFromJson(List<dynamic> list) {
    return list
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminTopClient.fromJson)
        .toList(growable: false);
  }
}

class AdminRecentUser {
  const AdminRecentUser({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.createdAt,
    required this.isActive,
  });

  final int uid;
  final String name;
  final String username;
  final String email;
  final DateTime? createdAt;
  final bool isActive;

  factory AdminRecentUser.fromJson(Map<String, dynamic> json) {
    return AdminRecentUser(
      uid: _firstInt(json, const ['uid', 'id', '_id']),
      name: _firstString(json, const ['name', 'displayName']) ?? 'Unknown user',
      username: _firstString(json, const ['username']) ?? '',
      email: _firstString(json, const ['email']) ?? '',
      createdAt: _firstDate(json, const ['createdAt', 'joinedAt']),
      isActive: _firstBool(json, const ['isActive', 'active']),
    );
  }

  static List<AdminRecentUser> listFromJson(List<dynamic> list) {
    return list
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminRecentUser.fromJson)
        .toList(growable: false);
  }
}

class AdminRecentVehicle {
  const AdminRecentVehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.imei,
    required this.deviceId,
    required this.createdAt,
    required this.secondaryExpiry,
    required this.isLicenseBlocked,
    required this.licenseBlockedAt,
    required this.licenseBlockReason,
    required this.primaryUserId,
    required this.userPrimary,
    required this.liveStatus,
    required this.hasDevice,
  });

  final int id;
  final String name;
  final String? plateNumber;
  final String? imei;
  final int? deviceId;
  final DateTime? createdAt;
  final DateTime? secondaryExpiry;
  final bool isLicenseBlocked;
  final DateTime? licenseBlockedAt;
  final String? licenseBlockReason;
  final int? primaryUserId;
  final AdminExpiryUserMini? userPrimary;
  final String liveStatus;
  final bool hasDevice;

  String get status => liveStatus;
  bool get licenseBlocked => isLicenseBlocked;
  String? get primaryUserName => userPrimary?.name;

  factory AdminRecentVehicle.fromJson(Map<String, dynamic> json) {
    final deviceId = _firstIntOrNull(json, const ['deviceId']);
    final imei = _firstString(json, const ['imei']);
    final explicitHasDevice = _firstBoolOrNull(json, const ['hasDevice']);
    final isLicenseBlocked = _firstBool(json, const ['isLicenseBlocked']);
    final hasDevice = explicitHasDevice ?? (deviceId != null && imei != null);

    return AdminRecentVehicle(
      id: _firstInt(json, const ['id', '_id', 'vehicleId']),
      name: _firstString(json, const ['name', 'vehicleName']) ?? 'Vehicle',
      plateNumber: _firstString(json, const ['plateNumber', 'plateNo']),
      imei: imei,
      deviceId: deviceId,
      createdAt: _firstDate(json, const ['createdAt']),
      secondaryExpiry: _firstDate(json, const ['secondaryExpiry']),
      isLicenseBlocked: isLicenseBlocked,
      licenseBlockedAt: _firstDate(json, const ['licenseBlockedAt']),
      licenseBlockReason: _firstString(json, const ['licenseBlockReason']),
      primaryUserId: _firstIntOrNull(json, const ['primaryUserId', 'userId']),
      userPrimary: AdminExpiryUserMini.tryFromJson(
        _firstMap(json, const ['userPrimary', 'user', 'owner']),
      ),
      liveStatus: _normalizeLiveStatus(
        _firstString(json, const ['liveStatus', 'status']),
        hasDevice: hasDevice,
        isLicenseBlocked: isLicenseBlocked,
      ),
      hasDevice: hasDevice,
    );
  }

  static List<AdminRecentVehicle> listFromJson(List<dynamic> list) {
    return list
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminRecentVehicle.fromJson)
        .toList(growable: false);
  }
}

class AdminRecentPayment {
  const AdminRecentPayment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.reference,
    required this.fromUser,
    required this.vehicle,
  });

  final int id;
  final String amount;
  final String currency;
  final String status;
  final DateTime? createdAt;
  final String? reference;
  final AdminRecentPaymentUser? fromUser;
  final AdminRecentPaymentVehicle? vehicle;

  double get amountValue => _parseDouble(amount) ?? 0;
  String get userName => fromUser?.name ?? fromUser?.username ?? 'Unknown';
  String? get vehicleName => vehicle?.plateNumber ?? vehicle?.name;

  factory AdminRecentPayment.fromJson(Map<String, dynamic> json) {
    return AdminRecentPayment(
      id: _firstInt(json, const ['id', '_id', 'transactionId']),
      amount: _firstAmountString(json, const ['amount']),
      currency: _normalizeCurrency(
        _firstString(json, const ['currency', 'currencyCode']) ?? 'USD',
      ),
      status: _normalizeStatus(
        _firstString(json, const ['status', 'paymentStatus']) ?? 'PENDING',
      ),
      createdAt: _firstDate(json, const ['createdAt', 'paidAt']),
      reference: _firstString(json, const ['reference', 'ref']),
      fromUser: AdminRecentPaymentUser.tryFromJson(
        _firstMap(json, const ['fromUser', 'user']),
      ),
      vehicle: AdminRecentPaymentVehicle.tryFromJson(
        _firstMap(json, const ['vehicle']),
      ),
    );
  }

  static List<AdminRecentPayment> listFromJson(List<dynamic> list) {
    return list
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminRecentPayment.fromJson)
        .toList(growable: false);
  }
}

class AdminRecentPaymentUser {
  const AdminRecentPaymentUser({
    required this.uid,
    required this.name,
    required this.username,
  });

  final int uid;
  final String name;
  final String username;

  static AdminRecentPaymentUser? tryFromJson(dynamic json) {
    final source = _asMap(json);
    if (source.isEmpty) {
      return null;
    }

    return AdminRecentPaymentUser(
      uid: _firstInt(source, const ['uid', 'id', 'userId']),
      name: _firstString(source, const ['name']) ?? '',
      username: _firstString(source, const ['username']) ?? '',
    );
  }
}

class AdminRecentPaymentVehicle {
  const AdminRecentPaymentVehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
  });

  final int id;
  final String name;
  final String? plateNumber;

  static AdminRecentPaymentVehicle? tryFromJson(dynamic json) {
    final source = _asMap(json);
    if (source.isEmpty) {
      return null;
    }

    return AdminRecentPaymentVehicle(
      id: _firstInt(source, const ['id', '_id', 'vehicleId']),
      name: _firstString(source, const ['name', 'vehicleName']) ?? 'Vehicle',
      plateNumber: _firstString(source, const ['plateNumber', 'plateNo']),
    );
  }
}

class AdminDashboardRecent {
  const AdminDashboardRecent({
    required this.users,
    required this.vehicles,
    required this.payments,
  });

  final List<AdminRecentUser> users;
  final List<AdminRecentVehicle> vehicles;
  final List<AdminRecentPayment> payments;

  factory AdminDashboardRecent.fromJson(Map<String, dynamic> json) {
    return AdminDashboardRecent(
      users: AdminRecentUser.listFromJson(
        _firstList(json, const ['users', 'recentUsers']) ?? const <dynamic>[],
      ),
      vehicles: AdminRecentVehicle.listFromJson(
        _firstList(json, const ['vehicles', 'recentVehicles']) ??
            const <dynamic>[],
      ),
      payments: AdminRecentPayment.listFromJson(
        _firstList(json, const ['payments', 'recentPayments']) ??
            const <dynamic>[],
      ),
    );
  }
}

Map<String, dynamic> _dashboardObject(dynamic value) {
  final source = _asMap(value);
  if (source.isEmpty) {
    return const <String, dynamic>{};
  }

  final nested = _asMap(source['data']);
  if (nested.isNotEmpty &&
      (_looksLikeEnvelope(source) || _looksLikeDashboard(nested))) {
    return _dashboardObject(nested);
  }

  return source;
}

bool _looksLikeEnvelope(Map<String, dynamic> source) {
  return source.containsKey('data') &&
      (source.containsKey('action') ||
          source.containsKey('message') ||
          source.containsKey('status') ||
          source.containsKey('success') ||
          source.containsKey('timestamp'));
}

bool _looksLikeDashboard(Map<String, dynamic> source) {
  return source.containsKey('totals') ||
      source.containsKey('revenue') ||
      source.containsKey('expiry') ||
      source.containsKey('vehicleLiveStatus') ||
      source.containsKey('generatedAt') ||
      source.containsKey('recent');
}

List<String> _parseCurrencies(
  Map<String, dynamic> source,
  String fallbackCurrency,
) {
  final raw = _firstList(source, const ['availableCurrencies']);
  final currencies = raw
          ?.map((item) => _normalizeCurrency(item.toString()))
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false) ??
      const <String>[];

  if (currencies.isNotEmpty) {
    return currencies;
  }

  return <String>[fallbackCurrency];
}

String _normalizeCurrency(String value) {
  final raw = value.trim().toUpperCase();
  const aliases = <String, String>{
    'CA': 'CAD',
    'US': 'USD',
    'IN': 'INR',
    'EU': 'EUR',
    'GB': 'GBP',
    'AE': 'AED',
  };
  return aliases[raw] ?? (raw.isEmpty ? 'USD' : raw);
}

String _normalizeLiveStatus(
  String? value, {
  required bool hasDevice,
  required bool isLicenseBlocked,
}) {
  if (isLicenseBlocked) {
    return 'LICENSE_BLOCKED';
  }

  final raw =
      value?.trim().replaceAll('-', '_').replaceAll(' ', '_').toUpperCase();

  switch (raw) {
    case 'RUNNING':
    case 'MOVING':
      return 'RUNNING';
    case 'STOP':
    case 'STOPPED':
    case 'IDLE':
      return 'STOP';
    case 'INACTIVE':
      return 'INACTIVE';
    case 'NOT_INSTALLED':
    case 'NO_DEVICE':
    case 'NODEVICE':
      return 'NOT_INSTALLED';
    case 'LICENSE_BLOCKED':
      return 'LICENSE_BLOCKED';
    case 'NO_DATA':
    case 'NODATA':
    case 'UNKNOWN':
      return 'NO_DATA';
  }

  return hasDevice ? 'NO_DATA' : 'NOT_INSTALLED';
}

String _normalizeStatus(String value) {
  return value.trim().replaceAll('-', '_').replaceAll(' ', '_').toUpperCase();
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

double _firstDouble(Map<String, dynamic> source, List<String> keys) {
  return _firstNum(source, keys)?.toDouble() ?? 0;
}

int _firstInt(Map<String, dynamic> source, List<String> keys) {
  return _firstNum(source, keys)?.toInt() ?? 0;
}

int? _firstIntOrNull(Map<String, dynamic> source, List<String> keys) {
  return _firstNum(source, keys)?.toInt();
}

num? _firstNum(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is num) {
      return value;
    }

    if (value is String) {
      final parsed = _parseDouble(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return null;
}

double? _parseDouble(String value) {
  final normalized = value.replaceAll(',', '').trim();
  if (normalized.isEmpty) {
    return null;
  }

  return double.tryParse(normalized);
}

String _firstAmountString(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (value is num) {
      return value.toString();
    }
  }

  return '0';
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

bool _firstBool(Map<String, dynamic> source, List<String> keys) {
  return _firstBoolOrNull(source, keys) ?? false;
}

bool? _firstBoolOrNull(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
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

    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return null;
}
