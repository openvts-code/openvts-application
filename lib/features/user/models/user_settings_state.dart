import 'user_settings_model.dart';

class UserSettingsState {
  const UserSettingsState({
    required this.selectedTab,
    required this.profile,
    required this.localization,
    required this.draftProfile,
    required this.draftLocalization,
    required this.emailSubscription,
    required this.languages,
    required this.dateFormats,
    required this.timezones,
    required this.countries,
    required this.mobilePrefixes,
    required this.states,
    required this.cities,
    required this.isLoadingInitial,
    required this.isLoadingProfile,
    required this.isSavingProfile,
    required this.isSavingCompany,
    required this.isChangingPassword,
    required this.isUploadingProfilePhoto,
    required this.isRequestingEmailOtp,
    required this.isConfirmingEmailOtp,
    required this.isRequestingWhatsAppOtp,
    required this.isConfirmingWhatsAppOtp,
    required this.isLoadingEmailSubscription,
    required this.isSubscribingEmail,
    required this.isLoadingLocalization,
    required this.isSavingLocalization,
    required this.isLoadingReferences,
    required this.errorMessage,
    required this.profileErrorMessage,
    required this.localizationErrorMessage,
  });

  const UserSettingsState.initial()
      : selectedTab = UserSettingsTab.profile,
        profile = null,
        localization = null,
        draftProfile = null,
        draftLocalization = null,
        emailSubscription = null,
        languages = const <UserLanguageOption>[],
        dateFormats = const <UserDateFormatOption>[],
        timezones = const <String>[],
        countries = const <UserCountryOption>[],
        mobilePrefixes = const <UserMobilePrefixOption>[],
        states = const <UserStateOption>[],
        cities = const <UserCityOption>[],
        isLoadingInitial = false,
        isLoadingProfile = false,
        isSavingProfile = false,
        isSavingCompany = false,
        isChangingPassword = false,
        isUploadingProfilePhoto = false,
        isRequestingEmailOtp = false,
        isConfirmingEmailOtp = false,
        isRequestingWhatsAppOtp = false,
        isConfirmingWhatsAppOtp = false,
        isLoadingEmailSubscription = false,
        isSubscribingEmail = false,
        isLoadingLocalization = false,
        isSavingLocalization = false,
        isLoadingReferences = false,
        errorMessage = null,
        profileErrorMessage = null,
        localizationErrorMessage = null;

  static const Object _unset = Object();

  final UserSettingsTab selectedTab;
  final UserSettingsProfile? profile;
  final UserLocalizationSettings? localization;
  final UserSettingsProfile? draftProfile;
  final UserLocalizationSettings? draftLocalization;
  final UserEmailSubscriptionStatus? emailSubscription;

  final List<UserLanguageOption> languages;
  final List<UserDateFormatOption> dateFormats;
  final List<String> timezones;
  final List<UserCountryOption> countries;
  final List<UserMobilePrefixOption> mobilePrefixes;
  final List<UserStateOption> states;
  final List<UserCityOption> cities;

  final bool isLoadingInitial;
  final bool isLoadingProfile;
  final bool isSavingProfile;
  final bool isSavingCompany;
  final bool isChangingPassword;
  final bool isUploadingProfilePhoto;
  final bool isRequestingEmailOtp;
  final bool isConfirmingEmailOtp;
  final bool isRequestingWhatsAppOtp;
  final bool isConfirmingWhatsAppOtp;
  final bool isLoadingEmailSubscription;
  final bool isSubscribingEmail;
  final bool isLoadingLocalization;
  final bool isSavingLocalization;
  final bool isLoadingReferences;

  final String? errorMessage;
  final String? profileErrorMessage;
  final String? localizationErrorMessage;

  bool get hasProfile => profile != null;

  bool get hasLocalization => localization != null;

  bool get isProfileDirty {
    final saved = profile;
    final draft = draftProfile;

    if (saved == null && draft == null) {
      return false;
    }

    if (saved == null || draft == null) {
      return true;
    }

    return saved != draft;
  }

  bool get isLocalizationDirty {
    final saved = localization;
    final draft = draftLocalization;

    if (saved == null && draft == null) {
      return false;
    }

    if (saved == null || draft == null) {
      return true;
    }

    return saved != draft;
  }

  bool get hasAnyBusyState {
    return isLoadingInitial ||
        isLoadingProfile ||
        isSavingProfile ||
        isSavingCompany ||
        isChangingPassword ||
        isUploadingProfilePhoto ||
        isRequestingEmailOtp ||
        isConfirmingEmailOtp ||
        isRequestingWhatsAppOtp ||
        isConfirmingWhatsAppOtp ||
        isLoadingEmailSubscription ||
        isSubscribingEmail ||
        isLoadingLocalization ||
        isSavingLocalization ||
        isLoadingReferences;
  }

  bool get canSaveProfile => isProfileDirty && !hasAnyBusyState;

  bool get canSaveLocalization => isLocalizationDirty && !hasAnyBusyState;

  UserSettingsState copyWith({
    UserSettingsTab? selectedTab,
    Object? profile = _unset,
    Object? localization = _unset,
    Object? draftProfile = _unset,
    Object? draftLocalization = _unset,
    Object? emailSubscription = _unset,
    List<UserLanguageOption>? languages,
    List<UserDateFormatOption>? dateFormats,
    List<String>? timezones,
    List<UserCountryOption>? countries,
    List<UserMobilePrefixOption>? mobilePrefixes,
    List<UserStateOption>? states,
    List<UserCityOption>? cities,
    bool? isLoadingInitial,
    bool? isLoadingProfile,
    bool? isSavingProfile,
    bool? isSavingCompany,
    bool? isChangingPassword,
    bool? isUploadingProfilePhoto,
    bool? isRequestingEmailOtp,
    bool? isConfirmingEmailOtp,
    bool? isRequestingWhatsAppOtp,
    bool? isConfirmingWhatsAppOtp,
    bool? isLoadingEmailSubscription,
    bool? isSubscribingEmail,
    bool? isLoadingLocalization,
    bool? isSavingLocalization,
    bool? isLoadingReferences,
    Object? errorMessage = _unset,
    Object? profileErrorMessage = _unset,
    Object? localizationErrorMessage = _unset,
  }) {
    return UserSettingsState(
      selectedTab: selectedTab ?? this.selectedTab,
      profile: identical(profile, _unset)
          ? this.profile
          : profile as UserSettingsProfile?,
      localization: identical(localization, _unset)
          ? this.localization
          : localization as UserLocalizationSettings?,
      draftProfile: identical(draftProfile, _unset)
          ? this.draftProfile
          : draftProfile as UserSettingsProfile?,
      draftLocalization: identical(draftLocalization, _unset)
          ? this.draftLocalization
          : draftLocalization as UserLocalizationSettings?,
      emailSubscription: identical(emailSubscription, _unset)
          ? this.emailSubscription
          : emailSubscription as UserEmailSubscriptionStatus?,
      languages: languages ?? this.languages,
      dateFormats: dateFormats ?? this.dateFormats,
      timezones: timezones ?? this.timezones,
      countries: countries ?? this.countries,
      mobilePrefixes: mobilePrefixes ?? this.mobilePrefixes,
      states: states ?? this.states,
      cities: cities ?? this.cities,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      isSavingCompany: isSavingCompany ?? this.isSavingCompany,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      isUploadingProfilePhoto:
          isUploadingProfilePhoto ?? this.isUploadingProfilePhoto,
      isRequestingEmailOtp: isRequestingEmailOtp ?? this.isRequestingEmailOtp,
      isConfirmingEmailOtp: isConfirmingEmailOtp ?? this.isConfirmingEmailOtp,
      isRequestingWhatsAppOtp:
          isRequestingWhatsAppOtp ?? this.isRequestingWhatsAppOtp,
      isConfirmingWhatsAppOtp:
          isConfirmingWhatsAppOtp ?? this.isConfirmingWhatsAppOtp,
      isLoadingEmailSubscription:
          isLoadingEmailSubscription ?? this.isLoadingEmailSubscription,
      isSubscribingEmail: isSubscribingEmail ?? this.isSubscribingEmail,
      isLoadingLocalization:
          isLoadingLocalization ?? this.isLoadingLocalization,
      isSavingLocalization: isSavingLocalization ?? this.isSavingLocalization,
      isLoadingReferences: isLoadingReferences ?? this.isLoadingReferences,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      profileErrorMessage: identical(profileErrorMessage, _unset)
          ? this.profileErrorMessage
          : profileErrorMessage as String?,
      localizationErrorMessage: identical(localizationErrorMessage, _unset)
          ? this.localizationErrorMessage
          : localizationErrorMessage as String?,
    );
  }
}
