/// Iteration ceiling for a single 2-opt pass (matches the web tuning).
const int kTwoOptDefaultMaxIterations = 1000;

/// Standard 2-opt local search.
///
/// Reverses segments `order[i..j]` whenever doing so shortens the tour.
///
/// Constraints respected:
/// * `order[0]` is never moved (start is always pinned).
/// * When [fixedEnd] is `true` (a fixed end node was set) or [roundTrip] is
///   `false`, `order[n-1]` is also never moved — this matches the web
///   behaviour where the last position is preserved even in "auto end" mode.
/// * When [roundTrip] is `true`, the wrap-around edge `order[n-1] → order[0]`
///   participates in the swap cost calculation.
///
/// Returns a new list (input is not mutated).
List<int> twoOptOptimize({
  required List<int> order,
  required List<List<double>> matrix,
  required bool roundTrip,
  required bool fixedEnd,
  int maxIterations = kTwoOptDefaultMaxIterations,
}) {
  final n = order.length;
  if (n < 4) return List<int>.from(order);

  final route = List<int>.from(order);
  // When end is "pinned" we cannot touch the last position.
  final bool pinLast = !roundTrip || fixedEnd;
  final int iMax = pinLast ? n - 3 : n - 2; // inclusive
  final int jMax = pinLast ? n - 2 : n - 1; // inclusive
  if (iMax < 1 || jMax <= iMax) return route;

  bool improved = true;
  int iter = 0;

  while (improved && iter < maxIterations) {
    improved = false;
    for (int i = 1; i <= iMax; i++) {
      for (int j = i + 1; j <= jMax; j++) {
        if (++iter > maxIterations) {
          return route;
        }
        final int a = route[i - 1];
        final int b = route[i];
        final int c = route[j];
        // Node after the segment. For round-trip we wrap to route[0] when the
        // segment ends at the last position.
        int d;
        if (j + 1 < n) {
          d = route[j + 1];
        } else if (roundTrip) {
          d = route[0];
        } else {
          continue;
        }
        final double before = matrix[a][b] + matrix[c][d];
        final double after = matrix[a][c] + matrix[b][d];
        if (after + 1e-12 < before) {
          // Reverse the [i..j] segment in place.
          int l = i, r = j;
          while (l < r) {
            final int tmp = route[l];
            route[l] = route[r];
            route[r] = tmp;
            l++;
            r--;
          }
          improved = true;
        }
      }
    }
  }
  return route;
}
