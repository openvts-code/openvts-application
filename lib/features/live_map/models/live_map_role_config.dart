import '../../../core/router/route_paths.dart';
import '../../../core/storage/storage_keys.dart';
import 'live_map_role.dart';
export 'live_map_role.dart';

/// Role-aware configuration consumed by the shared live map engine.
///
/// Every role (superadmin / admin / user) hits a different backend prefix.
/// To avoid duplicating the 13k-line live map screen per role, the shared
/// engine reads endpoints + feature flags from a [LiveMapRoleConfig] rather
/// than hard-coding `/superadmin/...` paths.
///
/// Endpoint builders that accept an `imei`, `cmdId`, or `vehicleId` always
/// run the argument through [Uri.encodeComponent] before interpolation, so
/// callers can safely pass raw values.
class LiveMapRoleConfig {
  const LiveMapRoleConfig({
    required this.role,
    required this.title,
    required this.homeRoute,
    required this.mapTelemetryEndpoint,
    required this.mapEventsEndpoint,
    required this.vehicleDetailsByImei,
    required this.vehicleLogsByImei,
    required this.vehicleEventsByImei,
    required this.vehicleHistoryByImei,
    required this.vehicleReplayByImei,
    required this.vehicleSensorsByImei,
    this.vehicleTrailByImei,
    this.geofencesEndpoint,
    this.poisEndpoint,
    this.routesEndpoint,
    this.customCommandsEndpoint,
    this.systemVariablesEndpoint,
    this.sendCommandByImei,
    this.commandHistoryByImei,
    this.commandStatusByCmdId,
    this.commandLogByCmdId,
    this.userSendCommandBulkEndpoint,
    this.userCommandHistoryByVehicleId,
    this.supportsGeofence = false,
    this.supportsPoi = false,
    this.supportsRoute = false,
    this.supportsCommands = false,
    this.commandSendMode = LiveMapCommandSendMode.disabled,
    required this.notificationSubscribeMode,
    required this.telemetrySubscribeMode,
    required this.visualSettingsStorageKey,
    required this.mapLayerStorageKey,
  });

  final LiveMapRole role;
  final String title;
  final String homeRoute;

  // --- Map streams ---------------------------------------------------------
  final String mapTelemetryEndpoint;
  final String mapEventsEndpoint;

  // --- Vehicle drilldown (by IMEI) ----------------------------------------
  final String Function(String imei) vehicleDetailsByImei;
  final String Function(String imei) vehicleLogsByImei;
  final String Function(String imei) vehicleEventsByImei;
  final String Function(String imei) vehicleHistoryByImei;
  final String Function(String imei) vehicleReplayByImei;
  final String Function(String imei) vehicleSensorsByImei;
  final String Function(String imei)? vehicleTrailByImei;

  // --- Overlays ------------------------------------------------------------
  final String? geofencesEndpoint;
  final String? poisEndpoint;
  final String? routesEndpoint;

  // --- Commands (by-IMEI flow: superadmin / admin) ------------------------
  final String? customCommandsEndpoint;
  final String? systemVariablesEndpoint;
  final String Function(String imei)? sendCommandByImei;
  final String Function(String imei)? commandHistoryByImei;
  final String Function(String cmdId)? commandStatusByCmdId;
  final String Function(String cmdId)? commandLogByCmdId;

  // --- Commands (bulk flow: user) -----------------------------------------
  final String? userSendCommandBulkEndpoint;
  final String Function(String vehicleId)? userCommandHistoryByVehicleId;

  // --- Feature flags -------------------------------------------------------
  final bool supportsGeofence;
  final bool supportsPoi;
  final bool supportsRoute;
  final bool supportsCommands;

  final LiveMapCommandSendMode commandSendMode;
  final LiveMapNotificationSubscribeMode notificationSubscribeMode;
  final LiveMapTelemetrySubscribeMode telemetrySubscribeMode;

  // --- Persistence keys ----------------------------------------------------
  final String visualSettingsStorageKey;
  final String mapLayerStorageKey;

  // ------------------------------------------------------------------------
  // Factory configs
  // ------------------------------------------------------------------------

  static String _e(String value) => Uri.encodeComponent(value);

  /// Endpoints for the SUPERADMIN live map.
  factory LiveMapRoleConfig.superadmin() {
    const base = '/superadmin';
    return LiveMapRoleConfig(
      role: LiveMapRole.superadmin,
      title: 'Live Map',
      homeRoute: RoutePaths.superadminHome,
      mapTelemetryEndpoint: '$base/map-telemetry',
      mapEventsEndpoint: '$base/map-events',
      vehicleDetailsByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}',
      vehicleLogsByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/logs',
      vehicleEventsByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/events',
      vehicleHistoryByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/history',
      vehicleReplayByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/replay',
      vehicleSensorsByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/sensors',
      vehicleTrailByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/trail',
      geofencesEndpoint: '$base/geofences',
      poisEndpoint: '$base/pois',
      routesEndpoint: '$base/routes',
      customCommandsEndpoint: '$base/customcommands',
      systemVariablesEndpoint: '$base/systemvariables',
      sendCommandByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/send-command',
      commandHistoryByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/commands',
      commandStatusByCmdId: (cmdId) =>
          '$base/commands/status/${_e(cmdId)}',
      commandLogByCmdId: (cmdId) => '$base/commands/${_e(cmdId)}',
      supportsGeofence: true,
      supportsPoi: true,
      supportsRoute: true,
      supportsCommands: true,
      commandSendMode: LiveMapCommandSendMode.byImei,
      notificationSubscribeMode:
          LiveMapNotificationSubscribeMode.superadminScope,
      telemetrySubscribeMode: LiveMapTelemetrySubscribeMode.none,
      visualSettingsStorageKey: StorageKeys.superadminMapVisualSettings,
      mapLayerStorageKey: StorageKeys.superadminMapLayerId,
    );
  }

  /// Endpoints for the ADMIN live map.
  ///
  /// Admins do NOT have geofence/POI/route overlays. Commands are issued
  /// per-IMEI, same as superadmin.
  factory LiveMapRoleConfig.admin() {
    const base = '/admin';
    return LiveMapRoleConfig(
      role: LiveMapRole.admin,
      title: 'Live Map',
      homeRoute: RoutePaths.adminHome,
      mapTelemetryEndpoint: '$base/map-telemetry',
      mapEventsEndpoint: '$base/map-events',
      vehicleDetailsByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}',
      vehicleLogsByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/logs',
      vehicleEventsByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/events',
      vehicleHistoryByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/history',
      vehicleReplayByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/replay',
      vehicleSensorsByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/sensors',
      vehicleTrailByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/trail',
      customCommandsEndpoint: '$base/customcommands',
      systemVariablesEndpoint: '$base/systemvariables',
      sendCommandByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/send-command',
      commandHistoryByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/commands',
      commandStatusByCmdId: (cmdId) =>
          '$base/commands/status/${_e(cmdId)}',
      commandLogByCmdId: (cmdId) => '$base/commands/${_e(cmdId)}',
      supportsGeofence: false,
      supportsPoi: false,
      supportsRoute: false,
      supportsCommands: true,
      commandSendMode: LiveMapCommandSendMode.byImei,
      notificationSubscribeMode: LiveMapNotificationSubscribeMode.imeis,
      telemetrySubscribeMode: LiveMapTelemetrySubscribeMode.imeis,
      visualSettingsStorageKey: StorageKeys.adminMapVisualSettings,
      mapLayerStorageKey: StorageKeys.adminMapLayerId,
    );
  }

  /// Endpoints for the USER live map.
  ///
  /// Users own geofence/POI/route overlays, but commands are sent in bulk
  /// via `/user/commands/send-bulk` (no by-IMEI POST), and command history
  /// is queried by `vehicleId` rather than IMEI.
  factory LiveMapRoleConfig.user() {
    const base = '/user';
    return LiveMapRoleConfig(
      role: LiveMapRole.user,
      title: 'Live Map',
      homeRoute: RoutePaths.userHome,
      mapTelemetryEndpoint: '$base/map-telemetry',
      mapEventsEndpoint: '$base/map-events',
      vehicleDetailsByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}',
      vehicleLogsByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/logs',
      vehicleEventsByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/events',
      vehicleHistoryByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/history',
      vehicleReplayByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/replay',
      vehicleSensorsByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/sensors',
      vehicleTrailByImei: (imei) =>
          '$base/vehicles/by-imei/${_e(imei)}/trail',
      geofencesEndpoint: '$base/geofences',
      poisEndpoint: '$base/pois',
      routesEndpoint: '$base/routes',
      customCommandsEndpoint: '$base/customcommands',
      systemVariablesEndpoint: '$base/systemvariables',
      userSendCommandBulkEndpoint: '$base/commands/send-bulk',
      commandStatusByCmdId: (cmdId) =>
          '$base/commands/status/${_e(cmdId)}',
      userCommandHistoryByVehicleId: (vehicleId) =>
          '$base/vehicles/${_e(vehicleId)}/commands',
      commandLogByCmdId: (cmdId) => '$base/commands/${_e(cmdId)}',
      supportsGeofence: true,
      supportsPoi: true,
      supportsRoute: true,
      supportsCommands: true,
      commandSendMode: LiveMapCommandSendMode.bulkByVehicleId,
      notificationSubscribeMode: LiveMapNotificationSubscribeMode.imeis,
      telemetrySubscribeMode: LiveMapTelemetrySubscribeMode.imeis,
      visualSettingsStorageKey: StorageKeys.userMapVisualSettings,
      mapLayerStorageKey: StorageKeys.userMapLayerId,
    );
  }

  /// Convenience: look up the config for a given role.
  factory LiveMapRoleConfig.forRole(LiveMapRole role) {
    switch (role) {
      case LiveMapRole.superadmin:
        return LiveMapRoleConfig.superadmin();
      case LiveMapRole.admin:
        return LiveMapRoleConfig.admin();
      case LiveMapRole.user:
        return LiveMapRoleConfig.user();
    }
  }
}
