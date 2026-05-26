import 'package:flutter/foundation.dart';

/// Lightweight performance trace used to debug release-startup slowdowns
/// introduced by mobile push initialization.
///
/// Logs are emitted only in debug or profile builds so release output stays
/// clean. Use short, low-cardinality labels to keep traces grep-friendly.
void mobilePushPerfLog(String label) {
  if (kDebugMode || kProfileMode) {
    debugPrint('[push-perf] $label');
  }
}
