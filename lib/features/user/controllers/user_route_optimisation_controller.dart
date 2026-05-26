import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_landmark_model.dart';
import '../models/user_route_optimisation_model.dart';
import '../models/user_route_optimisation_state.dart';
import '../services/user_route_optimisation_service.dart';
import '../utils/route_optimisation_engine.dart';
import '../utils/route_optimisation_google_maps.dart';

/// Owns the entire Route Optimisation workspace lifecycle: point CRUD,
/// constraints, the optimise → road-fetch pipeline, save-to-backend, and
/// the copy/share helpers.
///
/// All business logic lives here — widgets must only read state and invoke
/// the methods on this notifier. All API calls are delegated to
/// [UserRouteOptimisationService] and the pure algorithm utilities live in
/// `lib/features/user/utils/route_optimisation_*.dart`.
class UserRouteOptimisationController
    extends StateNotifier<UserRouteOptimisationState> {
  UserRouteOptimisationController({
    required UserRouteOptimisationService service,
  })  : _service = service,
        super(const UserRouteOptimisationState());

  final UserRouteOptimisationService _service;

  int _ephemeralIdCounter = 0;

  // ---------------------------------------------------------------------
  // Landmark loading
  // ---------------------------------------------------------------------

  /// Fetches POIs and geofences for the picker sheet. Errors surface via
  /// [UserRouteOptimisationState.errorMessage] — the existing list contents
  /// are preserved on failure so the picker stays usable.
  Future<void> loadLandmarks() async {
    state = state.copyWith(
      isLoadingLandmarks: true,
      clearErrorMessage: true,
    );
    try {
      final results = await Future.wait<dynamic>([
        _service.fetchPois(),
        _service.fetchGeofences(),
      ]);
      if (!mounted) return;
      final pois = (results[0] as List<UserPoi>)
          .map(_service.poiToPoint)
          .whereType<RouteOptimisationPoint>()
          .toList(growable: false);
      final geofences = (results[1] as List<UserGeofence>)
          .map(_service.geofenceToPoint)
          .whereType<RouteOptimisationPoint>()
          .toList(growable: false);
      state = state.copyWith(
        landmarkPois: pois,
        landmarkGeofences: geofences,
        isLoadingLandmarks: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingLandmarks: false,
        errorMessage: 'Failed to load landmarks: ${_friendly(e)}',
      );
    }
  }

  void setLandmarkSearchQuery(String value) {
    if (value == state.landmarkSearchQuery) return;
    state = state.copyWith(landmarkSearchQuery: value);
  }

  void setSelectedLandmarkTypeTab(LandmarkTypeTab tab) {
    if (tab == state.selectedLandmarkTypeTab) return;
    state = state.copyWith(selectedLandmarkTypeTab: tab);
  }

  // ---------------------------------------------------------------------
  // Point management
  // ---------------------------------------------------------------------

  /// Adds new points, skipping any whose [RouteOptimisationPoint.id] is
  /// already present. Clears the current result.
  void addPoints(List<RouteOptimisationPoint> incoming) {
    if (incoming.isEmpty) return;
    final existing = state.existingPointIds;
    final additions = <RouteOptimisationPoint>[];
    for (final p in incoming) {
      if (existing.add(p.id)) additions.add(p);
    }
    if (additions.isEmpty) return;
    state =
        _withPoints(<RouteOptimisationPoint>[...state.points, ...additions]);
  }

  /// Convenience for "tap a landmark card to add it".
  void quickAddPoint(RouteOptimisationPoint point) => addPoints([point]);

  /// Adds a hand-entered point (form sheet).
  void addManualPoint({
    required String name,
    required double lat,
    required double lon,
  }) {
    if (!_validCoord(lat, lon)) {
      state = state.copyWith(errorMessage: 'Coordinates are out of range.');
      return;
    }
    final trimmed = name.trim().isEmpty ? 'Manual point' : name.trim();
    final point = RouteOptimisationPoint(
      id: _nextEphemeralId(RouteOptimisationPointSource.manual),
      name: trimmed,
      lat: lat,
      lon: lon,
      source: RouteOptimisationPointSource.manual,
    );
    addPoints([point]);
  }

  /// Adds a point originating from a map tap.
  void addMapPoint({
    required double lat,
    required double lon,
    String? name,
  }) {
    if (!_validCoord(lat, lon)) {
      state = state.copyWith(errorMessage: 'Coordinates are out of range.');
      return;
    }
    final label = (name == null || name.trim().isEmpty)
        ? 'Map stop ${state.points.length + 1}'
        : name.trim();
    final point = RouteOptimisationPoint(
      id: _nextEphemeralId(RouteOptimisationPointSource.map),
      name: label,
      lat: lat,
      lon: lon,
      source: RouteOptimisationPointSource.map,
    );
    final next = <RouteOptimisationPoint>[...state.points, point];
    state = _withPoints(next).copyWith(
      pendingMapPoint: point,
      selectedPointIndex: next.length - 1,
    );
  }

  /// Map-tap entry point used by the map widget when [clickToAddMode] is on.
  /// Does nothing when click-to-add is off.
  void handleMapTap(double lat, double lon) {
    if (!state.clickToAddMode) return;
    addMapPoint(lat: lat, lon: lon);
  }

  /// Replaces the point at [index] (e.g., after the rename sheet closes).
  void updatePoint(int index, RouteOptimisationPoint point) {
    if (index < 0 || index >= state.points.length) return;
    final next = <RouteOptimisationPoint>[...state.points];
    next[index] = point;
    state = _withPoints(next);
  }

  /// Deletes the point at [index] and shifts start/end indices safely.
  void deletePoint(int index) {
    if (index < 0 || index >= state.points.length) return;
    final next = <RouteOptimisationPoint>[...state.points]..removeAt(index);

    final newStart =
        _shiftIndexAfterDelete(state.startIndex, index, fallback: 0);
    final newEnd = _shiftIndexAfterDelete(state.endIndex, index, fallback: -1);

    final selected = state.selectedPointIndex;
    int? newSelected = selected;
    if (selected != null) {
      if (selected == index) {
        newSelected = null;
      } else if (selected > index) {
        newSelected = selected - 1;
      }
    }

    state = _withPoints(
      next,
      startIndex: newStart,
      endIndex: next.isEmpty ? -1 : newEnd,
      selectedPointIndex: newSelected,
      clearSelectedPointIndex: newSelected == null,
    );
  }

  /// Reorders points and re-anchors start/end to the same logical point.
  void reorderPoint(int fromIndex, int toIndex) {
    final n = state.points.length;
    if (fromIndex < 0 || fromIndex >= n) return;
    var target = toIndex;
    if (target > fromIndex) target -= 1;
    target = target.clamp(0, n - 1);
    if (target == fromIndex) return;

    final next = <RouteOptimisationPoint>[...state.points];
    final moved = next.removeAt(fromIndex);
    next.insert(target, moved);

    final newStart =
        _shiftIndexAfterReorder(state.startIndex, fromIndex, target);
    final newEnd = state.endIndex < 0
        ? -1
        : _shiftIndexAfterReorder(state.endIndex, fromIndex, target);

    state = _withPoints(
      next,
      startIndex: newStart,
      endIndex: newEnd,
    );
  }

  // ---------------------------------------------------------------------
  // Constraints
  // ---------------------------------------------------------------------

  void setStartIndex(int index) {
    if (index < 0 || index >= state.points.length) return;
    if (index == state.startIndex) return;
    final newEnd = state.endIndex == index ? -1 : state.endIndex;
    state = state.copyWith(
      startIndex: index,
      endIndex: newEnd,
      clearResult: true,
      clearRoadGeometry: true,
    );
  }

  /// Pass `-1` to switch back to "auto" end (last point).
  void setEndIndex(int index) {
    if (index < -1 || index >= state.points.length) return;
    if (index >= 0 && index == state.startIndex) return;
    state = state.copyWith(
      endIndex: index,
      roundTrip: false,
      clearResult: true,
      clearRoadGeometry: true,
    );
  }

  void toggleRoundTrip() {
    final next = !state.roundTrip;
    state = state.copyWith(
      roundTrip: next,
      endIndex: next ? -1 : state.endIndex,
      clearResult: true,
      clearRoadGeometry: true,
    );
  }

  // ---------------------------------------------------------------------
  // Map interaction toggles
  // ---------------------------------------------------------------------

  void setClickToAddMode(bool value) {
    if (value == state.clickToAddMode) return;
    state = state.copyWith(
      clickToAddMode: value,
      clearPendingMapPoint: !value,
    );
  }

  void setSelectedPointIndex(int? index) {
    if (index == state.selectedPointIndex) return;
    state = state.copyWith(
      selectedPointIndex: index,
      clearSelectedPointIndex: index == null,
    );
  }

  void clearPendingMapPoint() {
    if (state.pendingMapPoint == null) return;
    state = state.copyWith(clearPendingMapPoint: true);
  }

  // ---------------------------------------------------------------------
  // Workspace lifecycle
  // ---------------------------------------------------------------------

  void clearAll() {
    state = const UserRouteOptimisationState().copyWith(
      // Preserve picker results so the user doesn't have to refetch.
      landmarkPois: state.landmarkPois,
      landmarkGeofences: state.landmarkGeofences,
    );
  }

  void clearResult() {
    if (state.result == null && state.roadGeometry == null) return;
    state = state.copyWith(
      clearResult: true,
      clearRoadGeometry: true,
    );
  }

  void clearError() {
    if (state.errorMessage == null && state.successMessage == null) return;
    state = state.copyWith(
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  /// Replaces the points list with the optimised ordering so the user can
  /// continue editing from that baseline.
  void applyOptimisedOrder() {
    final r = state.result;
    if (r == null) return;
    if (r.optimizedOrder.length != state.points.length) return;
    final reordered = <RouteOptimisationPoint>[
      for (final i in r.optimizedOrder) state.points[i],
    ];
    state = state.copyWith(
      points: reordered,
      startIndex: 0,
      endIndex: -1,
      roundTrip: false,
      clearResult: true,
      clearRoadGeometry: true,
      clearSelectedPointIndex: true,
    );
  }

  // ---------------------------------------------------------------------
  // Optimise
  // ---------------------------------------------------------------------

  /// Runs the pure-Dart engine, then attempts to fetch road geometry from
  /// OSRM (best-effort — never blocks the result).
  Future<void> optimise() async {
    if (!state.canOptimise) return;
    state = state.copyWith(
      isOptimising: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
      clearResult: true,
      clearRoadGeometry: true,
    );

    final pointsSnapshot =
        List<RouteOptimisationPoint>.unmodifiable(state.points);
    final constraintsSnapshot = state.constraints;
    final roundTripSnapshot = state.roundTrip;

    RouteOptimisationResult result;
    try {
      result = optimizeRoute(pointsSnapshot, constraintsSnapshot);
    } on RouteOptimisationException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isOptimising: false,
        errorMessage: e.message,
      );
      return;
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isOptimising: false,
        errorMessage: 'Optimisation failed: ${_friendly(e)}',
      );
      return;
    }

    if (!mounted) return;
    // Bail out if the user edited points while optimising.
    if (!_pointsEqual(pointsSnapshot, state.points)) {
      state = state.copyWith(isOptimising: false);
      return;
    }
    state = state.copyWith(
      result: result,
      isOptimising: false,
      isFetchingRoadGeometry: true,
    );

    OptimisedRoadGeometry? geom;
    try {
      geom = await _service.fetchOsrmRouteForOrder(
        points: pointsSnapshot,
        order: result.optimizedOrder,
        roundTrip: roundTripSnapshot,
      );
    } catch (_) {
      geom = null;
    }
    if (!mounted) return;
    if (!_pointsEqual(pointsSnapshot, state.points) || state.result != result) {
      // Workspace moved on — discard stale geometry silently.
      state = state.copyWith(isFetchingRoadGeometry: false);
      return;
    }
    state = state.copyWith(
      isFetchingRoadGeometry: false,
      roadGeometry: geom,
      clearRoadGeometry: geom == null,
    );
  }

  // ---------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------

  /// Persists the optimised route via `POST /user/routes`. Preserves the
  /// current points/result on failure.
  Future<bool> saveOptimisedRoute({
    required String name,
    String? description,
    String? color,
    bool isActive = true,
    int toleranceMeters = 100,
  }) async {
    final result = state.result;
    if (result == null) {
      state = state.copyWith(
        errorMessage: 'Run an optimisation before saving the route.',
      );
      return false;
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: 'Route name is required.');
      return false;
    }
    if (!state.canSaveRoute) return false;

    state = state.copyWith(
      isSavingRoute: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );

    try {
      final geodata = _service.buildLineGeoDataForOrder(
        points: state.points,
        order: result.optimizedOrder,
        roundTrip: state.roundTrip,
        roadGeometry: state.roadGeometry,
        toleranceM: toleranceMeters.toDouble(),
      );
      final descTrim = description?.trim();
      final colorTrim = color?.trim();
      final request = CreateUserRouteRequest(
        name: trimmed,
        description:
            (descTrim != null && descTrim.isNotEmpty) ? descTrim : null,
        color: (colorTrim != null && colorTrim.isNotEmpty) ? colorTrim : null,
        isActive: isActive,
        geodata: geodata,
        toleranceMeters: toleranceMeters.toDouble(),
      );
      final saved = await _service.saveRoute(request);
      if (!mounted) return true;
      state = state.copyWith(
        isSavingRoute: false,
        successMessage: 'Route "${saved.name}" saved.',
        lastSavedRouteId: saved.id,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSavingRoute: false,
        errorMessage: 'Failed to save route: ${_friendly(e)}',
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Share / copy / open
  // ---------------------------------------------------------------------

  /// Copies a JSON snapshot of the workspace to the system clipboard.
  Future<bool> copyJson() async {
    try {
      final text = _service.buildJsonExport(
        points: state.points,
        constraints: state.constraints,
        result: state.result,
        roadGeometry: state.roadGeometry,
      );
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return true;
      state = state.copyWith(
        successMessage: 'Workspace JSON copied to clipboard.',
        clearErrorMessage: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        errorMessage: 'Could not copy JSON: ${_friendly(e)}',
      );
      return false;
    }
  }

  /// Copies the human-readable optimisation report to the clipboard.
  Future<bool> copyReport() async {
    final result = state.result;
    if (result == null) {
      state = state.copyWith(
        errorMessage: 'Run an optimisation before copying the report.',
      );
      return false;
    }
    try {
      await Clipboard.setData(
        ClipboardData(text: _service.buildTextReport(result)),
      );
      if (!mounted) return true;
      state = state.copyWith(
        successMessage: 'Optimisation report copied to clipboard.',
        clearErrorMessage: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        errorMessage: 'Could not copy report: ${_friendly(e)}',
      );
      return false;
    }
  }

  /// Builds a Google Maps Directions URL for the current (optimised or raw)
  /// order. Returns an empty string when fewer than 2 points exist.
  String buildGoogleMapsUrl() {
    if (state.points.length < 2) return '';
    final order = state.result?.optimizedOrder ??
        List<int>.generate(state.points.length, (i) => i);
    return generateGoogleMapsUrl(
      points: state.points,
      order: order,
      roundTrip: state.roundTrip,
    );
  }

  // ---------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------

  /// Single helper for "points changed" — resets dependent caches and
  /// clamps the start/end indices to the new length.
  UserRouteOptimisationState _withPoints(
    List<RouteOptimisationPoint> next, {
    int? startIndex,
    int? endIndex,
    int? selectedPointIndex,
    bool clearSelectedPointIndex = false,
  }) {
    final n = next.length;
    int newStart;
    int newEnd;
    if (n == 0) {
      newStart = 0;
      newEnd = -1;
    } else {
      newStart = (startIndex ?? state.startIndex).clamp(0, n - 1);
      final candidateEnd = endIndex ?? state.endIndex;
      newEnd = (candidateEnd >= 0 && candidateEnd < n) ? candidateEnd : -1;
      if (newEnd == newStart) newEnd = -1;
    }
    return state.copyWith(
      points: next,
      startIndex: newStart,
      endIndex: newEnd,
      selectedPointIndex: selectedPointIndex,
      clearSelectedPointIndex: clearSelectedPointIndex,
      clearResult: true,
      clearRoadGeometry: true,
      clearPendingMapPoint: false,
    );
  }

  String _nextEphemeralId(RouteOptimisationPointSource source) {
    _ephemeralIdCounter += 1;
    final ts = DateTime.now().microsecondsSinceEpoch;
    return '${source.idPrefix}-$ts-$_ephemeralIdCounter';
  }

  bool _validCoord(double lat, double lon) =>
      RouteOptimisationValidation.isLatValid(lat) &&
      RouteOptimisationValidation.isLonValid(lon);

  /// Returns the new value of an index after the entry at [deleted] was
  /// removed from the list. Returns [fallback] when the index pointed at
  /// the deleted entry (or no longer has a target).
  int _shiftIndexAfterDelete(
    int current,
    int deleted, {
    required int fallback,
  }) {
    if (current < 0) return fallback;
    if (current == deleted) return fallback;
    if (current > deleted) return current - 1;
    return current;
  }

  /// Returns the new value of an index after the element at [from] was
  /// moved to [to] within the same list.
  int _shiftIndexAfterReorder(int current, int from, int to) {
    if (current < 0) return current;
    if (current == from) return to;
    // Element removed before [current]?
    var adjusted = current;
    if (from < current) adjusted -= 1;
    // Then inserted at <= new index?
    if (to <= adjusted) adjusted += 1;
    return adjusted;
  }

  bool _pointsEqual(
    List<RouteOptimisationPoint> a,
    List<RouteOptimisationPoint> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
      if (a[i].lat != b[i].lat || a[i].lon != b[i].lon) return false;
    }
    return true;
  }

  String _friendly(Object error) {
    final msg = error.toString();
    if (msg.startsWith('Exception: ')) return msg.substring(11);
    return msg;
  }
}
