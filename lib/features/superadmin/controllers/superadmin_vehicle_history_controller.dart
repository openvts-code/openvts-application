import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../models/superadmin_vehicle_history_model.dart';
import '../services/superadmin_vehicle_service.dart';

class SuperadminVehicleHistoryController
    extends StateNotifier<SuperadminVehicleHistoryState> {
  SuperadminVehicleHistoryController(this._service)
      : super(const SuperadminVehicleHistoryState.initial());

  final SuperadminVehicleService _service;

  Future<void> loadHistory(SuperadminVehicleHistoryRequest request) async {
    state = state.copyWith(
      request: request,
      isLoading: true,
      clearHistory: true,
      clearErrorMessage: true,
    );

    try {
      final history = await _service.getVehicleHistory(request);
      state = state.copyWith(
        request: request,
        history: history,
        isLoading: false,
        clearErrorMessage: true,
      );
    } catch (error) {
      state = state.copyWith(
        request: request,
        isLoading: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> retry() async {
    final request = state.request;
    if (request == null || state.isLoading) {
      return;
    }

    await loadHistory(request);
  }

  void clearHistory() {
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(
      isLoading: false,
      clearHistory: true,
      clearErrorMessage: true,
    );
  }

  String _toErrorMessage(Object error) {
    if (error is ApiException) {
      final message = error.message.trim();
      if (message.isNotEmpty) {
        return message;
      }
    }

    if (error is DioException) {
      final responseMessage = _extractResponseMessage(error.response?.data);
      if (responseMessage != null) {
        return responseMessage;
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The history request timed out. Please try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server right now.';
      }

      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }

    return raw.isEmpty ? 'Unable to load vehicle history.' : raw;
  }

  String? _extractResponseMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in const ['message', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }

        if (value is List) {
          final parts = value
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }

      final nestedData = data['data'];
      if (!identical(nestedData, data)) {
        return _extractResponseMessage(nestedData);
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }
}
