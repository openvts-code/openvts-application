/// Greedy nearest-neighbour tour over a precomputed distance matrix.
///
/// * [startIndex] is always the first node in the returned order.
/// * When [endIndex] is `>= 0` and != [startIndex] and [roundTrip] is `false`,
///   the end node is reserved and appended last.
/// * When [roundTrip] is `true`, the closing leg back to [startIndex] is left
///   for the caller — the returned list does not repeat the start.
List<int> nearestNeighborOrder({
  required List<List<double>> matrix,
  required int startIndex,
  required int endIndex,
  required bool roundTrip,
}) {
  final n = matrix.length;
  if (n == 0) return const <int>[];
  if (n == 1) return <int>[0];

  final visited = List<bool>.filled(n, false);
  final order = <int>[startIndex];
  visited[startIndex] = true;

  final bool reserveEnd =
      !roundTrip && endIndex >= 0 && endIndex != startIndex && endIndex < n;
  if (reserveEnd) {
    visited[endIndex] = true;
  }

  int current = startIndex;
  final int remaining = n - (reserveEnd ? 2 : 1);
  for (int step = 0; step < remaining; step++) {
    int best = -1;
    double bestDist = double.infinity;
    final row = matrix[current];
    for (int j = 0; j < n; j++) {
      if (visited[j]) continue;
      final d = row[j];
      if (d < bestDist) {
        bestDist = d;
        best = j;
      }
    }
    if (best < 0) break;
    visited[best] = true;
    order.add(best);
    current = best;
  }

  if (reserveEnd) {
    order.add(endIndex);
  }
  return order;
}
