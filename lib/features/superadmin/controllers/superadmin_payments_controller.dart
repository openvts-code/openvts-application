import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/superadmin_payments_model.dart';
import '../models/superadmin_payments_state.dart';
import '../services/superadmin_payments_service.dart';

class SuperadminPaymentsController
    extends StateNotifier<SuperadminPaymentsState> {
  SuperadminPaymentsController(this._service)
      : super(const SuperadminPaymentsState.initial());

  final SuperadminPaymentsService _service;
  Timer? _searchDebounce;

  Future<void> loadInitial() async {
    state = state.copyWith(
      refreshKey: _newRefreshKey(),
      page: 1,
      errorMessage: null,
      analyticsErrorMessage: null,
    );

    await Future.wait<void>([
      loadAdmins(),
      loadTransactions(),
      loadAnalytics(),
    ]);
  }

  Future<void> refresh() async {
    state = state.copyWith(
      refreshKey: _newRefreshKey(),
      errorMessage: null,
      analyticsErrorMessage: null,
    );

    await Future.wait<void>([
      loadAdmins(),
      loadTransactions(),
      loadAnalytics(),
    ]);
  }

  Future<void> loadAdmins() async {
    state = state.copyWith(
      isLoadingAdmins: true,
      errorMessage: null,
    );

    try {
      final admins = await _service.getAdmins(
        refreshKey: _currentRefreshKey,
      );

      final selectedAdminId = state.selectedAdminId;
      final hasSelectedAdmin = selectedAdminId != null &&
          admins.any((item) => item.uid == selectedAdminId);

      state = state.copyWith(
        admins: admins,
        selectedAdminId: hasSelectedAdmin ? selectedAdminId : null,
        isLoadingAdmins: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingAdmins: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> loadTransactions() async {
    await _loadTransactions(
      targetPage: state.page,
      append: false,
    );
  }

  Future<void> loadAnalytics() async {
    state = state.copyWith(
      isLoadingAnalytics: true,
      analyticsErrorMessage: null,
    );

    try {
      final range = _resolveRangeQuery();
      final analytics = await _service.getTransactionsAnalytics(
        adminId: _selectedAdminIdAsString,
        from: range.from,
        to: range.to,
        refreshKey: _currentRefreshKey,
      );

      state = state.copyWith(
        analytics: analytics,
        isLoadingAnalytics: false,
        analyticsErrorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingAnalytics: false,
        analyticsErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> setAdminFilter(String? adminId) async {
    final nextAdminId = _parseAdminId(adminId);
    if (nextAdminId == state.selectedAdminId) {
      return;
    }

    state = state.copyWith(
      selectedAdminId: nextAdminId,
      page: 1,
      errorMessage: null,
      analyticsErrorMessage: null,
    );

    await _reloadFilteredData();
  }

  Future<void> setStatusFilter(SuperadminTransactionStatus? status) async {
    if (status == state.selectedStatus) {
      return;
    }

    state = state.copyWith(
      selectedStatus: status,
      page: 1,
      errorMessage: null,
      analyticsErrorMessage: null,
    );

    await _reloadFilteredData();
  }

  void setSearchQuery(String value) {
    state = state.copyWith(
      searchQuery: value,
      page: 1,
      errorMessage: null,
      analyticsErrorMessage: null,
    );

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_reloadFilteredData());
    });
  }

  Future<void> setRangePreset(SuperadminPaymentsRangePreset preset) async {
    if (preset == state.rangePreset &&
        preset != SuperadminPaymentsRangePreset.custom) {
      return;
    }

    state = state.copyWith(
      rangePreset: preset,
      customFrom: preset == SuperadminPaymentsRangePreset.custom
          ? state.customFrom
          : null,
      customTo: preset == SuperadminPaymentsRangePreset.custom
          ? state.customTo
          : null,
      page: 1,
      errorMessage: null,
      analyticsErrorMessage: null,
    );

    await _reloadFilteredData();
  }

  Future<void> setCustomRange(
    DateTime? from,
    DateTime? to,
  ) async {
    DateTime? normalizedFrom = from;
    DateTime? normalizedTo = to;

    if (normalizedFrom != null &&
        normalizedTo != null &&
        normalizedFrom.isAfter(normalizedTo)) {
      final temp = normalizedFrom;
      normalizedFrom = normalizedTo;
      normalizedTo = temp;
    }

    state = state.copyWith(
      rangePreset: SuperadminPaymentsRangePreset.custom,
      customFrom: normalizedFrom,
      customTo: normalizedTo,
      page: 1,
      errorMessage: null,
      analyticsErrorMessage: null,
    );

    await _reloadFilteredData();
  }

  Future<void> loadMore() async {
    if (!state.hasMoreTransactions || state.isLoadingTransactions) {
      return;
    }

    await _loadTransactions(
      targetPage: state.page + 1,
      append: true,
    );
  }

  Future<SuperadminTransaction> recordManualPayment(
    SuperadminRecordPaymentRequest request,
  ) async {
    state = state.copyWith(
      isRecordingPayment: true,
      errorMessage: null,
    );

    try {
      final transaction = await _service.recordManualPayment(request);

      state = state.copyWith(
        isRecordingPayment: false,
        refreshKey: _newRefreshKey(),
      );

      await Future.wait<void>([
        loadTransactions(),
        loadAnalytics(),
      ]);

      return transaction;
    } catch (error) {
      state = state.copyWith(
        isRecordingPayment: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      selectedAdminId: null,
      selectedStatus: null,
      searchQuery: '',
      rangePreset: SuperadminPaymentsRangePreset.thisMonth,
      customFrom: null,
      customTo: null,
      page: 1,
      errorMessage: null,
      analyticsErrorMessage: null,
    );

    await _reloadFilteredData();
  }

  Future<void> _reloadFilteredData() async {
    await Future.wait<void>([
      loadTransactions(),
      loadAnalytics(),
    ]);
  }

  Future<void> _loadTransactions({
    required int targetPage,
    required bool append,
  }) async {
    final page = targetPage < 1 ? 1 : targetPage;

    state = state.copyWith(
      isLoadingTransactions: true,
      errorMessage: null,
    );

    try {
      final range = _resolveRangeQuery();
      final response = await _service.getTransactions(
        adminId: _selectedAdminIdAsString,
        status: state.selectedStatus,
        search: state.searchQuery.trim().isEmpty ? null : state.searchQuery,
        from: range.from,
        to: range.to,
        page: page,
        limit: state.limit,
        refreshKey: _currentRefreshKey,
      );

      final items = append
          ? _mergeTransactions(state.transactions, response.items)
          : response.items;

      state = state.copyWith(
        transactions: items,
        page: response.page <= 0 ? page : response.page,
        limit: response.limit <= 0 ? state.limit : response.limit,
        total: response.total < items.length ? items.length : response.total,
        isLoadingTransactions: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingTransactions: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  List<SuperadminTransaction> _mergeTransactions(
    List<SuperadminTransaction> current,
    List<SuperadminTransaction> incoming,
  ) {
    final merged = <String, SuperadminTransaction>{
      for (final item in current)
        item.id.isEmpty ? _fallbackTransactionKey(item) : item.id: item,
    };

    for (final item in incoming) {
      final key = item.id.isEmpty ? _fallbackTransactionKey(item) : item.id;
      merged[key] = item;
    }

    final values = merged.values.toList(growable: false)
      ..sort((left, right) {
        final leftTime = left.createdAt?.millisecondsSinceEpoch ?? 0;
        final rightTime = right.createdAt?.millisecondsSinceEpoch ?? 0;
        return rightTime.compareTo(leftTime);
      });

    return values;
  }

  String _fallbackTransactionKey(SuperadminTransaction transaction) {
    return [
      transaction.createdAtRaw,
      transaction.amount,
      transaction.reference,
      transaction.providerRef,
    ].join('|');
  }

  int? _parseAdminId(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }

    return parsed;
  }

  _RangeQuery _resolveRangeQuery() {
    final now = DateTime.now();
    switch (state.rangePreset) {
      case SuperadminPaymentsRangePreset.thisMonth:
        final from = DateTime(now.year, now.month, 1);
        return _RangeQuery(
          from: _formatYmd(from),
          to: _formatYmd(now),
        );
      case SuperadminPaymentsRangePreset.last30:
        final from = now.subtract(const Duration(days: 29));
        return _RangeQuery(
          from: _formatYmd(from),
          to: _formatYmd(now),
        );
      case SuperadminPaymentsRangePreset.thisYear:
        final from = DateTime(now.year, 1, 1);
        return _RangeQuery(
          from: _formatYmd(from),
          to: _formatYmd(now),
        );
      case SuperadminPaymentsRangePreset.custom:
        final customFrom = state.customFrom;
        final customTo = state.customTo;
        return _RangeQuery(
          from: customFrom == null ? null : _formatYmd(customFrom),
          to: customTo == null ? null : _formatYmd(customTo),
        );
    }
  }

  String _formatYmd(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String get _currentRefreshKey {
    final refreshKey = state.refreshKey.trim();
    if (refreshKey.isNotEmpty) {
      return refreshKey;
    }

    final next = _newRefreshKey();
    state = state.copyWith(refreshKey: next);
    return next;
  }

  String? get _selectedAdminIdAsString {
    final selected = state.selectedAdminId;
    if (selected == null || selected <= 0) {
      return null;
    }

    return selected.toString();
  }

  String _newRefreshKey() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String _toErrorMessage(Object error) {
    if (error is ArgumentError) {
      final message = error.message?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    if (error is DioException) {
      final responseMessage = _extractResponseMessage(error.response?.data);
      if (responseMessage != null) {
        return responseMessage;
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Please try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server right now.';
      }

      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }

    return raw;
  }

  String? _extractResponseMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in const ['message', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }

        if (value is List) {
          final parts = value
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }

      final nestedData = data['data'];
      if (!identical(nestedData, data)) {
        return _extractResponseMessage(nestedData);
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

class _RangeQuery {
  const _RangeQuery({
    required this.from,
    required this.to,
  });

  final String? from;
  final String? to;
}
