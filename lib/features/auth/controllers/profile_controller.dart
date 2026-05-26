import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/current_user.dart';
import '../services/auth_service.dart';
import 'auth_controller.dart';
import 'profile_state.dart';

final profileControllerProvider =
    StateNotifierProvider.autoDispose<ProfileController, ProfileState>((ref) {
  return ProfileController(
    authService: ref.watch(authServiceProvider),
    authController: ref.read(authControllerProvider.notifier),
    initialUser: ref.read(authControllerProvider).user,
  );
});

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController({
    required AuthService authService,
    required AuthController authController,
    CurrentUser? initialUser,
  })  : _authService = authService,
        _authController = authController,
        super(ProfileState.initial(user: initialUser));

  final AuthService _authService;
  final AuthController _authController;

  Future<void> load({bool refresh = false}) async {
    final currentUser = state.user ?? _authController.currentUser;
    if (currentUser == null) {
      return;
    }

    state = state.copyWith(
      user: currentUser,
      isInitialLoading: true,
      errorMessage: null,
    );

    try {
      final profile = await _authService.getProfile(currentUser);
      await _authController.replaceCurrentUser(profile);
      state = state.copyWith(
        user: profile,
        isInitialLoading: false,
        localPhotoBytes: null,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isInitialLoading: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<CurrentUser> uploadPhoto({
    required List<int> bytes,
    required String fileName,
  }) async {
    final currentUser = state.user ?? _authController.currentUser;
    if (currentUser == null) {
      throw Exception('No active user profile is available.');
    }

    state = state.copyWith(
      user: currentUser,
      isUploadingPhoto: true,
      localPhotoBytes: bytes,
      errorMessage: null,
    );

    try {
      final updatedUser = await _authService.uploadProfilePhoto(
        currentUser,
        bytes: bytes,
        fileName: fileName,
      );
      await _authController.replaceCurrentUser(updatedUser);
      state = state.copyWith(
        user: updatedUser,
        isUploadingPhoto: false,
        clearError: true,
      );
      return updatedUser;
    } catch (error) {
      state = state.copyWith(
        isUploadingPhoto: false,
        localPhotoBytes: null,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  String _toErrorMessage(Object error) {
    if (error is DioException) {
      final responseMessage = _extractResponseMessage(error.response?.data);
      if (responseMessage != null) {
        return responseMessage;
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Please try again.';
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

    return raw;
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
