import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/superadmin/models/superadmin_dashboard_model.dart';

void main() {
  test('parses superadmin overview counts from live backend shape', () {
    final model = SuperadminDashboardModel.fromSources(
      overview: <String, dynamic>{
        'totalCounts': <String, dynamic>{
          'totalAdmins': 17,
          'totalVehicles': 10,
          'activeVehicles': 10,
          'totalUsers': 9,
          'licensedCredits': 2914018,
          'usedCredits': 0,
          'vehicleLiveStatus': <String, dynamic>{
            'all': 10,
            'connected': 0,
            'running': 0,
            'stop': 3,
            'inactive': 1,
            'noData': 6,
          },
        },
        'recentVehicles': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 11,
            'name': 'Car 7',
            'imei': '12345678669012346',
            'vehicleType': <String, dynamic>{
              'name': 'Car',
              'slug': 'car',
            },
            'createdAt': '2026-05-04T09:50:40.176Z',
          },
        ],
        'recentUsers': <Map<String, dynamic>>[
          <String, dynamic>{
            'uid': 34,
            'name': 'Daniel',
            'email': 'daniel125@gmail.com',
            'createdAt': '2026-05-13T10:48:04.437Z',
          },
        ],
        'adoptionGraph': <Map<String, dynamic>>[
          <String, dynamic>{
            'month': 'May',
            'year': 2026,
            'userCount': 5,
            'vehicleCount': 6,
            'licensesAssigned': 2911868,
            'licensesUsed': 0,
          },
        ],
        'latestTransactions': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 36,
            'amount': 7512,
            'currency': 'INR',
            'status': 'SUCCESS',
            'createdAt': '2026-05-13T11:21:00.030Z',
            'fromUser': <String, dynamic>{
              'uid': 34,
              'name': 'Daniel',
              'username': 'Daniel',
              'email': 'daniel125@gmail.com',
            },
          },
        ],
      },
      activityLogs: <String, dynamic>{
        'items': <Map<String, dynamic>>[],
      },
      actors: <Map<String, dynamic>>[],
    );

    expect(model.counts.totalAdmins, 17);
    expect(model.counts.totalVehicles, 10);
    expect(model.counts.activeVehicles, 10);
    expect(model.counts.totalUsers, 9);
    expect(model.counts.licensesIssued, 2914018);
    expect(model.counts.licensesUsed, 0);

    expect(model.vehicleStatus.totalDevices, 10);
    expect(model.vehicleStatus.stopCount, 3);
    expect(model.vehicleStatus.noDataCount, 6);

    expect(model.recentVehicles.single.subtitle, 'Car');
    expect(model.recentUsers.single.id, '34');
    expect(model.adoptionGrowth.single.label, 'May\'26');
    expect(model.adoptionGrowth.single.licenses, 2911868);
    expect(model.transactions.single.title, 'Daniel (@Daniel)');
  });
}