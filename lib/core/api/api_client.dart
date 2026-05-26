import 'package:dio/dio.dart';

import '../performance/open_vts_perf.dart';
import 'api_exception.dart';
import 'api_response.dart';

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    required T Function(dynamic json) parser,
  }) {
    return OpenVtsPerf.traceAsync(_apiPerfLabel('GET', endpoint), () async {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse(response, parser);
    });
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    required T Function(dynamic json) parser,
  }) {
    return OpenVtsPerf.traceAsync(_apiPerfLabel('POST', endpoint), () async {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse(response, parser);
    });
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Options? options,
    required T Function(dynamic json) parser,
  }) {
    return OpenVtsPerf.traceAsync(_apiPerfLabel('PUT', endpoint), () async {
      final response = await _dio.put<dynamic>(
        endpoint,
        data: data,
        options: options,
      );
      return _parseResponse(response, parser);
    });
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    required T Function(dynamic json) parser,
  }) {
    return OpenVtsPerf.traceAsync(_apiPerfLabel('PATCH', endpoint), () async {
      final response = await _dio.patch<dynamic>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse(response, parser);
    });
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Options? options,
    required T Function(dynamic json) parser,
  }) {
    return OpenVtsPerf.traceAsync(_apiPerfLabel('DELETE', endpoint), () async {
      final response = await _dio.delete<dynamic>(
        endpoint,
        data: data,
        options: options,
      );
      return _parseResponse(response, parser);
    });
  }

  String _apiPerfLabel(String method, String endpoint) {
    return 'api.$method ${_safeEndpointForPerf(endpoint)}';
  }

  String _safeEndpointForPerf(String endpoint) {
    final normalized = endpoint.trim();
    if (normalized.isEmpty) {
      return '/';
    }

    final parsed = Uri.tryParse(normalized);
    final path = parsed?.path.trim();
    if (path != null && path.isNotEmpty) {
      return path.startsWith('/') ? path : '/$path';
    }

    final withoutQuery = normalized.split('?').first.split('#').first.trim();
    if (withoutQuery.isEmpty) {
      return '/';
    }

    return withoutQuery.startsWith('/') ? withoutQuery : '/$withoutQuery';
  }

  ApiResponse<T> _parseResponse<T>(
    Response<dynamic> response,
    T Function(dynamic json) parser,
  ) {
    final data = response.data;
    if (data is Map<String, dynamic> && _looksLikeEnvelope(data)) {
      try {
        final apiResponse = ApiResponse<T>.fromJson(data, parser);
        if (apiResponse.success) {
          return apiResponse;
        }
      } catch (_) {
        // Fall through to the implicit envelope path below.
      }

      if (_canUseImplicitEnvelope(data, response.statusCode)) {
        try {
          return ApiResponse<T>(
            success: true,
            data: parser(_extractEnvelopePayload(data)),
            message: _extractMessage(data),
          );
        } catch (_) {
          throw ApiException(
            message: 'Invalid API response format',
            statusCode: response.statusCode,
            details: data,
          );
        }
      }

      final apiResponse = ApiResponse<T>.fromJson(data, parser);
      throw ApiException(
        message: apiResponse.message ?? 'Request failed',
        statusCode: response.statusCode,
        details: data,
      );
    }

    try {
      return ApiResponse<T>(
        success: _isSuccessStatusCode(response.statusCode),
        data: parser(data),
        message: _extractMessage(data),
      );
    } catch (_) {
      throw ApiException(
        message: 'Invalid API response format',
        statusCode: response.statusCode,
        details: data,
      );
    }
  }

  bool _looksLikeEnvelope(Map<String, dynamic> data) {
    if (data.containsKey('data') ||
        data.containsKey('success') ||
        data['action'] is bool ||
        data.containsKey('timestamp')) {
      return true;
    }

    final status = data['status']?.toString().trim().toLowerCase();
    return status == 'success' ||
        status == 'ok' ||
        status == 'error' ||
        status == 'failed' ||
        status == 'fail';
  }

  bool _canUseImplicitEnvelope(Map<String, dynamic> data, int? statusCode) {
    if (!data.containsKey('data') || !_isSuccessStatusCode(statusCode)) {
      return false;
    }

    final status = data['status']?.toString().trim().toLowerCase();
    if (status == 'error' || status == 'failed' || status == 'fail') {
      return false;
    }

    if (data['success'] == false) {
      return false;
    }

    if (data['action'] == false) {
      return false;
    }

    final envelope = _asMap(data['data']);
    if (envelope['action'] == false) {
      return false;
    }

    return true;
  }

  dynamic _extractEnvelopePayload(Map<String, dynamic> data) {
    final envelope = data['data'];
    final envelopeMap = _asMap(envelope);

    if (envelopeMap.containsKey('data')) {
      return envelopeMap['data'];
    }

    return envelope;
  }

  bool _isSuccessStatusCode(int? statusCode) {
    if (statusCode == null) {
      return true;
    }

    return statusCode >= 200 && statusCode < 300;
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final envelope = _asMap(data['data']);
      final nestedMessage = envelope['message']?.toString().trim();
      if (nestedMessage != null && nestedMessage.isNotEmpty) {
        return nestedMessage;
      }

      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    if (data is String) {
      final message = data.trim();
      if (message.isNotEmpty) {
        return message;
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
}
