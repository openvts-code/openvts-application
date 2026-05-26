import 'user_vehicle_model.dart';

enum UserVehicleStatusFilter { all, active, inactive, licenseBlocked }

enum UserVehicleDetailsTab { details, sensors, documents, config }

class UserVehiclesState {
  const UserVehiclesState({
    this.vehicles = const <UserVehicleListItem>[],
    this.filteredVehicles = const <UserVehicleListItem>[],
    this.searchQuery = '',
    this.statusFilter = UserVehicleStatusFilter.all,
    this.typeFilter,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.refreshKey,
  });

  const UserVehiclesState.initial()
      : this(
          isLoading: true,
        );

  static const Object _unset = Object();

  final List<UserVehicleListItem> vehicles;
  final List<UserVehicleListItem> filteredVehicles;
  final String searchQuery;
  final UserVehicleStatusFilter statusFilter;
  final String? typeFilter;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final String? refreshKey;

  bool get hasActiveFilters {
    return searchQuery.trim().isNotEmpty ||
        statusFilter != UserVehicleStatusFilter.all ||
        (typeFilter?.trim().isNotEmpty ?? false);
  }

  UserVehiclesState copyWith({
    List<UserVehicleListItem>? vehicles,
    List<UserVehicleListItem>? filteredVehicles,
    String? searchQuery,
    UserVehicleStatusFilter? statusFilter,
    Object? typeFilter = _unset,
    bool? isLoading,
    bool? isRefreshing,
    Object? errorMessage = _unset,
    Object? refreshKey = _unset,
  }) {
    return UserVehiclesState(
      vehicles: vehicles ?? this.vehicles,
      filteredVehicles: filteredVehicles ?? this.filteredVehicles,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: identical(typeFilter, _unset)
          ? this.typeFilter
          : typeFilter as String?,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      refreshKey: identical(refreshKey, _unset)
          ? this.refreshKey
          : refreshKey as String?,
    );
  }
}

class UserVehicleDetailsState {
  const UserVehicleDetailsState({
    required this.vehicleId,
    required this.initialVehicle,
    required this.vehicle,
    required this.selectedTab,
    required this.sensors,
    required this.documents,
    required this.documentTypes,
    required this.vehicleTypes,
    required this.timezones,
    required this.telemetryPayload,
    required this.isLoadingVehicle,
    required this.isRefreshing,
    required this.isLoadingSensors,
    required this.isLoadingSensorTelemetry,
    required this.isLoadingSensorHistory,
    required this.isLoadingDocuments,
    required this.isLoadingDocumentTypes,
    required this.isLoadingReferenceData,
    required this.isSavingVehicle,
    required this.isSavingConfig,
    required this.isCreatingSensor,
    required this.isUpdatingSensor,
    required this.isDeletingSensor,
    required this.isRunningSensor,
    required this.isUploadingDocument,
    required this.isUpdatingDocument,
    required this.isDeletingDocument,
    required this.errorMessage,
    required this.sectionErrorMessage,
  });

  UserVehicleDetailsState.initial({
    required this.vehicleId,
    this.initialVehicle,
  })  : vehicle = null,
        selectedTab = UserVehicleDetailsTab.details,
        sensors = const <UserVehicleSensor>[],
        documents = const <UserVehicleDocument>[],
        documentTypes = const <UserVehicleDocumentType>[],
        vehicleTypes = const <UserVehicleTypeOption>[],
        timezones = const <String>[],
        telemetryPayload = null,
        isLoadingVehicle = false,
        isRefreshing = false,
        isLoadingSensors = false,
        isLoadingSensorTelemetry = false,
        isLoadingSensorHistory = false,
        isLoadingDocuments = false,
        isLoadingDocumentTypes = false,
        isLoadingReferenceData = false,
        isSavingVehicle = false,
        isSavingConfig = false,
        isCreatingSensor = false,
        isUpdatingSensor = false,
        isDeletingSensor = false,
        isRunningSensor = false,
        isUploadingDocument = false,
        isUpdatingDocument = false,
        isDeletingDocument = false,
        errorMessage = null,
        sectionErrorMessage = null;

  static const Object _unset = Object();

  final String vehicleId;
  final UserVehicleListItem? initialVehicle;
  final UserVehicleDetails? vehicle;
  final UserVehicleDetailsTab selectedTab;
  final List<UserVehicleSensor> sensors;
  final List<UserVehicleDocument> documents;
  final List<UserVehicleDocumentType> documentTypes;
  final List<UserVehicleTypeOption> vehicleTypes;
  final List<String> timezones;
  final UserVehicleSensorTelemetry? telemetryPayload;
  final bool isLoadingVehicle;
  final bool isRefreshing;
  final bool isLoadingSensors;
  final bool isLoadingSensorTelemetry;
  final bool isLoadingSensorHistory;
  final bool isLoadingDocuments;
  final bool isLoadingDocumentTypes;
  final bool isLoadingReferenceData;
  final bool isSavingVehicle;
  final bool isSavingConfig;
  final bool isCreatingSensor;
  final bool isUpdatingSensor;
  final bool isDeletingSensor;
  final bool isRunningSensor;
  final bool isUploadingDocument;
  final bool isUpdatingDocument;
  final bool isDeletingDocument;
  final String? errorMessage;
  final String? sectionErrorMessage;

  bool get hasVehicle => vehicle != null || initialVehicle != null;
  bool get hasReferenceData => vehicleTypes.isNotEmpty || timezones.isNotEmpty;
  bool get hasDocumentReferenceData => documentTypes.isNotEmpty;

  bool get isRefreshingCurrentTab {
    return switch (selectedTab) {
      UserVehicleDetailsTab.details => isLoadingVehicle || isRefreshing,
      UserVehicleDetailsTab.sensors => isLoadingSensors,
      UserVehicleDetailsTab.documents =>
        isLoadingDocuments || isLoadingDocumentTypes,
      UserVehicleDetailsTab.config => isLoadingVehicle || isRefreshing,
    };
  }

  UserVehicleDetailsState copyWith({
    Object? initialVehicle = _unset,
    Object? vehicle = _unset,
    UserVehicleDetailsTab? selectedTab,
    List<UserVehicleSensor>? sensors,
    List<UserVehicleDocument>? documents,
    List<UserVehicleDocumentType>? documentTypes,
    List<UserVehicleTypeOption>? vehicleTypes,
    List<String>? timezones,
    Object? telemetryPayload = _unset,
    bool? isLoadingVehicle,
    bool? isRefreshing,
    bool? isLoadingSensors,
    bool? isLoadingSensorTelemetry,
    bool? isLoadingSensorHistory,
    bool? isLoadingDocuments,
    bool? isLoadingDocumentTypes,
    bool? isLoadingReferenceData,
    bool? isSavingVehicle,
    bool? isSavingConfig,
    bool? isCreatingSensor,
    bool? isUpdatingSensor,
    bool? isDeletingSensor,
    bool? isRunningSensor,
    bool? isUploadingDocument,
    bool? isUpdatingDocument,
    bool? isDeletingDocument,
    Object? errorMessage = _unset,
    Object? sectionErrorMessage = _unset,
  }) {
    return UserVehicleDetailsState(
      vehicleId: vehicleId,
      initialVehicle: identical(initialVehicle, _unset)
          ? this.initialVehicle
          : initialVehicle as UserVehicleListItem?,
      vehicle: identical(vehicle, _unset)
          ? this.vehicle
          : vehicle as UserVehicleDetails?,
      selectedTab: selectedTab ?? this.selectedTab,
      sensors: sensors ?? this.sensors,
      documents: documents ?? this.documents,
      documentTypes: documentTypes ?? this.documentTypes,
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      timezones: timezones ?? this.timezones,
      telemetryPayload: identical(telemetryPayload, _unset)
          ? this.telemetryPayload
          : telemetryPayload as UserVehicleSensorTelemetry?,
      isLoadingVehicle: isLoadingVehicle ?? this.isLoadingVehicle,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingSensors: isLoadingSensors ?? this.isLoadingSensors,
      isLoadingSensorTelemetry:
          isLoadingSensorTelemetry ?? this.isLoadingSensorTelemetry,
      isLoadingSensorHistory:
          isLoadingSensorHistory ?? this.isLoadingSensorHistory,
      isLoadingDocuments: isLoadingDocuments ?? this.isLoadingDocuments,
      isLoadingDocumentTypes:
          isLoadingDocumentTypes ?? this.isLoadingDocumentTypes,
      isLoadingReferenceData:
          isLoadingReferenceData ?? this.isLoadingReferenceData,
      isSavingVehicle: isSavingVehicle ?? this.isSavingVehicle,
      isSavingConfig: isSavingConfig ?? this.isSavingConfig,
      isCreatingSensor: isCreatingSensor ?? this.isCreatingSensor,
      isUpdatingSensor: isUpdatingSensor ?? this.isUpdatingSensor,
      isDeletingSensor: isDeletingSensor ?? this.isDeletingSensor,
      isRunningSensor: isRunningSensor ?? this.isRunningSensor,
      isUploadingDocument: isUploadingDocument ?? this.isUploadingDocument,
      isUpdatingDocument: isUpdatingDocument ?? this.isUpdatingDocument,
      isDeletingDocument: isDeletingDocument ?? this.isDeletingDocument,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      sectionErrorMessage: identical(sectionErrorMessage, _unset)
          ? this.sectionErrorMessage
          : sectionErrorMessage as String?,
    );
  }
}
