import 'dart:math' as math;

import '../models/user_route_optimisation_model.dart';
import 'route_optimisation_distance.dart';
import 'route_optimisation_held_karp.dart';
import 'route_optimisation_nearest_neighbor.dart';
import 'route_optimisation_two_opt.dart';

/// Threshold below or equal to which the exact Held-Karp solver is used.
const int kExactSolverThreshold = kHeldKarpMaxPoints;

/// Iteration ceiling for the second 2-opt pass run inside multi-start.
const int kMultiStartTwoOptIterations = 500;

/// Multi-start restart count for the heuristic path.
int multiStartRestartsFor(int n) =>
    math.min(20, math.max(5, n ~/ 2));

/// Computes the optimised order for [points] under the supplied [constraints].
///
/// * `N < 2` → throws [RouteOptimisationException].
/// * `N <= kExactSolverThreshold` → Held-Karp (exact).
/// * `N > kExactSolverThreshold` → nearest-neighbour + 2-opt, then multi-start
///   2-opt with capped restarts, best of the two is returned.
///
/// The matrix build and DP/heuristic passes run synchronously on the caller's
/// isolate. Bounds are tuned so a typical N=30 input finishes in well under
/// 500 ms on a mid-range mobile device — for genuinely huge inputs the caller
/// should hop into a `compute()` isolate.
RouteOptimisationResult optimizeRoute(
  List<RouteOptimisationPoint> points,
  RouteOptimisationConstraints constraints,
) {
  RouteOptimisationValidation.requireOptimisable(points);

  final int n = points.length;
  final int startIndex = constraints.startIndex.clamp(0, n - 1);
  final int endIndex =
      (constraints.roundTrip || constraints.endIndex < 0)
          ? -1
          : (constraints.endIndex >= n ? -1 : constraints.endIndex);
  final bool roundTrip = constraints.roundTrip;
  final bool fixedEnd = !roundTrip && endIndex >= 0 && endIndex != startIndex;

  final stopwatch = Stopwatch()..start();
  final matrix = buildDistanceMatrix(points);

  final originalOrder = List<int>.generate(n, (i) => i);
  final double originalDistance = calculateOrderDistance(
    originalOrder,
    matrix,
    roundTrip: roundTrip,
  );

  late List<int> bestOrder;
  late String algorithmUsed;

  if (n <= kExactSolverThreshold) {
    bestOrder = heldKarpOptimalOrder(
      matrix: matrix,
      startIndex: startIndex,
      endIndex: endIndex,
      roundTrip: roundTrip,
    );
    algorithmUsed = 'Held-Karp DP (exact, N=$n)';
  } else {
    // Heuristic: NN + 2-opt, then multi-start 2-opt, take the better.
    final nn = nearestNeighborOrder(
      matrix: matrix,
      startIndex: startIndex,
      endIndex: endIndex,
      roundTrip: roundTrip,
    );
    final nnImproved = twoOptOptimize(
      order: nn,
      matrix: matrix,
      roundTrip: roundTrip,
      fixedEnd: fixedEnd,
      maxIterations: kTwoOptDefaultMaxIterations,
    );

    final multiStart = _multiStartTwoOpt(
      seed: nnImproved,
      matrix: matrix,
      startIndex: startIndex,
      endIndex: endIndex,
      roundTrip: roundTrip,
      fixedEnd: fixedEnd,
    );

    final nnDist =
        calculateOrderDistance(nnImproved, matrix, roundTrip: roundTrip);
    final msDist =
        calculateOrderDistance(multiStart, matrix, roundTrip: roundTrip);
    bestOrder = (msDist < nnDist) ? multiStart : nnImproved;
    algorithmUsed = 'Heuristic (NN + 2-opt + multi-start)';
  }

  final double optimisedDistance = calculateOrderDistance(
    bestOrder,
    matrix,
    roundTrip: roundTrip,
  );
  stopwatch.stop();

  final double improvementPct = originalDistance > 0
      ? ((originalDistance - optimisedDistance) / originalDistance) * 100.0
      : 0.0;
  final double processingMs = stopwatch.elapsedMicroseconds / 1000.0;

  final logs = _buildReport(
    points: points,
    originalOrder: originalOrder,
    optimisedOrder: bestOrder,
    originalDistance: originalDistance,
    optimisedDistance: optimisedDistance,
    improvementPct: improvementPct,
    processingMs: processingMs,
    algorithmUsed: algorithmUsed,
    roundTrip: roundTrip,
  );

  return RouteOptimisationResult(
    originalOrder: originalOrder,
    optimizedOrder: bestOrder,
    originalDistanceKm: originalDistance,
    optimizedDistanceKm: optimisedDistance,
    improvementPct: improvementPct,
    processingMs: processingMs,
    algorithmUsed: algorithmUsed,
    logs: logs,
  );
}

// ---------------------------------------------------------------------------
// Multi-start 2-opt
// ---------------------------------------------------------------------------

List<int> _multiStartTwoOpt({
  required List<int> seed,
  required List<List<double>> matrix,
  required int startIndex,
  required int endIndex,
  required bool roundTrip,
  required bool fixedEnd,
}) {
  final int n = seed.length;
  if (n < 4) return seed;
  final restarts = multiStartRestartsFor(n);
  final rng = math.Random(0xC0FFEE ^ n);

  var bestOrder = seed;
  var bestDist =
      calculateOrderDistance(seed, matrix, roundTrip: roundTrip);

  // Indices eligible to be shuffled (everything except pinned start/end).
  final middle = <int>[];
  for (int i = 0; i < n; i++) {
    if (i == startIndex) continue;
    if (fixedEnd && i == endIndex) continue;
    middle.add(i);
  }
  if (middle.length < 2) return bestOrder;

  for (int r = 0; r < restarts; r++) {
    final shuffled = List<int>.from(middle)..shuffle(rng);
    final candidate = <int>[startIndex, ...shuffled];
    if (fixedEnd) candidate.add(endIndex);

    final improved = twoOptOptimize(
      order: candidate,
      matrix: matrix,
      roundTrip: roundTrip,
      fixedEnd: fixedEnd,
      maxIterations: kMultiStartTwoOptIterations,
    );
    final dist =
        calculateOrderDistance(improved, matrix, roundTrip: roundTrip);
    if (dist < bestDist) {
      bestDist = dist;
      bestOrder = improved;
    }
  }
  return bestOrder;
}

// ---------------------------------------------------------------------------
// Report formatter
// ---------------------------------------------------------------------------

String _buildReport({
  required List<RouteOptimisationPoint> points,
  required List<int> originalOrder,
  required List<int> optimisedOrder,
  required double originalDistance,
  required double optimisedDistance,
  required double improvementPct,
  required double processingMs,
  required String algorithmUsed,
  required bool roundTrip,
}) {
  final saved = originalDistance - optimisedDistance;
  final mode = roundTrip ? 'Round Trip (cycle)' : 'Open Path';
  final buf = StringBuffer();
  buf.writeln('================ ROUTE OPTIMISATION REPORT ================');
  buf.writeln('Algorithm    : $algorithmUsed');
  buf.writeln('Points       : ${points.length}');
  buf.writeln('Mode         : $mode');
  buf.writeln('Time         : ${processingMs.toStringAsFixed(2)} ms');
  buf.writeln('-----------------------------------------------------------');
  buf.writeln('DISTANCE SUMMARY');
  buf.writeln('Original     : ${originalDistance.toStringAsFixed(3)} km');
  buf.writeln('Optimised    : ${optimisedDistance.toStringAsFixed(3)} km');
  buf.writeln('Saved        : ${saved.toStringAsFixed(3)} km');
  buf.writeln('Improvement  : ${improvementPct.toStringAsFixed(2)} %');
  buf.writeln('-----------------------------------------------------------');
  buf.writeln('OPTIMISED ROUTE ORDER');
  for (var i = 0; i < optimisedOrder.length; i++) {
    final p = points[optimisedOrder[i]];
    final tag = i == 0
        ? ' [START]'
        : (i == optimisedOrder.length - 1 && !roundTrip ? ' [END]' : '');
    buf.writeln(' ${(i + 1).toString().padLeft(2)}) ${p.name}$tag');
  }
  if (roundTrip && optimisedOrder.isNotEmpty) {
    final start = points[optimisedOrder.first];
    buf.writeln(' ${(optimisedOrder.length + 1).toString().padLeft(2)})'
        ' ${start.name} [RETURN]');
  }
  buf.writeln('===========================================================');
  // Original order line, useful for debugging non-trivial inputs.
  buf.writeln('Original order: $originalOrder');
  buf.writeln('Optimised order: $optimisedOrder');
  return buf.toString();
}
