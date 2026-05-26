import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/superadmin_administrator_model.dart';
import '../models/superadmin_administrators_state.dart';
import '../services/superadmin_administrators_service.dart';

class SuperadminAdministratorsController
    extends StateNotifier<SuperadminAdministratorsState> {
  SuperadminAdministratorsController(this._service)
      : super(const SuperadminAdministratorsState.initial()) {
    load();
  }

  final SuperadminAdministratorsService _service;

  Future<void> load({bool refresh = false}) async {
    final hasData = state.hasItems;

    state = state.copyWith(
      isInitialLoading: !hasData,
      isRefreshing: hasData || refresh,
      errorMessage: null,
    );

    try {
      final page = await _service.getAdministrators();

      state = state.copyWith(
      administrators: page.items,
        isInitialLoading: false,
        isRefreshing: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  Future<void> prepareCreateForm() async {
    state = state.copyWith(
      stateOptions: const <SuperadminStateOption>[],
      cityOptions: const <SuperadminCityOption>[],
      isCatalogLoading: state.countries.isEmpty || state.mobilePrefixes.isEmpty,
      errorMessage: null,
    );

    if (state.countries.isNotEmpty && state.mobilePrefixes.isNotEmpty) {
      state = state.copyWith(isCatalogLoading: false);
      return;
    }

    try {
      final countries = await _service.getCountries();
      final prefixes = await _service.getMobilePrefixes();
      state = state.copyWith(
        countries: countries,
        mobilePrefixes: prefixes,
        isCatalogLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isCatalogLoading: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  void setSearchQuery(String value) {
    state = state.copyWith(
      searchQuery: value,
      currentPage: 1,
    );
  }

  void setRoleFilter(SuperadminAdministratorRoleFilter value) {
    state = state.copyWith(
      roleFilter: value,
      currentPage: 1,
    );
  }

  void setStatusFilter(SuperadminAdministratorStatusFilter value) {
    state = state.copyWith(
      statusFilter: value,
      currentPage: 1,
    );
  }

  void setSortOption(SuperadminAdministratorSortOption value) {
    state = state.copyWith(
      sortOption: value,
      currentPage: 1,
    );
  }

  void setRecordsPerPage(int value) {
    state = state.copyWith(
      recordsPerPage: value,
      currentPage: 1,
    );
  }

  void goToPage(int value) {
    state = state.copyWith(currentPage: value);
  }

  Future<void> loadStateOptions(String countryCode) async {
    final normalized = countryCode.trim().toUpperCase();
    if (normalized.isEmpty) {
      state = state.copyWith(
        stateOptions: const <SuperadminStateOption>[],
        cityOptions: const <SuperadminCityOption>[],
      );
      return;
    }

    state = state.copyWith(
      isCatalogLoading: true,
      stateOptions: const <SuperadminStateOption>[],
      cityOptions: const <SuperadminCityOption>[],
      errorMessage: null,
    );

    try {
      final states = await _service.getStates(normalized);
      state = state.copyWith(
        stateOptions: states,
        cityOptions: const <SuperadminCityOption>[],
        isCatalogLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isCatalogLoading: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> loadCityOptions(String countryCode, String stateCode) async {
    final normalizedCountry = countryCode.trim().toUpperCase();
    final normalizedState = stateCode.trim().toUpperCase();
    if (normalizedCountry.isEmpty || normalizedState.isEmpty) {
      state = state.copyWith(cityOptions: const <SuperadminCityOption>[]);
      return;
    }

    state = state.copyWith(
      isCatalogLoading: true,
      cityOptions: const <SuperadminCityOption>[],
      errorMessage: null,
    );

    try {
      final cities = await _service.getCities(normalizedCountry, normalizedState);
      state = state.copyWith(
        cityOptions: cities,
        isCatalogLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isCatalogLoading: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> createAdministrator(
    SuperadminCreateAdministratorRequest request,
  ) async {
    state = state.copyWith(
      isCreating: true,
      errorMessage: null,
    );

    try {
      await _service.createAdministrator(request);
      state = state.copyWith(isCreating: false);
      await load(refresh: true);
    } catch (error) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> setAdministratorActive(
    SuperadminAdministrator administrator, {
    required bool isActive,
  }) async {
    state = state.copyWith(
      togglingAdministratorId: administrator.id,
      errorMessage: null,
    );

    try {
      await _service.setAdministratorActive(
        administrator.id,
        isActive: isActive,
      );

      await load(refresh: true);
      state = state.copyWith(
        togglingAdministratorId: null,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        togglingAdministratorId: null,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> deleteAdministrator(SuperadminAdministrator administrator) async {
    state = state.copyWith(
      deletingAdministratorId: administrator.id,
      errorMessage: null,
    );

    try {
      await _service.deleteAdministrator(administrator.id);

      await load(refresh: true);
      state = state.copyWith(
        deletingAdministratorId: null,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        deletingAdministratorId: null,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<SuperadminAdministratorLoginOutcome> loginAsAdministrator(
    SuperadminAdministrator administrator,
  ) async {
    state = state.copyWith(
      loggingInAdministratorId: administrator.id,
      errorMessage: null,
    );

    try {
      final outcome = await _service.loginAsAdministrator(administrator.id);
      state = state.copyWith(loggingInAdministratorId: null);
      return outcome;
    } catch (error) {
      state = state.copyWith(
        loggingInAdministratorId: null,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
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