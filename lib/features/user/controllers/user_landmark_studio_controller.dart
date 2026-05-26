import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_landmark_state.dart';
import '../services/user_landmark_service.dart';

/// Optional controller used by the Landmark Studio landing screen to surface
/// quick counts. Failures must never block the landing screen from rendering.
class UserLandmarkStudioController
    extends StateNotifier<UserLandmarkStudioCountsState> {
  UserLandmarkStudioController({required UserLandmarkService service})
      : _service = service,
        super(const UserLandmarkStudioCountsState.initial());

  final UserLandmarkService _service;
  int _requestSerial = 0;

  Future<void> load() async {
    final serial = ++_requestSerial;
    state = state.copyWith(isLoading: true, errorMessage: null);

    final results = await Future.wait<int?>([
      _safeCount(_service.fetchGeofences()),
      _safeCount(_service.fetchPois()),
      _safeCount(_service.fetchRoutes(includeGeodata: false)),
    ]);

    if (!mounted || serial != _requestSerial) return;

    state = state.copyWith(
      geofencesCount: results[0],
      poisCount: results[1],
      routesCount: results[2],
      isLoading: false,
      errorMessage: null,
    );
  }

  Future<void> refresh() => load();

  Future<int?> _safeCount<T>(Future<List<T>> future) async {
    try {
      final list = await future;
      return list.length;
    } catch (_) {
      // Counts are advisory; ignore errors so the landing screen still loads.
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Shared error mapping
// ---------------------------------------------------------------------------

String userLandmarkErrorMessage(Object error, {required String fallback}) {
  if (error is DioException) {
    final response = error.response?.data;
    if (response is Map<String, dynamic>) {
      for (final key in const ['message', 'error']) {
        final value = response[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
        if (value is List) {
          final parts = value
              .whereType<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(growable: false);
          if (parts.isNotEmpty) return parts.join(', ');
        }
      }
      final nested = response['data'];
      if (nested is Map<String, dynamic>) {
        final nestedMessage = nested['message'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage.trim();
        }
      }
    } else if (response is String && response.trim().isNotEmpty) {
      return response.trim();
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the server right now.';
      default:
        break;
    }
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) return message;
  }

  final raw = error.toString().trim();
  if (raw.startsWith('Exception: ')) {
    return raw.substring('Exception: '.length).trim();
  }
  return raw.isEmpty ? fallback : raw;
}
