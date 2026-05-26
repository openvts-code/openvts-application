import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../config/app_config.dart';
import '../storage/local_cache.dart';
import '../storage/storage_keys.dart';
import '../storage/token_storage.dart';
import 'mobile_fcm_config_model.dart';
import 'mobile_push_local_notifications.dart';
import 'mobile_push_message_mapper.dart';
import 'mobile_push_perf.dart';
import 'mobile_push_platform.dart';
import 'mobile_push_token_model.dart';

// Mobile push API calls must never stall startup. Use short, explicit
// timeouts so a slow or unreachable backend cannot delay UI flows.
const Duration _mobilePushApiSendTimeout = Duration(seconds: 6);
const Duration _mobilePushApiReceiveTimeout = Duration(seconds: 6);

Options _mobilePushApiOptions() {
  return Options(
    sendTimeout: _mobilePushApiSendTimeout,
    receiveTimeout: _mobilePushApiReceiveTimeout,
  );
}

enum MobilePushInitStatus {
  disabled,
  initialized,
  pendingRestart,
  failed,
}

class MobilePushInitResult {
  const MobilePushInitResult({
    required this.status,
    required this.platform,
    this.configVersion,
    this.message,
  });

  final MobilePushInitStatus status;
  final MobilePushPlatform platform;
  final String? configVersion;
  final String? message;

  bool get isEnabled => status == MobilePushInitStatus.initialized;

  factory MobilePushInitResult.disabled({
    required MobilePushPlatform platform,
    String? message,
  }) {
    return MobilePushInitResult(
      status: MobilePushInitStatus.disabled,
      platform: platform,
      message: message,
    );
  }

  factory MobilePushInitResult.initialized({
    required MobilePushPlatform platform,
    String? configVersion,
  }) {
    return MobilePushInitResult(
      status: MobilePushInitStatus.initialized,
      platform: platform,
      configVersion: configVersion,
    );
  }

  factory MobilePushInitResult.pendingRestart({
    required MobilePushPlatform platform,
    String? configVersion,
    String? message,
  }) {
    return MobilePushInitResult(
      status: MobilePushInitStatus.pendingRestart,
      platform: platform,
      configVersion: configVersion,
      message: message,
    );
  }

  factory MobilePushInitResult.failed({
    required MobilePushPlatform platform,
    String? message,
  }) {
    return MobilePushInitResult(
      status: MobilePushInitStatus.failed,
      platform: platform,
      message: message,
    );
  }
}

class MobilePushService {
  MobilePushService({
    required ApiClient apiClient,
    required LocalCache localCache,
    required TokenStorage tokenStorage,
    required FlutterSecureStorage secureStorage,
    DeviceInfoPlugin? deviceInfoPlugin,
    MobilePushLocalNotifications? localNotifications,
  })  : _apiClient = apiClient,
        _localCache = localCache,
        _tokenStorage = tokenStorage,
        _secureStorage = secureStorage,
        _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin(),
        _localNotifications =
            localNotifications ?? MobilePushLocalNotifications();

  final ApiClient _apiClient;
  final LocalCache _localCache;
  final TokenStorage _tokenStorage;
  final FlutterSecureStorage _secureStorage;
  final DeviceInfoPlugin _deviceInfoPlugin;
  final MobilePushLocalNotifications _localNotifications;

  final _foregroundMessageController =
      StreamController<MobilePushMessage>.broadcast();
  final _notificationTapController =
      StreamController<MobilePushMessage>.broadcast();
  final _tokenRefreshController = StreamController<String>.broadcast();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _notificationTapSubscription;
  Future<MobilePushInitResult>? _initializeFuture;
  bool _listenersStarted = false;
  String? _initializedConfigVersion;
  FutureOr<void> Function(MobilePushMessage message)? _navigationHandler;
  FutureOr<void> Function(MobilePushMessage message)?
      _notificationCenterRefreshHook;

  Stream<MobilePushMessage> get foregroundMessages =>
      _foregroundMessageController.stream;

  Stream<MobilePushMessage> get notificationTaps =>
      _notificationTapController.stream;

  Stream<String> get tokenRefreshes => _tokenRefreshController.stream;

  bool get hasFirebaseApp => Firebase.apps.isNotEmpty;

  void setNavigationHandler(
    FutureOr<void> Function(MobilePushMessage message)? handler,
  ) {
    _navigationHandler = handler;
  }

  void setNotificationCenterRefreshHook(
    FutureOr<void> Function(MobilePushMessage message)? hook,
  ) {
    _notificationCenterRefreshHook = hook;
  }

  Future<MobilePushInitResult> initialize() {
    _initializeFuture ??= _initializeInternal();
    return _initializeFuture!.whenComplete(() {
      _initializeFuture = null;
    });
  }

  Future<MobileFcmConfigResponse> fetchMobileConfig({
    MobilePushPlatform? platform,
  }) async {
    final effectivePlatform =
        platform ?? MobilePushPlatform.fromCurrentPlatform();
    if (!effectivePlatform.isSupported) {
      throw UnsupportedError('Mobile push platform is unsupported.');
    }

    mobilePushPerfLog('fetch_mobile_config start');
    try {
      final response = await _apiClient.get<MobileFcmConfigResponse>(
        ApiEndpoints.auth.fcmMobileConfig,
        queryParameters: <String, dynamic>{
          'platform': effectivePlatform.apiValue,
        },
        options: _mobilePushApiOptions(),
        parser: MobileFcmConfigResponse.fromDynamic,
      );
      mobilePushPerfLog('fetch_mobile_config ok');
      return response.data;
    } catch (error) {
      mobilePushPerfLog('fetch_mobile_config fail');
      rethrow;
    }
  }

  Future<bool> registerCurrentToken({String? token}) async {
    if (AppConfig.useMockData ||
        !MobilePushPlatform.fromCurrentPlatform().isSupported) {
      return false;
    }
    if (Firebase.apps.isEmpty) {
      return false;
    }

    final tokenToRegister = token?.trim().isNotEmpty == true
        ? token!.trim()
        : (await FirebaseMessaging.instance.getToken())?.trim();
    if (tokenToRegister == null || tokenToRegister.isEmpty) {
      return false;
    }

    return _registerToken(tokenToRegister);
  }

  Future<bool> deregisterToken({String? token}) async {
    if (AppConfig.useMockData ||
        !MobilePushPlatform.fromCurrentPlatform().isSupported) {
      return false;
    }
    if (await _tokenStorage.getActiveSession() == null) {
      return false;
    }

    try {
      final tokenToRemove = _firstNonEmpty([
        token,
        _localCache.getString(StorageKeys.mobilePushRegisteredToken),
        _localCache.getString(StorageKeys.mobilePushFcmToken),
      ]);
      final deviceId = await _readStoredDeviceId();
      final request = RemovePushTokenRequest(
        token: tokenToRemove,
        deviceId: deviceId,
      );
      final payload = request.toJson();
      if (payload.isEmpty) {
        return false;
      }

      await _apiClient.delete<bool>(
        ApiEndpoints.auth.pushToken,
        data: payload,
        options: _mobilePushApiOptions(),
        parser: (_) => true,
      );
      await _clearRegisteredTokenState();
      return true;
    } catch (error) {
      await _rememberLastInitError(_safeError(error));
      return false;
    }
  }

  Future<MobilePushTokenDiagnostics> fetchMyRegisteredTokens() async {
    final platform = MobilePushPlatform.fromCurrentPlatform();
    if (AppConfig.useMockData || !platform.isSupported) {
      return MobilePushTokenDiagnostics.empty(platform: platform);
    }
    if (await _tokenStorage.getActiveSession() == null) {
      return MobilePushTokenDiagnostics.empty(platform: platform);
    }

    final registeredTokenLast10 = _last10(
      _localCache.getString(StorageKeys.mobilePushRegisteredToken),
    );
    final response = await _apiClient.get<MobilePushTokenDiagnostics>(
      ApiEndpoints.auth.pushTokensMe,
      queryParameters: <String, dynamic>{'platform': platform.apiValue},
      options: _mobilePushApiOptions(),
      parser: (json) => MobilePushTokenDiagnostics.fromDynamic(
        json,
        platform: platform,
        currentRegisteredTokenLast10: registeredTokenLast10,
      ),
    );

    return response.data;
  }

  Future<String?> getCurrentToken() async {
    if (AppConfig.useMockData ||
        !MobilePushPlatform.fromCurrentPlatform().isSupported ||
        Firebase.apps.isEmpty) {
      return null;
    }

    final token = (await FirebaseMessaging.instance.getToken())?.trim();
    if (token == null || token.isEmpty) {
      return null;
    }

    await _localCache.setString(StorageKeys.mobilePushFcmToken, token);
    return token;
  }

  Future<NotificationSettings?> getNotificationSettings() async {
    if (AppConfig.useMockData ||
        !MobilePushPlatform.fromCurrentPlatform().isSupported ||
        Firebase.apps.isEmpty) {
      return null;
    }

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    await _rememberPermissionStatus(settings);
    return settings;
  }

  Future<NotificationSettings?> requestNotificationPermission() async {
    if (AppConfig.useMockData ||
        !MobilePushPlatform.fromCurrentPlatform().isSupported ||
        Firebase.apps.isEmpty) {
      return null;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _rememberPermissionStatus(settings);
    return settings;
  }

  Future<String> sendTestNotification() async {
    final platform = MobilePushPlatform.fromCurrentPlatform();
    if (AppConfig.useMockData || !platform.isSupported) {
      throw StateError('Mobile push is not supported on this platform.');
    }
    if (await _tokenStorage.getActiveSession() == null) {
      throw StateError('Sign in before sending a mobile push test.');
    }

    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.user.testFcmMe,
      data: <String, dynamic>{
        'platform': platform.apiValue,
        'title': 'OpenVTS Mobile Test',
        'body': 'Mobile push notifications are working.',
      },
      parser: (json) => json,
    );

    final message = response.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }

    final fallback = _extractMessage(response.data);
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return 'Mobile test notification sent.';
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _notificationTapSubscription?.cancel();
    await _tokenRefreshController.close();
    await _foregroundMessageController.close();
    await _notificationTapController.close();
  }

  Future<MobilePushInitResult> _initializeInternal() async {
    final platform = MobilePushPlatform.fromCurrentPlatform();
    if (AppConfig.useMockData) {
      return MobilePushInitResult.disabled(
        platform: platform,
        message: 'Mobile push is disabled while mock data is enabled.',
      );
    }

    if (!platform.isSupported) {
      return MobilePushInitResult.disabled(
        platform: platform,
        message: 'Mobile push is not supported on this platform.',
      );
    }

    try {
      await _localNotifications.initialize(onTap: _handleNotificationTap);

      final previousConfigVersion = _initializedConfigVersion ??
          _localCache.getString(StorageKeys.mobilePushFirebaseConfigVersion);

      // Prefer using cached Firebase config at startup to avoid a network
      // request to /auth/fcm-mobile-config during hot app start. Remote
      // fetches are performed only when no cached config is present.
      final cachedJson = _localCache.getString(
        StorageKeys.mobilePushFirebaseConfigJson,
      );

      if (cachedJson != null && cachedJson.trim().isNotEmpty) {
        try {
          final cached = MobileFcmConfigResponse.fromDynamic(
            jsonDecode(cachedJson),
          );

          final config = cached;
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: config.firebaseOptions.toFirebaseOptions(),
            );
            _initializedConfigVersion = config.configVersion;
          } else {
            // Runtime already has a Firebase app; accept cached config as the
            // authoritative local config for background registration purposes.
            _initializedConfigVersion = config.configVersion;
          }
        } catch (_) {
          // Corrupt cache -> fall back to fetching remote config.
          final config = await fetchMobileConfig(platform: platform);
          await _cacheConfig(config);

          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: config.firebaseOptions.toFirebaseOptions(),
            );
            _initializedConfigVersion = config.configVersion;
          } else if (_isSameRuntimeConfig(previousConfigVersion, config)) {
            _initializedConfigVersion = config.configVersion;
          } else {
            const message =
                'Firebase mobile config changed and will apply on next cold start.';
            await _rememberLastInitError(message);
            return MobilePushInitResult.pendingRestart(
              platform: platform,
              configVersion: config.configVersion,
              message: message,
            );
          }
        }
      } else {
        // No cached config available — fetch remote config as before.
        final config = await fetchMobileConfig(platform: platform);
        await _cacheConfig(config);

        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: config.firebaseOptions.toFirebaseOptions(),
          );
          _initializedConfigVersion = config.configVersion;
        } else if (_isSameRuntimeConfig(previousConfigVersion, config)) {
          _initializedConfigVersion = config.configVersion;
        } else {
          const message =
              'Firebase mobile config changed and will apply on next cold start.';
          await _rememberLastInitError(message);
          return MobilePushInitResult.pendingRestart(
            platform: platform,
            configVersion: config.configVersion,
            message: message,
          );
        }
      }

      await _clearLastInitError();
      _startListeners();

      try {
        await getCurrentToken();
      } catch (error) {
        await _rememberLastInitError(_safeError(error));
      }

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(
          MobilePushMessageMapper.fromRemoteMessage(initialMessage),
        );
      }

      return MobilePushInitResult.initialized(
        platform: platform,
        configVersion: _initializedConfigVersion ??
            _localCache.getString(StorageKeys.mobilePushFirebaseConfigVersion),
      );
    } catch (error) {
      final message = _safeError(error);
      await _rememberLastInitError(message);
      return MobilePushInitResult.failed(
        platform: platform,
        message: message,
      );
    }
  }

  bool _isSameRuntimeConfig(
    String? previousConfigVersion,
    MobileFcmConfigResponse config,
  ) {
    final nextVersion = config.configVersion.trim();
    if (nextVersion.isEmpty) {
      return previousConfigVersion == null || previousConfigVersion.isEmpty;
    }

    return previousConfigVersion == nextVersion;
  }

  Future<void> _rememberPermissionStatus(NotificationSettings settings) async {
    await _localCache.setString(
      StorageKeys.mobilePushLastPermissionStatus,
      settings.authorizationStatus.name,
    );
  }

  void _startListeners() {
    if (_listenersStarted) {
      return;
    }

    _listenersStarted = true;
    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen(
      _handleTokenRefresh,
      onError: (Object error) {
        unawaited(_rememberLastInitError(_safeError(error)));
      },
    );
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      (message) {
        unawaited(_safeHandleForegroundMessage(message));
      },
      onError: (Object error) {
        unawaited(_rememberLastInitError(_safeError(error)));
      },
    );
    _notificationTapSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        unawaited(_safeHandleNotificationTap(message));
      },
      onError: (Object error) {
        unawaited(_rememberLastInitError(_safeError(error)));
      },
    );
  }

  Future<void> _handleTokenRefresh(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) {
      return;
    }

    await _localCache.setString(StorageKeys.mobilePushFcmToken, normalized);
    _tokenRefreshController.add(normalized);
  }

  Future<void> _safeHandleForegroundMessage(RemoteMessage message) async {
    try {
      await _handleForegroundMessage(message);
    } catch (error) {
      await _rememberLastInitError(_safeError(error));
    }
  }

  Future<void> _safeHandleNotificationTap(RemoteMessage message) async {
    try {
      await _handleNotificationTap(
        MobilePushMessageMapper.fromRemoteMessage(message),
      );
    } catch (error) {
      await _rememberLastInitError(_safeError(error));
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    MobilePushMessage? mappedMessage;
    try {
      mappedMessage = MobilePushMessageMapper.fromRemoteMessage(message);
      _foregroundMessageController.add(mappedMessage);
    } catch (error) {
      await _rememberLastInitError(_safeError(error));
      return;
    }

    try {
      await _localNotifications.showForegroundMessage(mappedMessage);
    } catch (error) {
      await _rememberLastInitError(_safeError(error));
      // Continue — notification center refresh must still run.
    }

    try {
      final refreshHook = _notificationCenterRefreshHook;
      if (refreshHook != null) {
        await Future<void>.sync(() => refreshHook(mappedMessage!));
      }
    } catch (error) {
      await _rememberLastInitError(_safeError(error));
    }
  }

  Future<void> _handleNotificationTap(MobilePushMessage message) async {
    _notificationTapController.add(message);

    final handler = _navigationHandler;
    if (handler != null) {
      await Future<void>.sync(() => handler(message));
    }
  }

  Future<bool> _registerToken(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return false;
    }

    final session = await _tokenStorage.getActiveSession();
    if (session == null) {
      return false;
    }

    try {
      final platform = MobilePushPlatform.fromCurrentPlatform();
      if (!platform.isSupported) {
        return false;
      }

      final deviceId = await _getOrCreateDeviceId();
      final userAgent = await _buildUserAgent(platform);
      final request = RegisterPushTokenRequest(
        token: normalizedToken,
        platform: platform,
        deviceId: deviceId,
        userAgent: userAgent,
      );

      mobilePushPerfLog('register_token start');
      await _apiClient.post<bool>(
        ApiEndpoints.auth.pushToken,
        data: request.toJson(),
        options: _mobilePushApiOptions(),
        parser: (_) => true,
      );
      mobilePushPerfLog('register_token ok');

      await _localCache.setString(
        StorageKeys.mobilePushFcmToken,
        normalizedToken,
      );
      await _localCache.setString(
        StorageKeys.mobilePushRegisteredToken,
        normalizedToken,
      );
      await _localCache.setString(
        StorageKeys.mobilePushRegisteredUserId,
        session.user.id,
      );
      await _localCache.setString(
        StorageKeys.mobilePushRegisteredPlatform,
        platform.apiValue,
      );
      return true;
    } catch (error) {
      mobilePushPerfLog('register_token fail');
      await _rememberLastInitError(_safeError(error));
      return false;
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _readStoredDeviceId();
    if (existing != null) {
      return existing;
    }

    final generated = const Uuid().v4();
    try {
      await _secureStorage.write(
        key: StorageKeys.mobilePushDeviceId,
        value: generated,
      );
    } catch (_) {
      // Secure storage unavailable; persist to local cache as fallback.
      await _localCache.setString(StorageKeys.mobilePushDeviceId, generated);
    }
    return generated;
  }

  Future<String?> _readStoredDeviceId() async {
    // Try secure storage first.
    try {
      final secureValue =
          (await _secureStorage.read(key: StorageKeys.mobilePushDeviceId))
              ?.trim();
      if (secureValue != null && secureValue.isNotEmpty) {
        return secureValue;
      }
    } catch (_) {
      // Keystore unavailable or corrupted; attempt to clear the bad entry.
      try {
        await _secureStorage.delete(key: StorageKeys.mobilePushDeviceId);
      } catch (_) {
        // Ignore — deletion is best-effort cleanup only.
      }
    }

    // Fall back to local cache (set during migration or previous write).
    final cachedValue =
        _localCache.getString(StorageKeys.mobilePushDeviceId)?.trim();
    if (cachedValue != null && cachedValue.isNotEmpty) {
      // Best-effort re-persist to secure storage; failure is non-fatal.
      try {
        await _secureStorage.write(
          key: StorageKeys.mobilePushDeviceId,
          value: cachedValue,
        );
      } catch (_) {
        // Secure storage unavailable; caller will use the cached value.
      }
      return cachedValue;
    }

    return null;
  }

  Future<String> _buildUserAgent(MobilePushPlatform platform) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appPart = '${packageInfo.packageName}/${packageInfo.version}'
        '+${packageInfo.buildNumber}';
    final devicePart = await _deviceDescription(platform);
    return '$appPart (${platform.apiValue}; $devicePart)';
  }

  Future<String> _deviceDescription(MobilePushPlatform platform) async {
    try {
      switch (platform) {
        case MobilePushPlatform.android:
          final info = await _deviceInfoPlugin.androidInfo;
          return _joinNonEmpty([
            info.manufacturer,
            info.model,
            'sdk ${info.version.sdkInt}',
          ]);
        case MobilePushPlatform.ios:
          final info = await _deviceInfoPlugin.iosInfo;
          return _joinNonEmpty([
            info.model,
            info.utsname.machine,
            info.systemName,
            info.systemVersion,
          ]);
        case MobilePushPlatform.unsupported:
          return 'unsupported';
      }
    } catch (_) {
      return 'unknown device';
    }
  }

  Future<void> _cacheConfig(MobileFcmConfigResponse config) async {
    await _localCache.setString(
      StorageKeys.mobilePushFirebaseConfigJson,
      jsonEncode(config.toJson()),
    );
    await _localCache.setString(
      StorageKeys.mobilePushFirebaseConfigVersion,
      config.configVersion,
    );
  }

  Future<void> _clearRegisteredTokenState() async {
    await _localCache.remove(StorageKeys.mobilePushRegisteredToken);
    await _localCache.remove(StorageKeys.mobilePushRegisteredUserId);
    await _localCache.remove(StorageKeys.mobilePushRegisteredPlatform);
  }

  Future<void> _rememberLastInitError(String message) async {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      return;
    }
    await _localCache.setString(
      StorageKeys.mobilePushLastInitError,
      normalized,
    );
  }

  Future<void> _clearLastInitError() async {
    await _localCache.remove(StorageKeys.mobilePushLastInitError);
  }

  String _safeError(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'Mobile push operation failed.';
    }
    return message.length > 300 ? message.substring(0, 300) : message;
  }
}

String? _firstNonEmpty(Iterable<dynamic> values) {
  for (final value in values) {
    final normalized = value?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }

  return null;
}

String? _last10(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized.length <= 10) {
    return normalized;
  }

  return normalized.substring(normalized.length - 10);
}

String _joinNonEmpty(Iterable<dynamic> values) {
  return values
      .map((value) => value?.toString().trim())
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .join(' ');
}

String? _extractMessage(dynamic json) {
  if (json is Map<String, dynamic>) {
    final message = json['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final data = json['data'];
    if (!identical(data, json)) {
      return _extractMessage(data);
    }
  }

  if (json is Map) {
    return _extractMessage(
      json.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  if (json is String && json.trim().isNotEmpty) {
    return json.trim();
  }

  return null;
}
