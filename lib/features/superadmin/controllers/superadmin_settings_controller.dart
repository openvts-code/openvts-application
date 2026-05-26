import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/superadmin_settings_model.dart';
import '../models/superadmin_settings_state.dart';
import '../services/superadmin_settings_service.dart';

class SuperadminSettingsController
    extends StateNotifier<SuperadminSettingsState> {
  SuperadminSettingsController(this._service)
      : super(const SuperadminSettingsState.initial());

  final SuperadminSettingsService _service;

  // ---------------------------------------------------------------
  // Initial / section navigation
  // ---------------------------------------------------------------

  Future<void> loadInitial() async {
    if (state.isLoadingInitial) return;

    state = state.copyWith(
      isLoadingInitial: true,
      errorMessage: null,
    );

    try {
      await loadProfile();
    } catch (error) {
      state = state.copyWith(errorMessage: _toErrorMessage(error));
    } finally {
      state = state.copyWith(isLoadingInitial: false);
    }
  }

  void selectSection(SuperadminSettingsSection section) {
    if (state.selectedSection == section) return;
    state = state.copyWith(
      selectedSection: section,
      sectionErrorMessage: null,
    );
    unawaited(_loadForSection(section));
  }

  Future<void> refreshCurrentSection() => _loadForSection(state.selectedSection);

  Future<void> _loadForSection(SuperadminSettingsSection section) async {
    switch (section) {
      case SuperadminSettingsSection.profile:
        await loadProfile();
        break;
      case SuperadminSettingsSection.whiteLabel:
        await loadWhiteLabel();
        break;
      case SuperadminSettingsSection.smtp:
        await loadSmtp();
        break;
      case SuperadminSettingsSection.localization:
        await loadLocalization();
        break;
      case SuperadminSettingsSection.general:
        await loadSoftwareConfig();
        break;
    }
  }

  // ---------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------

  Future<void> loadProfile() async {
    state = state.copyWith(
      isLoadingProfile: true,
      sectionErrorMessage: null,
    );
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

  Future<bool> updateProfile(SuperadminUpdateProfileRequest request) async {
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

  Future<bool> updateCompany(SuperadminUpdateCompanyRequest request) async {
    state = state.copyWith(isSavingCompany: true, sectionErrorMessage: null);
    try {
      await _service.updateCompany(request);
      // Refresh profile so company info is in sync.
      try {
        final profile = await _service.getProfile();
        state = state.copyWith(profile: profile);
      } catch (_) {
        // Silently ignore refresh failure.
      }
      state = state.copyWith(isSavingCompany: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSavingCompany: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> changePassword(SuperadminChangePasswordRequest request) async {
    state = state.copyWith(
      isChangingPassword: true,
      sectionErrorMessage: null,
    );
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
        userId: userId,
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
    state = state.copyWith(isRequestingEmailOtp: true, sectionErrorMessage: null);
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
      // Refresh profile to update verification flags.
      try {
        final profile = await _service.getProfile();
        state = state.copyWith(profile: profile);
      } catch (_) {}
      return true;
    } catch (error) {
      state = state.copyWith(sectionErrorMessage: _toErrorMessage(error));
      return false;
    }
  }

  Future<bool> requestWhatsAppOtp() async {
    state = state.copyWith(isRequestingWhatsAppOtp: true, sectionErrorMessage: null);
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
      try {
        final profile = await _service.getProfile();
        state = state.copyWith(profile: profile);
      } catch (_) {}
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
      state = state.copyWith(
        isSubscribingEmail: false,
        emailSubscribed: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubscribingEmail: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------
  // White Label
  // ---------------------------------------------------------------

  Future<void> loadWhiteLabel() async {
    state = state.copyWith(
      isLoadingWhiteLabel: true,
      sectionErrorMessage: null,
    );
    try {
      final whiteLabel = await _service.getWhiteLabel();
      state = state.copyWith(
        whiteLabel: whiteLabel,
        isLoadingWhiteLabel: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingWhiteLabel: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<bool> updateWhiteLabel({
    String? customDomain,
    String? primaryColor,
    FileAttachment? logoLight,
    FileAttachment? logoDark,
    FileAttachment? favicon,
    String? logoLightUrl,
    String? logoDarkUrl,
    String? faviconUrl,
  }) async {
    state = state.copyWith(
      isSavingWhiteLabel: true,
      sectionErrorMessage: null,
    );
    try {
      final updated = await _service.updateWhiteLabel(
        customDomain: customDomain,
        primaryColor: primaryColor,
        logoLight: logoLight,
        logoDark: logoDark,
        favicon: favicon,
        logoLightUrl: logoLightUrl,
        logoDarkUrl: logoDarkUrl,
        faviconUrl: faviconUrl,
      );
      state = state.copyWith(
        whiteLabel: updated,
        isSavingWhiteLabel: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSavingWhiteLabel: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------
  // SMTP
  // ---------------------------------------------------------------

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

  Future<bool> updateSmtp(SuperadminSmtpSettings request) async {
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

  // ---------------------------------------------------------------
  // Localization
  // ---------------------------------------------------------------

  Future<void> loadLocalization() async {
    state = state.copyWith(
      isLoadingLocalization: true,
      sectionErrorMessage: null,
    );
    try {
      final results = await Future.wait<dynamic>([
        _service.getLocalization(),
        _safeLoadLanguages(),
        _safeLoadDateFormats(),
        _safeLoadTimezones(),
      ]);
      state = state.copyWith(
        localization: results[0] as SuperadminLocalizationSettings,
        languages: results[1] as List<SuperadminLanguageOption>,
        dateFormats: results[2] as List<SuperadminDateFormatOption>,
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

  Future<List<SuperadminLanguageOption>> _safeLoadLanguages() async {
    try {
      return await _service.getLanguages();
    } catch (_) {
      return state.languages;
    }
  }

  Future<List<SuperadminDateFormatOption>> _safeLoadDateFormats() async {
    try {
      return await _service.getDateFormats();
    } catch (_) {
      return state.dateFormats;
    }
  }

  Future<List<String>> _safeLoadTimezones() async {
    try {
      return await _service.getTimezones();
    } catch (_) {
      return state.timezones;
    }
  }

  Future<bool> updateLocalization(
    SuperadminLocalizationSettings request,
  ) async {
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

  // ---------------------------------------------------------------
  // Software config / data retention
  // ---------------------------------------------------------------

  Future<void> loadSoftwareConfig() async {
    state = state.copyWith(
      isLoadingSoftwareConfig: true,
      sectionErrorMessage: null,
    );
    try {
      final config = await _service.getSoftwareConfig();
      state = state.copyWith(
        softwareConfig: config,
        isLoadingSoftwareConfig: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingSoftwareConfig: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<bool> updateSoftwareConfig(SuperadminSoftwareConfig request) async {
    state = state.copyWith(
      isSavingSoftwareConfig: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.updateSoftwareConfig(request);
      state = state.copyWith(
        softwareConfig: request,
        isSavingSoftwareConfig: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSavingSoftwareConfig: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> previewDataRetention() async {
    state = state.copyWith(
      isPreviewingDataRetention: true,
      sectionErrorMessage: null,
    );
    try {
      final summary = await _service.previewDataRetention();
      state = state.copyWith(
        dataRetentionPreview: summary,
        isPreviewingDataRetention: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isPreviewingDataRetention: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> runDataRetention({required bool dryRun}) async {
    state = state.copyWith(
      isRunningDataRetention: true,
      sectionErrorMessage: null,
    );
    try {
      final summary = await _service.runDataRetention(dryRun: dryRun);
      state = state.copyWith(
        dataRetentionPreview: summary,
        isRunningDataRetention: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isRunningDataRetention: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------

  String _toErrorMessage(Object error) {
    if (error is DioException) {
      final response = error.response;
      final data = response?.data;
      if (data is Map) {
        final map = data.cast<String, dynamic>();
        for (final key in const ['message', 'error', 'detail']) {
          final value = map[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
        final nested = map['data'];
        if (nested is Map) {
          final nestedMap = nested.cast<String, dynamic>();
          for (final key in const ['message', 'error']) {
            final value = nestedMap[key];
            if (value is String && value.trim().isNotEmpty) {
              return value.trim();
            }
          }
        }
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    return error.toString();
  }
}
