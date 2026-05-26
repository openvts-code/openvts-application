import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../models/admin_payments_model.dart';
import '../models/admin_users_model.dart';

class AdminPaymentsService {
  AdminPaymentsService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = normalReadOptions();

  static final Options _mutationOptions = normalWriteOptions();

  Future<AdminPaymentsPage> getPayments({
    int page = 1,
    int limit = 100,
    String? userId,
    AdminPaymentStatus? status,
    DateTime? from,
    DateTime? to,
    String? refreshKey,
  }) async {
    final query = <String, dynamic>{
      'page': page < 1 ? 1 : page,
      'limit': limit < 1 ? 100 : (limit > 100 ? 100 : limit),
      if ((userId ?? '').trim().isNotEmpty) 'userId': userId!.trim(),
      if (status != null) 'status': status.apiValue,
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
      if ((refreshKey ?? '').trim().isNotEmpty) 'rk': refreshKey!.trim(),
    };

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.adminPayments,
      queryParameters: query,
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminPaymentsPage.fromJson(
      response.data,
      defaultPage: query['page'] as int,
      defaultLimit: query['limit'] as int,
    );
  }

  Future<AdminPaymentsAnalytics> getTransactionsAnalytics({
    String? userId,
    DateTime? from,
    DateTime? to,
    String? refreshKey,
  }) async {
    final query = <String, dynamic>{
      if ((userId ?? '').trim().isNotEmpty) 'userId': userId!.trim(),
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
      if ((refreshKey ?? '').trim().isNotEmpty) 'rk': refreshKey!.trim(),
    };

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.transactionsAnalytics,
      queryParameters: query.isEmpty ? null : query,
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminPaymentsAnalytics.fromJson(response.data);
  }

  Future<List<AdminUserListItem>> getUsers() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.users,
      options: _readOptions,
      parser: (json) => json,
    );

    return parseAdminUsers(response.data);
  }

  Future<List<AdminRenewVehicleOption>> getLinkedVehicles(String userId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.linkedVehiclesByUserId(userId.trim()),
      options: _readOptions,
      parser: (json) => json,
    );

    final list = _extractList(response.data);
    return list
        .map(AdminRenewVehicleOption.fromJson)
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<void> renewVehicles(AdminRenewPaymentRequest request) async {
    await _apiClient.post<void>(
      ApiEndpoints.admin.renewVehiclesPayment,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  List<dynamic> _extractList(dynamic json) {
    if (json is List) return json;
    if (json is Map<String, dynamic>) {
      final data = json['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        for (final key in const ['items', 'vehicles', 'data']) {
          final value = data[key];
          if (value is List) return value;
        }
      }
      for (final key in const ['items', 'vehicles']) {
        final value = json[key];
        if (value is List) return value;
      }
    }
    return const <dynamic>[];
  }
}
