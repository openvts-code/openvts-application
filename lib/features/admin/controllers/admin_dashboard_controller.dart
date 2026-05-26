import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_cache.dart';
import '../models/admin_dashboard_state.dart';
import '../services/admin_dashboard_service.dart';

class AdminDashboardController extends StateNotifier<AdminDashboardState> {
  AdminDashboardController({
    required AdminDashboardService service,
    required LocalCache localCache,
  })  : _service = service,
        _localCache = localCache,
        super(const AdminDashboardState.initial());

  static const String currencyCacheKey = 'openvts_admin_dashboard_currency';
  static const String _legacyCurrencyCacheKey = 'adminDashboardCurrency';

  final AdminDashboardService _service;
  final LocalCache _localCache;

  int _refreshKey = 0;

  Future<void> load() async {
    final savedCurrency = _readSavedCurrency();
    await _fetchDashboard(
      currency: savedCurrency,
      initialLoading: !state.hasData,
      refreshing: state.hasData,
    );
  }

  Future<void> refresh() async {
    _refreshKey++;
    await _fetchDashboard(
      currency: state.selectedCurrency ?? _readSavedCurrency(),
      refreshKey: _refreshKey.toString(),
      initialLoading: !state.hasData,
      refreshing: state.hasData,
    );
  }

  Future<void> changeCurrency(String currency) async {
    final normalizedCurrency = currency.trim().toUpperCase();
    if (normalizedCurrency.isEmpty) {
      return;
    }

    await _saveCurrency(normalizedCurrency);
    await _fetchDashboard(
      currency: normalizedCurrency,
      initialLoading: !state.hasData,
      refreshing: state.hasData,
      selectedCurrency: normalizedCurrency,
    );
  }

  Future<void> _fetchDashboard({
    String? currency,
    String? refreshKey,
    required bool initialLoading,
    required bool refreshing,
    String? selectedCurrency,
  }) async {
    state = state.copyWith(
      selectedCurrency: selectedCurrency ?? state.selectedCurrency ?? currency,
      isInitialLoading: initialLoading,
      isRefreshing: refreshing,
      errorMessage: null,
    );

    try {
      final dashboard = await _service.getDashboardSummary(
        currency: currency,
        refreshKey: refreshKey,
      );
      await _saveCurrency(dashboard.selectedCurrency);

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        dashboard: dashboard,
        selectedCurrency: dashboard.selectedCurrency,
        isInitialLoading: false,
        isRefreshing: false,
        errorMessage: null,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  String? _readSavedCurrency() {
    final primary = _localCache.getString(currencyCacheKey)?.trim();
    if (primary != null && primary.isNotEmpty) {
      return primary.toUpperCase();
    }

    final legacy = _localCache.getString(_legacyCurrencyCacheKey)?.trim();
    if (legacy != null && legacy.isNotEmpty) {
      return legacy.toUpperCase();
    }

    return null;
  }

  Future<void> _saveCurrency(String currency) async {
    final normalizedCurrency = currency.trim().toUpperCase();
    if (normalizedCurrency.isEmpty) {
      return;
    }

    await _localCache.setString(currencyCacheKey, normalizedCurrency);
  }

  String _toErrorMessage(Object error) {
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
}
