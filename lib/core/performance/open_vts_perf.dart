import 'package:flutter/foundation.dart';

class OpenVtsPerf {
  const OpenVtsPerf._();

  static bool get _enabled => kDebugMode || kProfileMode;

  static void mark(String label) {
    if (!_enabled) {
      return;
    }

    debugPrint('[perf] ${_sanitizeLabel(label)}');
  }

  static Future<T> traceAsync<T>(
    String label,
    Future<T> Function() action,
  ) async {
    if (!_enabled) {
      return action();
    }

    final stopwatch = Stopwatch()..start();
    try {
      return await action();
    } finally {
      stopwatch.stop();
      _log(label, stopwatch.elapsedMilliseconds);
    }
  }

  static T traceSync<T>(String label, T Function() action) {
    if (!_enabled) {
      return action();
    }

    final stopwatch = Stopwatch()..start();
    try {
      return action();
    } finally {
      stopwatch.stop();
      _log(label, stopwatch.elapsedMilliseconds);
    }
  }

  static void _log(String label, int elapsedMilliseconds) {
    debugPrint('[perf] ${_sanitizeLabel(label)} ${elapsedMilliseconds}ms');
  }

  static String _sanitizeLabel(String label) {
    final normalized = label
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return 'unknown';
    }

    return normalized.length > 160 ? normalized.substring(0, 160) : normalized;
  }
}
