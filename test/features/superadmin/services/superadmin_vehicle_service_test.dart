import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/api/api_client.dart';
import 'package:open_vts/core/api/api_endpoints.dart';
import 'package:open_vts/features/notifications/models/app_notification.dart';
import 'package:open_vts/features/superadmin/models/superadmin_vehicle_model.dart';
import 'package:open_vts/features/superadmin/services/superadmin_vehicle_service.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'USE_MOCK_DATA=false');
  });

  group('SuperadminVehicleService replay', () {
    final service = SuperadminVehicleService(ApiClient(Dio()));

    test('builds map telemetry counts with inactive excluded from stop', () {
      final telemetry = service.parseMapTelemetryPayload(<String, dynamic>{
        'vehicles': <Map<String, dynamic>>[
          _mapVehicle(imei: 'running-by-speed', speedKph: 12),
          _mapVehicle(imei: 'running-by-status', status: 'moving'),
          _mapVehicle(imei: 'stopped', status: 'idle'),
          _mapVehicle(imei: 'inactive', status: 'inactive'),
          _mapVehicle(imei: 'offline', status: 'offline'),
          _mapVehicle(
            imei: 'license-blocked',
            status: 'running',
            licenseBlocked: true,
          ),
        ],
      });

      expect(telemetry.allCount, 6);
      expect(telemetry.runningCount, 2);
      expect(telemetry.stopCount, 1);
      expect(telemetry.inactiveCount, 3);
    });

    test('parses live distance and odometer as separate telemetry fields', () {
      final telemetry = service.parseMapTelemetryPayload(<String, dynamic>{
        'vehicles': <Map<String, dynamic>>[
          <String, dynamic>{
            'vehicleId': 'veh-1',
            'vehicleName': 'Car 1',
            'imei': 'imei-1',
            'status': 'running',
            'speedKph': 18,
            'latitude': 28.61,
            'longitude': 77.20,
            'telemetry': <String, dynamic>{
              'distanceToday': 27.84,
              'distance': 31.2,
              'totalDistance': 1026.6,
              'odometer': 2048.5,
              'engineHoursToday': 1.25,
              'totalengineHours': 900.5,
              'satellites': 11,
            },
          },
        ],
      });

      final vehicle = telemetry.vehicles.single;
      expect(vehicle.distanceKm, 27.84);
      expect(vehicle.odometerKm, 2048.5);
      expect(vehicle.engineHoursToday, 1.25);
      expect(vehicle.totalEngineHours, 900.5);
      expect(vehicle.satellites, 11);
    });

    test('does not parse live totalDistance as today distance or odometer', () {
      final telemetry = service.parseMapTelemetryPayload(<String, dynamic>{
        'vehicles': <Map<String, dynamic>>[
          <String, dynamic>{
            'vehicleId': 'veh-1',
            'vehicleName': 'Car 1',
            'imei': 'imei-1',
            'status': 'stop',
            'speedKph': 0,
            'latitude': 28.61,
            'longitude': 77.20,
            'telemetry': <String, dynamic>{
              'totalDistance': 1026.6,
              'todayDistance': 8.2,
            },
          },
        ],
      });

      final vehicle = telemetry.vehicles.single;
      expect(vehicle.distanceKm, 8.2);
      expect(vehicle.odometerKm, isNull);
    });

    test(
      'does not parse details totalDistance or mileage as live distance',
      () {
        final details = service.parseVehicleDetailsPayload(<String, dynamic>{
          'vehicle': <String, dynamic>{
            'imei': 'imei-1',
            'totalDistance': 1026.6,
            'mileage': 2048.5,
          },
        });

        expect(details.distanceKm, isNull);
      },
    );

    test('uses the superadmin replay endpoint by IMEI', () {
      expect(
        ApiEndpoints.superadmin.vehicleReplayByImei('867440060976859'),
        '/superadmin/vehicles/by-imei/867440060976859/replay',
      );
    });

    test('uses the superadmin logs endpoint by IMEI', () {
      expect(
        ApiEndpoints.superadmin.vehicleLogsByImei('867440060976859'),
        '/superadmin/vehicles/by-imei/867440060976859/logs',
      );
    });

    test('uses the superadmin events endpoint by IMEI', () {
      expect(
        ApiEndpoints.superadmin.vehicleEventsByImei('867440060976859'),
        '/superadmin/vehicles/by-imei/867440060976859/events',
      );
    });

    test('uses the superadmin sensors endpoint by IMEI', () {
      expect(
        ApiEndpoints.superadmin.vehicleSensorsByImei('867440060976859'),
        '/superadmin/vehicles/by-imei/867440060976859/sensors',
      );
    });

    test('uses the superadmin Web command endpoints', () {
      expect(
        ApiEndpoints.superadmin.customCommands,
        '/superadmin/customcommands',
      );
      expect(
        ApiEndpoints.superadmin.systemVariables,
        '/superadmin/systemvariables',
      );
      expect(
        ApiEndpoints.superadmin.vehicleCommandsByImei('867440060976859'),
        '/superadmin/vehicles/by-imei/867440060976859/commands',
      );
      expect(
        ApiEndpoints.superadmin.commandHistoryByImei('867440060976859'),
        '/superadmin/vehicles/by-imei/867440060976859/commands',
      );
      expect(
        ApiEndpoints.superadmin.sendDeviceCommand('867440060976859'),
        '/superadmin/devices/867440060976859/send-command',
      );
      expect(
        ApiEndpoints.superadmin.sendDeviceCommandByImei('867440060976859'),
        '/superadmin/devices/867440060976859/send-command',
      );
      expect(
        ApiEndpoints.superadmin.sendDeviceCommandByImei('imei/with space'),
        '/superadmin/devices/imei%2Fwith%20space/send-command',
      );
      expect(
        ApiEndpoints.superadmin.sendVehicleCommandByImei('867440060976859'),
        '/superadmin/vehicles/by-imei/867440060976859/send-command',
      );
      expect(
        ApiEndpoints.superadmin.commandStatusByCmdId('cmd-1'),
        '/superadmin/commands/status/cmd-1',
      );
      expect(
        ApiEndpoints.superadmin.commandStatus('cmd-1'),
        '/superadmin/commands/status/cmd-1',
      );
      expect(
        ApiEndpoints.superadmin.commandByCmdId('cmd-1'),
        '/superadmin/commands/cmd-1',
      );
      expect(
        ApiEndpoints.superadmin.commandLog('cmd-1'),
        '/superadmin/commands/cmd-1',
      );
    });

    test('loads command history with limit and cursor query params', () async {
      RequestOptions? capturedRequest;
      final commandService = SuperadminVehicleService(
        ApiClient(
          _buildDio(
            onRequest: (options) => capturedRequest = options,
            dataForRequest: (_) => const <String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'nextCursorId': null,
              'hasMore': false,
            },
          ),
        ),
      );

      await commandService.getCommandHistoryByImei(
        imei: '867440060976859',
        limit: 50,
        cursorId: '73',
      );

      expect(
        capturedRequest?.path,
        '/superadmin/vehicles/by-imei/867440060976859/commands',
      );
      expect(capturedRequest?.queryParameters['limit'], 50);
      expect(capturedRequest?.queryParameters['cursorId'], '73');
    });

    test('sends commands through the Web parity device endpoint', () async {
      RequestOptions? capturedRequest;
      final commandService = SuperadminVehicleService(
        ApiClient(
          _buildDio(
            onRequest: (options) => capturedRequest = options,
            dataForRequest: (_) => const <String, dynamic>{
              'cmdId': 'cmd-1',
              'connected': true,
              'queued': false,
            },
          ),
        ),
      );

      final result = await commandService.sendCommandByImei(
        imei: '867440060976859',
        command: ' STATUS ',
        note: ' verify ',
      );

      expect(
        capturedRequest?.path,
        '/superadmin/devices/867440060976859/send-command',
      );
      expect(capturedRequest?.method, 'POST');
      expect(capturedRequest?.data, <String, dynamic>{
        'command': 'STATUS',
      });
      expect(result.cmdId, 'cmd-1');
      expect(result.localStatus, 'SENT');
    });

    test('parses vehicle database logs with cursor and raw details', () {
      final page = service.parseVehicleLogsPayload(<String, dynamic>{
        'data': <String, dynamic>{
          'items': <Map<String, dynamic>>[
            _logPayload(
              id: '42',
              imei: 'imei-1',
              serverTime: '2026-05-16T10:00:00.000Z',
              packetType: 'location',
              speedKph: 28,
              ignition: true,
              raw: '78780d010359339075056886000d0a',
              attributes: <String, dynamic>{'battery': 88},
            ),
          ],
          'nextCursor': '42',
        },
      });

      expect(page.nextCursor, '42');
      expect(page.items, hasLength(1));
      final item = page.items.single;
      expect(item.source, SuperadminVehicleLogSource.api);
      expect(item.imei, 'imei-1');
      expect(item.packetType, 'location');
      expect(item.speedKph, 28);
      expect(item.ignition, isTrue);
      expect(item.rawPacket, '78780d010359339075056886000d0a');
      expect(item.attributes, <String, dynamic>{'battery': 88});
    });

    test('merges live logs by selected IMEI and serverTime packetType', () {
      final databaseRows = service.parseVehicleLogsPayload(<String, dynamic>{
        'items': <Map<String, dynamic>>[
          _logPayload(
            id: 'db-1',
            imei: 'imei-1',
            serverTime: '2026-05-16T10:00:00.000Z',
            packetType: 'location',
            speedKph: 12,
          ),
          _logPayload(
            id: 'db-2',
            imei: 'imei-1',
            serverTime: '2026-05-16T09:59:00.000Z',
            packetType: 'heartbeat',
            speedKph: 0,
          ),
        ],
      }).items;
      final liveRows = service.parseTelemetryLogListPayload(<String, dynamic>{
        'items': <Map<String, dynamic>>[
          _logPayload(
            id: 'live-other',
            imei: 'other-imei',
            serverTime: '2026-05-16T10:02:00.000Z',
            packetType: 'location',
            speedKph: 99,
          ),
          _logPayload(
            id: 'live-new',
            imei: 'imei-1',
            serverTime: '2026-05-16T10:01:00.000Z',
            packetType: 'alarm',
            speedKph: 18,
          ),
          _logPayload(
            id: 'live-dupe',
            imei: 'imei-1',
            serverTime: '2026-05-16T10:00:00.000Z',
            packetType: 'location',
            speedKph: 44,
          ),
        ],
      });

      final merged = mergeSuperadminVehicleLogs(
        current: databaseRows,
        incoming: liveRows,
        imei: 'imei-1',
        cap: 2,
      );

      expect(merged, hasLength(2));
      expect(merged.map((row) => row.id), <String>['live-new', 'live-dupe']);
      expect(merged.first.packetType, 'alarm');
      expect(merged.last.speedKph, 44);
      expect(merged.every((row) => row.imei == 'imei-1'), isTrue);
    });

    test('parses vehicle events with cursor and selected IMEI filtering', () {
      final page = service.parseVehicleEventsPayload(
        <String, dynamic>{
          'data': <String, dynamic>{
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                _eventPayload(
                  id: 51,
                  imei: 'imei-1',
                  createdAt: '2026-05-16T10:00:00.000Z',
                  title: 'Overspeed',
                  category: 'OVERSPEED',
                ),
                _eventPayload(
                  id: 50,
                  imei: 'other-imei',
                  createdAt: '2026-05-16T09:59:00.000Z',
                  title: 'Ignored',
                  category: 'IGNITION',
                ),
              ],
              'nextCursor': '50',
            },
          },
        },
        imei: 'imei-1',
        requestedLimit: 50,
      );

      expect(page.nextCursor, '50');
      expect(page.items, hasLength(1));
      expect(page.items.single.vehicleImei, 'imei-1');
      expect(page.items.single.title, 'Overspeed');
      expect(page.items.single.category, 'OVERSPEED');
    });

    test('parses notif:new vehicle event wrappers by nested vehicle IMEI', () {
      final event = service.parseVehicleEventPayload(<String, dynamic>{
        'event': _eventPayload(
          id: 90,
          imei: 'imei-1',
          createdAt: '2026-05-16T10:02:00.000Z',
          title: 'Geofence',
          category: 'GEOFENCE',
          useNestedVehicleImei: true,
        ),
      }, imei: 'imei-1');
      final ignored = service.parseVehicleEventPayload(<String, dynamic>{
        'event': _eventPayload(
          id: 91,
          imei: 'other-imei',
          createdAt: '2026-05-16T10:03:00.000Z',
          title: 'Other vehicle',
          category: 'GEOFENCE',
          useNestedVehicleImei: true,
        ),
      }, imei: 'imei-1');

      expect(event, isNotNull);
      expect(event!.vehicleImei, 'imei-1');
      expect(event.title, 'Geofence');
      expect(ignored, isNull);
    });

    test('merges vehicle events by id and dedupe fallback newest first', () {
      final current = <AppNotification>[
        AppNotification.fromJson(
          _eventPayload(
            id: 100,
            imei: 'imei-1',
            createdAt: '2026-05-16T10:00:00.000Z',
            title: 'Database duplicate',
            category: 'OVERSPEED',
          ),
        ),
        AppNotification.fromJson(
          _eventPayload(
            id: 0,
            imei: 'imei-1',
            createdAt: '2026-05-16T09:58:00.000Z',
            title: 'Database fallback',
            category: 'IGNITION',
            dedupeKey: 'fallback-event',
          ),
        ),
      ];
      final incoming = <AppNotification>[
        AppNotification.fromJson(
          _eventPayload(
            id: 101,
            imei: 'other-imei',
            createdAt: '2026-05-16T10:03:00.000Z',
            title: 'Other vehicle',
            category: 'IGNITION',
          ),
        ),
        AppNotification.fromJson(
          _eventPayload(
            id: 101,
            imei: 'imei-1',
            createdAt: '2026-05-16T10:02:00.000Z',
            title: 'Live new',
            category: 'IGNITION',
          ),
        ),
        AppNotification.fromJson(
          _eventPayload(
            id: 100,
            imei: 'imei-1',
            createdAt: '2026-05-16T10:01:00.000Z',
            title: 'Live duplicate',
            category: 'OVERSPEED',
          ),
        ),
        AppNotification.fromJson(
          _eventPayload(
            id: 0,
            imei: 'imei-1',
            createdAt: '2026-05-16T10:04:00.000Z',
            title: 'Live fallback duplicate',
            category: 'IGNITION',
            dedupeKey: 'fallback-event',
          ),
        ),
      ];

      final merged = mergeSuperadminVehicleEvents(
        current: current,
        incoming: incoming,
        imei: 'imei-1',
        cap: 2,
      );

      expect(merged, hasLength(2));
      expect(merged.map((event) => event.title), <String>[
        'Live fallback duplicate',
        'Live new',
      ]);
      expect(merged.every((event) => event.vehicleImei == 'imei-1'), isTrue);
    });

    test('parses vehicle sensors from flexible payload shapes', () {
      final dataSensorsPage = service.parseVehicleSensorsPayload(
        <String, dynamic>{
          'data': <String, dynamic>{
            'sensors': <Map<String, dynamic>>[
              _sensorPayload(
                id: 1,
                name: 'Fuel level',
                rawAttribute: 'attributes.fuelLevel',
                displayValue: '76',
                unit: '%',
              ),
            ],
            'totalCount': 1,
            'truncated': false,
            'telemetryMeta': <String, dynamic>{
              'hasTelemetry': true,
              'serverTime': '2026-05-16T10:00:00.000Z',
            },
          },
        },
      );
      final dataItemsPage = service.parseVehicleSensorsPayload(
        <String, dynamic>{
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              _sensorPayload(
                id: 2,
                name: 'Ignition',
                rawAttribute: 'ignition',
                displayValue: 'Off',
                type: 'boolean',
              ),
            ],
          },
        },
      );

      expect(dataSensorsPage.items, hasLength(1));
      expect(dataSensorsPage.totalCount, 1);
      expect(dataSensorsPage.truncated, isFalse);
      expect(dataSensorsPage.telemetryMeta?.hasTelemetry, isTrue);
      expect(
        dataSensorsPage.telemetryMeta?.serverTime?.toUtc().toIso8601String(),
        '2026-05-16T10:00:00.000Z',
      );
      expect(dataSensorsPage.items.single.name, 'Fuel level');
      expect(dataSensorsPage.items.single.sourceKey, 'attributes.fuelLevel');
      expect(dataSensorsPage.items.single.latestValue, '76');
      expect(dataSensorsPage.items.single.unit, '%');
      expect(dataItemsPage.items.single.name, 'Ignition');
      expect(dataItemsPage.items.single.type, 'boolean');
    });

    test('updates sensor latest values from matching live telemetry', () {
      final sensors = service.parseVehicleSensorsPayload(<String, dynamic>{
        'items': <Map<String, dynamic>>[
          _sensorPayload(
            id: 1,
            name: 'Speed',
            rawAttribute: 'speedKph',
            displayValue: '0',
            unit: 'km/h',
          ),
          _sensorPayload(
            id: 2,
            name: 'Ignition',
            expression: "attributes['ignition']",
            displayValue: 'Off',
            type: 'boolean',
          ),
          _sensorPayload(
            id: 3,
            name: 'No match',
            rawAttribute: 'unknownSensor',
            displayValue: '--',
          ),
        ],
      }).items;
      final updatedAt = DateTime.parse('2026-05-16T10:04:00.000Z');

      final updated = updateSuperadminVehicleSensorsWithTelemetry(
        sensors: sensors,
        telemetry: <String, Object?>{'speedKph': 42, 'ignition': true},
        updatedAt: updatedAt,
      );

      expect(updated[0].latestValue, '42');
      expect(updated[0].status, 'Live');
      expect(updated[0].lastUpdated, updatedAt);
      expect(updated[1].latestValue, 'On');
      expect(updated[1].status, 'Live');
      expect(updated[2].latestValue, '--');
      expect(updated[2].status, 'OK');
    });

    test(
      'parses custom commands and system variables from flexible shapes',
      () {
        final commands = service.parseCustomCommandsPayload(<String, dynamic>{
          'data': <String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 11,
                'deviceTypeId': 3,
                'commandTypeId': 7,
                'command': r'STATUS#{{IMEI}}#${LAT},${LON}',
                'isActive': true,
                'commandType': <String, dynamic>{
                  'id': 7,
                  'name': 'Status',
                  'description': 'Status command',
                },
                'deviceType': <String, dynamic>{
                  'id': 3,
                  'name': 'GT06',
                  'protocol': 'GPRS',
                },
              },
            ],
          },
        });
        final variables = service.parseSystemVariablesPayload(<String, dynamic>{
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 1,
                'name': 'SERVER',
                'initialValue': 'OPENVTS',
              },
            ],
          },
        });

        expect(commands, hasLength(1));
        expect(commands.single.commandTypeName, 'Status');
        expect(commands.single.deviceProtocol, 'GPRS');
        expect(commands.single.protocol, 'GPRS');
        expect(commands.single.command, r'STATUS#{{IMEI}}#${LAT},${LON}');
        expect(variables.single.key, 'SERVER');
        expect(variables.single.name, 'SERVER');
        expect(variables.single.value, 'OPENVTS');
        expect(variables.single.isActive, isTrue);
        expect(variables.single.initialValue, 'OPENVTS');
      },
    );

    test('parses command history, send response, and status payloads', () {
      final history = service.parseVehicleCommandsPayload(<String, dynamic>{
        'data': <String, dynamic>{
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              _commandPayload(
                id: 42,
                cmdId: 'cmd-42',
                status: 'RESPONDED',
                responseRaw: 'OK',
              ),
            ],
            'nextCursorId': '42',
            'hasMore': true,
          },
        },
      });
      final send = service.parseSendCommandResponsePayload(<String, dynamic>{
        'cmdId': 'cmd-43',
        'connected': false,
        'queued': true,
        'queueId': 'queue-43',
      });
      final status = service.parseCommandPayload(<String, dynamic>{
        'data': <String, dynamic>{
          'cmdId': 'cmd-43',
          'status': 'SENT',
          'sentAt': '2026-05-16T10:01:00.000Z',
        },
      });

      expect(history.items, hasLength(1));
      expect(history.nextCursorId, '42');
      expect(history.hasMore, isTrue);
      expect(history.items.single.cmdId, 'cmd-42');
      expect(history.items.single.responseRaw, 'OK');
      expect(history.items.single.metadata['source'], 'test');
      expect(send.wasQueued, isTrue);
      expect(send.localStatus, 'QUEUED');
      expect(send.queueId, 'queue-43');
      expect(status?.cmdId, 'cmd-43');
      expect(status?.status, 'SENT');
      expect(
        status?.sentAt?.toUtc().toIso8601String(),
        '2026-05-16T10:01:00.000Z',
      );
      expect(
        service.parseCommandStatusPayload(<String, dynamic>{
          'cmdId': 'cmd-43',
          'status': 'sent',
        })?.status,
        'SENT',
      );
    });

    test('parses wrapped replay points and ignores invalid coordinates', () {
      final replay = service.parseVehicleReplayPayload(<String, dynamic>{
        'data': <String, dynamic>{
          'data': <String, dynamic>{
            'imei': '867440060976859',
            'from': '2026-05-15T10:00:00.000Z',
            'to': '2026-05-15T11:00:00.000Z',
            'meta': <String, dynamic>{
              'totalRaw': 2,
              'returned': 1,
              'bucketSeconds': 10,
            },
            'points': <Map<String, dynamic>>[
              <String, dynamic>{
                'serverTime': '2026-05-15T10:12:22.000Z',
                'deviceTime': '2026-05-15T10:12:20.000Z',
                'latitude': 28.6139,
                'longitude': 77.209,
                'speedKph': 42,
                'course': 135,
                'ignition': true,
                'acc': true,
                'odometer': 52000.8,
                'distance': 1250.4,
                'engineHours': 2.4,
                'totalengineHours': 900.5,
                'satellites': 10,
                'attributes': <String, dynamic>{'event': 'gps'},
              },
              <String, dynamic>{
                'serverTime': '2026-05-15T10:13:22.000Z',
                'speedKph': 18,
              },
            ],
          },
        },
      });

      expect(replay.imei, '867440060976859');
      expect(replay.meta.totalRaw, 2);
      expect(replay.meta.returned, 1);
      expect(replay.meta.bucketSeconds, 10);
      expect(replay.points, hasLength(1));
      expect(replay.points.single.latitude, 28.6139);
      expect(replay.points.single.longitude, 77.209);
      expect(
        replay.points.single.effectiveTime?.toUtc().toIso8601String(),
        '2026-05-15T10:12:20.000Z',
      );
      expect(replay.points.single.attributes['event'], 'gps');
    });

    test('supports data.points and root points replay payloads', () {
      final dataPointsReplay = service.parseVehicleReplayPayload(
        <String, dynamic>{
          'data': <String, dynamic>{
            'points': <Map<String, dynamic>>[
              _replayPoint(latitude: 28.61, longitude: 77.20),
            ],
          },
        },
      );
      final rootPointsReplay = service.parseVehicleReplayPayload(
        <String, dynamic>{
          'points': <Map<String, dynamic>>[
            _replayPoint(latitude: 28.62, longitude: 77.21),
          ],
        },
      );

      expect(dataPointsReplay.points, hasLength(1));
      expect(dataPointsReplay.points.single.latitude, 28.61);
      expect(rootPointsReplay.points, hasLength(1));
      expect(rootPointsReplay.points.single.longitude, 77.21);
    });

    test('parses replay odometer and engine hours from attributes', () {
      final replay = service.parseVehicleReplayPayload(<String, dynamic>{
        'points': <Map<String, dynamic>>[
          _replayPoint(
            latitude: 28.61,
            longitude: 77.20,
            attributes: <String, dynamic>{
              'totalOdometer': 1026.6,
              'totalDistance': 12.4,
              'hours': 3695760000,
            },
          ),
        ],
      });

      final point = replay.points.single;
      expect(point.odometer, 1026.6);
      expect(point.totalengineHours, closeTo(1026.6, 0.001));
    });

    test('prefers plausible total odometer over tiny replay counters', () {
      final replay = service.parseVehicleReplayPayload(<String, dynamic>{
        'points': <Map<String, dynamic>>[
          <String, dynamic>{
            'serverTime': '2026-05-15T10:12:22.000Z',
            'latitude': 28.61,
            'longitude': 77.20,
            'speedKph': 12,
            'odometer': 1,
            'attributes': <String, dynamic>{'totalOdometer': 1026.6},
          },
        ],
      });

      expect(replay.points.single.odometer, 1026.6);
    });

    test('does not parse replay distance fields as odometer', () {
      final replay = service.parseVehicleReplayPayload(<String, dynamic>{
        'points': <Map<String, dynamic>>[
          _replayPoint(
            latitude: 28.61,
            longitude: 77.20,
            attributes: <String, dynamic>{
              'distance': 4.2,
              'distanceKm': 4.2,
              'totalDistance': 1026.6,
              'tripDistance': 4.2,
            },
          ),
        ],
      });

      expect(replay.points.single.odometer, isNull);
    });

    test('converts explicit replay odometer meter fields to kilometers', () {
      final replay = service.parseVehicleReplayPayload(<String, dynamic>{
        'points': <Map<String, dynamic>>[
          _replayPoint(
            latitude: 28.61,
            longitude: 77.20,
            attributes: <String, dynamic>{'odometerMeters': 1026600},
          ),
        ],
      });

      expect(replay.points.single.odometer, 1026.6);
    });
  });
}

Map<String, dynamic> _mapVehicle({
  required String imei,
  String status = 'stop',
  double speedKph = 0,
  bool? licenseBlocked,
}) {
  return <String, dynamic>{
    'vehicleId': imei,
    'vehicleName': imei,
    'imei': imei,
    'status': status,
    'speedKph': speedKph,
    'latitude': 28.61,
    'longitude': 77.20,
    if (licenseBlocked != null) 'licenseBlocked': licenseBlocked,
  };
}

Map<String, dynamic> _replayPoint({
  required double latitude,
  required double longitude,
  Map<String, dynamic>? attributes,
}) {
  return <String, dynamic>{
    'serverTime': '2026-05-15T10:12:22.000Z',
    'latitude': latitude,
    'longitude': longitude,
    'speedKph': 12,
    if (attributes != null) 'attributes': attributes,
  };
}

Map<String, dynamic> _logPayload({
  required String id,
  required String imei,
  required String serverTime,
  required String packetType,
  double speedKph = 0,
  bool? ignition,
  String? raw,
  Map<String, dynamic>? attributes,
}) {
  return <String, dynamic>{
    'id': id,
    'imei': imei,
    'serverTime': serverTime,
    'deviceTime': serverTime,
    'packetType': packetType,
    'protocol': 'gt06',
    'speedKph': speedKph,
    'course': 180,
    if (ignition != null) 'ignition': ignition,
    'acc': ignition,
    'latitude': 28.6139,
    'longitude': 77.209,
    'altitude': 216,
    'satellites': 10,
    'valid': true,
    'distance': 1.2,
    'odometer': 1026.6,
    'engineHours': 1.5,
    'totalengineHours': 900.5,
    if (raw != null) 'raw': raw,
    if (attributes != null) 'attributes': attributes,
  };
}

Map<String, dynamic> _eventPayload({
  required int id,
  required String imei,
  required String createdAt,
  required String title,
  required String category,
  String? dedupeKey,
  bool useNestedVehicleImei = false,
}) {
  return <String, dynamic>{
    'id': id,
    'title': title,
    'category': category,
    'message': '$title event for $imei',
    'severity': category == 'OVERSPEED' ? 'CRITICAL' : 'INFO',
    'createdAt': createdAt,
    'dedupeKey': dedupeKey ?? '$imei:$id:$category',
    if (!useNestedVehicleImei) 'imei': imei,
    'metadata': <String, dynamic>{
      if (!useNestedVehicleImei) 'imei': imei,
      if (useNestedVehicleImei)
        'vehicle': <String, dynamic>{'imei': imei, 'name': 'Vehicle $imei'},
    },
  };
}

Map<String, dynamic> _sensorPayload({
  required int id,
  required String name,
  String type = 'number',
  String? rawAttribute,
  String? expression,
  String displayValue = '0',
  String? unit,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'dataType': type,
    'unit': unit,
    'rawAttribute': rawAttribute,
    'expression': expression,
    'description': 'Sensor $name',
    'updatedAt': '2026-05-16T09:58:00.000Z',
    'computed': <String, dynamic>{
      'ok': true,
      'displayValue': displayValue,
      'type': type,
      'ms': 1.2,
    },
  };
}

Map<String, dynamic> _commandPayload({
  required int id,
  required String cmdId,
  required String status,
  String? responseRaw,
}) {
  return <String, dynamic>{
    'id': id,
    'cmdId': cmdId,
    'imei': '867440060976859',
    'vehicleId': 99,
    'command': 'STATUS',
    'status': status,
    'requestedByRole': 'SUPERADMIN',
    'transport': 'GPRS',
    'source': 'superadmin.sendDeviceCommandByImei',
    'queueId': 'queue-$id',
    'connectedAtSend': true,
    'requestedAt': '2026-05-16T10:00:00.000Z',
    'sentAt': '2026-05-16T10:00:01.000Z',
    'respondedAt': responseRaw == null ? null : '2026-05-16T10:00:04.000Z',
    'responseRaw': responseRaw,
    'metadata': <String, dynamic>{'source': 'test'},
  };
}

Dio _buildDio({
  required void Function(RequestOptions options) onRequest,
  required dynamic Function(RequestOptions options) dataForRequest,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: dataForRequest(options),
          ),
        );
      },
    ),
  );
  return dio;
}
