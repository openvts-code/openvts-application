import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/superadmin/models/superadmin_administrator_model.dart';

void main() {
  test('parses administrators from live-style payload keys', () {
    final page = SuperadminAdministratorPage.fromJson(<String, dynamic>{
      'rows': <Map<String, dynamic>>[
        <String, dynamic>{
          'uid': 34,
          'Name': 'Daniel',
          'username': 'Daniel',
          'email': 'daniel125@gmail.com',
          'companyName': 'Open VTS',
          'mobile_prefix': '+93',
          'mobile': '546345625',
          'countrycode': 'AU',
          'credits': 20,
          'totalvehicles': 0,
          'status': true,
          'Lastlogin': null,
        },
        <String, dynamic>{
          'uid': 2,
          'Name': 'mukesh Kumar',
          'username': 'admin',
          'email': 'shashankrajput656@gmail.com',
          'companyName': 'Open VTS',
          'mobile_prefix': '+91',
          'mobile': '9999999999',
          'countrycode': 'IN',
          'credits': 1989,
          'totalvehicles': 10,
          'status': true,
          'Lastlogin': '2026-05-14T09:42:35.047Z',
        },
      ],
      'count': 17,
    });

    expect(page.totalCount, 17);
    expect(page.items, hasLength(2));

    final first = page.items.first;
    expect(first.id, '34');
    expect(first.name, 'Daniel');
    expect(first.companyName, 'Open VTS');
    expect(first.phoneDisplay, '+93 546345625');
    expect(first.countryCode, 'AU');
    expect(first.totalVehicles, 0);
    expect(first.totalCredits, 20);
    expect(first.lastLoginAt, isNull);

    final second = page.items.last;
    expect(second.id, '2');
    expect(second.roleLabel, 'Admin');
    expect(second.name, 'mukesh Kumar');
    expect(second.totalVehicles, 10);
    expect(second.totalCredits, 1989);
    expect(second.lastLoginAt, isNotNull);
  });

  test('falls back to username, list counts, and human-readable login strings', () {
    final page = SuperadminAdministratorPage.fromJson(<String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          '_id': 'admin-2',
          'username': 'Daniel',
          'email': 'daniel125@gmail.com',
          'role': 'ADMIN',
          'companyName': 'Open VTS',
          'country': 'Australia',
          'state': 'Australian Capital Territory',
          'credits': '12',
          'vehicles': <Map<String, dynamic>>[
            <String, dynamic>{'id': 1},
          ],
          'users': <Map<String, dynamic>>[
            <String, dynamic>{'id': 1},
            <String, dynamic>{'id': 2},
          ],
          'lastLogin': '12 May 2026 • 11:38',
          'status': 'active',
        },
      ],
    });

    final administrator = page.items.single;

    expect(administrator.name, 'Daniel');
    expect(administrator.totalVehicles, 1);
    expect(administrator.totalUsers, 2);
    expect(administrator.totalCredits, 12);
    expect(administrator.lastLoginAt, isNotNull);
    expect(administrator.isActive, isTrue);
  });

  test('parses nested profile names, nested counters, and raw login text', () {
    final administrator = SuperadminAdministrator.fromJson(<String, dynamic>{
      '_id': 'admin-3',
      'profile': <String, dynamic>{
        'firstName': 'Rashid',
        'lastName': 'Khan',
      },
      'vehicles': <String, dynamic>{
        'count': 7,
      },
      'credits': <String, dynamic>{
        'availableCredits': '15',
      },
      'lastLogin': 'Yesterday at 10:42 PM',
    });

    expect(administrator.name, 'Rashid Khan');
    expect(administrator.totalVehicles, 7);
    expect(administrator.totalCredits, 15);
    expect(administrator.lastLoginAt, isNull);
    expect(administrator.lastLoginText, 'Yesterday at 10:42 PM');
  });

  test('parses device aliases and nested date objects for admin hydration', () {
    final administrator = SuperadminAdministrator.fromJson(<String, dynamic>{
      '_id': 'admin-4',
      'name': 'Device-backed admin',
      'deviceCount': 6,
      'lastLogin': <String, dynamic>{
        r'$date': '2026-05-12T11:38:00.000Z',
      },
    });

    expect(administrator.totalVehicles, 6);
    expect(administrator.lastLoginAt, isNotNull);
  });
}