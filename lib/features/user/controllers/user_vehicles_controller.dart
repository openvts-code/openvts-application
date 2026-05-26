import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_vehicle_model.dart';
import '../models/user_vehicle_state.dart';
import '../services/user_vehicle_service.dart';

class UserVehiclesController extends StateNotifier<UserVehiclesState> {
  UserVehiclesController({required UserVehicleService service})
      : _service = service,
        super(const UserVehiclesState.initial());

  final UserVehicleService _service;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: state.vehicles.isEmpty,
      isRefreshing: state.vehicles.isNotEmpty,
      errorMessage: null,
    );

    try {
      final vehicles = await _service.getVehicles(refreshKey: state.refreshKey);
      if (!mounted) return;
      state = _withFiltered(
        state.copyWith(
          vehicles: vehicles,
          isLoading: false,
          isRefreshing: false,
        ),
      );
    } catch (error) {
      if (!mounted) return;
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
      final vehicles = await _service.getVehicles(refreshKey: refreshKey);
      if (!mounted) return;
      state = _withFiltered(
        state.copyWith(
          vehicles: vehicles,
          isRefreshing: false,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  void setSearchQuery(String query) {
    state = _withFiltered(state.copyWith(searchQuery: query.trim()));
  }

  void setStatusFilter(UserVehicleStatusFilter filter) {
    state = _withFiltered(state.copyWith(statusFilter: filter));
  }

  void setTypeFilter(String? typeFilter) {
    final normalized = typeFilter?.trim();
    state = _withFiltered(
      state.copyWith(
        typeFilter:
            normalized == null || normalized.isEmpty ? null : normalized,
      ),
    );
  }

  void clearFilters() {
    state = _withFiltered(
      state.copyWith(
        searchQuery: '',
        statusFilter: UserVehicleStatusFilter.all,
        typeFilter: null,
      ),
    );
  }

  UserVehiclesState _withFiltered(UserVehiclesState next) {
    final query = next.searchQuery.trim().toLowerCase();
    final typeFilter = next.typeFilter?.trim().toLowerCase();
    final filtered = next.vehicles.where((vehicle) {
      final matchesSearch =
          query.isEmpty || vehicle.searchContent.contains(query);
      if (!matchesSearch) return false;

      final matchesStatus = switch (next.statusFilter) {
        UserVehicleStatusFilter.all => true,
        UserVehicleStatusFilter.active =>
          vehicle.isActive && !vehicle.isLicenseBlocked,
        UserVehicleStatusFilter.inactive => !vehicle.isActive,
        UserVehicleStatusFilter.licenseBlocked => vehicle.isLicenseBlocked,
      };
      if (!matchesStatus) return false;

      if (typeFilter == null || typeFilter.isEmpty) return true;
      return _typeTokens(vehicle).contains(typeFilter);
    }).toList(growable: false);

    return next.copyWith(filteredVehicles: filtered);
  }

  Set<String> _typeTokens(UserVehicleListItem vehicle) {
    final type = vehicle.vehicleType;
    if (type == null) return const <String>{};
    return <String>{
      type.id.trim().toLowerCase(),
      type.name.trim().toLowerCase(),
      type.slug.trim().toLowerCase(),
    }..removeWhere((item) => item.isEmpty);
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final responseMessage = _extractResponseMessage(error.response?.data);
      if (responseMessage != null) return responseMessage;
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Please try again.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server right now.';
      }
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw.isEmpty ? 'Vehicles could not be loaded.' : raw;
  }

  String? _extractResponseMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in const ['message', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
        if (value is List) {
          final parts = value
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          if (parts.isNotEmpty) return parts.join(', ');
        }
      }
      final nestedData = data['data'];
      if (!identical(nestedData, data)) {
        return _extractResponseMessage(nestedData);
      }
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    return null;
  }
}
