import 'package:dio/dio.dart';

class SafeLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // Keep logging minimal. Never print tokens or passwords.
      // ignore: avoid_print
      print('[API] ${options.method} ${options.uri}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ${response.statusCode} ${response.requestOptions.uri}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      final statusCode = err.response?.statusCode;
      final prefix = statusCode == null ? '[API] ERROR' : '[API] $statusCode';
      final message = err.message?.trim();
      final suffix = message == null || message.isEmpty ? err.type.name : '${err.type.name}: $message';
      // ignore: avoid_print
      print('$prefix ${err.requestOptions.uri} ($suffix)');
      return true;
    }());
    handler.next(err);
  }
}
