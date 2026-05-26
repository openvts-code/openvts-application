import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../models/admin_inventory_model.dart';
import '../models/admin_inventory_state.dart';
import '../services/admin_inventory_service.dart';

class AdminInventoryController extends StateNotifier<AdminInventoryState> {
  AdminInventoryController({required AdminInventoryService service})
      : _service = service,
        super(const AdminInventoryState.initial());

  final AdminInventoryService _service;

  Future<void> loadInitial() => loadDevices();

  Future<void> selectTab(String tab) async {
    state = state.copyWith(selectedTab: tab, errorMessage: null);
    if (tab == AdminInventoryTab.simCards &&
        state.simCards.isEmpty &&
        !state.isLoadingSimCards) {
      await loadSimCards();
    }
  }

  Future<void> loadDevices() async {
    final hasData = state.devices.isNotEmpty;
    state = state.copyWith(
      isLoadingDevices: !hasData,
      isRefreshingDevices: hasData,
      devicesErrorMessage: null,
      errorMessage: null,
    );

    try {
      final devices = await _service.getDevices(
        refreshKey: state.devicesRefreshKey == 0
            ? null
            : state.devicesRefreshKey.toString(),
      );
      if (!mounted) return;

      state = _applyDeviceFilters(
        state.copyWith(
          devices: devices,
          isLoadingDevices: false,
          isRefreshingDevices: false,
          devicesErrorMessage: null,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingDevices: false,
        isRefreshingDevices: false,
        devicesErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> loadSimCards() async {
    final hasData = state.simCards.isNotEmpty;
    state = state.copyWith(
      isLoadingSimCards: !hasData,
      isRefreshingSimCards: hasData,
      simCardsErrorMessage: null,
      errorMessage: null,
    );

    try {
      final simCards = await _service.getSimCards(
        refreshKey: state.simCardsRefreshKey == 0
            ? null
            : state.simCardsRefreshKey.toString(),
      );
      if (!mounted) return;

      state = _applySimFilters(
        state.copyWith(
          simCards: simCards,
          isLoadingSimCards: false,
          isRefreshingSimCards: false,
          simCardsErrorMessage: null,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingSimCards: false,
        isRefreshingSimCards: false,
        simCardsErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> refreshCurrentTab() {
    return state.selectedTab == AdminInventoryTab.simCards
        ? refreshSimCards()
        : refreshDevices();
  }

  Future<void> refreshDevices() async {
    final key = state.devicesRefreshKey + 1;
    state = state.copyWith(
      devicesRefreshKey: key,
      isRefreshingDevices: true,
      devicesErrorMessage: null,
    );

    try {
      final devices = await _service.getDevices(refreshKey: key.toString());
      if (!mounted) return;
      state = _applyDeviceFilters(
        state.copyWith(
          devices: devices,
          isLoadingDevices: false,
          isRefreshingDevices: false,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isRefreshingDevices: false,
        isLoadingDevices: false,
        devicesErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> refreshSimCards() async {
    final key = state.simCardsRefreshKey + 1;
    state = state.copyWith(
      simCardsRefreshKey: key,
      isRefreshingSimCards: true,
      simCardsErrorMessage: null,
    );

    try {
      final simCards = await _service.getSimCards(refreshKey: key.toString());
      if (!mounted) return;
      state = _applySimFilters(
        state.copyWith(
          simCards: simCards,
          isLoadingSimCards: false,
          isRefreshingSimCards: false,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isRefreshingSimCards: false,
        isLoadingSimCards: false,
        simCardsErrorMessage: _toErrorMessage(error),
      );
    }
  }

  void setDeviceSearchQuery(String value) {
    state = _applyDeviceFilters(
      state.copyWith(
        deviceSearchQuery: value,
        deviceCurrentPage: 1,
        devicesErrorMessage: null,
      ),
    );
  }

  void setSimSearchQuery(String value) {
    state = _applySimFilters(
      state.copyWith(
        simSearchQuery: value,
        simCurrentPage: 1,
        simCardsErrorMessage: null,
      ),
    );
  }

  void setDeviceStatusFilter(AdminInventoryStatusFilter value) {
    state = _applyDeviceFilters(
      state.copyWith(deviceStatusFilter: value, deviceCurrentPage: 1),
    );
  }

  void setSimStatusFilter(AdminInventoryStatusFilter value) {
    state = _applySimFilters(
      state.copyWith(simStatusFilter: value, simCurrentPage: 1),
    );
  }

  void setDeviceActiveFilter(AdminInventoryActiveFilter value) {
    state = _applyDeviceFilters(
      state.copyWith(deviceActiveFilter: value, deviceCurrentPage: 1),
    );
  }

  void setSimActiveFilter(AdminInventoryActiveFilter value) {
    state = _applySimFilters(
      state.copyWith(simActiveFilter: value, simCurrentPage: 1),
    );
  }

  void setDeviceSortOption(AdminInventoryDeviceSortOption value) {
    state = _applyDeviceFilters(
      state.copyWith(deviceSortOption: value, deviceCurrentPage: 1),
    );
  }

  void setSimSortOption(AdminInventorySimSortOption value) {
    state = _applySimFilters(
      state.copyWith(simSortOption: value, simCurrentPage: 1),
    );
  }

  void setDeviceProviderFilter(String? value) {
    final normalized = value?.trim();
    state = _applySimFilters(
      state.copyWith(
        deviceProviderFilter:
            normalized == null || normalized.isEmpty ? null : normalized,
        simCurrentPage: 1,
      ),
    );
  }

  void setDeviceRecordsPerPage(int value) {
    state = state.copyWith(deviceRecordsPerPage: value, deviceCurrentPage: 1);
  }

  void setSimRecordsPerPage(int value) {
    state = state.copyWith(simRecordsPerPage: value, simCurrentPage: 1);
  }

  void goToDevicePage(int value) {
    state = state.copyWith(deviceCurrentPage: value);
  }

  void goToSimPage(int value) {
    state = state.copyWith(simCurrentPage: value);
  }

  void clearDeviceFilters() {
    state = _applyDeviceFilters(
      state.copyWith(
        deviceSearchQuery: '',
        deviceStatusFilter: AdminInventoryStatusFilter.all,
        deviceActiveFilter: AdminInventoryActiveFilter.all,
        deviceSortOption: AdminInventoryDeviceSortOption.newest,
        deviceCurrentPage: 1,
      ),
    );
  }

  void clearSimFilters() {
    state = _applySimFilters(
      state.copyWith(
        simSearchQuery: '',
        simStatusFilter: AdminInventoryStatusFilter.all,
        simActiveFilter: AdminInventoryActiveFilter.all,
        simSortOption: AdminInventorySimSortOption.newest,
        deviceProviderFilter: null,
        simCurrentPage: 1,
      ),
    );
  }

  Future<List<AdminDeviceTypeOption>> loadDeviceTypes() async {
    if (state.deviceTypes.isNotEmpty) {
      return state.deviceTypes;
    }
    final items = await _service.getDeviceTypes();
    if (mounted) {
      state = state.copyWith(deviceTypes: items);
    }
    return items;
  }

  Future<List<AdminSimProviderOption>> loadSimProviders() async {
    if (state.simProviders.isNotEmpty) {
      return state.simProviders;
    }
    final items = await _service.getSimProviders();
    if (mounted) {
      state = state.copyWith(simProviders: items);
    }
    return items;
  }

  Future<List<AdminQuickSimCardOption>> loadQuickSimcards() async {
    if (state.quickSimcards.isNotEmpty) {
      return state.quickSimcards;
    }
    final items = await _service.getQuickSimcards();
    if (mounted) {
      state = state.copyWith(quickSimcards: items);
    }
    return items;
  }

  Future<bool> createDevice(AdminCreateDeviceRequest request) async {
    if (state.isCreating) return false;
    state = state.copyWith(isCreating: true, createErrorMessage: null);
    try {
      await _service.createDevice(request);
      if (!mounted) return false;
      state = state.copyWith(isCreating: false, createErrorMessage: null);
      await refreshDevices();
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isCreating: false,
        createErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> createSimCard(AdminCreateSimCardRequest request) async {
    if (state.isCreating) return false;
    state = state.copyWith(isCreating: true, createErrorMessage: null);
    try {
      await _service.createSimCard(request);
      if (!mounted) return false;
      state = state.copyWith(isCreating: false, createErrorMessage: null);
      await refreshSimCards();
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isCreating: false,
        createErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> createDeviceAndSim(
      AdminCreateDeviceAndSimRequest request) async {
    if (state.isCreating) return false;
    state = state.copyWith(isCreating: true, createErrorMessage: null);
    try {
      await _service.createDeviceAndSim(request);
      if (!mounted) return false;
      state = state.copyWith(isCreating: false, createErrorMessage: null);
      await Future.wait([refreshDevices(), refreshSimCards()]);
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isCreating: false,
        createErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateDevice({
    required String id,
    required AdminUpdateDeviceRequest request,
  }) async {
    if (state.editingDeviceIds.contains(id)) return false;
    final editingIds = {...state.editingDeviceIds, id};
    state =
        state.copyWith(editingDeviceIds: editingIds, editErrorMessage: null);

    try {
      await _service.updateDevice(id: id, request: request);
      if (!mounted) return false;
      final updatedIds = {...state.editingDeviceIds}..remove(id);
      state =
          state.copyWith(editingDeviceIds: updatedIds, editErrorMessage: null);
      await Future.wait([refreshDevices(), refreshSimCards()]);
      return true;
    } catch (error) {
      if (!mounted) return false;
      final updatedIds = {...state.editingDeviceIds}..remove(id);
      state = state.copyWith(
        editingDeviceIds: updatedIds,
        editErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateSimCard({
    required String id,
    required AdminUpdateSimCardRequest request,
  }) async {
    if (state.editingSimIds.contains(id)) return false;
    final editingIds = {...state.editingSimIds, id};
    state = state.copyWith(editingSimIds: editingIds, editErrorMessage: null);

    try {
      await _service.updateSimCard(id: id, request: request);
      if (!mounted) return false;
      final updatedIds = {...state.editingSimIds}..remove(id);
      state = state.copyWith(editingSimIds: updatedIds, editErrorMessage: null);
      await Future.wait([refreshSimCards(), refreshDevices()]);
      return true;
    } catch (error) {
      if (!mounted) return false;
      final updatedIds = {...state.editingSimIds}..remove(id);
      state = state.copyWith(
        editingSimIds: updatedIds,
        editErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  AdminInventoryState _applyDeviceFilters(AdminInventoryState next) {
    final normalized = next.deviceSearchQuery.trim().toLowerCase();

    final filtered = next.devices.where((item) {
      final matchesSearch = normalized.isEmpty ||
          <String>[
            item.imei,
            item.deviceType,
            item.assignedSimNumber,
            item.statusLabel,
          ].any((v) => v.toLowerCase().contains(normalized));

      final matchesStatus = switch (next.deviceStatusFilter) {
        AdminInventoryStatusFilter.all => true,
        AdminInventoryStatusFilter.inStock =>
          item.status == AdminInventoryStatus.inStock,
        AdminInventoryStatusFilter.inUse =>
          item.status == AdminInventoryStatus.inUse,
        AdminInventoryStatusFilter.inScrap =>
          item.status == AdminInventoryStatus.inScrap,
      };

      final matchesActive = switch (next.deviceActiveFilter) {
        AdminInventoryActiveFilter.all => true,
        AdminInventoryActiveFilter.active => item.isActive,
        AdminInventoryActiveFilter.inactive => !item.isActive,
      };

      return matchesSearch && matchesStatus && matchesActive;
    }).toList(growable: true);

    switch (next.deviceSortOption) {
      case AdminInventoryDeviceSortOption.newest:
        filtered.sort((a, b) {
          final ad = a.createdAt;
          final bd = b.createdAt;
          if (ad == null && bd == null) {
            return a.imei.toLowerCase().compareTo(b.imei.toLowerCase());
          }
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
      case AdminInventoryDeviceSortOption.imeiAsc:
        filtered.sort(
          (a, b) => a.imei.toLowerCase().compareTo(b.imei.toLowerCase()),
        );
      case AdminInventoryDeviceSortOption.typeAsc:
        filtered.sort(
          (a, b) =>
              a.deviceType.toLowerCase().compareTo(b.deviceType.toLowerCase()),
        );
      case AdminInventoryDeviceSortOption.activeFirst:
        filtered.sort((a, b) {
          final activeCompare =
              (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0);
          if (activeCompare != 0) return activeCompare;
          return a.imei.toLowerCase().compareTo(b.imei.toLowerCase());
        });
    }

    return next.copyWith(filteredDevices: filtered);
  }

  AdminInventoryState _applySimFilters(AdminInventoryState next) {
    final normalized = next.simSearchQuery.trim().toLowerCase();

    final filtered = next.simCards.where((item) {
      final matchesSearch = normalized.isEmpty ||
          <String>[
            item.simNumber,
            item.imsi,
            item.iccid,
            item.provider,
            item.associatedDeviceImeis.join(', '),
            item.associatedDeviceImei,
            item.statusLabel,
          ].any((v) => v.toLowerCase().contains(normalized));

      final matchesStatus = switch (next.simStatusFilter) {
        AdminInventoryStatusFilter.all => true,
        AdminInventoryStatusFilter.inStock =>
          item.status == AdminInventoryStatus.inStock,
        AdminInventoryStatusFilter.inUse =>
          item.status == AdminInventoryStatus.inUse,
        AdminInventoryStatusFilter.inScrap =>
          item.status == AdminInventoryStatus.inScrap,
      };

      final matchesActive = switch (next.simActiveFilter) {
        AdminInventoryActiveFilter.all => true,
        AdminInventoryActiveFilter.active => item.isActive,
        AdminInventoryActiveFilter.inactive => !item.isActive,
      };
      final provider = next.deviceProviderFilter?.trim().toLowerCase();
      final matchesProvider = provider == null || provider.isEmpty
          ? true
          : item.provider.toLowerCase() == provider;

      return matchesSearch && matchesStatus && matchesActive && matchesProvider;
    }).toList(growable: true);

    switch (next.simSortOption) {
      case AdminInventorySimSortOption.newest:
        filtered.sort((a, b) {
          final ad = a.createdAt;
          final bd = b.createdAt;
          if (ad == null && bd == null) {
            return a.simNumber
                .toLowerCase()
                .compareTo(b.simNumber.toLowerCase());
          }
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
      case AdminInventorySimSortOption.simNumberAsc:
        filtered.sort(
          (a, b) =>
              a.simNumber.toLowerCase().compareTo(b.simNumber.toLowerCase()),
        );
      case AdminInventorySimSortOption.providerAsc:
        filtered.sort(
          (a, b) =>
              a.provider.toLowerCase().compareTo(b.provider.toLowerCase()),
        );
      case AdminInventorySimSortOption.activeFirst:
        filtered.sort((a, b) {
          final activeCompare =
              (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0);
          if (activeCompare != 0) return activeCompare;
          return a.simNumber.toLowerCase().compareTo(b.simNumber.toLowerCase());
        });
    }

    return next.copyWith(filteredSimCards: filtered);
  }

  String _toErrorMessage(Object error) {
    if (error is ApiException) return error.message;

    if (error is DioException) {
      final message = _extractMessage(error.response?.data);
      if (message != null) return message;
      return error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : 'Unable to process request.';
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      final nested = data['data'];
      if (!identical(nested, data)) {
        return _extractMessage(nested);
      }
    }
    return null;
  }
}
