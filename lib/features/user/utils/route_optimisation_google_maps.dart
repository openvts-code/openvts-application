import '../models/user_route_optimisation_model.dart';

/// Practical cap for Google Maps "Directions URL" waypoints.
///
/// The Google Maps Directions URL accepts up to ~25 stops in addition to
/// origin and destination. Beyond that the URL is silently truncated or
/// rejected — we down-sample evenly while keeping the visit sequence.
const int kGoogleMapsMaxWaypoints = 25;

/// Builds a `https://www.google.com/maps/dir/?api=1&...` URL for the given
/// [points] visited in [order].
///
/// Coordinate order in the URL is **`lat,lon`** (NOT `lon,lat`).
///
/// When [roundTrip] is `true`, the destination equals the origin and the rest
/// of [order] becomes waypoints in between. Middle waypoints beyond
/// [kGoogleMapsMaxWaypoints] are evenly down-sampled to fit Google's limit.
///
/// Returns an empty string when [order] is shorter than two stops — callers
/// should guard against that and present a snackbar instead of opening the
/// URL.
String generateGoogleMapsUrl({
  required List<RouteOptimisationPoint> points,
  required List<int> order,
  required bool roundTrip,
}) {
  if (order.length < 2) return '';
  final resolved = <RouteOptimisationPoint>[
    for (final i in order)
      if (i >= 0 && i < points.length) points[i],
  ];
  if (resolved.length < 2) return '';

  final origin = resolved.first;
  final destination = roundTrip ? origin : resolved.last;

  // Middle waypoints: everything between first and last (and, for round-trip,
  // also include the final stop because destination == origin).
  final middle = roundTrip
      ? resolved.sublist(1) // last stop is still a real stop to visit
      : resolved.sublist(1, resolved.length - 1);

  final waypoints = _downsampleWaypoints(middle, kGoogleMapsMaxWaypoints);

  final originStr = _latLonString(origin);
  final destStr = _latLonString(destination);

  final params = <String, String>{
    'api': '1',
    'origin': originStr,
    'destination': destStr,
    'travelmode': 'driving',
  };
  if (waypoints.isNotEmpty) {
    params['waypoints'] = waypoints.map(_latLonString).join('|');
  }

  final query = params.entries
      .map((e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');
  return 'https://www.google.com/maps/dir/?$query';
}

String _latLonString(RouteOptimisationPoint p) =>
    '${p.lat.toStringAsFixed(6)},${p.lon.toStringAsFixed(6)}';

/// Evenly samples at most [max] entries from [items] while preserving order
/// and always keeping the first and last entry when present.
List<RouteOptimisationPoint> _downsampleWaypoints(
  List<RouteOptimisationPoint> items,
  int max,
) {
  if (items.length <= max) return items;
  if (max <= 0) return const <RouteOptimisationPoint>[];
  if (max == 1) return <RouteOptimisationPoint>[items.first];

  final picked = <RouteOptimisationPoint>[];
  final step = (items.length - 1) / (max - 1);
  for (int k = 0; k < max; k++) {
    final idx = (k * step).round().clamp(0, items.length - 1);
    final p = items[idx];
    if (picked.isEmpty || !identical(picked.last, p)) {
      picked.add(p);
    }
  }
  return picked;
}
