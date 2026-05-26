import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../models/admin_transactions_model.dart';
import '../models/admin_transactions_state.dart';
import '../services/admin_transactions_service.dart';

class AdminTransactionsController
    extends StateNotifier<AdminTransactionsState> {
  AdminTransactionsController({required AdminTransactionsService service})
      : _service = service,
        super(const AdminTransactionsState.initial());

  final AdminTransactionsService _service;
  List<AdminTransaction> _serverTransactions = const <AdminTransaction>[];

  Future<void> load() => _loadPage(page: 1, refreshing: false, append: false);

  Future<void> refresh() async {
    state = state.copyWith(refreshKey: state.refreshKey + 1);
    await _loadPage(page: 1, refreshing: true, append: false);
  }

  Future<void> loadMore() async {
    if (!state.hasMoreTransactions || state.isLoadingMore || state.isLoading) {
      return;
    }
    await _loadPage(page: state.page + 1, refreshing: false, append: true);
  }

  Future<void> setStatus(AdminTransactionStatus? value) async {
    state = state.copyWith(selectedStatus: value);
    await _loadPage(page: 1, refreshing: false, append: false);
  }

  void setMode(AdminPaymentMode? value) {
    state = state.copyWith(selectedMode: value);
    state =
        state.copyWith(transactions: _applyLocalFilters(_serverTransactions));
  }

  void setType(AdminPaymentType? value) {
    state = state.copyWith(selectedType: value);
    state =
        state.copyWith(transactions: _applyLocalFilters(_serverTransactions));
  }

  Future<void> setSearchQuery(String value) async {
    state = state.copyWith(searchQuery: value);
    await _loadPage(page: 1, refreshing: false, append: false);
  }

  Future<void> setRangePreset(AdminTransactionsRangePreset value) async {
    state = state.copyWith(
      rangePreset: value,
      customFrom: value == AdminTransactionsRangePreset.custom
          ? state.customFrom
          : null,
      customTo:
          value == AdminTransactionsRangePreset.custom ? state.customTo : null,
    );
    await _loadPage(page: 1, refreshing: false, append: false);
  }

  Future<void> setCustomRange(DateTime? from, DateTime? to) async {
    DateTime? f = from;
    DateTime? t = to;
    if (f != null && t != null && f.isAfter(t)) {
      final temp = f;
      f = t;
      t = temp;
    }

    state = state.copyWith(
      rangePreset: AdminTransactionsRangePreset.custom,
      customFrom: f,
      customTo: t,
    );
    await _loadPage(page: 1, refreshing: false, append: false);
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      selectedStatus: null,
      selectedMode: null,
      selectedType: null,
      searchQuery: '',
      rangePreset: AdminTransactionsRangePreset.thisMonth,
      customFrom: null,
      customTo: null,
    );
    await _loadPage(page: 1, refreshing: false, append: false);
  }

  Future<void> _loadPage({
    required int page,
    required bool refreshing,
    required bool append,
  }) async {
    final hasItems = state.transactions.isNotEmpty;
    state = state.copyWith(
      isLoading: !hasItems && !refreshing && !append,
      isRefreshing: refreshing,
      isLoadingMore: append,
      errorMessage: null,
    );

    final range = _resolveRange();

    try {
      final response = await _service.getTransactions(
        page: page,
        limit: state.limit,
        status: state.selectedStatus,
        search: state.searchQuery,
        from: range.from,
        to: range.to,
        refreshKey: state.refreshKey.toString(),
      );

      final merged = append
          ? _mergeById(_serverTransactions, response.items)
          : response.items;
      _serverTransactions = merged;
      final filtered = _applyLocalFilters(merged);

      state = state.copyWith(
        transactions: filtered,
        page: response.page,
        limit: response.limit,
        total: response.total,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  List<AdminTransaction> _mergeById(
    List<AdminTransaction> current,
    List<AdminTransaction> incoming,
  ) {
    final map = <String, AdminTransaction>{
      for (final item in current)
        item.id.isEmpty ? _fallbackKey(item) : item.id: item,
    };

    for (final item in incoming) {
      final key = item.id.isEmpty ? _fallbackKey(item) : item.id;
      map[key] = item;
    }

    final values = map.values.toList(growable: false)
      ..sort((a, b) {
        final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
    return values;
  }

  List<AdminTransaction> _applyLocalFilters(List<AdminTransaction> items) {
    return items.where((item) {
      final modeOk =
          state.selectedMode == null || item.paymentMode == state.selectedMode;
      final typeOk =
          state.selectedType == null || item.paymentType == state.selectedType;
      return modeOk && typeOk;
    }).toList(growable: false);
  }

  _DateRange _resolveRange() {
    final now = DateTime.now();
    if (state.rangePreset == AdminTransactionsRangePreset.thisMonth) {
      return const _DateRange(null, null);
    }

    if (state.rangePreset == AdminTransactionsRangePreset.last30) {
      final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final from = to.subtract(const Duration(days: 29));
      return _DateRange(from, to);
    }

    if (state.rangePreset == AdminTransactionsRangePreset.thisYear) {
      final from = DateTime(now.year, 1, 1);
      final to = DateTime(now.year, 12, 31, 23, 59, 59);
      return _DateRange(from, to);
    }

    return _DateRange(state.customFrom, state.customTo);
  }

  String _fallbackKey(AdminTransaction item) {
    return '${item.createdAtRaw}|${item.amount}|${item.reference}|${item.providerRef}';
  }

  String _toErrorMessage(Object error) {
    if (error is ApiException) return error.message;

    if (error is DioException) {
      final map = error.response?.data;
      if (map is Map && map['message'] != null) {
        return map['message'].toString();
      }
      return error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : 'Unable to load transactions.';
    }

    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw;
  }
}

class _DateRange {
  const _DateRange(this.from, this.to);

  final DateTime? from;
  final DateTime? to;
}
