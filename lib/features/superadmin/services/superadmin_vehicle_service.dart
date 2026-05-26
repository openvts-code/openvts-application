import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/models/vehicle_summary.dart';
import '../../notifications/models/app_notification.dart';
import '../models/superadmin_vehicle_history_model.dart';
import '../models/superadmin_vehicle_model.dart';

class SuperadminVehicleService {
  SuperadminVehicleService(this._apiClient);

  static bool _mapVehiclesEndpointUnavailable = false;

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );

  final ApiClient _apiClient;

  Future<SuperadminVehiclePage> getVehicles({
    String? refreshKey,
  }) async {
    if (AppConfig.useMockData) {
      return SuperadminVehiclePage.fromJson(_mockVehiclesPayload);
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.vehicles,
      queryParameters: <String, dynamic>{
        'rk': refreshKey ?? DateTime.now().millisecondsSinceEpoch.toString(),
      },
      options: _readOptions,
      parser: (json) => json,
    );

    return SuperadminVehiclePage.fromJson(response.data);
  }

  Future<List<VehicleSummary>> getMapVehicles({
    String? refreshKey,
  }) async {
    if (AppConfig.useMockData) {
      return _mockMapVehicles;
    }

    final requestKey =
        refreshKey ?? DateTime.now().millisecondsSinceEpoch.toString();

    if (_mapVehiclesEndpointUnavailable) {
      return _loadVehicleLocationFallback(refreshKey: requestKey);
    }

    try {
      final response = await _apiClient.get<List<VehicleSummary>>(
        ApiEndpoints.superadmin.mapVehicles,
        queryParameters: <String, dynamic>{
          'rk': requestKey,
        },
        options: _readOptions,
        parser: _parseVehicleList,
      );

      return response.data;
    } on DioException catch (error) {
      if (!_shouldFallbackToVehicleList(error)) {
        rethrow;
      }

      _mapVehiclesEndpointUnavailable = true;

      return _loadVehicleLocationFallback(refreshKey: requestKey);
    }
  }

  Future<SuperadminMapTelemetry> getMapTelemetry({
    String? refreshKey,
  }) async {
    if (AppConfig.useMockData) {
      return _buildTelemetryFromVehicles(_mockMapVehicles);
    }

    final requestKey =
        refreshKey ?? DateTime.now().millisecondsSinceEpoch.toString();

    final response = await _apiClient.get<SuperadminMapTelemetry>(
      ApiEndpoints.superadmin.mapTelemetry,
      queryParameters: <String, dynamic>{
        'rk': requestKey,
      },
      options: _readOptions,
      parser: _parseMapTelemetry,
    );

    return response.data;
  }

  Future<SuperadminVehicleDetails> getVehicleDetailsByImei(String imei) async {
    final normalizedImei = imei.trim();
    if (normalizedImei.isEmpty) {
      return const SuperadminVehicleDetails.empty();
    }

    if (AppConfig.useMockData) {
      return _buildMockVehicleDetails(normalizedImei);
    }

    final response = await _apiClient.get<SuperadminVehicleDetails>(
      ApiEndpoints.superadmin.vehicleDetailsByImei(normalizedImei),
      options: _readOptions,
      parser: _parseVehicleDetails,
    );

    return response.data;
  }

  Future<SuperadminVehicleLogPage> getVehicleLogsByImei(
    String imei, {
    int limit = 100,
    String? beforeId,
  }) async {
    final normalizedImei = imei.trim();
    if (normalizedImei.isEmpty) {
      return const SuperadminVehicleLogPage(items: <SuperadminVehicleLog>[]);
    }

    final normalizedLimit = limit < 1
        ? 100
        : limit > 500
            ? 500
            : limit;
    final normalizedCursor = beforeId?.trim() ?? '';

    if (AppConfig.useMockData) {
      return _buildMockVehicleLogs(
        normalizedImei,
        limit: normalizedLimit,
        beforeId: normalizedCursor.isEmpty ? null : normalizedCursor,
      );
    }

    final response = await _apiClient.get<SuperadminVehicleLogPage>(
      ApiEndpoints.superadmin.vehicleLogsByImei(normalizedImei),
      queryParameters: <String, dynamic>{
        'limit': normalizedLimit,
        if (normalizedCursor.isNotEmpty) 'beforeId': normalizedCursor,
      },
      options: _readOptions,
      parser: SuperadminVehicleLogPage.fromJson,
    );

    return response.data;
  }

  Future<SuperadminVehicleEventPage> getVehicleEventsByImei(
    String imei, {
    int limit = 50,
    String? beforeId,
  }) async {
    final normalizedImei = imei.trim();
    if (normalizedImei.isEmpty) {
      return const SuperadminVehicleEventPage(items: <AppNotification>[]);
    }

    final normalizedLimit = limit < 1
        ? 50
        : limit > 300
            ? 300
            : limit;
    final normalizedCursor = beforeId?.trim() ?? '';

    if (AppConfig.useMockData) {
      return _buildMockVehicleEvents(
        normalizedImei,
        limit: normalizedLimit,
        beforeId: normalizedCursor.isEmpty ? null : normalizedCursor,
      );
    }

    final response = await _apiClient.get<SuperadminVehicleEventPage>(
      ApiEndpoints.superadmin.vehicleEventsByImei(normalizedImei),
      queryParameters: <String, dynamic>{
        'limit': normalizedLimit,
        if (normalizedCursor.isNotEmpty) 'beforeId': normalizedCursor,
      },
      options: _readOptions,
      parser: (json) => SuperadminVehicleEventPage.fromJson(
        json,
        imei: normalizedImei,
        requestedLimit: normalizedLimit,
      ),
    );

    return response.data;
  }

  Future<SuperadminVehicleSensorPage> getVehicleSensorsByImei(
    String imei,
  ) async {
    final normalizedImei = imei.trim();
    if (normalizedImei.isEmpty) {
      return const SuperadminVehicleSensorPage(
        items: <SuperadminVehicleSensor>[],
        totalCount: 0,
      );
    }

    if (AppConfig.useMockData) {
      return _buildMockVehicleSensors(normalizedImei);
    }

    final response = await _apiClient.get<SuperadminVehicleSensorPage>(
      ApiEndpoints.superadmin.vehicleSensorsByImei(normalizedImei),
      queryParameters: const <String, dynamic>{
        'includeTelemetryMeta': 'true',
      },
      options: _readOptions,
      parser: SuperadminVehicleSensorPage.fromJson,
    );

    return response.data;
  }

  Future<List<SuperadminCustomCommand>> getCustomCommands({
    int? deviceTypeId,
    bool activeOnly = true,
  }) async {
    if (AppConfig.useMockData) {
      return _buildMockCustomCommands();
    }

    final response = await _apiClient.get<List<SuperadminCustomCommand>>(
      ApiEndpoints.superadmin.customCommands,
      queryParameters: <String, dynamic>{
        'activeOnly': activeOnly,
        if (deviceTypeId != null) 'deviceTypeId': deviceTypeId.toString(),
      },
      options: _readOptions,
      parser: parseSuperadminCustomCommands,
    );

    return response.data;
  }

  Future<List<SuperadminSystemVariable>> getSystemVariables() async {
    if (AppConfig.useMockData) {
      return _buildMockSystemVariables();
    }

    final response = await _apiClient.get<List<SuperadminSystemVariable>>(
      ApiEndpoints.superadmin.systemVariables,
      options: _readOptions,
      parser: parseSuperadminSystemVariables,
    );

    return response.data;
  }

  Future<SuperadminCommandHistoryPage> getCommandHistoryByImei({
    required String imei,
    int limit = 50,
    String? cursorId,
  }) async {
    final normalizedImei = imei.trim();
    if (normalizedImei.isEmpty) {
      return const SuperadminCommandHistoryPage(
        items: <SuperadminCommandHistoryItem>[],
      );
    }

    final normalizedLimit = limit < 1
        ? 50
        : limit > 100
            ? 100
            : limit;
    final normalizedCursor = cursorId?.trim() ?? '';

    if (AppConfig.useMockData) {
      return _buildMockVehicleCommands(
        normalizedImei,
        limit: normalizedLimit,
        cursorId: normalizedCursor.isEmpty ? null : normalizedCursor,
      );
    }

    final response = await _apiClient.get<SuperadminCommandHistoryPage>(
      ApiEndpoints.superadmin.commandHistoryByImei(normalizedImei),
      queryParameters: <String, dynamic>{
        'limit': normalizedLimit,
        if (normalizedCursor.isNotEmpty) 'cursorId': normalizedCursor,
      },
      options: _readOptions,
      parser: SuperadminCommandHistoryPage.fromJson,
    );

    return response.data;
  }

  Future<SuperadminVehicleCommandPage> getVehicleCommandsByImei(
    String imei, {
    int limit = 50,
    String? cursorId,
  }) {
    return getCommandHistoryByImei(
      imei: imei,
      limit: limit,
      cursorId: cursorId,
    );
  }

  Future<SuperadminSendCommandResult> sendCommandByImei({
    required String imei,
    required String command,
    String? note,
  }) async {
    final normalizedImei = imei.trim();
    final normalizedCommand = command.trim();
    if (normalizedImei.isEmpty) {
      throw ArgumentError('Vehicle IMEI is required to send a command.');
    }
    if (normalizedCommand.isEmpty) {
      throw ArgumentError('Command text is required.');
    }
    if (normalizedCommand.length > 500) {
      throw ArgumentError('Command text must be 500 characters or less.');
    }

    if (AppConfig.useMockData) {
      return SuperadminSendCommandResult.fromJson(
        <String, dynamic>{
          'cmdId': 'mock-${DateTime.now().millisecondsSinceEpoch}',
          'connected': true,
          'queued': false,
          'status': 'SENT',
        },
      );
    }

    final response = await _apiClient.post<SuperadminSendCommandResult>(
      ApiEndpoints.superadmin.sendDeviceCommandByImei(normalizedImei),
      data: <String, dynamic>{
        'command': normalizedCommand,
      },
      options: _readOptions,
      parser: SuperadminSendCommandResult.fromJson,
    );

    return response.data;
  }

  Future<SuperadminSendCommandResponse> sendDeviceCommandByImei({
    required String imei,
    required String command,
    String? note,
  }) {
    return sendCommandByImei(
      imei: imei,
      command: command,
      note: note,
    );
  }

  Future<SuperadminCommandStatus?> getCommandStatus(String cmdId) async {
    final normalizedCmdId = cmdId.trim();
    if (normalizedCmdId.isEmpty) {
      return null;
    }

    if (AppConfig.useMockData) {
      return SuperadminCommandStatus.tryParse(
        <String, dynamic>{
          'cmdId': normalizedCmdId,
          'status': 'RESPONDED',
          'responseRaw': 'OK',
          'respondedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }

    final response = await _apiClient.get<SuperadminCommandStatus?>(
      ApiEndpoints.superadmin.commandStatus(normalizedCmdId),
      options: _readOptions,
      parser: SuperadminCommandStatus.tryParse,
    );

    return response.data;
  }

  Future<SuperadminCommandHistoryItem?> getCommandLogByCmdId(
    String cmdId,
  ) async {
    final normalizedCmdId = cmdId.trim();
    if (normalizedCmdId.isEmpty) {
      return null;
    }

    if (AppConfig.useMockData) {
      return SuperadminCommandHistoryItem.tryParse(
        <String, dynamic>{
          'id': normalizedCmdId,
          'cmdId': normalizedCmdId,
          'status': 'RESPONDED',
          'command': 'STATUS',
          'responseRaw': 'OK',
          'respondedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }

    final response = await _apiClient.get<SuperadminCommandHistoryItem?>(
      ApiEndpoints.superadmin.commandLog(normalizedCmdId),
      options: _readOptions,
      parser: SuperadminCommandHistoryItem.tryParse,
    );

    return response.data;
  }

  Future<SuperadminVehicleCommandEntry?> getCommandDetail(String cmdId) {
    return getCommandLogByCmdId(cmdId);
  }

  Future<SuperadminVehicleHistory> getVehicleHistory(
    SuperadminVehicleHistoryRequest request, {
    int maxPoints = 50000,
  }) async {
    final normalizedImei = request.imei;
    if (normalizedImei.isEmpty) {
      throw ArgumentError('Vehicle IMEI is required to load history.');
    }

    final from = request.from.isAfter(request.to) ? request.to : request.from;
    final to = request.to.isBefore(request.from) ? request.from : request.to;
    final normalizedRequest = SuperadminVehicleHistoryRequest(
      vehicle: request.vehicle,
      from: from,
      to: to,
      stopMinutes: request.stopMinutes < 1 ? 1 : request.stopMinutes,
    );

    final response = await _apiClient.get<SuperadminVehicleHistory>(
      ApiEndpoints.superadmin.vehicleHistoryByImei(normalizedImei),
      queryParameters: <String, dynamic>{
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'stopMin': normalizedRequest.stopMinutes.toString(),
        'maxPoints': maxPoints.toString(),
      },
      options: _readOptions,
      parser: (json) => _parseVehicleHistory(json, normalizedRequest),
    );

    return response.data;
  }

  Future<SuperadminVehicleReplay> getVehicleReplayByImei({
    required String imei,
    required DateTime from,
    required DateTime to,
    int maxPoints = 5000,
  }) async {
    final normalizedImei = imei.trim();
    if (normalizedImei.isEmpty) {
      throw ArgumentError('Vehicle IMEI is required to load replay.');
    }

    if (AppConfig.useMockData) {
      return _buildMockVehicleReplay(normalizedImei, from, to);
    }

    final response = await _apiClient.get<SuperadminVehicleReplay>(
      ApiEndpoints.superadmin.vehicleReplayByImei(normalizedImei),
      queryParameters: <String, dynamic>{
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'maxPoints': maxPoints,
      },
      options: _readOptions,
      parser: SuperadminVehicleReplay.fromJson,
    );

    return response.data;
  }

  SuperadminMapTelemetry parseMapTelemetryPayload(dynamic json) {
    return _parseMapTelemetry(json);
  }

  SuperadminVehicleHistory parseVehicleHistoryPayload(
    dynamic json,
    SuperadminVehicleHistoryRequest request,
  ) {
    return _parseVehicleHistory(json, request);
  }

  SuperadminVehicleReplay parseVehicleReplayPayload(dynamic json) {
    return SuperadminVehicleReplay.fromJson(json);
  }

  SuperadminVehicleDetails parseVehicleDetailsPayload(dynamic json) {
    return _parseVehicleDetails(json);
  }

  SuperadminVehicleLogPage parseVehicleLogsPayload(dynamic json) {
    return SuperadminVehicleLogPage.fromJson(json);
  }

  SuperadminVehicleLog? parseTelemetryLogPayload(dynamic raw) {
    return SuperadminVehicleLog.tryParse(
      raw,
      source: SuperadminVehicleLogSource.live,
    );
  }

  List<SuperadminVehicleLog> parseTelemetryLogListPayload(dynamic raw) {
    return SuperadminVehicleLogPage.fromJson(
      raw,
      source: SuperadminVehicleLogSource.live,
    ).items;
  }

  SuperadminVehicleEventPage parseVehicleEventsPayload(
    dynamic raw, {
    String? imei,
    int requestedLimit = 50,
  }) {
    return SuperadminVehicleEventPage.fromJson(
      raw,
      imei: imei,
      requestedLimit: requestedLimit,
    );
  }

  AppNotification? parseVehicleEventPayload(
    dynamic raw, {
    String? imei,
  }) {
    final page = SuperadminVehicleEventPage.fromJson(
      raw,
      imei: imei,
      requestedLimit: 1,
    );
    return page.items.isEmpty ? null : page.items.first;
  }

  SuperadminVehicleSensorPage parseVehicleSensorsPayload(dynamic raw) {
    return SuperadminVehicleSensorPage.fromJson(raw);
  }

  List<SuperadminCustomCommand> parseCustomCommandsPayload(dynamic raw) {
    return parseSuperadminCustomCommands(raw);
  }

  List<SuperadminSystemVariable> parseSystemVariablesPayload(dynamic raw) {
    return parseSuperadminSystemVariables(raw);
  }

  SuperadminCommandHistoryPage parseVehicleCommandsPayload(dynamic raw) {
    return SuperadminCommandHistoryPage.fromJson(raw);
  }

  SuperadminSendCommandResult parseSendCommandResponsePayload(dynamic raw) {
    return SuperadminSendCommandResult.fromJson(raw);
  }

  SuperadminCommandHistoryItem? parseCommandPayload(dynamic raw) {
    return SuperadminCommandHistoryItem.tryParse(raw);
  }

  SuperadminCommandStatus? parseCommandStatusPayload(dynamic raw) {
    return SuperadminCommandStatus.tryParse(raw);
  }

  VehicleSummary? parseTelemetryVehiclePayload(
    dynamic raw, {
    bool requireCoordinates = false,
  }) {
    return _vehicleSummaryFromJson(
      raw,
      requireCoordinates: requireCoordinates,
    );
  }

  SuperadminMapTelemetry buildTelemetryFromVehicles(
    List<VehicleSummary> vehicles,
  ) {
    return _buildTelemetryFromVehicles(vehicles);
  }

  List<String> resolveVehicleIdentityAliases(
    dynamic raw, {
    VehicleSummary? fallbackVehicle,
  }) {
    final source = _asMap(raw);
    final candidateMaps = source.isEmpty
        ? const <Map<String, dynamic>>[]
        : _candidateVehicleMaps(source);
    return _vehicleIdentityAliases(
      candidateMaps: candidateMaps,
      fallbackVehicle: fallbackVehicle,
    );
  }

  List<String> resolveVehicleIdentityAliasesForVehicle(VehicleSummary vehicle) {
    return _vehicleIdentityAliases(fallbackVehicle: vehicle);
  }

  List<VehicleSummary> _parseVehicleList(
    dynamic json, {
    bool requireCoordinates = true,
  }) {
    final list = switch (json) {
      List<dynamic> raw => raw,
      Map<String, dynamic> raw =>
        (raw['items'] ?? raw['rows'] ?? raw['data'] ?? raw['vehicles']) is List
            ? (raw['items'] ?? raw['rows'] ?? raw['data'] ?? raw['vehicles'])
                as List<dynamic>
            : const <dynamic>[],
      _ => const <dynamic>[],
    };

    return list
        .map((item) => _vehicleSummaryFromJson(
              item,
              requireCoordinates: requireCoordinates,
            ))
        .whereType<VehicleSummary>()
        .toList(growable: false);
  }

  SuperadminMapTelemetry _parseMapTelemetry(dynamic json) {
    final vehicles = _parseTelemetryVehicles(json);
    final listResult = _parseTelemetryCountList(
      json,
      vehicles: vehicles,
    );
    if (listResult != null) {
      return listResult;
    }

    final root = _asMap(json);
    final candidates = <Map<String, dynamic>>[
      root,
      _asMap(root['data']),
      _asMap(root['telemetry']),
      _asMap(root['counts']),
    ];

    final rootData = _asMap(root['data']);
    candidates.addAll(<Map<String, dynamic>>[
      _asMap(rootData['telemetry']),
      _asMap(rootData['counts']),
      _asMap(rootData['items']),
      _asMap(rootData['stats']),
    ]);

    for (final candidate in candidates) {
      final parsed = _parseTelemetryMap(candidate, vehicles: vehicles);
      if (parsed != null) {
        return parsed;
      }
    }

    if (vehicles.isNotEmpty) {
      return _buildTelemetryFromVehicles(vehicles);
    }

    return const SuperadminMapTelemetry(
      allCount: 0,
      runningCount: 0,
      stopCount: 0,
      inactiveCount: 0,
      vehicles: <VehicleSummary>[],
    );
  }

  SuperadminMapTelemetry? _parseTelemetryMap(
    Map<String, dynamic> source, {
    List<VehicleSummary> vehicles = const <VehicleSummary>[],
  }) {
    if (source.isEmpty) {
      return null;
    }

    final all = _firstInt(source, const [
      'all',
      'allCount',
      'all_count',
      'total',
      'totalCount',
      'total_count',
      'vehicles',
      'vehicleCount',
      'vehicle_count',
    ]);
    final running = _firstInt(source, const [
      'running',
      'runningCount',
      'running_count',
      'moving',
      'movingCount',
      'moving_count',
      'active',
      'activeCount',
      'active_count',
    ]);
    final stop = _firstInt(source, const [
      'stop',
      'stopped',
      'stopCount',
      'stop_count',
      'stoppedCount',
      'stopped_count',
      'idle',
      'idleCount',
      'idle_count',
    ]);
    final inactive = _firstInt(source, const [
      'inactive',
      'inactiveCount',
      'inactive_count',
      'noData',
      'no_data',
      'noDataCount',
      'no_data_count',
      'offline',
      'offlineCount',
      'offline_count',
      'disconnected',
      'disconnectedCount',
      'disconnected_count',
      'licenseBlocked',
      'license_blocked',
      'licenseBlockedCount',
      'license_blocked_count',
    ]);

    if (all != null || running != null || stop != null || inactive != null) {
      if (vehicles.isNotEmpty) {
        return _buildTelemetryFromVehicles(vehicles);
      }

      final resolvedRunning = running ?? 0;
      final resolvedInactive = inactive ?? 0;
      final resolvedStop = all == null
          ? stop ?? 0
          : (all - resolvedRunning - resolvedInactive).clamp(0, all).toInt();
      return SuperadminMapTelemetry(
        allCount: all ?? resolvedRunning + resolvedStop + resolvedInactive,
        runningCount: resolvedRunning,
        stopCount: resolvedStop,
        inactiveCount: resolvedInactive,
        vehicles: vehicles,
      );
    }

    return _parseTelemetryCountList(source, vehicles: vehicles);
  }

  List<VehicleSummary> _parseTelemetryVehicles(dynamic json) {
    final root = _asMap(json);
    final rootData = _asMap(root['data']);
    final telemetry = _asMap(root['telemetry']);
    final counts = _asMap(root['counts']);
    final stats = _asMap(root['stats']);

    final candidates = <dynamic>[
      json,
      root['vehicles'],
      root['items'],
      root['rows'],
      root['list'],
      root['results'],
      root['data'],
      root['telemetry'],
      rootData,
      rootData['vehicles'],
      rootData['items'],
      rootData['rows'],
      rootData['list'],
      rootData['results'],
      rootData['data'],
      rootData['telemetry'],
      telemetry,
      telemetry['vehicles'],
      telemetry['items'],
      telemetry['rows'],
      counts['vehicles'],
      stats['vehicles'],
    ];

    for (final candidate in candidates) {
      final vehicles = _parseVehicleList(
        candidate,
        requireCoordinates: false,
      );
      if (vehicles.isNotEmpty) {
        return vehicles;
      }
    }

    return const <VehicleSummary>[];
  }

  SuperadminVehicleHistory _parseVehicleHistory(
    dynamic json,
    SuperadminVehicleHistoryRequest request,
  ) {
    final points = _parseVehicleHistoryPoints(json);
    final segments = _parseVehicleHistorySegments(json);
    final stopMarkers = _parseVehicleHistoryStopMarkers(json);
    final summaryMaps = _vehicleHistorySummaryMaps(json);
    final overspeedSegments = _parseVehicleHistoryOverspeedSegments(json);
    final analytics = _parseVehicleHistoryAnalytics(summaryMaps);

    return SuperadminVehicleHistory(
      request: request,
      points: points,
      segments: segments,
      stopMarkers: stopMarkers,
      overspeedSegments: overspeedSegments,
      analytics: analytics,
      totalDistanceKm: analytics.totalDistanceKm,
      maxSpeedKph: analytics.maxSpeedKph,
    );
  }

  SuperadminVehicleHistoryAnalytics _parseVehicleHistoryAnalytics(
    List<Map<String, dynamic>> summaryMaps,
  ) {
    return SuperadminVehicleHistoryAnalytics(
      totalDistanceKm: _firstDoubleByKeyPriority(summaryMaps, const [
        'totalDistanceKm',
        'total_distance_km',
        'distanceKm',
        'distance_km',
        'distance',
        'totalDistance',
        'total_distance',
        'coveredDistance',
        'covered_distance',
      ]),
      movingTimeSec: _firstIntByKeyPriority(summaryMaps, const [
        'movingTimeSec',
        'moving_time_sec',
        'movingDurationSeconds',
        'moving_duration_seconds',
        'runningDurationSeconds',
        'running_duration_seconds',
        'driveDurationSeconds',
        'drive_duration_seconds',
      ]),
      idleTimeSec: _firstIntByKeyPriority(summaryMaps, const [
        'idleTimeSec',
        'idle_time_sec',
        'idleDurationSeconds',
        'idle_duration_seconds',
      ]),
      stopTimeSec: _firstIntByKeyPriority(summaryMaps, const [
        'stopTimeSec',
        'stop_time_sec',
        'stopDurationSeconds',
        'stop_duration_seconds',
        'stoppedDurationSeconds',
        'stopped_duration_seconds',
      ]),
      maxSpeedKph: _firstDoubleByKeyPriority(summaryMaps, const [
        'maxSpeedKph',
        'max_speed_kph',
        'maxSpeed',
        'max_speed',
        'topSpeedKph',
        'top_speed_kph',
        'topSpeed',
        'top_speed',
      ]),
      avgMovingSpeedKph: _firstDoubleByKeyPriority(summaryMaps, const [
        'avgMovingSpeedKph',
        'avg_moving_speed_kph',
        'avgSpeedKph',
        'avg_speed_kph',
        'averageSpeedKph',
        'average_speed_kph',
        'avgSpeed',
        'avg_speed',
        'averageSpeed',
        'average_speed',
      ]),
      stopsCount: _firstIntByKeyPriority(summaryMaps, const [
        'stopsCount',
        'stops_count',
        'stopCount',
        'stop_count',
        'stoppageCount',
        'stoppage_count',
        'stops',
      ]),
      pointsReturned: _firstIntByKeyPriority(summaryMaps, const [
        'pointsReturned',
        'points_returned',
        'pointCount',
        'point_count',
      ]),
      overspeedCount: _firstIntByKeyPriority(summaryMaps, const [
        'overspeedCount',
        'overspeed_count',
        'overSpeedCount',
        'over_speed_count',
        'speedingCount',
        'speeding_count',
      ]),
    );
  }

  List<SuperadminVehicleHistoryPoint> _parseVehicleHistoryPoints(dynamic json) {
    final candidates = _vehicleHistoryListCandidates(json);

    for (final candidate in candidates) {
      final list = _asVehicleHistoryList(candidate);
      if (list == null || list.isEmpty) {
        continue;
      }

      final points = list
          .map(_parseVehicleHistoryPoint)
          .whereType<SuperadminVehicleHistoryPoint>()
          .toList(growable: false);
      if (points.isEmpty) {
        continue;
      }

      return points;
    }

    return const <SuperadminVehicleHistoryPoint>[];
  }

  List<SuperadminVehicleHistorySegment> _parseVehicleHistorySegments(
    dynamic json,
  ) {
    final candidates = _vehicleHistorySegmentListCandidates(json);

    for (final candidate in candidates) {
      final list = _asVehicleHistoryList(candidate);
      if (list == null || list.isEmpty) {
        continue;
      }

      final segments = <SuperadminVehicleHistorySegment>[];
      for (final raw in list) {
        final segment = _parseVehicleHistorySegment(raw);
        if (segment == null) {
          continue;
        }

        if (segment.type == SuperadminVehicleHistorySegmentType.other) {
          continue;
        }

        segments.add(segment);
      }

      if (segments.isNotEmpty) {
        return segments;
      }
    }

    return const <SuperadminVehicleHistorySegment>[];
  }

  List<SuperadminVehicleHistorySegment> _parseVehicleHistoryOverspeedSegments(
    dynamic json,
  ) {
    final candidates = _vehicleHistoryOverspeedSegmentListCandidates(json);

    for (final candidate in candidates) {
      final list = _asVehicleHistoryList(candidate);
      if (list == null || list.isEmpty) {
        continue;
      }

      final segments = <SuperadminVehicleHistorySegment>[];
      for (final raw in list) {
        final segment = _parseVehicleHistorySegment(raw);
        if (segment == null) {
          continue;
        }

        segments.add(_asOverspeedVehicleHistorySegment(segment));
      }

      if (segments.isNotEmpty) {
        return segments;
      }
    }

    return const <SuperadminVehicleHistorySegment>[];
  }

  List<dynamic> _vehicleHistoryOverspeedSegmentListCandidates(dynamic json) {
    final root = _asMap(json);
    final rootData = _asMap(root['data']);
    final history = _asMap(root['history']);
    final route = _asMap(root['route']);
    final telemetry = _asMap(root['telemetry']);
    final playback = _asMap(root['playback']);
    final rootDataHistory = _asMap(rootData['history']);
    final rootDataPlayback = _asMap(rootData['playback']);

    final sources = <Map<String, dynamic>>[
      root,
      rootData,
      history,
      route,
      telemetry,
      playback,
      rootDataHistory,
      rootDataPlayback,
    ];

    final candidates = <dynamic>[];
    for (final source in sources) {
      if (source.isEmpty) {
        continue;
      }

      for (final key in const [
        'overspeedSegments',
        'overspeed_segments',
        'overSpeedSegments',
        'over_speed_segments',
        'speedingSegments',
        'speeding_segments',
      ]) {
        candidates.add(source[key]);
      }
    }

    return candidates;
  }

  SuperadminVehicleHistorySegment _asOverspeedVehicleHistorySegment(
    SuperadminVehicleHistorySegment segment,
  ) {
    if (segment.type == SuperadminVehicleHistorySegmentType.overspeed) {
      return segment;
    }

    return SuperadminVehicleHistorySegment(
      id: segment.id,
      type: SuperadminVehicleHistorySegmentType.overspeed,
      rawType: segment.rawType.isEmpty ? 'overspeed' : segment.rawType,
      startIndex: segment.startIndex,
      endIndex: segment.endIndex,
      startTime: segment.startTime,
      endTime: segment.endTime,
      durationSec: segment.durationSec,
      address: segment.address,
      reason: segment.reason,
      distanceKm: segment.distanceKm,
      maxSpeedKph: segment.maxSpeedKph,
      avgSpeedKph: segment.avgSpeedKph,
      latitude: segment.latitude,
      longitude: segment.longitude,
      startLatitude: segment.startLatitude,
      startLongitude: segment.startLongitude,
      endLatitude: segment.endLatitude,
      endLongitude: segment.endLongitude,
    );
  }

  List<dynamic> _vehicleHistorySegmentListCandidates(dynamic json) {
    final root = _asMap(json);
    final rootData = _asMap(root['data']);
    final history = _asMap(root['history']);
    final route = _asMap(root['route']);
    final telemetry = _asMap(root['telemetry']);
    final playback = _asMap(root['playback']);
    final rootDataHistory = _asMap(rootData['history']);
    final rootDataPlayback = _asMap(rootData['playback']);

    final sources = <Map<String, dynamic>>[
      root,
      rootData,
      history,
      route,
      telemetry,
      playback,
      rootDataHistory,
      rootDataPlayback,
    ];

    final candidates = <dynamic>[];
    for (final source in sources) {
      if (source.isEmpty) {
        continue;
      }

      for (final key in const [
        'segments',
        'historySegments',
        'history_segments',
        'timeline',
        'timelineRows',
        'timeline_rows',
      ]) {
        candidates.add(source[key]);
      }
    }

    return candidates;
  }

  SuperadminVehicleHistorySegment? _parseVehicleHistorySegment(dynamic raw) {
    final source = _asMap(raw);
    if (source.isEmpty) {
      return null;
    }

    final candidateMaps = <Map<String, dynamic>>[
      source,
      _asMap(source['segment']),
      _asMap(source['data']),
      _asMap(source['summary']),
      _asMap(source['analytics']),
      _asMap(source['metrics']),
      _asMap(source['start']),
      _asMap(source['end']),
    ].where((candidate) => candidate.isNotEmpty).toList(growable: false);
    final id = _firstStringInMaps(candidateMaps, const [
          'id',
          '_id',
          'segmentId',
          'segment_id',
        ]) ??
        '';
    final rawType = _firstStringInMaps(candidateMaps, const [
          'type',
          'kind',
          'category',
          'status',
          'state',
          'segmentType',
          'segment_type',
          'motionState',
          'motion_state',
          'label',
          'title',
          'name',
        ]) ??
        '';
    final type = _parseVehicleHistorySegmentType(rawType);
    final startIndex = _firstIntByKeyPriority(candidateMaps, const [
      'startIndex',
      'start_index',
    ]);
    final endIndex = _firstIntByKeyPriority(candidateMaps, const [
      'endIndex',
      'end_index',
    ]);

    final startTime = _firstDateInMaps(candidateMaps, const [
      'startTime',
      'start_time',
      'startAt',
      'start_at',
      'startedAt',
      'started_at',
      'from',
      'fromTime',
      'from_time',
      'timestampStart',
      'timestamp_start',
    ]);
    final endTime = _firstDateInMaps(candidateMaps, const [
      'endTime',
      'end_time',
      'endAt',
      'end_at',
      'endedAt',
      'ended_at',
      'to',
      'toTime',
      'to_time',
      'timestampEnd',
      'timestamp_end',
    ]);
    final durationSec = _parseVehicleHistoryDurationSec(candidateMaps);
    final address = _firstStringInMaps(candidateMaps, const [
          'address',
          'formattedAddress',
          'formatted_address',
          'locationName',
          'location_name',
          'place',
          'landmark',
          'description',
        ]) ??
        '';
    final reason = _firstStringInMaps(candidateMaps, const [
          'reason',
          'stopReason',
          'stop_reason',
          'cause',
          'stopCause',
          'stop_cause',
          'event',
          'eventType',
          'event_type',
        ]) ??
        '';
    final coordinates = _extractCoordinates(source);
    final startCoordinates = _firstCoordinatesInMaps([
      _asMap(source['start']),
      _asMap(source['startPoint']),
      _asMap(source['start_point']),
      _asMap(source['from']),
    ]);
    final endCoordinates = _firstCoordinatesInMaps([
      _asMap(source['end']),
      _asMap(source['endPoint']),
      _asMap(source['end_point']),
      _asMap(source['to']),
    ]);
    final distanceKm = _parseVehicleHistoryDistanceKm(candidateMaps);
    final avgSpeedKph = _firstDoubleByKeyPriority(candidateMaps, const [
      'avgSpeedKph',
      'avg_speed_kph',
      'averageSpeedKph',
      'average_speed_kph',
      'avgSpeed',
      'avg_speed',
      'averageSpeed',
      'average_speed',
    ]);
    final maxSpeedKph = _firstDoubleByKeyPriority(candidateMaps, const [
      'maxSpeedKph',
      'max_speed_kph',
      'maxSpeed',
      'max_speed',
      'topSpeedKph',
      'top_speed_kph',
      'topSpeed',
      'top_speed',
    ]);

    if (type == SuperadminVehicleHistorySegmentType.other &&
        startTime == null &&
        endTime == null &&
        durationSec == null &&
        address.isEmpty &&
        distanceKm == null &&
        avgSpeedKph == null &&
        maxSpeedKph == null &&
        startIndex == null &&
        endIndex == null &&
        coordinates == null &&
        startCoordinates == null &&
        endCoordinates == null) {
      return null;
    }

    return SuperadminVehicleHistorySegment(
      id: id,
      type: type,
      rawType: rawType,
      startIndex: startIndex,
      endIndex: endIndex,
      startTime: startTime,
      endTime: endTime,
      durationSec: durationSec,
      address: address,
      reason: reason,
      distanceKm: distanceKm,
      maxSpeedKph: maxSpeedKph,
      avgSpeedKph: avgSpeedKph,
      latitude: coordinates?.latitude,
      longitude: coordinates?.longitude,
      startLatitude: startCoordinates?.latitude,
      startLongitude: startCoordinates?.longitude,
      endLatitude: endCoordinates?.latitude,
      endLongitude: endCoordinates?.longitude,
    );
  }

  SuperadminVehicleHistorySegmentType _parseVehicleHistorySegmentType(
    String rawType,
  ) {
    final normalized = rawType.trim().toLowerCase();
    if (normalized == 'idle' || normalized.contains('idle')) {
      return SuperadminVehicleHistorySegmentType.idle;
    }

    if (normalized == 'stop' ||
        normalized.contains('stop') ||
        normalized.contains('stoppage') ||
        normalized.contains('parking') ||
        normalized.contains('halt')) {
      return SuperadminVehicleHistorySegmentType.stop;
    }

    if (normalized == 'overspeed' || normalized.contains('overspeed')) {
      return SuperadminVehicleHistorySegmentType.overspeed;
    }

    if (normalized == 'drive' ||
        normalized.contains('run') ||
        normalized.contains('drive') ||
        normalized.contains('driving') ||
        normalized.contains('move') ||
        normalized.contains('moving') ||
        normalized.contains('travel')) {
      return SuperadminVehicleHistorySegmentType.drive;
    }

    return SuperadminVehicleHistorySegmentType.other;
  }

  int? _parseVehicleHistoryDurationSec(
    List<Map<String, dynamic>> candidateMaps,
  ) {
    final seconds = _firstDoubleByKeyPriority(candidateMaps, const [
      'durationSec',
      'durationSeconds',
      'duration_seconds',
      'stopSeconds',
      'stop_seconds',
      'parkingSeconds',
      'parking_seconds',
      'idleSeconds',
      'idle_seconds',
    ]);
    if (seconds != null && seconds >= 0) {
      return seconds.round();
    }

    final minutes = _firstDoubleByKeyPriority(candidateMaps, const [
      'durationMinutes',
      'duration_minutes',
      'stopMinutes',
      'stop_minutes',
      'stopMin',
      'stop_min',
      'parkingMinutes',
      'parking_minutes',
      'idleMinutes',
      'idle_minutes',
    ]);
    if (minutes != null && minutes >= 0) {
      return (minutes * 60).round();
    }

    final milliseconds = _firstDoubleByKeyPriority(candidateMaps, const [
      'durationMs',
      'duration_ms',
      'durationMilliseconds',
      'duration_milliseconds',
      'stopMs',
      'stop_ms',
    ]);
    if (milliseconds != null && milliseconds >= 0) {
      return (milliseconds / 1000).round();
    }

    return null;
  }

  double? _parseVehicleHistoryDistanceKm(
    List<Map<String, dynamic>> candidateMaps,
  ) {
    final kilometers = _firstDoubleByKeyPriority(candidateMaps, const [
      'distanceKm',
      'distance_km',
      'distance',
      'totalDistanceKm',
      'total_distance_km',
      'coveredDistanceKm',
      'covered_distance_km',
    ]);
    if (kilometers != null) {
      return kilometers;
    }

    final meters = _firstDoubleByKeyPriority(candidateMaps, const [
      'distanceMeters',
      'distance_meters',
      'distanceM',
      'distance_m',
      'coveredDistanceMeters',
      'covered_distance_meters',
    ]);
    if (meters != null) {
      return meters / 1000;
    }

    return null;
  }

  List<dynamic> _vehicleHistoryListCandidates(dynamic json) {
    final root = _asMap(json);
    final rootData = _asMap(root['data']);
    final history = _asMap(root['history']);
    final route = _asMap(root['route']);
    final telemetry = _asMap(root['telemetry']);
    final rootDataHistory = _asMap(rootData['history']);
    final rootDataRoute = _asMap(rootData['route']);
    final rootDataTelemetry = _asMap(rootData['telemetry']);

    return <dynamic>[
      json,
      root['points'],
      root['history'],
      root['items'],
      root['rows'],
      root['records'],
      root['logs'],
      root['telemetry'],
      root['trail'],
      root['route'],
      root['locations'],
      root['positions'],
      rootData,
      rootData['points'],
      rootData['history'],
      rootData['items'],
      rootData['rows'],
      rootData['records'],
      rootData['logs'],
      rootData['telemetry'],
      rootData['trail'],
      rootData['route'],
      rootData['locations'],
      rootData['positions'],
      history['points'],
      history['items'],
      history['rows'],
      history['records'],
      route['points'],
      route['items'],
      route['rows'],
      route['records'],
      telemetry['points'],
      telemetry['items'],
      telemetry['rows'],
      rootDataHistory['points'],
      rootDataHistory['items'],
      rootDataHistory['rows'],
      rootDataHistory['records'],
      rootDataRoute['points'],
      rootDataRoute['items'],
      rootDataRoute['rows'],
      rootDataTelemetry['points'],
      rootDataTelemetry['items'],
      rootDataTelemetry['rows'],
    ];
  }

  List<dynamic>? _asVehicleHistoryList(dynamic value) {
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
      'points',
      'history',
      'items',
      'rows',
      'records',
      'logs',
      'data',
      'telemetry',
      'trail',
      'route',
      'locations',
      'positions',
    ]);
  }

  List<SuperadminVehicleHistoryStopMarker> _parseVehicleHistoryStopMarkers(
    dynamic json,
  ) {
    final candidates = _vehicleHistoryStopListCandidates(json);
    final stopMarkers = <SuperadminVehicleHistoryStopMarker>[];

    for (final candidate in candidates) {
      final list = _asVehicleHistoryList(candidate.value);
      if (list == null || list.isEmpty) {
        continue;
      }

      for (final raw in list) {
        final stopMarker = _parseVehicleHistoryStopMarker(
          raw,
          requireStopKind: candidate.requireStopKind,
        );
        if (stopMarker == null) {
          continue;
        }

        stopMarkers.add(stopMarker);
      }
    }

    return stopMarkers;
  }

  List<_HistoryStopListCandidate> _vehicleHistoryStopListCandidates(
    dynamic json,
  ) {
    final root = _asMap(json);
    final rootData = _asMap(root['data']);
    final history = _asMap(root['history']);
    final route = _asMap(root['route']);
    final telemetry = _asMap(root['telemetry']);
    final playback = _asMap(root['playback']);
    final rootDataHistory = _asMap(rootData['history']);
    final rootDataPlayback = _asMap(rootData['playback']);

    final sources = <Map<String, dynamic>>[
      root,
      rootData,
      history,
      route,
      telemetry,
      playback,
      rootDataHistory,
      rootDataPlayback,
    ];

    final candidates = <_HistoryStopListCandidate>[];
    for (final source in sources) {
      if (source.isEmpty) {
        continue;
      }

      for (final key in const [
        'stopMarkers',
        'stop_markers',
      ]) {
        candidates.add(
          _HistoryStopListCandidate(
            source[key],
            requireStopKind: false,
          ),
        );
      }
    }

    return candidates;
  }

  SuperadminVehicleHistoryStopMarker? _parseVehicleHistoryStopMarker(
    dynamic raw, {
    required bool requireStopKind,
  }) {
    final source = _asMap(raw);
    if (source.isEmpty) {
      return null;
    }

    final candidateMaps = <Map<String, dynamic>>[
      source,
      _asMap(source['stop']),
      _asMap(source['marker']),
      _asMap(source['segment']),
      _asMap(source['location']),
      _asMap(source['position']),
      _asMap(source['point']),
      _asMap(source['start']),
      _asMap(source['end']),
      _asMap(source['data']),
    ].where((candidate) => candidate.isNotEmpty).toList(growable: false);

    if (requireStopKind && !_looksLikeStopSegment(candidateMaps)) {
      return null;
    }

    final segmentId = _firstStringInMaps(candidateMaps, const [
          'segmentId',
          'segment_id',
          'id',
          '_id',
        ]) ??
        '';
    final type = _parseVehicleHistoryStopMarkerType(
      _firstStringInMaps(candidateMaps, const [
            'type',
            'kind',
            'category',
            'label',
            'title',
            'name',
          ]) ??
          '',
    );
    final coordinates = _extractCoordinates(source);
    final startTime = _firstDateInMaps(candidateMaps, const [
      'startTime',
      'start_time',
      'startAt',
      'start_at',
      'startedAt',
      'started_at',
      'from',
      'fromTime',
      'from_time',
      'stopStart',
      'stop_start',
      'timestamp',
      'time',
    ]);
    final endTime = _firstDateInMaps(candidateMaps, const [
      'endTime',
      'end_time',
      'endAt',
      'end_at',
      'endedAt',
      'ended_at',
      'to',
      'toTime',
      'to_time',
      'stopEnd',
      'stop_end',
    ]);
    final durationSec = _parseVehicleHistoryDurationSec(candidateMaps);
    final address = _firstStringInMaps(candidateMaps, const [
          'address',
          'formattedAddress',
          'formatted_address',
          'locationName',
          'location_name',
          'place',
          'landmark',
          'description',
        ]) ??
        '';
    final reason = _firstStringInMaps(candidateMaps, const [
          'reason',
          'stopReason',
          'stop_reason',
          'cause',
          'stopCause',
          'stop_cause',
          'event',
          'eventType',
          'event_type',
          'type',
          'kind',
          'category',
          'label',
          'title',
          'name',
          'engineStatus',
          'engine_status',
          'ignitionStatus',
          'ignition_status',
        ]) ??
        '';

    if (coordinates == null &&
        startTime == null &&
        endTime == null &&
        durationSec == null &&
        address.isEmpty) {
      return null;
    }

    return SuperadminVehicleHistoryStopMarker(
      segmentId: segmentId,
      type: type,
      startTime: startTime,
      endTime: endTime,
      latitude: coordinates?.latitude,
      longitude: coordinates?.longitude,
      durationSec: durationSec,
      address: address,
      reason: reason,
    );
  }

  SuperadminVehicleHistoryStopMarkerType _parseVehicleHistoryStopMarkerType(
    String rawType,
  ) {
    final normalized = rawType.trim().toLowerCase();
    if (normalized == 'idle' || normalized.contains('idle')) {
      return SuperadminVehicleHistoryStopMarkerType.idle;
    }

    if (normalized == 'stop' ||
        normalized.contains('stop') ||
        normalized.contains('stoppage') ||
        normalized.contains('parking') ||
        normalized.contains('halt')) {
      return SuperadminVehicleHistoryStopMarkerType.stop;
    }

    return SuperadminVehicleHistoryStopMarkerType.other;
  }

  bool _looksLikeStopSegment(List<Map<String, dynamic>> candidateMaps) {
    final label = _firstStringInMaps(candidateMaps, const [
      'type',
      'kind',
      'category',
      'status',
      'state',
      'segmentType',
      'segment_type',
      'label',
      'title',
      'name',
    ]);
    final normalized = label?.trim().toLowerCase() ?? '';

    return normalized.contains('stop') ||
        normalized.contains('stoppage') ||
        normalized.contains('halt') ||
        normalized.contains('parking');
  }

  List<Map<String, dynamic>> _vehicleHistorySummaryMaps(dynamic json) {
    final root = _asMap(json);
    final rootData = _asMap(root['data']);
    final history = _asMap(root['history']);
    final rootDataHistory = _asMap(rootData['history']);

    return <Map<String, dynamic>>[
      root,
      _asMap(root['summary']),
      _asMap(root['stats']),
      _asMap(root['totals']),
      _asMap(root['analytics']),
      rootData,
      _asMap(rootData['summary']),
      _asMap(rootData['stats']),
      _asMap(rootData['totals']),
      _asMap(rootData['analytics']),
      history,
      _asMap(history['summary']),
      _asMap(history['stats']),
      _asMap(history['analytics']),
      rootDataHistory,
      _asMap(rootDataHistory['summary']),
      _asMap(rootDataHistory['stats']),
      _asMap(rootDataHistory['analytics']),
    ].where((source) => source.isNotEmpty).toList(growable: false);
  }

  SuperadminVehicleHistoryPoint? _parseVehicleHistoryPoint(dynamic raw) {
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
      _asMap(source['event']),
      _asMap(source['stop']),
    ].where((candidate) => candidate.isNotEmpty).toList(growable: false);
    final coordinates = _extractCoordinates(source);
    final serverTime = _firstDateInMaps(candidateMaps, const [
      'serverTime',
      'server_time',
      'timestamp',
      'time',
      'recordedAt',
      'recorded_at',
      'createdAt',
      'created_at',
      'updatedAt',
      'updated_at',
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
    final speedKph = _firstDoubleByKeyPriority(candidateMaps, const [
      'speedKph',
      'speed_kph',
      'speed',
      'vehicleSpeed',
      'vehicle_speed',
      'gpsSpeed',
      'gps_speed',
    ]);
    final course = _firstDoubleByKeyPriority(candidateMaps, const [
      'course',
      'heading',
      'bearing',
    ]);
    final ignition = _firstBoolByKeyPriority(candidateMaps, const [
      'ignition',
      'ignitionStatus',
      'ignition_status',
      'engineOn',
      'engine_on',
    ]);
    final acc = _firstBoolByKeyPriority(candidateMaps, const [
      'acc',
      'accessory',
      'accessoryOn',
      'accessory_on',
    ]);
    final status = _firstStringInMaps(candidateMaps, const [
          'status',
          'state',
          'vehicleStatus',
          'vehicle_status',
          'motionState',
          'motion_state',
        ]) ??
        '';
    final eventLabel = _firstStringInMaps(candidateMaps, const [
          'event',
          'eventType',
          'event_type',
          'type',
          'label',
          'title',
          'name',
        ]) ??
        '';
    final address = _firstStringInMaps(candidateMaps, const [
          'address',
          'formattedAddress',
          'formatted_address',
          'locationName',
          'location_name',
          'place',
          'landmark',
          'description',
        ]) ??
        '';
    final distanceKm = _firstDoubleByKeyPriority(candidateMaps, const [
      'distanceKm',
      'distance_km',
      'distance',
      'odometerKm',
      'odometer_km',
      'odometer',
      'totalDistance',
      'total_distance',
      'coveredDistance',
      'covered_distance',
    ]);
    final stopDurationSec = _parseVehicleHistoryDurationSec(candidateMaps);

    if (serverTime == null &&
        deviceTime == null &&
        coordinates == null &&
        speedKph == null &&
        status.isEmpty &&
        eventLabel.isEmpty &&
        address.isEmpty) {
      return null;
    }

    return SuperadminVehicleHistoryPoint(
      serverTime: serverTime,
      deviceTime: deviceTime,
      latitude: coordinates?.latitude,
      longitude: coordinates?.longitude,
      speedKph: speedKph,
      course: course,
      ignition: ignition,
      acc: acc,
      status: status,
      address: address,
      eventLabel: eventLabel,
      distanceKm: distanceKm,
      stopDuration:
          stopDurationSec == null ? null : Duration(seconds: stopDurationSec),
    );
  }

  SuperadminMapTelemetry? _parseTelemetryCountList(
    dynamic json, {
    List<VehicleSummary> vehicles = const <VehicleSummary>[],
  }) {
    final list = switch (json) {
      List<dynamic> raw => raw,
      Map<String, dynamic> raw => _firstList(
          raw, const ['items', 'rows', 'data', 'telemetry', 'counts', 'stats']),
      _ => null,
    };

    if (list == null || list.isEmpty) {
      return null;
    }

    int? all;
    int? running;
    int? stop;
    int? inactive;

    for (final item in list) {
      final source = _asMap(item);
      if (source.isEmpty) {
        continue;
      }

      final label = _firstString(
              source, const ['label', 'name', 'key', 'type', 'title', 'status'])
          ?.toLowerCase();
      final count = _firstInt(
          source, const ['count', 'value', 'total', 'items', 'vehicles']);
      if (label == null || count == null) {
        continue;
      }

      if (label.contains('all')) {
        all = count;
        continue;
      }

      if (label.contains('inactive') ||
          label.contains('no_data') ||
          label.contains('no data') ||
          label.contains('offline') ||
          label.contains('disconnected') ||
          label.contains('license_blocked') ||
          label.contains('license blocked')) {
        inactive = count;
        continue;
      }

      if (label.contains('running') ||
          label.contains('moving') ||
          label.contains('active')) {
        running = count;
        continue;
      }

      if (label.contains('stop') ||
          label.contains('stopped') ||
          label.contains('idle')) {
        stop = count;
      }
    }

    if (all == null && running == null && stop == null && inactive == null) {
      return null;
    }

    if (vehicles.isNotEmpty) {
      return _buildTelemetryFromVehicles(vehicles);
    }

    final resolvedRunning = running ?? 0;
    final resolvedInactive = inactive ?? 0;
    final resolvedStop = all == null
        ? stop ?? 0
        : (all - resolvedRunning - resolvedInactive).clamp(0, all).toInt();
    return SuperadminMapTelemetry(
      allCount: all ?? resolvedRunning + resolvedStop + resolvedInactive,
      runningCount: resolvedRunning,
      stopCount: resolvedStop,
      inactiveCount: resolvedInactive,
      vehicles: vehicles,
    );
  }

  SuperadminMapTelemetry _buildTelemetryFromVehicles(
    List<VehicleSummary> vehicles,
  ) {
    final inactiveCount = vehicles.where(_isInactiveVehicle).length;
    final runningCount = vehicles
        .where((vehicle) => !_isInactiveVehicle(vehicle))
        .where(_isRunningVehicle)
        .length;
    return SuperadminMapTelemetry(
      allCount: vehicles.length,
      runningCount: runningCount,
      stopCount: vehicles.length - runningCount - inactiveCount,
      inactiveCount: inactiveCount,
      vehicles: vehicles,
    );
  }

  SuperadminVehicleDetails _buildMockVehicleDetails(String imei) {
    final vehicles = ((_mockVehiclesPayload['vehicles'] as List?) ?? const [])
        .map(_asMap)
        .toList(growable: false);

    Map<String, dynamic> vehicleRecord = const <String, dynamic>{};
    for (final item in vehicles) {
      if (item['imei']?.toString().trim() == imei) {
        vehicleRecord = item;
        break;
      }
    }

    if (vehicleRecord.isEmpty && vehicles.isNotEmpty) {
      vehicleRecord = vehicles.first;
    }

    final recordId = vehicleRecord['_id']?.toString().trim() ?? '';
    VehicleSummary? liveVehicle;
    for (final item in _mockMapVehicles) {
      if (item.id == recordId) {
        liveVehicle = item;
        break;
      }
    }

    return _parseVehicleDetails(
      <String, dynamic>{
        'vehicle': vehicleRecord,
        'vinNumber': '-',
        'vehicleType': <String, dynamic>{
          'name': 'Car',
        },
        'gpsModel': 'GT06',
        'device': <String, dynamic>{
          'imei': vehicleRecord['imei'],
          'sim': vehicleRecord['sim'],
          'model': 'GT06',
        },
        'primaryUser': vehicleRecord['primaryUser'],
        'addedBy': vehicleRecord['addedBy'],
        'todayDistance': 27.84,
        'odometer': 1026.6,
        'todayEngineHours': '1h 3m',
        'totalEngineHours': '18h 47m',
        'ignition': false,
        'satellites': 11,
        'address': 'Achhnera, Kiraoli, Agra, Uttar Pradesh, India',
        'telemetry': <String, dynamic>{
          'status': liveVehicle?.status ?? vehicleRecord['status'],
          'speed': liveVehicle?.speed ?? 0,
          'latitude': liveVehicle?.latitude ?? 27.185390,
          'longitude': liveVehicle?.longitude ?? 77.723290,
        },
        'location': <String, dynamic>{
          'address': 'Achhnera, Kiraoli, Agra, Uttar Pradesh, India',
          'latitude': liveVehicle?.latitude ?? 27.185390,
          'longitude': liveVehicle?.longitude ?? 77.723290,
        },
      },
    );
  }

  SuperadminVehicleLogPage _buildMockVehicleLogs(
    String imei, {
    required int limit,
    String? beforeId,
  }) {
    final startIndex = int.tryParse(beforeId ?? '') ?? 0;
    final now = DateTime.now().toUtc();
    final rows = List<Map<String, dynamic>>.generate(limit, (index) {
      final id = startIndex + index + 1;
      final serverTime = now.subtract(Duration(seconds: id * 20));
      return <String, dynamic>{
        'id': id.toString(),
        'imei': imei,
        'serverTime': serverTime.toIso8601String(),
        'deviceTime':
            serverTime.subtract(const Duration(seconds: 2)).toIso8601String(),
        'packetType': id.isEven ? 'location' : 'heartbeat',
        'protocol': 'gt06',
        'speedKph': id.isEven ? 24 + (id % 6) : 0,
        'course': (id * 12) % 360,
        'ignition': id.isEven,
        'acc': id.isEven,
        'latitude': 28.6139 + (id * 0.0001),
        'longitude': 77.2090 + (id * 0.0001),
        'altitude': 216,
        'satellites': 10,
        'valid': true,
        'odometer': 1026.6 + (id * 0.1),
        'distance': id * 0.05,
        'engineHours': id * 0.01,
        'totalengineHours': 900.5 + (id * 0.01),
        'raw': '78780d010359339075056886000d0a',
        'attributes': <String, dynamic>{
          'batteryLevel': 88,
          'mock': true,
        },
        'createdAt': serverTime.toIso8601String(),
      };
    });

    return SuperadminVehicleLogPage.fromJson(
      <String, dynamic>{
        'items': rows,
        'nextCursor': (startIndex + rows.length).toString(),
      },
    );
  }

  SuperadminVehicleEventPage _buildMockVehicleEvents(
    String imei, {
    required int limit,
    String? beforeId,
  }) {
    final startIndex = int.tryParse(beforeId ?? '') ?? 0;
    final now = DateTime.now().toUtc();
    final rows = List<Map<String, dynamic>>.generate(limit, (index) {
      final id = startIndex + index + 1;
      final createdAt = now.subtract(Duration(minutes: id * 7));
      final isCritical = id % 3 == 0;
      return <String, dynamic>{
        'id': 7000 - id,
        'dedupeKey': '$imei:event:$id',
        'imei': imei,
        'title': isCritical ? 'Overspeed' : 'Ignition',
        'category': isCritical ? 'OVERSPEED' : 'IGNITION',
        'message': isCritical
            ? 'Vehicle crossed the configured speed threshold.'
            : 'Ignition status changed for the selected vehicle.',
        'severity': isCritical ? 'CRITICAL' : 'INFO',
        'createdAt': createdAt.toIso8601String(),
        'metadata': <String, dynamic>{
          'imei': imei,
          'mock': true,
        },
      };
    });

    return SuperadminVehicleEventPage.fromJson(
      <String, dynamic>{
        'items': rows,
        'nextCursor': (startIndex + rows.length).toString(),
        'hasMore': true,
      },
      imei: imei,
      requestedLimit: limit,
    );
  }

  SuperadminVehicleSensorPage _buildMockVehicleSensors(String imei) {
    final now = DateTime.now().toUtc();
    return SuperadminVehicleSensorPage.fromJson(
      <String, dynamic>{
        'vehicle': <String, dynamic>{'imei': imei},
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'name': 'Speed',
            'dataType': 'number',
            'unit': 'km/h',
            'rawAttribute': 'speedKph',
            'updatedAt': now.toIso8601String(),
            'computed': <String, dynamic>{
              'ok': true,
              'displayValue': '0',
              'type': 'number',
            },
          },
          <String, dynamic>{
            'id': 2,
            'name': 'Ignition',
            'dataType': 'boolean',
            'rawAttribute': 'ignition',
            'updatedAt': now.toIso8601String(),
            'computed': <String, dynamic>{
              'ok': true,
              'displayValue': 'Off',
              'type': 'boolean',
            },
          },
        ],
        'totalCount': 2,
        'truncated': false,
        'telemetryMeta': <String, dynamic>{
          'hasTelemetry': true,
          'serverTime': now.toIso8601String(),
        },
      },
    );
  }

  List<SuperadminCustomCommand> _buildMockCustomCommands() {
    return parseSuperadminCustomCommands(
      const <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 1,
          'deviceTypeId': 1,
          'commandTypeId': 1,
          'command': 'STATUS',
          'isActive': true,
          'commandType': <String, dynamic>{
            'id': 1,
            'name': 'Status',
            'description': 'Request current device status',
          },
          'deviceType': <String, dynamic>{
            'id': 1,
            'name': 'GPS Tracker',
            'protocol': 'GPRS',
          },
        },
        <String, dynamic>{
          'id': 2,
          'deviceTypeId': 1,
          'commandTypeId': 2,
          'command': r'WHERE#{{IMEI}}#${LAT},${LON}',
          'isActive': true,
          'commandType': <String, dynamic>{
            'id': 2,
            'name': 'Locate',
          },
          'deviceType': <String, dynamic>{
            'id': 1,
            'name': 'GPS Tracker',
            'protocol': 'GPRS',
          },
        },
      ],
    );
  }

  List<SuperadminSystemVariable> _buildMockSystemVariables() {
    return parseSuperadminSystemVariables(
      const <Map<String, dynamic>>[
        <String, dynamic>{'id': 1, 'name': 'SERVER', 'initialValue': 'OPENVTS'},
        <String, dynamic>{'id': 2, 'name': 'MODE', 'initialValue': 'LIVE'},
      ],
    );
  }

  SuperadminCommandHistoryPage _buildMockVehicleCommands(
    String imei, {
    required int limit,
    String? cursorId,
  }) {
    final startIndex = int.tryParse(cursorId ?? '') ?? 0;
    final now = DateTime.now().toUtc();
    final rows = List<Map<String, dynamic>>.generate(limit, (index) {
      final id = startIndex + index + 1;
      final requestedAt = now.subtract(Duration(minutes: id * 5));
      return <String, dynamic>{
        'id': 9000 - id,
        'cmdId': 'mock-cmd-$id',
        'imei': imei,
        'command': id.isEven ? 'STATUS' : 'WHERE#$imei',
        'status': id.isEven ? 'RESPONDED' : 'SENT',
        'requestedByRole': 'SUPERADMIN',
        'transport': 'GPRS',
        'source': 'mock',
        'connectedAtSend': true,
        'requestedAt': requestedAt.toIso8601String(),
        'sentAt': requestedAt.add(const Duration(seconds: 1)).toIso8601String(),
        if (id.isEven)
          'respondedAt':
              requestedAt.add(const Duration(seconds: 4)).toIso8601String(),
        if (id.isEven) 'responseRaw': 'OK',
        'metadata': <String, dynamic>{'mock': true},
      };
    });

    return SuperadminCommandHistoryPage.fromJson(
      <String, dynamic>{
        'items': rows,
        'nextCursorId': (startIndex + rows.length).toString(),
        'hasMore': true,
      },
    );
  }

  bool _shouldFallbackToVehicleList(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == 404 || statusCode == 405;
  }

  Future<List<VehicleSummary>> _loadVehicleLocationFallback({
    required String refreshKey,
  }) async {
    try {
      final response = await _apiClient.get<dynamic>(
        ApiEndpoints.superadmin.vehicles,
        queryParameters: <String, dynamic>{
          'rk': refreshKey,
        },
        options: _readOptions,
        parser: (json) => json,
      );

      return _parseVehicleList(response.data);
    } catch (_) {
      return const <VehicleSummary>[];
    }
  }

  VehicleSummary? _vehicleSummaryFromJson(
    dynamic raw, {
    bool requireCoordinates = true,
  }) {
    final json = _asMap(raw);
    if (json.isEmpty) {
      return null;
    }

    final candidateMaps = _candidateVehicleMaps(json);
    final coordinates = _extractCoordinates(json);
    if (coordinates == null && requireCoordinates) {
      return null;
    }

    final plateNumber = _firstStringInMaps(candidateMaps, const [
          'plateNumber',
          'plate_number',
          'plateNo',
          'plate_no',
          'vehicleNumber',
          'vehicle_number',
          'registrationNo',
          'registration_no',
          'registrationNumber',
          'registration_number',
        ]) ??
        '';
    final name = (_firstStringInMaps(candidateMaps, const [
              'name',
              'vehicleName',
              'vehicle_name',
              'label',
              'title'
            ]) ??
            '')
        .trim();
    final imei = _firstStringInMaps(candidateMaps, const [
          'imei',
          'deviceImei',
          'device_imei',
          'trackerImei',
          'tracker_imei',
        ]) ??
        '';
    final licenseBlocked = _firstBoolByKeyPriority(candidateMaps, const [
      'licenseBlocked',
      'license_blocked',
      'isLicenseBlocked',
      'is_license_blocked',
    ]);
    final status = licenseBlocked == true
        ? 'license_blocked'
        : _firstStringInMaps(candidateMaps, const [
              'status',
              'state',
              'vehicleStatus',
              'vehicle_status',
              'liveStatus',
              'live_status',
              'connectionStatus',
              'connection_status',
              'lastStatus',
              'last_status',
            ]) ??
            'unknown';

    return VehicleSummary(
      id: _firstStringInMaps(candidateMaps,
              const ['id', '_id', 'vehicleId', 'vehicle_id', 'uid']) ??
          '',
      imei: imei,
      name: name.isNotEmpty ? name : plateNumber,
      plateNumber: plateNumber,
      status: status,
      speed: _firstDoubleInMaps(candidateMaps, const [
            'speed',
            'vehicleSpeed',
            'vehicle_speed',
            'gpsSpeed',
            'gps_speed',
            'speedKph',
            'speed_kph',
            'currentSpeed',
            'current_speed',
          ]) ??
          0,
      latitude: coordinates?.latitude ?? 28.6139,
      longitude: coordinates?.longitude ?? 77.2090,
      deviceTypeId: _firstIntByKeyPriority(candidateMaps, const [
            'deviceTypeId',
            'device_type_id',
            'trackerDeviceTypeId',
            'tracker_device_type_id',
          ]) ??
          _firstInt(_asMap(json['deviceType']), const ['id']) ??
          _firstInt(_asMap(json['device_type']), const ['id']),
      hasValidLocation: coordinates != null,
      updatedAt: _firstDateInMaps(candidateMaps, const [
        'updatedAt',
        'updated_at',
        'lastUpdate',
        'last_update',
        'lastUpdatedAt',
        'last_updated_at',
        'lastUpdatedAtMs',
        'last_updated_at_ms',
        'timestamp',
        'deviceTime',
        'device_time',
        'gpsTime',
        'gps_time',
        'serverTime',
        'server_time',
        'serverTimeMs',
        'server_time_ms',
        'lastSeenAt',
        'last_seen_at',
        'lastSeen',
        'last_seen',
        'lastSeenOn',
        'last_seen_on',
        'seenAt',
        'seen_at',
        'packetTime',
        'packet_time',
        'recordedAt',
        'recorded_at',
        'time',
        'dateTime',
        'datetime',
        'createdAt',
        'created_at',
        'date',
      ]),
      distanceKm: _firstDoubleByKeyPriority(candidateMaps, const [
        'todayDistance',
        'today_distance',
        'distanceToday',
        'distance_today',
        'todayKm',
        'today_km',
        'kmToday',
        'km_today',
        'dailyDistance',
        'daily_distance',
        'travelDistance',
        'travel_distance',
        'coveredDistance',
        'covered_distance',
        'tripDistance',
        'trip_distance',
        'coveredKm',
        'covered_km',
        'distance',
        'distanceKm',
        'distance_km',
      ]),
      odometerKm: _firstOdometerKmByKeyPriority(candidateMaps, const [
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
      engineHoursToday: _firstEngineHoursByKeyPriority(candidateMaps, const [
        'engineHoursToday',
        'engine_hours_today',
        'todayEngineHours',
        'today_engine_hours',
        'engineHours',
        'engine_hours',
      ]),
      engineHours: _firstEngineHoursByKeyPriority(candidateMaps, const [
        'engineHours',
        'engine_hours',
      ]),
      totalEngineHours: _firstEngineHoursByKeyPriority(candidateMaps, const [
        'totalengineHours',
        'totalEngineHours',
        'total_engine_hours',
        'engineHoursTotal',
        'engine_hours_total',
        'hours',
      ]),
      satellites: _firstIntByKeyPriority(candidateMaps, const [
        'satellites',
        'satelliteCount',
        'satellite_count',
        'gpsSatellites',
        'gps_satellites',
      ]),
      headingDegrees: _normalizedHeadingDegrees(
        _firstDoubleInMaps(candidateMaps, const [
              'heading',
              'bearing',
              'course',
              'angle',
              'direction',
              'headingDegrees',
              'heading_degrees',
              'bearingDegrees',
              'bearing_degrees',
              'courseDegrees',
              'course_degrees',
            ]) ??
            _radiansToDegrees(
              _firstDoubleInMaps(candidateMaps, const [
                'headingRadians',
                'heading_radians',
                'bearingRadians',
                'bearing_radians',
                'courseRadians',
                'course_radians',
              ]),
            ),
      ),
      ignition: _firstBoolByKeyPriority(candidateMaps, const [
        'ignition',
        'ignitionStatus',
        'ignition_status',
        'engineOn',
        'engine_on',
      ]),
      acc: _firstBoolByKeyPriority(candidateMaps, const [
        'acc',
        'accessory',
        'accessoryOn',
        'accessory_on',
      ]),
      deviceConnectionStatus: _firstStringInMaps(candidateMaps, const [
        'deviceConnectionStatus',
        'device_connection_status',
        'connectionStatus',
        'connection_status',
      ]),
      lastSeenAt: _firstDateInMaps(candidateMaps, const [
        'lastSeenAt',
        'last_seen_at',
        'lastSeen',
        'last_seen',
        'seenAt',
        'seen_at',
      ]),
    );
  }

  double? _normalizedHeadingDegrees(double? value) {
    if (value == null || !value.isFinite) {
      return null;
    }

    final normalized = value % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double? _radiansToDegrees(double? radians) {
    if (radians == null) {
      return null;
    }

    return radians * (180 / 3.1415926535897932);
  }

  List<String> _vehicleIdentityAliases({
    List<Map<String, dynamic>> candidateMaps = const <Map<String, dynamic>>[],
    VehicleSummary? fallbackVehicle,
  }) {
    final aliases = <String>[];
    final seen = <String>{};

    void addAlias(String prefix, String? rawValue) {
      final value = (rawValue ?? '').trim();
      if (value.isEmpty) {
        return;
      }

      final alias = '$prefix:$value';
      if (seen.add(alias)) {
        aliases.add(alias);
      }
    }

    addAlias(
      'id',
      _firstStringInMaps(candidateMaps, const [
        'id',
        '_id',
        'vehicleId',
        'vehicle_id',
        'uid',
        'deviceId',
        'device_id',
        'trackerId',
        'tracker_id',
      ]),
    );
    addAlias(
      'imei',
      _firstStringInMaps(candidateMaps, const [
        'imei',
        'deviceImei',
        'device_imei',
        'trackerImei',
        'tracker_imei',
      ]),
    );
    addAlias(
      'plate',
      _firstStringInMaps(candidateMaps, const [
        'plateNumber',
        'plate_number',
        'plateNo',
        'plate_no',
        'vehicleNumber',
        'vehicle_number',
        'registrationNo',
        'registration_no',
        'registrationNumber',
        'registration_number',
      ]),
    );

    if (fallbackVehicle != null) {
      addAlias('id', fallbackVehicle.id);
      addAlias('imei', fallbackVehicle.imei);
      addAlias('plate', fallbackVehicle.plateNumber);
    }

    return aliases;
  }

  List<Map<String, dynamic>> _candidateVehicleMaps(
      Map<String, dynamic> source) {
    final dataMap = _asMap(source['data']);
    final telemetryMap = _asMap(source['telemetry']);
    final lastTelemetryMap = _asMap(source['lastTelemetry']);
    final lastTelemetrySnakeMap = _asMap(source['last_telemetry']);
    final telemetrySnapshotMap = _asMap(source['telemetrySnapshot']);
    final telemetrySnapshotSnakeMap = _asMap(source['telemetry_snapshot']);
    final candidates = <Map<String, dynamic>>[
      source,
      _asMap(source['vehicle']),
      _asMap(source['details']),
      _asMap(source['vehicleDetails']),
      _asMap(source['vehicle_details']),
      _asMap(source['vehicleInfo']),
      _asMap(source['vehicle_info']),
      dataMap,
      _asMap(source['device']),
      _asMap(source['deviceType']),
      _asMap(source['device_type']),
      _asMap(source['tracker']),
      telemetryMap,
      lastTelemetryMap,
      lastTelemetrySnakeMap,
      telemetrySnapshotMap,
      telemetrySnapshotSnakeMap,
      _asMap(source['summary']),
      _asMap(source['stats']),
      _asMap(source['metrics']),
      _asMap(source['metadata']),
      _asMap(source['meta']),
      _asMap(source['attributes']),
      _asMap(dataMap['attributes']),
      _asMap(telemetryMap['attributes']),
      _asMap(lastTelemetryMap['attributes']),
      _asMap(lastTelemetrySnakeMap['attributes']),
      _asMap(telemetrySnapshotMap['attributes']),
      _asMap(telemetrySnapshotSnakeMap['attributes']),
      _asMap(source['position']),
      _asMap(source['location']),
      _asMap(source['lastLocation']),
      _asMap(source['last_location']),
      _asMap(source['currentLocation']),
      _asMap(source['current_location']),
    ];

    return candidates.where((candidate) => candidate.isNotEmpty).toList(
          growable: false,
        );
  }

  _CoordinatePair? _extractCoordinates(Map<String, dynamic> json) {
    final latitude = _firstDouble(json, const ['latitude', 'lat']);
    final longitude =
        _firstDouble(json, const ['longitude', 'lng', 'lon', 'long']);

    if (_isValidCoordinatePair(latitude, longitude)) {
      return _CoordinatePair(latitude!, longitude!);
    }

    final coordinateList =
        _firstList(json, const ['coordinates', 'coord', 'coords']);
    if (coordinateList != null && coordinateList.length >= 2) {
      final longitude = _asDouble(coordinateList[0]);
      final latitude = _asDouble(coordinateList[1]);
      if (_isValidCoordinatePair(latitude, longitude)) {
        return _CoordinatePair(latitude!, longitude!);
      }
    }

    for (final key in const [
      'location',
      'lastLocation',
      'last_location',
      'currentLocation',
      'current_location',
      'position',
      'gps',
      'tracker',
      'device',
      'deviceLocation',
      'device_location',
      'geometry',
    ]) {
      final nested = _asMap(json[key]);
      if (nested.isEmpty) {
        continue;
      }

      final nestedCoordinates = _extractCoordinates(nested);
      if (nestedCoordinates != null) {
        return nestedCoordinates;
      }
    }

    return null;
  }

  _CoordinatePair? _firstCoordinatesInMaps(
    List<Map<String, dynamic>> candidates,
  ) {
    for (final candidate in candidates) {
      if (candidate.isEmpty) {
        continue;
      }

      final coordinates = _extractCoordinates(candidate);
      if (coordinates != null) {
        return coordinates;
      }
    }

    return null;
  }

  SuperadminVehicleDetails _parseVehicleDetails(dynamic raw) {
    final source = _asMap(raw);
    if (source.isEmpty) {
      return const SuperadminVehicleDetails.empty();
    }

    final candidateMaps = _candidateVehicleMaps(source);
    final coordinates = _extractCoordinates(source);

    return SuperadminVehicleDetails(
      imei: _firstStringInMaps(candidateMaps, const [
            'imei',
            'deviceImei',
            'device_imei',
            'trackerImei',
            'tracker_imei',
          ]) ??
          '',
      name: _firstStringInMaps(candidateMaps, const [
            'name',
            'vehicleName',
            'vehicle_name',
            'displayName',
            'display_name',
            'title',
            'label',
          ]) ??
          '',
      plateNumber: _firstStringInMaps(candidateMaps, const [
            'plateNumber',
            'plate_number',
            'plateNo',
            'plate_no',
            'vehicleNumber',
            'vehicle_number',
            'registrationNo',
            'registration_no',
            'registrationNumber',
            'registration_number',
          ]) ??
          '',
      status: _firstStringInMaps(candidateMaps, const [
            'status',
            'vehicleStatus',
            'vehicle_status',
            'state',
            'liveStatus',
            'live_status',
            'connectionStatus',
            'connection_status',
            'lastStatus',
            'last_status',
          ]) ??
          '',
      speed: _firstDoubleByKeyPriority(candidateMaps, const [
        'speed',
        'vehicleSpeed',
        'vehicle_speed',
        'gpsSpeed',
        'gps_speed',
        'speedKph',
        'speed_kph',
        'currentSpeed',
        'current_speed',
      ]),
      distanceKm: _firstDoubleByKeyPriority(candidateMaps, const [
        'todayDistance',
        'today_distance',
        'distanceToday',
        'distance_today',
        'todayKm',
        'today_km',
        'kmToday',
        'km_today',
        'dailyDistance',
        'daily_distance',
        'travelDistance',
        'travel_distance',
        'coveredDistance',
        'covered_distance',
        'tripDistance',
        'trip_distance',
        'coveredKm',
        'covered_km',
        'distance',
        'distanceKm',
        'distance_km',
      ]),
      updatedAt: _firstDateInMaps(candidateMaps, const [
        'updatedAt',
        'updated_at',
        'lastUpdate',
        'last_update',
        'timestamp',
        'deviceTime',
        'device_time',
        'gpsTime',
        'gps_time',
        'serverTime',
        'server_time',
        'lastSeenAt',
        'last_seen_at',
        'lastSeen',
        'last_seen',
        'lastSeenOn',
        'last_seen_on',
        'seenAt',
        'seen_at',
        'packetTime',
        'packet_time',
        'recordedAt',
        'recorded_at',
        'time',
        'dateTime',
        'datetime',
        'createdAt',
        'created_at',
        'date',
      ]),
      latitude: coordinates?.latitude,
      longitude: coordinates?.longitude,
      sections: _buildVehicleDetailsSections(source),
    );
  }

  SuperadminVehicleReplay _buildMockVehicleReplay(
    String imei,
    DateTime from,
    DateTime to,
  ) {
    final start = from.toUtc();
    final end = to.toUtc();
    final totalSeconds = end.difference(start).inSeconds.abs();
    final stepSeconds = totalSeconds <= 0 ? 60 : (totalSeconds / 23).round();
    const baseLatitude = 28.6139;
    const baseLongitude = 77.2090;
    final points = List<SuperadminReplayPoint>.generate(24, (index) {
      final isStopped = index >= 8 && index <= 11;
      return SuperadminReplayPoint(
        serverTime: start.add(Duration(seconds: stepSeconds * index + 2)),
        deviceTime: start.add(Duration(seconds: stepSeconds * index)),
        latitude: baseLatitude + (index * 0.0012),
        longitude: baseLongitude + (index * 0.0010),
        speedKph: isStopped ? 0 : 24 + ((index % 5) * 4),
        course: 42 + (index * 3),
        ignition: true,
        acc: true,
        odometer: 52000.8 + (index * 0.18),
        distance: index * 180,
        engineHours: 2.4 + (index * 0.01),
        totalengineHours: 900.5 + (index * 0.01),
        satellites: 10,
        attributes: const <String, dynamic>{},
      );
    });

    return SuperadminVehicleReplay(
      imei: imei,
      from: from,
      to: to,
      meta: SuperadminReplayMeta(
        totalRaw: points.length,
        returned: points.length,
        bucketSeconds: stepSeconds,
      ),
      points: points,
    );
  }

  List<SuperadminVehicleDetailsSection> _buildVehicleDetailsSections(
    Map<String, dynamic> source,
  ) {
    if (source.isEmpty) {
      return const <SuperadminVehicleDetailsSection>[];
    }

    final sections = <SuperadminVehicleDetailsSection>[];
    final overviewRows = <SuperadminVehicleDetailField>[];

    for (final entry in source.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map || value is List) {
        final rows = <SuperadminVehicleDetailField>[];
        _appendVehicleDetailRows(rows, '', value);
        if (rows.isNotEmpty) {
          sections.add(
            SuperadminVehicleDetailsSection(
              title: _humanizeVehicleDetailLabel(key),
              rows: rows,
            ),
          );
        }
        continue;
      }

      final formattedValue = _formatVehicleDetailScalar(value);
      if (formattedValue == null) {
        continue;
      }

      overviewRows.add(
        SuperadminVehicleDetailField(
          label: _humanizeVehicleDetailLabel(key),
          value: formattedValue,
        ),
      );
    }

    if (overviewRows.isNotEmpty) {
      sections.insert(
        0,
        SuperadminVehicleDetailsSection(
          title: 'Overview',
          rows: overviewRows,
        ),
      );
    }

    return sections;
  }

  void _appendVehicleDetailRows(
    List<SuperadminVehicleDetailField> rows,
    String path,
    dynamic value,
  ) {
    if (value is Map) {
      final nested = _asMap(value);
      for (final entry in nested.entries) {
        final nestedPath = path.isEmpty ? entry.key : '$path / ${entry.key}';
        _appendVehicleDetailRows(rows, nestedPath, entry.value);
      }
      return;
    }

    if (value is List) {
      if (value.isEmpty) {
        return;
      }

      final containsStructuredItem = value.any(
        (item) => item is Map || item is List,
      );
      if (!containsStructuredItem) {
        final items = value
            .map(_formatVehicleDetailScalar)
            .whereType<String>()
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        if (items.isEmpty) {
          return;
        }

        rows.add(
          SuperadminVehicleDetailField(
            label: _humanizeVehicleDetailLabel(path),
            value: items.join(', '),
          ),
        );
        return;
      }

      for (var index = 0; index < value.length; index++) {
        final nestedPath =
            path.isEmpty ? 'Item ${index + 1}' : '$path ${index + 1}';
        _appendVehicleDetailRows(rows, nestedPath, value[index]);
      }
      return;
    }

    final formattedValue = _formatVehicleDetailScalar(value);
    if (formattedValue == null) {
      return;
    }

    rows.add(
      SuperadminVehicleDetailField(
        label: _humanizeVehicleDetailLabel(path),
        value: formattedValue,
      ),
    );
  }

  String? _formatVehicleDetailScalar(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (value is bool) {
      return value ? 'True' : 'False';
    }

    if (value is num) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }

      return value.toString();
    }

    if (value is DateTime) {
      return value.toLocal().toIso8601String();
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _humanizeVehicleDetailLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Value';
    }

    final segments = trimmed.split('/');
    return segments.map((segment) {
      final normalized = segment
          .replaceAll(RegExp(r'[_-]+'), ' ')
          .replaceAll(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (normalized.isEmpty) {
        return 'Value';
      }

      final lower = normalized.toLowerCase();
      return switch (lower) {
        'imei' => 'IMEI',
        'id' => 'ID',
        'gps' => 'GPS',
        'sim' => 'SIM',
        _ => normalized
            .split(' ')
            .map((word) => word.isEmpty
                ? word
                : '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' '),
      };
    }).join(' / ');
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

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    return const <String, dynamic>{};
  }

  List<dynamic>? _firstList(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is List<dynamic>) {
        return value;
      }

      if (value is List) {
        return value.toList(growable: false);
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
      if (text.isNotEmpty) {
        return text;
      }
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

  double? _firstDoubleByKeyPriority(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final key in keys) {
      for (final source in sources) {
        final value = _asDouble(source[key]);
        if (value != null) {
          return value;
        }
      }
    }

    return null;
  }

  double? _firstOdometerKmByKeyPriority(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final key in keys) {
      for (final source in sources) {
        final value = _asDouble(source[key]);
        if (value == null) {
          continue;
        }

        final normalizedValue = _normalizeOdometerKm(key, value);
        if (normalizedValue.isFinite && normalizedValue > 0) {
          return normalizedValue;
        }
      }
    }

    return null;
  }

  double _normalizeOdometerKm(String key, double value) {
    final normalizedKey = _normalizeTelemetryMetricKey(key);
    if (normalizedKey.endsWith('meters')) {
      return value / 1000;
    }

    return value;
  }

  double? _firstEngineHoursByKeyPriority(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final key in keys) {
      for (final source in sources) {
        final value = _asEngineHours(source[key]);
        if (value != null) {
          return _normalizeEngineHours(key, value);
        }
      }
    }

    return null;
  }

  double _normalizeEngineHours(String key, double value) {
    final normalizedKey = _normalizeTelemetryMetricKey(key);
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
    final matches = RegExp(
      r'(\d+(?:\.\d+)?)\s*(h|hr|hrs|hour|hours|m|min|mins|minute|minutes|s|sec|secs|second|seconds)\b',
      caseSensitive: false,
    ).allMatches(value);
    var totalHours = 0.0;
    var matched = false;

    for (final match in matches) {
      final amount = double.tryParse(match.group(1)!);
      final unit = match.group(2)!.toLowerCase();
      if (amount == null) {
        continue;
      }

      matched = true;
      if (unit.startsWith('h')) {
        totalHours += amount;
      } else if (unit.startsWith('m')) {
        totalHours += amount / 60;
      } else {
        totalHours += amount / 3600;
      }
    }

    return matched ? totalHours : null;
  }

  String _normalizeTelemetryMetricKey(String key) {
    return key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  int? _firstIntByKeyPriority(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final key in keys) {
      for (final source in sources) {
        final value = _asInt(source[key]);
        if (value != null) {
          return value;
        }
      }
    }

    return null;
  }

  bool? _firstBoolByKeyPriority(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final key in keys) {
      for (final source in sources) {
        final value = _asBool(source[key]);
        if (value != null) {
          return value;
        }
      }
    }

    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final trimmed = value.trim();
      final direct = double.tryParse(trimmed);
      if (direct != null) {
        return direct;
      }

      final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(trimmed);
      if (match == null) {
        return null;
      }

      return double.tryParse(match.group(0)!);
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

  DateTime _dateFromEpoch(num value) {
    final raw = value.toInt();
    final milliseconds = raw.abs() < 100000000000 ? raw * 1000 : raw;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }

  int? _firstInt(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = _asInt(source[key]);
      if (value != null) {
        return value;
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
      final trimmed = value.trim();
      return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.toInt();
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
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) {
        return null;
      }

      if (normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'on') {
        return true;
      }

      if (normalized == 'false' ||
          normalized == '0' ||
          normalized == 'no' ||
          normalized == 'off') {
        return false;
      }
    }

    return null;
  }
}

class SuperadminMapTelemetry {
  const SuperadminMapTelemetry({
    required this.allCount,
    required this.runningCount,
    required this.stopCount,
    required this.inactiveCount,
    required this.vehicles,
  });

  final int allCount;
  final int runningCount;
  final int stopCount;
  final int inactiveCount;
  final List<VehicleSummary> vehicles;
}

class SuperadminVehicleDetails {
  const SuperadminVehicleDetails({
    required this.imei,
    required this.name,
    required this.plateNumber,
    required this.status,
    required this.speed,
    required this.distanceKm,
    required this.updatedAt,
    required this.latitude,
    required this.longitude,
    required this.sections,
  });

  const SuperadminVehicleDetails.empty({this.imei = ''})
      : name = '',
        plateNumber = '',
        status = '',
        speed = null,
        distanceKm = null,
        updatedAt = null,
        latitude = null,
        longitude = null,
        sections = const <SuperadminVehicleDetailsSection>[];

  final String imei;
  final String name;
  final String plateNumber;
  final String status;
  final double? speed;
  final double? distanceKm;
  final DateTime? updatedAt;
  final double? latitude;
  final double? longitude;
  final List<SuperadminVehicleDetailsSection> sections;

  bool get hasCoordinates => latitude != null && longitude != null;
}

class SuperadminVehicleDetailsSection {
  const SuperadminVehicleDetailsSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<SuperadminVehicleDetailField> rows;
}

class SuperadminVehicleDetailField {
  const SuperadminVehicleDetailField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _HistoryStopListCandidate {
  const _HistoryStopListCandidate(
    this.value, {
    required this.requireStopKind,
  });

  final dynamic value;
  final bool requireStopKind;
}

class _CoordinatePair {
  const _CoordinatePair(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

const _mockVehiclesPayload = <String, dynamic>{
  'totalVehicles': 5,
  'vehicles': <Map<String, dynamic>>[
    <String, dynamic>{
      '_id': 'veh-1',
      'name': 'CAR 76',
      'plateNumber': 'UP80GH6512',
      'status': 'active',
      'vehicleType': <String, dynamic>{'name': 'car'},
      'imei': '867440060976859',
      'sim': '5754123841461',
      'primaryUser': <String, dynamic>{'name': 'the user'},
      'addedBy': <String, dynamic>{'name': 'mukesh Kumar'},
      'createdAt': '2026-04-24T19:54:00Z',
    },
    <String, dynamic>{
      '_id': 'veh-2',
      'name': 'Car 7',
      'plateNumber': 'MH12AB0007',
      'status': 'active',
      'vehicleType': <String, dynamic>{'name': 'car'},
      'imei': '12345678669812346',
      'sim': '9876543211',
      'primaryUser': <String, dynamic>{'name': 'wwwwwwwwwww...'},
      'addedBy': <String, dynamic>{'name': 'mukesh Kumar'},
      'createdAt': '2026-05-04T15:20:00Z',
    },
    <String, dynamic>{
      '_id': 'veh-3',
      'name': 'Car 7',
      'plateNumber': 'MH12AB0007',
      'status': 'active',
      'vehicleType': <String, dynamic>{'name': 'car'},
      'imei': '123456789812346',
      'sim': '9876543211',
      'primaryUser': <String, dynamic>{'name': 'wwwwwwwwwww...'},
      'addedBy': <String, dynamic>{'name': 'mukesh Kumar'},
      'createdAt': '2026-05-04T15:14:00Z',
    },
    <String, dynamic>{
      '_id': 'veh-4',
      'name': 'Truck 12',
      'plateNumber': 'GJ01AA1234',
      'status': 'active',
      'vehicleType': <String, dynamic>{'name': 'truck'},
      'imei': '123456789812345',
      'sim': '9876543210',
      'primaryUser': <String, dynamic>{'name': 'wwwwwwwwwww...'},
      'addedBy': <String, dynamic>{'name': 'mukesh Kumar'},
      'createdAt': '2026-05-04T15:14:00Z',
    },
    <String, dynamic>{
      '_id': 'veh-5',
      'name': 'bike',
      'plateNumber': 'MH-01',
      'status': 'active',
      'vehicleType': <String, dynamic>{'name': 'bike'},
      'imei': '867440065904111',
      'sim': '6767656766566',
      'primaryUser': <String, dynamic>{'name': 'the user'},
      'addedBy': <String, dynamic>{'name': 'mukesh Kumar'},
      'createdAt': '2026-04-21T12:03:00Z',
    },
  ],
};

const _mockMapVehicles = [
  VehicleSummary(
    id: 'veh-1',
    imei: '867440060976859',
    name: 'CAR 76',
    plateNumber: 'UP80GH6512',
    status: 'online',
    speed: 0,
    latitude: 28.6139,
    longitude: 77.2090,
  ),
  VehicleSummary(
    id: 'veh-2',
    imei: '12345678669812346',
    name: 'Car 7',
    plateNumber: 'MH12AB0007',
    status: 'online',
    speed: 0,
    latitude: 28.7041,
    longitude: 77.1025,
  ),
  VehicleSummary(
    id: 'veh-4',
    imei: '123456789812345',
    name: 'Truck 12',
    plateNumber: 'GJ01AA1234',
    status: 'online',
    speed: 0,
    latitude: 23.0225,
    longitude: 72.5714,
  ),
  VehicleSummary(
    id: 'veh-5',
    imei: '867440065904111',
    name: 'bike',
    plateNumber: 'MH-01',
    status: 'online',
    speed: 0,
    latitude: 19.0760,
    longitude: 72.8777,
  ),
];

bool _isRunningVehicle(VehicleSummary vehicle) {
  final status = _normalizeVehicleStatus(vehicle.status);
  return vehicle.speed > 0 ||
      status.contains('running') ||
      status.contains('moving') ||
      status.contains('drive');
}

bool _isInactiveVehicle(VehicleSummary vehicle) {
  final status = _normalizeVehicleStatus(vehicle.status);
  if (const <String>{
    'inactive',
    'no_data',
    'offline',
    'disconnected',
    'license_blocked',
  }.contains(status)) {
    return true;
  }

  final deviceStatus = vehicle.deviceConnectionStatus?.trim().toUpperCase();
  if (deviceStatus == 'DISCONNECTED') {
    final lastSeenAt = vehicle.lastSeenAt ?? vehicle.updatedAt;
    if (lastSeenAt == null) {
      return true;
    }

    final age = DateTime.now().difference(lastSeenAt);
    return !age.isNegative && age >= const Duration(hours: 48);
  }

  return false;
}

String _normalizeVehicleStatus(String status) {
  return status.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
}
