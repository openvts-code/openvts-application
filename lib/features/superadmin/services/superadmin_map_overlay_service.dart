import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../models/superadmin_map_overlay_model.dart';

class SuperadminMapOverlayService {
  SuperadminMapOverlayService(this._apiClient);

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );

  final ApiClient _apiClient;

  Future<List<SuperadminMapGeofence>> getGeofences({
    String? refreshKey,
  }) async {
    if (AppConfig.useMockData) {
      return _mockGeofences;
    }

    final response = await _apiClient.get<List<SuperadminMapGeofence>>(
      ApiEndpoints.superadmin.geofences,
      queryParameters: <String, dynamic>{
        'rk': _requestKey(refreshKey),
      },
      options: _readOptions,
      parser: _parseGeofenceList,
    );

    return response.data;
  }

  Future<List<SuperadminMapPoi>> getPois({
    String? refreshKey,
  }) async {
    if (AppConfig.useMockData) {
      return _mockPois;
    }

    final response = await _apiClient.get<List<SuperadminMapPoi>>(
      ApiEndpoints.superadmin.pois,
      queryParameters: <String, dynamic>{
        'rk': _requestKey(refreshKey),
      },
      options: _readOptions,
      parser: _parsePoiList,
    );

    return response.data;
  }

  Future<List<SuperadminMapRoute>> getRoutes({
    String? refreshKey,
  }) async {
    if (AppConfig.useMockData) {
      return _mockRoutes;
    }

    final response = await _apiClient.get<List<SuperadminMapRoute>>(
      ApiEndpoints.superadmin.routes,
      queryParameters: <String, dynamic>{
        'includeGeodata': true,
        'rk': _requestKey(refreshKey),
      },
      options: _readOptions,
      parser: _parseRouteList,
    );

    return response.data;
  }

  List<SuperadminMapGeofence> parseGeofencesPayload(dynamic json) {
    return _parseGeofenceList(json);
  }

  List<SuperadminMapPoi> parsePoisPayload(dynamic json) {
    return _parsePoiList(json);
  }

  List<SuperadminMapRoute> parseRoutesPayload(dynamic json) {
    return _parseRouteList(json);
  }

  String _requestKey(String? refreshKey) {
    return refreshKey ?? DateTime.now().millisecondsSinceEpoch.toString();
  }

  List<SuperadminMapGeofence> _parseGeofenceList(dynamic json) {
    final items = _extractDomainList(
      json,
      keys: const [
        'geofences',
        'fences',
        'items',
        'rows',
        'records',
        'data',
        'results',
        'list',
        'features',
      ],
      looksLikeRecord: _looksLikeGeofenceRecord,
    );

    final geofences = <SuperadminMapGeofence>[];
    for (var index = 0; index < items.length; index++) {
      final geofence = _parseGeofence(items[index], index);
      if (geofence != null) {
        geofences.add(geofence);
      }
    }

    return geofences;
  }

  List<SuperadminMapPoi> _parsePoiList(dynamic json) {
    final items = _extractDomainList(
      json,
      keys: const [
        'pois',
        'poi',
        'pointsOfInterest',
        'points_of_interest',
        'landmarks',
        'items',
        'rows',
        'records',
        'data',
        'results',
        'list',
        'features',
      ],
      looksLikeRecord: _looksLikePoiRecord,
    );

    final pois = <SuperadminMapPoi>[];
    for (var index = 0; index < items.length; index++) {
      final poi = _parsePoi(items[index], index);
      if (poi != null) {
        pois.add(poi);
      }
    }

    return pois;
  }

  List<SuperadminMapRoute> _parseRouteList(dynamic json) {
    final items = _extractDomainList(
      json,
      keys: const [
        'routes',
        'route',
        'items',
        'rows',
        'records',
        'data',
        'results',
        'list',
        'features',
      ],
      looksLikeRecord: _looksLikeRouteRecord,
    );

    final routes = <SuperadminMapRoute>[];
    for (var index = 0; index < items.length; index++) {
      final route = _parseRoute(items[index], index);
      if (route != null) {
        routes.add(route);
      }
    }

    return routes;
  }

  SuperadminMapGeofence? _parseGeofence(dynamic raw, int index) {
    final source = _asMap(_normalizeStructuredValue(raw));
    if (source.isEmpty) {
      return null;
    }

    final data = _firstMap(source, const ['data', 'geofence', 'fence']);
    final properties =
        _firstMap(source, const ['properties', 'meta', 'details']);
    final geometry = _firstMap(source, const ['geometry', 'shape']) ??
        _firstMap(data, const ['geometry', 'shape']) ??
        _firstMap(properties, const ['geometry', 'shape']);

    final candidates = <Map<String, dynamic>>[
      source,
      if (data != null) data,
      if (properties != null) properties,
      if (geometry != null) geometry,
    ];

    final typeName = (_firstStringInMaps(
              candidates,
              const [
                'type',
                'shapeType',
                'shape_type',
                'geofenceType',
                'geofence_type',
                'geometryType',
                'geometry_type',
              ],
            ) ??
            '')
        .toLowerCase();

    final radiusMeters = _firstNumInMaps(
      candidates,
      const [
        'radius',
        'radiusMeters',
        'radius_meters',
        'radiusInMeters',
        'radius_in_meters',
        'buffer',
      ],
    )?.abs();

    final center = _firstPoint(
      <dynamic>[
        source['center'],
        source['position'],
        source['location'],
        source['latlng'],
        if (data != null) ...[
          data['center'],
          data['position'],
          data['location'],
        ],
        if (properties != null) ...[
          properties['center'],
          properties['position'],
          properties['location'],
        ],
        if (geometry != null) ...[
          geometry['center'],
          geometry['position'],
        ],
        source,
        if (data != null) data,
        if (properties != null) properties,
      ],
    );

    final points = _firstNonEmptyPointSeries(
      <dynamic>[
        if (geometry != null) ...[
          geometry['coordinates'],
          geometry['points'],
          geometry['path'],
        ],
        source['coordinates'],
        source['polygon'],
        source['vertices'],
        source['path'],
        source['points'],
        source['geodata'],
        if (data != null) ...[
          data['coordinates'],
          data['polygon'],
          data['vertices'],
          data['path'],
        ],
        if (properties != null) ...[
          properties['coordinates'],
          properties['polygon'],
          properties['vertices'],
        ],
      ],
      minLength: 3,
      preferGeoJsonOrder:
          _looksLikeGeoJsonMap(geometry) || typeName.contains('polygon'),
    );

    final type = typeName.contains('circle') ||
            (points.isEmpty && center != null && (radiusMeters ?? 0) > 0)
        ? SuperadminMapGeofenceType.circle
        : SuperadminMapGeofenceType.polygon;

    final geofence = SuperadminMapGeofence(
      id: _firstStringInMaps(
            candidates,
            const [
              'id',
              '_id',
              'uid',
              'geofenceId',
              'geofence_id',
              'fenceId',
              'fence_id',
            ],
          ) ??
          'geofence-$index',
      name: _firstStringInMaps(
            candidates,
            const [
              'name',
              'title',
              'label',
              'geofenceName',
              'geofence_name',
              'fenceName',
              'fence_name',
            ],
          ) ??
          'Geofence ${index + 1}',
      type: type,
      points: points,
      center: center,
      radiusMeters: radiusMeters,
    );

    return geofence.hasGeometry ? geofence : null;
  }

  SuperadminMapPoi? _parsePoi(dynamic raw, int index) {
    final source = _asMap(_normalizeStructuredValue(raw));
    if (source.isEmpty) {
      return null;
    }

    final data = _firstMap(source, const ['data', 'poi', 'landmark']);
    final properties =
        _firstMap(source, const ['properties', 'meta', 'details']);
    final geometry = _firstMap(source, const ['geometry']) ??
        _firstMap(data, const ['geometry']) ??
        _firstMap(properties, const ['geometry']);

    final candidates = <Map<String, dynamic>>[
      source,
      if (data != null) data,
      if (properties != null) properties,
      if (geometry != null) geometry,
    ];

    final position = _firstPoint(
      <dynamic>[
        source['location'],
        source['position'],
        source['coordinates'],
        source['center'],
        if (data != null) ...[
          data['location'],
          data['position'],
          data['coordinates'],
          data['center'],
        ],
        if (geometry != null) ...[
          geometry['coordinates'],
          geometry['point'],
        ],
        source,
        if (data != null) data,
        if (properties != null) properties,
      ],
      preferGeoJsonOrder: _looksLikeGeoJsonMap(geometry),
    );

    if (position == null) {
      return null;
    }

    return SuperadminMapPoi(
      id: _firstStringInMaps(
            candidates,
            const [
              'id',
              '_id',
              'uid',
              'poiId',
              'poi_id',
              'landmarkId',
              'landmark_id',
            ],
          ) ??
          'poi-$index',
      name: _firstStringInMaps(
            candidates,
            const [
              'name',
              'title',
              'label',
              'poiName',
              'poi_name',
              'landmarkName',
              'landmark_name',
            ],
          ) ??
          'POI ${index + 1}',
      position: position,
      category: _firstStringInMaps(
        candidates,
        const [
          'category',
          'type',
          'kind',
          'poiType',
          'poi_type',
          'landmarkType',
          'landmark_type',
        ],
      ),
    );
  }

  SuperadminMapRoute? _parseRoute(dynamic raw, int index) {
    final source = _asMap(_normalizeStructuredValue(raw));
    if (source.isEmpty) {
      return null;
    }

    final data = _firstMap(source, const ['data', 'route', 'details']);
    final properties = _firstMap(source, const ['properties', 'meta']);
    final geodata = _firstMap(
      source,
      const ['geodata', 'geoData', 'routeData', 'route_data'],
    );
    final geometry = _firstMap(source, const ['geometry', 'shape']) ??
        _firstMap(data, const ['geometry', 'shape']) ??
        _firstMap(geodata, const ['geometry', 'shape']) ??
        _firstMap(properties, const ['geometry', 'shape']);

    final candidates = <Map<String, dynamic>>[
      source,
      if (data != null) data,
      if (properties != null) properties,
      if (geodata != null) geodata,
      if (geometry != null) geometry,
    ];

    var path = _firstNonEmptyPointSeries(
      <dynamic>[
        source['geodata'],
        source['geoData'],
        source['routeData'],
        source['route_data'],
        if (geodata != null) ...[
          geodata['coordinates'],
          geodata['path'],
          geodata['points'],
        ],
        if (geometry != null) ...[
          geometry['coordinates'],
          geometry['path'],
          geometry['points'],
        ],
        source['coordinates'],
        source['path'],
        source['points'],
        source['polyline'],
        source['waypoints'],
        source['stops'],
        if (data != null) ...[
          data['geodata'],
          data['coordinates'],
          data['path'],
          data['points'],
          data['polyline'],
          data['waypoints'],
          data['stops'],
        ],
      ],
      minLength: 2,
      preferGeoJsonOrder:
          _looksLikeGeoJsonMap(geometry) || _looksLikeGeoJsonMap(geodata),
    );

    if (path.isEmpty) {
      path = _decodePolylineFromCandidates(candidates);
    }

    final route = SuperadminMapRoute(
      id: _firstStringInMaps(
            candidates,
            const [
              'id',
              '_id',
              'uid',
              'routeId',
              'route_id',
            ],
          ) ??
          'route-$index',
      name: _firstStringInMaps(
            candidates,
            const ['name', 'title', 'label', 'routeName', 'route_name'],
          ) ??
          'Route ${index + 1}',
      path: path,
    );

    return route.hasPath ? route : null;
  }

  List<dynamic> _extractDomainList(
    dynamic json, {
    required List<String> keys,
    required bool Function(Map<String, dynamic> json) looksLikeRecord,
  }) {
    final normalized = _normalizeStructuredValue(json);
    if (normalized is List) {
      return normalized;
    }

    final map = _asMap(normalized);
    if (map.isEmpty) {
      return const <dynamic>[];
    }

    for (final key in keys) {
      final value = map[key];
      if (value is List) {
        return value;
      }
    }

    for (final key in const ['data', 'result', 'payload', 'response']) {
      final nested = map[key];
      if (nested == null || identical(nested, normalized)) {
        continue;
      }

      final extracted = _extractDomainList(
        nested,
        keys: keys,
        looksLikeRecord: looksLikeRecord,
      );
      if (extracted.isNotEmpty) {
        return extracted;
      }
    }

    if (looksLikeRecord(map)) {
      return <dynamic>[map];
    }

    return const <dynamic>[];
  }

  LatLng? _firstPoint(
    List<dynamic> candidates, {
    bool preferGeoJsonOrder = false,
  }) {
    for (final candidate in candidates) {
      final points = _extractPointSeries(
        candidate,
        minLength: 1,
        preferGeoJsonOrder: preferGeoJsonOrder,
      );
      if (points.isNotEmpty) {
        return points.first;
      }
    }

    return null;
  }

  List<LatLng> _firstNonEmptyPointSeries(
    List<dynamic> candidates, {
    required int minLength,
    bool preferGeoJsonOrder = false,
  }) {
    for (final candidate in candidates) {
      final points = _extractPointSeries(
        candidate,
        minLength: minLength,
        preferGeoJsonOrder: preferGeoJsonOrder,
      );
      if (points.isNotEmpty) {
        return points;
      }
    }

    return const <LatLng>[];
  }

  List<LatLng> _extractPointSeries(
    dynamic raw, {
    required int minLength,
    bool preferGeoJsonOrder = false,
  }) {
    final normalized = _normalizeStructuredValue(raw);
    if (normalized == null) {
      return const <LatLng>[];
    }

    if (normalized is String) {
      final fromString = _extractPointSeriesFromString(
        normalized,
        preferGeoJsonOrder: preferGeoJsonOrder,
      );
      return fromString.length >= minLength ? fromString : const <LatLng>[];
    }

    final point = _latLngFromAny(
      normalized,
      preferGeoJsonOrder: preferGeoJsonOrder,
    );
    if (point != null) {
      return minLength <= 1 ? <LatLng>[point] : const <LatLng>[];
    }

    if (normalized is List) {
      final points = <LatLng>[];
      for (final item in normalized) {
        points.addAll(
          _extractPointSeries(
            item,
            minLength: 1,
            preferGeoJsonOrder: preferGeoJsonOrder,
          ),
        );
      }

      final deduped = _dedupeSequentialPoints(points);
      return deduped.length >= minLength ? deduped : const <LatLng>[];
    }

    final map = _asMap(normalized);
    if (map.isEmpty) {
      return const <LatLng>[];
    }

    final geometry =
        _firstMap(map, const ['geometry', 'geojson', 'geodata', 'shape']);
    if (geometry != null && geometry.isNotEmpty) {
      final geometryPoints = _extractPointSeries(
        geometry['coordinates'] ??
            geometry['points'] ??
            geometry['path'] ??
            geometry,
        minLength: minLength,
        preferGeoJsonOrder: _looksLikeGeoJsonMap(geometry),
      );
      if (geometryPoints.isNotEmpty) {
        return geometryPoints;
      }
    }

    for (final key in const [
      'coordinates',
      'points',
      'path',
      'polyline',
      'polygon',
      'vertices',
      'geodata',
      'geoData',
      'waypoints',
      'stops',
      'route',
      'location',
      'center',
      'position',
    ]) {
      final points = _extractPointSeries(
        map[key],
        minLength: minLength,
        preferGeoJsonOrder: preferGeoJsonOrder || key == 'coordinates',
      );
      if (points.isNotEmpty) {
        return points;
      }
    }

    return const <LatLng>[];
  }

  List<LatLng> _extractPointSeriesFromString(
    String raw, {
    bool preferGeoJsonOrder = false,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const <LatLng>[];
    }

    for (final separator in const [';', '|']) {
      if (!trimmed.contains(separator)) {
        continue;
      }

      final points = trimmed
          .split(separator)
          .map(
            (segment) => _latLngFromString(
              segment,
              preferGeoJsonOrder: preferGeoJsonOrder,
            ),
          )
          .whereType<LatLng>()
          .toList(growable: false);
      final deduped = _dedupeSequentialPoints(points);
      if (deduped.isNotEmpty) {
        return deduped;
      }
    }

    final matches = RegExp(r'-?\d+(?:\.\d+)?')
        .allMatches(trimmed)
        .map((match) => double.tryParse(match.group(0)!))
        .whereType<double>()
        .toList(growable: false);
    if (matches.length >= 4 && matches.length.isEven) {
      final points = <LatLng>[];
      final preferGeoJson = preferGeoJsonOrder ||
          trimmed.toUpperCase().startsWith('POINT') ||
          trimmed.toUpperCase().startsWith('LINESTRING') ||
          trimmed.toUpperCase().startsWith('POLYGON');
      for (var index = 0; index < matches.length; index += 2) {
        final point = _pointFromPair(
          matches[index],
          matches[index + 1],
          preferGeoJsonOrder: preferGeoJson,
        );
        if (point != null) {
          points.add(point);
        }
      }

      final deduped = _dedupeSequentialPoints(points);
      if (deduped.isNotEmpty) {
        return deduped;
      }
    }

    final point = _latLngFromString(
      trimmed,
      preferGeoJsonOrder: preferGeoJsonOrder,
    );
    return point == null ? const <LatLng>[] : <LatLng>[point];
  }

  List<LatLng> _decodePolylineFromCandidates(
      List<Map<String, dynamic>> candidates) {
    final encoded = _firstStringInMaps(
      candidates,
      const [
        'polyline',
        'encodedPolyline',
        'encoded_polyline',
        'overviewPolyline',
        'overview_polyline',
      ],
    );
    if (encoded == null || encoded.trim().isEmpty) {
      return const <LatLng>[];
    }

    return _decodePolyline(encoded.trim());
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    try {
      while (index < encoded.length) {
        var shift = 0;
        var result = 0;
        var codeUnit = 0;

        do {
          codeUnit = encoded.codeUnitAt(index++) - 63;
          result |= (codeUnit & 0x1f) << shift;
          shift += 5;
        } while (codeUnit >= 0x20);

        final latitudeDelta = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
        latitude += latitudeDelta;

        shift = 0;
        result = 0;

        do {
          codeUnit = encoded.codeUnitAt(index++) - 63;
          result |= (codeUnit & 0x1f) << shift;
          shift += 5;
        } while (codeUnit >= 0x20);

        final longitudeDelta = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
        longitude += longitudeDelta;

        points.add(LatLng(latitude / 1e5, longitude / 1e5));
      }
    } catch (_) {
      return const <LatLng>[];
    }

    return points.length >= 2 ? points : const <LatLng>[];
  }

  LatLng? _latLngFromAny(
    dynamic raw, {
    bool preferGeoJsonOrder = false,
  }) {
    final normalized = _normalizeStructuredValue(raw);
    if (normalized == null) {
      return null;
    }

    if (normalized is String) {
      return _latLngFromString(
        normalized,
        preferGeoJsonOrder: preferGeoJsonOrder,
      );
    }

    if (normalized is List) {
      if (normalized.length < 2) {
        return null;
      }

      final first = _parseDouble(normalized[0]);
      final second = _parseDouble(normalized[1]);
      if (first == null || second == null) {
        return null;
      }

      return _pointFromPair(
        first,
        second,
        preferGeoJsonOrder: preferGeoJsonOrder,
      );
    }

    final map = _asMap(normalized);
    if (map.isEmpty) {
      return null;
    }

    final latitude = _firstNum(
      map,
      const ['lat', 'latitude', 'y', 'centerLat', 'center_lat'],
    );
    final longitude = _firstNum(
      map,
      const ['lng', 'lon', 'long', 'longitude', 'x', 'centerLng', 'center_lng'],
    );
    if (latitude != null && longitude != null) {
      return _pointFromPair(latitude, longitude);
    }

    return null;
  }

  LatLng? _latLngFromString(
    String raw, {
    bool preferGeoJsonOrder = false,
  }) {
    final matches = RegExp(r'-?\d+(?:\.\d+)?')
        .allMatches(raw)
        .map((match) => double.tryParse(match.group(0)!))
        .whereType<double>()
        .toList(growable: false);
    if (matches.length < 2) {
      return null;
    }

    final preferGeoJson =
        preferGeoJsonOrder || raw.toUpperCase().startsWith('POINT');
    return _pointFromPair(
      matches[0],
      matches[1],
      preferGeoJsonOrder: preferGeoJson,
    );
  }

  LatLng? _pointFromPair(
    double first,
    double second, {
    bool preferGeoJsonOrder = false,
  }) {
    final candidates = <List<double>>[];
    if (preferGeoJsonOrder || (first.abs() > 90 && second.abs() <= 90)) {
      candidates.add(<double>[second, first]);
    }
    candidates.add(<double>[first, second]);
    candidates.add(<double>[second, first]);

    for (final candidate in candidates) {
      final latitude = candidate[0];
      final longitude = candidate[1];
      if (_isValidCoordinate(latitude, longitude)) {
        return LatLng(latitude, longitude);
      }
    }

    return null;
  }

  bool _isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  List<LatLng> _dedupeSequentialPoints(List<LatLng> points) {
    if (points.length < 2) {
      return points;
    }

    final deduped = <LatLng>[points.first];
    for (final point in points.skip(1)) {
      final previous = deduped.last;
      if (previous.latitude == point.latitude &&
          previous.longitude == point.longitude) {
        continue;
      }

      deduped.add(point);
    }

    return deduped;
  }

  dynamic _normalizeStructuredValue(dynamic value) {
    if (value is! String) {
      return value;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return trimmed;
      }
    }

    return trimmed;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    final normalized = _normalizeStructuredValue(value);
    if (normalized is Map<String, dynamic>) {
      return normalized;
    }

    if (normalized is Map) {
      return normalized.map(
        (key, item) => MapEntry(key.toString(), item),
      );
    }

    return const <String, dynamic>{};
  }

  Map<String, dynamic>? _firstMap(
    Map<String, dynamic>? source,
    List<String> keys,
  ) {
    if (source == null || source.isEmpty) {
      return null;
    }

    for (final key in keys) {
      final map = _asMap(source[key]);
      if (map.isNotEmpty) {
        return map;
      }
    }

    return null;
  }

  String? _firstString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = _normalizeStructuredValue(source[key]);
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'null') {
          return trimmed;
        }
      }

      if (value is num || value is bool) {
        return value.toString();
      }
    }

    return null;
  }

  double? _firstNum(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = _parseDouble(source[key]);
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  String? _firstStringInMaps(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      final value = _firstString(source, keys);
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  double? _firstNumInMaps(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      final value = _firstNum(source, keys);
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  double? _parseDouble(dynamic value) {
    final normalized = _normalizeStructuredValue(value);
    if (normalized is num) {
      return normalized.toDouble();
    }

    if (normalized is String) {
      return double.tryParse(normalized.trim());
    }

    return null;
  }

  bool _looksLikeGeoJsonMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return false;
    }

    final type = (_firstString(map, const ['type']) ?? '').toLowerCase();
    return type == 'point' ||
        type == 'multipoint' ||
        type == 'linestring' ||
        type == 'multilinestring' ||
        type == 'polygon' ||
        type == 'multipolygon' ||
        type == 'feature';
  }

  bool _looksLikeGeofenceRecord(Map<String, dynamic> json) {
    return _firstString(
              json,
              const ['geofenceId', 'geofence_id', 'fenceId', 'fence_id'],
            ) !=
            null ||
        _firstNum(
              json,
              const ['radius', 'radiusMeters', 'radius_meters'],
            ) !=
            null ||
        json.containsKey('geometry') ||
        json.containsKey('polygon') ||
        json.containsKey('vertices') ||
        json.containsKey('coordinates') ||
        json.containsKey('center');
  }

  bool _looksLikePoiRecord(Map<String, dynamic> json) {
    return _firstString(
              json,
              const ['poiId', 'poi_id', 'landmarkId', 'landmark_id'],
            ) !=
            null ||
        _firstNum(json, const ['lat', 'latitude']) != null ||
        json.containsKey('location') ||
        json.containsKey('position') ||
        json.containsKey('coordinates');
  }

  bool _looksLikeRouteRecord(Map<String, dynamic> json) {
    return _firstString(json, const ['routeId', 'route_id']) != null ||
        json.containsKey('geodata') ||
        json.containsKey('routeData') ||
        json.containsKey('coordinates') ||
        json.containsKey('path') ||
        json.containsKey('polyline') ||
        json.containsKey('geometry');
  }
}

const List<SuperadminMapGeofence> _mockGeofences = <SuperadminMapGeofence>[
  SuperadminMapGeofence(
    id: 'geofence-yard',
    name: 'South Yard',
    type: SuperadminMapGeofenceType.polygon,
    points: <LatLng>[
      LatLng(28.6218, 77.2056),
      LatLng(28.6228, 77.2122),
      LatLng(28.6185, 77.2148),
      LatLng(28.6162, 77.2084),
    ],
  ),
  SuperadminMapGeofence(
    id: 'geofence-hq',
    name: 'HQ Radius',
    type: SuperadminMapGeofenceType.circle,
    points: <LatLng>[],
    center: LatLng(28.6139, 77.2090),
    radiusMeters: 420,
  ),
];

const List<SuperadminMapPoi> _mockPois = <SuperadminMapPoi>[
  SuperadminMapPoi(
    id: 'poi-workshop',
    name: 'Workshop',
    position: LatLng(28.6177, 77.2078),
    category: 'Service',
  ),
  SuperadminMapPoi(
    id: 'poi-fuel',
    name: 'Fuel Station',
    position: LatLng(28.6206, 77.2146),
    category: 'Fuel',
  ),
];

const List<SuperadminMapRoute> _mockRoutes = <SuperadminMapRoute>[
  SuperadminMapRoute(
    id: 'route-ring',
    name: 'Delivery Loop',
    path: <LatLng>[
      LatLng(28.6118, 77.2014),
      LatLng(28.6174, 77.2052),
      LatLng(28.6208, 77.2121),
      LatLng(28.6159, 77.2176),
      LatLng(28.6101, 77.2134),
    ],
  ),
];
