import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/api/api_client.dart';
import 'package:open_vts/features/superadmin/models/superadmin_map_overlay_model.dart';
import 'package:open_vts/features/superadmin/services/superadmin_map_overlay_service.dart';

void main() {
  group('SuperadminMapOverlayService', () {
    final service = SuperadminMapOverlayService(ApiClient(Dio()));

    test('parses polygon and circle geofences from mixed payloads', () {
      final geofences = service.parseGeofencesPayload(
        <String, dynamic>{
          'data': <String, dynamic>{
            'geofences': <Map<String, dynamic>>[
              <String, dynamic>{
                '_id': 'geo-1',
                'name': 'South Yard',
                'geometry': <String, dynamic>{
                  'type': 'Polygon',
                  'coordinates': <dynamic>[
                    <dynamic>[
                      <dynamic>[77.2000, 28.6100],
                      <dynamic>[77.2100, 28.6100],
                      <dynamic>[77.2100, 28.6200],
                      <dynamic>[77.2000, 28.6200],
                    ],
                  ],
                },
              },
              <String, dynamic>{
                'geofenceId': 'geo-2',
                'geofenceName': 'HQ Radius',
                'type': 'circle',
                'center': <String, dynamic>{
                  'lat': 28.6150,
                  'lng': 77.2150,
                },
                'radiusMeters': 250,
              },
            ],
          },
        },
      );

      expect(geofences, hasLength(2));
      expect(geofences.first.type, SuperadminMapGeofenceType.polygon);
      expect(geofences.first.points, hasLength(4));
      expect(geofences.first.points.first.latitude, closeTo(28.61, 0.0001));
      expect(geofences.last.isCircle, isTrue);
      expect(geofences.last.center, isNotNull);
      expect(geofences.last.radiusMeters, 250);
    });

    test('parses POIs from nested payloads and geojson coordinates', () {
      final pois = service.parsePoisPayload(
        <String, dynamic>{
          'data': <String, dynamic>{
            'pois': <Map<String, dynamic>>[
              <String, dynamic>{
                '_id': 'poi-1',
                'title': 'Depot',
                'category': 'Yard',
                'geometry': <String, dynamic>{
                  'type': 'Point',
                  'coordinates': <dynamic>[77.2230, 28.6320],
                },
              },
              <String, dynamic>{
                'poiId': 'poi-2',
                'poiName': 'Fuel Station',
                'location': <String, dynamic>{
                  'latitude': 28.6280,
                  'longitude': 77.2180,
                },
              },
            ],
          },
        },
      );

      expect(pois, hasLength(2));
      expect(pois.first.name, 'Depot');
      expect(pois.first.position.latitude, closeTo(28.6320, 0.0001));
      expect(pois.first.position.longitude, closeTo(77.2230, 0.0001));
      expect(pois.last.name, 'Fuel Station');
      expect(pois.last.position.latitude, closeTo(28.6280, 0.0001));
    });

    test('parses routes from geodata coordinates and encoded polylines', () {
      final routes = service.parseRoutesPayload(
        <String, dynamic>{
          'data': <String, dynamic>{
            'routes': <Map<String, dynamic>>[
              <String, dynamic>{
                'routeId': 'route-1',
                'routeName': 'Primary Loop',
                'geodata': <String, dynamic>{
                  'geometry': <String, dynamic>{
                    'type': 'LineString',
                    'coordinates': <dynamic>[
                      <dynamic>[77.2050, 28.6100],
                      <dynamic>[77.2140, 28.6160],
                      <dynamic>[77.2200, 28.6220],
                    ],
                  },
                },
              },
              <String, dynamic>{
                '_id': 'route-2',
                'title': 'Encoded Route',
                'polyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
              },
            ],
          },
        },
      );

      expect(routes, hasLength(2));
      expect(routes.first.name, 'Primary Loop');
      expect(routes.first.path, hasLength(3));
      expect(routes.first.path.first.latitude, closeTo(28.6100, 0.0001));
      expect(routes.first.path.first.longitude, closeTo(77.2050, 0.0001));
      expect(routes.last.path, hasLength(3));
      expect(routes.last.path.first.latitude, closeTo(38.5, 0.0001));
      expect(routes.last.path.first.longitude, closeTo(-120.2, 0.0001));
    });
  });
}
