// Lightweight RFC4180-tolerant CSV parser plus entity-aware row validation
// for the Landmark Studio bulk-import flow.
//
// Why a custom parser: the project does not pull in the `csv` package and
// the import surface area is small. This file stays dependency-free.

import '../models/user_landmark_model.dart';

class UserLandmarkCsvParser {
  const UserLandmarkCsvParser._();

  /// Splits CSV text into a list of rows. Honours quoted fields, escaped
  /// quotes (""), CRLF/LF endings, and trims trailing empty trailing rows.
  static List<List<String>> parseRaw(String input) {
    final rows = <List<String>>[];
    final field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;

    void endField() {
      row.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      rows.add(row);
      row = <String>[];
    }

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          endField();
        } else if (char == '\r') {
          // Treat as start of a row terminator; consume optional LF next.
          if (i + 1 < input.length && input[i + 1] == '\n') i++;
          endRow();
        } else if (char == '\n') {
          endRow();
        } else {
          field.write(char);
        }
      }
    }

    if (field.isNotEmpty || row.isNotEmpty) {
      endRow();
    }

    while (rows.isNotEmpty && rows.last.every((cell) => cell.trim().isEmpty)) {
      rows.removeLast();
    }
    return rows;
  }

  /// Parses CSV into validated bulk-job rows for the given [entityType].
  static UserLandmarkCsvParseResult parseForEntity(
    String text,
    UserLandmarkEntityType entityType,
  ) {
    final raw = parseRaw(text);
    if (raw.isEmpty) {
      return const UserLandmarkCsvParseResult(
        validRows: <Map<String, dynamic>>[],
        invalidRows: <UserLandmarkCsvInvalidRow>[],
        header: <String>[],
      );
    }

    final header =
        raw.first.map((c) => c.trim().toLowerCase()).toList(growable: false);
    final required = _requiredColumns(entityType);
    final missing = required.where((c) => !header.contains(c)).toList();
    if (missing.isNotEmpty) {
      return UserLandmarkCsvParseResult(
        validRows: const <Map<String, dynamic>>[],
        invalidRows: <UserLandmarkCsvInvalidRow>[
          UserLandmarkCsvInvalidRow(
            rowNumber: 1,
            rawLine: raw.first.join(','),
            error: 'Missing required columns: ${missing.join(', ')}.',
          ),
        ],
        header: header,
      );
    }

    final valid = <Map<String, dynamic>>[];
    final invalid = <UserLandmarkCsvInvalidRow>[];

    for (var i = 1; i < raw.length; i++) {
      final row = raw[i];
      if (row.every((c) => c.trim().isEmpty)) continue;
      final cells = <String, String>{};
      for (var j = 0; j < header.length; j++) {
        cells[header[j]] = j < row.length ? row[j].trim() : '';
      }
      try {
        valid.add(_buildRow(entityType, cells));
      } on FormatException catch (e) {
        invalid.add(
          UserLandmarkCsvInvalidRow(
            rowNumber: i + 1,
            rawLine: row.join(','),
            error: e.message,
          ),
        );
      }
    }

    return UserLandmarkCsvParseResult(
      validRows: List<Map<String, dynamic>>.unmodifiable(valid),
      invalidRows: List<UserLandmarkCsvInvalidRow>.unmodifiable(invalid),
      header: header,
    );
  }

  // -------------------------------------------------------------------
  // Schema
  // -------------------------------------------------------------------

  static List<String> templateHeader(UserLandmarkEntityType type) {
    switch (type) {
      case UserLandmarkEntityType.geofence:
        return const <String>[
          'name',
          'type', // CIRCLE / POLYGON
          'color',
          'isActive',
          'toleranceMeters',
          'radiusMeters',
          'centerLat',
          'centerLon',
          'coordinates', // lon lat;lon lat;... for polygon
          'description',
        ];
      case UserLandmarkEntityType.poi:
        return const <String>[
          'name',
          'category',
          'icon',
          'color',
          'isActive',
          'toleranceMeters',
          'lat',
          'lon',
          'description',
        ];
      case UserLandmarkEntityType.route:
        return const <String>[
          'name',
          'color',
          'isActive',
          'toleranceMeters',
          'coordinates', // lon lat;lon lat;...
          'description',
        ];
    }
  }

  static List<String> _requiredColumns(UserLandmarkEntityType type) {
    switch (type) {
      case UserLandmarkEntityType.geofence:
        return const <String>['name', 'type'];
      case UserLandmarkEntityType.poi:
        return const <String>['name', 'lat', 'lon'];
      case UserLandmarkEntityType.route:
        return const <String>['name', 'coordinates'];
    }
  }

  static Map<String, dynamic> _buildRow(
    UserLandmarkEntityType entityType,
    Map<String, String> cells,
  ) {
    final name = cells['name']?.trim() ?? '';
    if (name.length < 2) {
      throw const FormatException('Name must be at least 2 characters.');
    }
    final color = cells['color']?.trim();
    if (color != null && color.isNotEmpty && !_isHexColor(color)) {
      throw const FormatException('Color must be a 6-digit hex value.');
    }
    final tolerance = _parseOptionalDouble(cells['tolerancemeters']);
    final isActive = _parseBool(cells['isactive']) ?? true;

    final row = <String, dynamic>{
      'name': name,
      if (color != null && color.isNotEmpty) 'color': color,
      'isActive': isActive,
      if (tolerance != null) 'toleranceMeters': tolerance,
      if ((cells['description'] ?? '').trim().isNotEmpty)
        'description': cells['description']!.trim(),
    };

    switch (entityType) {
      case UserLandmarkEntityType.geofence:
        final type =
            (cells['type'] ?? '').trim().toUpperCase().replaceAll(' ', '_');
        if (type != 'CIRCLE' && type != 'POLYGON') {
          throw const FormatException(
            'Geofence type must be CIRCLE or POLYGON.',
          );
        }
        if (type == 'CIRCLE') {
          final lat = _parseRequiredDouble(cells['centerlat'], 'centerLat');
          final lon = _parseRequiredDouble(cells['centerlon'], 'centerLon');
          final radius =
              _parseRequiredDouble(cells['radiusmeters'], 'radiusMeters');
          if (radius <= 0) {
            throw const FormatException(
              'Circle radiusMeters must be greater than 0.',
            );
          }
          _assertLatLon(lat, lon);
          row['geodata'] = <String, dynamic>{
            'type': 'CIRCLE',
            'center': <double>[lon, lat],
            'radius': radius,
          };
          row['radius'] = radius;
        } else {
          final pts = _parseCoordList(cells['coordinates']);
          if (pts.length < 3) {
            throw const FormatException(
              'Polygon coordinates need at least 3 points.',
            );
          }
          row['geodata'] = <String, dynamic>{
            'type': 'POLYGON',
            'coordinates': <List<List<double>>>[
              pts.map((p) => <double>[p[0], p[1]]).toList(growable: false),
            ],
          };
        }
        break;
      case UserLandmarkEntityType.poi:
        final lat = _parseRequiredDouble(cells['lat'], 'lat');
        final lon = _parseRequiredDouble(cells['lon'], 'lon');
        _assertLatLon(lat, lon);
        row['coordinates'] = <double>[lon, lat];
        final cat = (cells['category'] ?? '').trim();
        if (cat.isNotEmpty) row['category'] = cat;
        final icon = (cells['icon'] ?? '').trim();
        if (icon.isNotEmpty) row['icon'] = icon;
        break;
      case UserLandmarkEntityType.route:
        final pts = _parseCoordList(cells['coordinates']);
        if (pts.length < 2) {
          throw const FormatException(
            'Route coordinates need at least 2 points.',
          );
        }
        row['geodata'] = <String, dynamic>{
          'kind': 'LINE',
          'geometry': <String, dynamic>{
            'type': 'LineString',
            'coordinates':
                pts.map((p) => <double>[p[0], p[1]]).toList(growable: false),
          },
          if (tolerance != null) 'toleranceM': tolerance,
        };
        break;
    }

    return row;
  }

  // -------------------------------------------------------------------
  // Field parsers
  // -------------------------------------------------------------------

  static double _parseRequiredDouble(String? raw, String field) {
    final v = _parseOptionalDouble(raw);
    if (v == null) {
      throw FormatException('$field is required and must be numeric.');
    }
    return v;
  }

  static double? _parseOptionalDouble(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    final parsed = double.tryParse(t);
    if (parsed == null || parsed.isNaN) return null;
    return parsed;
  }

  static bool? _parseBool(String? raw) {
    if (raw == null) return null;
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return null;
    if (t == 'true' || t == '1' || t == 'yes' || t == 'y') return true;
    if (t == 'false' || t == '0' || t == 'no' || t == 'n') return false;
    return null;
  }

  // Coordinates column shape: "lon lat;lon lat;..." or "lon,lat|lon,lat".
  // Returns a list of [lon, lat] pairs.
  static List<List<double>> _parseCoordList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      throw const FormatException('coordinates column is empty.');
    }
    final pairs = raw
        .split(RegExp(r'[;|]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    final out = <List<double>>[];
    for (final pair in pairs) {
      final parts =
          pair.split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();
      if (parts.length < 2) {
        throw FormatException('Invalid coordinate pair "$pair".');
      }
      final lon = double.tryParse(parts[0]);
      final lat = double.tryParse(parts[1]);
      if (lon == null || lat == null || lon.isNaN || lat.isNaN) {
        throw FormatException('Invalid coordinate pair "$pair".');
      }
      _assertLatLon(lat, lon);
      out.add(<double>[lon, lat]);
    }
    return out;
  }

  static void _assertLatLon(double lat, double lon) {
    if (lat < -90 || lat > 90) {
      throw FormatException('Latitude $lat is out of range.');
    }
    if (lon < -180 || lon > 180) {
      throw FormatException('Longitude $lon is out of range.');
    }
  }

  static bool _isHexColor(String value) {
    final cleaned = value.replaceAll('#', '').trim();
    if (cleaned.length != 6) return false;
    return int.tryParse(cleaned, radix: 16) != null;
  }
}

class UserLandmarkCsvParseResult {
  const UserLandmarkCsvParseResult({
    required this.validRows,
    required this.invalidRows,
    required this.header,
  });

  final List<Map<String, dynamic>> validRows;
  final List<UserLandmarkCsvInvalidRow> invalidRows;
  final List<String> header;

  bool get isEmpty => validRows.isEmpty && invalidRows.isEmpty;
  bool get hasIssues => invalidRows.isNotEmpty;
}

class UserLandmarkCsvInvalidRow {
  const UserLandmarkCsvInvalidRow({
    required this.rowNumber,
    required this.rawLine,
    required this.error,
  });

  final int rowNumber;
  final String rawLine;
  final String error;
}
