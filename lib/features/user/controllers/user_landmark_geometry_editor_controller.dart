import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/user_landmark_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class UserLandmarkGeometryEditorState {
  const UserLandmarkGeometryEditorState({
    required this.editorMode,
    required this.points,
    required this.circleCenter,
    required this.circleRadiusM,
    required this.rectangleStart,
    required this.rectangleEnd,
    required this.lockSquare,
    required this.toleranceM,
    required this.selectedVertexIndex,
    required this.undoDepth,
    required this.redoDepth,
    required this.isDirty,
    required this.validationError,
    required this.mapCenter,
    required this.mapZoom,
    required this.snapEnabled,
  });

  const UserLandmarkGeometryEditorState.initial({
    UserGeofenceEditorMode mode = UserGeofenceEditorMode.polygon,
    this.mapCenter,
    this.mapZoom = 14,
  })  : editorMode = mode,
        points = const <UserGeoPoint>[],
        circleCenter = null,
        circleRadiusM = null,
        rectangleStart = null,
        rectangleEnd = null,
        lockSquare = false,
        toleranceM = null,
        selectedVertexIndex = null,
        undoDepth = 0,
        redoDepth = 0,
        isDirty = false,
        validationError = null,
        snapEnabled = false;

  static const Object _unset = Object();

  final UserGeofenceEditorMode editorMode;
  final List<UserGeoPoint> points;
  final UserGeoPoint? circleCenter;
  final double? circleRadiusM;
  final UserGeoPoint? rectangleStart;
  final UserGeoPoint? rectangleEnd;
  final bool lockSquare;
  final double? toleranceM;
  final int? selectedVertexIndex;
  final int undoDepth;
  final int redoDepth;
  final bool isDirty;
  final String? validationError;
  final UserGeoPoint? mapCenter;
  final double mapZoom;
  final bool snapEnabled;

  bool get canUndo => undoDepth > 0;
  bool get canRedo => redoDepth > 0;

  /// Rectangle corners derived from the two stored corner points (with
  /// optional square locking). Empty if either corner is missing.
  List<UserGeoPoint> get rectangleCorners {
    final a = rectangleStart;
    final b = rectangleEnd;
    if (a == null || b == null) return const <UserGeoPoint>[];
    var minLat = math.min(a.lat, b.lat);
    var maxLat = math.max(a.lat, b.lat);
    var minLon = math.min(a.lon, b.lon);
    var maxLon = math.max(a.lon, b.lon);

    if (lockSquare) {
      final midLat = (minLat + maxLat) / 2;
      final midLon = (minLon + maxLon) / 2;
      final latSpanM = (maxLat - minLat) * _metersPerDegreeLat;
      final lonSpanM = (maxLon - minLon) *
          _metersPerDegreeLat *
          math.cos(midLat * math.pi / 180);
      final sideM = math.max(latSpanM, lonSpanM);
      final halfLat = (sideM / _metersPerDegreeLat) / 2;
      final lonScale = math.cos(midLat * math.pi / 180);
      final halfLon = lonScale.abs() < 1e-9
          ? halfLat
          : (sideM / _metersPerDegreeLat) / 2 / lonScale;
      minLat = midLat - halfLat;
      maxLat = midLat + halfLat;
      minLon = midLon - halfLon;
      maxLon = midLon + halfLon;
    }

    return <UserGeoPoint>[
      UserGeoPoint(lat: minLat, lon: minLon),
      UserGeoPoint(lat: minLat, lon: maxLon),
      UserGeoPoint(lat: maxLat, lon: maxLon),
      UserGeoPoint(lat: maxLat, lon: minLon),
    ];
  }

  String? get measurementSummary {
    switch (editorMode) {
      case UserGeofenceEditorMode.circle:
        final radius = circleRadiusM;
        if (radius == null || radius <= 0) return null;
        return 'Radius: ${_formatMeters(radius)}';
      case UserGeofenceEditorMode.line:
        if (points.length < 2) return null;
        return 'Length: ${_formatMeters(_lineLengthMeters(points))}';
      case UserGeofenceEditorMode.polygon:
        if (points.length < 3) return null;
        final perimeter = _lineLengthMeters([...points, points.first]);
        final area = _polygonAreaSquareMeters(points);
        return 'Perimeter: ${_formatMeters(perimeter)} • '
            'Area: ${_formatSquareMeters(area)}';
      case UserGeofenceEditorMode.rectangle:
        final corners = rectangleCorners;
        if (corners.length != 4) return null;
        final perimeter = _lineLengthMeters([...corners, corners.first]);
        final area = _polygonAreaSquareMeters(corners);
        return 'Perimeter: ${_formatMeters(perimeter)} • '
            'Area: ${_formatSquareMeters(area)}';
      case UserGeofenceEditorMode.view:
        return null;
    }
  }

  UserLandmarkGeometryEditorState copyWith({
    UserGeofenceEditorMode? editorMode,
    List<UserGeoPoint>? points,
    Object? circleCenter = _unset,
    Object? circleRadiusM = _unset,
    Object? rectangleStart = _unset,
    Object? rectangleEnd = _unset,
    bool? lockSquare,
    Object? toleranceM = _unset,
    Object? selectedVertexIndex = _unset,
    int? undoDepth,
    int? redoDepth,
    bool? isDirty,
    Object? validationError = _unset,
    Object? mapCenter = _unset,
    double? mapZoom,
    bool? snapEnabled,
  }) {
    return UserLandmarkGeometryEditorState(
      editorMode: editorMode ?? this.editorMode,
      points: points ?? this.points,
      circleCenter: identical(circleCenter, _unset)
          ? this.circleCenter
          : circleCenter as UserGeoPoint?,
      circleRadiusM: identical(circleRadiusM, _unset)
          ? this.circleRadiusM
          : circleRadiusM as double?,
      rectangleStart: identical(rectangleStart, _unset)
          ? this.rectangleStart
          : rectangleStart as UserGeoPoint?,
      rectangleEnd: identical(rectangleEnd, _unset)
          ? this.rectangleEnd
          : rectangleEnd as UserGeoPoint?,
      lockSquare: lockSquare ?? this.lockSquare,
      toleranceM: identical(toleranceM, _unset)
          ? this.toleranceM
          : toleranceM as double?,
      selectedVertexIndex: identical(selectedVertexIndex, _unset)
          ? this.selectedVertexIndex
          : selectedVertexIndex as int?,
      undoDepth: undoDepth ?? this.undoDepth,
      redoDepth: redoDepth ?? this.redoDepth,
      isDirty: isDirty ?? this.isDirty,
      validationError: identical(validationError, _unset)
          ? this.validationError
          : validationError as String?,
      mapCenter: identical(mapCenter, _unset)
          ? this.mapCenter
          : mapCenter as UserGeoPoint?,
      mapZoom: mapZoom ?? this.mapZoom,
      snapEnabled: snapEnabled ?? this.snapEnabled,
    );
  }
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class UserLandmarkGeometryEditorController
    extends StateNotifier<UserLandmarkGeometryEditorState> {
  UserLandmarkGeometryEditorController({
    UserGeofenceEditorMode initialMode = UserGeofenceEditorMode.polygon,
    UserGeoPoint? initialCenter,
    double initialZoom = 14,
  }) : super(
          UserLandmarkGeometryEditorState.initial(
            mode: initialMode,
            mapCenter: initialCenter,
            mapZoom: initialZoom,
          ),
        );

  static const int _historyLimit = 50;

  final List<UserLandmarkGeometryEditorState> _undoStack =
      <UserLandmarkGeometryEditorState>[];
  final List<UserLandmarkGeometryEditorState> _redoStack =
      <UserLandmarkGeometryEditorState>[];

  // ----- Mode / map view ---------------------------------------------------

  void setMode(UserGeofenceEditorMode mode) {
    if (mode == state.editorMode) return;
    _pushHistory();
    state = state.copyWith(
      editorMode: mode,
      selectedVertexIndex: null,
      validationError: null,
    );
  }

  void setMapView({UserGeoPoint? center, double? zoom}) {
    state = state.copyWith(mapCenter: center, mapZoom: zoom);
  }

  void setSnapEnabled(bool enabled) {
    if (enabled == state.snapEnabled) return;
    state = state.copyWith(snapEnabled: enabled);
  }

  void setLockSquare(bool enabled) {
    if (enabled == state.lockSquare) return;
    _pushHistory();
    state = state.copyWith(lockSquare: enabled, isDirty: true);
  }

  // ----- Map tap dispatcher ------------------------------------------------

  void tapMap(UserGeoPoint point) {
    switch (state.editorMode) {
      case UserGeofenceEditorMode.circle:
        if (state.circleCenter == null) {
          setCircleCenter(point);
        } else if ((state.circleRadiusM ?? 0) <= 0) {
          final distance = _distanceMeters(state.circleCenter!, point);
          setCircleRadius(distance);
        } else {
          // Re-center on subsequent taps.
          setCircleCenter(point);
        }
        break;
      case UserGeofenceEditorMode.rectangle:
        if (state.rectangleStart == null) {
          setRectangleCornerA(point);
        } else {
          setRectangleCornerB(point);
        }
        break;
      case UserGeofenceEditorMode.polygon:
      case UserGeofenceEditorMode.line:
        addPoint(point);
        break;
      case UserGeofenceEditorMode.view:
        break;
    }
  }

  // ----- Circle ------------------------------------------------------------

  void setCircleCenter(UserGeoPoint point) {
    _pushHistory();
    state = state.copyWith(
      circleCenter: point,
      isDirty: true,
      validationError: null,
    );
  }

  void setCircleRadius(double meters) {
    if (meters < 0) meters = 0;
    _pushHistory();
    state = state.copyWith(
      circleRadiusM: meters,
      isDirty: true,
      validationError: null,
    );
  }

  // ----- Rectangle ---------------------------------------------------------

  void setRectangleCornerA(UserGeoPoint point) {
    _pushHistory();
    state = state.copyWith(
      rectangleStart: point,
      isDirty: true,
      validationError: null,
    );
  }

  void setRectangleCornerB(UserGeoPoint point) {
    _pushHistory();
    state = state.copyWith(
      rectangleEnd: point,
      isDirty: true,
      validationError: null,
    );
  }

  // ----- Polygon / Line points --------------------------------------------

  void addPoint(UserGeoPoint point) {
    _pushHistory();
    final next = <UserGeoPoint>[...state.points, point];
    state = state.copyWith(
      points: next,
      selectedVertexIndex: next.length - 1,
      isDirty: true,
      validationError: null,
    );
  }

  void updatePoint(int index, UserGeoPoint point) {
    if (index < 0 || index >= state.points.length) return;
    _pushHistory();
    final next = <UserGeoPoint>[...state.points];
    next[index] = point;
    state = state.copyWith(
      points: next,
      isDirty: true,
      validationError: null,
    );
  }

  void removePoint(int index) {
    if (index < 0 || index >= state.points.length) return;
    _pushHistory();
    final next = <UserGeoPoint>[...state.points]..removeAt(index);
    int? selected = state.selectedVertexIndex;
    if (selected != null) {
      if (selected == index) {
        selected = null;
      } else if (selected > index) {
        selected = selected - 1;
      }
    }
    state = state.copyWith(
      points: next,
      selectedVertexIndex: selected,
      isDirty: true,
      validationError: null,
    );
  }

  void insertPointAfter(int index, UserGeoPoint point) {
    if (index < -1 || index >= state.points.length) return;
    _pushHistory();
    final next = <UserGeoPoint>[...state.points];
    next.insert(index + 1, point);
    state = state.copyWith(
      points: next,
      selectedVertexIndex: index + 1,
      isDirty: true,
      validationError: null,
    );
  }

  void selectVertex(int? index) {
    if (index == state.selectedVertexIndex) return;
    if (index != null && (index < 0 || index >= state.points.length)) {
      return;
    }
    state = state.copyWith(selectedVertexIndex: index);
  }

  /// Nudges the currently selected vertex by the given north/east meter
  /// offsets. Positive north moves toward higher latitude; positive east
  /// moves toward higher longitude.
  void moveSelectedPointByMeters({double north = 0, double east = 0}) {
    final index = state.selectedVertexIndex;
    if (index == null || index < 0 || index >= state.points.length) return;
    if (north == 0 && east == 0) return;
    final current = state.points[index];
    final dLat = north / _metersPerDegreeLat;
    final lonScale = math.cos(current.lat * math.pi / 180);
    final dLon =
        lonScale.abs() < 1e-9 ? 0.0 : east / (_metersPerDegreeLat * lonScale);
    updatePoint(
      index,
      UserGeoPoint(lat: current.lat + dLat, lon: current.lon + dLon),
    );
  }

  // ----- Tolerance ---------------------------------------------------------

  void updateTolerance(double meters) {
    final normalized = meters < 0 ? 0.0 : meters;
    state = state.copyWith(toleranceM: normalized, isDirty: true);
  }

  // ----- Undo / redo / clear ----------------------------------------------

  void undo() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    _redoStack.add(_snapshot());
    if (_redoStack.length > _historyLimit) {
      _redoStack.removeAt(0);
    }
    state = previous.copyWith(
      undoDepth: _undoStack.length,
      redoDepth: _redoStack.length,
    );
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(_snapshot());
    if (_undoStack.length > _historyLimit) {
      _undoStack.removeAt(0);
    }
    state = next.copyWith(
      undoDepth: _undoStack.length,
      redoDepth: _redoStack.length,
    );
  }

  void clear() {
    _pushHistory();
    state = state.copyWith(
      points: const <UserGeoPoint>[],
      circleCenter: null,
      circleRadiusM: null,
      rectangleStart: null,
      rectangleEnd: null,
      selectedVertexIndex: null,
      isDirty: true,
      validationError: null,
    );
  }

  // ----- Validation & export ----------------------------------------------

  /// Returns null on success, or a user-facing error message. Also stores the
  /// message in [state.validationError].
  String? validate() {
    final error = _validateForCurrentMode();
    state = state.copyWith(validationError: error);
    return error;
  }

  /// Returns a geofence geodata object for the current mode, or null if
  /// the geometry is invalid. Use [validate] to surface the reason.
  UserGeofenceGeoData? buildGeofenceGeoData() {
    if (_validateForCurrentMode() != null) return null;
    switch (state.editorMode) {
      case UserGeofenceEditorMode.circle:
        return UserCircleGeoData(
          center: state.circleCenter!,
          radiusM: state.circleRadiusM!,
        );
      case UserGeofenceEditorMode.polygon:
        return UserPolygonGeoData(coordinates: List.of(state.points));
      case UserGeofenceEditorMode.rectangle:
        return UserPolygonGeoData(coordinates: state.rectangleCorners);
      case UserGeofenceEditorMode.line:
        return UserLineGeoData(
          coordinates: List.of(state.points),
          toleranceM: state.toleranceM,
        );
      case UserGeofenceEditorMode.view:
        return null;
    }
  }

  /// Builds a line geodata for a route. Returns null if the geometry is
  /// invalid (route requires ≥2 points).
  UserLineGeoData? buildRouteGeoData() {
    if (state.points.length < 2) {
      state = state.copyWith(
        validationError: 'Route requires at least 2 points.',
      );
      return null;
    }
    state = state.copyWith(validationError: null);
    return UserLineGeoData(
      coordinates: List.of(state.points),
      toleranceM: state.toleranceM,
    );
  }

  /// Hydrates the editor from previously persisted geodata so the user can
  /// continue editing an existing geofence or route.
  void loadFromExistingGeodata(
    UserGeofenceGeoData? geodata, {
    double? toleranceM,
    LatLng? cameraCenter,
  }) {
    _undoStack.clear();
    _redoStack.clear();

    if (geodata == null) {
      state = state.copyWith(
        points: const <UserGeoPoint>[],
        circleCenter: null,
        circleRadiusM: null,
        rectangleStart: null,
        rectangleEnd: null,
        toleranceM: toleranceM,
        selectedVertexIndex: null,
        undoDepth: 0,
        redoDepth: 0,
        isDirty: false,
        validationError: null,
        mapCenter: cameraCenter == null
            ? state.mapCenter
            : UserGeoPoint(
                lat: cameraCenter.latitude,
                lon: cameraCenter.longitude,
              ),
      );
      return;
    }

    if (geodata is UserCircleGeoData) {
      state = state.copyWith(
        editorMode: UserGeofenceEditorMode.circle,
        points: const <UserGeoPoint>[],
        circleCenter: geodata.center,
        circleRadiusM: geodata.radiusM,
        rectangleStart: null,
        rectangleEnd: null,
        toleranceM: toleranceM,
        selectedVertexIndex: null,
        undoDepth: 0,
        redoDepth: 0,
        isDirty: false,
        validationError: null,
      );
      return;
    }

    if (geodata is UserPolygonGeoData) {
      state = state.copyWith(
        editorMode: UserGeofenceEditorMode.polygon,
        points: List.of(geodata.coordinates),
        circleCenter: null,
        circleRadiusM: null,
        rectangleStart: null,
        rectangleEnd: null,
        toleranceM: toleranceM,
        selectedVertexIndex: null,
        undoDepth: 0,
        redoDepth: 0,
        isDirty: false,
        validationError: null,
      );
      return;
    }

    if (geodata is UserLineGeoData) {
      state = state.copyWith(
        editorMode: UserGeofenceEditorMode.line,
        points: List.of(geodata.coordinates),
        circleCenter: null,
        circleRadiusM: null,
        rectangleStart: null,
        rectangleEnd: null,
        toleranceM: toleranceM ?? geodata.toleranceM,
        selectedVertexIndex: null,
        undoDepth: 0,
        redoDepth: 0,
        isDirty: false,
        validationError: null,
      );
    }
  }

  // ----- Internals ---------------------------------------------------------

  String? _validateForCurrentMode() {
    switch (state.editorMode) {
      case UserGeofenceEditorMode.circle:
        if (state.circleCenter == null) {
          return 'Tap the map to set the circle center.';
        }
        if (!_isFinitePoint(state.circleCenter!)) {
          return 'Circle center has invalid coordinates.';
        }
        final r = state.circleRadiusM;
        if (r == null || !r.isFinite || r <= 0) {
          return 'Circle radius must be greater than zero.';
        }
        return null;
      case UserGeofenceEditorMode.polygon:
        if (_uniquePointCount(state.points) < 3) {
          return 'Polygon requires at least 3 unique points.';
        }
        if (state.points.any((p) => !_isFinitePoint(p))) {
          return 'Polygon has invalid coordinates.';
        }
        return null;
      case UserGeofenceEditorMode.rectangle:
        if (state.rectangleStart == null || state.rectangleEnd == null) {
          return 'Tap two corners to define the rectangle.';
        }
        if (!_isFinitePoint(state.rectangleStart!) ||
            !_isFinitePoint(state.rectangleEnd!)) {
          return 'Rectangle corners have invalid coordinates.';
        }
        if (state.rectangleStart!.isCloseTo(state.rectangleEnd!)) {
          return 'Rectangle corners must be different points.';
        }
        return null;
      case UserGeofenceEditorMode.line:
        if (state.points.length < 2) {
          return 'Line requires at least 2 points.';
        }
        if (state.points.any((p) => !_isFinitePoint(p))) {
          return 'Line has invalid coordinates.';
        }
        if (state.toleranceM != null &&
            (!state.toleranceM!.isFinite || state.toleranceM! < 0)) {
          return 'Tolerance must be a non-negative number.';
        }
        return null;
      case UserGeofenceEditorMode.view:
        return 'Switch to a drawing mode to edit geometry.';
    }
  }

  UserLandmarkGeometryEditorState _snapshot() {
    return state.copyWith(
      points: List<UserGeoPoint>.unmodifiable(state.points),
    );
  }

  void _pushHistory() {
    _undoStack.add(_snapshot());
    if (_undoStack.length > _historyLimit) {
      _undoStack.removeAt(0);
    }
    if (_redoStack.isNotEmpty) {
      _redoStack.clear();
    }
    // Reflect new stack sizes in the next state mutation.
    state = state.copyWith(
      undoDepth: _undoStack.length,
      redoDepth: _redoStack.length,
    );
  }
}

// ---------------------------------------------------------------------------
// Geometry helpers
// ---------------------------------------------------------------------------

const double _metersPerDegreeLat = 111320.0;
const double _earthRadiusM = 6371008.8;

bool _isFinitePoint(UserGeoPoint p) =>
    p.lat.isFinite &&
    p.lon.isFinite &&
    p.lat >= -90 &&
    p.lat <= 90 &&
    p.lon >= -180 &&
    p.lon <= 180;

double _distanceMeters(UserGeoPoint a, UserGeoPoint b) {
  final lat1 = a.lat * math.pi / 180;
  final lat2 = b.lat * math.pi / 180;
  final dLat = lat2 - lat1;
  final dLon = (b.lon - a.lon) * math.pi / 180;
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return _earthRadiusM * c;
}

double _lineLengthMeters(List<UserGeoPoint> points) {
  if (points.length < 2) return 0;
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += _distanceMeters(points[i - 1], points[i]);
  }
  return total;
}

double _polygonAreaSquareMeters(List<UserGeoPoint> points) {
  if (points.length < 3) return 0;
  // Equirectangular projection around the centroid; adequate for editor UI.
  var sumLat = 0.0;
  for (final p in points) {
    sumLat += p.lat;
  }
  final refLat = (sumLat / points.length) * math.pi / 180;
  final cosRef = math.cos(refLat);
  final projected = points
      .map((p) => <double>[
            p.lon * _metersPerDegreeLat * cosRef,
            p.lat * _metersPerDegreeLat,
          ])
      .toList(growable: false);
  var area = 0.0;
  for (var i = 0; i < projected.length; i++) {
    final j = (i + 1) % projected.length;
    area += projected[i][0] * projected[j][1];
    area -= projected[j][0] * projected[i][1];
  }
  return area.abs() / 2;
}

int _uniquePointCount(List<UserGeoPoint> points) {
  final set = <String>{};
  for (final p in points) {
    set.add('${p.lat.toStringAsFixed(8)}_${p.lon.toStringAsFixed(8)}');
  }
  return set.length;
}

String _formatMeters(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
  return '${meters.toStringAsFixed(0)} m';
}

String _formatSquareMeters(double squareMeters) {
  if (squareMeters >= 1000000) {
    return '${(squareMeters / 1000000).toStringAsFixed(2)} km²';
  }
  if (squareMeters >= 10000) {
    return '${(squareMeters / 10000).toStringAsFixed(2)} ha';
  }
  return '${squareMeters.toStringAsFixed(0)} m²';
}
