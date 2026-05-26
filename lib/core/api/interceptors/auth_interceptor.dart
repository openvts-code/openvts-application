import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var token = _tokenStorage.cachedActiveAccessToken;
    if (token == null && !_tokenStorage.isCacheHydrated) {
      await _tokenStorage.hydrateCache();
      token = _tokenStorage.cachedActiveAccessToken;
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
