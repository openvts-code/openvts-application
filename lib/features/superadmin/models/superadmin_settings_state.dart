import 'superadmin_settings_model.dart';

class SuperadminSettingsState {
  const SuperadminSettingsState({
    required this.selectedSection,
    required this.profile,
    required this.whiteLabel,
    required this.smtp,
    required this.localization,
    required this.softwareConfig,
    required this.languages,
    required this.dateFormats,
    required this.timezones,
    required this.dataRetentionPreview,
    required this.isLoadingInitial,
    required this.isLoadingProfile,
    required this.isLoadingWhiteLabel,
    required this.isLoadingSmtp,
    required this.isLoadingLocalization,
    required this.isLoadingSoftwareConfig,
    required this.isSavingProfile,
    required this.isSavingCompany,
    required this.isChangingPassword,
    required this.isUploadingProfilePhoto,
    required this.isSavingWhiteLabel,
    required this.isSavingSmtp,
    required this.isTestingSmtp,
    required this.isSavingLocalization,
    required this.isSavingSoftwareConfig,
    required this.isPreviewingDataRetention,
    required this.isRunningDataRetention,
    required this.emailSubscribed,
    required this.isLoadingEmailSubscription,
    required this.isSubscribingEmail,
    required this.isRequestingEmailOtp,
    required this.isRequestingWhatsAppOtp,
    required this.errorMessage,
    required this.sectionErrorMessage,
  });

  const SuperadminSettingsState.initial()
      : selectedSection = SuperadminSettingsSection.profile,
        profile = null,
        whiteLabel = null,
        smtp = null,
        localization = null,
        softwareConfig = null,
        languages = const <SuperadminLanguageOption>[],
        dateFormats = const <SuperadminDateFormatOption>[],
        timezones = const <String>[],
        dataRetentionPreview = null,
        isLoadingInitial = false,
        isLoadingProfile = false,
        isLoadingWhiteLabel = false,
        isLoadingSmtp = false,
        isLoadingLocalization = false,
        isLoadingSoftwareConfig = false,
        isSavingProfile = false,
        isSavingCompany = false,
        isChangingPassword = false,
        isUploadingProfilePhoto = false,
        isSavingWhiteLabel = false,
        isSavingSmtp = false,
        isTestingSmtp = false,
        isSavingLocalization = false,
        isSavingSoftwareConfig = false,
        isPreviewingDataRetention = false,
        isRunningDataRetention = false,
        emailSubscribed = null,
        isLoadingEmailSubscription = false,
        isSubscribingEmail = false,
        isRequestingEmailOtp = false,
        isRequestingWhatsAppOtp = false,
        errorMessage = null,
        sectionErrorMessage = null;

  static const Object _unset = Object();

  final SuperadminSettingsSection selectedSection;
  final SuperadminProfileSettings? profile;
  final SuperadminWhiteLabelSettings? whiteLabel;
  final SuperadminSmtpSettings? smtp;
  final SuperadminLocalizationSettings? localization;
  final SuperadminSoftwareConfig? softwareConfig;
  final List<SuperadminLanguageOption> languages;
  final List<SuperadminDateFormatOption> dateFormats;
  final List<String> timezones;
  final SuperadminDataRetentionSummary? dataRetentionPreview;
  final bool isLoadingInitial;
  final bool isLoadingProfile;
  final bool isLoadingWhiteLabel;
  final bool isLoadingSmtp;
  final bool isLoadingLocalization;
  final bool isLoadingSoftwareConfig;
  final bool isSavingProfile;
  final bool isSavingCompany;
  final bool isChangingPassword;
  final bool isUploadingProfilePhoto;
  final bool isSavingWhiteLabel;
  final bool isSavingSmtp;
  final bool isTestingSmtp;
  final bool isSavingLocalization;
  final bool isSavingSoftwareConfig;
  final bool isPreviewingDataRetention;
  final bool isRunningDataRetention;
  final bool? emailSubscribed;
  final bool isLoadingEmailSubscription;
  final bool isSubscribingEmail;
  final bool isRequestingEmailOtp;
  final bool isRequestingWhatsAppOtp;
  final String? errorMessage;
  final String? sectionErrorMessage;

  SuperadminSettingsState copyWith({
    SuperadminSettingsSection? selectedSection,
    Object? profile = _unset,
    Object? whiteLabel = _unset,
    Object? smtp = _unset,
    Object? localization = _unset,
    Object? softwareConfig = _unset,
    List<SuperadminLanguageOption>? languages,
    List<SuperadminDateFormatOption>? dateFormats,
    List<String>? timezones,
    Object? dataRetentionPreview = _unset,
    bool? isLoadingInitial,
    bool? isLoadingProfile,
    bool? isLoadingWhiteLabel,
    bool? isLoadingSmtp,
    bool? isLoadingLocalization,
    bool? isLoadingSoftwareConfig,
    bool? isSavingProfile,
    bool? isSavingCompany,
    bool? isChangingPassword,
    bool? isUploadingProfilePhoto,
    bool? isSavingWhiteLabel,
    bool? isSavingSmtp,
    bool? isTestingSmtp,
    bool? isSavingLocalization,
    bool? isSavingSoftwareConfig,
    bool? isPreviewingDataRetention,
    bool? isRunningDataRetention,
    Object? emailSubscribed = _unset,
    bool? isLoadingEmailSubscription,
    bool? isSubscribingEmail,
    bool? isRequestingEmailOtp,
    bool? isRequestingWhatsAppOtp,
    Object? errorMessage = _unset,
    Object? sectionErrorMessage = _unset,
  }) {
    return SuperadminSettingsState(
      selectedSection: selectedSection ?? this.selectedSection,
      profile: identical(profile, _unset)
          ? this.profile
          : profile as SuperadminProfileSettings?,
      whiteLabel: identical(whiteLabel, _unset)
          ? this.whiteLabel
          : whiteLabel as SuperadminWhiteLabelSettings?,
      smtp: identical(smtp, _unset)
          ? this.smtp
          : smtp as SuperadminSmtpSettings?,
      localization: identical(localization, _unset)
          ? this.localization
          : localization as SuperadminLocalizationSettings?,
      softwareConfig: identical(softwareConfig, _unset)
          ? this.softwareConfig
          : softwareConfig as SuperadminSoftwareConfig?,
      languages: languages ?? this.languages,
      dateFormats: dateFormats ?? this.dateFormats,
      timezones: timezones ?? this.timezones,
      dataRetentionPreview: identical(dataRetentionPreview, _unset)
          ? this.dataRetentionPreview
          : dataRetentionPreview as SuperadminDataRetentionSummary?,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      isLoadingWhiteLabel: isLoadingWhiteLabel ?? this.isLoadingWhiteLabel,
      isLoadingSmtp: isLoadingSmtp ?? this.isLoadingSmtp,
      isLoadingLocalization:
          isLoadingLocalization ?? this.isLoadingLocalization,
      isLoadingSoftwareConfig:
          isLoadingSoftwareConfig ?? this.isLoadingSoftwareConfig,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      isSavingCompany: isSavingCompany ?? this.isSavingCompany,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      isUploadingProfilePhoto:
          isUploadingProfilePhoto ?? this.isUploadingProfilePhoto,
      isSavingWhiteLabel: isSavingWhiteLabel ?? this.isSavingWhiteLabel,
      isSavingSmtp: isSavingSmtp ?? this.isSavingSmtp,
      isTestingSmtp: isTestingSmtp ?? this.isTestingSmtp,
      isSavingLocalization: isSavingLocalization ?? this.isSavingLocalization,
      isSavingSoftwareConfig:
          isSavingSoftwareConfig ?? this.isSavingSoftwareConfig,
      isPreviewingDataRetention:
          isPreviewingDataRetention ?? this.isPreviewingDataRetention,
      isRunningDataRetention:
          isRunningDataRetention ?? this.isRunningDataRetention,
      emailSubscribed: identical(emailSubscribed, _unset)
          ? this.emailSubscribed
          : emailSubscribed as bool?,
      isLoadingEmailSubscription:
          isLoadingEmailSubscription ?? this.isLoadingEmailSubscription,
      isSubscribingEmail: isSubscribingEmail ?? this.isSubscribingEmail,
      isRequestingEmailOtp:
          isRequestingEmailOtp ?? this.isRequestingEmailOtp,
      isRequestingWhatsAppOtp:
          isRequestingWhatsAppOtp ?? this.isRequestingWhatsAppOtp,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      sectionErrorMessage: identical(sectionErrorMessage, _unset)
          ? this.sectionErrorMessage
          : sectionErrorMessage as String?,
    );
  }
}
