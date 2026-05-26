import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/storage_keys.dart';
import 'mobile_fcm_config_model.dart';

@pragma('vm:entry-point')
Future<void> openVtsFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (Firebase.apps.isNotEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final cachedConfig = preferences.getString(
      StorageKeys.mobilePushFirebaseConfigJson,
    );
    if (cachedConfig == null || cachedConfig.trim().isEmpty) {
      return;
    }

    final decoded = jsonDecode(cachedConfig);
    final config = MobileFcmConfigResponse.fromDynamic(decoded);
    await Firebase.initializeApp(
      options: config.firebaseOptions.toFirebaseOptions(),
    );
  } catch (_) {
    return;
  }
}
