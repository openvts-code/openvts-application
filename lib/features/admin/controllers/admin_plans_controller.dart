import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../models/admin_plans_model.dart';
import '../models/admin_plans_state.dart';
import '../services/admin_plans_service.dart';

class AdminPlansController extends StateNotifier<AdminPlansState> {
  AdminPlansController({required AdminPlansService service})
      : _service = service,
        super(const AdminPlansState.initial());

  final AdminPlansService _service;

  Future<void> load() async {
    await _fetchPlans(
      refreshKey: state.refreshKey == 0 ? null : state.refreshKey.toString(),
      refreshing: state.hasPlans,
    );
  }

  Future<void> refresh() async {
    final nextRefreshKey = state.refreshKey + 1;
    state = state.copyWith(refreshKey: nextRefreshKey);
    await _fetchPlans(refreshKey: nextRefreshKey.toString(), refreshing: true);
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value, errorMessage: null);
  }

  Future<void> loadCurrencies({bool force = false}) async {
    if (state.isLoadingCurrencies) {
      return;
    }
    if (!force && state.currencies.isNotEmpty) {
      return;
    }

    state = state.copyWith(
      isLoadingCurrencies: true,
      submitErrorMessage: null,
      errorMessage: null,
    );

    try {
      final currencies = await _service.getCurrencies();
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        currencies: currencies,
        isLoadingCurrencies: false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isLoadingCurrencies: false,
        submitErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<AdminPlan?> createPlan(AdminPlanMutationRequest request) async {
    if (state.isCreating) {
      return null;
    }

    state = state.copyWith(
      isCreating: true,
      submitErrorMessage: null,
      errorMessage: null,
    );

    try {
      final plan = await _service.createPlan(request);
      if (!mounted) {
        return null;
      }
      state = state.copyWith(isCreating: false, submitErrorMessage: null);
      await refresh();
      return plan;
    } catch (error) {
      if (!mounted) {
        return null;
      }
      state = state.copyWith(
        isCreating: false,
        submitErrorMessage: _toErrorMessage(error),
      );
      return null;
    }
  }

  Future<bool> updatePlan({
    required String id,
    required AdminPlanMutationRequest request,
  }) async {
    if (state.isUpdating) {
      return false;
    }

    state = state.copyWith(
      isUpdating: true,
      submitErrorMessage: null,
      errorMessage: null,
    );

    try {
      await _service.updatePlan(id: id, request: request);
      if (!mounted) {
        return false;
      }
      state = state.copyWith(isUpdating: false, submitErrorMessage: null);
      await refresh();
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      state = state.copyWith(
        isUpdating: false,
        submitErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<void> _fetchPlans({
    String? refreshKey,
    required bool refreshing,
  }) async {
    final hasExistingPlans = state.hasPlans;
    state = state.copyWith(
      isLoading: !hasExistingPlans && !refreshing,
      isRefreshing: hasExistingPlans || refreshing,
      errorMessage: null,
    );

    try {
      final plans = await _service.getPlans(refreshKey: refreshKey);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        plans: plans,
        isLoading: false,
        isRefreshing: false,
        errorMessage: null,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  String _toErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
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
      }
      final nested = data['data'];
      if (!identical(nested, data)) {
        return _extractResponseMessage(nested);
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }
}
