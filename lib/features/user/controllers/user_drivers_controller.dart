import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_driver_model.dart';
import '../models/user_drivers_state.dart';
import '../services/user_driver_service.dart';

class UserDriversController extends StateNotifier<UserDriversState> {
  UserDriversController({required UserDriverService service})
      : _service = service,
        super(const UserDriversState.initial());

  final UserDriverService _service;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: state.drivers.isEmpty,
      isRefreshing: state.drivers.isNotEmpty,
      errorMessage: null,
    );

    try {
      final drivers = await _service.fetchDrivers(refreshKey: state.refreshKey);
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        drivers: drivers,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> refresh() async {
    final refreshKey = DateTime.now().millisecondsSinceEpoch.toString();
    state = state.copyWith(
      refreshKey: refreshKey,
      isRefreshing: true,
      errorMessage: null,
    );

    try {
      final drivers = await _service.fetchDrivers(refreshKey: refreshKey);
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        drivers: drivers,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  Future<UserDriver?> createDriver(CreateUserDriverRequest request) async {
    if (state.isCreating) {
      return null;
    }

    state = state.copyWith(
      isCreating: true,
      errorMessage: null,
    );

    try {
      final created = await _service.createDriver(request);
      if (!mounted) {
        return created;
      }

      final nextDrivers = _upsertDriver(state.drivers, created);
      state = state.copyWith(
        drivers: nextDrivers,
        isCreating: false,
      );

      await refresh();
      return created;
    } catch (error) {
      if (!mounted) {
        return null;
      }

      state = state.copyWith(
        isCreating: false,
        errorMessage: _errorMessage(error),
      );
      return null;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
  }

  void setStatusFilter(UserDriverStatusFilter filter) {
    state = state.copyWith(selectedStatusFilter: filter);
  }

  void setAssignmentFilter(UserDriverAssignmentFilter filter) {
    state = state.copyWith(selectedAssignmentFilter: filter);
  }

  void setVerificationFilter(UserDriverVerificationFilter filter) {
    state = state.copyWith(selectedVerificationFilter: filter);
  }

  Future<List<UserDriverCountryOption>> getCountries() {
    return _service.fetchCountries();
  }

  Future<List<UserDriverMobilePrefixOption>> getMobilePrefixes() {
    return _service.fetchMobilePrefixes();
  }

  Future<List<UserDriverStateOption>> getStates(String countryCode) {
    return _service.fetchStates(countryCode);
  }

  Future<List<UserDriverCityOption>> getCities(
    String countryCode,
    String stateCode,
  ) {
    return _service.fetchCities(countryCode, stateCode);
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedStatusFilter: UserDriverStatusFilter.all,
      selectedAssignmentFilter: UserDriverAssignmentFilter.all,
      selectedVerificationFilter: UserDriverVerificationFilter.all,
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  List<UserDriver> _upsertDriver(List<UserDriver> drivers, UserDriver driver) {
    final id = driver.id.trim();
    if (id.isEmpty) {
      return drivers;
    }

    var replaced = false;
    final next = drivers.map((item) {
      if (item.id != id) {
        return item;
      }
      replaced = true;
      return driver;
    }).toList(growable: true);

    if (!replaced) {
      next.insert(0, driver);
    }

    return next;
  }

  String _errorMessage(Object error) {
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

    return raw.isEmpty ? 'Drivers could not be loaded.' : raw;
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
