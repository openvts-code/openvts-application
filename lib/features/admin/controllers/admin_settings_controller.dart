import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_settings_model.dart';
import '../models/admin_settings_state.dart';
import '../services/admin_settings_service.dart';

class AdminSettingsController extends StateNotifier<AdminSettingsState> {
  AdminSettingsController(this._service)
      : super(const AdminSettingsState.initial());

  final AdminSettingsService _service;

  Future<void> loadInitial() async {
    if (state.isLoadingInitial) return;
    state = state.copyWith(isLoadingInitial: true, errorMessage: null);
    try {
      await loadProfile();
    } catch (error) {
      state = state.copyWith(errorMessage: _toErrorMessage(error));
    } finally {
      state = state.copyWith(isLoadingInitial: false);
    }
  }

  void selectSection(AdminSettingsSection section) {
    if (state.selectedSection == section) return;
    state = state.copyWith(selectedSection: section, sectionErrorMessage: null);
    unawaited(_loadForSection(section, lazy: true));
  }

  Future<void> refreshCurrentSection() => _loadForSection(
        state.selectedSection,
        lazy: false,
      );

  Future<void> _loadForSection(
    AdminSettingsSection section, {
    required bool lazy,
  }) async {
    switch (section) {
      case AdminSettingsSection.profile:
        if (!lazy || state.profile == null) await loadProfile();
        break;
      case AdminSettingsSection.localization:
        if (!lazy || state.localization == null) await loadLocalization();
        break;
      case AdminSettingsSection.smtp:
        if (!lazy || state.smtp == null) await loadSmtp();
        break;
    }
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoadingProfile: true, sectionErrorMessage: null);
    try {
      final profile = await _service.getProfile();
      state = state.copyWith(profile: profile, isLoadingProfile: false);
    } catch (error) {
      state = state.copyWith(
        isLoadingProfile: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<bool> updateProfile(AdminUpdateProfileRequest request) async {
    state = state.copyWith(isSavingProfile: true, sectionErrorMessage: null);
    try {
      final profile = await _service.updateProfile(request);
      state = state.copyWith(profile: profile, isSavingProfile: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSavingProfile: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateCompany(AdminUpdateCompanyRequest request) async {
    state = state.copyWith(isSavingCompany: true, sectionErrorMessage: null);
    try {
      await _service.updateCompany(request);
      final profile = await _service.getProfile();
      state = state.copyWith(profile: profile, isSavingCompany: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSavingCompany: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> changePassword(AdminChangePasswordRequest request) async {
    state = state.copyWith(isChangingPassword: true, sectionErrorMessage: null);
    try {
      await _service.changePassword(request);
      state = state.copyWith(isChangingPassword: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isChangingPassword: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> uploadProfilePhoto({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) async {
    state = state.copyWith(
      isUploadingProfilePhoto: true,
      sectionErrorMessage: null,
    );
    try {
      final profile = await _service.uploadProfilePhoto(
        bytes: bytes,
        fileName: fileName,
      );
      state = state.copyWith(
        profile: profile,
        isUploadingProfilePhoto: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isUploadingProfilePhoto: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> requestEmailOtp() async {
    state =
        state.copyWith(isRequestingEmailOtp: true, sectionErrorMessage: null);
    try {
      await _service.requestEmailOtp();
      state = state.copyWith(isRequestingEmailOtp: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isRequestingEmailOtp: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> confirmEmailOtp(String otp) async {
    try {
      await _service.confirmEmailOtp(otp);
      final profile = await _service.getProfile();
      state = state.copyWith(profile: profile);
      return true;
    } catch (error) {
      state = state.copyWith(sectionErrorMessage: _toErrorMessage(error));
      return false;
    }
  }

  Future<bool> requestWhatsAppOtp() async {
    state = state.copyWith(
      isRequestingWhatsAppOtp: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.requestWhatsAppOtp();
      state = state.copyWith(isRequestingWhatsAppOtp: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isRequestingWhatsAppOtp: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> confirmWhatsAppOtp(String otp) async {
    try {
      await _service.confirmWhatsAppOtp(otp);
      final profile = await _service.getProfile();
      state = state.copyWith(profile: profile);
      return true;
    } catch (error) {
      state = state.copyWith(sectionErrorMessage: _toErrorMessage(error));
      return false;
    }
  }

  Future<void> loadEmailSubscription() async {
    state = state.copyWith(
      isLoadingEmailSubscription: true,
      sectionErrorMessage: null,
    );
    try {
      final subscribed = await _service.getEmailSubscription();
      state = state.copyWith(
        emailSubscribed: subscribed,
        isLoadingEmailSubscription: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingEmailSubscription: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<bool> subscribeEmail() async {
    state = state.copyWith(isSubscribingEmail: true, sectionErrorMessage: null);
    try {
      await _service.subscribeEmail();
      state = state.copyWith(isSubscribingEmail: false, emailSubscribed: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubscribingEmail: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<void> loadLocalization() async {
    state = state.copyWith(
      isLoadingLocalization: true,
      sectionErrorMessage: null,
    );
    try {
      final results = await Future.wait<dynamic>([
        _service.getLocalization(),
        _safeLanguages(),
        _safeDateFormats(),
        _safeTimezones(),
      ]);
      state = state.copyWith(
        localization: results[0] as AdminLocalizationSettings,
        languages: results[1] as List<AdminLanguageOption>,
        dateFormats: results[2] as List<AdminDateFormatOption>,
        timezones: results[3] as List<String>,
        isLoadingLocalization: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingLocalization: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<List<AdminLanguageOption>> _safeLanguages() async {
    try {
      return await _service.getLanguages();
    } catch (_) {
      return state.languages;
    }
  }

  Future<List<AdminDateFormatOption>> _safeDateFormats() async {
    try {
      return await _service.getDateFormats();
    } catch (_) {
      return state.dateFormats;
    }
  }

  Future<List<String>> _safeTimezones() async {
    try {
      return await _service.getTimezones();
    } catch (_) {
      return state.timezones;
    }
  }

  Future<bool> updateLocalization(AdminLocalizationSettings request) async {
    state = state.copyWith(
      isSavingLocalization: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.updateLocalization(request);
      state = state.copyWith(
        localization: request,
        isSavingLocalization: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSavingLocalization: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<void> loadSmtp() async {
    state = state.copyWith(isLoadingSmtp: true, sectionErrorMessage: null);
    try {
      final smtp = await _service.getSmtpSettings();
      state = state.copyWith(smtp: smtp, isLoadingSmtp: false);
    } catch (error) {
      state = state.copyWith(
        isLoadingSmtp: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<bool> updateSmtp(AdminSmtpSettings request) async {
    state = state.copyWith(isSavingSmtp: true, sectionErrorMessage: null);
    try {
      await _service.updateSmtpSettings(request);
      state = state.copyWith(smtp: request, isSavingSmtp: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSavingSmtp: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> testSmtp(String email) async {
    state = state.copyWith(isTestingSmtp: true, sectionErrorMessage: null);
    try {
      await _service.testSmtp(email);
      state = state.copyWith(isTestingSmtp: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isTestingSmtp: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  String _toErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!.trim();
      }
    }
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw;
  }
}
