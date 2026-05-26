import 'admin_inventory_model.dart';

class AdminInventoryState {
  const AdminInventoryState({
    required this.selectedTab,
    required this.devices,
    required this.filteredDevices,
    required this.simCards,
    required this.filteredSimCards,
    required this.deviceSearchQuery,
    required this.simSearchQuery,
    required this.deviceStatusFilter,
    required this.simStatusFilter,
    required this.deviceActiveFilter,
    required this.simActiveFilter,
    required this.deviceSortOption,
    required this.simSortOption,
    required this.deviceProviderFilter,
    required this.deviceRecordsPerPage,
    required this.deviceCurrentPage,
    required this.simRecordsPerPage,
    required this.simCurrentPage,
    required this.isLoadingDevices,
    required this.isLoadingSimCards,
    required this.isRefreshingDevices,
    required this.isRefreshingSimCards,
    required this.isCreating,
    required this.editingDeviceIds,
    required this.editingSimIds,
    required this.deviceTypes,
    required this.simProviders,
    required this.quickSimcards,
    required this.errorMessage,
    required this.devicesErrorMessage,
    required this.simCardsErrorMessage,
    required this.createErrorMessage,
    required this.editErrorMessage,
    required this.devicesRefreshKey,
    required this.simCardsRefreshKey,
  });

  const AdminInventoryState.initial()
      : selectedTab = AdminInventoryTab.devices,
        devices = const <AdminInventoryDevice>[],
        filteredDevices = const <AdminInventoryDevice>[],
        simCards = const <AdminInventorySimCard>[],
        filteredSimCards = const <AdminInventorySimCard>[],
        deviceSearchQuery = '',
        simSearchQuery = '',
        deviceStatusFilter = AdminInventoryStatusFilter.all,
        simStatusFilter = AdminInventoryStatusFilter.all,
        deviceActiveFilter = AdminInventoryActiveFilter.all,
        simActiveFilter = AdminInventoryActiveFilter.all,
        deviceSortOption = AdminInventoryDeviceSortOption.newest,
        simSortOption = AdminInventorySimSortOption.newest,
        deviceProviderFilter = null,
        deviceRecordsPerPage = 10,
        deviceCurrentPage = 1,
        simRecordsPerPage = 10,
        simCurrentPage = 1,
        isLoadingDevices = true,
        isLoadingSimCards = false,
        isRefreshingDevices = false,
        isRefreshingSimCards = false,
        isCreating = false,
        editingDeviceIds = const <String>{},
        editingSimIds = const <String>{},
        deviceTypes = const <AdminDeviceTypeOption>[],
        simProviders = const <AdminSimProviderOption>[],
        quickSimcards = const <AdminQuickSimCardOption>[],
        errorMessage = null,
        devicesErrorMessage = null,
        simCardsErrorMessage = null,
        createErrorMessage = null,
        editErrorMessage = null,
        devicesRefreshKey = 0,
        simCardsRefreshKey = 0;

  static const _unset = Object();

  final String selectedTab;
  final List<AdminInventoryDevice> devices;
  final List<AdminInventoryDevice> filteredDevices;
  final List<AdminInventorySimCard> simCards;
  final List<AdminInventorySimCard> filteredSimCards;
  final String deviceSearchQuery;
  final String simSearchQuery;
  final AdminInventoryStatusFilter deviceStatusFilter;
  final AdminInventoryStatusFilter simStatusFilter;
  final AdminInventoryActiveFilter deviceActiveFilter;
  final AdminInventoryActiveFilter simActiveFilter;
  final AdminInventoryDeviceSortOption deviceSortOption;
  final AdminInventorySimSortOption simSortOption;
  final String? deviceProviderFilter;
  final int deviceRecordsPerPage;
  final int deviceCurrentPage;
  final int simRecordsPerPage;
  final int simCurrentPage;
  final bool isLoadingDevices;
  final bool isLoadingSimCards;
  final bool isRefreshingDevices;
  final bool isRefreshingSimCards;
  final bool isCreating;
  final Set<String> editingDeviceIds;
  final Set<String> editingSimIds;
  final List<AdminDeviceTypeOption> deviceTypes;
  final List<AdminSimProviderOption> simProviders;
  final List<AdminQuickSimCardOption> quickSimcards;
  final String? errorMessage;
  final String? devicesErrorMessage;
  final String? simCardsErrorMessage;
  final String? createErrorMessage;
  final String? editErrorMessage;
  final int devicesRefreshKey;
  final int simCardsRefreshKey;

  int get deviceFilteredCount => filteredDevices.length;
  int get simFilteredCount => filteredSimCards.length;
  int get devicePageCount {
    if (deviceFilteredCount <= 0) return 1;
    return ((deviceFilteredCount - 1) ~/ deviceRecordsPerPage) + 1;
  }

  int get simPageCount {
    if (simFilteredCount <= 0) return 1;
    return ((simFilteredCount - 1) ~/ simRecordsPerPage) + 1;
  }

  int get safeDeviceCurrentPage {
    if (deviceCurrentPage < 1) {
      return 1;
    }
    if (deviceCurrentPage > devicePageCount) {
      return devicePageCount;
    }
    return deviceCurrentPage;
  }

  int get safeSimCurrentPage {
    if (simCurrentPage < 1) {
      return 1;
    }
    if (simCurrentPage > simPageCount) {
      return simPageCount;
    }
    return simCurrentPage;
  }

  List<AdminInventoryDevice> get visibleDevices {
    if (filteredDevices.isEmpty) {
      return const <AdminInventoryDevice>[];
    }
    final start = (safeDeviceCurrentPage - 1) * deviceRecordsPerPage;
    if (start >= filteredDevices.length) {
      return const <AdminInventoryDevice>[];
    }
    final end = (start + deviceRecordsPerPage).clamp(0, filteredDevices.length);
    return filteredDevices.sublist(start, end);
  }

  List<AdminInventorySimCard> get visibleSimCards {
    if (filteredSimCards.isEmpty) {
      return const <AdminInventorySimCard>[];
    }
    final start = (safeSimCurrentPage - 1) * simRecordsPerPage;
    if (start >= filteredSimCards.length) {
      return const <AdminInventorySimCard>[];
    }
    final end = (start + simRecordsPerPage).clamp(0, filteredSimCards.length);
    return filteredSimCards.sublist(start, end);
  }

  int get deviceShowingCount => visibleDevices.length;
  int get simShowingCount => visibleSimCards.length;

  AdminInventoryState copyWith({
    String? selectedTab,
    List<AdminInventoryDevice>? devices,
    List<AdminInventoryDevice>? filteredDevices,
    List<AdminInventorySimCard>? simCards,
    List<AdminInventorySimCard>? filteredSimCards,
    String? deviceSearchQuery,
    String? simSearchQuery,
    AdminInventoryStatusFilter? deviceStatusFilter,
    AdminInventoryStatusFilter? simStatusFilter,
    AdminInventoryActiveFilter? deviceActiveFilter,
    AdminInventoryActiveFilter? simActiveFilter,
    AdminInventoryDeviceSortOption? deviceSortOption,
    AdminInventorySimSortOption? simSortOption,
    Object? deviceProviderFilter = _unset,
    int? deviceRecordsPerPage,
    int? deviceCurrentPage,
    int? simRecordsPerPage,
    int? simCurrentPage,
    bool? isLoadingDevices,
    bool? isLoadingSimCards,
    bool? isRefreshingDevices,
    bool? isRefreshingSimCards,
    bool? isCreating,
    Set<String>? editingDeviceIds,
    Set<String>? editingSimIds,
    List<AdminDeviceTypeOption>? deviceTypes,
    List<AdminSimProviderOption>? simProviders,
    List<AdminQuickSimCardOption>? quickSimcards,
    Object? errorMessage = _unset,
    Object? devicesErrorMessage = _unset,
    Object? simCardsErrorMessage = _unset,
    Object? createErrorMessage = _unset,
    Object? editErrorMessage = _unset,
    int? devicesRefreshKey,
    int? simCardsRefreshKey,
  }) {
    return AdminInventoryState(
      selectedTab: selectedTab ?? this.selectedTab,
      devices: devices ?? this.devices,
      filteredDevices: filteredDevices ?? this.filteredDevices,
      simCards: simCards ?? this.simCards,
      filteredSimCards: filteredSimCards ?? this.filteredSimCards,
      deviceSearchQuery: deviceSearchQuery ?? this.deviceSearchQuery,
      simSearchQuery: simSearchQuery ?? this.simSearchQuery,
      deviceStatusFilter: deviceStatusFilter ?? this.deviceStatusFilter,
      simStatusFilter: simStatusFilter ?? this.simStatusFilter,
      deviceActiveFilter: deviceActiveFilter ?? this.deviceActiveFilter,
      simActiveFilter: simActiveFilter ?? this.simActiveFilter,
      deviceSortOption: deviceSortOption ?? this.deviceSortOption,
      simSortOption: simSortOption ?? this.simSortOption,
      deviceProviderFilter: identical(deviceProviderFilter, _unset)
          ? this.deviceProviderFilter
          : deviceProviderFilter as String?,
      deviceRecordsPerPage: deviceRecordsPerPage ?? this.deviceRecordsPerPage,
      deviceCurrentPage: deviceCurrentPage ?? this.deviceCurrentPage,
      simRecordsPerPage: simRecordsPerPage ?? this.simRecordsPerPage,
      simCurrentPage: simCurrentPage ?? this.simCurrentPage,
      isLoadingDevices: isLoadingDevices ?? this.isLoadingDevices,
      isLoadingSimCards: isLoadingSimCards ?? this.isLoadingSimCards,
      isRefreshingDevices: isRefreshingDevices ?? this.isRefreshingDevices,
      isRefreshingSimCards: isRefreshingSimCards ?? this.isRefreshingSimCards,
      isCreating: isCreating ?? this.isCreating,
      editingDeviceIds: editingDeviceIds ?? this.editingDeviceIds,
      editingSimIds: editingSimIds ?? this.editingSimIds,
      deviceTypes: deviceTypes ?? this.deviceTypes,
      simProviders: simProviders ?? this.simProviders,
      quickSimcards: quickSimcards ?? this.quickSimcards,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      devicesErrorMessage: identical(devicesErrorMessage, _unset)
          ? this.devicesErrorMessage
          : devicesErrorMessage as String?,
      simCardsErrorMessage: identical(simCardsErrorMessage, _unset)
          ? this.simCardsErrorMessage
          : simCardsErrorMessage as String?,
      createErrorMessage: identical(createErrorMessage, _unset)
          ? this.createErrorMessage
          : createErrorMessage as String?,
      editErrorMessage: identical(editErrorMessage, _unset)
          ? this.editErrorMessage
          : editErrorMessage as String?,
      devicesRefreshKey: devicesRefreshKey ?? this.devicesRefreshKey,
      simCardsRefreshKey: simCardsRefreshKey ?? this.simCardsRefreshKey,
    );
  }
}
