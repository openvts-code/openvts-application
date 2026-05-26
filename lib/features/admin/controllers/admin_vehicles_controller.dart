import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_vehicle_model.dart';
import '../models/admin_vehicle_state.dart';
import '../services/admin_vehicle_service.dart';

class AdminVehiclesController extends StateNotifier<AdminVehiclesState> {
  AdminVehiclesController({required AdminVehicleService service})
      : _service = service,
        super(AdminVehiclesState.initial());

  final AdminVehicleService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final vehicles = await _service.getVehicles();
      _setVehicles(vehicles, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, errorMessage: null);
    try {
      final vehicles = await _service.getVehicles(
        refreshKey: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      _setVehicles(vehicles, isRefreshing: false);
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
    _applyFilters();
  }

  void setStatusFilter(AdminVehicleStatusFilter value) {
    state = state.copyWith(statusFilter: value);
    _applyFilters();
  }

  void setTypeFilter(String value) {
    state = state.copyWith(typeFilter: value);
    _applyFilters();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      statusFilter: AdminVehicleStatusFilter.all,
      typeFilter: '',
    );
    _applyFilters();
  }

  Future<void> createVehicle(AdminCreateVehicleRequest request) async {
    state = state.copyWith(isCreating: true, errorMessage: null);
    try {
      await _service.createVehicle(request);
      if (!mounted) {
        return;
      }
      state = state.copyWith(isCreating: false);
      await refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isCreating: false,
        errorMessage: _errorMessage(error),
      );
      rethrow;
    }
  }

  Future<AdminCreateVehicleCatalog> getCreateVehicleCatalog() async {
    final results = await Future.wait<dynamic>([
      _service.getUsers(),
      _service.getQuickDevices(),
      _service.getVehicleTypes(),
      _service.getPricingPlans(),
    ]);

    return AdminCreateVehicleCatalog(
      users: results[0] as List<AdminVehicleUserMini>,
      devices: results[1] as List<AdminQuickDeviceOption>,
      vehicleTypes: results[2] as List<AdminVehicleTypeOption>,
      plans: results[3] as List<AdminPricingPlanOption>,
    );
  }

  Future<bool> updateVehicleStatus(
      {required String id, required bool isActive}) async {
    final current = state.vehicles;
    final updating = <String>{...state.updatingIds, id};
    final optimistic = current
        .map((item) => item.id == id
            ? AdminVehicleListItem(
                id: item.id,
                name: item.name,
                vin: item.vin,
                plateNumber: item.plateNumber,
                isActive: isActive,
                isLicenseBlocked: item.isLicenseBlocked,
                licenseBlockedAt: item.licenseBlockedAt,
                licenseBlockReason: item.licenseBlockReason,
                createdAt: item.createdAt,
                updatedAt: item.updatedAt,
                imei: item.imei,
                simNumber: item.simNumber,
                vehicleType: item.vehicleType,
                device: item.device,
                primaryUser: item.primaryUser,
              )
            : item)
        .toList(growable: false);
    state = state.copyWith(
      updatingIds: updating,
      errorMessage: null,
      vehicles: optimistic,
    );
    _applyFilters();
    try {
      await _service.updateVehicleStatus(id: id, isActive: isActive);
      state = state.copyWith(updatingIds: {...state.updatingIds}..remove(id));
      _applyFilters();
      return true;
    } catch (error) {
      state = state.copyWith(
        updatingIds: {...state.updatingIds}..remove(id),
        vehicles: current,
        errorMessage: _errorMessage(error),
      );
      _applyFilters();
      return false;
    }
  }

  Future<bool> deleteVehicle(String id) async {
    final deleting = <String>{...state.deletingIds, id};
    state = state.copyWith(deletingIds: deleting, errorMessage: null);
    try {
      await _service.deleteVehicle(id);
      final vehicles =
          state.vehicles.where((item) => item.id != id).toList(growable: false);
      state = state.copyWith(
          deletingIds: {...state.deletingIds}..remove(id), vehicles: vehicles);
      _applyFilters();
      return true;
    } catch (error) {
      state = state.copyWith(
        deletingIds: {...state.deletingIds}..remove(id),
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  void _setVehicles(
    List<AdminVehicleListItem> vehicles, {
    bool? isLoading,
    bool? isRefreshing,
  }) {
    state = state.copyWith(
      vehicles: vehicles,
      isLoading: isLoading,
      isRefreshing: isRefreshing,
      errorMessage: null,
    );
    _applyFilters();
  }

  void _applyFilters() {
    final query = state.searchQuery.trim().toLowerCase();
    final typeFilter = state.typeFilter.trim().toLowerCase();
    final filtered = state.vehicles.where((vehicle) {
      if (state.statusFilter == AdminVehicleStatusFilter.active &&
          !vehicle.isActive) {
        return false;
      }
      if (state.statusFilter == AdminVehicleStatusFilter.inactive &&
          vehicle.isActive) {
        return false;
      }
      if (state.statusFilter == AdminVehicleStatusFilter.licenseBlocked &&
          !vehicle.isLicenseBlocked) {
        return false;
      }
      if (typeFilter.isNotEmpty &&
          vehicle.vehicleTypeName.toLowerCase() != typeFilter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      final haystack = <String>[
        vehicle.name,
        vehicle.plateNumber,
        vehicle.vin,
        vehicle.imei,
        vehicle.simNumber,
        vehicle.vehicleTypeName,
        vehicle.primaryUserName,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);

    state = state.copyWith(filteredVehicles: filtered);
  }

  String _errorMessage(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception:')) {
      return message.replaceFirst('Exception:', '').trim();
    }
    return message.isEmpty ? 'Unable to complete request.' : message;
  }
}

class AdminCreateVehicleCatalog {
  const AdminCreateVehicleCatalog({
    required this.users,
    required this.devices,
    required this.vehicleTypes,
    required this.plans,
  });

  final List<AdminVehicleUserMini> users;
  final List<AdminQuickDeviceOption> devices;
  final List<AdminVehicleTypeOption> vehicleTypes;
  final List<AdminPricingPlanOption> plans;
}
