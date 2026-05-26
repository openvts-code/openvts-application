import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Options for normal, fast-read API calls (short receive timeout).
Options normalReadOptions() {
  return Options(
    sendTimeout: const Duration(seconds: AppConfig.connectTimeoutSeconds),
    receiveTimeout: const Duration(seconds: AppConfig.receiveTimeoutSeconds),
  );
}

/// Options for normal mutations where the backend should respond quickly.
Options normalWriteOptions() {
  return Options(
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  );
}

/// Options for heavier reads where server may take longer (45-60s).
Options heavyReadOptions() {
  return Options(
    sendTimeout: const Duration(seconds: AppConfig.connectTimeoutSeconds),
    receiveTimeout: const Duration(seconds: 60),
  );
}

/// Options for uploads / exports / long-running endpoints.
Options uploadOptions() {
  return Options(
    sendTimeout: const Duration(seconds: 300),
    receiveTimeout: const Duration(seconds: 300),
  );
}

/// Options for file downloads and export responses.
Options downloadOptions() {
  return Options(
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 300),
  );
}

/// Options for best-effort background reads that should fail fast.
Options lowPriorityOptions() {
  return Options(
    sendTimeout: const Duration(seconds: AppConfig.connectTimeoutSeconds),
    receiveTimeout: const Duration(seconds: 8),
  );
}
