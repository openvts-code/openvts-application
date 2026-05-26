import 'admin_vehicle_model.dart';

enum AdminVehicleStatusFilter { all, active, inactive, licenseBlocked }

enum AdminVehicleDetailsTab {
  details,
  users,
  logs,
  commands,
  sensors,
  documents,
  config,
  events,
}

class AdminVehiclesState {
  const AdminVehiclesState({
    required this.vehicles,
    required this.filteredVehicles,
    required this.searchQuery,
    required this.statusFilter,
    required this.typeFilter,
    required this.isLoading,
    required this.isRefreshing,
    required this.isCreating,
    required this.updatingIds,
    required this.deletingIds,
    required this.errorMessage,
  });

  factory AdminVehiclesState.initial() => const AdminVehiclesState(
        vehicles: <AdminVehicleListItem>[],
        filteredVehicles: <AdminVehicleListItem>[],
        searchQuery: '',
        statusFilter: AdminVehicleStatusFilter.all,
        typeFilter: '',
        isLoading: false,
        isRefreshing: false,
        isCreating: false,
        updatingIds: <String>{},
        deletingIds: <String>{},
        errorMessage: null,
      );

  final List<AdminVehicleListItem> vehicles;
  final List<AdminVehicleListItem> filteredVehicles;
  final String searchQuery;
  final AdminVehicleStatusFilter statusFilter;
  final String typeFilter;
  final bool isLoading;
  final bool isRefreshing;
  final bool isCreating;
  final Set<String> updatingIds;
  final Set<String> deletingIds;
  final String? errorMessage;

  static const Object _unset = Object();

  AdminVehiclesState copyWith({
    List<AdminVehicleListItem>? vehicles,
    List<AdminVehicleListItem>? filteredVehicles,
    String? searchQuery,
    AdminVehicleStatusFilter? statusFilter,
    String? typeFilter,
    bool? isLoading,
    bool? isRefreshing,
    bool? isCreating,
    Set<String>? updatingIds,
    Set<String>? deletingIds,
    Object? errorMessage = _unset,
  }) {
    return AdminVehiclesState(
      vehicles: vehicles ?? this.vehicles,
      filteredVehicles: filteredVehicles ?? this.filteredVehicles,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCreating: isCreating ?? this.isCreating,
      updatingIds: updatingIds ?? this.updatingIds,
      deletingIds: deletingIds ?? this.deletingIds,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class AdminVehicleDetailsState {
  const AdminVehicleDetailsState({
    required this.vehicleId,
    required this.initialVehicle,
    required this.vehicle,
    required this.selectedTab,
    required this.linkedUsers,
    required this.availableUsers,
    required this.logs,
    required this.logNextCursor,
    required this.events,
    required this.eventNextCursor,
    required this.commandHistory,
    required this.sensors,
    required this.documents,
    required this.documentTypes,
    required this.vehicleTypes,
    required this.timezones,
    required this.quickDevices,
    required this.pricingPlans,
    required this.customCommands,
    required this.systemVariables,
    required this.isLoadingVehicle,
    required this.isLoadingUsers,
    required this.isLoadingLogs,
    required this.isLoadingMoreLogs,
    required this.isLoadingEvents,
    required this.isLoadingMoreEvents,
    required this.isLoadingCommands,
    required this.isLoadingSensors,
    required this.isLoadingDocuments,
    required this.isLoadingReferences,
    required this.isUpdatingVehicle,
    required this.isUpdatingStatus,
    required this.isDeletingVehicle,
    required this.isUpdatingConfig,
    required this.isLinkingUser,
    required this.isUnlinkingUser,
    required this.isSendingCommand,
    required this.isUploadingDocument,
    required this.isUpdatingDocument,
    required this.isDeletingDocument,
    required this.isCreatingSensor,
    required this.isUpdatingSensor,
    required this.isDeletingSensor,
    required this.isRunningSensor,
    required this.errorMessage,
    required this.sectionErrorMessage,
  });

  factory AdminVehicleDetailsState.initial({
    required String vehicleId,
    AdminVehicleDetails? initialVehicle,
  }) {
    return AdminVehicleDetailsState(
      vehicleId: vehicleId,
      initialVehicle: initialVehicle,
      vehicle: initialVehicle,
      selectedTab: AdminVehicleDetailsTab.details,
      linkedUsers: const <AdminVehicleUserMini>[],
      availableUsers: const <AdminVehicleUserMini>[],
      logs: const <AdminVehicleLogItem>[],
      logNextCursor: null,
      events: const <AdminVehicleEventItem>[],
      eventNextCursor: null,
      commandHistory: const <AdminVehicleCommandItem>[],
      sensors: const <AdminVehicleSensor>[],
      documents: const <AdminVehicleDocument>[],
      documentTypes: const <AdminVehicleDocumentType>[],
      vehicleTypes: const <AdminVehicleTypeOption>[],
      timezones: const <String>[],
      quickDevices: const <AdminQuickDeviceOption>[],
      pricingPlans: const <AdminPricingPlanOption>[],
      customCommands: const <AdminCustomCommand>[],
      systemVariables: const <AdminSystemVariable>[],
      isLoadingVehicle: false,
      isLoadingUsers: false,
      isLoadingLogs: false,
      isLoadingMoreLogs: false,
      isLoadingEvents: false,
      isLoadingMoreEvents: false,
      isLoadingCommands: false,
      isLoadingSensors: false,
      isLoadingDocuments: false,
      isLoadingReferences: false,
      isUpdatingVehicle: false,
      isUpdatingStatus: false,
      isDeletingVehicle: false,
      isUpdatingConfig: false,
      isLinkingUser: false,
      isUnlinkingUser: false,
      isSendingCommand: false,
      isUploadingDocument: false,
      isUpdatingDocument: false,
      isDeletingDocument: false,
      isCreatingSensor: false,
      isUpdatingSensor: false,
      isDeletingSensor: false,
      isRunningSensor: false,
      errorMessage: null,
      sectionErrorMessage: null,
    );
  }

  final String vehicleId;
  final AdminVehicleDetails? initialVehicle;
  final AdminVehicleDetails? vehicle;
  final AdminVehicleDetailsTab selectedTab;
  final List<AdminVehicleUserMini> linkedUsers;
  final List<AdminVehicleUserMini> availableUsers;
  final List<AdminVehicleLogItem> logs;
  final String? logNextCursor;
  final List<AdminVehicleEventItem> events;
  final String? eventNextCursor;
  final List<AdminVehicleCommandItem> commandHistory;
  final List<AdminVehicleSensor> sensors;
  final List<AdminVehicleDocument> documents;
  final List<AdminVehicleDocumentType> documentTypes;
  final List<AdminVehicleTypeOption> vehicleTypes;
  final List<String> timezones;
  final List<AdminQuickDeviceOption> quickDevices;
  final List<AdminPricingPlanOption> pricingPlans;
  final List<AdminCustomCommand> customCommands;
  final List<AdminSystemVariable> systemVariables;

  final bool isLoadingVehicle;
  final bool isLoadingUsers;
  final bool isLoadingLogs;
  final bool isLoadingMoreLogs;
  final bool isLoadingEvents;
  final bool isLoadingMoreEvents;
  final bool isLoadingCommands;
  final bool isLoadingSensors;
  final bool isLoadingDocuments;
  final bool isLoadingReferences;

  final bool isUpdatingVehicle;
  final bool isUpdatingStatus;
  final bool isDeletingVehicle;
  final bool isUpdatingConfig;
  final bool isLinkingUser;
  final bool isUnlinkingUser;
  final bool isSendingCommand;
  final bool isUploadingDocument;
  final bool isUpdatingDocument;
  final bool isDeletingDocument;
  final bool isCreatingSensor;
  final bool isUpdatingSensor;
  final bool isDeletingSensor;
  final bool isRunningSensor;

  final String? errorMessage;
  final String? sectionErrorMessage;

  static const Object _unset = Object();

  AdminVehicleDetailsState copyWith({
    Object? initialVehicle = _unset,
    Object? vehicle = _unset,
    AdminVehicleDetailsTab? selectedTab,
    List<AdminVehicleUserMini>? linkedUsers,
    List<AdminVehicleUserMini>? availableUsers,
    List<AdminVehicleLogItem>? logs,
    Object? logNextCursor = _unset,
    List<AdminVehicleEventItem>? events,
    Object? eventNextCursor = _unset,
    List<AdminVehicleCommandItem>? commandHistory,
    List<AdminVehicleSensor>? sensors,
    List<AdminVehicleDocument>? documents,
    List<AdminVehicleDocumentType>? documentTypes,
    List<AdminVehicleTypeOption>? vehicleTypes,
    List<String>? timezones,
    List<AdminQuickDeviceOption>? quickDevices,
    List<AdminPricingPlanOption>? pricingPlans,
    List<AdminCustomCommand>? customCommands,
    List<AdminSystemVariable>? systemVariables,
    bool? isLoadingVehicle,
    bool? isLoadingUsers,
    bool? isLoadingLogs,
    bool? isLoadingMoreLogs,
    bool? isLoadingEvents,
    bool? isLoadingMoreEvents,
    bool? isLoadingCommands,
    bool? isLoadingSensors,
    bool? isLoadingDocuments,
    bool? isLoadingReferences,
    bool? isUpdatingVehicle,
    bool? isUpdatingStatus,
    bool? isDeletingVehicle,
    bool? isUpdatingConfig,
    bool? isLinkingUser,
    bool? isUnlinkingUser,
    bool? isSendingCommand,
    bool? isUploadingDocument,
    bool? isUpdatingDocument,
    bool? isDeletingDocument,
    bool? isCreatingSensor,
    bool? isUpdatingSensor,
    bool? isDeletingSensor,
    bool? isRunningSensor,
    Object? errorMessage = _unset,
    Object? sectionErrorMessage = _unset,
  }) {
    return AdminVehicleDetailsState(
      vehicleId: vehicleId,
      initialVehicle: identical(initialVehicle, _unset)
          ? this.initialVehicle
          : initialVehicle as AdminVehicleDetails?,
      vehicle: identical(vehicle, _unset)
          ? this.vehicle
          : vehicle as AdminVehicleDetails?,
      selectedTab: selectedTab ?? this.selectedTab,
      linkedUsers: linkedUsers ?? this.linkedUsers,
      availableUsers: availableUsers ?? this.availableUsers,
      logs: logs ?? this.logs,
      logNextCursor: identical(logNextCursor, _unset)
          ? this.logNextCursor
          : logNextCursor as String?,
      events: events ?? this.events,
      eventNextCursor: identical(eventNextCursor, _unset)
          ? this.eventNextCursor
          : eventNextCursor as String?,
      commandHistory: commandHistory ?? this.commandHistory,
      sensors: sensors ?? this.sensors,
      documents: documents ?? this.documents,
      documentTypes: documentTypes ?? this.documentTypes,
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      timezones: timezones ?? this.timezones,
      quickDevices: quickDevices ?? this.quickDevices,
      pricingPlans: pricingPlans ?? this.pricingPlans,
      customCommands: customCommands ?? this.customCommands,
      systemVariables: systemVariables ?? this.systemVariables,
      isLoadingVehicle: isLoadingVehicle ?? this.isLoadingVehicle,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isLoadingLogs: isLoadingLogs ?? this.isLoadingLogs,
      isLoadingMoreLogs: isLoadingMoreLogs ?? this.isLoadingMoreLogs,
      isLoadingEvents: isLoadingEvents ?? this.isLoadingEvents,
      isLoadingMoreEvents: isLoadingMoreEvents ?? this.isLoadingMoreEvents,
      isLoadingCommands: isLoadingCommands ?? this.isLoadingCommands,
      isLoadingSensors: isLoadingSensors ?? this.isLoadingSensors,
      isLoadingDocuments: isLoadingDocuments ?? this.isLoadingDocuments,
      isLoadingReferences: isLoadingReferences ?? this.isLoadingReferences,
      isUpdatingVehicle: isUpdatingVehicle ?? this.isUpdatingVehicle,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      isDeletingVehicle: isDeletingVehicle ?? this.isDeletingVehicle,
      isUpdatingConfig: isUpdatingConfig ?? this.isUpdatingConfig,
      isLinkingUser: isLinkingUser ?? this.isLinkingUser,
      isUnlinkingUser: isUnlinkingUser ?? this.isUnlinkingUser,
      isSendingCommand: isSendingCommand ?? this.isSendingCommand,
      isUploadingDocument: isUploadingDocument ?? this.isUploadingDocument,
      isUpdatingDocument: isUpdatingDocument ?? this.isUpdatingDocument,
      isDeletingDocument: isDeletingDocument ?? this.isDeletingDocument,
      isCreatingSensor: isCreatingSensor ?? this.isCreatingSensor,
      isUpdatingSensor: isUpdatingSensor ?? this.isUpdatingSensor,
      isDeletingSensor: isDeletingSensor ?? this.isDeletingSensor,
      isRunningSensor: isRunningSensor ?? this.isRunningSensor,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      sectionErrorMessage: identical(sectionErrorMessage, _unset)
          ? this.sectionErrorMessage
          : sectionErrorMessage as String?,
    );
  }
}
