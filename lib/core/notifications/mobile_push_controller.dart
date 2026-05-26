import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../config/app_config.dart';
import '../performance/open_vts_perf.dart';
import '../storage/local_cache.dart';
import '../storage/storage_keys.dart';
import '../storage/token_storage.dart';
import 'mobile_push_message_mapper.dart';
import 'mobile_push_perf.dart';
import 'mobile_push_platform.dart';
import 'mobile_push_service.dart';
import 'mobile_push_state.dart';

class MobilePushController extends StateNotifier<MobilePushState> {
  MobilePushController({
    required MobilePushService service,
    required LocalCache localCache,
    required TokenStorage tokenStorage,
  })  : _service = service,
        _localCache = localCache,
        _tokenStorage = tokenStorage,
        super(_initialState(localCache)) {
    _tokenRefreshSubscription = _service.tokenRefreshes.listen(
      (token) => unawaited(handleTokenRefresh(token)),
      onError: (Object error) => unawaited(_rememberError(_safeError(error))),
    );
    _foregroundMessageSubscription = _service.foregroundMessages.listen(
      (message) => unawaited(handleForegroundMessage(message)),
      onError: (Object error) => unawaited(_rememberError(_safeError(error))),
    );
    _notificationTapSubscription = _service.notificationTaps.listen(
      (message) => unawaited(handleNotificationTap(message)),
      onError: (Object error) => unawaited(_rememberError(_safeError(error))),
    );
  }

  static const _registrationCooldown = Duration(seconds: 45);

  final MobilePushService _service;
  final LocalCache _localCache;
  final TokenStorage _tokenStorage;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<MobilePushMessage>? _foregroundMessageSubscription;
  StreamSubscription<MobilePushMessage>? _notificationTapSubscription;
  Future<void>? _coreInitialization;
  Future<String?>? _testNotificationInFlight;
  DateTime? _lastRegistrationAttemptAt;
  bool _didRunAfterAppStart = false;
  bool _registrationInFlight = false;
  bool _authAllowsRegistration = false;

  static MobilePushState _initialState(LocalCache localCache) {
    final platform = MobilePushPlatform.fromCurrentPlatform();
    final permissionStatus = localCache.getString(
      StorageKeys.mobilePushLastPermissionStatus,
    );

    return MobilePushState.initial(
      isSupported: platform.isSupported && !AppConfig.useMockData,
      platform: platform,
      permissionStatus: AppConfig.useMockData ? 'disabled' : permissionStatus,
      fcmTokenLast10: _last10(
        localCache.getString(StorageKeys.mobilePushFcmToken),
      ),
      registeredTokenLast10: _last10(
        localCache.getString(StorageKeys.mobilePushRegisteredToken),
      ),
      configVersion: localCache.getString(
        StorageKeys.mobilePushFirebaseConfigVersion,
      ),
      lastError: localCache.getString(StorageKeys.mobilePushLastInitError),
    );
  }

  void updateAuthenticationState({required bool isAuthenticated}) {
    _authAllowsRegistration = isAuthenticated;
  }

  Future<void> initializeCore() {
    if (_coreInitialization != null) {
      return _coreInitialization!;
    }
    if (state.isInitialized) {
      return Future<void>.value();
    }

    _coreInitialization = _initializeCoreInternal().whenComplete(() {
      _coreInitialization = null;
    });
    return _coreInitialization!;
  }

  Future<void> initializeAfterAppStart() async {
    if (_didRunAfterAppStart) {
      return;
    }

    _didRunAfterAppStart = true;
    // Hydrate cached push state only at cold app start. Avoid network calls
    // such as fetching mobile config here so startup/login/home rendering
    // isn't competed with background network work. Full initialization
    // (which may fetch `/auth/fcm-mobile-config`) runs only when a
    // registration attempt is explicitly required.
    await OpenVtsPerf.traceAsync('push.hydrateCachedState', () async {
      _syncCachedState();
    });
  }

  Future<void> requestPermissionAndRegisterForCurrentSession() async {
    if (!_canUsePush || !_authAllowsRegistration) {
      return;
    }

    if (await _tokenStorage.getActiveSession() == null) {
      return;
    }

    await initializeCore();
    if (!_service.hasFirebaseApp) {
      return;
    }

    try {
      final settings = await _service.requestNotificationPermission();
      if (settings == null) {
        return;
      }

      _applyPermissionSettings(settings);
      if (_isGranted(settings.authorizationStatus)) {
        await _registerTokenForCurrentSession(force: true);
      }
    } catch (error) {
      await _rememberError(_safeError(error));
    }
  }

  Future<bool> registerTokenForCurrentSession() {
    if (!shouldAttemptBackgroundRegistration) {
      return Future<bool>.value(false);
    }

    return OpenVtsPerf.traceAsync(
      'push.registerToken',
      _registerTokenForCurrentSession,
    );
  }

  Future<bool> deregisterCurrentToken() async {
    if (!_canUsePush || !_authAllowsRegistration) {
      return false;
    }
    if (await _tokenStorage.getActiveSession() == null) {
      return false;
    }

    try {
      final removed = await _service.deregisterToken();
      _syncCachedState();
      if (!removed) {
        await _rememberError(
          _cachedError() ?? 'Push token deregistration failed.',
        );
        return false;
      }

      await clearError();
      return true;
    } catch (error) {
      await _rememberError(_safeError(error));
      _syncCachedState();
      return false;
    }
  }

  Future<void> handleTokenRefresh(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) {
      return;
    }

    await _localCache.setString(StorageKeys.mobilePushFcmToken, normalized);
    _syncCachedState(fcmToken: normalized);

    // Attempt background registration only when the full set of gating
    // criteria are met. Otherwise, hydrate cache and defer registration
    // until the user explicitly tests mobile push or opens Notification
    // Settings.
    if (_authAllowsRegistration && shouldAttemptBackgroundRegistration) {
      await _registerTokenForCurrentSession(token: normalized, force: true);
    }
  }

  Future<void> handleForegroundMessage(MobilePushMessage message) {
    _syncCachedState();
    return Future<void>.value();
  }

  Future<void> handleNotificationTap(MobilePushMessage message) {
    _syncCachedState();
    return Future<void>.value();
  }

  Future<void> refreshPermissionStatus() async {
    if (!_canUsePush || !_service.hasFirebaseApp) {
      _syncCachedState();
      return;
    }

    try {
      final settings = await _service.getNotificationSettings();
      if (settings != null) {
        _applyPermissionSettings(settings);
      }
    } catch (error) {
      await _rememberError(_safeError(error));
    }
  }

  Future<void> refreshTokenDiagnostics() async {
    if (!_canUsePush) {
      _emit(
        state.copyWith(
          registeredTokenCount: null,
          currentTokenVerifiedByBackend: null,
          tokenDiagnosticsUpdatedAt: null,
        ),
      );
      return;
    }

    try {
      final diagnostics = await _service.fetchMyRegisteredTokens();
      _emit(
        state.copyWith(
          registeredTokenCount: diagnostics.activeCount,
          currentTokenVerifiedByBackend: diagnostics.currentTokenRegistered,
          tokenDiagnosticsUpdatedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      _syncCachedState();
    }
  }

  Future<String?> sendTestNotification() {
    final inFlight = _testNotificationInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final operation = _sendTestNotificationInternal().whenComplete(() {
      _testNotificationInFlight = null;
    });
    _testNotificationInFlight = operation;
    return operation;
  }

  Future<String?> _sendTestNotificationInternal() async {
    _emit(
      state.copyWith(
        isTesting: true,
        testStep: MobilePushTestStep.idle,
        lastError: null,
      ),
    );

    try {
      final platform = MobilePushPlatform.fromCurrentPlatform();
      if (AppConfig.useMockData || !platform.isSupported) {
        await _rememberTestFailure(
          'Mobile push is not supported on this platform.',
        );
        return null;
      }

      final session = await _tokenStorage.getActiveSession();
      if (session == null) {
        await _rememberTestFailure(
          'Sign in before sending a mobile push test.',
        );
        return null;
      }

      _setTestStep(MobilePushTestStep.initializingFirebase);
      await initializeCore();
      if (!_service.hasFirebaseApp) {
        await _rememberTestFailure(
          'Firebase mobile push is not initialized. Check Firebase Android/iOS config.',
        );
        return null;
      }

      _setTestStep(MobilePushTestStep.checkingPermission);
      final permissionGranted = await _ensurePermissionForTest();
      if (!permissionGranted) {
        _setTestStep(MobilePushTestStep.failed);
        return null;
      }

      _setTestStep(MobilePushTestStep.generatingToken);
      final token = (await _service.getCurrentToken())?.trim();
      if (token == null || token.isEmpty) {
        _syncCachedState();
        await _rememberTestFailure(
          'Unable to generate FCM token for this device.',
        );
        return null;
      }

      _syncCachedState(fcmToken: token);
      _setTestStep(MobilePushTestStep.registeringToken);
      final registered = await _registerTokenForCurrentSession(
        token: token,
        force: true,
      );
      _syncCachedState(fcmToken: token);

      if (!registered && !_isAlreadyRegisteredForSession(token, session)) {
        await _rememberTestFailure(
          'FCM token generated but backend registration failed.',
        );
        return null;
      }

      _setTestStep(MobilePushTestStep.verifyingBackendToken);
      await refreshTokenDiagnostics();
      _setTestStep(MobilePushTestStep.sendingBackendTest);
      final message = await _service.sendTestNotification();
      _syncCachedState(fcmToken: token);
      _setTestStep(MobilePushTestStep.verifyingBackendToken);
      await refreshTokenDiagnostics();
      await clearError();
      _setTestStep(MobilePushTestStep.completed);
      return message;
    } catch (error, stackTrace) {
      assert(() {
        stackTrace.toString();
        return true;
      }());
      await _rememberTestFailure(_mobilePushTestErrorMessage(error));
      return null;
    } finally {
      _emit(state.copyWith(isTesting: false));
    }
  }

  Future<bool> _ensurePermissionForTest() async {
    try {
      final currentSettings = await _service.getNotificationSettings();
      if (currentSettings != null) {
        _applyPermissionSettings(currentSettings);
      }

      if (state.isPermissionGranted) {
        return true;
      }

      final requestedSettings = await _service.requestNotificationPermission();
      if (requestedSettings != null) {
        _applyPermissionSettings(requestedSettings);
      }

      if (state.isPermissionGranted) {
        return true;
      }
    } catch (_) {
      // Fall through to the same actionable permission error below.
    }

    await _rememberError(
      'Notification permission is not granted. Enable notifications for this app and try again.',
    );
    return false;
  }

  Future<void> clearError() async {
    await _localCache.remove(StorageKeys.mobilePushLastInitError);
    _emit(state.copyWith(lastError: null));
  }

  Future<void> _initializeCoreInternal() async {
    mobilePushPerfLog('push_init start');
    final platform = MobilePushPlatform.fromCurrentPlatform();
    if (AppConfig.useMockData || !platform.isSupported) {
      _emit(
        state.copyWith(
          isSupported: false,
          isInitialized: false,
          isInitializing: false,
          isPermissionGranted: false,
          permissionStatus: AppConfig.useMockData ? 'disabled' : 'unsupported',
          platform: platform,
          lastError: null,
          pendingReinitializeOnNextLaunch: false,
        ),
      );
      return;
    }

    _emit(
      state.copyWith(
        isSupported: true,
        isInitializing: true,
        platform: platform,
        lastError: null,
      ),
    );

    final result = await _service.initialize();
    final pendingRestart = result.status == MobilePushInitStatus.pendingRestart;
    final initialized = result.status == MobilePushInitStatus.initialized ||
        (pendingRestart && _service.hasFirebaseApp);
    final failed = result.status == MobilePushInitStatus.failed;

    _emit(
      state.copyWith(
        isSupported: result.platform.isSupported,
        isInitialized: initialized,
        isInitializing: false,
        platform: result.platform,
        configVersion: result.configVersion ??
            _localCache.getString(StorageKeys.mobilePushFirebaseConfigVersion),
        lastError: failed || pendingRestart ? result.message : null,
        pendingReinitializeOnNextLaunch: pendingRestart,
      ),
    );
    _syncCachedState();
    mobilePushPerfLog(
      failed
          ? 'push_init fail'
          : pendingRestart
              ? 'push_init pending_restart'
              : 'push_init ok',
    );
  }

  Future<bool> _registerTokenForCurrentSession({
    String? token,
    bool force = false,
  }) async {
    if (!_canUsePush) {
      _syncCachedState(fcmToken: token);
      return false;
    }

    final session = await _tokenStorage.getActiveSession();
    if (session == null) {
      return false;
    }

    await initializeCore();
    if (!_service.hasFirebaseApp) {
      return false;
    }

    final tokenToRegister = _firstNonEmpty([
      token,
      await _service.getCurrentToken(),
      _localCache.getString(StorageKeys.mobilePushFcmToken),
    ]);
    if (tokenToRegister == null) {
      _syncCachedState();
      return false;
    }

    _syncCachedState(fcmToken: tokenToRegister);
    if (_isAlreadyRegisteredForSession(tokenToRegister, session)) {
      // Already registered for this session/device. Do NOT fetch diagnostics
      // here — that runs only when the Notification Settings/Diagnostics card
      // is opened or when the Test Mobile Push flow validates registration.
      return true;
    }
    if (_registrationInFlight || _isRegistrationCooldownActive(force: force)) {
      return false;
    }

    _registrationInFlight = true;
    _lastRegistrationAttemptAt = DateTime.now();

    try {
      final registered = await _service.registerCurrentToken(
        token: tokenToRegister,
      );
      _syncCachedState(fcmToken: tokenToRegister);
      if (registered) {
        _lastRegistrationAttemptAt = null;
        await clearError();
        // Diagnostics fetch intentionally omitted on the hot startup path.
        // It runs only from Notification Settings/Diagnostics or Test Push.
        return true;
      }

      await _rememberError('Push token registration failed.');
      return false;
    } catch (error) {
      await _rememberError('Push token registration failed.');
      return false;
    } finally {
      _registrationInFlight = false;
    }
  }

  bool _isAlreadyRegisteredForSession(String token, RoleSession session) {
    final registeredToken = _localCache.getString(
      StorageKeys.mobilePushRegisteredToken,
    );
    final registeredUserId = _localCache.getString(
      StorageKeys.mobilePushRegisteredUserId,
    );
    final registeredPlatform = _localCache.getString(
      StorageKeys.mobilePushRegisteredPlatform,
    );

    return registeredToken == token &&
        registeredUserId == session.user.id &&
        registeredPlatform == state.platform.apiValue;
  }

  bool _isRegistrationCooldownActive({required bool force}) {
    if (force) {
      return false;
    }
    final lastAttempt = _lastRegistrationAttemptAt;
    if (lastAttempt == null) {
      return false;
    }

    return DateTime.now().difference(lastAttempt) < _registrationCooldown;
  }

  bool get _canUsePush => state.isSupported && !AppConfig.useMockData;

  /// Whether the controller is allowed to attempt a silent/background
  /// registration without user interaction. This checks local/cached state
  /// only and deliberately avoids any network calls; it is intended to be
  /// evaluated at app start and right after auth/session restore to decide
  /// whether a non-blocking registration should be attempted.
  bool get shouldAttemptBackgroundRegistration {
    final hasCachedConfig = _hasCachedFirebaseConfig;
    final cooldownInactive = !_isRegistrationCooldownActive(force: false);
    final permissionGranted = state.isPermissionGranted;
    final notPendingRestart = !state.pendingReinitializeOnNextLaunch;

    return _authAllowsRegistration &&
        _canUsePush &&
        permissionGranted &&
        hasCachedConfig &&
        notPendingRestart &&
        cooldownInactive;
  }

  bool get _hasCachedFirebaseConfig {
    final cachedConfigVersion = _localCache.getString(
      StorageKeys.mobilePushFirebaseConfigVersion,
    );
    final cachedConfigJson = _localCache.getString(
      StorageKeys.mobilePushFirebaseConfigJson,
    );

    return cachedConfigVersion?.trim().isNotEmpty == true &&
        cachedConfigJson?.trim().isNotEmpty == true;
  }

  void _applyPermissionSettings(NotificationSettings settings) {
    final status = settings.authorizationStatus.name;
    _emit(
      state.copyWith(
        isPermissionGranted: _isGranted(settings.authorizationStatus),
        permissionStatus: status,
      ),
    );
  }

  Future<void> _rememberError(String message) async {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      return;
    }

    await _localCache.setString(
      StorageKeys.mobilePushLastInitError,
      normalized,
    );
    _emit(
      state.copyWith(
        isInitializing: false,
        lastError: normalized,
      ),
    );
  }

  Future<void> _rememberTestFailure(String message) async {
    _setTestStep(MobilePushTestStep.failed);
    await _rememberError(message);
  }

  void _setTestStep(MobilePushTestStep step) {
    _emit(state.copyWith(testStep: step));
  }

  void _syncCachedState({String? fcmToken, String? registeredToken}) {
    _emit(
      state.copyWith(
        fcmTokenLast10: _last10(
          fcmToken ?? _localCache.getString(StorageKeys.mobilePushFcmToken),
        ),
        registeredTokenLast10: _last10(
          registeredToken ??
              _localCache.getString(StorageKeys.mobilePushRegisteredToken),
        ),
        configVersion: _localCache.getString(
          StorageKeys.mobilePushFirebaseConfigVersion,
        ),
      ),
    );
  }

  String? _cachedError() {
    return _localCache.getString(StorageKeys.mobilePushLastInitError);
  }

  String _mobilePushTestErrorMessage(Object error) {
    String? message;

    if (error is ApiException) {
      message = error.message;
    } else if (error is DioException) {
      message = _dioExceptionMessage(error);
    } else if (error is FirebaseException) {
      final code = error.code.trim();
      final firebaseMessage = error.message?.trim();
      message = firebaseMessage == null || firebaseMessage.isEmpty
          ? 'Firebase error: $code.'
          : 'Firebase error: $code. $firebaseMessage';
    } else if (error is StateError) {
      message = error.message;
    } else if (error is Exception) {
      message = error.toString();
    }

    return _sanitizeMobilePushTestError(message);
  }

  String? _dioExceptionMessage(DioException error) {
    final responseData = error.response?.data;
    final root = _asStringKeyMap(responseData);
    final nestedData = _asStringKeyMap(root['data']);

    return _firstNonEmpty([
      nestedData['message'],
      root['message'],
      error.response?.statusMessage,
      error.message,
    ]);
  }

  Map<String, dynamic> _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    return const <String, dynamic>{};
  }

  void _emit(MobilePushState nextState) {
    if (mounted) {
      state = nextState;
    }
  }

  @override
  void dispose() {
    unawaited(_tokenRefreshSubscription?.cancel());
    unawaited(_foregroundMessageSubscription?.cancel());
    unawaited(_notificationTapSubscription?.cancel());
    super.dispose();
  }
}

bool _isGranted(AuthorizationStatus status) {
  return status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;
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

String _safeError(Object error) {
  final message = error.toString().trim();
  if (message.isEmpty) {
    return 'Mobile push operation failed.';
  }
  return message.length > 300 ? message.substring(0, 300) : message;
}

String _sanitizeMobilePushTestError(String? value) {
  var message = value?.trim() ?? '';
  if (message.isEmpty) {
    return 'Unable to send mobile test notification right now.';
  }

  final lower = message.toLowerCase();
  if (lower.contains('serviceaccountjson') ||
      lower.contains('service account json') ||
      lower.contains('service_account_json') ||
      lower.contains('private_key') ||
      lower.contains('privatekey') ||
      lower.contains('private key') ||
      lower.contains('-----begin private key-----')) {
    return 'Notification service credentials are misconfigured.';
  }

  message = message
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceFirst(RegExp(r'^(Exception|StateError):\s*'), '')
      .replaceAll(RegExp(r'[A-Za-z0-9_:-]{40,}'), '[redacted]')
      .trim();

  if (message.isEmpty) {
    return 'Unable to send mobile test notification right now.';
  }

  return message.length > 220 ? message.substring(0, 220) : message;
}
