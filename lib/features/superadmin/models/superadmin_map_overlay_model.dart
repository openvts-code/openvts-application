import 'package:latlong2/latlong.dart';

enum SuperadminMapGeofenceType { polygon, circle }

class SuperadminMapGeofence {
  const SuperadminMapGeofence({
    required this.id,
    required this.name,
    required this.type,
    required this.points,
    this.center,
    this.radiusMeters,
  });

  final String id;
  final String name;
  final SuperadminMapGeofenceType type;
  final List<LatLng> points;
  final LatLng? center;
  final double? radiusMeters;

  bool get isCircle => type == SuperadminMapGeofenceType.circle;

  bool get hasGeometry {
    if (isCircle) {
      return center != null && (radiusMeters ?? 0) > 0;
    }

    return points.length >= 3;
  }
}

class SuperadminMapPoi {
  const SuperadminMapPoi({
    required this.id,
    required this.name,
    required this.position,
    this.category,
  });

  final String id;
  final String name;
  final LatLng position;
  final String? category;
}

class SuperadminMapRoute {
  const SuperadminMapRoute({
    required this.id,
    required this.name,
    required this.path,
  });

  final String id;
  final String name;
  final List<LatLng> path;

  bool get hasPath => path.length >= 2;
}
