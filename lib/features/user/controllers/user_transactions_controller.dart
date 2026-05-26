import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_transactions_model.dart';
import '../models/user_transactions_state.dart';
import '../services/user_transactions_service.dart';

class UserTransactionsController extends StateNotifier<UserTransactionsState> {
  UserTransactionsController({required UserTransactionsService service})
      : _service = service,
        super(const UserTransactionsState.initial());

  final UserTransactionsService _service;
  Timer? _searchDebounce;

  Future<void> loadInitial() async {
    state = state.copyWith(
      page: 1,
      refreshKey: _newRefreshKey(),
      errorMessage: null,
    );

    await _loadTransactions(
      targetPage: 1,
      append: false,
      isRefresh: false,
    );
  }

  Future<void> loadTransactions() async {
    await _loadTransactions(
      targetPage: 1,
      append: false,
      isRefresh: false,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(
      page: 1,
      refreshKey: _newRefreshKey(),
      errorMessage: null,
    );

    await _loadTransactions(
      targetPage: 1,
      append: false,
      isRefresh: true,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isRefreshing) {
      return;
    }

    await _loadTransactions(
      targetPage: state.page + 1,
      append: true,
      isRefresh: false,
    );
  }

  Future<void> setStatusFilter(UserTransactionStatus? status) async {
    if (status == state.selectedStatus) {
      return;
    }

    state = state.copyWith(
      selectedStatus: status,
      page: 1,
      errorMessage: null,
    );

    await loadTransactions();
  }

  void setPaymentModeFilter(UserPaymentMode? mode) {
    if (mode == state.selectedPaymentMode) {
      return;
    }

    state = state.copyWith(
      selectedPaymentMode: mode,
      errorMessage: null,
    );
  }

  void setPaymentTypeFilter(String? type) {
    final normalized = type?.trim();
    final nextType = (normalized == null || normalized.isEmpty)
        ? null
        : normalized.toUpperCase();

    if (nextType == state.selectedPaymentType) {
      return;
    }

    state = state.copyWith(
      selectedPaymentType: nextType,
      errorMessage: null,
    );
  }

  void setSearchQuery(String value) {
    state = state.copyWith(
      searchQuery: value,
      page: 1,
      errorMessage: null,
    );

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }

      unawaited(loadTransactions());
    });
  }

  Future<void> setRangePreset(UserTransactionsRangePreset preset) async {
    if (preset == state.rangePreset &&
        preset != UserTransactionsRangePreset.custom) {
      return;
    }

    state = state.copyWith(
      rangePreset: preset,
      customFrom: preset == UserTransactionsRangePreset.custom
          ? state.customFrom
          : null,
      customTo:
          preset == UserTransactionsRangePreset.custom ? state.customTo : null,
      page: 1,
      errorMessage: null,
    );

    await loadTransactions();
  }

  Future<void> setCustomRange(DateTime? from, DateTime? to) async {
    DateTime? normalizedFrom = from;
    DateTime? normalizedTo = to;

    if (normalizedFrom != null &&
        normalizedTo != null &&
        normalizedFrom.isAfter(normalizedTo)) {
      final swap = normalizedFrom;
      normalizedFrom = normalizedTo;
      normalizedTo = swap;
    }

    state = state.copyWith(
      rangePreset: UserTransactionsRangePreset.custom,
      customFrom: normalizedFrom,
      customTo: normalizedTo,
      page: 1,
      errorMessage: null,
    );

    await loadTransactions();
  }

  void selectTransaction(UserTransaction transaction) {
    state = state.copyWith(selectedTransaction: transaction);
  }

  void clearSelectedTransaction() {
    state = state.copyWith(selectedTransaction: null);
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      selectedStatus: null,
      selectedPaymentMode: null,
      selectedPaymentType: null,
      searchQuery: '',
      rangePreset: UserTransactionsRangePreset.thisMonth,
      customFrom: null,
      customTo: null,
      page: 1,
      errorMessage: null,
    );

    await loadTransactions();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> _loadTransactions({
    required int targetPage,
    required bool append,
    required bool isRefresh,
  }) async {
    final page = targetPage < 1 ? 1 : targetPage;

    state = state.copyWith(
      isLoading: true,
      isRefreshing: isRefresh,
      errorMessage: null,
    );

    try {
      final range = _resolveRangeQuery();
      final response = await _service.getTransactions(
        status: state.selectedStatus,
        search: state.searchQuery.trim().isEmpty ? null : state.searchQuery,
        from: range.from,
        to: range.to,
        page: page,
        limit: state.limit,
        refreshKey: _currentRefreshKey,
      );

      final merged = append
          ? _mergeTransactions(state.transactions, response.items)
          : response.items;
      final sorted = _sortNewestFirst(merged);

      state = state.copyWith(
        transactions: sorted,
        page: response.page <= 0 ? page : response.page,
        limit: response.limit <= 0 ? state.limit : response.limit,
        total: response.total < sorted.length ? sorted.length : response.total,
        isLoading: false,
        isRefreshing: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  List<UserTransaction> _mergeTransactions(
    List<UserTransaction> current,
    List<UserTransaction> incoming,
  ) {
    final merged = <String, UserTransaction>{
      for (final item in current) _transactionIdentity(item): item,
    };

    for (final item in incoming) {
      merged[_transactionIdentity(item)] = item;
    }

    return merged.values.toList(growable: false);
  }

  List<UserTransaction> _sortNewestFirst(List<UserTransaction> value) {
    final output = value.toList(growable: false);
    output.sort((left, right) {
      final leftTime = left.createdAt?.millisecondsSinceEpoch ?? 0;
      final rightTime = right.createdAt?.millisecondsSinceEpoch ?? 0;
      final byDate = rightTime.compareTo(leftTime);
      if (byDate != 0) {
        return byDate;
      }

      return right.id.compareTo(left.id);
    });
    return output;
  }

  String _transactionIdentity(UserTransaction value) {
    final id = value.id.trim();
    if (id.isNotEmpty) {
      return id;
    }

    return [
      value.createdAtRaw.trim(),
      value.amount.trim(),
      value.reference.trim(),
      value.providerRef.trim(),
      value.paymentType.trim(),
    ].join('|');
  }

  _RangeQuery _resolveRangeQuery() {
    final now = DateTime.now();

    switch (state.rangePreset) {
      case UserTransactionsRangePreset.thisMonth:
        // Keep this preset aligned with web by letting backend apply
        // its default current-month range when from/to are absent.
        return const _RangeQuery(from: null, to: null);
      case UserTransactionsRangePreset.last30Days:
        final from = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
        return _RangeQuery(
          from: _formatIsoStartOfDay(from),
          to: _formatIsoEndOfDay(now),
        );
      case UserTransactionsRangePreset.thisYear:
        final from = DateTime(now.year, 1, 1);
        return _RangeQuery(
          from: _formatIsoStartOfDay(from),
          to: _formatIsoEndOfDay(now),
        );
      case UserTransactionsRangePreset.custom:
        return _RangeQuery(
          from: state.customFrom == null
              ? null
              : _formatIsoStartOfDay(state.customFrom!),
          to: state.customTo == null
              ? null
              : _formatIsoEndOfDay(state.customTo!),
        );
    }
  }

  String _formatIsoStartOfDay(DateTime value) {
    final start = DateTime(value.year, value.month, value.day);
    return start.toUtc().toIso8601String();
  }

  String _formatIsoEndOfDay(DateTime value) {
    final end = DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
    return end.toUtc().toIso8601String();
  }

  String get _currentRefreshKey {
    final normalized = state.refreshKey.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }

    final next = _newRefreshKey();
    state = state.copyWith(refreshKey: next);
    return next;
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

    return raw.isEmpty ? 'Unable to load transactions.' : raw;
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
