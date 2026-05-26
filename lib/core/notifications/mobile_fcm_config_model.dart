import 'package:firebase_core/firebase_core.dart';

import 'mobile_push_platform.dart';

class MobileFirebaseOptionsModel {
  const MobileFirebaseOptionsModel({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.storageBucket,
    this.authDomain,
    this.androidPackageName,
    this.iosBundleId,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? storageBucket;
  final String? authDomain;
  final String? androidPackageName;
  final String? iosBundleId;

  factory MobileFirebaseOptionsModel.fromDynamic(
    dynamic source, {
    MobilePushPlatform? platform,
  }) {
    final configPayload = _extractConfigPayload(source);
    final effectivePlatform = platform ??
        MobilePushPlatform.fromApiValue(
          _readOptionalString(configPayload, const ['platform']),
        );
    final payload = _extractFirebaseOptionsPayload(configPayload);

    final iosBundleId = _readOptionalString(
      payload,
      const ['iosBundleId', 'ios_bundle_id', 'bundleId', 'bundle_id'],
    );
    if (effectivePlatform == MobilePushPlatform.ios && iosBundleId == null) {
      throw const FormatException(
        'FCM iOS app config is missing iosBundleId.',
      );
    }

    return MobileFirebaseOptionsModel(
      apiKey: _readRequiredString(payload, const ['apiKey', 'api_key']),
      appId: _readRequiredString(
        payload,
        const ['appId', 'appID', 'app_id'],
      ),
      messagingSenderId: _readRequiredString(
        payload,
        const [
          'messagingSenderId',
          'messaging_sender_id',
          'gcmSenderId',
          'gcm_sender_id',
        ],
      ),
      projectId: _readRequiredString(
        payload,
        const ['projectId', 'project_id'],
      ),
      storageBucket: _readOptionalString(
        payload,
        const ['storageBucket', 'storage_bucket'],
      ),
      authDomain: _readOptionalString(
        payload,
        const ['authDomain', 'auth_domain'],
      ),
      androidPackageName: _readOptionalString(
        payload,
        const ['androidPackageName', 'android_package_name', 'packageName'],
      ),
      iosBundleId: iosBundleId,
    );
  }

  FirebaseOptions toFirebaseOptions() {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain,
      storageBucket: storageBucket,
      iosBundleId: iosBundleId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'apiKey': apiKey,
      'appId': appId,
      'messagingSenderId': messagingSenderId,
      'projectId': projectId,
      if (storageBucket != null) 'storageBucket': storageBucket,
      if (authDomain != null) 'authDomain': authDomain,
      if (androidPackageName != null) 'androidPackageName': androidPackageName,
      if (iosBundleId != null) 'iosBundleId': iosBundleId,
    };
  }
}

class MobileFcmConfigResponse {
  const MobileFcmConfigResponse({
    required this.platform,
    required this.firebaseOptions,
    required this.configVersion,
  });

  final MobilePushPlatform platform;
  final MobileFirebaseOptionsModel firebaseOptions;
  final String configVersion;

  factory MobileFcmConfigResponse.fromDynamic(dynamic source) {
    final payload = _extractConfigPayload(source);
    final platform = MobilePushPlatform.fromApiValue(
      _readOptionalString(payload, const ['platform']),
    );
    if (!platform.isSupported) {
      throw const FormatException(
        'FCM mobile config platform must be android or ios.',
      );
    }

    return MobileFcmConfigResponse(
      platform: platform,
      firebaseOptions: MobileFirebaseOptionsModel.fromDynamic(
        payload,
        platform: platform,
      ),
      configVersion: _readOptionalString(
            payload,
            const ['configVersion', 'config_version', 'version'],
          ) ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'platform': platform.apiValue,
      'firebaseOptions': firebaseOptions.toJson(),
      'configVersion': configVersion,
    };
  }
}

Map<String, dynamic> _extractConfigPayload(dynamic source) {
  final root = _asMap(source);
  if (root.isEmpty) {
    return const <String, dynamic>{};
  }

  if (root.containsKey('firebaseOptions') ||
      root.containsKey('platform') ||
      _looksLikeFirebaseOptions(root)) {
    return root;
  }

  for (final key in const ['data', 'payload', 'result', 'response']) {
    final nestedSource = root[key];
    if (nestedSource == null || identical(nestedSource, source)) {
      continue;
    }

    final nested = _extractConfigPayload(nestedSource);
    if (nested.isNotEmpty) {
      return nested;
    }
  }

  return root;
}

Map<String, dynamic> _extractFirebaseOptionsPayload(dynamic source) {
  final root = _asMap(source);
  if (root.isEmpty) {
    return const <String, dynamic>{};
  }

  final directOptions = _asMap(root['firebaseOptions']);
  if (directOptions.isNotEmpty) {
    return directOptions;
  }

  if (_looksLikeFirebaseOptions(root)) {
    return root;
  }

  for (final key in const ['data', 'payload', 'result', 'response']) {
    final nestedSource = root[key];
    if (nestedSource == null || identical(nestedSource, source)) {
      continue;
    }

    final nested = _extractFirebaseOptionsPayload(nestedSource);
    if (nested.isNotEmpty) {
      return nested;
    }
  }

  return root;
}

bool _looksLikeFirebaseOptions(Map<String, dynamic> map) {
  for (final key in const [
    'apiKey',
    'api_key',
    'appId',
    'appID',
    'app_id',
    'messagingSenderId',
    'messaging_sender_id',
    'projectId',
    'project_id',
  ]) {
    if (map.containsKey(key)) {
      return true;
    }
  }

  return false;
}

String _readRequiredString(Map<String, dynamic> map, List<String> keys) {
  final value = _readOptionalString(map, keys);
  if (value == null) {
    throw FormatException('FCM mobile app config is missing ${keys.first}.');
  }

  return value;
}

String? _readOptionalString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final raw = map[key];
    final value = raw?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return null;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  return const <String, dynamic>{};
}
