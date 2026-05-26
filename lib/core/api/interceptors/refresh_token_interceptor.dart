import 'dart:convert';

import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../../storage/token_storage.dart';
import '../api_endpoints.dart';

class RefreshTokenInterceptor extends QueuedInterceptor {
  RefreshTokenInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
  })  : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (statusCode != 401 || alreadyRetried) {
      handler.next(err);
      return;
    }

    final activeSession = await _tokenStorage.getActiveSession();
    if (activeSession == null) {
      handler.next(err);
      return;
    }

    final refreshToken = activeSession.refreshToken.trim();
    if (refreshToken.isEmpty) {
      await _tokenStorage.clearSessionForRole(activeSession.role);
      handler.next(err);
      return;
    }

    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _runtimeBaseUrl(err.requestOptions),
          connectTimeout:
              const Duration(seconds: AppConfig.connectTimeoutSeconds),
          receiveTimeout:
              const Duration(seconds: AppConfig.receiveTimeoutSeconds),
        ),
      );

      final refreshResponse = await refreshDio.post<dynamic>(
        ApiEndpoints.auth.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final data = refreshResponse.data;
      String? newAccessToken;
      String? newRefreshToken;

      if (data is Map<String, dynamic>) {
        final envelope = data['data'];
        final payload =
            envelope is Map<String, dynamic> && envelope.containsKey('data')
                ? envelope['data']
                : envelope;

        if (payload is Map<String, dynamic>) {
          newAccessToken = payload['token']?.toString() ??
              payload['accessToken']?.toString() ??
              payload['access_token']?.toString();
          newRefreshToken = payload['refresh_token']?.toString() ??
              payload['refreshToken']?.toString() ??
              refreshToken;
        }
      }

      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _tokenStorage.clearSessionForRole(activeSession.role);
        handler.next(err);
        return;
      }

      final normalizedNewRefreshToken = newRefreshToken?.trim();
      final effectiveRefreshToken =
          normalizedNewRefreshToken == null || normalizedNewRefreshToken.isEmpty
              ? refreshToken
              : normalizedNewRefreshToken;

      await _tokenStorage.saveSessionForRole(
        role: activeSession.role,
        accessToken: newAccessToken,
        refreshToken: effectiveRefreshToken,
        currentUserJson: jsonEncode(activeSession.user.toJson()),
      );

      final requestOptions = err.requestOptions;
      requestOptions.extra['retried'] = true;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final clonedResponse = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(clonedResponse);
    } catch (_) {
      await _tokenStorage.clearSessionForRole(activeSession.role);
      handler.next(err);
    }
  }

  String _runtimeBaseUrl(RequestOptions requestOptions) {
    final requestBaseUrl = requestOptions.baseUrl.trim();
    if (requestBaseUrl.isNotEmpty) {
      return requestBaseUrl;
    }

    final dioBaseUrl = _dio.options.baseUrl.trim();
    if (dioBaseUrl.isNotEmpty) {
      return dioBaseUrl;
    }

    return AppConfig.apiBaseUrl;
  }
}
