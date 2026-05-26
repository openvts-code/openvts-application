import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:open_vts/core/api/api_client.dart';
import 'package:open_vts/features/superadmin/services/superadmin_calendar_service.dart';

void main() {
  group('SuperadminCalendarService', () {
    test('maps calendar event filters to backend enum values', () async {
      RequestOptions? capturedRequest;
      final service = SuperadminCalendarService(
        ApiClient(_buildDio((options) {
          capturedRequest = options;
        })),
      );

      final result = await service.getEvents(
        '2026-05-01',
        '2026-05-31',
        const ['users', 'vehicle', 'expiry'],
      );

      expect(result.isSuccess, isTrue);
      expect(
        capturedRequest?.queryParameters['types'],
        'USER_CREATED,VEHICLE_CREATED,VEHICLE_EXPIRY',
      );
    });

    test('maps calendar day filters to backend enum values', () async {
      RequestOptions? capturedRequest;
      final service = SuperadminCalendarService(
        ApiClient(_buildDio((options) {
          capturedRequest = options;
        })),
      );

      final result = await service.getDayDetails(
        '2026-05-15',
        const ['users', 'vehicle', 'expiry'],
      );

      expect(result.isSuccess, isTrue);
      expect(
        capturedRequest?.queryParameters['types'],
        'USER_CREATED,VEHICLE_CREATED,VEHICLE_EXPIRY',
      );
    });
  });
}

Dio _buildDio(void Function(RequestOptions options) onRequest) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: const <dynamic>[],
          ),
        );
      },
    ),
  );
  return dio;
}