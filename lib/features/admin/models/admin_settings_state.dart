import 'admin_settings_model.dart';

class AdminSettingsState {
  const AdminSettingsState({
    required this.selectedSection,
    required this.profile,
    required this.localization,
    required this.smtp,
    required this.languages,
    required this.dateFormats,
    required this.timezones,
    required this.isLoadingInitial,
    required this.isLoadingProfile,
    required this.isLoadingLocalization,
    required this.isLoadingSmtp,
    required this.isSavingProfile,
    required this.isSavingCompany,
    required this.isChangingPassword,
    required this.isUploadingProfilePhoto,
    required this.isSavingLocalization,
    required this.isSavingSmtp,
    required this.isTestingSmtp,
    required this.isLoadingEmailSubscription,
    required this.isSubscribingEmail,
    required this.isRequestingEmailOtp,
    required this.isRequestingWhatsAppOtp,
    required this.emailSubscribed,
    required this.errorMessage,
    required this.sectionErrorMessage,
  });

  const AdminSettingsState.initial()
      : selectedSection = AdminSettingsSection.profile,
        profile = null,
        localization = null,
        smtp = null,
        languages = const <AdminLanguageOption>[],
        dateFormats = const <AdminDateFormatOption>[],
        timezones = const <String>[],
        isLoadingInitial = false,
        isLoadingProfile = false,
        isLoadingLocalization = false,
        isLoadingSmtp = false,
        isSavingProfile = false,
        isSavingCompany = false,
        isChangingPassword = false,
        isUploadingProfilePhoto = false,
        isSavingLocalization = false,
        isSavingSmtp = false,
        isTestingSmtp = false,
        isLoadingEmailSubscription = false,
        isSubscribingEmail = false,
        isRequestingEmailOtp = false,
        isRequestingWhatsAppOtp = false,
        emailSubscribed = null,
        errorMessage = null,
        sectionErrorMessage = null;

  static const _unset = Object();

  final AdminSettingsSection selectedSection;
  final AdminProfileSettings? profile;
  final AdminLocalizationSettings? localization;
  final AdminSmtpSettings? smtp;
  final List<AdminLanguageOption> languages;
  final List<AdminDateFormatOption> dateFormats;
  final List<String> timezones;
  final bool isLoadingInitial;
  final bool isLoadingProfile;
  final bool isLoadingLocalization;
  final bool isLoadingSmtp;
  final bool isSavingProfile;
  final bool isSavingCompany;
  final bool isChangingPassword;
  final bool isUploadingProfilePhoto;
  final bool isSavingLocalization;
  final bool isSavingSmtp;
  final bool isTestingSmtp;
  final bool isLoadingEmailSubscription;
  final bool isSubscribingEmail;
  final bool isRequestingEmailOtp;
  final bool isRequestingWhatsAppOtp;
  final bool? emailSubscribed;
  final String? errorMessage;
  final String? sectionErrorMessage;

  AdminSettingsState copyWith({
    AdminSettingsSection? selectedSection,
    Object? profile = _unset,
    Object? localization = _unset,
    Object? smtp = _unset,
    List<AdminLanguageOption>? languages,
    List<AdminDateFormatOption>? dateFormats,
    List<String>? timezones,
    bool? isLoadingInitial,
    bool? isLoadingProfile,
    bool? isLoadingLocalization,
    bool? isLoadingSmtp,
    bool? isSavingProfile,
    bool? isSavingCompany,
    bool? isChangingPassword,
    bool? isUploadingProfilePhoto,
    bool? isSavingLocalization,
    bool? isSavingSmtp,
    bool? isTestingSmtp,
    bool? isLoadingEmailSubscription,
    bool? isSubscribingEmail,
    bool? isRequestingEmailOtp,
    bool? isRequestingWhatsAppOtp,
    Object? emailSubscribed = _unset,
    Object? errorMessage = _unset,
    Object? sectionErrorMessage = _unset,
  }) {
    return AdminSettingsState(
      selectedSection: selectedSection ?? this.selectedSection,
      profile: identical(profile, _unset)
          ? this.profile
          : profile as AdminProfileSettings?,
      localization: identical(localization, _unset)
          ? this.localization
          : localization as AdminLocalizationSettings?,
      smtp: identical(smtp, _unset) ? this.smtp : smtp as AdminSmtpSettings?,
      languages: languages ?? this.languages,
      dateFormats: dateFormats ?? this.dateFormats,
      timezones: timezones ?? this.timezones,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      isLoadingLocalization:
          isLoadingLocalization ?? this.isLoadingLocalization,
      isLoadingSmtp: isLoadingSmtp ?? this.isLoadingSmtp,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      isSavingCompany: isSavingCompany ?? this.isSavingCompany,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      isUploadingProfilePhoto:
          isUploadingProfilePhoto ?? this.isUploadingProfilePhoto,
      isSavingLocalization: isSavingLocalization ?? this.isSavingLocalization,
      isSavingSmtp: isSavingSmtp ?? this.isSavingSmtp,
      isTestingSmtp: isTestingSmtp ?? this.isTestingSmtp,
      isLoadingEmailSubscription:
          isLoadingEmailSubscription ?? this.isLoadingEmailSubscription,
      isSubscribingEmail: isSubscribingEmail ?? this.isSubscribingEmail,
      isRequestingEmailOtp: isRequestingEmailOtp ?? this.isRequestingEmailOtp,
      isRequestingWhatsAppOtp:
          isRequestingWhatsAppOtp ?? this.isRequestingWhatsAppOtp,
      emailSubscribed: identical(emailSubscribed, _unset)
          ? this.emailSubscribed
          : emailSubscribed as bool?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      sectionErrorMessage: identical(sectionErrorMessage, _unset)
          ? this.sectionErrorMessage
          : sectionErrorMessage as String?,
    );
  }
}
