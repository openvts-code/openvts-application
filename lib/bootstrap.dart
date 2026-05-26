import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_config.dart';
import 'core/notifications/mobile_push_background_handler.dart';
import 'core/notifications/mobile_push_perf.dart';
import 'core/performance/open_vts_perf.dart';

void registerBackgroundHandlers() {
  if (AppConfig.useMockData) {
    return;
  }

  try {
    FirebaseMessaging.onBackgroundMessage(
      openVtsFirebaseMessagingBackgroundHandler,
    );
  } catch (e) {
    debugPrint('Failed to register Firebase background handler: $e');
  }
}

Future<void> bootstrap(Future<void> Function() runApp) async {
  WidgetsFlutterBinding.ensureInitialized();

  final stopwatch =
      (kDebugMode || kProfileMode) ? (Stopwatch()..start()) : null;
  mobilePushPerfLog('app_boot start');

  try {
    await OpenVtsPerf.traceAsync(
      'bootstrap.dotenv',
      () => dotenv.load(fileName: '.env'),
    );
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
    // Initialize with empty map so dotenv.env accesses don't throw NotInitializedError
    dotenv.testLoad(fileInput: '');
  }

  registerBackgroundHandlers();

  await runApp();

  if (stopwatch != null) {
    mobilePushPerfLog('app_boot end (${stopwatch.elapsedMilliseconds}ms)');
  }
}
