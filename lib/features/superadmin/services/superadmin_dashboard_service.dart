import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../models/superadmin_dashboard_model.dart';

class SuperadminDashboardService {
  SuperadminDashboardService(this._apiClient);

  final ApiClient _apiClient;

  static const int activityLogPageSize = 20;

  Future<SuperadminDashboardModel> getDashboard() async {
    if (AppConfig.useMockData) {
      return SuperadminDashboardModel.fromSources(
        overview: <String, dynamic>{
          'allAdmins': 17,
          'totalVehicles': 10,
          'activeVehicle': 10,
          'totalUsers': 9,
          'licenseIssued': 2914018,
          'licenseUsed': 0,
          'adoptionGrowth': <Map<String, dynamic>>[
            {'label': 'Jun\'25', 'vehicles': 0, 'users': 0, 'licenses': 0},
            {'label': 'Jul\'25', 'vehicles': 0, 'users': 0, 'licenses': 0},
            {'label': 'Aug\'25', 'vehicles': 0, 'users': 0, 'licenses': 0},
            {'label': 'Sep\'25', 'vehicles': 0, 'users': 0, 'licenses': 0},
            {'label': 'Oct\'25', 'vehicles': 0, 'users': 0, 'licenses': 0},
            {'label': 'Nov\'25', 'vehicles': 0, 'users': 0, 'licenses': 0},
            {'label': 'Dec\'25', 'vehicles': 0, 'users': 0, 'licenses': 0},
            {'label': 'Jan\'26', 'vehicles': 0, 'users': 0, 'licenses': 0},
            {'label': 'Feb\'26', 'vehicles': 0, 'users': 0, 'licenses': 0},
            {'label': 'Mar\'26', 'vehicles': 0, 'users': 0, 'licenses': 0},
            {'label': 'Apr\'26', 'vehicles': 0, 'users': 0, 'licenses': 350000},
            {'label': 'May\'26', 'vehicles': 10, 'users': 9, 'licenses': 2914018},
          ],
          'vehicleStatus': <String, dynamic>{
            'totalDevices': 10,
            'connected': 2,
            'running': 0,
            'stop': 3,
            'inactive': 1,
            'noData': 6,
          },
          'recentVehicles': <Map<String, dynamic>>[
            {
              'id': 'car-7-a',
              'name': 'Car 7',
              'type': 'Car',
              'status': 'Active',
              'updatedAt': '2026-05-04T10:00:00Z',
            },
            {
              'id': 'car-7-b',
              'name': 'Car 7',
              'type': 'Car',
              'status': 'Active',
              'updatedAt': '2026-05-04T10:00:00Z',
            },
            {
              'id': 'truck-12',
              'name': 'Truck 12',
              'type': 'Truck',
              'status': 'Active',
              'updatedAt': '2026-05-04T10:00:00Z',
            },
            {
              'id': 'car-long',
              'name': 'sisivikdyvkfvnfkdnfkdki',
              'type': 'Car',
              'status': 'Active',
              'updatedAt': '2026-05-04T10:00:00Z',
            },
            {
              'id': 'hatch-1',
              'name': 'jfsdofhsishsi',
              'type': 'Hatchback',
              'status': 'Active',
              'updatedAt': '2026-05-04T10:00:00Z',
            },
            {
              'id': 'hatch-2',
              'name': 'zojcdsvjidfiji',
              'type': 'Hatchback',
              'status': 'Active',
              'updatedAt': '2026-05-04T10:00:00Z',
            },
          ],
          'transactions': <Map<String, dynamic>>[
            {
              'id': 'txn-1',
              'title': 'Daniel (@Daniel)',
              'subtitle': 'yesterday',
              'amount': 7512,
              'currency': 'INR',
              'status': 'Success',
              'createdAt': '2026-05-13T12:00:00Z',
            },
            {
              'id': 'txn-2',
              'title': 'Daniel (@Daniel)',
              'subtitle': 'yesterday',
              'amount': 564,
              'currency': 'INR',
              'status': 'Success',
              'createdAt': '2026-05-13T11:00:00Z',
            },
            {
              'id': 'txn-3',
              'title': 'wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww (@jjdjdjsmsksksksmd)',
              'subtitle': '6d ago',
              'amount': 1000000,
              'currency': 'INR',
              'status': 'Success',
              'createdAt': '2026-05-08T11:00:00Z',
            },
            {
              'id': 'txn-4',
              'title': 'Prerna Verma (@vkflojfobjfggg)',
              'subtitle': '6d ago',
              'amount': 1000000,
              'currency': 'INR',
              'status': 'Success',
              'createdAt': '2026-05-08T09:00:00Z',
            },
            {
              'id': 'txn-5',
              'title': 'prachi (@bkbgkbkbgkbk)',
              'subtitle': '6d ago',
              'amount': 1000,
              'currency': 'INR',
              'status': 'Success',
              'createdAt': '2026-05-08T08:00:00Z',
            },
          ],
          'recentUsers': <Map<String, dynamic>>[
            {
              'id': 'user-1',
              'name': 'Daniel',
              'email': 'daniel125@gmail.com',
              'createdAt': '2026-05-13T12:00:00Z',
              'initials': 'D',
            },
            {
              'id': 'user-2',
              'name': 'ROBERT HOOK',
              'email': 'roberthook@gmail.com',
              'createdAt': '2026-05-13T10:00:00Z',
              'initials': 'RH',
            },
            {
              'id': 'user-3',
              'name': 'prachi',
              'email': 'prachi@g.hh',
              'createdAt': '2026-05-07T10:00:00Z',
              'initials': 'P',
            },
            {
              'id': 'user-4',
              'name': 'Prerna Verma',
              'email': 'prernaverma2910@gmail.commmmm',
              'createdAt': '2026-05-07T10:00:00Z',
              'initials': 'PV',
            },
          ],
        },
        activityLogs: <String, dynamic>{
          'items': <Map<String, dynamic>>[
            {
              'id': 'log-1',
              'title': 'Login Auth #1',
              'actorName': 'Mukesh Kumar',
              'actorRole': 'SUPERADMIN',
              'createdAt': '2026-05-14T11:55:00Z',
            },
            {
              'id': 'log-2',
              'title': 'Create Geocoding',
              'actorName': 'Mukesh Kumar',
              'actorRole': 'SUPERADMIN',
              'createdAt': '2026-05-14T11:01:00Z',
            },
            {
              'id': 'log-3',
              'title': 'Create Policy',
              'actorName': 'Mukesh Kumar',
              'actorRole': 'SUPERADMIN',
              'createdAt': '2026-05-14T09:00:00Z',
            },
          ],
        },
        actors: <Map<String, dynamic>>[
          {'id': 1, 'name': 'Mukesh Kumar'},
          {'id': 2, 'name': 'Daniel'},
        ],
      );
    }

    final refreshKey = DateTime.now().millisecondsSinceEpoch.toString();

    final results = await Future.wait<dynamic>([
      _fetchDashboardOverview(refreshKey),
      _fetchActivityLogs(
        limit: activityLogPageSize,
        refreshKey: refreshKey,
      ),
      _fetchAdminList(),
    ]);

    return SuperadminDashboardModel.fromSources(
      overview: results[0],
      activityLogs: results[1],
      actors: results[2],
    );
  }

  Future<dynamic> fetchActivityLogs({
    int limit = activityLogPageSize,
    int? cursorId,
    int? actorId,
    DateTime? from,
    DateTime? to,
    String? refreshKey,
  }) {
    return _fetchActivityLogs(
      limit: limit,
      cursorId: cursorId,
      actorId: actorId,
      from: from,
      to: to,
      refreshKey: refreshKey,
    );
  }

  Future<List<SuperadminActorOption>> fetchActivityActors() async {
    final data = await _fetchAdminList();
    return SuperadminActorOption.listFromJson(data);
  }

  Future<dynamic> _fetchDashboardOverview(String refreshKey) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.dashboardOverview,
      queryParameters: <String, dynamic>{
        'rk': refreshKey,
      },
      parser: (json) => json,
    );
    return response.data;
  }

  Future<dynamic> _fetchAdminList() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.adminList,
      parser: (json) => json,
    );
    return response.data;
  }

  Future<dynamic> _fetchActivityLogs({
    required int limit,
    int? cursorId,
    int? actorId,
    DateTime? from,
    DateTime? to,
    String? refreshKey,
  }) async {
    final queryParameters = <String, dynamic>{
      'limit': limit,
    };

    if (cursorId != null) {
      queryParameters['cursorId'] = cursorId;
    } else {
      if (actorId != null) {
        queryParameters['actorId'] = actorId;
      }
      if (from != null) {
        queryParameters['from'] = from.toUtc().toIso8601String();
      }
      if (to != null) {
        queryParameters['to'] = to.toUtc().toIso8601String();
      }
      queryParameters['rk'] =
          refreshKey ?? DateTime.now().millisecondsSinceEpoch.toString();
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.dashboardActivityLogs,
      queryParameters: queryParameters,
      parser: (json) => json,
    );
    return response.data;
  }
}
