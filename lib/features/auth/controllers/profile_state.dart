import '../models/current_user.dart';

class ProfileState {
  static const _unset = Object();

  const ProfileState({
    this.user,
    this.isInitialLoading = false,
    this.isUploadingPhoto = false,
    this.localPhotoBytes,
    this.errorMessage,
  });

  const ProfileState.initial({CurrentUser? user}) : this(user: user);

  final CurrentUser? user;
  final bool isInitialLoading;
  final bool isUploadingPhoto;
  final List<int>? localPhotoBytes;
  final String? errorMessage;

  bool get isBusy => isInitialLoading || isUploadingPhoto;

  ProfileState copyWith({
    CurrentUser? user,
    bool? isInitialLoading,
    bool? isUploadingPhoto,
    Object? localPhotoBytes = _unset,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      localPhotoBytes: identical(localPhotoBytes, _unset)
          ? this.localPhotoBytes
          : localPhotoBytes as List<int>?,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
