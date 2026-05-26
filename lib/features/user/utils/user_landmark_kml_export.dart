// Client-side KML generation for Landmark Studio exports.
//
// Mirrors the shape produced by the web app's KML utility so that exported
// files round-trip with the same toolchain. No backend coordination is
// required — input is the current loaded list from each controller.

import 'dart:math' as math;

import '../models/user_landmark_model.dart';

class UserLandmarkKmlExport {
  const UserLandmarkKmlExport._();

  static String forGeofences(
    List<UserGeofence> items, {
    String documentName = 'OpenVTS Geofences',
  }) {
    final buffer = _openDocument(documentName);
    for (final g in items) {
      _writeGeofencePlacemark(buffer, g);
    }
    _closeDocument(buffer);
    return buffer.toString();
  }

  static String forPois(
    List<UserPoi> items, {
    String documentName = 'OpenVTS POIs',
  }) {
    final buffer = _openDocument(documentName);
    for (final p in items) {
      _writePoiPlacemark(buffer, p);
    }
    _closeDocument(buffer);
    return buffer.toString();
  }

  static String forRoutes(
    List<UserRouteLandmark> items, {
    String documentName = 'OpenVTS Routes',
  }) {
    final buffer = _openDocument(documentName);
    for (final r in items) {
      _writeRoutePlacemark(buffer, r);
    }
    _closeDocument(buffer);
    return buffer.toString();
  }

  // -------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------

  static StringBuffer _openDocument(String name) {
    return StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2">')
      ..writeln('  <Document>')
      ..write('    <name>')
      ..write(_xml(name))
      ..writeln('</name>');
  }

  static void _closeDocument(StringBuffer buffer) {
    buffer
      ..writeln('  </Document>')
      ..writeln('</kml>');
  }

  static void _writeGeofencePlacemark(StringBuffer buf, UserGeofence g) {
    final styleId = _styleId('gf', g.id);
    _writeLineStyle(buf, styleId, g.color, lineWidth: 2);

    buf.writeln('    <Placemark>');
    buf.write('      <name>');
    buf.write(_xml(g.name));
    buf.writeln('</name>');
    _writeDescription(buf, g.description);
    buf.writeln('      <styleUrl>#$styleId</styleUrl>');
    _writeExtendedData(buf, <String, String?>{
      'entity': 'GEOFENCE',
      'id': g.id,
      'type': g.type.name,
      'isActive': g.isActive.toString(),
      'color': g.color,
      'toleranceMeters': g.toleranceMeters?.toString(),
      'radiusMeters': g.radius?.toString(),
    });

    final geo = g.geodata;
    if (geo is UserPolygonGeoData) {
      _writePolygon(buf, geo.coordinates);
    } else if (geo is UserCircleGeoData) {
      // KML has no native circle; emit a polygon approximation so the
      // exported file renders identically in Google Earth.
      final ring = _circleRing(
        geo.center.lat,
        geo.center.lon,
        geo.radiusM,
      );
      _writePolygon(buf, ring);
    } else if (geo is UserLineGeoData) {
      _writeLineString(buf, geo.coordinates);
    }

    buf.writeln('    </Placemark>');
  }

  static void _writePoiPlacemark(StringBuffer buf, UserPoi p) {
    final styleId = _styleId('poi', p.id);
    _writeIconStyle(buf, styleId, p.color);

    buf.writeln('    <Placemark>');
    buf.write('      <name>');
    buf.write(_xml(p.name));
    buf.writeln('</name>');
    _writeDescription(buf, p.description);
    buf.writeln('      <styleUrl>#$styleId</styleUrl>');
    _writeExtendedData(buf, <String, String?>{
      'entity': 'POI',
      'id': p.id,
      'category': p.category,
      'icon': p.iconSlug,
      'isActive': p.isActive.toString(),
      'color': p.color,
      'toleranceMeters': p.toleranceMeters?.toString(),
    });

    final c = p.coordinates;
    if (c != null) {
      buf
        ..writeln('      <Point>')
        ..write('        <coordinates>')
        ..write(_coord(c.lon, c.lat))
        ..writeln('</coordinates>')
        ..writeln('      </Point>');
    }
    buf.writeln('    </Placemark>');
  }

  static void _writeRoutePlacemark(StringBuffer buf, UserRouteLandmark r) {
    final styleId = _styleId('rt', r.id);
    _writeLineStyle(buf, styleId, r.color, lineWidth: 3);

    buf.writeln('    <Placemark>');
    buf.write('      <name>');
    buf.write(_xml(r.name));
    buf.writeln('</name>');
    _writeDescription(buf, r.description);
    buf.writeln('      <styleUrl>#$styleId</styleUrl>');
    _writeExtendedData(buf, <String, String?>{
      'entity': 'ROUTE',
      'id': r.id,
      'isActive': r.isActive.toString(),
      'color': r.color,
      'toleranceMeters': r.toleranceMeters?.toString(),
    });

    final geo = r.geodata;
    if (geo != null && geo.coordinates.length >= 2) {
      _writeLineString(buf, geo.coordinates);
    }
    buf.writeln('    </Placemark>');
  }

  // ---- Geometry helpers -------------------------------------------------

  static void _writePolygon(StringBuffer buf, List<UserGeoPoint> ring) {
    if (ring.isEmpty) return;
    final closed = <UserGeoPoint>[...ring];
    if (!closed.first.isCloseTo(closed.last)) {
      closed.add(closed.first);
    }
    buf
      ..writeln('      <Polygon>')
      ..writeln('        <outerBoundaryIs>')
      ..writeln('          <LinearRing>')
      ..write('            <coordinates>');
    for (var i = 0; i < closed.length; i++) {
      buf.write(_coord(closed[i].lon, closed[i].lat));
      if (i != closed.length - 1) buf.write(' ');
    }
    buf
      ..writeln('</coordinates>')
      ..writeln('          </LinearRing>')
      ..writeln('        </outerBoundaryIs>')
      ..writeln('      </Polygon>');
  }

  static void _writeLineString(StringBuffer buf, List<UserGeoPoint> pts) {
    if (pts.isEmpty) return;
    buf
      ..writeln('      <LineString>')
      ..writeln('        <tessellate>1</tessellate>')
      ..write('        <coordinates>');
    for (var i = 0; i < pts.length; i++) {
      buf.write(_coord(pts[i].lon, pts[i].lat));
      if (i != pts.length - 1) buf.write(' ');
    }
    buf
      ..writeln('</coordinates>')
      ..writeln('      </LineString>');
  }

  // Approximate a circle as a 64-vertex polygon ring using equirectangular
  // small-angle math. Accurate enough for visualisation in KML viewers.
  static List<UserGeoPoint> _circleRing(
    double lat,
    double lon,
    double radiusM, {
    int segments = 64,
  }) {
    if (radiusM <= 0) return <UserGeoPoint>[UserGeoPoint(lat: lat, lon: lon)];
    const earthM = 6378137.0;
    final latRad = lat * (3.141592653589793 / 180.0);
    final dLat = (radiusM / earthM) * (180.0 / 3.141592653589793);
    final cosLat = _cos(latRad);
    final dLon = cosLat.abs() < 1e-12
        ? 0.0
        : (radiusM / (earthM * cosLat)) * (180.0 / 3.141592653589793);
    final out = <UserGeoPoint>[];
    for (var i = 0; i < segments; i++) {
      final theta = (i / segments) * 2 * 3.141592653589793;
      out.add(
        UserGeoPoint(
          lat: lat + dLat * _sin(theta),
          lon: lon + dLon * _cos(theta),
        ),
      );
    }
    return out;
  }

  // ---- Style helpers ---------------------------------------------------

  static void _writeLineStyle(
    StringBuffer buf,
    String id,
    String hex, {
    required int lineWidth,
  }) {
    final kml = _hexToKmlColor(hex);
    buf
      ..writeln('    <Style id="$id">')
      ..writeln('      <LineStyle>')
      ..writeln('        <color>$kml</color>')
      ..writeln('        <width>$lineWidth</width>')
      ..writeln('      </LineStyle>')
      ..writeln('      <PolyStyle>')
      ..writeln('        <color>${_withAlpha(kml, '66')}</color>')
      ..writeln('      </PolyStyle>')
      ..writeln('    </Style>');
  }

  static void _writeIconStyle(StringBuffer buf, String id, String hex) {
    final kml = _hexToKmlColor(hex);
    buf
      ..writeln('    <Style id="$id">')
      ..writeln('      <IconStyle>')
      ..writeln('        <color>$kml</color>')
      ..writeln('        <scale>1.0</scale>')
      ..writeln('        <Icon>')
      ..writeln('          <href>https://maps.google.com/'
          'mapfiles/kml/shapes/placemark_circle.png</href>')
      ..writeln('        </Icon>')
      ..writeln('      </IconStyle>')
      ..writeln('    </Style>');
  }

  static void _writeDescription(StringBuffer buf, String description) {
    if (description.trim().isEmpty) return;
    buf
      ..write('      <description>')
      ..write(_xml(description))
      ..writeln('</description>');
  }

  static void _writeExtendedData(
    StringBuffer buf,
    Map<String, String?> data,
  ) {
    final entries = data.entries
        .where((e) => e.value != null && e.value!.isNotEmpty)
        .toList(growable: false);
    if (entries.isEmpty) return;
    buf.writeln('      <ExtendedData>');
    for (final e in entries) {
      buf
        ..write('        <Data name="')
        ..write(_xml(e.key))
        ..write('"><value>')
        ..write(_xml(e.value!))
        ..writeln('</value></Data>');
    }
    buf.writeln('      </ExtendedData>');
  }

  // ---- Primitive helpers -----------------------------------------------

  static String _coord(double lon, double lat) =>
      '${lon.toStringAsFixed(6)},${lat.toStringAsFixed(6)},0';

  // KML colours are AABBGGRR (ARGB swapped + reversed).
  static String _hexToKmlColor(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6) return 'ff222222';
    final r = cleaned.substring(0, 2).toLowerCase();
    final g = cleaned.substring(2, 4).toLowerCase();
    final b = cleaned.substring(4, 6).toLowerCase();
    return 'ff$b$g$r';
  }

  static String _withAlpha(String kmlColor, String alphaHex) {
    if (kmlColor.length != 8) return kmlColor;
    return '$alphaHex${kmlColor.substring(2)}';
  }

  static String _styleId(String prefix, String id) {
    final safe = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${prefix}_${safe.isEmpty ? 'anon' : safe}';
  }

  static String _xml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static double _sin(double x) => math.sin(x);
  static double _cos(double x) => math.cos(x);
}
