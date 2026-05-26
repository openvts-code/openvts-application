import 'user_landmark_model.dart';

// ---------------------------------------------------------------------------
// Geofences list state
// ---------------------------------------------------------------------------

class UserGeofencesState {
  const UserGeofencesState({
    required this.geofences,
    required this.selectedGeofence,
    required this.searchQuery,
    required this.statusFilter,
    required this.typeFilter,
    required this.isLoading,
    required this.isRefreshing,
    required this.isCreating,
    required this.isUpdating,
    required this.deletingIds,
    required this.errorMessage,
    required this.refreshKey,
  });

  const UserGeofencesState.initial()
      : geofences = const <UserGeofence>[],
        selectedGeofence = null,
        searchQuery = '',
        statusFilter = UserLandmarkStatusFilter.all,
        typeFilter = null,
        isLoading = false,
        isRefreshing = false,
        isCreating = false,
        isUpdating = false,
        deletingIds = const <String>{},
        errorMessage = null,
        refreshKey = '';

  static const Object _unset = Object();

  final List<UserGeofence> geofences;
  final UserGeofence? selectedGeofence;
  final String searchQuery;
  final UserLandmarkStatusFilter statusFilter;
  final UserGeofenceType? typeFilter;
  final bool isLoading;
  final bool isRefreshing;
  final bool isCreating;
  final bool isUpdating;
  final Set<String> deletingIds;
  final String? errorMessage;
  final String refreshKey;

  bool get isDeleting => deletingIds.isNotEmpty;
  bool isDeletingId(String id) => deletingIds.contains(id);

  bool get hasGeofences => geofences.isNotEmpty;

  bool get hasActiveFilters {
    return searchQuery.trim().isNotEmpty ||
        statusFilter != UserLandmarkStatusFilter.all ||
        typeFilter != null;
  }

  List<UserGeofence> get filteredGeofences {
    final query = searchQuery.trim().toLowerCase();
    final activeFlag = statusFilter.asActiveFlag;
    final type = typeFilter;
    if (query.isEmpty && activeFlag == null && type == null) {
      return geofences;
    }
    return geofences.where((g) {
      if (activeFlag != null && g.isActive != activeFlag) return false;
      if (type != null && g.type != type) return false;
      if (query.isEmpty) return true;
      return g.name.toLowerCase().contains(query) ||
          g.description.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  UserGeofencesState copyWith({
    List<UserGeofence>? geofences,
    Object? selectedGeofence = _unset,
    String? searchQuery,
    UserLandmarkStatusFilter? statusFilter,
    Object? typeFilter = _unset,
    bool? isLoading,
    bool? isRefreshing,
    bool? isCreating,
    bool? isUpdating,
    Set<String>? deletingIds,
    Object? errorMessage = _unset,
    String? refreshKey,
  }) {
    return UserGeofencesState(
      geofences: geofences ?? this.geofences,
      selectedGeofence: identical(selectedGeofence, _unset)
          ? this.selectedGeofence
          : selectedGeofence as UserGeofence?,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: identical(typeFilter, _unset)
          ? this.typeFilter
          : typeFilter as UserGeofenceType?,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      deletingIds: deletingIds ?? this.deletingIds,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}

// ---------------------------------------------------------------------------
// POIs list state
// ---------------------------------------------------------------------------

class UserPoisState {
  const UserPoisState({
    required this.pois,
    required this.selectedPoi,
    required this.searchQuery,
    required this.statusFilter,
    required this.categoryFilter,
    required this.isLoading,
    required this.isRefreshing,
    required this.isCreating,
    required this.isUpdating,
    required this.deletingIds,
    required this.errorMessage,
    required this.refreshKey,
  });

  const UserPoisState.initial()
      : pois = const <UserPoi>[],
        selectedPoi = null,
        searchQuery = '',
        statusFilter = UserLandmarkStatusFilter.all,
        categoryFilter = null,
        isLoading = false,
        isRefreshing = false,
        isCreating = false,
        isUpdating = false,
        deletingIds = const <String>{},
        errorMessage = null,
        refreshKey = '';

  static const Object _unset = Object();

  final List<UserPoi> pois;
  final UserPoi? selectedPoi;
  final String searchQuery;
  final UserLandmarkStatusFilter statusFilter;
  final String? categoryFilter;
  final bool isLoading;
  final bool isRefreshing;
  final bool isCreating;
  final bool isUpdating;
  final Set<String> deletingIds;
  final String? errorMessage;
  final String refreshKey;

  bool get isDeleting => deletingIds.isNotEmpty;
  bool isDeletingId(String id) => deletingIds.contains(id);

  bool get hasPois => pois.isNotEmpty;

  bool get hasActiveFilters {
    return searchQuery.trim().isNotEmpty ||
        statusFilter != UserLandmarkStatusFilter.all ||
        (categoryFilter?.trim().isNotEmpty ?? false);
  }

  List<String> get availableCategories {
    final set = <String>{};
    for (final poi in pois) {
      final c = poi.category.trim();
      if (c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<UserPoi> get filteredPois {
    final query = searchQuery.trim().toLowerCase();
    final activeFlag = statusFilter.asActiveFlag;
    final category = categoryFilter?.trim().toLowerCase() ?? '';
    if (query.isEmpty && activeFlag == null && category.isEmpty) {
      return pois;
    }
    return pois.where((p) {
      if (activeFlag != null && p.isActive != activeFlag) return false;
      if (category.isNotEmpty && p.category.toLowerCase() != category) {
        return false;
      }
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  UserPoisState copyWith({
    List<UserPoi>? pois,
    Object? selectedPoi = _unset,
    String? searchQuery,
    UserLandmarkStatusFilter? statusFilter,
    Object? categoryFilter = _unset,
    bool? isLoading,
    bool? isRefreshing,
    bool? isCreating,
    bool? isUpdating,
    Set<String>? deletingIds,
    Object? errorMessage = _unset,
    String? refreshKey,
  }) {
    return UserPoisState(
      pois: pois ?? this.pois,
      selectedPoi: identical(selectedPoi, _unset)
          ? this.selectedPoi
          : selectedPoi as UserPoi?,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: identical(categoryFilter, _unset)
          ? this.categoryFilter
          : categoryFilter as String?,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      deletingIds: deletingIds ?? this.deletingIds,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}

// ---------------------------------------------------------------------------
// Routes list state
// ---------------------------------------------------------------------------

class UserRoutesState {
  const UserRoutesState({
    required this.routes,
    required this.selectedRoute,
    required this.searchQuery,
    required this.statusFilter,
    required this.isLoading,
    required this.isRefreshing,
    required this.isCreating,
    required this.isUpdating,
    required this.deletingIds,
    required this.errorMessage,
    required this.refreshKey,
  });

  const UserRoutesState.initial()
      : routes = const <UserRouteLandmark>[],
        selectedRoute = null,
        searchQuery = '',
        statusFilter = UserLandmarkStatusFilter.all,
        isLoading = false,
        isRefreshing = false,
        isCreating = false,
        isUpdating = false,
        deletingIds = const <String>{},
        errorMessage = null,
        refreshKey = '';

  static const Object _unset = Object();

  final List<UserRouteLandmark> routes;
  final UserRouteLandmark? selectedRoute;
  final String searchQuery;
  final UserLandmarkStatusFilter statusFilter;
  final bool isLoading;
  final bool isRefreshing;
  final bool isCreating;
  final bool isUpdating;
  final Set<String> deletingIds;
  final String? errorMessage;
  final String refreshKey;

  bool get isDeleting => deletingIds.isNotEmpty;
  bool isDeletingId(String id) => deletingIds.contains(id);

  bool get hasRoutes => routes.isNotEmpty;

  bool get hasActiveFilters {
    return searchQuery.trim().isNotEmpty ||
        statusFilter != UserLandmarkStatusFilter.all;
  }

  List<UserRouteLandmark> get filteredRoutes {
    final query = searchQuery.trim().toLowerCase();
    final activeFlag = statusFilter.asActiveFlag;
    if (query.isEmpty && activeFlag == null) {
      return routes;
    }
    return routes.where((r) {
      if (activeFlag != null && r.isActive != activeFlag) return false;
      if (query.isEmpty) return true;
      return r.name.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  UserRoutesState copyWith({
    List<UserRouteLandmark>? routes,
    Object? selectedRoute = _unset,
    String? searchQuery,
    UserLandmarkStatusFilter? statusFilter,
    bool? isLoading,
    bool? isRefreshing,
    bool? isCreating,
    bool? isUpdating,
    Set<String>? deletingIds,
    Object? errorMessage = _unset,
    String? refreshKey,
  }) {
    return UserRoutesState(
      routes: routes ?? this.routes,
      selectedRoute: identical(selectedRoute, _unset)
          ? this.selectedRoute
          : selectedRoute as UserRouteLandmark?,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      deletingIds: deletingIds ?? this.deletingIds,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}

// ---------------------------------------------------------------------------
// Editor state (shared by geofence / poi / route editors)
// ---------------------------------------------------------------------------

class UserLandmarkEditorState {
  const UserLandmarkEditorState({
    required this.entityType,
    required this.mode,
    required this.workingPoints,
    required this.circleCenter,
    required this.circleRadiusM,
    required this.poiPoint,
    required this.isSaving,
    required this.errorMessage,
  });

  const UserLandmarkEditorState.initial({
    this.entityType = UserLandmarkEntityType.geofence,
  })  : mode = UserGeofenceEditorMode.view,
        workingPoints = const <UserGeoPoint>[],
        circleCenter = null,
        circleRadiusM = null,
        poiPoint = null,
        isSaving = false,
        errorMessage = null;

  static const Object _unset = Object();

  final UserLandmarkEntityType entityType;
  final UserGeofenceEditorMode mode;
  final List<UserGeoPoint> workingPoints;
  final UserGeoPoint? circleCenter;
  final double? circleRadiusM;
  final UserGeoPoint? poiPoint;
  final bool isSaving;
  final String? errorMessage;

  bool get canSave {
    switch (entityType) {
      case UserLandmarkEntityType.geofence:
        switch (mode) {
          case UserGeofenceEditorMode.circle:
            return circleCenter != null && (circleRadiusM ?? 0) > 0;
          case UserGeofenceEditorMode.polygon:
          case UserGeofenceEditorMode.rectangle:
            return _uniquePointCount(workingPoints) >= 3;
          case UserGeofenceEditorMode.line:
            return workingPoints.length >= 2;
          case UserGeofenceEditorMode.view:
            return false;
        }
      case UserLandmarkEntityType.poi:
        return poiPoint != null;
      case UserLandmarkEntityType.route:
        return workingPoints.length >= 2;
    }
  }

  UserLandmarkEditorState copyWith({
    UserLandmarkEntityType? entityType,
    UserGeofenceEditorMode? mode,
    List<UserGeoPoint>? workingPoints,
    Object? circleCenter = _unset,
    Object? circleRadiusM = _unset,
    Object? poiPoint = _unset,
    bool? isSaving,
    Object? errorMessage = _unset,
  }) {
    return UserLandmarkEditorState(
      entityType: entityType ?? this.entityType,
      mode: mode ?? this.mode,
      workingPoints: workingPoints ?? this.workingPoints,
      circleCenter: identical(circleCenter, _unset)
          ? this.circleCenter
          : circleCenter as UserGeoPoint?,
      circleRadiusM: identical(circleRadiusM, _unset)
          ? this.circleRadiusM
          : circleRadiusM as double?,
      poiPoint: identical(poiPoint, _unset)
          ? this.poiPoint
          : poiPoint as UserGeoPoint?,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

int _uniquePointCount(List<UserGeoPoint> points) {
  final set = <String>{};
  for (final p in points) {
    set.add('${p.lat.toStringAsFixed(8)}_${p.lon.toStringAsFixed(8)}');
  }
  return set.length;
}

// ---------------------------------------------------------------------------
// Bulk job state
// ---------------------------------------------------------------------------

class UserLandmarkBulkJobState {
  const UserLandmarkBulkJobState({
    required this.job,
    required this.isLoading,
    required this.isUploading,
    required this.errorMessage,
  });

  const UserLandmarkBulkJobState.initial()
      : job = null,
        isLoading = false,
        isUploading = false,
        errorMessage = null;

  static const Object _unset = Object();

  final UserLandmarkBulkJob? job;
  final bool isLoading;
  final bool isUploading;
  final String? errorMessage;

  UserLandmarkBulkJobState copyWith({
    Object? job = _unset,
    bool? isLoading,
    bool? isUploading,
    Object? errorMessage = _unset,
  }) {
    return UserLandmarkBulkJobState(
      job: identical(job, _unset) ? this.job : job as UserLandmarkBulkJob?,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Studio landing counts state
// ---------------------------------------------------------------------------

class UserLandmarkStudioCountsState {
  const UserLandmarkStudioCountsState({
    required this.geofencesCount,
    required this.poisCount,
    required this.routesCount,
    required this.isLoading,
    required this.errorMessage,
  });

  const UserLandmarkStudioCountsState.initial()
      : geofencesCount = null,
        poisCount = null,
        routesCount = null,
        isLoading = false,
        errorMessage = null;

  static const Object _unset = Object();

  final int? geofencesCount;
  final int? poisCount;
  final int? routesCount;
  final bool isLoading;
  final String? errorMessage;

  bool get hasAnyCount =>
      geofencesCount != null || poisCount != null || routesCount != null;

  UserLandmarkStudioCountsState copyWith({
    Object? geofencesCount = _unset,
    Object? poisCount = _unset,
    Object? routesCount = _unset,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return UserLandmarkStudioCountsState(
      geofencesCount: identical(geofencesCount, _unset)
          ? this.geofencesCount
          : geofencesCount as int?,
      poisCount:
          identical(poisCount, _unset) ? this.poisCount : poisCount as int?,
      routesCount: identical(routesCount, _unset)
          ? this.routesCount
          : routesCount as int?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
