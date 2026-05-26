import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../models/user_transactions_model.dart';

class UserTransactionsService {
  UserTransactionsService(this._apiClient);

  static const int _maxLimit = 100;

  static final Options _readOptions = normalReadOptions();

  final ApiClient _apiClient;

  Future<UserTransactionPage> getTransactions({
    UserTransactionStatus? status,
    String? search,
    String? from,
    String? to,
    int page = 1,
    int limit = 100,
    String? refreshKey,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedLimit = _normalizeLimit(limit);
    final normalizedSearch = search?.trim() ?? '';
    final normalizedFrom = _normalizeDateFilter(from, fieldName: 'from');
    final normalizedTo = _normalizeDateFilter(to, fieldName: 'to');

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.user.transactions,
      queryParameters: <String, dynamic>{
        'page': normalizedPage,
        'limit': normalizedLimit,
        'rk': _resolveRefreshKey(refreshKey),
        if (status != null) 'status': status.apiValue,
        if (normalizedSearch.isNotEmpty) 'q': normalizedSearch,
        if (normalizedFrom != null) 'from': normalizedFrom,
        if (normalizedTo != null) 'to': normalizedTo,
      },
      options: _readOptions,
      parser: (json) => json,
    );

    return UserTransactionPage.fromJson(
      response.data,
      defaultPage: normalizedPage,
      defaultLimit: normalizedLimit,
    );
  }

  int _normalizeLimit(int value) {
    if (value <= 0) {
      return _maxLimit;
    }

    if (value > _maxLimit) {
      return _maxLimit;
    }

    return value;
  }

  String? _normalizeDateFilter(
    String? value, {
    required String fieldName,
  }) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    if (DateTime.tryParse(normalized) == null) {
      throw ArgumentError('$fieldName must use a valid ISO date format.');
    }

    return normalized;
  }

  String _resolveRefreshKey(String? refreshKey) {
    final normalized = refreshKey?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }

    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
