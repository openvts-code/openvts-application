import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../models/user_landmark_model.dart';
import '../models/user_route_optimisation_model.dart';
import 'user_landmark_service.dart';

/// Service layer for the Route Optimisation feature.
///
/// Responsibilities:
/// 1. Read POIs/geofences via the existing [UserLandmarkService] (single
///    source for those endpoints — no new backend routes are introduced).
/// 2. Convert landmarks into [RouteOptimisationPoint]s with stable IDs.
/// 3. Persist the final optimised route as a `LINE` geofence via
///    [UserLandmarkService.createRoute].
/// 4. Optionally fetch a road-aligned polyline from the public OSRM demo
///    server. OSRM is **never required** — every failure falls back to a
///    straight-line route and returns `null` to the caller.
/// 5. Provide export helpers for "Copy JSON" / "Copy report" UI buttons.
class UserRouteOptimisationService {
  UserRouteOptimisationService(
    this._landmarks, {
    Dio? osrmClient,
    String osrmBaseUrl = _defaultOsrmBaseUrl,
  })  : _osrmBaseUrl = osrmBaseUrl,
        _osrm = osrmClient ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 25),
                responseType: ResponseType.json,
                headers: const <String, String>{
                  'Accept': 'application/json',
                },
              ),
            );

  static const String _defaultOsrmBaseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  /// Maximum waypoints per OSRM request before the service splits the route
  /// into overlapping batches. The public OSRM demo server soft-limits at
  /// ~100 — staying well under that keeps batches stable.
  static const int kOsrmMaxWaypointsPerRequest = 60;

  final UserLandmarkService _landmarks;
  final Dio _osrm;
  final String _osrmBaseUrl;

  // -------------------------------------------------------------------------
  // 1) Landmark lookups
  // -------------------------------------------------------------------------

  Future<List<UserPoi>> fetchPois({String? search}) {
    return _landmarks.fetchPois(search: search, isActive: true);
  }

  Future<List<UserGeofence>> fetchGeofences({String? search}) {
    return _landmarks.fetchGeofences(search: search, isActive: true);
  }

  // -------------------------------------------------------------------------
  // 2) Landmark → RouteOptimisationPoint conversion
  // -------------------------------------------------------------------------

  /// Builds a route point from a POI. Returns `null` when coordinates are
  /// missing or out of range so callers can silently skip bad rows.
  RouteOptimisationPoint? poiToPoint(UserPoi poi) {
    final c = poi.coordinates;
    if (c == null) return null;
    if (!RouteOptimisationValidation.isLatValid(c.lat) ||
        !RouteOptimisationValidation.isLonValid(c.lon)) {
      return null;
    }
    final name = poi.name.trim().isEmpty ? 'POI' : poi.name.trim();
    return RouteOptimisationPoint(
      id: '${RouteOptimisationPointSource.poi.idPrefix}-${poi.id}',
      name: name,
      lat: c.lat,
      lon: c.lon,
      source: RouteOptimisationPointSource.poi,
      sourceId: poi.id,
    );
  }

  /// Builds a route point from a geofence by resolving its visual centre.
  /// Returns `null` when no valid centre can be computed.
  RouteOptimisationPoint? geofenceToPoint(UserGeofence geofence) {
    final centre = geofenceCenter(geofence);
    if (centre == null) return null;
    if (!RouteOptimisationValidation.isLatValid(centre.lat) ||
        !RouteOptimisationValidation.isLonValid(centre.lon)) {
      return null;
    }
    final name =
        geofence.name.trim().isEmpty ? 'Geofence' : geofence.name.trim();
    return RouteOptimisationPoint(
      id: '${RouteOptimisationPointSource.geofence.idPrefix}-${geofence.id}',
      name: name,
      lat: centre.lat,
      lon: centre.lon,
      source: RouteOptimisationPointSource.geofence,
      sourceId: geofence.id,
    );
  }

  /// Computes a representative centre for any supported geofence shape:
  /// circle → centre, polygon → bounds centre, line → midpoint by arc length.
  UserGeoPoint? geofenceCenter(UserGeofence geofence) {
    final geo = geofence.geodata;
    if (geo == null) return null;
    if (geo is UserCircleGeoData) {
      return geo.center;
    }
    if (geo is UserPolygonGeoData) {
      return _polygonBoundsCenter(geo.coordinates);
    }
    if (geo is UserLineGeoData) {
      return _lineMidpoint(geo.coordinates);
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // 3) Save optimised route
  // -------------------------------------------------------------------------

  /// Persists a route via `POST /user/routes`.
  Future<UserRouteLandmark> saveRoute(CreateUserRouteRequest request) {
    return _landmarks.createRoute(request);
  }

  /// Builds the `LINE` payload coordinates for the optimised order, optionally
  /// preferring the road-aligned [roadGeometry] over straight-line connectors.
  ///
  /// Coordinates handed to [CreateUserRouteRequest.toJson] are encoded as
  /// `[lon, lat]` by [UserGeoPoint.toLonLat] — callers only need to provide
  /// the [UserLineGeoData] returned here.
  UserLineGeoData buildLineGeoDataForOrder({
    required List<RouteOptimisationPoint> points,
    required List<int> order,
    required bool roundTrip,
    OptimisedRoadGeometry? roadGeometry,
    double? toleranceM,
  }) {
    if (roadGeometry != null && roadGeometry.isNotEmpty) {
      return UserLineGeoData(
        coordinates: List<UserGeoPoint>.from(roadGeometry.backendCoordinates),
        toleranceM: toleranceM,
      );
    }
    final coords = <UserGeoPoint>[];
    for (final idx in order) {
      if (idx < 0 || idx >= points.length) continue;
      coords.add(points[idx].toGeoPoint());
    }
    if (roundTrip && coords.length >= 2) {
      final first = coords.first;
      final last = coords.last;
      if (first.lat != last.lat || first.lon != last.lon) {
        coords.add(first);
      }
    }
    return UserLineGeoData(coordinates: coords, toleranceM: toleranceM);
  }

  // -------------------------------------------------------------------------
  // 4) Optional OSRM road geometry
  // -------------------------------------------------------------------------

  /// Returns an OSRM-aligned polyline for [points] visited in [order], or
  /// `null` when the request fails for any reason (network, timeout, HTTP
  /// error, malformed response, too few points, …). Never throws — saving
  /// the route must not depend on this call.
  ///
  /// For inputs larger than [kOsrmMaxWaypointsPerRequest] the route is split
  /// into overlapping batches and the legs are stitched together.
  Future<OptimisedRoadGeometry?> fetchOsrmRouteForOrder({
    required List<RouteOptimisationPoint> points,
    required List<int> order,
    required bool roundTrip,
  }) async {
    try {
      final resolved = <RouteOptimisationPoint>[
        for (final i in order)
          if (i >= 0 && i < points.length) points[i],
      ];
      if (resolved.length < 2) return null;
      if (roundTrip) {
        resolved.add(resolved.first);
      }

      // Single request fast path.
      if (resolved.length <= kOsrmMaxWaypointsPerRequest) {
        return await _osrmRequestBatch(resolved);
      }

      // Batched path: overlap by 1 waypoint so legs stitch without gaps.
      final batches = <List<RouteOptimisationPoint>>[];
      var i = 0;
      while (i < resolved.length - 1) {
        final end = (i + kOsrmMaxWaypointsPerRequest <= resolved.length)
            ? i + kOsrmMaxWaypointsPerRequest
            : resolved.length;
        batches.add(resolved.sublist(i, end));
        if (end == resolved.length) break;
        i = end - 1;
      }

      final allLegs = <List<LatLng>>[];
      final allBackend = <UserGeoPoint>[];
      double? totalDist;
      double? totalDur;
      for (final batch in batches) {
        final part = await _osrmRequestBatch(batch);
        if (part == null) return null;
        allLegs.addAll(part.legs);
        for (final p in part.backendCoordinates) {
          if (allBackend.isNotEmpty) {
            final last = allBackend.last;
            if (last.lat == p.lat && last.lon == p.lon) continue;
          }
          allBackend.add(p);
        }
        totalDist = (totalDist ?? 0) + (part.distanceMeters ?? 0);
        totalDur = (totalDur ?? 0) + (part.durationSeconds ?? 0);
      }
      return OptimisedRoadGeometry(
        legs: allLegs,
        backendCoordinates: allBackend,
        distanceMeters: totalDist,
        durationSeconds: totalDur,
      );
    } catch (_) {
      // Network/parse failures are non-fatal — caller must fall back to
      // straight-line connectors.
      return null;
    }
  }

  Future<OptimisedRoadGeometry?> _osrmRequestBatch(
    List<RouteOptimisationPoint> waypoints,
  ) async {
    if (waypoints.length < 2) return null;
    final coords = waypoints
        .map((p) =>
            '${p.lon.toStringAsFixed(6)},${p.lat.toStringAsFixed(6)}')
        .join(';');
    final url = '$_osrmBaseUrl/$coords';
    final Response<dynamic> resp;
    try {
      resp = await _osrm.get<dynamic>(
        url,
        queryParameters: const <String, dynamic>{
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'false',
        },
      );
    } on DioException {
      return null;
    }
    final data = resp.data;
    if (data is! Map) return null;
    final code = data['code'];
    if (code is String && code != 'Ok') return null;
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final route = routes.first;
    if (route is! Map) return null;

    // Full polyline (GeoJSON coords are [lon, lat]).
    final geometry = route['geometry'];
    final backendCoords = <UserGeoPoint>[];
    final fullLatLng = <LatLng>[];
    if (geometry is Map) {
      final coordsRaw = geometry['coordinates'];
      if (coordsRaw is List) {
        for (final c in coordsRaw) {
          if (c is List && c.length >= 2) {
            final lon = _asDouble(c[0]);
            final lat = _asDouble(c[1]);
            if (lon == null || lat == null) continue;
            if (!RouteOptimisationValidation.isLatValid(lat) ||
                !RouteOptimisationValidation.isLonValid(lon)) {
              continue;
            }
            backendCoords.add(UserGeoPoint(lat: lat, lon: lon));
            fullLatLng.add(LatLng(lat, lon));
          }
        }
      }
    }
    if (backendCoords.length < 2) return null;

    // Per-leg polylines — when OSRM omits per-leg geometry (default for the
    // demo server) we surface the full polyline as a single leg.
    final legs = <List<LatLng>>[];
    final rawLegs = route['legs'];
    if (rawLegs is List && rawLegs.isNotEmpty) {
      for (final leg in rawLegs) {
        if (leg is! Map) continue;
        final legGeom = leg['geometry'];
        if (legGeom is Map) {
          final legCoords = legGeom['coordinates'];
          if (legCoords is List && legCoords.isNotEmpty) {
            final pts = <LatLng>[];
            for (final c in legCoords) {
              if (c is List && c.length >= 2) {
                final lon = _asDouble(c[0]);
                final lat = _asDouble(c[1]);
                if (lon != null && lat != null) pts.add(LatLng(lat, lon));
              }
            }
            if (pts.length >= 2) legs.add(pts);
          }
        }
      }
    }
    if (legs.isEmpty) legs.add(fullLatLng);

    return OptimisedRoadGeometry(
      legs: legs,
      backendCoordinates: backendCoords,
      distanceMeters: _asDouble(route['distance']),
      durationSeconds: _asDouble(route['duration']),
    );
  }

  // -------------------------------------------------------------------------
  // 5) Export helpers
  // -------------------------------------------------------------------------

  /// Pretty-printed JSON snapshot of the optimisation workspace — suitable for
  /// a "Copy JSON" button. Includes points, result metrics and the optimised
  /// order (both as indices and as lat/lon pairs).
  String buildJsonExport({
    required List<RouteOptimisationPoint> points,
    required RouteOptimisationConstraints constraints,
    RouteOptimisationResult? result,
    OptimisedRoadGeometry? roadGeometry,
  }) {
    final payload = <String, dynamic>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'constraints': <String, dynamic>{
        'startIndex': constraints.startIndex,
        'endIndex': constraints.endIndex,
        'roundTrip': constraints.roundTrip,
      },
      'points': <Map<String, dynamic>>[
        for (final p in points)
          <String, dynamic>{
            'id': p.id,
            'name': p.name,
            'lat': p.lat,
            'lon': p.lon,
            'source': p.source.name,
            if (p.sourceId != null) 'sourceId': p.sourceId,
          },
      ],
    };
    if (result != null) {
      payload['result'] = <String, dynamic>{
        'algorithmUsed': result.algorithmUsed,
        'processingMs': result.processingMs,
        'originalDistanceKm': result.originalDistanceKm,
        'optimizedDistanceKm': result.optimizedDistanceKm,
        'improvementPct': result.improvementPct,
        'originalOrder': result.originalOrder,
        'optimizedOrder': result.optimizedOrder,
        'optimizedSequence': <Map<String, dynamic>>[
          for (final i in result.optimizedOrder)
            if (i >= 0 && i < points.length)
              <String, dynamic>{
                'index': i,
                'name': points[i].name,
                'lat': points[i].lat,
                'lon': points[i].lon,
              },
        ],
      };
    }
    if (roadGeometry != null && roadGeometry.isNotEmpty) {
      payload['roadGeometry'] = <String, dynamic>{
        if (roadGeometry.distanceMeters != null)
          'distanceMeters': roadGeometry.distanceMeters,
        if (roadGeometry.durationSeconds != null)
          'durationSeconds': roadGeometry.durationSeconds,
        'coordinates': <List<double>>[
          for (final p in roadGeometry.backendCoordinates) p.toLonLat(),
        ],
      };
    }
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Plain-text version of [RouteOptimisationResult.logs] — exposed so the UI
  /// has a single canonical source for "Copy report".
  String buildTextReport(RouteOptimisationResult result) => result.logs;

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  static UserGeoPoint? _polygonBoundsCenter(List<UserGeoPoint> coords) {
    if (coords.isEmpty) return null;
    double minLat = coords.first.lat, maxLat = coords.first.lat;
    double minLon = coords.first.lon, maxLon = coords.first.lon;
    for (final p in coords) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lon < minLon) minLon = p.lon;
      if (p.lon > maxLon) maxLon = p.lon;
    }
    return UserGeoPoint(
      lat: (minLat + maxLat) / 2.0,
      lon: (minLon + maxLon) / 2.0,
    );
  }

  static UserGeoPoint? _lineMidpoint(List<UserGeoPoint> coords) {
    if (coords.isEmpty) return null;
    if (coords.length == 1) return coords.first;
    const distance = Distance();
    var total = 0.0;
    final segLengths = <double>[];
    for (var i = 0; i < coords.length - 1; i++) {
      final d = distance(
        LatLng(coords[i].lat, coords[i].lon),
        LatLng(coords[i + 1].lat, coords[i + 1].lon),
      );
      segLengths.add(d);
      total += d;
    }
    if (total <= 0) return coords.first;
    final half = total / 2.0;
    var acc = 0.0;
    for (var i = 0; i < segLengths.length; i++) {
      final segLen = segLengths[i];
      if (acc + segLen >= half) {
        final remaining = half - acc;
        final t = segLen == 0 ? 0.0 : remaining / segLen;
        final a = coords[i];
        final b = coords[i + 1];
        return UserGeoPoint(
          lat: a.lat + (b.lat - a.lat) * t,
          lon: a.lon + (b.lon - a.lon) * t,
        );
      }
      acc += segLen;
    }
    return coords.last;
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
