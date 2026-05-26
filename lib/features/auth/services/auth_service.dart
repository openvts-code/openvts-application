import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/models/user_role.dart';
import '../models/current_user.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<LoginResponse> login(LoginRequest request) async {
    if (AppConfig.useMockData) {
      final role = request.identifier.toLowerCase().contains('superadmin')
          ? UserRole.superadmin
          : request.identifier.toLowerCase().contains('admin')
              ? UserRole.admin
              : UserRole.user;

      return LoginResponse(
        accessToken: 'mock-access-token-${role.apiValue}',
        refreshToken: 'mock-refresh-token-${role.apiValue}',
        user: CurrentUser(
          id: '1',
          name: role == UserRole.superadmin
              ? 'Super Admin'
              : role == UserRole.admin
                  ? 'Admin'
                  : 'User',
          email: request.identifier.contains('@')
              ? request.identifier
              : '${request.identifier}@openvts.local',
          role: role,
          username: request.identifier,
          profileUrl: 'https://i.pravatar.cc/300?u=${role.apiValue}',
          mobilePrefix: '+1',
          mobileNumber: '5559876543',
          phoneNumber: '+1 5559876543',
          accountStatus: 'active',
          isVerified: true,
          addressLine: '221 Fleet Street',
          countryCode: 'US',
          stateCode: 'CA',
          cityName: 'San Francisco',
          pincode: '94107',
        ),
      );
    }

    final response = await _apiClient.post<LoginResponse>(
      ApiEndpoints.auth.login,
      data: request.toJson(),
      parser: (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    );

    if (response.data.accessToken.isEmpty ||
        response.data.refreshToken.isEmpty) {
      throw const ApiException(message: 'Login response is missing tokens');
    }

    return response.data;
  }

  Future<void> logout() async {
    // Role logout is handled by local session removal.
    // Keep this method as a no-op to mirror web behavior.
    return;
  }

  Future<CurrentUser> getProfile(CurrentUser currentUser) async {
    if (AppConfig.useMockData) {
      return _mockProfile(currentUser);
    }

    final response = await _apiClient.get<CurrentUser>(
      _profileEndpoint(currentUser.role),
      parser: (json) {
        final payload = _extractProfilePayload(json);
        if (payload == null) {
          return currentUser;
        }

        final incoming =
            CurrentUser.fromJson(payload).copyWith(role: currentUser.role);
        return _mergeProfile(incoming, currentUser);
      },
    );

    return _mergeProfile(response.data, currentUser);
  }

  Future<CurrentUser> uploadProfilePhoto(
    CurrentUser currentUser, {
    required List<int> bytes,
    required String fileName,
  }) async {
    if (AppConfig.useMockData) {
      return _mockProfile(
        currentUser.copyWith(
          profileUrl:
              'https://i.pravatar.cc/300?u=${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
    }

    final uploadResponse = await _apiClient.post<CurrentUser?>(
      _uploadEndpoint(currentUser),
      data: FormData.fromMap({
        'type': 'PROFILE',
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: _contentTypeForFileName(fileName),
        ),
      }),
      parser: (json) => _parseUploadedProfile(json, currentUser),
    );

    final uploadedUser = uploadResponse.data;

    final refreshed = await getProfile(uploadedUser ?? currentUser);
    final profileUrl = _firstNonEmptyString([
      uploadedUser?.profileUrl,
      refreshed.profileUrl,
      currentUser.profileUrl,
    ]);
    if (profileUrl == null || profileUrl.trim().isEmpty) {
      return refreshed;
    }

    return refreshed.copyWith(profileUrl: _appendCacheBust(profileUrl));
  }

  String _profileEndpoint(UserRole role) {
    switch (role) {
      case UserRole.superadmin:
        return ApiEndpoints.superadmin.profile;
      case UserRole.admin:
        return ApiEndpoints.admin.profile;
      case UserRole.user:
        return ApiEndpoints.user.profile;
    }
  }

  String _uploadEndpoint(CurrentUser currentUser) {
    switch (currentUser.role) {
      case UserRole.superadmin:
        return ApiEndpoints.superadmin.uploadProfile(currentUser.id);
      case UserRole.admin:
        return ApiEndpoints.admin.uploadProfile;
      case UserRole.user:
        return ApiEndpoints.user.uploadProfile;
    }
  }

  CurrentUser _mockProfile(CurrentUser currentUser) {
    return currentUser.copyWith(
      mobilePrefix: currentUser.mobilePrefix ?? '+1',
      mobileNumber: currentUser.mobileNumber ?? '5559876543',
      phoneNumber: currentUser.resolvedPhoneNumber ?? '+1 5559876543',
      accountStatus: currentUser.accountStatus ?? 'active',
      isVerified: currentUser.isVerified ?? true,
      addressLine: currentUser.addressLine ?? '221 Fleet Street',
      countryCode: currentUser.countryCode ?? 'US',
      stateCode: currentUser.stateCode ?? 'CA',
      cityName: currentUser.cityName ?? 'San Francisco',
      pincode: currentUser.pincode ?? '94107',
      profileUrl: currentUser.profileUrl ??
          'https://i.pravatar.cc/300?u=${currentUser.role.apiValue}',
    );
  }

  CurrentUser _mergeProfile(CurrentUser incoming, CurrentUser fallback) {
    return fallback.copyWith(
      id: incoming.id.isNotEmpty ? incoming.id : fallback.id,
      name: incoming.name.isNotEmpty ? incoming.name : fallback.name,
      email: incoming.email.isNotEmpty ? incoming.email : fallback.email,
      role: fallback.role,
      username:
          incoming.username.isNotEmpty ? incoming.username : fallback.username,
      profileUrl: incoming.profileUrl ?? fallback.profileUrl,
      phoneNumber: incoming.resolvedPhoneNumber ?? fallback.resolvedPhoneNumber,
      accountStatus: incoming.accountStatus ?? fallback.accountStatus,
      isVerified: incoming.isVerified ?? fallback.isVerified,
      mobilePrefix: incoming.mobilePrefix ?? fallback.mobilePrefix,
      mobileNumber: incoming.mobileNumber ?? fallback.mobileNumber,
      addressLine: incoming.addressLine ?? fallback.addressLine,
      countryCode: incoming.countryCode ?? fallback.countryCode,
      stateCode: incoming.stateCode ?? fallback.stateCode,
      cityName: incoming.cityName ?? fallback.cityName,
      pincode: incoming.pincode ?? fallback.pincode,
    );
  }

  CurrentUser? _parseUploadedProfile(dynamic json, CurrentUser currentUser) {
    final payload = _extractProfilePayload(json);
    if (payload != null) {
      final incoming =
          CurrentUser.fromJson(payload).copyWith(role: currentUser.role);
      return _mergeProfile(incoming, currentUser);
    }

    final uploadedProfileUrl = _extractUploadedProfileUrl(json);
    if (uploadedProfileUrl == null) {
      return null;
    }

    return currentUser.copyWith(profileUrl: uploadedProfileUrl);
  }

  Map<String, dynamic>? _extractProfilePayload(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    if (_looksLikeProfilePayload(json)) {
      return json;
    }

    for (final key in const ['data', 'user', 'profile', 'result']) {
      final nested = _extractProfilePayload(json[key]);
      if (nested != null) {
        return nested;
      }
    }

    return null;
  }

  bool _looksLikeProfilePayload(Map<String, dynamic> json) {
    for (final key in const [
      'id',
      'userId',
      'user_id',
      'uid',
      'name',
      'displayName',
      'display_name',
      'fullName',
      'full_name',
      'email',
      'profileUrl',
      'profile_url',
      'avatar',
      'avatar_url',
      'image',
      'image_url',
    ]) {
      if (json.containsKey(key)) {
        return true;
      }
    }

    return false;
  }

  String? _extractUploadedProfileUrl(dynamic json) {
    if (json is String) {
      final normalized = json.trim();
      if (_looksLikeProfileUrl(normalized)) {
        return normalized;
      }
      return null;
    }

    if (json is List) {
      for (final item in json) {
        final nested = _extractUploadedProfileUrl(item);
        if (nested != null) {
          return nested;
        }
      }
      return null;
    }

    if (json is! Map<String, dynamic>) {
      return null;
    }

    final direct = _firstNonEmptyString([
      json['profileUrl'],
      json['profileURL'],
      json['profile_url'],
      json['profileImage'],
      json['profileImageUrl'],
      json['profile_image_url'],
      json['profile_image'],
      json['profilePicture'],
      json['profile_picture'],
      json['profilePhoto'],
      json['profile_photo'],
      json['profilePath'],
      json['profile_path'],
      json['avatar'],
      json['avatarPath'],
      json['avatar_path'],
      json['avatarUrl'],
      json['avatar_url'],
      json['image'],
      json['imagePath'],
      json['image_path'],
      json['imageUrl'],
      json['image_url'],
      json['photo'],
      json['photoPath'],
      json['photo_path'],
      json['photoUrl'],
      json['photo_url'],
      json['url'],
      json['path'],
      json['location'],
      json['storedName'],
      json['stored_name'],
      json['fileName'],
      json['file_name'],
      json['filePath'],
      json['file_path'],
      json['filepath'],
      json['fileUrl'],
      json['file_url'],
    ]);
    if (direct != null && _looksLikeProfileUrl(direct)) {
      return direct;
    }

    for (final key in const [
      'data',
      'result',
      'user',
      'profile',
      'file',
      'image',
      'photo',
      'avatar',
    ]) {
      final nested = _extractUploadedProfileUrl(json[key]);
      if (nested != null) {
        return nested;
      }
    }

    return null;
  }

  bool _looksLikeProfileUrl(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return false;
    }

    if (normalized.startsWith('data:image/')) {
      return true;
    }

    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('/')) {
      return true;
    }

    if (!normalized.contains(RegExp(r'\s')) &&
        (normalized.contains('/') || normalized.contains('\\'))) {
      return true;
    }

    return RegExp(
      r'\.(png|jpg|jpeg|gif|webp|bmp|svg)(\?|$)',
      caseSensitive: false,
    ).hasMatch(normalized);
  }

  MediaType _contentTypeForFileName(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    if (normalized.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (normalized.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    if (normalized.endsWith('.gif')) {
      return MediaType('image', 'gif');
    }
    if (normalized.endsWith('.bmp')) {
      return MediaType('image', 'bmp');
    }
    if (normalized.endsWith('.svg')) {
      return MediaType('image', 'svg+xml');
    }

    return MediaType('image', 'jpeg');
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final normalized = value?.toString().trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }

  String _appendCacheBust(String url) {
    final uri = Uri.tryParse(url);
    final version = DateTime.now().millisecondsSinceEpoch.toString();
    if (uri == null) {
      final separator = url.contains('?') ? '&' : '?';
      return '$url${separator}v=$version';
    }

    final parameters = Map<String, String>.from(uri.queryParameters);
    parameters['v'] = version;
    return uri.replace(queryParameters: parameters).toString();
  }
}
