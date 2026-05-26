import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/api/api_options.dart';
import '../../../shared/models/vehicle_summary.dart';
import '../../notifications/models/app_notification.dart';
import '../../superadmin/models/superadmin_map_overlay_model.dart';
import '../../superadmin/models/superadmin_vehicle_history_model.dart';
import '../../superadmin/models/superadmin_vehicle_model.dart';
import '../../superadmin/services/superadmin_map_overlay_service.dart';
import '../../superadmin/services/superadmin_vehicle_service.dart';
import '../models/live_map_role_config.dart';

// ---------------------------------------------------------------------------
// Role-neutral model aliases.
//
// The Superadmin Map parsers are battle-tested. Instead of duplicating ~3.7k
// lines of model + parser code, we expose them under role-neutral names via
// typedefs so the Admin/User maps can speak `LiveMapTelemetry` etc., while
// the underlying classes (and JSON parsing rules) stay byte-identical.
// ---------------------------------------------------------------------------
typedef LiveMapTelemetry = SuperadminMapTelemetry;
typedef LiveMapVehicleDetails = SuperadminVehicleDetails;
typedef LiveMapVehicleLogPage = SuperadminVehicleLogPage;
typedef LiveMapVehicleLog = SuperadminVehicleLog;
typedef LiveMapVehicleEventPage = SuperadminVehicleEventPage;
typedef LiveMapVehicleSensorPage = SuperadminVehicleSensorPage;
typedef LiveMapVehicleHistory = SuperadminVehicleHistory;
typedef LiveMapVehicleHistoryRequest = SuperadminVehicleHistoryRequest;
typedef LiveMapVehicleReplay = SuperadminVehicleReplay;
typedef LiveMapCustomCommand = SuperadminCustomCommand;
typedef LiveMapSystemVariable = SuperadminSystemVariable;
typedef LiveMapSendCommandResult = SuperadminSendCommandResult;
typedef LiveMapCommandHistoryPage = SuperadminCommandHistoryPage;
typedef LiveMapCommandHistoryItem = SuperadminCommandHistoryItem;
typedef LiveMapCommandStatus = SuperadminCommandStatus;

/// Shared role-aware live-map service.
///
/// Holds a [LiveMapRoleConfig] for endpoint resolution and delegates JSON
/// parsing to the proven Superadmin parsers. Every API call goes through
/// the role-scoped endpoint from [_config] — there is no path to leak a
/// superadmin endpoint into an admin/user session.
class LiveMapVehicleService {
  LiveMapVehicleService({
    required ApiClient apiClient,
    required LiveMapRoleConfig config,
  })  : _apiClient = apiClient,
        _config = config,
        _parsers = SuperadminVehicleService(apiClient),
        _overlayParsers = SuperadminMapOverlayService(apiClient);

  final ApiClient _apiClient;
  final LiveMapRoleConfig _config;
  // Used purely as a parser host — no methods on these instances that hit
  // a hard-coded superadmin endpoint are ever invoked from this class.
  final SuperadminVehicleService _parsers;
  final SuperadminMapOverlayService _overlayParsers;

  LiveMapRoleConfig get config => _config;
  LiveMapRole get role => _config.role;

  static final Options _readOptions = normalReadOptions();

  // -------------------------------------------------------------------------
  // Parser passthroughs (used by LiveMapController for socket payload merge).
  // -------------------------------------------------------------------------

  LiveMapTelemetry parseMapTelemetryPayload(dynamic json) {
    return _parsers.parseMapTelemetryPayload(json);
  }

  VehicleSummary? parseTelemetryVehiclePayload(
    dynamic raw, {
    bool requireCoordinates = false,
  }) {
    return _parsers.parseTelemetryVehiclePayload(
      raw,
      requireCoordinates: requireCoordinates,
    );
  }

  LiveMapTelemetry buildTelemetryFromVehicles(
    List<VehicleSummary> vehicles,
  ) {
    return _parsers.buildTelemetryFromVehicles(vehicles);
  }

  SuperadminVehicleLog? parseTelemetryLogPayload(dynamic raw) {
    return _parsers.parseTelemetryLogPayload(raw);
  }

  List<SuperadminVehicleLog> parseTelemetryLogListPayload(dynamic raw) {
    return _parsers.parseTelemetryLogListPayload(raw);
  }

  AppNotification? parseVehicleEventPayload(dynamic raw, {String? imei}) {
    return _parsers.parseVehicleEventPayload(raw, imei: imei);
  }

  List<String> resolveVehicleIdentityAliases(
    dynamic raw, {
    VehicleSummary? fallbackVehicle,
  }) {
    return _parsers.resolveVehicleIdentityAliases(
      raw,
      fallbackVehicle: fallbackVehicle,
    );
  }

  List<String> resolveVehicleIdentityAliasesForVehicle(VehicleSummary vehicle) {
    return _parsers.resolveVehicleIdentityAliasesForVehicle(vehicle);
  }

  // -------------------------------------------------------------------------
  // Map telemetry
  // -------------------------------------------------------------------------

  Future<LiveMapTelemetry> getMapTelemetry({String? refreshKey}) async {
    if (AppConfig.useMockData) {
      // Mock data lives inside SuperadminVehicleService; route through it
      // for parity with current Superadmin behavior.
      return _parsers.getMapTelemetry(refreshKey: refreshKey);
    }

    final response = await _apiClient.get<LiveMapTelemetry>(
      _config.mapTelemetryEndpoint,
      queryParameters: <String, dynamic>{
        'rk': refreshKey ?? DateTime.now().millisecondsSinceEpoch.toString(),
      },
      options: _readOptions,
      parser: _parsers.parseMapTelemetryPayload,
    );
    return response.data;
  }

  // -------------------------------------------------------------------------
  // Vehicle drilldown
  // -------------------------------------------------------------------------

  Future<LiveMapVehicleDetails> getVehicleDetailsByImei(String imei) async {
    final normalizedImei = imei.trim();
    if (normalizedImei.isEmpty) {
      return const SuperadminVehicleDetails.empty();
    }

    if (AppConfig.useMockData) {
      return _parsers.getVehicleDetailsByImei(normalizedImei);
    }

    final response = await _apiClient.get<LiveMapVehicleDetails>(
      _config.vehicleDetailsByImei(normalizedImei),
      options: _readOptions,
      parser: _parsers.parseVehicleDetailsPayload,
    );
    return response.data;
  }

  Future<LiveMapVehicleLogPage> getVehicleLogsByImei(
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
      return _parsers.getVehicleLogsByImei(
        normalizedImei,
        limit: normalizedLimit,
        beforeId: normalizedCursor.isEmpty ? null : normalizedCursor,
      );
    }

    final response = await _apiClient.get<LiveMapVehicleLogPage>(
      _config.vehicleLogsByImei(normalizedImei),
      queryParameters: <String, dynamic>{
        'limit': normalizedLimit,
        if (normalizedCursor.isNotEmpty) 'beforeId': normalizedCursor,
      },
      options: _readOptions,
      parser: _parsers.parseVehicleLogsPayload,
    );
    return response.data;
  }

  Future<LiveMapVehicleEventPage> getVehicleEventsByImei(
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
      return _parsers.getVehicleEventsByImei(
        normalizedImei,
        limit: normalizedLimit,
        beforeId: normalizedCursor.isEmpty ? null : normalizedCursor,
      );
    }

    final response = await _apiClient.get<LiveMapVehicleEventPage>(
      _config.vehicleEventsByImei(normalizedImei),
      queryParameters: <String, dynamic>{
        'limit': normalizedLimit,
        if (normalizedCursor.isNotEmpty) 'beforeId': normalizedCursor,
      },
      options: _readOptions,
      parser: (json) => _parsers.parseVehicleEventsPayload(
        json,
        imei: normalizedImei,
        requestedLimit: normalizedLimit,
      ),
    );
    return response.data;
  }

  Future<LiveMapVehicleSensorPage> getVehicleSensorsByImei(String imei) async {
    final normalizedImei = imei.trim();
    if (normalizedImei.isEmpty) {
      return const SuperadminVehicleSensorPage(
        items: <SuperadminVehicleSensor>[],
        totalCount: 0,
      );
    }

    if (AppConfig.useMockData) {
      return _parsers.getVehicleSensorsByImei(normalizedImei);
    }

    final response = await _apiClient.get<LiveMapVehicleSensorPage>(
      _config.vehicleSensorsByImei(normalizedImei),
      queryParameters: const <String, dynamic>{
        'includeTelemetryMeta': 'true',
      },
      options: _readOptions,
      parser: _parsers.parseVehicleSensorsPayload,
    );
    return response.data;
  }

  /// History fetch using the existing [LiveMapVehicleHistoryRequest] shape, so
  /// the shared [LiveMapVehicleHistoryController] can call this exactly the
  /// same way the legacy Superadmin history controller did.
  Future<LiveMapVehicleHistory> getVehicleHistory(
    LiveMapVehicleHistoryRequest request, {
    int maxPoints = 50000,
  }) async {
    return getVehicleHistoryByImei(
      imei: request.imei,
      from: request.from,
      to: request.to,
      stopMin: request.stopMinutes,
      maxPoints: maxPoints,
    );
  }

  Future<LiveMapVehicleHistory> getVehicleHistoryByImei({
    required String imei,
    required DateTime from,
    required DateTime to,
    int stopMin = 5,
    int maxPoints = 50000,
    int? overspeedKph,
  }) async {
    final normalizedImei = imei.trim();
    if (normalizedImei.isEmpty) {
      throw ArgumentError('Vehicle IMEI is required to load history.');
    }

    final normalizedFrom = from.isAfter(to) ? to : from;
    final normalizedTo = to.isBefore(from) ? from : to;
    final normalizedStopMin = stopMin < 1 ? 1 : stopMin;
    final normalizedMaxPoints = maxPoints < 1 ? 1 : maxPoints;

    final request = SuperadminVehicleHistoryRequest(
      vehicle: VehicleSummaryShim.forImei(normalizedImei),
      from: normalizedFrom,
      to: normalizedTo,
      stopMinutes: normalizedStopMin,
    );

    final response = await _apiClient.get<LiveMapVehicleHistory>(
      _config.vehicleHistoryByImei(normalizedImei),
      queryParameters: <String, dynamic>{
        'from': normalizedFrom.toUtc().toIso8601String(),
        'to': normalizedTo.toUtc().toIso8601String(),
        'stopMin': normalizedStopMin.toString(),
        'maxPoints': normalizedMaxPoints.toString(),
        if (overspeedKph != null) 'overspeedKph': overspeedKph.toString(),
      },
      options: heavyReadOptions(),
      parser: (json) => _parsers.parseVehicleHistoryPayload(json, request),
    );
    return response.data;
  }

  Future<LiveMapVehicleReplay> getVehicleReplayByImei({
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
      return _parsers.getVehicleReplayByImei(
        imei: normalizedImei,
        from: from,
        to: to,
        maxPoints: maxPoints,
      );
    }

    final response = await _apiClient.get<LiveMapVehicleReplay>(
      _config.vehicleReplayByImei(normalizedImei),
      queryParameters: <String, dynamic>{
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'maxPoints': maxPoints,
      },
      options: heavyReadOptions(),
      parser: _parsers.parseVehicleReplayPayload,
    );
    return response.data;
  }

  // -------------------------------------------------------------------------
  // Overlays — only when the role config opts in.
  // -------------------------------------------------------------------------

  Future<List<SuperadminMapGeofence>> getGeofences({String? refreshKey}) async {
    final endpoint = _config.geofencesEndpoint;
    if (!_config.supportsGeofence || endpoint == null) {
      throw StateError(
        'Geofences are not enabled for role ${_config.role.name}.',
      );
    }

    final response = await _apiClient.get<List<SuperadminMapGeofence>>(
      endpoint,
      queryParameters: <String, dynamic>{
        'rk': refreshKey ?? DateTime.now().millisecondsSinceEpoch.toString(),
      },
      options: _readOptions,
      parser: _overlayParsers.parseGeofencesPayload,
    );
    return response.data;
  }

  Future<List<SuperadminMapPoi>> getPois({String? refreshKey}) async {
    final endpoint = _config.poisEndpoint;
    if (!_config.supportsPoi || endpoint == null) {
      throw StateError(
        'POIs are not enabled for role ${_config.role.name}.',
      );
    }

    final response = await _apiClient.get<List<SuperadminMapPoi>>(
      endpoint,
      queryParameters: <String, dynamic>{
        'rk': refreshKey ?? DateTime.now().millisecondsSinceEpoch.toString(),
      },
      options: _readOptions,
      parser: _overlayParsers.parsePoisPayload,
    );
    return response.data;
  }

  Future<List<SuperadminMapRoute>> getRoutes({String? refreshKey}) async {
    final endpoint = _config.routesEndpoint;
    if (!_config.supportsRoute || endpoint == null) {
      throw StateError(
        'Routes are not enabled for role ${_config.role.name}.',
      );
    }

    final response = await _apiClient.get<List<SuperadminMapRoute>>(
      endpoint,
      queryParameters: <String, dynamic>{
        'includeGeodata': true,
        'rk': refreshKey ?? DateTime.now().millisecondsSinceEpoch.toString(),
      },
      options: _readOptions,
      parser: _overlayParsers.parseRoutesPayload,
    );
    return response.data;
  }

  // -------------------------------------------------------------------------
  // Commands
  // -------------------------------------------------------------------------

  Future<List<LiveMapCustomCommand>> getCustomCommands({
    int? deviceTypeId,
    bool activeOnly = true,
  }) async {
    final endpoint = _config.customCommandsEndpoint;
    if (endpoint == null) {
      throw StateError(
        'Custom commands are not enabled for role ${_config.role.name}.',
      );
    }

    if (AppConfig.useMockData) {
      return _parsers.getCustomCommands(
        deviceTypeId: deviceTypeId,
        activeOnly: activeOnly,
      );
    }

    final response = await _apiClient.get<List<LiveMapCustomCommand>>(
      endpoint,
      queryParameters: <String, dynamic>{
        'activeOnly': activeOnly,
        if (deviceTypeId != null) 'deviceTypeId': deviceTypeId.toString(),
      },
      options: _readOptions,
      parser: _parsers.parseCustomCommandsPayload,
    );
    return response.data;
  }

  Future<List<LiveMapSystemVariable>> getSystemVariables() async {
    final endpoint = _config.systemVariablesEndpoint;
    if (endpoint == null) {
      throw StateError(
        'System variables are not enabled for role ${_config.role.name}.',
      );
    }

    if (AppConfig.useMockData) {
      return _parsers.getSystemVariables();
    }

    final response = await _apiClient.get<List<LiveMapSystemVariable>>(
      endpoint,
      options: _readOptions,
      parser: _parsers.parseSystemVariablesPayload,
    );
    return response.data;
  }

  /// Superadmin/Admin command flow.
  Future<LiveMapSendCommandResult> sendCommandByImei({
    required String imei,
    required String command,
    String? note,
  }) async {
    if (_config.commandSendMode != LiveMapCommandSendMode.byImei) {
      throw StateError(
        'sendCommandByImei is not supported for role ${_config.role.name}; '
        'use sendBulkCommandForUserVehicles instead.',
      );
    }
    final builder = _config.sendCommandByImei;
    if (builder == null) {
      throw StateError(
        'sendCommandByImei endpoint missing for role ${_config.role.name}.',
      );
    }

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
      return _parsers.sendCommandByImei(
        imei: normalizedImei,
        command: normalizedCommand,
        note: note,
      );
    }

    final response = await _apiClient.post<LiveMapSendCommandResult>(
      builder(normalizedImei),
      data: <String, dynamic>{'command': normalizedCommand},
      options: _readOptions,
      parser: _parsers.parseSendCommandResponsePayload,
    );
    return response.data;
  }

  /// User bulk command flow — `POST /user/commands/send-bulk`.
  Future<LiveMapSendCommandResult> sendBulkCommandForUserVehicles({
    required List<String> vehicleIds,
    required String command,
  }) async {
    if (_config.commandSendMode != LiveMapCommandSendMode.bulkByVehicleId) {
      throw StateError(
        'sendBulkCommandForUserVehicles is not supported for role '
        '${_config.role.name}; use sendCommandByImei instead.',
      );
    }
    final endpoint = _config.userSendCommandBulkEndpoint;
    if (endpoint == null) {
      throw StateError(
        'Bulk send-command endpoint missing for role ${_config.role.name}.',
      );
    }

    final normalizedCommand = command.trim();
    final normalizedIds = vehicleIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (normalizedIds.isEmpty) {
      throw ArgumentError('At least one vehicleId is required.');
    }
    if (normalizedCommand.isEmpty) {
      throw ArgumentError('Command text is required.');
    }
    if (normalizedCommand.length > 500) {
      throw ArgumentError('Command text must be 500 characters or less.');
    }

    final response = await _apiClient.post<LiveMapSendCommandResult>(
      endpoint,
      data: <String, dynamic>{
        'vehicleIds': normalizedIds,
        'command': normalizedCommand,
      },
      options: _readOptions,
      parser: _parsers.parseSendCommandResponsePayload,
    );
    return response.data;
  }

  /// Per-IMEI command history (superadmin/admin).
  Future<LiveMapCommandHistoryPage> getCommandHistoryByImei({
    required String imei,
    int limit = 50,
    String? cursorId,
  }) async {
    final builder = _config.commandHistoryByImei;
    if (builder == null) {
      throw StateError(
        'commandHistoryByImei is not supported for role ${_config.role.name}; '
        'use getCommandHistoryByVehicleId instead.',
      );
    }

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
      return _parsers.getCommandHistoryByImei(
        imei: normalizedImei,
        limit: normalizedLimit,
        cursorId: normalizedCursor.isEmpty ? null : normalizedCursor,
      );
    }

    final response = await _apiClient.get<LiveMapCommandHistoryPage>(
      builder(normalizedImei),
      queryParameters: <String, dynamic>{
        'limit': normalizedLimit,
        if (normalizedCursor.isNotEmpty) 'cursorId': normalizedCursor,
      },
      options: _readOptions,
      parser: _parsers.parseVehicleCommandsPayload,
    );
    return response.data;
  }

  /// Per-vehicleId command history (user).
  Future<LiveMapCommandHistoryPage> getCommandHistoryByVehicleId({
    required String vehicleId,
    int limit = 50,
    String? cursorId,
  }) async {
    final builder = _config.userCommandHistoryByVehicleId;
    if (builder == null) {
      throw StateError(
        'commandHistoryByVehicleId is not supported for role '
        '${_config.role.name}; use getCommandHistoryByImei instead.',
      );
    }

    final normalizedId = vehicleId.trim();
    if (normalizedId.isEmpty) {
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

    final response = await _apiClient.get<LiveMapCommandHistoryPage>(
      builder(normalizedId),
      queryParameters: <String, dynamic>{
        'limit': normalizedLimit,
        if (normalizedCursor.isNotEmpty) 'cursorId': normalizedCursor,
      },
      options: _readOptions,
      parser: _parsers.parseVehicleCommandsPayload,
    );
    return response.data;
  }

  Future<LiveMapCommandStatus?> getCommandStatus(String cmdId) async {
    final builder = _config.commandStatusByCmdId;
    if (builder == null) {
      throw StateError(
        'commandStatus endpoint missing for role ${_config.role.name}.',
      );
    }

    final normalizedCmdId = cmdId.trim();
    if (normalizedCmdId.isEmpty) return null;

    if (AppConfig.useMockData) {
      return _parsers.getCommandStatus(normalizedCmdId);
    }

    final response = await _apiClient.get<LiveMapCommandStatus?>(
      builder(normalizedCmdId),
      options: _readOptions,
      parser: _parsers.parseCommandStatusPayload,
    );
    return response.data;
  }

  Future<LiveMapCommandHistoryItem?> getCommandLogByCmdId(String cmdId) async {
    final builder = _config.commandLogByCmdId;
    if (builder == null) {
      throw StateError(
        'commandLog endpoint missing for role ${_config.role.name}.',
      );
    }

    final normalizedCmdId = cmdId.trim();
    if (normalizedCmdId.isEmpty) return null;

    if (AppConfig.useMockData) {
      return _parsers.getCommandLogByCmdId(normalizedCmdId);
    }

    final response = await _apiClient.get<LiveMapCommandHistoryItem?>(
      builder(normalizedCmdId),
      options: _readOptions,
      parser: _parsers.parseCommandPayload,
    );
    return response.data;
  }

  /// Alias kept for parity with the legacy Superadmin service API.
  Future<LiveMapCommandHistoryItem?> getCommandDetail(String cmdId) {
    return getCommandLogByCmdId(cmdId);
  }
}

/// Internal helper — the Superadmin history parser needs a [VehicleSummary]
/// inside its request. The shared engine only knows the IMEI, so we build a
/// minimal placeholder used purely for downstream label fallback.
class VehicleSummaryShim {
  const VehicleSummaryShim._();

  static VehicleSummary forImei(String imei) {
    return VehicleSummary(
      id: imei,
      imei: imei,
      name: '',
      plateNumber: '',
      status: '',
      speed: 0,
      latitude: 0,
      longitude: 0,
      hasValidLocation: false,
    );
  }
}
