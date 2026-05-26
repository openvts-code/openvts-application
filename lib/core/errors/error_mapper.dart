import 'package:dio/dio.dart';

import 'app_error.dart';

class ErrorMapper {
  const ErrorMapper._();

  static AppError from(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      String message = 'Something went wrong';

      if (responseData is Map<String, dynamic>) {
        message = responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            message;
      } else if (error.message != null) {
        message = error.message!;
      }

      return AppError(
        message: message,
        code: statusCode?.toString(),
        originalError: error,
      );
    }

    return AppError(
      message: error.toString(),
      originalError: error,
    );
  }
}
