import 'package:latlong2/latlong.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum UserLandmarkEntityType { geofence, poi, route }

enum UserGeofenceType { circle, polygon, line }

enum UserGeofenceEditorMode { view, circle, polygon, rectangle, line }

enum UserLandmarkStatusFilter { all, active, inactive }

extension UserLandmarkEntityTypeX on UserLandmarkEntityType {
  String get apiValue {
    switch (this) {
      case UserLandmarkEntityType.geofence:
        return 'GEOFENCE';
      case UserLandmarkEntityType.poi:
        return 'POI';
      case UserLandmarkEntityType.route:
        return 'ROUTE';
    }
  }

  String get label {
    switch (this) {
      case UserLandmarkEntityType.geofence:
        return 'Geofence';
      case UserLandmarkEntityType.poi:
        return 'POI';
      case UserLandmarkEntityType.route:
        return 'Route';
    }
  }
}

extension UserGeofenceTypeX on UserGeofenceType {
  String get apiValue {
    switch (this) {
      case UserGeofenceType.circle:
        return 'CIRCLE';
      case UserGeofenceType.polygon:
        return 'POLYGON';
      case UserGeofenceType.line:
        return 'LINE';
    }
  }

  String get label {
    switch (this) {
      case UserGeofenceType.circle:
        return 'Circle';
      case UserGeofenceType.polygon:
        return 'Polygon';
      case UserGeofenceType.line:
        return 'Line';
    }
  }

  static UserGeofenceType? tryParse(dynamic value) {
    final normalized = _normalizeEnumValue(value);
    if (normalized.isEmpty) {
      return null;
    }
    switch (normalized) {
      case 'CIRCLE':
      case 'CIRCULAR':
        return UserGeofenceType.circle;
      case 'POLYGON':
      case 'RECTANGLE':
      case 'RECT':
        return UserGeofenceType.polygon;
      case 'LINE':
      case 'LINESTRING':
      case 'LINE_STRING':
      case 'CORRIDOR':
        return UserGeofenceType.line;
      default:
        return null;
    }
  }
}

extension UserGeofenceEditorModeX on UserGeofenceEditorMode {
  String get label {
    switch (this) {
      case UserGeofenceEditorMode.view:
        return 'View';
      case UserGeofenceEditorMode.circle:
        return 'Circle';
      case UserGeofenceEditorMode.polygon:
        return 'Polygon';
      case UserGeofenceEditorMode.rectangle:
        return 'Rectangle';
      case UserGeofenceEditorMode.line:
        return 'Line';
    }
  }
}

extension UserLandmarkStatusFilterX on UserLandmarkStatusFilter {
  bool? get asActiveFlag {
    switch (this) {
      case UserLandmarkStatusFilter.all:
        return null;
      case UserLandmarkStatusFilter.active:
        return true;
      case UserLandmarkStatusFilter.inactive:
        return false;
    }
  }

  String get label {
    switch (this) {
      case UserLandmarkStatusFilter.all:
        return 'All';
      case UserLandmarkStatusFilter.active:
        return 'Active';
      case UserLandmarkStatusFilter.inactive:
        return 'Inactive';
    }
  }
}

// ---------------------------------------------------------------------------
// Geometry primitives
// ---------------------------------------------------------------------------

class UserGeoPoint {
  const UserGeoPoint({required this.lat, required this.lon});

  final double lat;
  final double lon;

  LatLng toLatLng() => LatLng(lat, lon);

  /// GeoJSON-compatible serialization: [lon, lat].
  List<double> toLonLat() => <double>[lon, lat];

  Map<String, dynamic> toLatLngJson() =>
      <String, dynamic>{'lat': lat, 'lng': lon};

  bool isCloseTo(UserGeoPoint other, {double epsilon = 1e-9}) {
    return (lat - other.lat).abs() < epsilon &&
        (lon - other.lon).abs() < epsilon;
  }

  /// Parses a single point from either:
  /// - `[lon, lat]` (GeoJSON)
  /// - `{ lat, lng }` / `{ lat, lon }` / `{ latitude, longitude }`
  static UserGeoPoint? tryParse(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is UserGeoPoint) {
      return value;
    }

    if (value is LatLng) {
      return UserGeoPoint(lat: value.latitude, lon: value.longitude);
    }

    if (value is List && value.length >= 2) {
      final lon = _toDouble(value[0]);
      final lat = _toDouble(value[1]);
      if (lon != null && lat != null) {
        return UserGeoPoint(lat: lat, lon: lon);
      }
    }

    if (value is Map) {
      final source = _asMap(value);
      final lat = _toDouble(
        _firstValue(source, const ['lat', 'latitude', 'y']),
      );
      final lon = _toDouble(
        _firstValue(source, const ['lng', 'lon', 'long', 'longitude', 'x']),
      );
      if (lat != null && lon != null) {
        return UserGeoPoint(lat: lat, lon: lon);
      }
    }

    return null;
  }

  static List<UserGeoPoint> listFromJson(dynamic value) {
    if (value is! List) {
      return const <UserGeoPoint>[];
    }

    final result = <UserGeoPoint>[];
    for (final entry in value) {
      final parsed = tryParse(entry);
      if (parsed != null) {
        result.add(parsed);
      }
    }
    return result;
  }
}

/// Sealed base for geofence/route geometry payloads.
abstract class UserGeofenceGeoData {
  const UserGeofenceGeoData();

  /// One of CIRCLE / POLYGON / LINE.
  String get kind;

  Map<String, dynamic> toJson();

  bool get isValid;

  static UserGeofenceGeoData? tryParse(dynamic value) {
    final source = _asMap(value);
    if (source.isEmpty) {
      return null;
    }

    final type = UserGeofenceTypeX.tryParse(
      _firstValue(source, const ['type', 'kind', 'shape', 'geometryType']),
    );

    switch (type) {
      case UserGeofenceType.circle:
        return UserCircleGeoData.fromJson(source);
      case UserGeofenceType.polygon:
        return UserPolygonGeoData.fromJson(source);
      case UserGeofenceType.line:
        return UserLineGeoData.fromJson(source);
      case null:
        // Infer from shape contents when no explicit type is given.
        if (source.containsKey('center') ||
            source.containsKey('radius') ||
            source.containsKey('radiusM')) {
          return UserCircleGeoData.fromJson(source);
        }
        final coords =
            _firstValue(source, const ['coordinates', 'points', 'path']);
        if (coords is List && coords.isNotEmpty) {
          // GeoJSON polygon nests rings one level deep.
          final first = coords.first;
          if (first is List && first.isNotEmpty && first.first is List) {
            return UserPolygonGeoData.fromJson(source);
          }
          return UserLineGeoData.fromJson(source);
        }
        return null;
    }
  }
}

class UserCircleGeoData extends UserGeofenceGeoData {
  const UserCircleGeoData({required this.center, required this.radiusM});

  @override
  String get kind => 'CIRCLE';

  final UserGeoPoint center;

  /// Radius in meters.
  final double radiusM;

  @override
  bool get isValid => radiusM > 0;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'kind': kind,
      'center': <String, double>{'lat': center.lat, 'lon': center.lon},
      'radiusM': radiusM,
    };
  }

  factory UserCircleGeoData.fromJson(dynamic value) {
    final source = _asMap(value);
    final center = UserGeoPoint.tryParse(
          _firstValue(source, const ['center', 'centre', 'point']),
        ) ??
        const UserGeoPoint(lat: 0, lon: 0);
    final radius = _toDouble(
          _firstValue(
            source,
            const ['radius', 'radiusM', 'radius_m', 'radiusMeters'],
          ),
        ) ??
        0;
    return UserCircleGeoData(center: center, radiusM: radius);
  }
}

class UserPolygonGeoData extends UserGeofenceGeoData {
  const UserPolygonGeoData({required this.coordinates});

  @override
  String get kind => 'POLYGON';

  final List<UserGeoPoint> coordinates;

  @override
  bool get isValid {
    final unique = <String>{};
    for (final point in coordinates) {
      unique.add('${point.lat.toStringAsFixed(8)}_'
          '${point.lon.toStringAsFixed(8)}');
    }
    return unique.length >= 3;
  }

  @override
  Map<String, dynamic> toJson() {
    final ring = <UserGeoPoint>[...coordinates];
    if (ring.isNotEmpty && !ring.first.isCloseTo(ring.last)) {
      ring.add(ring.first);
    }
    return <String, dynamic>{
      'kind': kind,
      'geometry': <String, dynamic>{
        'type': 'Polygon',
        'coordinates': <List<List<double>>>[
          ring.map((p) => p.toLonLat()).toList(growable: false),
        ],
      },
    };
  }

  factory UserPolygonGeoData.fromJson(dynamic value) {
    final source = _asMap(value);
    dynamic raw = _firstValue(source, const ['coordinates', 'points', 'path']);
    if (raw == null) {
      final geometry = _asMap(_firstValue(source, const ['geometry', 'geo']));
      if (geometry.isNotEmpty) {
        raw = _firstValue(geometry, const ['coordinates', 'points', 'path']);
      }
    }

    List<UserGeoPoint> points = const <UserGeoPoint>[];
    if (raw is List && raw.isNotEmpty) {
      // GeoJSON polygon shape: [[ [lon,lat], ... ]]
      if (raw.first is List &&
          (raw.first as List).isNotEmpty &&
          (raw.first as List).first is List) {
        points = UserGeoPoint.listFromJson(raw.first);
      } else {
        points = UserGeoPoint.listFromJson(raw);
      }
    }

    // Drop the duplicated closing point on inbound parse.
    if (points.length >= 2 && points.first.isCloseTo(points.last)) {
      points = points.sublist(0, points.length - 1);
    }

    return UserPolygonGeoData(coordinates: points);
  }
}

class UserLineGeoData extends UserGeofenceGeoData {
  const UserLineGeoData({
    required this.coordinates,
    this.toleranceM,
  });

  @override
  String get kind => 'LINE';

  final List<UserGeoPoint> coordinates;
  final double? toleranceM;

  @override
  bool get isValid => coordinates.length >= 2;

  @override
  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'kind': kind,
      'geometry': <String, dynamic>{
        'type': 'LineString',
        'coordinates':
            coordinates.map((p) => p.toLonLat()).toList(growable: false),
      },
    };
    if (toleranceM != null) {
      payload['toleranceM'] = toleranceM;
    }
    return payload;
  }

  factory UserLineGeoData.fromJson(dynamic value) {
    final source = _asMap(value);
    final tolerance = _toDouble(
      _firstValue(
        source,
        const [
          'toleranceM',
          'tolerance_m',
          'tolerance',
          'toleranceMeters',
        ],
      ),
    );

    dynamic raw = _firstValue(source, const ['coordinates', 'points', 'path']);
    // OSRM-style wrapper: { kind:'LINE', geometry:{ type:'LineString', coordinates:[...] } }.
    if (raw == null) {
      final geometry = _asMap(_firstValue(source, const ['geometry', 'geo']));
      if (geometry.isNotEmpty) {
        raw = _firstValue(geometry, const ['coordinates', 'points', 'path']);
      }
    }

    List<UserGeoPoint> points = const <UserGeoPoint>[];
    if (raw is List) {
      points = UserGeoPoint.listFromJson(raw);
    }

    return UserLineGeoData(coordinates: points, toleranceM: tolerance);
  }
}

// ---------------------------------------------------------------------------
// Landmark entities
// ---------------------------------------------------------------------------

class UserGeofence {
  const UserGeofence({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.color,
    required this.radius,
    required this.toleranceMeters,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.geodata,
  });

  final String id;
  final String name;
  final String description;
  final UserGeofenceType type;
  final String color;
  final double? radius;
  final double? toleranceMeters;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserGeofenceGeoData? geodata;

  factory UserGeofence.fromJson(dynamic json) {
    final source = _unwrapSingle(json, const [
      'geofence',
      'data',
      'item',
      'record',
    ]);
    final geo = UserGeofenceGeoData.tryParse(
      _firstValue(source, const ['geodata', 'geoData', 'geometry', 'shape']),
    );
    final type = UserGeofenceTypeX.tryParse(
          _firstValue(source, const ['type', 'shapeType', 'geofenceType']),
        ) ??
        _typeFromGeoData(geo) ??
        UserGeofenceType.polygon;

    return UserGeofence(
      id: _firstId(source, const ['id', '_id', 'geofenceId']) ?? '',
      name: _firstString(source, const ['name', 'title', 'label']) ?? '',
      description:
          _firstString(source, const ['description', 'desc', 'notes']) ?? '',
      type: type,
      color: _firstString(source, const ['color', 'colour', 'hexColor']) ?? '',
      radius: _toDouble(
        _firstValue(source, const ['radius', 'radiusM', 'radius_m']),
      ),
      toleranceMeters: _toDouble(
        _firstValue(
          source,
          const ['toleranceMeters', 'tolerance_m', 'toleranceM', 'tolerance'],
        ),
      ),
      isActive: _toBool(
            _firstValue(
              source,
              const ['isActive', 'is_active', 'active', 'status'],
            ),
          ) ??
          true,
      createdAt:
          _parseDate(_firstValue(source, const ['createdAt', 'created_at'])),
      updatedAt:
          _parseDate(_firstValue(source, const ['updatedAt', 'updated_at'])),
      geodata: geo,
    );
  }

  static List<UserGeofence> listFromJson(dynamic json) {
    final list = _extractList(
      json,
      const ['geofences', 'data', 'items', 'rows', 'records', 'list'],
    );
    return list.map(UserGeofence.fromJson).toList(growable: false);
  }
}

class UserPoi {
  const UserPoi({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.color,
    required this.iconSlug,
    required this.toleranceMeters,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.coordinates,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String color;
  final String iconSlug;
  final double? toleranceMeters;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserGeoPoint? coordinates;

  factory UserPoi.fromJson(dynamic json) {
    final source = _unwrapSingle(json, const [
      'poi',
      'data',
      'item',
      'record',
    ]);

    UserGeoPoint? coords = UserGeoPoint.tryParse(
      _firstValue(
        source,
        const ['coordinates', 'location', 'point', 'position', 'latlng'],
      ),
    );

    // Some backends store lat/lon at the top level.
    coords ??= UserGeoPoint.tryParse(source);

    // GeoJSON Point geometry: { type:'Point', coordinates:[lon,lat] }.
    if (coords == null) {
      final geometry = _asMap(
        _firstValue(source, const ['geometry', 'geodata', 'geoData', 'shape']),
      );
      if (geometry.isNotEmpty) {
        coords = UserGeoPoint.tryParse(
          _firstValue(geometry, const ['coordinates', 'point', 'center']),
        );
      }
    }

    return UserPoi(
      id: _firstId(source, const ['id', '_id', 'poiId']) ?? '',
      name: _firstString(source, const ['name', 'title', 'label']) ?? '',
      description:
          _firstString(source, const ['description', 'desc', 'notes']) ?? '',
      category: _firstString(source, const ['category', 'type', 'group']) ?? '',
      color: _firstString(source, const ['color', 'colour', 'hexColor']) ?? '',
      iconSlug: _firstString(
            source,
            const ['icon', 'iconSlug', 'icon_slug', 'iconName'],
          ) ??
          '',
      toleranceMeters: _toDouble(
        _firstValue(
          source,
          const ['toleranceMeters', 'tolerance_m', 'toleranceM', 'tolerance'],
        ),
      ),
      isActive: _toBool(
            _firstValue(
              source,
              const ['isActive', 'is_active', 'active', 'status'],
            ),
          ) ??
          true,
      createdAt:
          _parseDate(_firstValue(source, const ['createdAt', 'created_at'])),
      updatedAt:
          _parseDate(_firstValue(source, const ['updatedAt', 'updated_at'])),
      coordinates: coords,
    );
  }

  static List<UserPoi> listFromJson(dynamic json) {
    final list = _extractList(
      json,
      const ['pois', 'data', 'items', 'rows', 'records', 'list'],
    );
    return list.map(UserPoi.fromJson).toList(growable: false);
  }
}

class UserRouteLandmark {
  const UserRouteLandmark({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.toleranceMeters,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.geodata,
  });

  final String id;
  final String name;
  final String description;
  final String color;
  final double? toleranceMeters;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserLineGeoData? geodata;

  factory UserRouteLandmark.fromJson(dynamic json) {
    final source = _unwrapSingle(json, const [
      'route',
      'data',
      'item',
      'record',
    ]);

    UserGeofenceGeoData? geo = UserGeofenceGeoData.tryParse(
      _firstValue(source, const ['geodata', 'geoData', 'geometry', 'shape']),
    );
    UserLineGeoData? line;
    if (geo is UserLineGeoData) {
      line = geo;
    } else if (geo != null) {
      // Route is always a line; if a different shape leaked through,
      // attempt to extract coordinates anyway.
      final raw = _firstValue(
        _asMap(
          _firstValue(
              source, const ['geodata', 'geoData', 'geometry', 'shape']),
        ),
        const ['coordinates', 'points', 'path'],
      );
      if (raw is List) {
        line = UserLineGeoData(
          coordinates: UserGeoPoint.listFromJson(raw),
        );
      }
    }

    return UserRouteLandmark(
      id: _firstId(source, const ['id', '_id', 'routeId']) ?? '',
      name: _firstString(source, const ['name', 'title', 'label']) ?? '',
      description:
          _firstString(source, const ['description', 'desc', 'notes']) ?? '',
      color: _firstString(source, const ['color', 'colour', 'hexColor']) ?? '',
      toleranceMeters: _toDouble(
        _firstValue(
          source,
          const ['toleranceMeters', 'tolerance_m', 'toleranceM', 'tolerance'],
        ),
      ),
      isActive: _toBool(
            _firstValue(
              source,
              const ['isActive', 'is_active', 'active', 'status'],
            ),
          ) ??
          true,
      createdAt:
          _parseDate(_firstValue(source, const ['createdAt', 'created_at'])),
      updatedAt:
          _parseDate(_firstValue(source, const ['updatedAt', 'updated_at'])),
      geodata: line,
    );
  }

  static List<UserRouteLandmark> listFromJson(dynamic json) {
    final list = _extractList(
      json,
      const ['routes', 'data', 'items', 'rows', 'records', 'list'],
    );
    return list.map(UserRouteLandmark.fromJson).toList(growable: false);
  }
}

UserGeofenceType? _typeFromGeoData(UserGeofenceGeoData? geo) {
  if (geo is UserCircleGeoData) return UserGeofenceType.circle;
  if (geo is UserPolygonGeoData) return UserGeofenceType.polygon;
  if (geo is UserLineGeoData) return UserGeofenceType.line;
  return null;
}

// ---------------------------------------------------------------------------
// Request models
// ---------------------------------------------------------------------------

class CreateUserGeofenceRequest {
  const CreateUserGeofenceRequest({
    required this.name,
    required this.geodata,
    this.description,
    this.color,
    this.toleranceMeters,
    this.isActive = true,
  });

  final String name;
  final UserGeofenceGeoData geodata;
  final String? description;
  final String? color;
  final double? toleranceMeters;
  final bool isActive;

  /// Throws [ArgumentError] if the payload is structurally invalid.
  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Geofence name is required');
    }
    final geo = geodata;
    if (geo is UserCircleGeoData && geo.radiusM <= 0) {
      throw ArgumentError('Circle geofence requires radius > 0');
    }
    if (geo is UserPolygonGeoData && !geo.isValid) {
      throw ArgumentError('Polygon geofence requires at least 3 unique points');
    }
    if (geo is UserLineGeoData && geo.coordinates.length < 2) {
      throw ArgumentError('Line geofence requires at least 2 points');
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return <String, dynamic>{
      'name': name.trim(),
      if (description != null) 'description': description!.trim(),
      if (color != null && color!.trim().isNotEmpty) 'color': color!.trim(),
      if (toleranceMeters != null) 'toleranceMeters': toleranceMeters,
      'isActive': isActive,
      'type': _typeFromGeoData(geodata)?.apiValue ?? geodata.kind,
      'geodata': geodata.toJson(),
    };
  }
}

class UpdateUserGeofenceRequest {
  const UpdateUserGeofenceRequest({
    this.name,
    this.description,
    this.color,
    this.toleranceMeters,
    this.isActive,
    this.geodata,
  });

  final String? name;
  final String? description;
  final String? color;
  final double? toleranceMeters;
  final bool? isActive;
  final UserGeofenceGeoData? geodata;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name!.trim();
    if (description != null) payload['description'] = description!.trim();
    if (color != null) payload['color'] = color!.trim();
    if (toleranceMeters != null) payload['toleranceMeters'] = toleranceMeters;
    if (isActive != null) payload['isActive'] = isActive;
    final geo = geodata;
    if (geo != null) {
      payload['type'] = _typeFromGeoData(geo)?.apiValue ?? geo.kind;
      payload['geodata'] = geo.toJson();
    }
    return payload;
  }
}

class CreateUserPoiRequest {
  const CreateUserPoiRequest({
    required this.name,
    required this.coordinates,
    this.description,
    this.category,
    this.color,
    this.iconSlug,
    this.toleranceMeters,
    this.isActive = true,
  });

  final String name;
  final UserGeoPoint coordinates;
  final String? description;
  final String? category;
  final String? color;
  final String? iconSlug;
  final double? toleranceMeters;
  final bool isActive;

  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('POI name is required');
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return <String, dynamic>{
      'name': name.trim(),
      if (description != null) 'description': description!.trim(),
      if (category != null && category!.trim().isNotEmpty)
        'category': category!.trim(),
      if (color != null && color!.trim().isNotEmpty) 'color': color!.trim(),
      if (iconSlug != null && iconSlug!.trim().isNotEmpty)
        'icon': iconSlug!.trim(),
      if (toleranceMeters != null) 'toleranceMeters': toleranceMeters,
      'isActive': isActive,
      'coordinates': <String, double>{
        'lat': coordinates.lat,
        'lon': coordinates.lon,
      },
    };
  }
}

class UpdateUserPoiRequest {
  const UpdateUserPoiRequest({
    this.name,
    this.description,
    this.category,
    this.color,
    this.iconSlug,
    this.toleranceMeters,
    this.isActive,
    this.coordinates,
  });

  final String? name;
  final String? description;
  final String? category;
  final String? color;
  final String? iconSlug;
  final double? toleranceMeters;
  final bool? isActive;
  final UserGeoPoint? coordinates;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name!.trim();
    if (description != null) payload['description'] = description!.trim();
    if (category != null) payload['category'] = category!.trim();
    if (color != null) payload['color'] = color!.trim();
    if (iconSlug != null) payload['icon'] = iconSlug!.trim();
    if (toleranceMeters != null) payload['toleranceMeters'] = toleranceMeters;
    if (isActive != null) payload['isActive'] = isActive;
    if (coordinates != null) {
      payload['coordinates'] = <String, double>{
        'lat': coordinates!.lat,
        'lon': coordinates!.lon,
      };
    }
    return payload;
  }
}

class CreateUserRouteRequest {
  const CreateUserRouteRequest({
    required this.name,
    required this.geodata,
    this.description,
    this.color,
    this.toleranceMeters,
    this.isActive = true,
  });

  final String name;
  final UserLineGeoData geodata;
  final String? description;
  final String? color;
  final double? toleranceMeters;
  final bool isActive;

  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Route name is required');
    }
    if (geodata.coordinates.length < 2) {
      throw ArgumentError('Route requires at least 2 points');
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return <String, dynamic>{
      'name': name.trim(),
      if (description != null) 'description': description!.trim(),
      if (color != null && color!.trim().isNotEmpty) 'color': color!.trim(),
      if (toleranceMeters != null) 'toleranceMeters': toleranceMeters,
      'isActive': isActive,
      'geodata': <String, dynamic>{
        'kind': 'LINE',
        'geometry': <String, dynamic>{
          'type': 'LineString',
          'coordinates': geodata.coordinates
              .map((p) => p.toLonLat())
              .toList(growable: false),
        },
        if (toleranceMeters != null) 'toleranceM': toleranceMeters,
      },
    };
  }
}

class UpdateUserRouteRequest {
  const UpdateUserRouteRequest({
    this.name,
    this.description,
    this.color,
    this.toleranceMeters,
    this.isActive,
    this.geodata,
  });

  final String? name;
  final String? description;
  final String? color;
  final double? toleranceMeters;
  final bool? isActive;
  final UserLineGeoData? geodata;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name!.trim();
    if (description != null) payload['description'] = description!.trim();
    if (color != null) payload['color'] = color!.trim();
    if (toleranceMeters != null) payload['toleranceMeters'] = toleranceMeters;
    if (isActive != null) payload['isActive'] = isActive;
    if (geodata != null) {
      payload['geodata'] = <String, dynamic>{
        'kind': 'LINE',
        'geometry': <String, dynamic>{
          'type': 'LineString',
          'coordinates': geodata!.coordinates
              .map((p) => p.toLonLat())
              .toList(growable: false),
        },
        if (toleranceMeters != null) 'toleranceM': toleranceMeters,
      };
    }
    return payload;
  }
}

// ---------------------------------------------------------------------------
// Bulk job models
// ---------------------------------------------------------------------------

enum UserLandmarkBulkJobStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
  unknown,
}

extension UserLandmarkBulkJobStatusX on UserLandmarkBulkJobStatus {
  String get label {
    switch (this) {
      case UserLandmarkBulkJobStatus.pending:
        return 'Pending';
      case UserLandmarkBulkJobStatus.running:
        return 'Running';
      case UserLandmarkBulkJobStatus.completed:
        return 'Completed';
      case UserLandmarkBulkJobStatus.failed:
        return 'Failed';
      case UserLandmarkBulkJobStatus.cancelled:
        return 'Cancelled';
      case UserLandmarkBulkJobStatus.unknown:
        return 'Unknown';
    }
  }

  static UserLandmarkBulkJobStatus parse(dynamic value) {
    switch (_normalizeEnumValue(value)) {
      case 'PENDING':
      case 'QUEUED':
      case 'WAITING':
        return UserLandmarkBulkJobStatus.pending;
      case 'RUNNING':
      case 'IN_PROGRESS':
      case 'PROCESSING':
        return UserLandmarkBulkJobStatus.running;
      case 'COMPLETED':
      case 'SUCCESS':
      case 'DONE':
        return UserLandmarkBulkJobStatus.completed;
      case 'FAILED':
      case 'ERROR':
        return UserLandmarkBulkJobStatus.failed;
      case 'CANCELLED':
      case 'CANCELED':
      case 'ABORTED':
        return UserLandmarkBulkJobStatus.cancelled;
      default:
        return UserLandmarkBulkJobStatus.unknown;
    }
  }
}

class UserLandmarkBulkJobRow {
  const UserLandmarkBulkJobRow({
    required this.index,
    required this.name,
    required this.entityType,
    required this.errorMessage,
    required this.raw,
  });

  final int? index;
  final String name;
  final UserLandmarkEntityType? entityType;
  final String errorMessage;
  final Map<String, dynamic> raw;

  factory UserLandmarkBulkJobRow.fromJson(dynamic json) {
    final source = _asMap(json);
    final entityRaw = _normalizeEnumValue(
      _firstValue(
        source,
        const ['entity', 'entityType', 'kind', 'type'],
      ),
    );
    UserLandmarkEntityType? entity;
    switch (entityRaw) {
      case 'GEOFENCE':
        entity = UserLandmarkEntityType.geofence;
        break;
      case 'POI':
        entity = UserLandmarkEntityType.poi;
        break;
      case 'ROUTE':
        entity = UserLandmarkEntityType.route;
        break;
    }

    return UserLandmarkBulkJobRow(
      index: _firstInt(source, const ['index', 'row', 'rowIndex']),
      name: _firstString(source, const ['name', 'title']) ?? '',
      entityType: entity,
      errorMessage:
          _firstString(source, const ['error', 'errorMessage', 'message']) ??
              '',
      raw: source,
    );
  }
}

class UserLandmarkBulkJob {
  const UserLandmarkBulkJob({
    required this.id,
    required this.status,
    required this.entityType,
    required this.total,
    required this.processed,
    required this.succeeded,
    required this.failed,
    required this.createdAt,
    required this.updatedAt,
    required this.errorMessage,
    required this.failedRows,
  });

  final String id;
  final UserLandmarkBulkJobStatus status;
  final UserLandmarkEntityType? entityType;
  final int total;
  final int processed;
  final int succeeded;
  final int failed;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String errorMessage;
  final List<UserLandmarkBulkJobRow> failedRows;

  bool get isTerminal =>
      status == UserLandmarkBulkJobStatus.completed ||
      status == UserLandmarkBulkJobStatus.failed ||
      status == UserLandmarkBulkJobStatus.cancelled;

  double get progress {
    if (total <= 0) return 0;
    return (processed / total).clamp(0, 1).toDouble();
  }

  factory UserLandmarkBulkJob.fromJson(dynamic json) {
    final source = _unwrapSingle(json, const [
      'job',
      'bulkJob',
      'data',
      'item',
      'record',
    ]);

    UserLandmarkEntityType? entity;
    switch (_normalizeEnumValue(
      _firstValue(source, const ['entity', 'entityType', 'kind', 'type']),
    )) {
      case 'GEOFENCE':
        entity = UserLandmarkEntityType.geofence;
        break;
      case 'POI':
        entity = UserLandmarkEntityType.poi;
        break;
      case 'ROUTE':
        entity = UserLandmarkEntityType.route;
        break;
    }

    final failedRowsRaw =
        _firstValue(source, const ['failedRows', 'errors', 'failures']);
    final failedRows = (failedRowsRaw is List)
        ? failedRowsRaw
            .map(UserLandmarkBulkJobRow.fromJson)
            .toList(growable: false)
        : const <UserLandmarkBulkJobRow>[];

    return UserLandmarkBulkJob(
      id: _firstId(source, const ['id', '_id', 'jobId']) ?? '',
      status: UserLandmarkBulkJobStatusX.parse(
        _firstValue(source, const ['status', 'state']),
      ),
      entityType: entity,
      total: _firstInt(source, const ['total', 'totalRows', 'count']) ?? 0,
      processed:
          _firstInt(source, const ['processed', 'processedRows', 'done']) ?? 0,
      succeeded: _firstInt(
            source,
            const ['succeeded', 'successCount', 'success'],
          ) ??
          0,
      failed: _firstInt(
            source,
            const ['failed', 'failedCount', 'errorsCount'],
          ) ??
          0,
      createdAt:
          _parseDate(_firstValue(source, const ['createdAt', 'created_at'])),
      updatedAt:
          _parseDate(_firstValue(source, const ['updatedAt', 'updated_at'])),
      errorMessage:
          _firstString(source, const ['error', 'errorMessage', 'message']) ??
              '',
      failedRows: failedRows,
    );
  }
}

class CreateUserLandmarkBulkJobRequest {
  const CreateUserLandmarkBulkJobRequest({
    required this.entityType,
    required this.rows,
  });

  final UserLandmarkEntityType entityType;
  final List<Map<String, dynamic>> rows;

  void validate() {
    if (rows.isEmpty) {
      throw ArgumentError('Bulk job requires at least one row');
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return <String, dynamic>{
      'entity': entityType.apiValue,
      'rows': rows,
    };
  }
}

// ---------------------------------------------------------------------------
// Shared parsing helpers (private)
// ---------------------------------------------------------------------------

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (source.containsKey(key) && source[key] != null) {
      return source[key];
    }
  }
  return null;
}

String? _firstString(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value == null) return null;
  if (value is String) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return null;
}

String? _firstId(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value == null) return null;
  if (value is String) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
  if (value is num) {
    if (value is int) return value.toString();
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }
  return value.toString();
}

int? _firstInt(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty) return null;
    final parsed = num.tryParse(normalized);
    return parsed?.toInt();
  }
  return null;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
  if (value is bool) return value ? 1 : 0;
  return null;
}

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    switch (normalized) {
      case 'true':
      case '1':
      case 'yes':
      case 'y':
      case 'active':
      case 'enabled':
      case 'on':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'n':
      case 'inactive':
      case 'disabled':
      case 'off':
        return false;
    }
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is num) {
    final raw = value.toInt();
    if (raw <= 0) return null;
    final millis = raw > 9999999999 ? raw : raw * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == '-') return null;
    return DateTime.tryParse(normalized);
  }
  return null;
}

String _normalizeEnumValue(dynamic value) {
  if (value == null) return '';
  final raw = value is String ? value : value.toString();
  return raw.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
}

/// Unwraps an envelope/wrapper around a single object response.
Map<String, dynamic> _unwrapSingle(dynamic json, List<String> wrapperKeys) {
  Map<String, dynamic> source = _asMap(json);
  if (source.isEmpty) return const <String, dynamic>{};

  for (var depth = 0; depth < 4; depth++) {
    var unwrapped = false;
    for (final key in wrapperKeys) {
      final nested = source[key];
      if (nested is Map) {
        final nestedMap = _asMap(nested);
        if (nestedMap.isNotEmpty) {
          source = nestedMap;
          unwrapped = true;
          break;
        }
      }
    }
    if (!unwrapped) break;
  }

  return source;
}

/// Extracts a list payload from any of the documented wrapper keys, or
/// returns the raw array if the response is already a list.
List<dynamic> _extractList(dynamic json, List<String> wrapperKeys) {
  if (json is List) return json;
  final source = _asMap(json);
  if (source.isEmpty) return const <dynamic>[];

  for (final key in wrapperKeys) {
    final value = source[key];
    if (value is List) return value;
  }

  // Recurse into a single nested wrapper (e.g. data: { items: [...] }).
  for (final nestedKey in const ['data', 'result', 'payload']) {
    final nested = source[nestedKey];
    if (nested != null) {
      if (nested is List) return nested;
      if (nested is Map) {
        return _extractList(nested, wrapperKeys);
      }
    }
  }

  return const <dynamic>[];
}
