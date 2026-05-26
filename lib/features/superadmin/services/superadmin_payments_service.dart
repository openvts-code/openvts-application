import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/superadmin_payments_model.dart';

class SuperadminPaymentsService {
  SuperadminPaymentsService(this._apiClient);

  static const int _maxLimit = 100;
  static const int _maxAmountLength = 12;
  static const int _maxReferenceLength = 100;

  static final RegExp _amountPattern = RegExp(r'^\d+(\.\d{1,2})?$');
  static final RegExp _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static const Set<String> _allowedPaymentModes = <String>{
    'CASH',
    'UPI',
    'BANK_TRANSFER',
    'CARD',
    'RAZORPAY',
    'STRIPE',
    'WALLET',
    'OTHER',
  };

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );

  static final Options _mutationOptions = Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  );

  final ApiClient _apiClient;

  Future<List<SuperadminPaymentAdminOption>> getAdmins({
    String? refreshKey,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.adminList,
      queryParameters: <String, dynamic>{
        'rk': _resolveRefreshKey(refreshKey),
      },
      options: _readOptions,
      parser: (json) => json,
    );

    return parseSuperadminPaymentAdminOptions(response.data);
  }

  Future<SuperadminTransactionPage> getTransactions({
    String? adminId,
    SuperadminTransactionStatus? status,
    String? search,
    String? from,
    String? to,
    int page = 1,
    int limit = _maxLimit,
    String? refreshKey,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedLimit = _normalizeLimit(limit);
    final normalizedAdminId = adminId?.trim() ?? '';
    final normalizedSearch = search?.trim() ?? '';
    final normalizedFrom = _normalizeDateFilter(
      from,
      fieldName: 'from',
    );
    final normalizedTo = _normalizeDateFilter(
      to,
      fieldName: 'to',
    );

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.transactions,
      queryParameters: <String, dynamic>{
        'page': normalizedPage,
        'limit': normalizedLimit,
        'rk': _resolveRefreshKey(refreshKey),
        if (normalizedAdminId.isNotEmpty) 'adminId': normalizedAdminId,
        if (status != null) 'status': status.apiValue,
        if (normalizedSearch.isNotEmpty) 'q': normalizedSearch,
        if (normalizedFrom.isNotEmpty) 'from': normalizedFrom,
        if (normalizedTo.isNotEmpty) 'to': normalizedTo,
      },
      options: _readOptions,
      parser: (json) => json,
    );

    return SuperadminTransactionPage.fromJson(
      response.data,
      defaultPage: normalizedPage,
      defaultLimit: normalizedLimit,
    );
  }

  Future<SuperadminTransactionsAnalytics> getTransactionsAnalytics({
    String? adminId,
    String? from,
    String? to,
    String? refreshKey,
  }) async {
    final normalizedAdminId = adminId?.trim() ?? '';
    final normalizedFrom = _normalizeDateFilter(
      from,
      fieldName: 'from',
    );
    final normalizedTo = _normalizeDateFilter(
      to,
      fieldName: 'to',
    );

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.transactionsAnalytics,
      queryParameters: <String, dynamic>{
        'rk': _resolveRefreshKey(refreshKey),
        if (normalizedAdminId.isNotEmpty) 'adminId': normalizedAdminId,
        if (normalizedFrom.isNotEmpty) 'from': normalizedFrom,
        if (normalizedTo.isNotEmpty) 'to': normalizedTo,
      },
      options: _readOptions,
      parser: (json) => json,
    );

    return SuperadminTransactionsAnalytics.fromJson(response.data);
  }

  Future<SuperadminTransaction> recordManualPayment(
    SuperadminRecordPaymentRequest request,
  ) async {
    _validateRecordPaymentRequest(request);

    final normalizedAmount = request.amount.trim();
    final normalizedReference = request.reference?.trim();

    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.superadmin.recordManualTransaction,
      data: <String, dynamic>{
        'adminId': request.adminId,
        'amount': normalizedAmount,
        'paymentMode': request.paymentMode.apiValue,
        if (normalizedReference != null && normalizedReference.isNotEmpty)
          'reference': normalizedReference,
      },
      options: _mutationOptions,
      parser: (json) => json,
    );

    return SuperadminRecordPaymentResult.fromJson(response.data).transaction;
  }

  void _validateRecordPaymentRequest(SuperadminRecordPaymentRequest request) {
    if (request.adminId <= 0) {
      throw ArgumentError('Please select a valid administrator.');
    }

    final normalizedAmount = request.amount.trim();
    if (normalizedAmount.isEmpty) {
      throw ArgumentError('Amount is required.');
    }

    if (normalizedAmount.length > _maxAmountLength) {
      throw ArgumentError('Amount must be $_maxAmountLength characters or less.');
    }

    if (!_amountPattern.hasMatch(normalizedAmount)) {
      throw ArgumentError('Amount must be a valid decimal with up to 2 places.');
    }

    final parsedAmount = num.tryParse(normalizedAmount);
    if (parsedAmount == null || parsedAmount <= 0) {
      throw ArgumentError('Amount must be greater than 0.');
    }

    final reference = request.reference?.trim() ?? '';
    if (reference.length > _maxReferenceLength) {
      throw ArgumentError(
        'Reference must be $_maxReferenceLength characters or less.',
      );
    }

    final paymentMode = request.paymentMode.apiValue;
    if (!_allowedPaymentModes.contains(paymentMode)) {
      throw ArgumentError('Invalid payment mode.');
    }
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

  String _normalizeDateFilter(
    String? value, {
    required String fieldName,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '';
    }

    if (!_datePattern.hasMatch(normalized)) {
      throw ArgumentError('$fieldName must use YYYY-MM-DD format.');
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
