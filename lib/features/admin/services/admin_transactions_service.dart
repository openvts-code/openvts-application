import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/admin_transactions_model.dart';

class AdminTransactionsService {
  AdminTransactionsService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );

  Future<AdminTransactionPage> getTransactions({
    int page = 1,
    int limit = 100,
    AdminTransactionStatus? status,
    String? search,
    DateTime? from,
    DateTime? to,
    String? refreshKey,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedLimit = limit > 100 ? 100 : (limit < 1 ? 100 : limit);

    final query = <String, dynamic>{
      'page': normalizedPage,
      'limit': normalizedLimit,
      if (status != null) 'status': status.apiValue,
      if ((search ?? '').trim().isNotEmpty) 'q': search!.trim(),
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
      if ((refreshKey ?? '').trim().isNotEmpty) 'rk': refreshKey!.trim(),
    };

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.transactions,
      queryParameters: query,
      options: _readOptions,
      parser: (json) => json,
    );

    return AdminTransactionPage.fromJson(
      response.data,
      defaultPage: normalizedPage,
      defaultLimit: normalizedLimit,
    );
  }
}
