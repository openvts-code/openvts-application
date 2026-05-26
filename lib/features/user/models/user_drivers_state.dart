import 'user_driver_model.dart';

enum UserDriverStatusFilter {
  all,
  active,
  inactive,
}

enum UserDriverAssignmentFilter {
  all,
  assigned,
  unassigned,
}

enum UserDriverVerificationFilter {
  all,
  verified,
  unverified,
}

class UserDriversState {
  const UserDriversState({
    this.drivers = const <UserDriver>[],
    this.searchQuery = '',
    this.selectedStatusFilter = UserDriverStatusFilter.all,
    this.selectedAssignmentFilter = UserDriverAssignmentFilter.all,
    this.selectedVerificationFilter = UserDriverVerificationFilter.all,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isCreating = false,
    this.errorMessage,
    this.refreshKey,
  });

  const UserDriversState.initial()
      : this(
          isLoading: true,
        );

  static const Object _unset = Object();

  final List<UserDriver> drivers;
  final String searchQuery;
  final UserDriverStatusFilter selectedStatusFilter;
  final UserDriverAssignmentFilter selectedAssignmentFilter;
  final UserDriverVerificationFilter selectedVerificationFilter;
  final bool isLoading;
  final bool isRefreshing;
  final bool isCreating;
  final String? errorMessage;
  final String? refreshKey;

  List<UserDriver> get filteredDrivers {
    final normalizedQuery = searchQuery.trim().toLowerCase();

    return drivers.where((driver) {
      if (normalizedQuery.isNotEmpty &&
          !driver.searchContent.contains(normalizedQuery)) {
        return false;
      }

      final statusMatches = switch (selectedStatusFilter) {
        UserDriverStatusFilter.all => true,
        UserDriverStatusFilter.active => driver.isActive,
        UserDriverStatusFilter.inactive => !driver.isActive,
      };

      if (!statusMatches) {
        return false;
      }

      final assignmentMatches = switch (selectedAssignmentFilter) {
        UserDriverAssignmentFilter.all => true,
        UserDriverAssignmentFilter.assigned => driver.hasAssignedVehicle,
        UserDriverAssignmentFilter.unassigned => !driver.hasAssignedVehicle,
      };

      if (!assignmentMatches) {
        return false;
      }

      return switch (selectedVerificationFilter) {
        UserDriverVerificationFilter.all => true,
        UserDriverVerificationFilter.verified => driver.isVerified,
        UserDriverVerificationFilter.unverified => !driver.isVerified,
      };
    }).toList(growable: false);
  }

  int get activeCount => drivers.where((item) => item.isActive).length;
  int get inactiveCount => drivers.where((item) => !item.isActive).length;
  int get verifiedCount => drivers.where((item) => item.isVerified).length;
  int get assignedCount =>
      drivers.where((item) => item.hasAssignedVehicle).length;
  int get unassignedCount =>
      drivers.where((item) => !item.hasAssignedVehicle).length;

  bool get hasDrivers => drivers.isNotEmpty;

  bool get hasActiveFilters {
    return searchQuery.trim().isNotEmpty ||
        selectedStatusFilter != UserDriverStatusFilter.all ||
        selectedAssignmentFilter != UserDriverAssignmentFilter.all ||
        selectedVerificationFilter != UserDriverVerificationFilter.all;
  }

  UserDriversState copyWith({
    List<UserDriver>? drivers,
    String? searchQuery,
    UserDriverStatusFilter? selectedStatusFilter,
    UserDriverAssignmentFilter? selectedAssignmentFilter,
    UserDriverVerificationFilter? selectedVerificationFilter,
    bool? isLoading,
    bool? isRefreshing,
    bool? isCreating,
    Object? errorMessage = _unset,
    Object? refreshKey = _unset,
  }) {
    return UserDriversState(
      drivers: drivers ?? this.drivers,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      selectedAssignmentFilter:
          selectedAssignmentFilter ?? this.selectedAssignmentFilter,
      selectedVerificationFilter:
          selectedVerificationFilter ?? this.selectedVerificationFilter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      refreshKey: identical(refreshKey, _unset)
          ? this.refreshKey
          : refreshKey as String?,
    );
  }
}

class UserDriverDetailsState {
  const UserDriverDetailsState({
    required this.driverId,
    required this.driver,
    required this.logs,
    required this.documents,
    required this.documentTypes,
    required this.availableVehicles,
    required this.isLoading,
    required this.isSaving,
    required this.isDeleting,
    required this.isAssigning,
    required this.isUnassigning,
    required this.isLoadingLogs,
    required this.isLoadingDocuments,
    required this.isUploadingDocument,
    required this.errorMessage,
  });

  UserDriverDetailsState.initial({
    required this.driverId,
    UserDriver? initialDriver,
  })  : driver = initialDriver,
        logs = const <UserDriverLog>[],
        documents = const <UserDriverDocument>[],
        documentTypes = const <UserDriverDocumentType>[],
        availableVehicles = const <UserDriverVehicleMini>[],
        isLoading = true,
        isSaving = false,
        isDeleting = false,
        isAssigning = false,
        isUnassigning = false,
        isLoadingLogs = false,
        isLoadingDocuments = false,
        isUploadingDocument = false,
        errorMessage = null;

  static const Object _unset = Object();

  final String driverId;
  final UserDriver? driver;
  final List<UserDriverLog> logs;
  final List<UserDriverDocument> documents;
  final List<UserDriverDocumentType> documentTypes;
  final List<UserDriverVehicleMini> availableVehicles;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final bool isAssigning;
  final bool isUnassigning;
  final bool isLoadingLogs;
  final bool isLoadingDocuments;
  final bool isUploadingDocument;
  final String? errorMessage;

  bool get hasDriver => driver != null;
  bool get hasAssignment => driver?.hasAssignedVehicle ?? false;

  UserDriverDetailsState copyWith({
    Object? driver = _unset,
    List<UserDriverLog>? logs,
    List<UserDriverDocument>? documents,
    List<UserDriverDocumentType>? documentTypes,
    List<UserDriverVehicleMini>? availableVehicles,
    bool? isLoading,
    bool? isSaving,
    bool? isDeleting,
    bool? isAssigning,
    bool? isUnassigning,
    bool? isLoadingLogs,
    bool? isLoadingDocuments,
    bool? isUploadingDocument,
    Object? errorMessage = _unset,
  }) {
    return UserDriverDetailsState(
      driverId: driverId,
      driver: identical(driver, _unset) ? this.driver : driver as UserDriver?,
      logs: logs ?? this.logs,
      documents: documents ?? this.documents,
      documentTypes: documentTypes ?? this.documentTypes,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      isAssigning: isAssigning ?? this.isAssigning,
      isUnassigning: isUnassigning ?? this.isUnassigning,
      isLoadingLogs: isLoadingLogs ?? this.isLoadingLogs,
      isLoadingDocuments: isLoadingDocuments ?? this.isLoadingDocuments,
      isUploadingDocument: isUploadingDocument ?? this.isUploadingDocument,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
