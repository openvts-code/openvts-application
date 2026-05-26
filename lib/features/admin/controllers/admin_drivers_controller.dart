import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../models/admin_drivers_model.dart';
import '../models/admin_drivers_state.dart';
import '../services/admin_drivers_service.dart';

class AdminDriversController extends StateNotifier<AdminDriversState> {
  AdminDriversController({required AdminDriversService service})
      : _service = service,
        super(const AdminDriversState.initial());

  final AdminDriversService _service;

  Future<void> load() async {
    await _fetchDrivers(
      refreshKey: state.refreshKey == 0 ? null : state.refreshKey.toString(),
      refreshing: state.hasDrivers,
    );
  }

  Future<void> refresh() async {
    final nextRefreshKey = state.refreshKey + 1;
    state = state.copyWith(refreshKey: nextRefreshKey);
    await _fetchDrivers(
      refreshKey: nextRefreshKey.toString(),
      refreshing: true,
    );
  }

  void setSearchQuery(String value) {
    state = _withFilteredDrivers(
      state.copyWith(searchQuery: value, currentPage: 1, errorMessage: null),
    );
  }

  void setStatusFilter(AdminDriverStatusFilter value) {
    state = _withFilteredDrivers(
      state.copyWith(statusFilter: value, currentPage: 1, errorMessage: null),
    );
  }

  void setVerifiedFilter(AdminDriverVerifiedFilter value) {
    state = _withFilteredDrivers(
      state.copyWith(verifiedFilter: value, currentPage: 1, errorMessage: null),
    );
  }

  void setCountryFilter(String? value) {
    final normalized = value?.trim();
    state = _withFilteredDrivers(
      state.copyWith(
        countryFilter:
            normalized == null || normalized.isEmpty ? null : normalized,
        currentPage: 1,
        errorMessage: null,
      ),
    );
  }

  void setSortOption(AdminDriversSortOption value) {
    state = _withFilteredDrivers(
      state.copyWith(sortOption: value, currentPage: 1, errorMessage: null),
    );
  }

  void setRecordsPerPage(int value) {
    state = state.copyWith(recordsPerPage: value, currentPage: 1);
  }

  void goToPage(int value) {
    state = state.copyWith(currentPage: value);
  }

  Future<void> createDriver(AdminDriverCreateRequest request) async {
    state = state.copyWith(isCreating: true, errorMessage: null);
    try {
      await _service.createDriver(request);
      if (!mounted) return;
      await _fetchDrivers(refreshing: true);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: _toErrorMessage(error));
      rethrow;
    } finally {
      if (mounted) {
        state = state.copyWith(isCreating: false);
      }
    }
  }

  Future<List<AdminDriverListItem>> fetchUsersForPrimarySelection() {
    return _service.getUsersForDriverPrimarySelection();
  }

  Future<void> deleteDriver(String driverId) async {
    await _service.deleteDriver(driverId);
    if (!mounted) return;
    final updated =
        state.drivers.where((d) => d.id != driverId).toList(growable: false);
    state = _withFilteredDrivers(
      state.copyWith(drivers: updated, errorMessage: null),
    );
  }

  void clearFilters() {
    state = _withFilteredDrivers(
      state.copyWith(
        searchQuery: '',
        statusFilter: AdminDriverStatusFilter.all,
        verifiedFilter: AdminDriverVerifiedFilter.all,
        countryFilter: null,
        sortOption: AdminDriversSortOption.newest,
        currentPage: 1,
        errorMessage: null,
      ),
    );
  }

  Future<void> _fetchDrivers({
    String? refreshKey,
    required bool refreshing,
  }) async {
    final hasExistingDrivers = state.hasDrivers;
    state = state.copyWith(
      isLoading: !hasExistingDrivers && !refreshing,
      isRefreshing: hasExistingDrivers || refreshing,
      errorMessage: null,
    );

    try {
      final drivers = await _service.getDrivers(refreshKey: refreshKey);
      if (!mounted) {
        return;
      }

      state = _withFilteredDrivers(
        state.copyWith(
          drivers: drivers,
          isLoading: false,
          isRefreshing: false,
          errorMessage: null,
        ),
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

  AdminDriversState _withFilteredDrivers(AdminDriversState nextState) {
    return nextState.copyWith(filteredDrivers: _filterDrivers(nextState));
  }

  List<AdminDriverListItem> _filterDrivers(AdminDriversState nextState) {
    final filtered = nextState.drivers.where((driver) {
      final matchesSearch = driver.matchesQuery(nextState.searchQuery);
      final matchesStatus = switch (nextState.statusFilter) {
        AdminDriverStatusFilter.all => true,
        AdminDriverStatusFilter.active => driver.isActive,
        AdminDriverStatusFilter.inactive => !driver.isActive,
      };
      final matchesVerified = switch (nextState.verifiedFilter) {
        AdminDriverVerifiedFilter.all => true,
        AdminDriverVerifiedFilter.verified => driver.isVerified,
        AdminDriverVerifiedFilter.unverified => !driver.isVerified,
      };
      final normalizedCountry = nextState.countryFilter?.trim().toUpperCase();
      final driverCountry = driver.countryCode.trim().toUpperCase();
      final matchesCountry =
          normalizedCountry == null || normalizedCountry.isEmpty
              ? true
              : driverCountry == normalizedCountry;

      return matchesSearch &&
          matchesStatus &&
          matchesVerified &&
          matchesCountry;
    }).toList(growable: false);

    if (filtered.length < 2) {
      return filtered;
    }

    switch (nextState.sortOption) {
      case AdminDriversSortOption.newest:
        filtered.sort((left, right) {
          final leftDate = left.createdAt;
          final rightDate = right.createdAt;
          if (leftDate == null && rightDate == null) {
            return left.firstName
                .toLowerCase()
                .compareTo(right.firstName.toLowerCase());
          }
          if (leftDate == null) return 1;
          if (rightDate == null) return -1;
          return rightDate.compareTo(leftDate);
        });
      case AdminDriversSortOption.nameAsc:
        filtered.sort(
          (left, right) => left.firstName
              .toLowerCase()
              .compareTo(right.firstName.toLowerCase()),
        );
      case AdminDriversSortOption.activeFirst:
        filtered.sort((left, right) {
          final activeCompare =
              (right.isActive ? 1 : 0).compareTo(left.isActive ? 1 : 0);
          if (activeCompare != 0) return activeCompare;
          return left.firstName
              .toLowerCase()
              .compareTo(right.firstName.toLowerCase());
        });
    }

    return filtered;
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
