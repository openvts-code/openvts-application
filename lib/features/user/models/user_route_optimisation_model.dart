import 'package:latlong2/latlong.dart';

import 'user_landmark_model.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Origin of a point added to the optimisation workspace.
///
/// `waypoint` is reserved for points that originated from an OSRM mid-segment
/// drag (a future enhancement) — it is intentionally distinct from `map`,
/// which only covers blank-canvas taps.
enum RouteOptimisationPointSource { geofence, poi, map, manual, waypoint }

extension RouteOptimisationPointSourceX on RouteOptimisationPointSource {
  String get label {
    switch (this) {
      case RouteOptimisationPointSource.geofence:
        return 'Geofence';
      case RouteOptimisationPointSource.poi:
        return 'POI';
      case RouteOptimisationPointSource.map:
        return 'Map tap';
      case RouteOptimisationPointSource.manual:
        return 'Manual';
      case RouteOptimisationPointSource.waypoint:
        return 'Waypoint';
    }
  }

  /// Prefix used when synthesising a unique [RouteOptimisationPoint.id].
  String get idPrefix {
    switch (this) {
      case RouteOptimisationPointSource.geofence:
        return 'geofence';
      case RouteOptimisationPointSource.poi:
        return 'poi';
      case RouteOptimisationPointSource.map:
        return 'map';
      case RouteOptimisationPointSource.manual:
        return 'manual';
      case RouteOptimisationPointSource.waypoint:
        return 'waypoint';
    }
  }
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

/// Controlled error type for optimisation pre-flight failures.
class RouteOptimisationException implements Exception {
  const RouteOptimisationException(this.message);
  final String message;
  @override
  String toString() => 'RouteOptimisationException: $message';
}

class RouteOptimisationValidation {
  const RouteOptimisationValidation._();

  static const double minLatitude = -90.0;
  static const double maxLatitude = 90.0;
  static const double minLongitude = -180.0;
  static const double maxLongitude = 180.0;
  static const int minPointsToOptimise = 2;

  static bool isLatValid(double value) =>
      value.isFinite && value >= minLatitude && value <= maxLatitude;

  static bool isLonValid(double value) =>
      value.isFinite && value >= minLongitude && value <= maxLongitude;

  /// Throws [RouteOptimisationException] when [points] cannot be optimised.
  static void requireOptimisable(List<RouteOptimisationPoint> points) {
    if (points.length < minPointsToOptimise) {
      throw const RouteOptimisationException(
        'At least 2 points are required to optimise.',
      );
    }
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (!isLatValid(p.lat)) {
        throw RouteOptimisationException(
          'Point #${i + 1} has invalid latitude (${p.lat}).',
        );
      }
      if (!isLonValid(p.lon)) {
        throw RouteOptimisationException(
          'Point #${i + 1} has invalid longitude (${p.lon}).',
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Point
// ---------------------------------------------------------------------------

/// A single waypoint in the route optimisation workspace.
///
/// `lat`/`lon` are kept as doubles (not [LatLng]) so the model is JSON-safe
/// and matches the rest of the user landmark models.
class RouteOptimisationPoint {
  RouteOptimisationPoint({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.source,
    this.sourceId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final double lat;
  final double lon;
  final RouteOptimisationPointSource source;

  /// Original landmark ID when [source] is `poi` or `geofence`.
  final String? sourceId;

  /// When the point was added to the workspace (used for stable display order
  /// when the user has not yet reordered).
  final DateTime createdAt;

  LatLng toLatLng() => LatLng(lat, lon);

  UserGeoPoint toGeoPoint() => UserGeoPoint(lat: lat, lon: lon);

  RouteOptimisationPoint copyWith({
    String? name,
    double? lat,
    double? lon,
  }) {
    return RouteOptimisationPoint(
      id: id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      source: source,
      sourceId: sourceId,
      createdAt: createdAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Constraints
// ---------------------------------------------------------------------------

/// Start/end/round-trip constraints applied during optimisation.
///
/// [endIndex] == -1 means "auto" (last point) when [roundTrip] is false.
/// When [roundTrip] is true, [endIndex] is ignored.
class RouteOptimisationConstraints {
  const RouteOptimisationConstraints({
    this.startIndex = 0,
    this.endIndex = -1,
    this.roundTrip = false,
  });

  final int startIndex;
  final int endIndex;
  final bool roundTrip;

  bool get hasFixedEnd => !roundTrip && endIndex >= 0;

  RouteOptimisationConstraints copyWith({
    int? startIndex,
    int? endIndex,
    bool? roundTrip,
  }) {
    return RouteOptimisationConstraints(
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      roundTrip: roundTrip ?? this.roundTrip,
    );
  }
}

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------

/// Result of one optimisation run.
class RouteOptimisationResult {
  const RouteOptimisationResult({
    required this.originalOrder,
    required this.optimizedOrder,
    required this.originalDistanceKm,
    required this.optimizedDistanceKm,
    required this.improvementPct,
    required this.processingMs,
    required this.algorithmUsed,
    required this.logs,
  });

  final List<int> originalOrder;
  final List<int> optimizedOrder;
  final double originalDistanceKm;
  final double optimizedDistanceKm;
  final double improvementPct;
  final double processingMs;

  /// Human-readable label of the algorithm chosen for this run, e.g.
  /// `"Held-Karp DP (exact, N=8)"` or
  /// `"Heuristic (NN + 2-opt + multi-start)"`.
  final String algorithmUsed;

  /// Pre-formatted ASCII report (same style as the web build).
  final String logs;

  bool get hasImprovement => optimizedDistanceKm + 1e-6 < originalDistanceKm;

  bool get reordered {
    if (originalOrder.length != optimizedOrder.length) return true;
    for (var i = 0; i < originalOrder.length; i++) {
      if (originalOrder[i] != optimizedOrder[i]) return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// OSRM road geometry
// ---------------------------------------------------------------------------

/// Polyline geometry returned by OSRM (or an equivalent provider) for a fully
/// ordered route. Coordinates are stored in two complementary forms:
///
/// * [legs] — per-leg `LatLng` polylines, ready for `flutter_map`.
/// * [backendCoordinates] — full polyline as `UserGeoPoint`, ready to feed
///   into the backend `geodata.geometry.coordinates` field (serialised as
///   `[lon, lat]` by [UserGeoPoint.toLonLat]).
class OptimisedRoadGeometry {
  const OptimisedRoadGeometry({
    required this.legs,
    required this.backendCoordinates,
    this.distanceMeters,
    this.durationSeconds,
  });

  final List<List<LatLng>> legs;
  final List<UserGeoPoint> backendCoordinates;
  final double? distanceMeters;
  final double? durationSeconds;

  /// Flattened polyline (deduplicated at leg boundaries).
  List<LatLng> get fullPolyline {
    final out = <LatLng>[];
    for (final leg in legs) {
      for (final p in leg) {
        if (out.isNotEmpty) {
          final last = out.last;
          if (last.latitude == p.latitude && last.longitude == p.longitude) {
            continue;
          }
        }
        out.add(p);
      }
    }
    return out;
  }

  bool get isEmpty => backendCoordinates.length < 2;
  bool get isNotEmpty => !isEmpty;
}
