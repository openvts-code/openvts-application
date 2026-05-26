import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/api/api_client.dart';
import 'package:open_vts/core/socket/socket_service.dart';
import 'package:open_vts/core/storage/token_storage.dart';
import 'package:open_vts/features/notifications/models/app_notification.dart';
import 'package:open_vts/features/notifications/models/notification_page.dart';
import 'package:open_vts/features/superadmin/controllers/superadmin_map_live_controller.dart';
import 'package:open_vts/features/superadmin/services/superadmin_map_events_service.dart';
import 'package:open_vts/features/superadmin/services/superadmin_vehicle_service.dart';
import 'package:open_vts/shared/models/vehicle_summary.dart';

void main() {
  group('SuperadminMapLiveController', () {
    test('loads REST baseline and skips telemetry snapshot subscription',
        () async {
      final telemetryConnection = _FakeSocketConnection();
      final notificationsConnection = _FakeSocketConnection();
      final vehicleService = _FakeVehicleService(
        fallbackTelemetry: _buildTelemetry([
          _vehicle(id: 'veh-1', imei: 'imei-1', name: 'Car 1', speed: 0),
          _vehicle(
            id: 'veh-2',
            imei: 'imei-2',
            name: 'Car 2',
            speed: 24,
            status: 'running',
          ),
        ]),
      );
      final controller = SuperadminMapLiveController(
        vehicleService,
        _FakeMapEventsService(
          notifications: <AppNotification>[
            _notification(id: 1, title: 'Initial alert'),
          ],
        ),
        _FakeSocketService(
          telemetryConnection: telemetryConnection,
          notificationsConnection: notificationsConnection,
        ),
      );
      addTearDown(controller.dispose);

      controller.initialize();
      await _flushAsync();
      telemetryConnection.triggerConnect();
      notificationsConnection.triggerConnect();
      await _flushAsync();

      expect(vehicleService.getMapTelemetryCalls, 1);
      expect(
        telemetryConnection.emittedEvents.map((event) => event.name),
        isNot(contains('telemetry:subscribe')),
      );
      expect(
        notificationsConnection.emittedEvents.map((event) => event.name),
        contains('notif:subscribe'),
      );
      expect(
        notificationsConnection.emittedEvents
            .firstWhere((event) => event.name == 'notif:subscribe')
            .data,
        const <String, dynamic>{'scope': 'superadmin'},
      );
      expect(controller.state.alerts, hasLength(1));
      expect(controller.state.telemetry.allCount, 2);
      expect(controller.state.telemetry.runningCount, 1);
      expect(controller.state.telemetry.stopCount, 1);
    });

    test('inserts notif:new alerts immediately newest first', () async {
      final notificationsConnection = _FakeSocketConnection();
      final controller = SuperadminMapLiveController(
        _FakeVehicleService(fallbackTelemetry: _buildTelemetry(const [])),
        _FakeMapEventsService(
          notifications: <AppNotification>[
            _notification(
              id: 1,
              title: 'Initial alert',
              createdAt: DateTime.utc(2026, 5, 16, 10),
            ),
          ],
        ),
        _FakeSocketService(
          telemetryConnection: _FakeSocketConnection(),
          notificationsConnection: notificationsConnection,
        ),
      );
      addTearDown(controller.dispose);

      controller.initialize();
      await _flushAsync();
      notificationsConnection.triggerConnect();
      notificationsConnection.triggerEvent('notif:new', <String, dynamic>{
        'id': 2,
        'title': 'Live alert',
        'message': 'Vehicle entered a geofence.',
        'severity': 'WARNING',
        'vehicleName': 'TRK-204',
        'createdAt': '2026-05-16T10:05:00.000Z',
      });
      await _flushAsync();

      expect(controller.state.alerts.map((alert) => alert.title), [
        'Live alert',
        'Initial alert',
      ]);
      expect(controller.state.alerts.first.contextLabel, 'TRK-204');
    });

    test('deduplicates REST and socket alerts by parsed event identity',
        () async {
      final notificationsConnection = _FakeSocketConnection();
      final controller = SuperadminMapLiveController(
        _FakeVehicleService(fallbackTelemetry: _buildTelemetry(const [])),
        _FakeMapEventsService(
          notifications: <AppNotification>[
            _notification(
              id: 9001,
              eventId: 77,
              title: 'Overspeed',
              message: 'Vehicle crossed the speed threshold.',
              createdAt: DateTime.utc(2026, 5, 16, 10),
            ),
          ],
        ),
        _FakeSocketService(
          telemetryConnection: _FakeSocketConnection(),
          notificationsConnection: notificationsConnection,
        ),
      );
      addTearDown(controller.dispose);

      controller.initialize();
      await _flushAsync();
      notificationsConnection.triggerConnect();
      notificationsConnection.triggerEvent('notif:new', <String, dynamic>{
        'id': 12345,
        'eventId': 77,
        'title': 'Overspeed',
        'message': 'Vehicle crossed the speed threshold.',
        'severity': 'CRITICAL',
        'createdAt': '2026-05-16T10:00:00.000Z',
      });
      notificationsConnection.triggerEvent('notif:new', <String, dynamic>{
        'title': 'Notification',
        'message': 'OpenVTS sent a new update.',
      });
      await _flushAsync();

      expect(controller.state.alerts, hasLength(1));
      expect(controller.state.alerts.single.id, 9001);
      expect(controller.state.alerts.single.eventId, 77);
    });

    test('caps live alerts at 300 and keeps them newest first', () async {
      final notificationsConnection = _FakeSocketConnection();
      final controller = SuperadminMapLiveController(
        _FakeVehicleService(fallbackTelemetry: _buildTelemetry(const [])),
        _FakeMapEventsService(notifications: const <AppNotification>[]),
        _FakeSocketService(
          telemetryConnection: _FakeSocketConnection(),
          notificationsConnection: notificationsConnection,
        ),
      );
      addTearDown(controller.dispose);

      controller.initialize();
      await _flushAsync();
      notificationsConnection.triggerConnect();
      for (var index = 0; index < 305; index += 1) {
        notificationsConnection.triggerEvent('notif:new', <String, dynamic>{
          'id': index + 1,
          'title': 'Alert ${index + 1}',
          'message': 'Message ${index + 1}',
          'severity': 'INFO',
          'createdAt': DateTime.utc(2026, 5, 16, 10, index).toIso8601String(),
        });
      }
      await _flushAsync();

      expect(controller.state.alerts, hasLength(300));
      expect(controller.state.alerts.first.title, 'Alert 305');
      expect(controller.state.alerts.last.title, 'Alert 6');
    });

    test('applies telemetry updates to existing vehicles by IMEI', () async {
      final telemetryConnection = _FakeSocketConnection();
      final controller = SuperadminMapLiveController(
        _FakeVehicleService(
          fallbackTelemetry: _buildTelemetry([
            _vehicle(id: 'veh-1', imei: 'imei-1', name: 'Car 1', speed: 0),
          ]),
        ),
        _FakeMapEventsService(notifications: const <AppNotification>[]),
        _FakeSocketService(
          telemetryConnection: telemetryConnection,
          notificationsConnection: _FakeSocketConnection(),
        ),
      );
      addTearDown(controller.dispose);

      controller.initialize();
      await _flushAsync();
      telemetryConnection.triggerConnect();
      telemetryConnection.triggerEvent(
        'telemetry:update',
        _vehiclePayload(
          imei: 'imei-1',
          speed: 32,
          status: 'running',
          latitude: 10.5,
          longitude: 20.5,
          course: 180,
          ignition: true,
          distanceKm: 7.25,
          odometerKm: 1026.6,
          engineHoursToday: 1.5,
          totalEngineHours: 900.5,
          satellites: 9,
        ),
      );
      telemetryConnection.triggerEvent(
        'telemetry:update',
        _vehiclePayload(
          imei: 'socket-only-imei',
          speed: 44,
          status: 'running',
          latitude: 11,
          longitude: 21,
        ),
      );
      await _flushLiveBatch();

      expect(controller.state.telemetry.allCount, 1);
      expect(controller.state.telemetry.runningCount, 1);
      expect(controller.state.telemetry.vehicles, hasLength(1));
      expect(controller.state.telemetry.vehicles.single.id, 'veh-1');
      expect(controller.state.telemetry.vehicles.single.speed, 32);
      expect(controller.state.telemetry.vehicles.single.latitude, 10.5);
      expect(controller.state.telemetry.vehicles.single.longitude, 20.5);
      expect(controller.state.telemetry.vehicles.single.headingDegrees, 180);
      expect(controller.state.telemetry.vehicles.single.ignition, isTrue);
      expect(controller.state.telemetry.vehicles.single.distanceKm, 7.25);
      expect(controller.state.telemetry.vehicles.single.odometerKm, 1026.6);
      expect(controller.state.telemetry.vehicles.single.engineHoursToday, 1.5);
      expect(
        controller.state.telemetry.vehicles.single.totalEngineHours,
        900.5,
      );
      expect(controller.state.telemetry.vehicles.single.satellites, 9);
    });

    test('batches rapid telemetry updates into one state publish', () async {
      final telemetryConnection = _FakeSocketConnection();
      final controller = SuperadminMapLiveController(
        _FakeVehicleService(
          fallbackTelemetry: _buildTelemetry([
            _vehicle(id: 'veh-1', imei: 'imei-1', name: 'Car 1', speed: 0),
            _vehicle(id: 'veh-2', imei: 'imei-2', name: 'Car 2', speed: 0),
          ]),
        ),
        _FakeMapEventsService(notifications: const <AppNotification>[]),
        _FakeSocketService(
          telemetryConnection: telemetryConnection,
          notificationsConnection: _FakeSocketConnection(),
        ),
      );
      addTearDown(controller.dispose);

      controller.initialize();
      await _flushAsync();
      telemetryConnection.triggerConnect();
      await _flushAsync();

      var statePublishes = 0;
      final removeListener = controller.addListener(
        (_) {
          statePublishes += 1;
        },
        fireImmediately: false,
      );
      addTearDown(removeListener);

      telemetryConnection.triggerEvent(
        'telemetry:update',
        _vehiclePayload(
          imei: 'imei-1',
          speed: 24,
          status: 'running',
          latitude: 10.001,
          longitude: 20.001,
        ),
      );
      telemetryConnection.triggerEvent(
        'telemetry:update',
        _vehiclePayload(
          imei: 'imei-2',
          speed: 18,
          status: 'running',
          latitude: 10.002,
          longitude: 20.002,
        ),
      );

      await _flushAsync();
      expect(statePublishes, 0);

      await _flushLiveBatch();

      expect(statePublishes, 1);
      expect(
        controller.state.telemetry.vehicles
            .firstWhere((vehicle) => vehicle.imei == 'imei-1')
            .speed,
        24,
      );
      expect(
        controller.state.telemetry.vehicles
            .firstWhere((vehicle) => vehicle.imei == 'imei-2')
            .speed,
        18,
      );
    });

    test('ignores GPS jitter drift and impossible coordinate jumps', () async {
      final telemetryConnection = _FakeSocketConnection();
      final baselineTime = DateTime.utc(2026, 5, 16, 10);
      final controller = SuperadminMapLiveController(
        _FakeVehicleService(
          fallbackTelemetry: _buildTelemetry([
            _vehicle(
              id: 'veh-1',
              imei: 'imei-1',
              name: 'Car 1',
              speed: 0,
              latitude: 10,
              longitude: 20,
              updatedAt: baselineTime,
            ),
          ]),
        ),
        _FakeMapEventsService(notifications: const <AppNotification>[]),
        _FakeSocketService(
          telemetryConnection: telemetryConnection,
          notificationsConnection: _FakeSocketConnection(),
        ),
      );
      addTearDown(controller.dispose);

      controller.initialize();
      await _flushAsync();
      telemetryConnection.triggerConnect();

      telemetryConnection.triggerEvent(
        'telemetry:update',
        _vehiclePayload(
          imei: 'imei-1',
          speed: 1,
          status: 'stop',
          latitude: 10.0001,
          longitude: 20,
          updatedAt: baselineTime.add(const Duration(seconds: 10)),
        ),
      );
      await _flushLiveBatch();

      expect(controller.state.telemetry.vehicles.single.speed, 1);
      expect(controller.state.telemetry.vehicles.single.latitude, 10);
      expect(controller.state.telemetry.vehicles.single.longitude, 20);

      telemetryConnection.triggerEvent(
        'telemetry:update',
        _vehiclePayload(
          imei: 'imei-1',
          speed: 80,
          status: 'running',
          latitude: 12,
          longitude: 22,
          updatedAt: baselineTime.add(const Duration(seconds: 20)),
        ),
      );
      await _flushLiveBatch();

      expect(controller.state.telemetry.vehicles.single.speed, 80);
      expect(controller.state.telemetry.vehicles.single.latitude, 10);
      expect(controller.state.telemetry.vehicles.single.longitude, 20);
    });

    test('patches existing vehicles from snapshots without creating baseline',
        () async {
      final telemetryConnection = _FakeSocketConnection();
      final controller = SuperadminMapLiveController(
        _FakeVehicleService(
          fallbackTelemetry: _buildTelemetry([
            _vehicle(id: 'veh-1', imei: 'imei-1', name: 'Car 1', speed: 0),
            _vehicle(id: 'veh-2', imei: 'imei-2', name: 'Car 2', speed: 0),
          ]),
        ),
        _FakeMapEventsService(notifications: const <AppNotification>[]),
        _FakeSocketService(
          telemetryConnection: telemetryConnection,
          notificationsConnection: _FakeSocketConnection(),
        ),
      );
      addTearDown(controller.dispose);

      controller.initialize();
      await _flushAsync();
      telemetryConnection.triggerConnect();
      telemetryConnection.triggerEvent('telemetry:snapshot', <String, dynamic>{
        'vehicles': <Map<String, dynamic>>[
          _vehiclePayload(
            imei: 'socket-only-imei',
            speed: 22,
            status: 'running',
            latitude: 11,
            longitude: 21,
          ),
          _vehiclePayload(
            imei: 'imei-2',
            speed: 35,
            status: 'running',
            latitude: 12,
            longitude: 22,
          ),
        ],
      });
      await _flushLiveBatch();

      expect(controller.state.telemetry.allCount, 2);
      expect(controller.state.telemetry.vehicles, hasLength(2));
      expect(
        controller.state.telemetry.vehicles
            .firstWhere((vehicle) => vehicle.imei == 'imei-2')
            .speed,
        35,
      );
      expect(
        controller.state.telemetry.vehicles
            .any((vehicle) => vehicle.imei == 'socket-only-imei'),
        isFalse,
      );
    });

    test('never expands a 10 vehicle REST baseline from socket-only updates',
        () async {
      final telemetryConnection = _FakeSocketConnection();
      final baselineVehicles = List<VehicleSummary>.generate(
        10,
        (index) => _vehicle(
          id: 'veh-$index',
          imei: 'imei-$index',
          name: 'Vehicle $index',
          speed: 0,
        ),
      );
      final controller = SuperadminMapLiveController(
        _FakeVehicleService(
            fallbackTelemetry: _buildTelemetry(baselineVehicles)),
        _FakeMapEventsService(notifications: const <AppNotification>[]),
        _FakeSocketService(
          telemetryConnection: telemetryConnection,
          notificationsConnection: _FakeSocketConnection(),
        ),
      );
      addTearDown(controller.dispose);

      controller.initialize();
      await _flushAsync();
      telemetryConnection.triggerConnect();
      for (var index = 0; index < 6; index += 1) {
        telemetryConnection.triggerEvent(
          'telemetry:update',
          _vehiclePayload(
            imei: 'socket-only-$index',
            speed: 40,
            status: 'running',
            latitude: 20 + index.toDouble(),
            longitude: 70 + index.toDouble(),
          ),
        );
      }
      await _flushLiveBatch();

      expect(controller.state.telemetry.allCount, 10);
      expect(controller.state.telemetry.vehicles, hasLength(10));
    });

    test('updates known vehicles from device status events only', () async {
      final telemetryConnection = _FakeSocketConnection();
      final controller = SuperadminMapLiveController(
        _FakeVehicleService(
          fallbackTelemetry: _buildTelemetry([
            _vehicle(
              id: 'veh-1',
              imei: 'imei-1',
              name: 'Car 1',
              speed: 0,
              ignition: true,
            ),
          ]),
        ),
        _FakeMapEventsService(notifications: const <AppNotification>[]),
        _FakeSocketService(
          telemetryConnection: telemetryConnection,
          notificationsConnection: _FakeSocketConnection(),
        ),
      );
      addTearDown(controller.dispose);

      controller.initialize();
      await _flushAsync();
      telemetryConnection.triggerConnect();
      telemetryConnection.triggerEvent('devicestatus:update', <String, dynamic>{
        'imei': 'imei-1',
        'status': 'CONNECTED',
        'updatedAt': '2026-05-16T12:00:00Z',
      });
      telemetryConnection.triggerEvent('devicestatus:update', <String, dynamic>{
        'imei': 'unknown-imei',
        'status': 'CONNECTED',
      });
      await _flushLiveBatch();

      expect(controller.state.telemetry.vehicles, hasLength(1));
      expect(controller.state.telemetry.vehicles.single.status, 'idle');
      expect(
        controller.state.telemetry.vehicles.single.deviceConnectionStatus,
        'CONNECTED',
      );
    });

    test('loads telemetry seed once and disconnects sockets on dispose',
        () async {
      final telemetryConnection = _FakeSocketConnection();
      final notificationsConnection = _FakeSocketConnection();
      final vehicleService = _FakeVehicleService(
        fallbackTelemetry: _buildTelemetry([
          _vehicle(id: 'veh-1', name: 'Fallback 1', speed: 0),
          _vehicle(id: 'veh-2', name: 'Fallback 2', speed: 14),
        ]),
      );
      final controller = SuperadminMapLiveController(
        vehicleService,
        _FakeMapEventsService(notifications: const <AppNotification>[]),
        _FakeSocketService(
          telemetryConnection: telemetryConnection,
          notificationsConnection: notificationsConnection,
        ),
      );

      controller.initialize();
      await _flushAsync();
      telemetryConnection.triggerError('socket failed');
      await _flushAsync();
      telemetryConnection.triggerError('socket failed again');
      await _flushAsync();

      expect(vehicleService.getMapTelemetryCalls, 1);
      expect(controller.state.telemetry.allCount, 2);
      expect(controller.state.telemetry.runningCount, 1);

      controller.dispose();

      expect(telemetryConnection.disconnectCalls, 1);
      expect(notificationsConnection.disconnectCalls, 1);
    });
  });
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Future<void> _flushLiveBatch() async {
  await _flushAsync();
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await _flushAsync();
}

class _FakeVehicleService extends SuperadminVehicleService {
  _FakeVehicleService({required this.fallbackTelemetry})
      : super(ApiClient(Dio()));

  final SuperadminMapTelemetry fallbackTelemetry;
  int getMapTelemetryCalls = 0;

  @override
  Future<SuperadminMapTelemetry> getMapTelemetry({String? refreshKey}) async {
    getMapTelemetryCalls += 1;
    return fallbackTelemetry;
  }

  @override
  SuperadminMapTelemetry parseMapTelemetryPayload(dynamic json) {
    final vehicles = _extractVehicleMaps(json)
        .map(_vehicleFromMap)
        .whereType<VehicleSummary>()
        .toList(growable: false);
    return buildTelemetryFromVehicles(vehicles);
  }

  @override
  VehicleSummary? parseTelemetryVehiclePayload(
    dynamic raw, {
    bool requireCoordinates = false,
  }) {
    final source = raw is Map<String, dynamic>
        ? raw
        : raw is Map
            ? raw.map((key, value) => MapEntry(key.toString(), value))
            : const <String, dynamic>{};
    return _vehicleFromMap(source);
  }

  @override
  SuperadminMapTelemetry buildTelemetryFromVehicles(
    List<VehicleSummary> vehicles,
  ) {
    return _buildTelemetry(vehicles);
  }

  @override
  List<String> resolveVehicleIdentityAliases(
    dynamic raw, {
    VehicleSummary? fallbackVehicle,
  }) {
    final map = raw is Map<String, dynamic>
        ? raw
        : raw is Map
            ? raw.map((key, value) => MapEntry(key.toString(), value))
            : const <String, dynamic>{};
    final aliases = <String>[];
    if (map['id']?.toString().trim().isNotEmpty ?? false) {
      aliases.add('id:${map['id'].toString().trim()}');
    }
    if (map['vehicleId']?.toString().trim().isNotEmpty ?? false) {
      aliases.add('id:${map['vehicleId'].toString().trim()}');
    }
    if (map['imei']?.toString().trim().isNotEmpty ?? false) {
      aliases.add('imei:${map['imei'].toString().trim()}');
    }
    if (fallbackVehicle != null) {
      if (fallbackVehicle.id.trim().isNotEmpty) {
        aliases.add('id:${fallbackVehicle.id.trim()}');
      }
      if (fallbackVehicle.imei.trim().isNotEmpty) {
        aliases.add('imei:${fallbackVehicle.imei.trim()}');
      }
    }
    return aliases.toSet().toList(growable: false);
  }

  @override
  List<String> resolveVehicleIdentityAliasesForVehicle(VehicleSummary vehicle) {
    return resolveVehicleIdentityAliases(
      const <String, dynamic>{},
      fallbackVehicle: vehicle,
    );
  }
}

class _FakeMapEventsService extends SuperadminMapEventsService {
  _FakeMapEventsService({required List<AppNotification> notifications})
      : _notifications = List<AppNotification>.from(notifications),
        super(ApiClient(Dio()));

  final List<AppNotification> _notifications;

  @override
  Future<NotificationPage> getMapEvents({
    int limit = 50,
    String? beforeId,
    String? from,
    String? to,
    String? source,
    String? severity,
  }) async {
    return NotificationPage(
      items: _notifications.take(limit).toList(growable: false),
      hasMore: _notifications.length > limit,
      nextBeforeId:
          _notifications.length > limit ? _notifications[limit - 1].id : null,
      unreadCount: _notifications.where((item) => !item.isRead).length,
    );
  }
}

class _FakeSocketService extends SocketService {
  _FakeSocketService({
    required _FakeSocketConnection telemetryConnection,
    required _FakeSocketConnection notificationsConnection,
  })  : _connections = <String, _FakeSocketConnection>{
          '/telemetry': telemetryConnection,
          '/notifications': notificationsConnection,
        },
        super(
          TokenStorage(const FlutterSecureStorage()),
          apiBaseUrl: 'https://app.openvts.io/api',
        );

  final Map<String, _FakeSocketConnection> _connections;

  @override
  Future<SocketConnection> connect(String namespace) async {
    final connection = _connections[namespace];
    if (connection == null) {
      throw StateError('No fake socket registered for $namespace');
    }

    return connection;
  }
}

class _FakeSocketConnection implements SocketConnection {
  final Map<String, List<SocketEventHandler>> _eventHandlers =
      <String, List<SocketEventHandler>>{};
  final List<void Function()> _connectHandlers = <void Function()>[];
  final List<SocketEventHandler> _disconnectHandlers = <SocketEventHandler>[];
  final List<SocketEventHandler> _errorHandlers = <SocketEventHandler>[];

  final List<_EmittedEvent> emittedEvents = <_EmittedEvent>[];
  int disconnectCalls = 0;
  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  @override
  void emit(String event, [dynamic data]) {
    emittedEvents.add(_EmittedEvent(event, data));
  }

  @override
  void on(String event, SocketEventHandler handler) {
    _eventHandlers
        .putIfAbsent(event, () => <SocketEventHandler>[])
        .add(handler);
  }

  @override
  void off(String event, [SocketEventHandler? handler]) {
    final handlers = _eventHandlers[event];
    if (handlers == null) {
      return;
    }

    if (handler == null) {
      _eventHandlers.remove(event);
      return;
    }

    handlers.remove(handler);
    if (handlers.isEmpty) {
      _eventHandlers.remove(event);
    }
  }

  @override
  void onConnect(void Function() handler) {
    _connectHandlers.add(handler);
  }

  @override
  void onDisconnect(SocketEventHandler handler) {
    _disconnectHandlers.add(handler);
  }

  @override
  void onError(SocketEventHandler handler) {
    _errorHandlers.add(handler);
  }

  @override
  void disconnect() {
    disconnectCalls += 1;
    _isConnected = false;
    for (final handler in List<SocketEventHandler>.from(_disconnectHandlers)) {
      handler('disconnect');
    }
  }

  void triggerConnect() {
    _isConnected = true;
    for (final handler in List<void Function()>.from(_connectHandlers)) {
      handler();
    }
  }

  void triggerEvent(String event, dynamic data) {
    for (final handler in List<SocketEventHandler>.from(
      _eventHandlers[event] ?? const <SocketEventHandler>[],
    )) {
      handler(data);
    }
  }

  void triggerError(dynamic error) {
    for (final handler in List<SocketEventHandler>.from(_errorHandlers)) {
      handler(error);
    }
  }
}

class _EmittedEvent {
  const _EmittedEvent(this.name, this.data);

  final String name;
  final dynamic data;
}

SuperadminMapTelemetry _buildTelemetry(List<VehicleSummary> vehicles) {
  final inactiveCount = vehicles.where(_isInactiveVehicle).length;
  final runningCount = vehicles
      .where((vehicle) => !_isInactiveVehicle(vehicle))
      .where(
        (vehicle) =>
            vehicle.speed > 0 ||
            vehicle.status.toLowerCase().contains('running'),
      )
      .length;
  return SuperadminMapTelemetry(
    allCount: vehicles.length,
    runningCount: runningCount,
    stopCount: vehicles.length - runningCount - inactiveCount,
    inactiveCount: inactiveCount,
    vehicles: vehicles,
  );
}

bool _isInactiveVehicle(VehicleSummary vehicle) {
  final status = vehicle.status.trim().toLowerCase();
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

VehicleSummary _vehicle({
  required String id,
  String imei = '',
  required String name,
  required double speed,
  String plateNumber = '',
  String status = 'stop',
  double latitude = 10,
  double longitude = 20,
  bool? ignition,
  bool? acc,
  String? deviceConnectionStatus,
  DateTime? updatedAt,
  DateTime? lastSeenAt,
  double? distanceKm,
  double? odometerKm,
  double? engineHoursToday,
  double? engineHours,
  double? totalEngineHours,
  int? satellites,
}) {
  return VehicleSummary(
    id: id,
    imei: imei,
    name: name,
    plateNumber: plateNumber,
    status: status,
    speed: speed,
    latitude: latitude,
    longitude: longitude,
    hasValidLocation: true,
    distanceKm: distanceKm,
    odometerKm: odometerKm,
    engineHoursToday: engineHoursToday,
    engineHours: engineHours,
    totalEngineHours: totalEngineHours,
    satellites: satellites,
    ignition: ignition,
    acc: acc,
    deviceConnectionStatus: deviceConnectionStatus,
    updatedAt: updatedAt,
    lastSeenAt: lastSeenAt,
  );
}

Map<String, dynamic> _vehiclePayload({
  String id = '',
  String imei = '',
  String name = '',
  required double speed,
  String plateNumber = '',
  String status = 'stop',
  required double latitude,
  required double longitude,
  double? course,
  bool? ignition,
  bool? acc,
  double? distanceKm,
  double? odometerKm,
  double? engineHoursToday,
  double? engineHours,
  double? totalEngineHours,
  int? satellites,
  DateTime? updatedAt,
}) {
  return <String, dynamic>{
    if (id.isNotEmpty) 'id': id,
    if (imei.isNotEmpty) 'imei': imei,
    if (name.isNotEmpty) 'name': name,
    'plateNumber': plateNumber,
    'status': status,
    'speed': speed,
    'latitude': latitude,
    'longitude': longitude,
    if (course != null) 'course': course,
    if (ignition != null) 'ignition': ignition,
    if (acc != null) 'acc': acc,
    if (distanceKm != null) 'distanceToday': distanceKm,
    if (odometerKm != null) 'odometer': odometerKm,
    if (engineHoursToday != null) 'engineHoursToday': engineHoursToday,
    if (engineHours != null) 'engineHours': engineHours,
    if (totalEngineHours != null) 'totalengineHours': totalEngineHours,
    if (satellites != null) 'satellites': satellites,
    if (updatedAt != null) 'updatedAt': updatedAt.toIso8601String(),
  };
}

VehicleSummary? _vehicleFromMap(Map<String, dynamic>? map) {
  if (map == null || map.isEmpty) {
    return null;
  }

  return VehicleSummary(
    id: map['id']?.toString() ?? map['vehicleId']?.toString() ?? '',
    imei: map['imei']?.toString() ?? '',
    name: map['name']?.toString() ?? map['plateNumber']?.toString() ?? '',
    plateNumber: map['plateNumber']?.toString() ?? '',
    status: map['status']?.toString() ?? 'stop',
    speed: (map['speed'] as num?)?.toDouble() ??
        (map['speedKph'] as num?)?.toDouble() ??
        0,
    latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    hasValidLocation:
        map.containsKey('latitude') && map.containsKey('longitude'),
    distanceKm: (map['distanceToday'] as num?)?.toDouble() ??
        (map['distanceKm'] as num?)?.toDouble() ??
        (map['distance'] as num?)?.toDouble(),
    odometerKm: (map['odometer'] as num?)?.toDouble() ??
        (map['odometerKm'] as num?)?.toDouble(),
    engineHoursToday: (map['engineHoursToday'] as num?)?.toDouble(),
    engineHours: (map['engineHours'] as num?)?.toDouble(),
    totalEngineHours: (map['totalengineHours'] as num?)?.toDouble() ??
        (map['totalEngineHours'] as num?)?.toDouble(),
    satellites: (map['satellites'] as num?)?.round(),
    headingDegrees: (map['course'] as num?)?.toDouble(),
    ignition: map['ignition'] as bool?,
    acc: map['acc'] as bool?,
    deviceConnectionStatus: map['deviceConnectionStatus']?.toString() ??
        map['connectionStatus']?.toString(),
    updatedAt: _parseDateTime(map['updatedAt']),
  );
}

DateTime? _parseDateTime(dynamic raw) {
  if (raw is DateTime) {
    return raw;
  }

  final value = raw?.toString().trim();
  if (value == null || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}

List<Map<String, dynamic>> _extractVehicleMaps(dynamic json) {
  if (json is List) {
    return json.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  if (json is Map<String, dynamic>) {
    final vehicles = json['vehicles'];
    if (vehicles is List) {
      return vehicles.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    return <Map<String, dynamic>>[json];
  }

  return const <Map<String, dynamic>>[];
}

AppNotification _notification({
  required int id,
  required String title,
  String? message,
  int? eventId,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    title: title,
    message: message ?? '$title body',
    isRead: false,
    createdAt: createdAt ?? DateTime.utc(2026, 5, 15, 11, id),
    eventId: eventId,
  );
}
