import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../superadmin/models/superadmin_vehicle_model.dart';
import '../models/user_dashboard_model.dart';

class UserDashboardService {
  UserDashboardService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<UserDashboardListItem>> getDashboards() async {
    if (AppConfig.useMockData) {
      return _mockDashboards();
    }

    final response = await _apiClient.get<List<UserDashboardListItem>>(
      ApiEndpoints.user.dashboards,
      parser: UserDashboardListItem.listFromResponse,
    );
    return response.data;
  }

  Future<UserDashboardDetail> getDashboardById(String id) async {
    if (AppConfig.useMockData) {
      return _mockDashboardDetail(id);
    }

    final response = await _apiClient.get<UserDashboardDetail>(
      ApiEndpoints.user.dashboardById(id),
      parser: UserDashboardDetail.fromJson,
    );
    return response.data;
  }

  Future<UserDashboardFleetStatus> getFleetStatus() async {
    if (AppConfig.useMockData) {
      return _mockFleetStatus();
    }

    final response = await _apiClient.get<UserDashboardFleetStatus>(
      ApiEndpoints.user.dashboardFleetStatus,
      parser: UserDashboardFleetStatus.fromJson,
    );
    return response.data;
  }

  Future<UserDashboardUsageLast7Days> getUsageLast7Days({
    String? vehicleId,
  }) async {
    if (AppConfig.useMockData) {
      return _mockUsageLast7Days(vehicleId: vehicleId);
    }

    final response = await _apiClient.get<UserDashboardUsageLast7Days>(
      ApiEndpoints.user.dashboardUsageLast7Days,
      queryParameters: _query({'vehicleId': vehicleId}),
      parser: UserDashboardUsageLast7Days.fromJson,
    );
    return response.data;
  }

  Future<UserDashboardWeeklyComparison> getWeeklyComparison({
    String? vehicleId,
  }) async {
    if (AppConfig.useMockData) {
      return _mockWeeklyComparison(vehicleId: vehicleId);
    }

    final response = await _apiClient.get<UserDashboardWeeklyComparison>(
      ApiEndpoints.user.dashboardWeeklyComparison,
      queryParameters: _query({'vehicleId': vehicleId}),
      parser: UserDashboardWeeklyComparison.fromJson,
    );
    return response.data;
  }

  Future<UserDashboardRecentAlertsPage> getRecentAlerts({
    String? vehicleId,
    int limit = 30,
    int? beforeId,
    String? from,
    String? refreshKey,
  }) async {
    if (AppConfig.useMockData) {
      return _mockRecentAlerts(limit: limit, vehicleId: vehicleId);
    }

    final response = await _apiClient.get<UserDashboardRecentAlertsPage>(
      ApiEndpoints.user.dashboardRecentAlerts,
      queryParameters: _query({
        'vehicleId': vehicleId,
        'limit': limit,
        'beforeId': beforeId,
        'from': from,
        'rk': refreshKey,
      }),
      parser: UserDashboardRecentAlertsPage.fromJson,
    );
    return response.data;
  }

  Future<UserDashboardAlertDetail> getRecentAlertDetail(String id) async {
    if (AppConfig.useMockData) {
      return _mockAlertDetail(id);
    }

    final response = await _apiClient.get<UserDashboardAlertDetail>(
      ApiEndpoints.user.dashboardRecentAlertById(id),
      parser: UserDashboardAlertDetail.fromJson,
    );
    return response.data;
  }

  Future<void> markRecentAlertRead(String id) async {
    if (AppConfig.useMockData) {
      return;
    }

    await _apiClient.patch<void>(
      ApiEndpoints.user.dashboardRecentAlertRead(id),
      data: const <String, dynamic>{},
      parser: (_) {},
    );
  }

  Future<UserDashboardTopAssets> getTopPerformingAssets({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    if (AppConfig.useMockData) {
      return _mockTopPerformingAssets(from: from, to: to, limit: limit);
    }

    final response = await _apiClient.get<UserDashboardTopAssets>(
      ApiEndpoints.user.dashboardTopPerformingAssets,
      queryParameters: _query({
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
        'limit': limit,
      }),
      parser: UserDashboardTopAssets.fromJson,
    );
    return response.data;
  }

  Future<UserDashboardDayNightComparison> getDayNightComparison({
    String? vehicleId,
    required DateTime from,
    required DateTime to,
  }) async {
    if (AppConfig.useMockData) {
      return _mockDayNightComparison(
        vehicleId: vehicleId,
        from: from,
        to: to,
      );
    }

    final response = await _apiClient.get<UserDashboardDayNightComparison>(
      ApiEndpoints.user.dashboardDayNightComparison,
      queryParameters: _query({
        'vehicleId': vehicleId,
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      }),
      parser: UserDashboardDayNightComparison.fromJson,
    );
    return response.data;
  }

  Future<List<UserDashboardVehicleOption>> getVehicles() async {
    if (AppConfig.useMockData) {
      return _mockVehicles();
    }

    final response = await _apiClient.get<List<UserDashboardVehicleOption>>(
      ApiEndpoints.user.vehicles,
      parser: UserDashboardVehicleOption.listFromResponse,
    );
    return response.data;
  }

  Future<List<UserDashboardSensorOption>> getVehicleSensors(
    String vehicleId,
  ) async {
    if (AppConfig.useMockData) {
      return _mockSensors();
    }

    final response = await _apiClient.get<List<UserDashboardSensorOption>>(
      ApiEndpoints.user.vehicleSensors(vehicleId),
      queryParameters: const <String, dynamic>{
        'limit': 100,
        'page': 1,
      },
      parser: UserDashboardSensorOption.listFromResponse,
    );
    return response.data;
  }

  Future<UserDashboardSensorHistory> getSensorHistory({
    required String vehicleId,
    required String sensorId,
    required DateTime from,
    required DateTime to,
    int maxPoints = 500,
  }) async {
    if (AppConfig.useMockData) {
      return _mockSensorHistory(from: from, to: to);
    }

    final response = await _apiClient.get<UserDashboardSensorHistory>(
      ApiEndpoints.user.vehicleSensorHistory(
        vehicleId: vehicleId,
        sensorId: sensorId,
      ),
      queryParameters: _query({
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
        'maxPoints': maxPoints,
      }),
      parser: UserDashboardSensorHistory.fromJson,
    );
    return response.data;
  }

  Future<List<UserDashboardCustomCommand>> getCustomCommands() async {
    if (AppConfig.useMockData) {
      return parseSuperadminCustomCommands(_mockCustomCommandsJson());
    }

    final response = await _apiClient.get<List<UserDashboardCustomCommand>>(
      ApiEndpoints.user.customCommands,
      parser: parseSuperadminCustomCommands,
    );
    return response.data;
  }

  Future<List<UserDashboardSystemVariable>> getSystemVariables() async {
    if (AppConfig.useMockData) {
      return parseSuperadminSystemVariables(_mockSystemVariablesJson());
    }

    final response = await _apiClient.get<List<UserDashboardSystemVariable>>(
      ApiEndpoints.user.systemVariables,
      parser: parseSuperadminSystemVariables,
    );
    return response.data;
  }

  Future<UserDashboardSendCommandResult> sendBulkCommand({
    required UserDashboardSendCommandMode mode,
    String? command,
    List<String> vehicleIds = const <String>[],
    List<UserDashboardSendCommandItem> items =
        const <UserDashboardSendCommandItem>[],
    String? note,
  }) async {
    final normalizedCommand = command?.trim();
    final payload = <String, dynamic>{
      'mode': mode.apiValue,
      if (normalizedCommand != null && normalizedCommand.isNotEmpty)
        'command': normalizedCommand,
      if (vehicleIds.isNotEmpty)
        'vehicleIds': vehicleIds.map(_jsonId).toList(growable: false),
      if (items.isNotEmpty)
        'items': items.map((item) => item.toJson()).toList(growable: false),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    if (AppConfig.useMockData) {
      return _mockSendCommandResult(payload);
    }

    final response = await _apiClient.post<UserDashboardSendCommandResult>(
      ApiEndpoints.user.sendCommandBulk,
      data: payload,
      parser: UserDashboardSendCommandResult.fromJson,
    );
    return response.data;
  }

  Map<String, dynamic> _query(Map<String, dynamic> values) {
    return {
      for (final entry in values.entries)
        if (entry.value != null && entry.value.toString().trim().isNotEmpty)
          entry.key: entry.value,
    };
  }
}

dynamic _jsonId(String id) => int.tryParse(id.trim()) ?? id.trim();

List<UserDashboardListItem> _mockDashboards() {
  final now = DateTime.now();
  return [
    UserDashboardListItem(
      id: '1',
      name: 'Default',
      version: 1,
      updatedAt: now,
    ),
  ];
}

UserDashboardDetail _mockDashboardDetail(String id) {
  final now = DateTime.now();
  return UserDashboardDetail.fromJson({
    'id': id,
    'name': 'Default',
    'version': 1,
    'createdAt': now.subtract(const Duration(days: 7)).toIso8601String(),
    'updatedAt': now.toIso8601String(),
    'config': {
      'widgets': [
        {'id': 'w_fleet', 'type': 'component_1', 'props': {}},
        {'id': 'w_usage', 'type': 'component_2', 'props': {}},
        {'id': 'w_alerts', 'type': 'component_3', 'props': {}},
      ],
      'layouts': {
        'xxs': [
          {'i': 'w_fleet', 'x': 0, 'y': 0, 'w': 2, 'h': 6},
          {'i': 'w_usage', 'x': 0, 'y': 6, 'w': 2, 'h': 6},
          {'i': 'w_alerts', 'x': 0, 'y': 12, 'w': 2, 'h': 5},
        ],
        'xs': [],
        'sm': [],
        'md': [],
        'lg': [],
      },
    },
  });
}

UserDashboardFleetStatus _mockFleetStatus() {
  return UserDashboardFleetStatus.fromJson({
    'totalVehicles': 12,
    'withDevice': 10,
    'noDevice': 2,
    'buckets': {
      'total': 10,
      'connected': 8,
      'running': 4,
      'idle': 2,
      'stopped': 2,
      'inactive': 1,
      'noData': 1,
    },
    'percentages': {
      'running': 33.3,
      'idle': 16.7,
      'stopped': 16.7,
      'inactive': 8.3,
      'noData': 8.3,
      'connected': 66.7,
      'noDevice': 16.7,
    },
    'updatedAt': DateTime.now().toIso8601String(),
  });
}

UserDashboardUsageLast7Days _mockUsageLast7Days({String? vehicleId}) {
  final now = DateTime.now();
  final points = List.generate(7, (index) {
    final date = now.subtract(Duration(days: 6 - index));
    return {
      'day': date.toIso8601String().substring(0, 10),
      'label': 'Day ${index + 1}',
      'drivenKm': 12.5 + index,
      'engineHours': 1.2 + index / 10,
    };
  });
  return UserDashboardUsageLast7Days.fromJson({
    'range': {
      'from': points.first['day'],
      'to': points.last['day'],
      'timezoneOffsetMin': 0,
    },
    'filter': {
      'mode': vehicleId == null ? 'ALL' : 'VEHICLE',
      if (vehicleId != null) 'vehicleId': vehicleId,
    },
    'points': points,
    'totals': {'drivenKm': 108.5, 'engineHours': 10.5},
    'updatedAt': now.toIso8601String(),
  });
}

UserDashboardWeeklyComparison _mockWeeklyComparison({String? vehicleId}) {
  final now = DateTime.now();
  return UserDashboardWeeklyComparison.fromJson({
    'timezoneOffsetMin': 0,
    'filter': {
      'mode': vehicleId == null ? 'ALL' : 'VEHICLE',
      if (vehicleId != null) 'vehicleId': vehicleId,
    },
    'week': {
      'thisWeek': {
        'from': now.subtract(const Duration(days: 6)).toIso8601String(),
        'to': now.toIso8601String()
      },
      'lastWeek': {
        'from': now.subtract(const Duration(days: 13)).toIso8601String(),
        'to': now.subtract(const Duration(days: 7)).toIso8601String()
      },
      'weekStart': 'MONDAY',
    },
    'points': const [
      {
        'dayIndex': 0,
        'label': 'Mon',
        'thisWeek': {'drivenKm': 8, 'engineHours': 1},
        'lastWeek': {'drivenKm': 6, 'engineHours': 0.8}
      },
      {
        'dayIndex': 1,
        'label': 'Tue',
        'thisWeek': {'drivenKm': 12, 'engineHours': 1.4},
        'lastWeek': {'drivenKm': 10, 'engineHours': 1.2}
      },
      {
        'dayIndex': 2,
        'label': 'Wed',
        'thisWeek': {'drivenKm': 9, 'engineHours': 1.1},
        'lastWeek': {'drivenKm': 7, 'engineHours': 0.9}
      },
    ],
    'totals': {
      'thisWeek': {'drivenKm': 29, 'engineHours': 3.5},
      'lastWeek': {'drivenKm': 23, 'engineHours': 2.9}
    },
    'updatedAt': now.toIso8601String(),
  });
}

UserDashboardRecentAlertsPage _mockRecentAlerts({
  required int limit,
  String? vehicleId,
}) {
  return UserDashboardRecentAlertsPage.fromJson({
    'filter': {
      'mode': vehicleId == null ? 'ALL' : 'VEHICLE',
      if (vehicleId != null) 'vehicleId': vehicleId,
    },
    'limit': limit,
    'nextCursor': null,
    'items': [
      {
        'id': 101,
        'vehicleId': 1,
        'vehicleName': 'Demo Truck',
        'plateNumber': 'OVT-1001',
        'imei': '123456789012345',
        'source': 'IGNITION',
        'severity': 'INFO',
        'title': 'Ignition On',
        'message': 'Vehicle ignition turned on.',
        'meta': {},
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ],
  });
}

UserDashboardAlertDetail _mockAlertDetail(String id) {
  return UserDashboardAlertDetail.fromJson({
    'id': id,
    'vehicleId': 1,
    'vehicleName': 'Demo Truck',
    'plateNumber': 'OVT-1001',
    'imei': '123456789012345',
    'source': 'IGNITION',
    'severity': 'INFO',
    'title': 'Ignition On',
    'message': 'Vehicle ignition turned on.',
    'meta': {},
    'isRead': true,
    'createdAt': DateTime.now().toIso8601String(),
    'deliveries': [],
  });
}

UserDashboardTopAssets _mockTopPerformingAssets({
  required DateTime from,
  required DateTime to,
  required int limit,
}) {
  return UserDashboardTopAssets.fromJson({
    'range': {'from': from.toIso8601String(), 'to': to.toIso8601String()},
    'limit': limit,
    'items': const [
      {
        'vehicleId': 1,
        'vehicleName': 'Demo Truck',
        'plateNumber': 'OVT-1001',
        'imei': '123456789012345',
        'drivenKm': 86.4
      },
      {
        'vehicleId': 2,
        'vehicleName': 'Service Van',
        'plateNumber': 'OVT-1002',
        'imei': '123456789012346',
        'drivenKm': 64.2
      },
    ],
    'updatedAt': DateTime.now().toIso8601String(),
  });
}

UserDashboardDayNightComparison _mockDayNightComparison({
  String? vehicleId,
  required DateTime from,
  required DateTime to,
}) {
  return UserDashboardDayNightComparison.fromJson({
    'timezoneOffsetMin': 0,
    'filter': {
      'mode': vehicleId == null ? 'ALL' : 'VEHICLE',
      if (vehicleId != null) 'vehicleId': vehicleId,
    },
    'range': {'from': from.toIso8601String(), 'to': to.toIso8601String()},
    'dayWindow': {'startHour': 6, 'endHour': 18, 'label': 'Day'},
    'points': const [
      {
        'dayKey': '2026-05-19',
        'label': 'Today',
        'day': {'drivenKm': 42, 'engineHours': 2.5},
        'night': {'drivenKm': 8, 'engineHours': 0.6}
      },
    ],
    'totals': {
      'day': {'drivenKm': 42, 'engineHours': 2.5},
      'night': {'drivenKm': 8, 'engineHours': 0.6},
      'overall': {'drivenKm': 50, 'engineHours': 3.1}
    },
    'percentages': {
      'dayDrivenKm': 84,
      'nightDrivenKm': 16,
      'dayEngineHours': 80.6,
      'nightEngineHours': 19.4
    },
    'updatedAt': DateTime.now().toIso8601String(),
  });
}

List<UserDashboardVehicleOption> _mockVehicles() {
  return UserDashboardVehicleOption.listFromResponse({
    'vehicles': const [
      {
        'id': 1,
        'name': 'Demo Truck',
        'plateNumber': 'OVT-1001',
        'imei': '123456789012345'
      },
      {
        'id': 2,
        'name': 'Service Van',
        'plateNumber': 'OVT-1002',
        'imei': '123456789012346'
      },
    ],
  });
}

List<UserDashboardSensorOption> _mockSensors() {
  return UserDashboardSensorOption.listFromResponse({
    'items': const [
      {'id': 1, 'name': 'Temperature', 'unit': 'C', 'dataType': 'FLOAT'},
      {'id': 2, 'name': 'Ignition', 'unit': null, 'dataType': 'BOOL'},
    ],
  });
}

UserDashboardSensorHistory _mockSensorHistory({
  required DateTime from,
  required DateTime to,
}) {
  return UserDashboardSensorHistory.fromJson({
    'supported': true,
    'sensor': {
      'id': 1,
      'name': 'Temperature',
      'unit': 'C',
      'dataType': 'FLOAT'
    },
    'range': {'from': from.toIso8601String(), 'to': to.toIso8601String()},
    'sampling': {'bucketSec': 300, 'returnedPoints': 2, 'errorCount': 0},
    'points': [
      {'t': from.toIso8601String(), 'v': 22.1},
      {'t': to.toIso8601String(), 'v': 24.3},
    ],
    'stats': {
      'min': 22.1,
      'max': 24.3,
      'avg': 23.2,
      'first': 22.1,
      'last': 24.3
    },
  });
}

List<Map<String, dynamic>> _mockCustomCommandsJson() {
  return const [
    {
      'id': 1,
      'command': 'STATUS',
      'isActive': true,
      'commandType': {'id': 1, 'name': 'Status'},
      'deviceType': {'id': 1, 'name': 'Generic', 'protocol': 'TCP'},
    },
  ];
}

List<Map<String, dynamic>> _mockSystemVariablesJson() {
  return const [
    {'id': 1, 'name': 'IMEI', 'initialValue': '{IMEI}'},
  ];
}

UserDashboardSendCommandResult _mockSendCommandResult(
  Map<String, dynamic> payload,
) {
  final vehicleIds = (payload['vehicleIds'] as List?) ?? const [];
  final itemCount = (payload['items'] as List?)?.length;
  final total = itemCount ??
      (vehicleIds.isEmpty ? _mockVehicles().length : vehicleIds.length);
  return UserDashboardSendCommandResult.fromJson({
    'mode': payload['mode'],
    'command': payload['command'] ?? '',
    'totalTargets': total,
    'sentNow': total,
    'queued': 0,
    'invalid': 0,
    'results': List.generate(total, (index) {
      final vehicle = _mockVehicles()[index % _mockVehicles().length];
      return {
        'vehicleId': vehicle.id,
        'vehicleName': vehicle.name,
        'plateNumber': vehicle.plateNumber,
        'imei': vehicle.imei,
        'cmdId': 'mock-$index',
        'connected': true,
        'queued': false,
      };
    }),
  });
}
