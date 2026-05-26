import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/superadmin/models/superadmin_calendar_model.dart';

void main() {
  test('parses grouped monthly calendar counts from typed buckets', () {
    final events = CalendarEvent.listFromPayload(<String, dynamic>{
      'users': <Map<String, dynamic>>[
        <String, dynamic>{
          'date': '2026-05-04',
          'count': 5,
        },
      ],
      'vehicle': <String, dynamic>{
        '2026-05-04': 6,
        '2026-05-14': 1,
      },
      'expiry': <String, dynamic>{
        '2026-05-04': <String, dynamic>{'count': '2'},
        '2026-05-15': 1,
      },
    });

    expect(events, hasLength(3));

    final fourth = events.firstWhere((item) => item.date == '2026-05-04');
    expect(fourth.usersCount, 5);
    expect(fourth.vehiclesCount, 6);
    expect(fourth.expiryCount, 2);

    final fourteenth = events.firstWhere((item) => item.date == '2026-05-14');
    expect(fourteenth.vehiclesCount, 1);

    final fifteenth = events.firstWhere((item) => item.date == '2026-05-15');
    expect(fifteenth.expiryCount, 1);
  });

  test('parses list-style monthly rows with alternate count keys', () {
    final events = CalendarEvent.listFromPayload(<String, dynamic>{
      'data': <Map<String, dynamic>>[
        <String, dynamic>{
          'event_date': '2026-05-10T00:00:00.000Z',
          'users_count': '3',
          'vehicle_count': 1,
          'expiry_count': 0,
        },
      ],
    });

    expect(events, hasLength(1));
    expect(events.single.date, '2026-05-10');
    expect(events.single.usersCount, 3);
    expect(events.single.vehiclesCount, 1);
  });

  test('parses date-keyed monthly rows with nested typed containers', () {
    final events = CalendarEvent.listFromPayload(<String, dynamic>{
      'calendar': <String, dynamic>{
        '2026-05-04': <String, dynamic>{
          'users': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'uid': 1},
              <String, dynamic>{'uid': 2},
              <String, dynamic>{'uid': 3},
              <String, dynamic>{'uid': 4},
              <String, dynamic>{'uid': 5},
            ],
          },
          'vehicle': <String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'vehicleId': 'veh-1'},
              <String, dynamic>{'vehicleId': 'veh-2'},
              <String, dynamic>{'vehicleId': 'veh-3'},
              <String, dynamic>{'vehicleId': 'veh-4'},
              <String, dynamic>{'vehicleId': 'veh-5'},
              <String, dynamic>{'vehicleId': 'veh-6'},
            ],
          },
          'expiry': <String, dynamic>{
            'summary': <String, dynamic>{'count': 2},
          },
        },
      },
    });

    expect(events, hasLength(1));
    expect(events.single.date, '2026-05-04');
    expect(events.single.usersCount, 5);
    expect(events.single.vehiclesCount, 6);
    expect(events.single.expiryCount, 2);
  });

  test('normalizes vehicle expiry buckets as expiry counts', () {
    final events = CalendarEvent.listFromPayload(<String, dynamic>{
      'VEHICLE_EXPIRY': <String, dynamic>{
        '2026-05-15': 3,
      },
    });

    expect(events, hasLength(1));
    expect(events.single.date, '2026-05-15');
    expect(events.single.expiryCount, 3);
    expect(events.single.vehiclesCount, 0);
  });

  test('parses grouped day details and summary counts', () {
    final details = CalendarDayDetail.listFromPayload(<String, dynamic>{
      'users': <Map<String, dynamic>>[
        <String, dynamic>{
          'uid': 7,
          'name': 'Aarya Singh',
          'mobile': '9999999999',
        },
      ],
      'vehicle': <Map<String, dynamic>>[
        <String, dynamic>{
          'vehicleId': 'veh-9',
          'plateNumber': 'UP80GH6512',
          'vehicleType': 'Car',
        },
      ],
      'expiry': 2,
    });

    expect(details, hasLength(3));

    final userDetail = details.firstWhere((item) => item.type == 'users');
    expect(userDetail.isUser, isTrue);
    expect(userDetail.userId, '7');
    expect(userDetail.title, 'Aarya Singh');

    final vehicleDetail = details.firstWhere((item) => item.type == 'vehicle');
    expect(vehicleDetail.isVehicle, isTrue);
    expect(vehicleDetail.vehicleId, 'veh-9');
    expect(vehicleDetail.title, 'UP80GH6512');

    final expiryDetail = details.firstWhere((item) => item.type == 'expiry');
    expect(expiryDetail.title, 'Expiry');
    expect(expiryDetail.subtitle, '2 events');
  });

  test('parses nested day details from wrapped typed containers', () {
    final details = CalendarDayDetail.listFromPayload(<String, dynamic>{
      'payload': <String, dynamic>{
        'users': <String, dynamic>{
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'uid': 9,
                'name': 'Nila Roy',
                'email': 'nila@example.com',
              },
            ],
          },
        },
        'vehicle': <String, dynamic>{
          'result': <String, dynamic>{
            'rows': <Map<String, dynamic>>[
              <String, dynamic>{
                'vehicleId': 'veh-22',
                'plateNumber': 'DL01AB1234',
              },
            ],
          },
        },
        'expiry': <String, dynamic>{
          'summary': <String, dynamic>{
            'count': 3,
          },
        },
      },
    });

    expect(details, hasLength(3));

    final userDetail = details.firstWhere((item) => item.type == 'users');
    expect(userDetail.title, 'Nila Roy');
    expect(userDetail.userId, '9');

    final vehicleDetail = details.firstWhere((item) => item.type == 'vehicle');
    expect(vehicleDetail.title, 'DL01AB1234');
    expect(vehicleDetail.vehicleId, 'veh-22');

    final expiryDetail = details.firstWhere((item) => item.type == 'expiry');
    expect(expiryDetail.count, 3);
    expect(expiryDetail.subtitle, '3 events');
  });
}
