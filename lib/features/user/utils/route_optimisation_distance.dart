import 'dart:math' as math;

import '../models/user_route_optimisation_model.dart';

/// Mean Earth radius used by the haversine formula.
const double kEarthRadiusKm = 6371.0;

double _toRadians(double degrees) => degrees * math.pi / 180.0;

/// Great-circle distance between two `(lat, lon)` pairs in kilometres.
///
/// Returns `0.0` for identical points and is symmetric:
/// `haversine(a, b) == haversine(b, a)`.
double haversineDistanceKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final s1 = math.sin(dLat / 2);
  final s2 = math.sin(dLon / 2);
  final a = s1 * s1 +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * s2 * s2;
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return kEarthRadiusKm * c;
}

/// Builds an NxN symmetric distance matrix (km) for the given points.
List<List<double>> buildDistanceMatrix(List<RouteOptimisationPoint> points) {
  final n = points.length;
  final matrix = List<List<double>>.generate(
    n,
    (_) => List<double>.filled(n, 0.0),
    growable: false,
  );
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      final d = haversineDistanceKm(
        points[i].lat,
        points[i].lon,
        points[j].lat,
        points[j].lon,
      );
      matrix[i][j] = d;
      matrix[j][i] = d;
    }
  }
  return matrix;
}

/// Total distance of an open route visiting [order] in sequence.
double calculateRouteDistance(List<int> order, List<List<double>> matrix) {
  if (order.length < 2) return 0.0;
  var total = 0.0;
  for (var i = 0; i < order.length - 1; i++) {
    total += matrix[order[i]][order[i + 1]];
  }
  return total;
}

/// Total distance of a closed route ([order] + return to start).
double calculateRoundTripDistance(
  List<int> order,
  List<List<double>> matrix,
) {
  if (order.length < 2) return 0.0;
  return calculateRouteDistance(order, matrix) +
      matrix[order.last][order.first];
}

/// Convenience: chooses open/closed sum based on [roundTrip].
double calculateOrderDistance(
  List<int> order,
  List<List<double>> matrix, {
  required bool roundTrip,
}) {
  return roundTrip
      ? calculateRoundTripDistance(order, matrix)
      : calculateRouteDistance(order, matrix);
}
