import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../models/admin_payments_model.dart';
import '../models/admin_payments_state.dart';
import '../services/admin_payments_service.dart';

class AdminPaymentsController extends StateNotifier<AdminPaymentsState> {
  AdminPaymentsController({required AdminPaymentsService service})
      : _service = service,
        super(const AdminPaymentsState.initial());

  final AdminPaymentsService _service;
  List<AdminPaymentTransaction> _serverItems =
      const <AdminPaymentTransaction>[];

  Future<void> load() async {
    await Future.wait<void>([
      loadUsers(),
      _loadPayments(page: 1, append: false, refreshing: false),
      loadAnalytics(),
    ]);
  }

  Future<void> refresh() async {
    state = state.copyWith(refreshKey: state.refreshKey + 1);
    await Future.wait<void>([
      _loadPayments(page: 1, append: false, refreshing: true),
      loadAnalytics(),
    ]);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    await _loadPayments(page: state.page + 1, append: true, refreshing: false);
  }

  Future<void> setUser(String? userId) async {
    state = state.copyWith(
        selectedUserId: (userId ?? '').trim().isEmpty ? null : userId);
    await Future.wait<void>([
      _loadPayments(page: 1, append: false, refreshing: false),
      loadAnalytics(),
    ]);
  }

  Future<void> setStatus(AdminPaymentStatus? status) async {
    state = state.copyWith(selectedStatus: status);
    await Future.wait<void>([
      _loadPayments(page: 1, append: false, refreshing: false),
      loadAnalytics(),
    ]);
  }

  void setMode(AdminPaymentMode? mode) {
    state = state.copyWith(selectedMode: mode);
    state = state.copyWith(transactions: _applyLocalFilters(_serverItems));
  }

  Future<void> setSearchQuery(String query) async {
    state = state.copyWith(searchQuery: query);
    state = state.copyWith(transactions: _applyLocalFilters(_serverItems));
  }

  Future<void> setRangePreset(AdminPaymentsRangePreset preset) async {
    state = state.copyWith(
      rangePreset: preset,
      customFrom:
          preset == AdminPaymentsRangePreset.custom ? state.customFrom : null,
      customTo:
          preset == AdminPaymentsRangePreset.custom ? state.customTo : null,
    );

    await Future.wait<void>([
      _loadPayments(page: 1, append: false, refreshing: false),
      loadAnalytics(),
    ]);
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
      rangePreset: AdminPaymentsRangePreset.custom,
      customFrom: f,
      customTo: t,
    );

    await Future.wait<void>([
      _loadPayments(page: 1, append: false, refreshing: false),
      loadAnalytics(),
    ]);
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      selectedUserId: null,
      selectedStatus: null,
      selectedMode: null,
      searchQuery: '',
      rangePreset: AdminPaymentsRangePreset.thisMonth,
      customFrom: null,
      customTo: null,
    );

    await Future.wait<void>([
      _loadPayments(page: 1, append: false, refreshing: false),
      loadAnalytics(),
    ]);
  }

  Future<void> loadUsers() async {
    try {
      final users = await _service.getUsers();
      if (!mounted) return;
      state = state.copyWith(users: users);
    } catch (_) {
      // keep non-blocking
    }
  }

  Future<List<AdminRenewVehicleOption>> loadRenewVehicles(String userId) {
    return _service.getLinkedVehicles(userId);
  }

  Future<bool> renewVehicles(AdminRenewPaymentRequest request) async {
    state = state.copyWith(isRenewing: true, errorMessage: null);
    try {
      await _service.renewVehicles(request);
      if (!mounted) return false;
      state = state.copyWith(isRenewing: false);
      await refresh();
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
          isRenewing: false, errorMessage: _toErrorMessage(error));
      return false;
    }
  }

  Future<void> loadAnalytics() async {
    state =
        state.copyWith(isLoadingAnalytics: true, analyticsErrorMessage: null);
    final range = _resolveRange();

    try {
      final analytics = await _service.getTransactionsAnalytics(
        userId: state.selectedUserId,
        from: range.from,
        to: range.to,
        refreshKey: state.refreshKey.toString(),
      );
      if (!mounted) return;
      state = state.copyWith(
          isLoadingAnalytics: false,
          analytics: analytics,
          analyticsErrorMessage: null);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
          isLoadingAnalytics: false,
          analyticsErrorMessage: _toErrorMessage(error));
    }
  }

  Future<void> _loadPayments({
    required int page,
    required bool append,
    required bool refreshing,
  }) async {
    final hasData = state.transactions.isNotEmpty;
    state = state.copyWith(
      isLoading: !hasData && !append && !refreshing,
      isRefreshing: refreshing,
      isLoadingMore: append,
      errorMessage: null,
    );

    final range = _resolveRange();

    try {
      final response = await _service.getPayments(
        page: page,
        limit: state.limit,
        userId: state.selectedUserId,
        status: state.selectedStatus,
        from: state.rangePreset == AdminPaymentsRangePreset.custom
            ? range.from
            : null,
        to: state.rangePreset == AdminPaymentsRangePreset.custom
            ? range.to
            : null,
        refreshKey: state.refreshKey.toString(),
      );

      final merged =
          append ? _mergeById(_serverItems, response.items) : response.items;
      _serverItems = merged;

      state = state.copyWith(
        transactions: _applyLocalFilters(merged),
        page: response.page,
        limit: response.limit,
        total: response.total,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
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

  List<AdminPaymentTransaction> _mergeById(
    List<AdminPaymentTransaction> current,
    List<AdminPaymentTransaction> incoming,
  ) {
    final merged = <String, AdminPaymentTransaction>{
      for (final item in current)
        item.id.isEmpty ? _fallbackKey(item) : item.id: item,
    };

    for (final item in incoming) {
      final key = item.id.isEmpty ? _fallbackKey(item) : item.id;
      merged[key] = item;
    }

    final values = merged.values.toList(growable: false)
      ..sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
          .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
    return values;
  }

  String _fallbackKey(AdminPaymentTransaction item) {
    return '${item.createdAtRaw}|${item.amount}|${item.reference}|${item.providerRef}';
  }

  List<AdminPaymentTransaction> _applyLocalFilters(
      List<AdminPaymentTransaction> items) {
    final q = state.searchQuery.trim().toLowerCase();
    return items.where((item) {
      final modeOk =
          state.selectedMode == null || item.paymentMode == state.selectedMode;
      final searchOk = q.isEmpty ||
          <String>[
            item.reference,
            item.provider,
            item.providerRef,
            item.toUser?.name ?? '',
            item.toUser?.username ?? '',
            item.vehicle['name']?.toString() ?? '',
            item.vehicle['plateNumber']?.toString() ?? '',
          ].any((v) => v.toLowerCase().contains(q));
      return modeOk && searchOk;
    }).toList(growable: false);
  }

  _DateRange _resolveRange() {
    final now = DateTime.now();
    if (state.rangePreset == AdminPaymentsRangePreset.thisMonth) {
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      return _DateRange(from, to);
    }

    if (state.rangePreset == AdminPaymentsRangePreset.last30) {
      final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final from = to.subtract(const Duration(days: 29));
      return _DateRange(from, to);
    }

    if (state.rangePreset == AdminPaymentsRangePreset.thisYear) {
      final from = DateTime(now.year, 1, 1);
      final to = DateTime(now.year, 12, 31, 23, 59, 59);
      return _DateRange(from, to);
    }

    return _DateRange(state.customFrom, state.customTo);
  }

  String _toErrorMessage(Object error) {
    if (error is ApiException) return error.message;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : 'Unable to process request.';
    }

    final raw = error.toString().trim();
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
