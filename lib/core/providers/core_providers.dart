import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../api/interceptors/auth_interceptor.dart';
import '../api/interceptors/error_interceptor.dart';
import '../api/interceptors/logging_interceptor.dart';
import '../api/interceptors/refresh_token_interceptor.dart';
import '../config/app_config.dart';
import '../notifications/mobile_push_controller.dart';
import '../notifications/mobile_push_service.dart';
import '../notifications/mobile_push_state.dart';
import '../providers/shared_preferences_provider.dart';
import '../socket/socket_service.dart';
import '../storage/local_cache.dart';
import '../storage/storage_keys.dart';
import '../storage/token_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

final localCacheProvider = Provider<LocalCache>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalCache(prefs);
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.watch(localCacheProvider));
});

final apiBaseUrlProvider =
    StateNotifierProvider<ApiBaseUrlController, String>((ref) {
  return ApiBaseUrlController(ref.watch(localCacheProvider));
});

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: AppConfig.connectTimeoutSeconds),
      receiveTimeout: const Duration(seconds: AppConfig.receiveTimeoutSeconds),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(_BodylessDeleteContentTypeInterceptor());

  final tokenStorage = ref.watch(tokenStorageProvider);
  dio.interceptors.add(AuthInterceptor(tokenStorage));
  dio.interceptors.add(
    RefreshTokenInterceptor(
      dio: dio,
      tokenStorage: tokenStorage,
    ),
  );
  dio.interceptors.add(ApiErrorInterceptor());
  dio.interceptors.add(SafeLoggingInterceptor());

  return dio;
});

class _BodylessDeleteContentTypeInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() == 'DELETE' && options.data == null) {
      options.headers.remove(Headers.contentTypeHeader);
      options.headers.remove('content-type');
      options.contentType = null;
    }

    handler.next(options);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

final mobilePushServiceProvider = Provider<MobilePushService>((ref) {
  final service = MobilePushService(
    apiClient: ref.watch(apiClientProvider),
    localCache: ref.watch(localCacheProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final mobilePushControllerProvider =
    StateNotifierProvider<MobilePushController, MobilePushState>((ref) {
  return MobilePushController(
    service: ref.watch(mobilePushServiceProvider),
    localCache: ref.watch(localCacheProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService(
    ref.watch(tokenStorageProvider),
    apiBaseUrl: ref.watch(apiBaseUrlProvider),
  );
});

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._localCache) : super(_initialValue(_localCache));

  final LocalCache _localCache;

  static ThemeMode _initialValue(LocalCache localCache) {
    switch (localCache.getString(StorageKeys.themeMode)) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final normalizedMode =
        mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    await _localCache.setString(
      StorageKeys.themeMode,
      normalizedMode == ThemeMode.dark ? 'dark' : 'light',
    );
    state = normalizedMode;
  }

  Future<void> toggle() {
    return setThemeMode(
      state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}

class ApiBaseUrlController extends StateNotifier<String> {
  ApiBaseUrlController(this._localCache) : super(_initialValue(_localCache));

  final LocalCache _localCache;

  static String _initialValue(LocalCache localCache) {
    final overrideValue = localCache.getString(StorageKeys.apiBaseUrlOverride);
    if (overrideValue != null && overrideValue.trim().isNotEmpty) {
      return _normalizeUrl(overrideValue);
    }

    return _normalizeUrl(AppConfig.apiBaseUrl);
  }

  String get defaultUrl => _normalizeUrl(AppConfig.apiBaseUrl);

  bool get isUsingDefault => state == defaultUrl;

  Future<void> saveCustomUrl(String value) async {
    final normalizedValue = _normalizeUrl(value);
    await _localCache.setString(
        StorageKeys.apiBaseUrlOverride, normalizedValue);
    state = normalizedValue;
  }

  Future<void> resetToDefault() async {
    await _localCache.remove(StorageKeys.apiBaseUrlOverride);
    state = defaultUrl;
  }

  static String normalizeUrl(String value) {
    return _normalizeUrl(value);
  }

  static String _normalizeUrl(String value) {
    return value.trim().replaceAll(RegExp(r'/+$'), '');
  }
}
