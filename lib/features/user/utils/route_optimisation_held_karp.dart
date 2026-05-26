import '../models/user_route_optimisation_model.dart';

/// Hard upper bound for the exact Held-Karp solver.
///
/// At N=12 the DP has 12 · 2^12 ≈ 49k states which runs in milliseconds on
/// mobile. At N=13 the cost roughly doubles and the heuristic path is used
/// instead.
const int kHeldKarpMaxPoints = 12;

/// Optimal Hamiltonian path (or cycle) over [matrix] respecting the supplied
/// start/end constraints.
///
/// * [startIndex] is always the first node in the returned order.
/// * When [roundTrip] is `true`, [endIndex] is ignored and the route closes
///   back at [startIndex] (the returned list does **not** repeat the start —
///   callers handle the closing leg).
/// * When [endIndex] is `>= 0` and != [startIndex], it becomes the last node.
/// * When [endIndex] is `-1` and [roundTrip] is `false`, any node may end
///   the route.
///
/// Throws [RouteOptimisationException] if `matrix.length > kHeldKarpMaxPoints`.
List<int> heldKarpOptimalOrder({
  required List<List<double>> matrix,
  required int startIndex,
  required int endIndex,
  required bool roundTrip,
}) {
  final n = matrix.length;
  if (n == 0) return const <int>[];
  if (n == 1) return <int>[0];
  if (n > kHeldKarpMaxPoints) {
    throw RouteOptimisationException(
      'Held-Karp solver supports at most $kHeldKarpMaxPoints points (got $n).',
    );
  }
  if (startIndex < 0 || startIndex >= n) {
    throw RouteOptimisationException('startIndex $startIndex out of range.');
  }

  final int effectiveEnd = (roundTrip || endIndex < 0 || endIndex == startIndex)
      ? -1
      : endIndex;

  final int full = (1 << n) - 1;
  const double inf = double.infinity;

  // dp[mask][i] = min cost of a path starting at startIndex, visiting exactly
  // the nodes in mask, ending at i (i must be in mask).
  final dp = List<List<double>>.generate(
    1 << n,
    (_) => List<double>.filled(n, inf),
    growable: false,
  );
  final parent = List<List<int>>.generate(
    1 << n,
    (_) => List<int>.filled(n, -1),
    growable: false,
  );

  dp[1 << startIndex][startIndex] = 0.0;

  final endBit = effectiveEnd >= 0 ? (1 << effectiveEnd) : 0;
  // When end is fixed, we may only step into it once everything else is
  // already visited.
  final int penultimateMask = effectiveEnd >= 0 ? (full ^ endBit) : 0;

  for (int mask = 1; mask <= full; mask++) {
    if ((mask & (1 << startIndex)) == 0) continue;
    for (int i = 0; i < n; i++) {
      if ((mask & (1 << i)) == 0) continue;
      final double base = dp[mask][i];
      if (base == inf) continue;
      for (int j = 0; j < n; j++) {
        if (j == i) continue;
        if ((mask & (1 << j)) != 0) continue;
        if (effectiveEnd >= 0 && j == effectiveEnd && mask != penultimateMask) {
          continue;
        }
        final int next = mask | (1 << j);
        final double cand = base + matrix[i][j];
        if (cand < dp[next][j]) {
          dp[next][j] = cand;
          parent[next][j] = i;
        }
      }
    }
  }

  // Pick the optimal terminal node.
  double best = inf;
  int last = -1;
  if (roundTrip) {
    for (int i = 0; i < n; i++) {
      if (i == startIndex) continue;
      final double cand = dp[full][i] + matrix[i][startIndex];
      if (cand < best) {
        best = cand;
        last = i;
      }
    }
  } else if (effectiveEnd >= 0) {
    best = dp[full][effectiveEnd];
    last = effectiveEnd;
  } else {
    for (int i = 0; i < n; i++) {
      if (dp[full][i] < best) {
        best = dp[full][i];
        last = i;
      }
    }
  }

  if (last < 0) {
    // Degenerate input — fall back to trivial sequential order.
    return List<int>.generate(n, (i) => i);
  }

  // Reconstruct the path by walking parent pointers backwards.
  final order = <int>[];
  int mask = full;
  int cur = last;
  while (cur != -1) {
    order.add(cur);
    final int prev = parent[mask][cur];
    mask ^= (1 << cur);
    cur = prev;
  }
  return order.reversed.toList(growable: false);
}
