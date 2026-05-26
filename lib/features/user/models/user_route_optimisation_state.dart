import 'user_route_optimisation_model.dart';

/// Tab choice in the "Add from landmarks" sheet.
enum LandmarkTypeTab { poi, geofence }

/// Immutable view-state for the Route Optimisation screen.
///
/// Field layout mirrors the React equivalent (`useRouteOptimization`) closely
/// so behaviour parity is easy to verify side-by-side.
class UserRouteOptimisationState {
  const UserRouteOptimisationState({
    this.points = const <RouteOptimisationPoint>[],
    this.startIndex = 0,
    this.endIndex = -1,
    this.roundTrip = false,
    this.result,
    this.roadGeometry,
    this.isOptimising = false,
    this.isSavingRoute = false,
    this.isLoadingLandmarks = false,
    this.isFetchingRoadGeometry = false,
    this.clickToAddMode = false,
    this.selectedPointIndex,
    this.pendingMapPoint,
    this.landmarkPois = const <RouteOptimisationPoint>[],
    this.landmarkGeofences = const <RouteOptimisationPoint>[],
    this.landmarkSearchQuery = '',
    this.selectedLandmarkTypeTab = LandmarkTypeTab.poi,
    this.errorMessage,
    this.successMessage,
    this.lastSavedRouteId,
  });

  // -- Core workspace -------------------------------------------------------
  final List<RouteOptimisationPoint> points;
  final int startIndex;

  /// `-1` ⇒ auto (last point) when [roundTrip] is `false`. Ignored when
  /// [roundTrip] is `true`.
  final int endIndex;
  final bool roundTrip;

  final RouteOptimisationResult? result;
  final OptimisedRoadGeometry? roadGeometry;

  // -- Loading flags --------------------------------------------------------
  final bool isOptimising;
  final bool isSavingRoute;
  final bool isLoadingLandmarks;
  final bool isFetchingRoadGeometry;

  // -- Map interaction ------------------------------------------------------
  final bool clickToAddMode;
  final int? selectedPointIndex;

  /// Last point added via map tap — exposed so the UI can focus the rename
  /// field for it. Cleared on the next user action.
  final RouteOptimisationPoint? pendingMapPoint;

  // -- Landmark picker ------------------------------------------------------
  final List<RouteOptimisationPoint> landmarkPois;
  final List<RouteOptimisationPoint> landmarkGeofences;
  final String landmarkSearchQuery;
  final LandmarkTypeTab selectedLandmarkTypeTab;

  // -- Toast slots ----------------------------------------------------------
  final String? errorMessage;
  final String? successMessage;
  final String? lastSavedRouteId;

  // -------------------------------------------------------------------------
  // Computed getters
  // -------------------------------------------------------------------------

  bool get hasPoints => points.isNotEmpty;

  bool get hasResult => result != null;

  /// Resolves the auto sentinel (`-1`) to a concrete index for UI display.
  ///
  /// * Round-trip ⇒ `startIndex` (route closes back at start).
  /// * Explicit end ⇒ `endIndex`.
  /// * Auto end with points ⇒ `points.length - 1`.
  /// * Empty ⇒ `-1`.
  int get effectiveEndIndex {
    if (points.isEmpty) return -1;
    if (roundTrip) return startIndex;
    if (endIndex >= 0 && endIndex < points.length) return endIndex;
    return points.length - 1;
  }

  bool get canOptimise =>
      points.length >= RouteOptimisationValidation.minPointsToOptimise &&
      !isOptimising;

  bool get canSaveRoute =>
      result != null && !isSavingRoute && points.length >= 2;

  /// Points in their current (user-visible) order — pre-optimisation.
  List<RouteOptimisationPoint> get orderedPoints =>
      List<RouteOptimisationPoint>.unmodifiable(points);

  /// Points in the optimised order, or [orderedPoints] when no result yet.
  List<RouteOptimisationPoint> get optimizedOrderedPoints {
    final r = result;
    if (r == null) return orderedPoints;
    final out = <RouteOptimisationPoint>[];
    for (final i in r.optimizedOrder) {
      if (i >= 0 && i < points.length) out.add(points[i]);
    }
    return out.isEmpty ? orderedPoints : List.unmodifiable(out);
  }

  String? get originalDistanceLabel =>
      result == null ? null : '${result!.originalDistanceKm.toStringAsFixed(2)} km';

  String? get optimizedDistanceLabel =>
      result == null ? null : '${result!.optimizedDistanceKm.toStringAsFixed(2)} km';

  String? get improvementLabel {
    final r = result;
    if (r == null) return null;
    final pct = r.improvementPct;
    final sign = pct > 0 ? '−' : (pct < 0 ? '+' : '');
    return '$sign${pct.abs().toStringAsFixed(2)}%';
  }

  /// Set of IDs currently in [points] — used to skip duplicate adds from the
  /// landmark sheet.
  Set<String> get existingPointIds =>
      <String>{for (final p in points) p.id};

  /// Derived constraints object handed to the optimisation engine.
  RouteOptimisationConstraints get constraints =>
      RouteOptimisationConstraints(
        startIndex: startIndex,
        endIndex: endIndex,
        roundTrip: roundTrip,
      );

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  UserRouteOptimisationState copyWith({
    List<RouteOptimisationPoint>? points,
    int? startIndex,
    int? endIndex,
    bool? roundTrip,
    RouteOptimisationResult? result,
    bool clearResult = false,
    OptimisedRoadGeometry? roadGeometry,
    bool clearRoadGeometry = false,
    bool? isOptimising,
    bool? isSavingRoute,
    bool? isLoadingLandmarks,
    bool? isFetchingRoadGeometry,
    bool? clickToAddMode,
    int? selectedPointIndex,
    bool clearSelectedPointIndex = false,
    RouteOptimisationPoint? pendingMapPoint,
    bool clearPendingMapPoint = false,
    List<RouteOptimisationPoint>? landmarkPois,
    List<RouteOptimisationPoint>? landmarkGeofences,
    String? landmarkSearchQuery,
    LandmarkTypeTab? selectedLandmarkTypeTab,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    String? lastSavedRouteId,
    bool clearLastSavedRouteId = false,
  }) {
    return UserRouteOptimisationState(
      points: points ?? this.points,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      roundTrip: roundTrip ?? this.roundTrip,
      result: clearResult ? null : (result ?? this.result),
      roadGeometry:
          clearRoadGeometry ? null : (roadGeometry ?? this.roadGeometry),
      isOptimising: isOptimising ?? this.isOptimising,
      isSavingRoute: isSavingRoute ?? this.isSavingRoute,
      isLoadingLandmarks: isLoadingLandmarks ?? this.isLoadingLandmarks,
      isFetchingRoadGeometry:
          isFetchingRoadGeometry ?? this.isFetchingRoadGeometry,
      clickToAddMode: clickToAddMode ?? this.clickToAddMode,
      selectedPointIndex: clearSelectedPointIndex
          ? null
          : (selectedPointIndex ?? this.selectedPointIndex),
      pendingMapPoint: clearPendingMapPoint
          ? null
          : (pendingMapPoint ?? this.pendingMapPoint),
      landmarkPois: landmarkPois ?? this.landmarkPois,
      landmarkGeofences: landmarkGeofences ?? this.landmarkGeofences,
      landmarkSearchQuery: landmarkSearchQuery ?? this.landmarkSearchQuery,
      selectedLandmarkTypeTab:
          selectedLandmarkTypeTab ?? this.selectedLandmarkTypeTab,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      lastSavedRouteId: clearLastSavedRouteId
          ? null
          : (lastSavedRouteId ?? this.lastSavedRouteId),
    );
  }
}
