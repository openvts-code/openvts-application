import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/socket/socket_service.dart';
import '../../../shared/models/vehicle_summary.dart';
import '../../notifications/models/app_notification.dart';
import '../models/superadmin_map_live_state.dart';
import '../services/superadmin_map_events_service.dart';
import '../services/superadmin_vehicle_service.dart';

class SuperadminMapLiveController
    extends StateNotifier<SuperadminMapLiveState> {
  SuperadminMapLiveController(
    this._vehicleService,
    this._mapEventsService,
    this._socketService,
  ) : super(const SuperadminMapLiveState.initial());

  static const String _superadminRole = 'superadmin';
  static const int _alertBootstrapLimit = 50;
  static const int _maxAlerts = 300;
  static const Duration _inactiveStatusThreshold = Duration(hours: 48);
  static const Duration _liveUpdateBatchWindow = Duration(milliseconds: 120);
  static const double _minCoordinateMoveMeters = 2;
  static const double _stationaryDriftSpeedKph = 5;
  static const double _stationaryDriftDistanceMeters = 25;
  static const double _maxPlausibleImpliedSpeedKph = 320;

  final SuperadminVehicleService _vehicleService;
  final SuperadminMapEventsService _mapEventsService;
  final SocketService _socketService;

  SocketConnection? _telemetryConnection;
  SocketConnection? _notificationsConnection;
  Map<String, VehicleSummary> _vehiclesByKey = <String, VehicleSummary>{};
  Map<String, String> _vehicleKeyByAlias = <String, String>{};
  final Map<String, dynamic> _pendingTelemetryUpdatesByAlias =
      <String, dynamic>{};
  final Map<String, dynamic> _pendingDeviceStatusUpdatesByAlias =
      <String, dynamic>{};
  Timer? _liveTelemetryPublishTimer;
  bool _hasPendingTelemetryPublish = false;
  bool _isBootstrappingTelemetry = false;
  bool _didSeedTelemetry = false;
  bool _hasTelemetryBaseline = false;

  void initialize() {
    unawaited(_initializeTelemetry());
    unawaited(_bootstrapAlerts());
    unawaited(_connectNotificationsSocket());
  }

  Future<void> _initializeTelemetry() async {
    final didLoadBaseline = await _bootstrapTelemetrySeed();
    if (!mounted || !didLoadBaseline) {
      return;
    }

    await _connectTelemetrySocket();
  }

  Future<bool> _bootstrapTelemetrySeed() async {
    if (_didSeedTelemetry) {
      return true;
    }

    if (_isBootstrappingTelemetry) {
      return false;
    }

    _isBootstrappingTelemetry = true;

    try {
      final telemetry = await _vehicleService.getMapTelemetry();
      if (!mounted) {
        return false;
      }

      _didSeedTelemetry = true;
      _hasTelemetryBaseline = true;
      _replaceBaselineVehicles(telemetry.vehicles);
      final didApplyPending = _applyPendingLiveUpdates();

      if (_vehiclesByKey.isNotEmpty || didApplyPending) {
        _publishMergedTelemetry();
      } else {
        _publishTelemetry(telemetry);
      }

      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isInitialLoading: false,
        errorMessage: _formatError(error),
      );
      return false;
    } finally {
      _isBootstrappingTelemetry = false;
    }
  }

  Future<void> _connectTelemetrySocket() async {
    if (_telemetryConnection != null) {
      return;
    }

    try {
      final connection = await _socketService.connect('/telemetry');
      if (!mounted) {
        connection.disconnect();
        return;
      }

      _telemetryConnection = connection;
      connection.onConnect(_handleTelemetryConnected);
      connection.onDisconnect(_handleTelemetryDisconnected);
      connection.onError(_handleTelemetrySocketError);
      connection.on('telemetry:snapshot', _handleTelemetrySnapshot);
      connection.on('telemetry:update', _handleTelemetryUpdate);
      connection.on('devicestatus:update', _handleDeviceStatusUpdate);
      connection.on('telemetry:error', _handleTelemetrySocketError);

      if (connection.isConnected) {
        _handleTelemetryConnected();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isTelemetryConnected: false,
        errorMessage: _formatError(error),
      );
    }
  }

  Future<void> _connectNotificationsSocket() async {
    try {
      final connection = await _socketService.connect('/notifications');
      if (!mounted) {
        connection.disconnect();
        return;
      }

      _notificationsConnection = connection;
      connection.onConnect(_handleNotificationsConnected);
      connection.onDisconnect(_handleNotificationsDisconnected);
      connection.onError(_handleNotificationsSocketError);
      connection.on('notif:new', _handleNotificationNew);
      connection.on('notif:error', _handleNotificationsSocketError);

      if (connection.isConnected) {
        _handleNotificationsConnected();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isNotificationsConnected: false,
        errorMessage: _formatError(error),
      );
    }
  }

  Future<void> _bootstrapAlerts() async {
    try {
      final page = await _mapEventsService.getMapEvents(
        limit: _alertBootstrapLimit,
      );
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        alerts: _mergeAlerts(
          current: state.alerts,
          incoming: page.items,
        ),
        isAlertsLoading: false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isAlertsLoading: false,
        errorMessage: _formatError(error),
      );
    }
  }

  void _handleTelemetryConnected() {
    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isTelemetryConnected: true,
      errorMessage: null,
    );
  }

  void _handleTelemetryDisconnected(dynamic _) {
    if (!mounted) {
      return;
    }

    state = state.copyWith(isTelemetryConnected: false);
  }

  void _handleTelemetrySocketError(dynamic error) {
    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isTelemetryConnected: false,
      errorMessage: _formatError(error),
    );
  }

  void _handleTelemetrySnapshot(dynamic data) {
    if (!_hasTelemetryBaseline) {
      return;
    }

    final telemetry = _vehicleService.parseMapTelemetryPayload(data);
    if (telemetry.vehicles.isEmpty) {
      return;
    }

    final didChange = _mergeVehicles(
      telemetry.vehicles,
      allowCreate: false,
    );
    if (didChange) {
      _scheduleMergedTelemetryPublish();
    }
  }

  void _handleTelemetryUpdate(dynamic data) {
    if (!_hasTelemetryBaseline) {
      _bufferPendingTelemetryUpdate(data);
      return;
    }

    if (_applyTelemetryUpdate(data)) {
      _scheduleMergedTelemetryPublish();
    }
  }

  void _handleDeviceStatusUpdate(dynamic data) {
    if (!_hasTelemetryBaseline) {
      _bufferPendingDeviceStatusUpdate(data);
      return;
    }

    if (_applyDeviceStatusUpdate(data)) {
      _scheduleMergedTelemetryPublish();
    }
  }

  bool _applyPendingLiveUpdates() {
    if (!_hasTelemetryBaseline) {
      return false;
    }

    var didChange = false;
    final pendingTelemetry =
        _pendingTelemetryUpdatesByAlias.values.toList(growable: false);
    _pendingTelemetryUpdatesByAlias.clear();
    for (final update in pendingTelemetry) {
      didChange = _applyTelemetryUpdate(update) || didChange;
    }

    final pendingDeviceStatuses =
        _pendingDeviceStatusUpdatesByAlias.values.toList(growable: false);
    _pendingDeviceStatusUpdatesByAlias.clear();
    for (final update in pendingDeviceStatuses) {
      didChange = _applyDeviceStatusUpdate(update) || didChange;
    }

    return didChange;
  }

  void _bufferPendingTelemetryUpdate(dynamic data) {
    final vehicle = _vehicleService.parseTelemetryVehiclePayload(
      data,
      requireCoordinates: false,
    );
    final aliases = _identityAliasesForPayload(
      data,
      fallbackVehicle: vehicle,
    );
    if (aliases.isEmpty) {
      return;
    }

    _pendingTelemetryUpdatesByAlias[aliases.first] = data;
  }

  void _bufferPendingDeviceStatusUpdate(dynamic data) {
    final aliases = _identityAliasesForPayload(data);
    if (aliases.isEmpty) {
      return;
    }

    _pendingDeviceStatusUpdatesByAlias[aliases.first] = data;
  }

  bool _applyTelemetryUpdate(dynamic data) {
    final vehicle = _vehicleService.parseTelemetryVehiclePayload(
      data,
      requireCoordinates: false,
    );
    if (vehicle == null) {
      return false;
    }

    final aliases = _identityAliasesForPayload(
      data,
      fallbackVehicle: vehicle,
    );
    if (aliases.isEmpty) {
      return false;
    }

    final updatedVehicles = Map<String, VehicleSummary>.from(_vehiclesByKey);
    final updatedAliases = Map<String, String>.from(_vehicleKeyByAlias);
    final didChange = _upsertVehicle(
      updatedVehicles,
      updatedAliases,
      vehicle,
      aliases: aliases,
      allowCreate: false,
    );
    if (!didChange) {
      return false;
    }

    _vehiclesByKey = updatedVehicles;
    _vehicleKeyByAlias = updatedAliases;
    return true;
  }

  bool _applyDeviceStatusUpdate(dynamic data) {
    final aliases = _identityAliasesForPayload(data);
    if (aliases.isEmpty) {
      return false;
    }

    final storageKey = _resolveStorageKey(
      _vehiclesByKey,
      _vehicleKeyByAlias,
      aliases: aliases,
      allowCreate: false,
    );
    if (storageKey == null) {
      return false;
    }

    final current = _vehiclesByKey[storageKey];
    if (current == null) {
      return false;
    }

    final source = _asMap(data);
    final connectionStatus = _firstString(source, const [
      'status',
      'deviceStatus',
      'device_status',
      'connectionStatus',
      'connection_status',
      'state',
    ]);
    final lastSeenAt = _firstDate(source, const [
      'lastSeenAt',
      'last_seen_at',
      'lastSeen',
      'last_seen',
    ]);
    final deviceStatusUpdatedAt = _firstDate(source, const [
      'updatedAt',
      'updated_at',
      'timestamp',
      'serverTime',
      'server_time',
    ]);
    final resolvedLastSeenAt = lastSeenAt ?? current.lastSeenAt;
    final updatedVehicle = current.copyWith(
      status: _deriveStatusForDeviceConnection(
        current,
        connectionStatus: connectionStatus,
        lastSeenAt: resolvedLastSeenAt,
        statusUpdatedAt: deviceStatusUpdatedAt,
      ),
      deviceConnectionStatus: connectionStatus,
      lastSeenAt: resolvedLastSeenAt,
    );

    _vehiclesByKey = Map<String, VehicleSummary>.from(_vehiclesByKey)
      ..[storageKey] = updatedVehicle;
    _vehicleKeyByAlias = Map<String, String>.from(_vehicleKeyByAlias);
    for (final alias in _identityAliasesForVehicle(updatedVehicle)) {
      _vehicleKeyByAlias[alias] = storageKey;
    }
    return true;
  }

  void _handleNotificationsConnected() {
    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isNotificationsConnected: true,
      errorMessage: null,
    );
    _notificationsConnection?.emit(
      'notif:subscribe',
      _socketSubscriptionPayload(),
    );
  }

  void _handleNotificationsDisconnected(dynamic _) {
    if (!mounted) {
      return;
    }

    state = state.copyWith(isNotificationsConnected: false);
  }

  void _handleNotificationsSocketError(dynamic error) {
    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isNotificationsConnected: false,
      errorMessage: _formatError(error),
    );
  }

  void _handleNotificationNew(dynamic payload) {
    if (!mounted) {
      return;
    }

    final notification = _mapEventsService.parseMapEventPayload(payload);
    if (notification == null) {
      return;
    }

    final alerts = _mergeAlerts(
      current: state.alerts,
      incoming: <AppNotification>[notification],
    );
    if (identical(alerts, state.alerts)) {
      return;
    }

    state = state.copyWith(
      alerts: alerts,
      isAlertsLoading: false,
    );
  }

  List<AppNotification> _mergeAlerts({
    required List<AppNotification> current,
    required Iterable<AppNotification> incoming,
  }) {
    final merged = <AppNotification>[];
    final seenKeys = <String>{};
    var didChange = false;

    void addNotification(AppNotification notification, {required bool isNew}) {
      final keys = _alertDedupeKeys(notification);
      if (keys.any(seenKeys.contains)) {
        return;
      }

      seenKeys.addAll(keys);
      merged.add(notification);
      if (isNew) {
        didChange = true;
      }
    }

    for (final notification in current) {
      addNotification(notification, isNew: false);
    }

    for (final notification in incoming) {
      addNotification(notification, isNew: true);
    }

    merged.sort(_compareAlertsNewestFirst);
    if (merged.length > _maxAlerts) {
      merged.removeRange(_maxAlerts, merged.length);
      didChange = true;
    }

    if (!didChange && merged.length == current.length) {
      return current;
    }

    return List<AppNotification>.unmodifiable(merged);
  }

  List<String> _alertDedupeKeys(AppNotification notification) {
    final keys = <String>[];
    final seen = <String>{};

    void add(String prefix, Object? value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) {
        return;
      }

      final key = '$prefix:${text.toLowerCase()}';
      if (seen.add(key)) {
        keys.add(key);
      }
    }

    if (notification.id > 0) {
      add('id', notification.id);
    }
    if (notification.eventId != null && notification.eventId! > 0) {
      add('event', notification.eventId);
    }
    if (notification.readId != null && notification.readId! > 0) {
      add('read', notification.readId);
    }
    if (notification.logId != null && notification.logId! > 0) {
      add('log', notification.logId);
    }
    add('dedupe', notification.dedupeKey);

    if (keys.isEmpty) {
      add(
        'fallback',
        [
          notification.title.trim(),
          notification.message.trim(),
          notification.createdAt?.toUtc().toIso8601String() ?? '',
          notification.contextLabel?.trim() ?? '',
        ].join('|'),
      );
    }

    return keys;
  }

  int _compareAlertsNewestFirst(
    AppNotification left,
    AppNotification right,
  ) {
    final leftCreatedAt = left.createdAt;
    final rightCreatedAt = right.createdAt;
    if (leftCreatedAt != null && rightCreatedAt != null) {
      final createdAtCompare = rightCreatedAt.compareTo(leftCreatedAt);
      if (createdAtCompare != 0) {
        return createdAtCompare;
      }
    } else if (leftCreatedAt != null) {
      return -1;
    } else if (rightCreatedAt != null) {
      return 1;
    }

    return right.id.compareTo(left.id);
  }

  void _replaceBaselineVehicles(Iterable<VehicleSummary> vehicles) {
    final updatedVehicles = <String, VehicleSummary>{};
    final updatedAliases = <String, String>{};
    for (final vehicle in vehicles) {
      _upsertVehicle(
        updatedVehicles,
        updatedAliases,
        vehicle,
        aliases: _identityAliasesForVehicle(vehicle),
        allowCreate: true,
      );
    }

    _vehiclesByKey = updatedVehicles;
    _vehicleKeyByAlias = updatedAliases;
  }

  bool _mergeVehicles(
    Iterable<VehicleSummary> vehicles, {
    required bool allowCreate,
  }) {
    var didChange = false;
    final updatedVehicles = Map<String, VehicleSummary>.from(_vehiclesByKey);
    final updatedAliases = Map<String, String>.from(_vehicleKeyByAlias);
    for (final vehicle in vehicles) {
      didChange = _upsertVehicle(
            updatedVehicles,
            updatedAliases,
            vehicle,
            aliases: _identityAliasesForVehicle(vehicle),
            allowCreate: allowCreate,
          ) ||
          didChange;
    }

    _vehiclesByKey = updatedVehicles;
    _vehicleKeyByAlias = updatedAliases;
    return didChange;
  }

  bool _upsertVehicle(
    Map<String, VehicleSummary> vehiclesByKey,
    Map<String, String> vehicleKeyByAlias,
    VehicleSummary vehicle, {
    required List<String> aliases,
    required bool allowCreate,
  }) {
    final stableAliases = _normalizeStableIdentityAliases(aliases);
    final storageKey = _resolveStorageKey(
      vehiclesByKey,
      vehicleKeyByAlias,
      aliases: stableAliases,
      allowCreate: allowCreate,
    );
    if (storageKey == null || storageKey.isEmpty) {
      return false;
    }

    final current = vehiclesByKey[storageKey];
    final mergedVehicle =
        current == null ? vehicle : _mergeVehicle(current, vehicle);

    if (current != null && _isSameVehicleSnapshot(current, mergedVehicle)) {
      for (final alias in stableAliases) {
        vehicleKeyByAlias[alias] = storageKey;
      }
      return false;
    }

    vehiclesByKey[storageKey] = mergedVehicle;

    for (final alias in stableAliases) {
      vehicleKeyByAlias[alias] = storageKey;
    }

    for (final alias in _identityAliasesForVehicle(mergedVehicle)) {
      vehicleKeyByAlias[alias] = storageKey;
    }

    return true;
  }

  String? _resolveStorageKey(
    Map<String, VehicleSummary> vehiclesByKey,
    Map<String, String> vehicleKeyByAlias, {
    required List<String> aliases,
    required bool allowCreate,
  }) {
    final stableAliases = _normalizeStableIdentityAliases(aliases);
    for (final alias in stableAliases) {
      final existingKey = vehicleKeyByAlias[alias];
      if (existingKey != null && vehiclesByKey.containsKey(existingKey)) {
        return existingKey;
      }
    }

    for (final entry in vehiclesByKey.entries) {
      final currentAliases = _identityAliasesForVehicle(entry.value);
      if (_sharesIdentityAlias(currentAliases, stableAliases)) {
        return entry.key;
      }
    }

    if (!allowCreate || stableAliases.isEmpty) {
      return null;
    }

    return stableAliases.first;
  }

  bool _sharesIdentityAlias(
    List<String> leftAliases,
    List<String> rightAliases,
  ) {
    if (leftAliases.isEmpty || rightAliases.isEmpty) {
      return false;
    }

    final rightAliasSet = rightAliases.toSet();
    for (final alias in leftAliases) {
      if (rightAliasSet.contains(alias)) {
        return true;
      }
    }

    return false;
  }

  VehicleSummary _mergeVehicle(
    VehicleSummary current,
    VehicleSummary incoming,
  ) {
    final useIncomingLocation = _shouldUseIncomingLocation(current, incoming);
    final resolvedUpdatedAt = _resolveMonotonicUpdatedAt(
      current: current,
      incoming: incoming,
      useIncomingLocation: useIncomingLocation,
    );
    return current.copyWith(
      id: incoming.id.isNotEmpty ? incoming.id : current.id,
      imei: incoming.imei.isNotEmpty ? incoming.imei : current.imei,
      name: incoming.name.trim().isEmpty ? current.name : incoming.name,
      plateNumber: incoming.plateNumber.isNotEmpty
          ? incoming.plateNumber
          : current.plateNumber,
      status: incoming.status == 'unknown' ? current.status : incoming.status,
      speed: incoming.speed,
      latitude: useIncomingLocation ? incoming.latitude : current.latitude,
      longitude: useIncomingLocation ? incoming.longitude : current.longitude,
      hasValidLocation: useIncomingLocation
          ? incoming.hasValidLocation
          : current.hasValidLocation,
      updatedAt: resolvedUpdatedAt,
      distanceKm: incoming.distanceKm ?? current.distanceKm,
      odometerKm: incoming.odometerKm ?? current.odometerKm,
      engineHoursToday: incoming.engineHoursToday ?? current.engineHoursToday,
      engineHours: incoming.engineHours ?? current.engineHours,
      totalEngineHours: incoming.totalEngineHours ?? current.totalEngineHours,
      satellites: incoming.satellites ?? current.satellites,
      headingDegrees: incoming.headingDegrees ?? current.headingDegrees,
      ignition: incoming.ignition ?? current.ignition,
      acc: incoming.acc ?? current.acc,
      deviceConnectionStatus:
          incoming.deviceConnectionStatus ?? current.deviceConnectionStatus,
      lastSeenAt: incoming.lastSeenAt ?? current.lastSeenAt,
    );
  }

  bool _shouldUseIncomingLocation(
    VehicleSummary current,
    VehicleSummary incoming,
  ) {
    if (!incoming.hasValidLocation) {
      return false;
    }

    if (!current.hasValidLocation) {
      return true;
    }

    final distanceMeters = _coordinateDistanceMeters(
      fromLatitude: current.latitude,
      fromLongitude: current.longitude,
      toLatitude: incoming.latitude,
      toLongitude: incoming.longitude,
    );

    if (distanceMeters < _minCoordinateMoveMeters) {
      return false;
    }

    if (incoming.speed < _stationaryDriftSpeedKph &&
        distanceMeters < _stationaryDriftDistanceMeters) {
      return false;
    }

    final currentTime = current.updatedAt ?? current.lastSeenAt;
    final incomingTime = incoming.updatedAt ?? incoming.lastSeenAt;
    if (currentTime != null && incomingTime != null) {
      if (incomingTime.isBefore(currentTime)) {
        return false;
      }

      final elapsedSeconds = incomingTime.difference(currentTime).inSeconds;
      if (elapsedSeconds >= 2) {
        final impliedSpeedKph = (distanceMeters / elapsedSeconds) * 3.6;
        if (impliedSpeedKph > _maxPlausibleImpliedSpeedKph) {
          return false;
        }
      }
    }

    return true;
  }

  DateTime? _resolveMonotonicUpdatedAt({
    required VehicleSummary current,
    required VehicleSummary incoming,
    required bool useIncomingLocation,
  }) {
    final currentTime = current.updatedAt ?? current.lastSeenAt;
    final incomingTime = incoming.updatedAt ?? incoming.lastSeenAt;

    if (!useIncomingLocation) {
      return incoming.updatedAt ?? current.updatedAt;
    }

    if (currentTime == null) {
      return incomingTime ?? DateTime.now().toUtc();
    }

    if (incomingTime == null || !incomingTime.isAfter(currentTime)) {
      return currentTime.add(const Duration(milliseconds: 250));
    }

    return incomingTime;
  }

  bool _isSameVehicleSnapshot(
    VehicleSummary left,
    VehicleSummary right,
  ) {
    return left.id == right.id &&
        left.imei == right.imei &&
        left.name == right.name &&
        left.plateNumber == right.plateNumber &&
        left.status == right.status &&
        left.speed == right.speed &&
        left.latitude == right.latitude &&
        left.longitude == right.longitude &&
        left.hasValidLocation == right.hasValidLocation &&
        left.updatedAt == right.updatedAt &&
        left.distanceKm == right.distanceKm &&
        left.odometerKm == right.odometerKm &&
        left.engineHoursToday == right.engineHoursToday &&
        left.engineHours == right.engineHours &&
        left.totalEngineHours == right.totalEngineHours &&
        left.satellites == right.satellites &&
        left.headingDegrees == right.headingDegrees &&
        left.ignition == right.ignition &&
        left.acc == right.acc &&
        left.deviceConnectionStatus == right.deviceConnectionStatus &&
        left.lastSeenAt == right.lastSeenAt;
  }

  List<String> _identityAliasesForPayload(
    dynamic raw, {
    VehicleSummary? fallbackVehicle,
  }) {
    return _normalizeStableIdentityAliases(
      _vehicleService.resolveVehicleIdentityAliases(
        raw,
        fallbackVehicle: fallbackVehicle,
      ),
    );
  }

  List<String> _identityAliasesForVehicle(VehicleSummary vehicle) {
    return _normalizeStableIdentityAliases(
      _vehicleService.resolveVehicleIdentityAliasesForVehicle(vehicle),
    );
  }

  List<String> _normalizeStableIdentityAliases(List<String> aliases) {
    final imeiAliases = <String>[];
    final idAliases = <String>[];
    final seen = <String>{};

    void addAlias(List<String> target, String prefix, String value) {
      final normalizedValue = value.trim().toLowerCase();
      if (normalizedValue.isEmpty) {
        return;
      }

      final alias = '$prefix:$normalizedValue';
      if (seen.add(alias)) {
        target.add(alias);
      }
    }

    for (final alias in aliases) {
      final separatorIndex = alias.indexOf(':');
      if (separatorIndex <= 0 || separatorIndex == alias.length - 1) {
        continue;
      }

      final prefix = alias.substring(0, separatorIndex).trim().toLowerCase();
      final value = alias.substring(separatorIndex + 1);
      if (prefix == 'imei') {
        addAlias(imeiAliases, prefix, value);
      } else if (prefix == 'id') {
        addAlias(idAliases, prefix, value);
      }
    }

    return <String>[...imeiAliases, ...idAliases];
  }

  String _deriveStatusForDeviceConnection(
    VehicleSummary vehicle, {
    required String? connectionStatus,
    required DateTime? lastSeenAt,
    required DateTime? statusUpdatedAt,
  }) {
    final normalized = connectionStatus?.trim().toUpperCase() ?? '';
    if (normalized == 'CONNECTED' || normalized == 'ONLINE') {
      if (vehicle.speed > 0) {
        return 'running';
      }

      if (vehicle.ignition == true || vehicle.acc == true) {
        return 'idle';
      }

      return 'stop';
    }

    if (normalized == 'DISCONNECTED' || normalized == 'OFFLINE') {
      final referenceTime = lastSeenAt ?? statusUpdatedAt ?? vehicle.updatedAt;
      if (referenceTime == null) {
        return 'no_data';
      }

      final age = DateTime.now().toUtc().difference(referenceTime.toUtc());
      if (age >= _inactiveStatusThreshold) {
        return 'inactive';
      }

      return 'stop';
    }

    return vehicle.status;
  }

  void _publishMergedTelemetry() {
    final telemetry = _vehicleService.buildTelemetryFromVehicles(
      _vehiclesByKey.values.toList(growable: false),
    );
    _publishTelemetry(telemetry);
  }

  void _scheduleMergedTelemetryPublish() {
    if (!mounted) {
      return;
    }

    _hasPendingTelemetryPublish = true;
    if (_liveTelemetryPublishTimer?.isActive ?? false) {
      return;
    }

    _liveTelemetryPublishTimer = Timer(
      _liveUpdateBatchWindow,
      _flushPendingTelemetryPublish,
    );
  }

  void _flushPendingTelemetryPublish() {
    _liveTelemetryPublishTimer = null;
    if (!mounted || !_hasPendingTelemetryPublish) {
      return;
    }

    _hasPendingTelemetryPublish = false;
    _publishMergedTelemetry();
  }

  void _publishTelemetry(SuperadminMapTelemetry telemetry) {
    if (!mounted) {
      return;
    }

    state = state.copyWith(
      telemetry: telemetry,
      isInitialLoading: false,
      errorMessage: null,
    );
  }

  Map<String, dynamic> _socketSubscriptionPayload() {
    return const <String, dynamic>{
      'scope': _superadminRole,
    };
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

  DateTime? _firstDate(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final parsed = _asDateTime(source[key]);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  DateTime? _asDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is num) {
      return _dateFromEpoch(value);
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
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

    return null;
  }

  DateTime _dateFromEpoch(num value) {
    final raw = value.toInt();
    final milliseconds = raw.abs() < 100000000000 ? raw * 1000 : raw;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }

  double _coordinateDistanceMeters({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    const earthRadiusMeters = 6371000.0;
    final deltaLatitude = _degreesToRadians(toLatitude - fromLatitude);
    final deltaLongitude = _degreesToRadians(toLongitude - fromLongitude);
    final startLatitudeRadians = _degreesToRadians(fromLatitude);
    final endLatitudeRadians = _degreesToRadians(toLatitude);
    final haversine = math.pow(math.sin(deltaLatitude / 2), 2) +
        math.cos(startLatitudeRadians) *
            math.cos(endLatitudeRadians) *
            math.pow(math.sin(deltaLongitude / 2), 2);
    final arc = 2 *
        math.atan2(
          math.sqrt(haversine.toDouble()),
          math.sqrt(1 - haversine.toDouble()),
        );
    return earthRadiusMeters * arc;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  String _formatError(Object? error) {
    final message = error?.toString().trim() ?? '';
    if (message.isEmpty) {
      return 'Unable to load live map data right now.';
    }

    return message;
  }

  @override
  void dispose() {
    _liveTelemetryPublishTimer?.cancel();
    _telemetryConnection?.disconnect();
    _notificationsConnection?.disconnect();
    super.dispose();
  }
}
