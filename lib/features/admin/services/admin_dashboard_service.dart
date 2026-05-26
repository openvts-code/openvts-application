import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../../../core/config/app_config.dart';
import '../models/admin_dashboard_model.dart';

class AdminDashboardService {
  AdminDashboardService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = normalReadOptions();

  Future<AdminDashboardSummary> getDashboardSummary({
    String? currency,
    int months = 12,
    int listLimit = 10,
    String? refreshKey,
  }) async {
    if (AppConfig.useMockData) {
      return AdminDashboardSummary.fromJson(
        _mockDashboardSummary(currency ?? 'INR', months: months),
      );
    }

    final response = await _apiClient.get<AdminDashboardSummary>(
      ApiEndpoints.admin.dashboardSummary,
      queryParameters: <String, dynamic>{
        if (refreshKey != null && refreshKey.trim().isNotEmpty)
          'rk': refreshKey.trim(),
        if (currency != null && currency.trim().isNotEmpty)
          'currency': currency.trim().toUpperCase(),
        'months': months,
        'listLimit': listLimit,
      },
      options: _readOptions,
      parser: AdminDashboardSummary.fromJson,
    );

    return response.data;
  }

  Map<String, dynamic> _mockDashboardSummary(
    String selectedCurrency, {
    required int months,
  }) {
    final now = DateTime.now().toUtc();
    final code = selectedCurrency.trim().toUpperCase();
    final isInr = code == 'INR';

    return <String, dynamic>{
      'generatedAt': now.toIso8601String(),
      'selectedCurrency': code,
      'defaultCurrency': 'INR',
      'availableCurrencies': const <String>['INR', 'USD'],
      'currency': code,
      'totals': const <String, dynamic>{
        'totalVehicles': 86,
        'totalUsers': 19,
      },
      'revenue': <String, dynamic>{
        'lastMonthRevenue': isInr ? 1845000 : 22140,
        'thisMonthRevenue': isInr ? 1268000 : 15216,
        'pendingAmount': isInr ? 248000 : 2976,
        'pendingCount': 7,
        'expectedRenewalRevenue': isInr ? 410000 : 4920,
        'projectedThisMonth': isInr ? 1678000 : 20136,
      },
      'expiry': <String, dynamic>{
        'thisWeek': 5,
        'thisMonth': 18,
        'preview': <Map<String, dynamic>>[
          _mockExpiryVehicle(
            id: 41,
            name: 'Truck 12',
            plateNumber: 'MH 12 TX 1984',
            imei: '865123456789012',
            userId: 7,
            userName: 'Daniel',
            planId: 2,
            planName: 'Premium',
            price: isInr ? 7500 : 90,
            currency: code,
            expiry: now.add(const Duration(days: 3)),
          ),
          _mockExpiryVehicle(
            id: 42,
            name: 'Car 7',
            plateNumber: 'KA 05 MR 7712',
            imei: '865123456789013',
            userId: 8,
            userName: 'Robert Hook',
            planId: 3,
            planName: 'Fleet',
            price: isInr ? 12000 : 144,
            currency: code,
            expiry: now.add(const Duration(days: 6)),
          ),
        ],
      },
      'installs': const <String, dynamic>{
        'thisMonth': 12,
      },
      'vehicleLiveStatus': const <String, dynamic>{
        'all': 76,
        'connected': 54,
        'running': 24,
        'stop': 18,
        'inactive': 4,
        'noData': 10,
        'noDevice': 10,
      },
      'graph': _mockGraph(now, months),
      'graphMeta': <String, dynamic>{
        'months': months,
        'rangeStartISO':
            DateTime.utc(now.year, now.month - months + 1, 1).toIso8601String(),
        'rangeEndISO': now.toIso8601String(),
      },
      'topClients': <Map<String, dynamic>>[
        _mockTopClient(now, 7, 'Daniel', isInr ? 420000 : 5040,
            isInr ? 45000 : 540, 18, 1),
        _mockTopClient(now, 8, 'Robert Hook', isInr ? 310000 : 3720, 0, 12, 3),
        _mockTopClient(now, 9, 'Prerna Verma', isInr ? 260000 : 3120,
            isInr ? 18000 : 216, 9, 6),
      ],
      'recent': <String, dynamic>{
        'users': <Map<String, dynamic>>[
          _mockUser(now, 7, 'Daniel', 'daniel', 'daniel125@gmail.com', 8, true),
          _mockUser(now, 8, 'Robert Hook', 'roberthook', 'robert@example.com',
              24, true),
          _mockUser(now, 9, 'Prerna Verma', 'prerna', 'prerna@example.com', 144,
              false),
        ],
        'vehicles': <Map<String, dynamic>>[
          _mockRecentVehicle(
            now: now,
            id: 41,
            name: 'Truck 12',
            plateNumber: 'MH 12 TX 1984',
            imei: '865123456789012',
            deviceId: 3,
            userId: 7,
            userName: 'Daniel',
            liveStatus: 'RUNNING',
            hasDevice: true,
            ageHours: 3,
            expiryDays: 3,
          ),
          _mockRecentVehicle(
            now: now,
            id: 42,
            name: 'Car 7',
            plateNumber: 'KA 05 MR 7712',
            imei: '865123456789013',
            deviceId: 4,
            userId: 8,
            userName: 'Robert Hook',
            liveStatus: 'STOP',
            hasDevice: true,
            ageHours: 24,
            expiryDays: 6,
          ),
          _mockRecentVehicle(
            now: now,
            id: 43,
            name: 'Hatchback 1',
            plateNumber: 'DL 09 AK 4411',
            imei: null,
            deviceId: null,
            userId: 9,
            userName: 'Prerna Verma',
            liveStatus: 'NOT_INSTALLED',
            hasDevice: false,
            ageHours: 48,
            expiryDays: 18,
          ),
        ],
        'payments': <Map<String, dynamic>>[
          _mockPayment(
              now,
              2001,
              isInr ? '7512' : '90',
              code,
              'SUCCESS',
              'PAY-2001',
              7,
              'Daniel',
              'daniel',
              41,
              'Truck 12',
              'MH 12 TX 1984',
              6),
          _mockPayment(
              now,
              2002,
              isInr ? '5640' : '68',
              code,
              'PENDING',
              'PAY-2002',
              8,
              'Robert Hook',
              'roberthook',
              42,
              'Car 7',
              'KA 05 MR 7712',
              24),
          _mockPayment(now, 2003, isInr ? '100000' : '1200', code, 'SUCCESS',
              'PAY-2003', 9, 'Prerna Verma', 'prerna', null, null, null, 96),
        ],
      },
    };
  }

  Map<String, dynamic> _mockExpiryVehicle({
    required int id,
    required String name,
    required String plateNumber,
    required String imei,
    required int userId,
    required String userName,
    required int planId,
    required String planName,
    required num price,
    required String currency,
    required DateTime expiry,
  }) {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'plateNumber': plateNumber,
      'imei': imei,
      'secondaryExpiry': expiry.toIso8601String(),
      'primaryUserId': userId,
      'userPrimary': <String, dynamic>{'uid': userId, 'name': userName},
      'plan': <String, dynamic>{
        'id': planId,
        'name': planName,
        'price': price,
        'currency': currency,
      },
    };
  }

  List<Map<String, dynamic>> _mockGraph(DateTime now, int months) {
    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return List<Map<String, dynamic>>.generate(months, (index) {
      final date = DateTime.utc(now.year, now.month - months + 1 + index, 1);
      return <String, dynamic>{
        'month': monthNames[date.month - 1],
        'year': date.year,
        'userCount': 8 + index,
        'vehicleCount': 22 + (index * 5),
      };
    });
  }

  Map<String, dynamic> _mockTopClient(
    DateTime now,
    int userId,
    String name,
    num revenue,
    num due,
    int vehicles,
    int daysAgo,
  ) {
    return <String, dynamic>{
      'userId': userId,
      'name': name,
      'revenue': revenue,
      'due': due,
      'vehicles': vehicles,
      'lastPaymentAt': now.subtract(Duration(days: daysAgo)).toIso8601String(),
    };
  }

  Map<String, dynamic> _mockUser(
    DateTime now,
    int uid,
    String name,
    String username,
    String email,
    int ageHours,
    bool isActive,
  ) {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'username': username,
      'email': email,
      'createdAt': now.subtract(Duration(hours: ageHours)).toIso8601String(),
      'isActive': isActive,
    };
  }

  Map<String, dynamic> _mockRecentVehicle({
    required DateTime now,
    required int id,
    required String name,
    required String plateNumber,
    required String? imei,
    required int? deviceId,
    required int userId,
    required String userName,
    required String liveStatus,
    required bool hasDevice,
    required int ageHours,
    required int expiryDays,
  }) {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'plateNumber': plateNumber,
      'imei': imei,
      'deviceId': deviceId,
      'createdAt': now.subtract(Duration(hours: ageHours)).toIso8601String(),
      'secondaryExpiry': now.add(Duration(days: expiryDays)).toIso8601String(),
      'isLicenseBlocked': false,
      'licenseBlockedAt': null,
      'licenseBlockReason': null,
      'primaryUserId': userId,
      'userPrimary': <String, dynamic>{'uid': userId, 'name': userName},
      'liveStatus': liveStatus,
      'hasDevice': hasDevice,
    };
  }

  Map<String, dynamic> _mockPayment(
    DateTime now,
    int id,
    String amount,
    String currency,
    String status,
    String reference,
    int userId,
    String userName,
    String username,
    int? vehicleId,
    String? vehicleName,
    String? plateNumber,
    int ageHours,
  ) {
    return <String, dynamic>{
      'id': id,
      'amount': amount,
      'currency': currency,
      'status': status,
      'createdAt': now.subtract(Duration(hours: ageHours)).toIso8601String(),
      'reference': reference,
      'fromUser': <String, dynamic>{
        'uid': userId,
        'name': userName,
        'username': username,
      },
      'vehicle': vehicleId == null
          ? null
          : <String, dynamic>{
              'id': vehicleId,
              'name': vehicleName,
              'plateNumber': plateNumber,
            },
    };
  }
}
