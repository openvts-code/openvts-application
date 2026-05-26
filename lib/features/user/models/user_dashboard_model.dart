import '../../superadmin/models/superadmin_vehicle_model.dart';

typedef UserDashboardCustomCommand = SuperadminCustomCommand;
typedef UserDashboardSystemVariable = SuperadminSystemVariable;

const List<String> userDashboardLayoutBreakpoints = [
  'lg',
  'md',
  'sm',
  'xs',
  'xxs',
];

const List<String> userDashboardMobileLayoutPreference = [
  'xxs',
  'xs',
  'sm',
  'md',
  'lg',
];

const Map<String, String> userDashboardWidgetTitles = {
  'component_1': 'Fleet Status',
  'fleet_status': 'Fleet Status',
  'component_2': '7-Day Usage',
  'usage_last_7_days': '7-Day Usage',
  'component_3': 'Recent Alerts',
  'recent_alerts': 'Recent Alerts',
  'component_4': 'Weekly Comparison',
  'weekly_comparison': 'Weekly Comparison',
  'component_5': 'Top Performing Assets',
  'top_performing_assets': 'Top Performing Assets',
  'component_6': 'Sensor History',
  'sensor_history': 'Sensor History',
  'component_7': 'Send Command',
  'send_command': 'Send Command',
  'component_9': 'Day / Night Comparison',
  'day_night_comparison': 'Day / Night Comparison',
};

class UserDashboardListItem {
  const UserDashboardListItem({
    required this.id,
    required this.name,
    required this.version,
    this.updatedAt,
  });

  final String id;
  final String name;
  final int version;
  final DateTime? updatedAt;

  factory UserDashboardListItem.fromJson(dynamic json) {
    final source = _asMap(_unwrapResponse(json));
    return UserDashboardListItem(
      id: _firstString(source, const ['id', '_id', 'uid']) ?? '',
      name:
          _firstString(source, const ['name', 'title', 'label']) ?? 'Dashboard',
      version: _firstInt(source, const ['version']) ?? 1,
      updatedAt: _firstDateTime(source, const ['updatedAt', 'updated_at']),
    );
  }

  static List<UserDashboardListItem> listFromResponse(dynamic json) {
    return _listFromResponse(json)
        .map(UserDashboardListItem.fromJson)
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class UserDashboardDetail {
  const UserDashboardDetail({
    required this.id,
    required this.name,
    required this.version,
    required this.config,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserDashboardConfig config;

  factory UserDashboardDetail.fromJson(dynamic json) {
    final source = _asMap(_unwrapResponse(json));
    return UserDashboardDetail(
      id: _firstString(source, const ['id', '_id', 'uid']) ?? '',
      name:
          _firstString(source, const ['name', 'title', 'label']) ?? 'Dashboard',
      version: _firstInt(source, const ['version']) ?? 1,
      createdAt: _firstDateTime(source, const ['createdAt', 'created_at']),
      updatedAt: _firstDateTime(source, const ['updatedAt', 'updated_at']),
      config: UserDashboardConfig.fromJson(source['config']),
    );
  }
}

class UserDashboardConfig {
  const UserDashboardConfig({
    required this.widgets,
    required this.layouts,
  });

  const UserDashboardConfig.empty()
      : widgets = const <UserDashboardWidgetConfig>[],
        layouts = const <String, List<UserDashboardLayoutItem>>{};

  final List<UserDashboardWidgetConfig> widgets;
  final Map<String, List<UserDashboardLayoutItem>> layouts;

  factory UserDashboardConfig.fromJson(dynamic json) {
    final source = _asMap(json);
    final layoutSource = _asMap(source['layouts']);
    final layouts = <String, List<UserDashboardLayoutItem>>{};

    for (final entry in layoutSource.entries) {
      layouts[entry.key] = _asList(entry.value)
          .map(UserDashboardLayoutItem.fromJson)
          .where((item) => item.i.trim().isNotEmpty)
          .toList(growable: false);
    }

    for (final breakpoint in userDashboardLayoutBreakpoints) {
      layouts.putIfAbsent(
        breakpoint,
        () => const <UserDashboardLayoutItem>[],
      );
    }

    return UserDashboardConfig(
      widgets: _asList(source['widgets'])
          .map(UserDashboardWidgetConfig.fromJson)
          .where((item) => item.id.trim().isNotEmpty)
          .toList(growable: false),
      layouts: Map.unmodifiable(layouts),
    );
  }
}

class UserDashboardWidgetConfig {
  const UserDashboardWidgetConfig({
    required this.id,
    required this.type,
    this.props = const <String, dynamic>{},
  });

  final String id;
  final String type;
  final Map<String, dynamic> props;

  String get title => userDashboardWidgetTitles[type] ?? 'Unknown Widget';

  bool get isSupported => userDashboardWidgetTitles.containsKey(type);

  factory UserDashboardWidgetConfig.fromJson(dynamic json) {
    final source = _asMap(json);
    final id = _firstString(source, const ['id', 'i', 'widgetId', 'widget_id']);
    return UserDashboardWidgetConfig(
      id: id ?? '',
      type: _firstString(source, const ['type', 'component', 'kind']) ?? '',
      props: Map.unmodifiable(_asMap(source['props'])),
    );
  }
}

class UserDashboardLayoutItem {
  const UserDashboardLayoutItem({
    required this.i,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.minW,
    this.minH,
    this.maxW,
    this.maxH,
  });

  final String i;
  final int x;
  final int y;
  final int w;
  final int h;
  final int? minW;
  final int? minH;
  final int? maxW;
  final int? maxH;

  factory UserDashboardLayoutItem.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardLayoutItem(
      i: _firstString(source, const ['i', 'id', 'widgetId', 'widget_id']) ?? '',
      x: _firstInt(source, const ['x']) ?? 0,
      y: _firstInt(source, const ['y']) ?? 0,
      w: _firstInt(source, const ['w', 'width']) ?? 1,
      h: _firstInt(source, const ['h', 'height']) ?? 1,
      minW: _firstInt(source, const ['minW', 'min_w']),
      minH: _firstInt(source, const ['minH', 'min_h']),
      maxW: _firstInt(source, const ['maxW', 'max_w']),
      maxH: _firstInt(source, const ['maxH', 'max_h']),
    );
  }
}

class UserDashboardFleetStatus {
  const UserDashboardFleetStatus({
    required this.totalVehicles,
    required this.withDevice,
    required this.noDevice,
    required this.buckets,
    required this.percentages,
    this.updatedAt,
  });

  final int totalVehicles;
  final int withDevice;
  final int noDevice;
  final UserDashboardFleetStatusBuckets buckets;
  final UserDashboardFleetStatusPercentages percentages;
  final DateTime? updatedAt;

  factory UserDashboardFleetStatus.fromJson(dynamic json) {
    final source = _asMap(_unwrapResponse(json));
    return UserDashboardFleetStatus(
      totalVehicles:
          _firstInt(source, const ['totalVehicles', 'total_vehicles']) ?? 0,
      withDevice: _firstInt(source, const ['withDevice', 'with_device']) ?? 0,
      noDevice: _firstInt(source, const ['noDevice', 'no_device']) ?? 0,
      buckets: UserDashboardFleetStatusBuckets.fromJson(source['buckets']),
      percentages: UserDashboardFleetStatusPercentages.fromJson(
        source['percentages'],
      ),
      updatedAt: _firstDateTime(source, const ['updatedAt', 'updated_at']),
    );
  }
}

class UserDashboardFleetStatusBuckets {
  const UserDashboardFleetStatusBuckets({
    required this.total,
    required this.connected,
    required this.running,
    required this.idle,
    required this.stopped,
    required this.inactive,
    required this.noData,
  });

  final int total;
  final int connected;
  final int running;
  final int idle;
  final int stopped;
  final int inactive;
  final int noData;

  factory UserDashboardFleetStatusBuckets.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardFleetStatusBuckets(
      total: _firstInt(source, const ['total']) ?? 0,
      connected: _firstInt(source, const ['connected']) ?? 0,
      running: _firstInt(source, const ['running']) ?? 0,
      idle: _firstInt(source, const ['idle']) ?? 0,
      stopped: _firstInt(source, const ['stopped']) ?? 0,
      inactive: _firstInt(source, const ['inactive']) ?? 0,
      noData: _firstInt(source, const ['noData', 'no_data']) ?? 0,
    );
  }
}

class UserDashboardFleetStatusPercentages {
  const UserDashboardFleetStatusPercentages({
    required this.running,
    required this.idle,
    required this.stopped,
    required this.inactive,
    required this.noData,
    required this.connected,
    required this.noDevice,
  });

  final double running;
  final double idle;
  final double stopped;
  final double inactive;
  final double noData;
  final double connected;
  final double noDevice;

  factory UserDashboardFleetStatusPercentages.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardFleetStatusPercentages(
      running: _firstDouble(source, const ['running']) ?? 0,
      idle: _firstDouble(source, const ['idle']) ?? 0,
      stopped: _firstDouble(source, const ['stopped']) ?? 0,
      inactive: _firstDouble(source, const ['inactive']) ?? 0,
      noData: _firstDouble(source, const ['noData', 'no_data']) ?? 0,
      connected: _firstDouble(source, const ['connected']) ?? 0,
      noDevice: _firstDouble(source, const ['noDevice', 'no_device']) ?? 0,
    );
  }
}

class UserDashboardUsageLast7Days {
  const UserDashboardUsageLast7Days({
    required this.range,
    required this.filter,
    required this.points,
    required this.totals,
    this.updatedAt,
  });

  final UserDashboardDateRange range;
  final UserDashboardVehicleFilter filter;
  final List<UserDashboardUsagePoint> points;
  final UserDashboardMetricPair totals;
  final DateTime? updatedAt;

  factory UserDashboardUsageLast7Days.fromJson(dynamic json) {
    final source = _asMap(_unwrapResponse(json));
    return UserDashboardUsageLast7Days(
      range: UserDashboardDateRange.fromJson(source['range']),
      filter: UserDashboardVehicleFilter.fromJson(source['filter']),
      points: _asList(source['points'])
          .map(UserDashboardUsagePoint.fromJson)
          .toList(growable: false),
      totals: UserDashboardMetricPair.fromJson(source['totals']),
      updatedAt: _firstDateTime(source, const ['updatedAt', 'updated_at']),
    );
  }
}

class UserDashboardUsagePoint {
  const UserDashboardUsagePoint({
    required this.day,
    required this.label,
    required this.drivenKm,
    required this.engineHours,
  });

  final String day;
  final String label;
  final double drivenKm;
  final double engineHours;

  factory UserDashboardUsagePoint.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardUsagePoint(
      day: _firstString(source, const ['day', 'dayKey', 'day_key']) ?? '',
      label: _firstString(source, const ['label']) ?? '',
      drivenKm: _firstDouble(source, const ['drivenKm', 'driven_km']) ?? 0,
      engineHours:
          _firstDouble(source, const ['engineHours', 'engine_hours']) ?? 0,
    );
  }
}

class UserDashboardWeeklyComparison {
  const UserDashboardWeeklyComparison({
    required this.timezoneOffsetMin,
    required this.filter,
    required this.week,
    required this.points,
    required this.totals,
    this.updatedAt,
  });

  final int timezoneOffsetMin;
  final UserDashboardVehicleFilter filter;
  final UserDashboardWeekRange week;
  final List<UserDashboardWeeklyPoint> points;
  final UserDashboardWeeklyTotals totals;
  final DateTime? updatedAt;

  factory UserDashboardWeeklyComparison.fromJson(dynamic json) {
    final source = _asMap(_unwrapResponse(json));
    return UserDashboardWeeklyComparison(
      timezoneOffsetMin: _firstInt(
              source, const ['timezoneOffsetMin', 'timezone_offset_min']) ??
          0,
      filter: UserDashboardVehicleFilter.fromJson(source['filter']),
      week: UserDashboardWeekRange.fromJson(source['week']),
      points: _asList(source['points'])
          .map(UserDashboardWeeklyPoint.fromJson)
          .toList(growable: false),
      totals: UserDashboardWeeklyTotals.fromJson(source['totals']),
      updatedAt: _firstDateTime(source, const ['updatedAt', 'updated_at']),
    );
  }
}

class UserDashboardWeeklyPoint {
  const UserDashboardWeeklyPoint({
    required this.dayIndex,
    required this.label,
    required this.thisWeek,
    required this.lastWeek,
  });

  final int dayIndex;
  final String label;
  final UserDashboardMetricPair thisWeek;
  final UserDashboardMetricPair lastWeek;

  factory UserDashboardWeeklyPoint.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardWeeklyPoint(
      dayIndex: _firstInt(source, const ['dayIndex', 'day_index']) ?? 0,
      label: _firstString(source, const ['label']) ?? '',
      thisWeek: UserDashboardMetricPair.fromJson(source['thisWeek']),
      lastWeek: UserDashboardMetricPair.fromJson(source['lastWeek']),
    );
  }
}

class UserDashboardWeeklyTotals {
  const UserDashboardWeeklyTotals({
    required this.thisWeek,
    required this.lastWeek,
  });

  final UserDashboardMetricPair thisWeek;
  final UserDashboardMetricPair lastWeek;

  factory UserDashboardWeeklyTotals.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardWeeklyTotals(
      thisWeek: UserDashboardMetricPair.fromJson(source['thisWeek']),
      lastWeek: UserDashboardMetricPair.fromJson(source['lastWeek']),
    );
  }
}

class UserDashboardWeekRange {
  const UserDashboardWeekRange({
    required this.thisWeek,
    required this.lastWeek,
    required this.weekStart,
  });

  final UserDashboardDateRange thisWeek;
  final UserDashboardDateRange lastWeek;
  final String weekStart;

  factory UserDashboardWeekRange.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardWeekRange(
      thisWeek: UserDashboardDateRange.fromJson(source['thisWeek']),
      lastWeek: UserDashboardDateRange.fromJson(source['lastWeek']),
      weekStart: _firstString(source, const ['weekStart', 'week_start']) ?? '',
    );
  }
}

class UserDashboardRecentAlertsPage {
  const UserDashboardRecentAlertsPage({
    required this.filter,
    required this.limit,
    this.nextCursor,
    required this.items,
  });

  final UserDashboardVehicleFilter filter;
  final int limit;
  final int? nextCursor;
  final List<UserDashboardAlertItem> items;

  factory UserDashboardRecentAlertsPage.fromJson(dynamic json) {
    final source = _asMap(_unwrapResponse(json));
    return UserDashboardRecentAlertsPage(
      filter: UserDashboardVehicleFilter.fromJson(source['filter']),
      limit: _firstInt(source, const ['limit']) ?? 0,
      nextCursor: _firstInt(source, const ['nextCursor', 'next_cursor']),
      items: _asList(source['items'])
          .map(UserDashboardAlertItem.fromJson)
          .toList(growable: false),
    );
  }
}

class UserDashboardAlertItem {
  const UserDashboardAlertItem({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    this.plateNumber,
    this.imei,
    required this.source,
    required this.severity,
    required this.title,
    required this.message,
    this.meta,
    required this.isRead,
    this.createdAt,
  });

  final String id;
  final String vehicleId;
  final String vehicleName;
  final String? plateNumber;
  final String? imei;
  final String source;
  final String severity;
  final String title;
  final String message;
  final Map<String, dynamic>? meta;
  final bool isRead;
  final DateTime? createdAt;

  factory UserDashboardAlertItem.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardAlertItem(
      id: _firstString(source, const ['id', '_id']) ?? '',
      vehicleId: _firstString(source, const ['vehicleId', 'vehicle_id']) ?? '',
      vehicleName:
          _firstString(source, const ['vehicleName', 'vehicle_name']) ?? '',
      plateNumber: _firstString(source, const ['plateNumber', 'plate_number']),
      imei: _firstString(source, const ['imei']),
      source: _firstString(source, const ['source']) ?? '',
      severity: _firstString(source, const ['severity']) ?? 'INFO',
      title: _firstString(source, const ['title']) ?? '',
      message: _firstString(source, const ['message']) ?? '',
      meta: source['meta'] == null
          ? null
          : Map.unmodifiable(_asMap(source['meta'])),
      isRead: _firstBool(source, const ['isRead', 'is_read', 'read']) ?? false,
      createdAt: _firstDateTime(source, const ['createdAt', 'created_at']),
    );
  }
}

class UserDashboardAlertDetail extends UserDashboardAlertItem {
  const UserDashboardAlertDetail({
    required super.id,
    required super.vehicleId,
    required super.vehicleName,
    super.plateNumber,
    super.imei,
    required super.source,
    required super.severity,
    required super.title,
    required super.message,
    super.meta,
    required super.isRead,
    super.createdAt,
    required this.deliveries,
  });

  final List<UserDashboardAlertDelivery> deliveries;

  factory UserDashboardAlertDetail.fromJson(dynamic json) {
    final source = _asMap(_unwrapResponse(json));
    final base = UserDashboardAlertItem.fromJson(source);
    return UserDashboardAlertDetail(
      id: base.id,
      vehicleId: base.vehicleId,
      vehicleName: base.vehicleName,
      plateNumber: base.plateNumber,
      imei: base.imei,
      source: base.source,
      severity: base.severity,
      title: base.title,
      message: base.message,
      meta: base.meta,
      isRead: base.isRead,
      createdAt: base.createdAt,
      deliveries: _asList(source['deliveries'])
          .map(UserDashboardAlertDelivery.fromJson)
          .toList(growable: false),
    );
  }
}

class UserDashboardAlertDelivery {
  const UserDashboardAlertDelivery({
    required this.id,
    required this.channel,
    required this.status,
    this.sentAt,
    this.deliveredAt,
    this.failureReason,
  });

  final String id;
  final String channel;
  final String status;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final String? failureReason;

  factory UserDashboardAlertDelivery.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardAlertDelivery(
      id: _firstString(source, const ['id', '_id']) ?? '',
      channel: _firstString(source, const ['channel']) ?? '',
      status: _firstString(source, const ['status']) ?? '',
      sentAt: _firstDateTime(source, const ['sentAt', 'sent_at']),
      deliveredAt:
          _firstDateTime(source, const ['deliveredAt', 'delivered_at']),
      failureReason:
          _firstString(source, const ['failureReason', 'failure_reason']),
    );
  }
}

class UserDashboardTopAssets {
  const UserDashboardTopAssets({
    required this.range,
    required this.limit,
    required this.items,
    this.updatedAt,
  });

  final UserDashboardDateRange range;
  final int limit;
  final List<UserDashboardTopAssetItem> items;
  final DateTime? updatedAt;

  factory UserDashboardTopAssets.fromJson(dynamic json) {
    final source = _asMap(_unwrapResponse(json));
    return UserDashboardTopAssets(
      range: UserDashboardDateRange.fromJson(source['range']),
      limit: _firstInt(source, const ['limit']) ?? 0,
      items: _asList(source['items'])
          .map(UserDashboardTopAssetItem.fromJson)
          .toList(growable: false),
      updatedAt: _firstDateTime(source, const ['updatedAt', 'updated_at']),
    );
  }
}

class UserDashboardTopAssetItem {
  const UserDashboardTopAssetItem({
    required this.vehicleId,
    required this.vehicleName,
    this.plateNumber,
    required this.imei,
    required this.drivenKm,
  });

  final String vehicleId;
  final String vehicleName;
  final String? plateNumber;
  final String imei;
  final double drivenKm;

  factory UserDashboardTopAssetItem.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardTopAssetItem(
      vehicleId: _firstString(source, const ['vehicleId', 'vehicle_id']) ?? '',
      vehicleName:
          _firstString(source, const ['vehicleName', 'vehicle_name']) ?? '',
      plateNumber: _firstString(source, const ['plateNumber', 'plate_number']),
      imei: _firstString(source, const ['imei']) ?? '',
      drivenKm: _firstDouble(source, const ['drivenKm', 'driven_km']) ?? 0,
    );
  }
}

class UserDashboardDayNightComparison {
  const UserDashboardDayNightComparison({
    required this.timezoneOffsetMin,
    required this.filter,
    required this.range,
    required this.dayWindow,
    required this.points,
    required this.totals,
    required this.percentages,
    this.updatedAt,
  });

  final int timezoneOffsetMin;
  final UserDashboardVehicleFilter filter;
  final UserDashboardDateRange range;
  final UserDashboardDayWindow dayWindow;
  final List<UserDashboardDayNightPoint> points;
  final UserDashboardDayNightTotals totals;
  final UserDashboardDayNightPercentages percentages;
  final DateTime? updatedAt;

  factory UserDashboardDayNightComparison.fromJson(dynamic json) {
    final source = _asMap(_unwrapResponse(json));
    return UserDashboardDayNightComparison(
      timezoneOffsetMin: _firstInt(
              source, const ['timezoneOffsetMin', 'timezone_offset_min']) ??
          0,
      filter: UserDashboardVehicleFilter.fromJson(source['filter']),
      range: UserDashboardDateRange.fromJson(source['range']),
      dayWindow: UserDashboardDayWindow.fromJson(source['dayWindow']),
      points: _asList(source['points'])
          .map(UserDashboardDayNightPoint.fromJson)
          .toList(growable: false),
      totals: UserDashboardDayNightTotals.fromJson(source['totals']),
      percentages: UserDashboardDayNightPercentages.fromJson(
        source['percentages'],
      ),
      updatedAt: _firstDateTime(source, const ['updatedAt', 'updated_at']),
    );
  }
}

class UserDashboardDayNightPoint {
  const UserDashboardDayNightPoint({
    required this.dayKey,
    required this.label,
    required this.day,
    required this.night,
  });

  final String dayKey;
  final String label;
  final UserDashboardMetricPair day;
  final UserDashboardMetricPair night;

  factory UserDashboardDayNightPoint.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardDayNightPoint(
      dayKey: _firstString(source, const ['dayKey', 'day_key']) ?? '',
      label: _firstString(source, const ['label']) ?? '',
      day: UserDashboardMetricPair.fromJson(source['day']),
      night: UserDashboardMetricPair.fromJson(source['night']),
    );
  }
}

class UserDashboardDayNightTotals {
  const UserDashboardDayNightTotals({
    required this.day,
    required this.night,
    required this.overall,
  });

  final UserDashboardMetricPair day;
  final UserDashboardMetricPair night;
  final UserDashboardMetricPair overall;

  factory UserDashboardDayNightTotals.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardDayNightTotals(
      day: UserDashboardMetricPair.fromJson(source['day']),
      night: UserDashboardMetricPair.fromJson(source['night']),
      overall: UserDashboardMetricPair.fromJson(source['overall']),
    );
  }
}

class UserDashboardDayNightPercentages {
  const UserDashboardDayNightPercentages({
    required this.dayDrivenKm,
    required this.nightDrivenKm,
    required this.dayEngineHours,
    required this.nightEngineHours,
  });

  final double dayDrivenKm;
  final double nightDrivenKm;
  final double dayEngineHours;
  final double nightEngineHours;

  factory UserDashboardDayNightPercentages.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardDayNightPercentages(
      dayDrivenKm:
          _firstDouble(source, const ['dayDrivenKm', 'day_driven_km']) ?? 0,
      nightDrivenKm:
          _firstDouble(source, const ['nightDrivenKm', 'night_driven_km']) ?? 0,
      dayEngineHours:
          _firstDouble(source, const ['dayEngineHours', 'day_engine_hours']) ??
              0,
      nightEngineHours: _firstDouble(
            source,
            const ['nightEngineHours', 'night_engine_hours'],
          ) ??
          0,
    );
  }
}

class UserDashboardDayWindow {
  const UserDashboardDayWindow({
    required this.startHour,
    required this.endHour,
    required this.label,
  });

  final int startHour;
  final int endHour;
  final String label;

  factory UserDashboardDayWindow.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardDayWindow(
      startHour: _firstInt(source, const ['startHour', 'start_hour']) ?? 0,
      endHour: _firstInt(source, const ['endHour', 'end_hour']) ?? 0,
      label: _firstString(source, const ['label']) ?? '',
    );
  }
}

class UserDashboardVehicleOption {
  const UserDashboardVehicleOption({
    required this.id,
    required this.name,
    this.plateNumber,
    this.imei,
    this.isLicenseBlocked = false,
  });

  final String id;
  final String name;
  final String? plateNumber;
  final String? imei;
  final bool isLicenseBlocked;

  bool get licenseBlocked => isLicenseBlocked;

  factory UserDashboardVehicleOption.fromJson(dynamic json) {
    final source = _asMap(json);
    final device = _asMap(source['device']);
    final vehicle = _asMap(source['vehicle']);
    final id = _firstString(source, const ['id', '_id', 'uid']) ?? '';
    final plateNumber =
        _firstString(source, const ['plateNumber', 'plate_number']);
    return UserDashboardVehicleOption(
      id: id,
      name:
          _firstString(source, const ['name', 'vehicleName', 'vehicle_name']) ??
              plateNumber ??
              (id.isEmpty ? 'Vehicle' : 'Vehicle $id'),
      plateNumber: plateNumber,
      imei: _firstString(source, const ['imei']) ??
          _firstString(device, const ['imei']),
      isLicenseBlocked: _firstBool(source, const [
            'isLicenseBlocked',
            'licenseBlocked',
            'is_license_blocked',
            'license_blocked',
          ]) ??
          _firstBool(vehicle, const [
            'isLicenseBlocked',
            'licenseBlocked',
            'is_license_blocked',
            'license_blocked',
          ]) ??
          false,
    );
  }

  static List<UserDashboardVehicleOption> listFromResponse(dynamic json) {
    final unwrapped = _unwrapResponse(json);
    final source = _asMap(unwrapped);
    final list =
        source.containsKey('vehicles') ? source['vehicles'] : unwrapped;
    return _asList(list)
        .map(UserDashboardVehicleOption.fromJson)
        .where((vehicle) => vehicle.id.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class UserDashboardSensorOption {
  const UserDashboardSensorOption({
    required this.id,
    required this.name,
    this.unit,
    this.dataType,
  });

  final String id;
  final String name;
  final String? unit;
  final String? dataType;

  factory UserDashboardSensorOption.fromJson(dynamic json) {
    final source = _asMap(json);
    final id = _firstString(source, const ['id', '_id']) ?? '';
    return UserDashboardSensorOption(
      id: id,
      name: _firstString(source, const ['name', 'label']) ??
          (id.isEmpty ? 'Sensor' : 'Sensor $id'),
      unit: _firstString(source, const ['unit']),
      dataType: _firstString(source, const ['dataType', 'data_type']),
    );
  }

  static List<UserDashboardSensorOption> listFromResponse(dynamic json) {
    final unwrapped = _unwrapResponse(json);
    final source = _asMap(unwrapped);
    final list = source.containsKey('items') ? source['items'] : unwrapped;
    return _asList(list)
        .map(UserDashboardSensorOption.fromJson)
        .where((sensor) => sensor.id.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class UserDashboardSensorHistory {
  const UserDashboardSensorHistory({
    required this.supported,
    this.reason,
    this.sensor,
    required this.range,
    required this.sampling,
    required this.points,
    required this.stats,
  });

  final bool supported;
  final String? reason;
  final UserDashboardSensorOption? sensor;
  final UserDashboardDateRange range;
  final UserDashboardSensorSampling sampling;
  final List<UserDashboardSensorHistoryPoint> points;
  final UserDashboardSensorHistoryStats stats;

  factory UserDashboardSensorHistory.fromJson(dynamic json) {
    final source = _asMap(_unwrapResponse(json));
    final sensorSource = source['sensor'];
    return UserDashboardSensorHistory(
      supported: _firstBool(source, const ['supported']) ?? true,
      reason: _firstString(source, const ['reason']),
      sensor: sensorSource == null
          ? null
          : UserDashboardSensorOption.fromJson(sensorSource),
      range: UserDashboardDateRange.fromJson(source['range']),
      sampling: UserDashboardSensorSampling.fromJson(source['sampling']),
      points: _asList(source['points'])
          .map(UserDashboardSensorHistoryPoint.fromJson)
          .toList(growable: false),
      stats: UserDashboardSensorHistoryStats.fromJson(source['stats']),
    );
  }
}

class UserDashboardSensorSampling {
  const UserDashboardSensorSampling({
    required this.bucketSec,
    required this.returnedPoints,
    required this.errorCount,
    this.maxPoints,
    this.estimatedBuckets,
  });

  final int bucketSec;
  final int returnedPoints;
  final int errorCount;
  final int? maxPoints;
  final int? estimatedBuckets;

  factory UserDashboardSensorSampling.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardSensorSampling(
      bucketSec: _firstInt(source, const ['bucketSec', 'bucket_sec']) ?? 0,
      returnedPoints:
          _firstInt(source, const ['returnedPoints', 'returned_points']) ?? 0,
      errorCount: _firstInt(source, const ['errorCount', 'error_count']) ?? 0,
      maxPoints: _firstInt(source, const ['maxPoints', 'max_points']),
      estimatedBuckets:
          _firstInt(source, const ['estimatedBuckets', 'estimated_buckets']),
    );
  }
}

class UserDashboardSensorHistoryPoint {
  const UserDashboardSensorHistoryPoint({
    required this.t,
    this.v,
  });

  final DateTime? t;
  final double? v;

  factory UserDashboardSensorHistoryPoint.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardSensorHistoryPoint(
      t: _firstDateTime(source, const ['t', 'time', 'timestamp']),
      v: _firstDouble(source, const ['v', 'value']),
    );
  }
}

class UserDashboardSensorHistoryStats {
  const UserDashboardSensorHistoryStats({
    this.min,
    this.max,
    this.avg,
    this.first,
    this.last,
  });

  final double? min;
  final double? max;
  final double? avg;
  final double? first;
  final double? last;

  factory UserDashboardSensorHistoryStats.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardSensorHistoryStats(
      min: _firstDouble(source, const ['min']),
      max: _firstDouble(source, const ['max']),
      avg: _firstDouble(source, const ['avg', 'average']),
      first: _firstDouble(source, const ['first']),
      last: _firstDouble(source, const ['last']),
    );
  }
}

class UserDashboardSendCommandResult {
  const UserDashboardSendCommandResult({
    required this.mode,
    required this.command,
    required this.totalTargets,
    required this.sentNow,
    required this.queued,
    required this.invalid,
    required this.results,
  });

  final String mode;
  final String command;
  final int totalTargets;
  final int sentNow;
  final int queued;
  final int invalid;
  final List<UserDashboardSendCommandItemResult> results;

  factory UserDashboardSendCommandResult.fromJson(dynamic json) {
    final source = _asMap(_unwrapResponse(json));
    return UserDashboardSendCommandResult(
      mode: _firstString(source, const ['mode']) ?? '',
      command: _firstString(source, const ['command']) ?? '',
      totalTargets:
          _firstInt(source, const ['totalTargets', 'total_targets']) ?? 0,
      sentNow: _firstInt(source, const ['sentNow', 'sent_now']) ?? 0,
      queued: _firstInt(source, const ['queued']) ?? 0,
      invalid: _firstInt(source, const ['invalid']) ?? 0,
      results: _asList(source['results'])
          .map(UserDashboardSendCommandItemResult.fromJson)
          .toList(growable: false),
    );
  }
}

enum UserDashboardSendCommandMode {
  all('ALL'),
  selected('SELECTED');

  const UserDashboardSendCommandMode(this.apiValue);

  final String apiValue;
}

class UserDashboardSendCommandItem {
  const UserDashboardSendCommandItem({
    required this.vehicleId,
    required this.command,
  });

  final String vehicleId;
  final String command;

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': _jsonId(vehicleId),
      'command': command,
    };
  }
}

class UserDashboardSendCommandItemResult {
  const UserDashboardSendCommandItemResult({
    this.vehicleId,
    this.vehicleName,
    this.plateNumber,
    this.imei,
    this.cmdId,
    this.connected,
    this.queued,
    this.queueId,
    this.error,
  });

  final String? vehicleId;
  final String? vehicleName;
  final String? plateNumber;
  final String? imei;
  final String? cmdId;
  final bool? connected;
  final bool? queued;
  final String? queueId;
  final String? error;

  factory UserDashboardSendCommandItemResult.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardSendCommandItemResult(
      vehicleId: _firstString(source, const ['vehicleId', 'vehicle_id']),
      vehicleName: _firstString(source, const ['vehicleName', 'vehicle_name']),
      plateNumber: _firstString(source, const ['plateNumber', 'plate_number']),
      imei: _firstString(source, const ['imei']),
      cmdId: _firstString(source, const ['cmdId', 'cmd_id', 'commandId']),
      connected: _firstBool(source, const ['connected']),
      queued: _firstBool(source, const ['queued']),
      queueId: _firstString(source, const ['queueId', 'queue_id']),
      error: _firstString(source, const ['error', 'message']),
    );
  }
}

class UserDashboardDateRange {
  const UserDashboardDateRange({
    this.from,
    this.to,
    this.timezoneOffsetMin,
    this.timezoneSource,
  });

  final String? from;
  final String? to;
  final int? timezoneOffsetMin;
  final String? timezoneSource;

  factory UserDashboardDateRange.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardDateRange(
      from: _firstString(source, const ['from', 'start']),
      to: _firstString(source, const ['to', 'end']),
      timezoneOffsetMin:
          _firstInt(source, const ['timezoneOffsetMin', 'timezone_offset_min']),
      timezoneSource:
          _firstString(source, const ['timezoneSource', 'timezone_source']),
    );
  }
}

class UserDashboardVehicleFilter {
  const UserDashboardVehicleFilter({
    required this.mode,
    this.vehicleId,
    this.vehicleName,
  });

  final String mode;
  final String? vehicleId;
  final String? vehicleName;

  factory UserDashboardVehicleFilter.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardVehicleFilter(
      mode: _firstString(source, const ['mode']) ?? 'ALL',
      vehicleId: _firstString(source, const ['vehicleId', 'vehicle_id']),
      vehicleName: _firstString(source, const ['vehicleName', 'vehicle_name']),
    );
  }
}

class UserDashboardMetricPair {
  const UserDashboardMetricPair({
    required this.drivenKm,
    required this.engineHours,
  });

  final double drivenKm;
  final double engineHours;

  factory UserDashboardMetricPair.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDashboardMetricPair(
      drivenKm: _firstDouble(source, const ['drivenKm', 'driven_km']) ?? 0,
      engineHours:
          _firstDouble(source, const ['engineHours', 'engine_hours']) ?? 0,
    );
  }
}

dynamic _unwrapResponse(dynamic raw) {
  var value = raw;
  for (var index = 0; index < 4; index++) {
    final source = _asMapOrNull(value);
    if (source == null || !source.containsKey('data')) {
      break;
    }

    final looksLikeEnvelope = source.length == 1 ||
        source.containsKey('action') ||
        source.containsKey('message') ||
        source.containsKey('success') ||
        source.containsKey('status') ||
        source.containsKey('timestamp');
    if (!looksLikeEnvelope) {
      break;
    }

    value = source['data'];
  }
  return value;
}

List<dynamic> _listFromResponse(dynamic raw) {
  final unwrapped = _unwrapResponse(raw);
  if (unwrapped is List) {
    return unwrapped;
  }

  final source = _asMap(unwrapped);
  for (final key in const ['items', 'dashboards', 'vehicles', 'data']) {
    final value = source[key];
    if (value is List) {
      return value;
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

Map<String, dynamic>? _asMapOrNull(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

String? _firstString(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

int? _firstInt(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final parsed = _asInt(source[key]);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

double? _firstDouble(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final parsed = _asDouble(source[key]);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

bool? _firstBool(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final parsed = _asBool(source[key]);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

DateTime? _firstDateTime(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final parsed = _asDateTime(source[key]);
    if (parsed != null) {
      return parsed;
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
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

bool? _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case 'yes':
      case '1':
        return true;
      case 'false':
      case 'no':
      case '0':
        return false;
    }
  }
  return null;
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    final isMillis = value.abs() > 9999999999;
    return DateTime.fromMillisecondsSinceEpoch(isMillis ? value : value * 1000);
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

dynamic _jsonId(String id) {
  return int.tryParse(id.trim()) ?? id.trim();
}
