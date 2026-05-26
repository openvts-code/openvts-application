import 'dart:convert';

enum UserSettingsTab {
  profile,
  localization,
}

enum UserLayoutDirection {
  ltr,
  rtl;

  String get apiValue => this == UserLayoutDirection.rtl ? 'RTL' : 'LTR';

  static UserLayoutDirection fromValue(dynamic value) {
    final normalized = value?.toString().trim().toUpperCase();
    return normalized == 'RTL'
        ? UserLayoutDirection.rtl
        : UserLayoutDirection.ltr;
  }
}

enum UserThemeMode {
  light,
  dark,
  system;

  String get apiValue {
    switch (this) {
      case UserThemeMode.light:
        return 'LIGHT';
      case UserThemeMode.dark:
        return 'DARK';
      case UserThemeMode.system:
        return 'SYSTEM';
    }
  }

  static UserThemeMode fromValue(dynamic value) {
    final normalized = value?.toString().trim().toUpperCase();
    switch (normalized) {
      case 'LIGHT':
        return UserThemeMode.light;
      case 'DARK':
        return UserThemeMode.dark;
      default:
        return UserThemeMode.system;
    }
  }
}

enum UserDistanceUnit {
  km,
  miles;

  String get apiValue => this == UserDistanceUnit.miles ? 'MILES' : 'KM';

  static UserDistanceUnit fromValue(dynamic value) {
    final normalized = value?.toString().trim().toUpperCase();
    return normalized == 'MILES' ? UserDistanceUnit.miles : UserDistanceUnit.km;
  }
}

enum UserTimeFormat {
  h24,
  h12;

  String get apiValue => this == UserTimeFormat.h24 ? '24H' : '12H';

  bool get use24Hour => this == UserTimeFormat.h24;

  static UserTimeFormat fromValue(dynamic value) {
    final normalized = value?.toString().trim().toUpperCase();
    return normalized == '12H' ? UserTimeFormat.h12 : UserTimeFormat.h24;
  }
}

class UserSettingsSocialLinks {
  const UserSettingsSocialLinks({
    this.facebook,
    this.twitter,
    this.linkedin,
    this.instagram,
    this.youtube,
    this.github,
  });

  final String? facebook;
  final String? twitter;
  final String? linkedin;
  final String? instagram;
  final String? youtube;
  final String? github;

  bool get isEmpty {
    return [facebook, twitter, linkedin, instagram, youtube, github]
        .every((value) => value == null || value.trim().isEmpty);
  }

  factory UserSettingsSocialLinks.fromDynamic(dynamic json) {
    final source = _parseJsonMapIfString(json);
    return UserSettingsSocialLinks(
      facebook: _readNullableString(source, const ['facebook']),
      twitter: _readNullableString(source, const ['twitter', 'x']),
      linkedin: _readNullableString(source, const ['linkedin']),
      instagram: _readNullableString(source, const ['instagram']),
      youtube: _readNullableString(source, const ['youtube']),
      github: _readNullableString(source, const ['github']),
    );
  }

  Map<String, dynamic> toJsonNonEmpty() {
    final map = <String, dynamic>{};
    void put(
      String key,
      String? value, {
      bool normalizeAsUrl = false,
    }) {
      final normalized =
          normalizeAsUrl ? _normalizeOptionalUrl(value) : value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        map[key] = normalized;
      }
    }

    put('facebook', facebook, normalizeAsUrl: true);
    put('twitter', twitter, normalizeAsUrl: true);
    put('linkedin', linkedin, normalizeAsUrl: true);
    put('instagram', instagram, normalizeAsUrl: true);
    put('youtube', youtube, normalizeAsUrl: true);
    put('github', github, normalizeAsUrl: true);

    return map;
  }

  UserSettingsSocialLinks copyWith({
    String? facebook,
    String? twitter,
    String? linkedin,
    String? instagram,
    String? youtube,
    String? github,
  }) {
    return UserSettingsSocialLinks(
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      linkedin: linkedin ?? this.linkedin,
      instagram: instagram ?? this.instagram,
      youtube: youtube ?? this.youtube,
      github: github ?? this.github,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserSettingsSocialLinks &&
        other.facebook == facebook &&
        other.twitter == twitter &&
        other.linkedin == linkedin &&
        other.instagram == instagram &&
        other.youtube == youtube &&
        other.github == github;
  }

  @override
  int get hashCode =>
      Object.hash(facebook, twitter, linkedin, instagram, youtube, github);
}

class UserSettingsCompany {
  const UserSettingsCompany({
    this.id,
    this.name,
    this.websiteUrl,
    this.customDomain,
    this.socialLinks,
    this.logoLightUrl,
    this.logoDarkUrl,
    this.faviconUrl,
    this.primaryColor,
  });

  final int? id;
  final String? name;
  final String? websiteUrl;
  final String? customDomain;
  final UserSettingsSocialLinks? socialLinks;
  final String? logoLightUrl;
  final String? logoDarkUrl;
  final String? faviconUrl;
  final String? primaryColor;

  factory UserSettingsCompany.fromDynamic(dynamic json) {
    final source = _asMap(json);
    final links = UserSettingsSocialLinks.fromDynamic(source['socialLinks']);

    return UserSettingsCompany(
      id: _readInt(source, const ['id', 'companyId']),
      name: _readNullableString(source, const ['name', 'companyName', 'Name']),
      websiteUrl: _readNullableString(source, const ['websiteUrl', 'website']),
      customDomain:
          _readNullableString(source, const ['customDomain', 'domain']),
      socialLinks: links.isEmpty ? null : links,
      logoLightUrl:
          _readNullableString(source, const ['logoLightUrl', 'logoLight']),
      logoDarkUrl:
          _readNullableString(source, const ['logoDarkUrl', 'logoDark']),
      faviconUrl: _readNullableString(source, const ['faviconUrl', 'favicon']),
      primaryColor:
          _readNullableString(source, const ['primaryColor', 'color']),
    );
  }

  UserSettingsCompany copyWith({
    int? id,
    String? name,
    String? websiteUrl,
    String? customDomain,
    UserSettingsSocialLinks? socialLinks,
    String? logoLightUrl,
    String? logoDarkUrl,
    String? faviconUrl,
    String? primaryColor,
  }) {
    return UserSettingsCompany(
      id: id ?? this.id,
      name: name ?? this.name,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      customDomain: customDomain ?? this.customDomain,
      socialLinks: socialLinks ?? this.socialLinks,
      logoLightUrl: logoLightUrl ?? this.logoLightUrl,
      logoDarkUrl: logoDarkUrl ?? this.logoDarkUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserSettingsCompany &&
        other.id == id &&
        other.name == name &&
        other.websiteUrl == websiteUrl &&
        other.customDomain == customDomain &&
        other.socialLinks == socialLinks &&
        other.logoLightUrl == logoLightUrl &&
        other.logoDarkUrl == logoDarkUrl &&
        other.faviconUrl == faviconUrl &&
        other.primaryColor == primaryColor;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        websiteUrl,
        customDomain,
        socialLinks,
        logoLightUrl,
        logoDarkUrl,
        faviconUrl,
        primaryColor,
      );
}

class UserSettingsAddress {
  const UserSettingsAddress({
    this.id,
    this.addressLine,
    this.countryCode,
    this.stateCode,
    this.cityName,
    this.cityId,
    this.pincode,
    this.fullAddress,
  });

  final int? id;
  final String? addressLine;
  final String? countryCode;
  final String? stateCode;
  final String? cityName;
  final int? cityId;
  final String? pincode;
  final String? fullAddress;

  factory UserSettingsAddress.fromDynamic(dynamic json) {
    final source = _asMap(json);
    return UserSettingsAddress(
      id: _readInt(source, const ['id', 'addressId']),
      addressLine: _readNullableString(
        source,
        const ['addressLine', 'address', 'line'],
      ),
      countryCode: _readNullableString(
        source,
        const ['countryCode', 'country'],
      ),
      stateCode: _readNullableString(source, const ['stateCode', 'state']),
      cityName: _readNullableString(
        source,
        const ['cityName', 'city', 'cityId'],
      ),
      cityId: _readInt(source, const ['cityId']),
      pincode: _readNullableString(
        source,
        const ['pincode', 'pinCode', 'zip', 'zipCode'],
      ),
      fullAddress: _readNullableString(
        source,
        const ['fullAddress', 'formatted'],
      ),
    );
  }

  UserSettingsAddress copyWith({
    int? id,
    String? addressLine,
    String? countryCode,
    String? stateCode,
    String? cityName,
    int? cityId,
    String? pincode,
    String? fullAddress,
  }) {
    return UserSettingsAddress(
      id: id ?? this.id,
      addressLine: addressLine ?? this.addressLine,
      countryCode: countryCode ?? this.countryCode,
      stateCode: stateCode ?? this.stateCode,
      cityName: cityName ?? this.cityName,
      cityId: cityId ?? this.cityId,
      pincode: pincode ?? this.pincode,
      fullAddress: fullAddress ?? this.fullAddress,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserSettingsAddress &&
        other.id == id &&
        other.addressLine == addressLine &&
        other.countryCode == countryCode &&
        other.stateCode == stateCode &&
        other.cityName == cityName &&
        other.cityId == cityId &&
        other.pincode == pincode &&
        other.fullAddress == fullAddress;
  }

  @override
  int get hashCode => Object.hash(
        id,
        addressLine,
        countryCode,
        stateCode,
        cityName,
        cityId,
        pincode,
        fullAddress,
      );
}

class UserSettingsProfile {
  const UserSettingsProfile({
    this.uid,
    this.name,
    this.username,
    this.email,
    this.mobilePrefix,
    this.mobileNumber,
    this.profileUrl,
    this.credits,
    this.createdAt,
    this.updatedAt,
    this.isEmailVerified = false,
    this.emailVerifiedAt,
    this.isMobileVerified = false,
    this.mobileVerifiedAt,
    this.company,
    this.address,
  });

  final int? uid;
  final String? name;
  final String? username;
  final String? email;
  final String? mobilePrefix;
  final String? mobileNumber;
  final String? profileUrl;
  final double? credits;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isEmailVerified;
  final DateTime? emailVerifiedAt;
  final bool isMobileVerified;
  final DateTime? mobileVerifiedAt;
  final UserSettingsCompany? company;
  final UserSettingsAddress? address;

  factory UserSettingsProfile.fromDynamic(dynamic json) {
    final source = _extractProfilePayload(json);

    Map<String, dynamic>? companyMap;
    final directCompany = _asMap(source['company']);
    if (directCompany.isNotEmpty) {
      companyMap = directCompany;
    } else {
      final companies = source['companies'];
      if (companies is List && companies.isNotEmpty) {
        final first = _asMap(companies.first);
        if (first.isNotEmpty) {
          companyMap = first;
        }
      }
    }

    Map<String, dynamic>? addressMap;
    final directAddress = _asMap(source['address']);
    if (directAddress.isNotEmpty) {
      addressMap = directAddress;
    }

    return UserSettingsProfile(
      uid: _readInt(source, const ['uid', 'id', 'userId', 'user_id']),
      name: _readNullableString(source, const ['name', 'Name', 'fullName']),
      username: _readNullableString(source, const ['username', 'userName']),
      email: _readNullableString(source, const ['email']),
      mobilePrefix: _readNullableString(
        source,
        const ['mobilePrefix', 'phonePrefix', 'mobile_prefix'],
      ),
      mobileNumber: _readNullableString(
        source,
        const ['mobileNumber', 'phoneNumber', 'mobile', 'mobile_number'],
      ),
      profileUrl: _readNullableString(
        source,
        const ['profileUrl', 'avatar', 'profile', 'image', 'url'],
      ),
      credits: _readDouble(source, const ['credits', 'balance']),
      createdAt: _readDateTime(source, const ['createdAt', 'created']),
      updatedAt: _readDateTime(source, const ['updatedAt', 'modified']),
      isEmailVerified: _readBool(
            source,
            const ['isEmailVerified', 'emailVerified', 'is_email_verified'],
          ) ??
          false,
      emailVerifiedAt: _readDateTime(source, const ['emailVerifiedAt']),
      isMobileVerified: _readBool(
            source,
            const ['isMobileVerified', 'mobileVerified', 'is_mobile_verified'],
          ) ??
          false,
      mobileVerifiedAt: _readDateTime(source, const ['mobileVerifiedAt']),
      company: companyMap == null
          ? null
          : UserSettingsCompany.fromDynamic(companyMap),
      address: addressMap == null
          ? null
          : UserSettingsAddress.fromDynamic(addressMap),
    );
  }

  UserSettingsProfile copyWith({
    int? uid,
    String? name,
    String? username,
    String? email,
    String? mobilePrefix,
    String? mobileNumber,
    String? profileUrl,
    double? credits,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    DateTime? emailVerifiedAt,
    bool? isMobileVerified,
    DateTime? mobileVerifiedAt,
    UserSettingsCompany? company,
    UserSettingsAddress? address,
  }) {
    return UserSettingsProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      mobilePrefix: mobilePrefix ?? this.mobilePrefix,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profileUrl: profileUrl ?? this.profileUrl,
      credits: credits ?? this.credits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      isMobileVerified: isMobileVerified ?? this.isMobileVerified,
      mobileVerifiedAt: mobileVerifiedAt ?? this.mobileVerifiedAt,
      company: company ?? this.company,
      address: address ?? this.address,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserSettingsProfile &&
        other.uid == uid &&
        other.name == name &&
        other.username == username &&
        other.email == email &&
        other.mobilePrefix == mobilePrefix &&
        other.mobileNumber == mobileNumber &&
        other.profileUrl == profileUrl &&
        other.credits == credits &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isEmailVerified == isEmailVerified &&
        other.emailVerifiedAt == emailVerifiedAt &&
        other.isMobileVerified == isMobileVerified &&
        other.mobileVerifiedAt == mobileVerifiedAt &&
        other.company == company &&
        other.address == address;
  }

  @override
  int get hashCode => Object.hash(
        uid,
        name,
        username,
        email,
        mobilePrefix,
        mobileNumber,
        profileUrl,
        credits,
        createdAt,
        updatedAt,
        isEmailVerified,
        emailVerifiedAt,
        isMobileVerified,
        mobileVerifiedAt,
        company,
        address,
      );
}

class UserEmailSubscriptionStatus {
  const UserEmailSubscriptionStatus({
    required this.isSubscribed,
    this.brandOwnerId,
    this.scope,
  });

  final bool isSubscribed;
  final int? brandOwnerId;
  final String? scope;

  factory UserEmailSubscriptionStatus.fromDynamic(dynamic json) {
    if (json is bool) {
      return UserEmailSubscriptionStatus(isSubscribed: json);
    }

    final source = _asMap(json);
    if (source.isEmpty) {
      return const UserEmailSubscriptionStatus(isSubscribed: false);
    }

    final nested = _asMap(source['data']);
    final isSubscribed = _readBool(
          source,
          const ['isSubscribed', 'subscribed', 'value'],
        ) ??
        _readBool(
          nested,
          const ['isSubscribed', 'subscribed', 'value'],
        ) ??
        false;

    return UserEmailSubscriptionStatus(
      isSubscribed: isSubscribed,
      brandOwnerId: _readInt(source, const ['brandOwnerId']) ??
          _readInt(nested, const ['brandOwnerId']),
      scope: _readNullableString(source, const ['scope']) ??
          _readNullableString(nested, const ['scope']),
    );
  }

  UserEmailSubscriptionStatus copyWith({
    bool? isSubscribed,
    int? brandOwnerId,
    String? scope,
  }) {
    return UserEmailSubscriptionStatus(
      isSubscribed: isSubscribed ?? this.isSubscribed,
      brandOwnerId: brandOwnerId ?? this.brandOwnerId,
      scope: scope ?? this.scope,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserEmailSubscriptionStatus &&
        other.isSubscribed == isSubscribed &&
        other.brandOwnerId == brandOwnerId &&
        other.scope == scope;
  }

  @override
  int get hashCode => Object.hash(isSubscribed, brandOwnerId, scope);
}

class UserUpdateProfileRequest {
  const UserUpdateProfileRequest({
    required this.name,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.addressLine,
    required this.countryCode,
    required this.stateCode,
    required this.cityName,
    this.email,
    this.pincode,
  });

  final String name;
  final String? email;
  final String mobilePrefix;
  final String mobileNumber;
  final String addressLine;
  final String countryCode;
  final String stateCode;
  final String cityName;
  final String? pincode;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'mobilePrefix': mobilePrefix.trim(),
      'mobileNumber': mobileNumber.trim(),
      'addressLine': addressLine.trim(),
      'countryCode': countryCode.trim().toUpperCase(),
      'stateCode': stateCode.trim().toUpperCase(),
      'cityName': cityName.trim(),
    };

    final normalizedEmail = email?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      payload['email'] = normalizedEmail;
    }

    final normalizedPincode = pincode?.trim();
    if (normalizedPincode != null && normalizedPincode.isNotEmpty) {
      payload['pincode'] = normalizedPincode;
    }

    return payload;
  }
}

class UserUpdateCompanyRequest {
  const UserUpdateCompanyRequest({
    this.name,
    this.websiteUrl,
    this.customDomain,
    this.socialLinks,
    this.primaryColor,
  });

  final String? name;
  final String? websiteUrl;
  final String? customDomain;
  final UserSettingsSocialLinks? socialLinks;
  final String? primaryColor;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};

    final normalizedName = name?.trim();
    if (normalizedName != null && normalizedName.isNotEmpty) {
      payload['name'] = normalizedName;
    }

    final normalizedWebsite = _normalizeOptionalUrl(websiteUrl);
    if (normalizedWebsite != null) {
      payload['websiteUrl'] = normalizedWebsite;
    }

    final normalizedDomain = _normalizeOptionalUrl(customDomain);
    if (normalizedDomain != null) {
      payload['customDomain'] = normalizedDomain;
    }

    final normalizedSocialLinks = socialLinks?.toJsonNonEmpty();
    if (normalizedSocialLinks != null && normalizedSocialLinks.isNotEmpty) {
      payload['socialLinks'] = normalizedSocialLinks;
    }

    final normalizedColor = primaryColor?.trim();
    if (normalizedColor != null && normalizedColor.isNotEmpty) {
      payload['primaryColor'] = normalizedColor;
    }

    return payload;
  }
}

class UserChangePasswordRequest {
  const UserChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
}

class UserOtpConfirmRequest {
  const UserOtpConfirmRequest({required this.otp});

  final String otp;

  Map<String, dynamic> toJson() => <String, dynamic>{'otp': otp.trim()};
}

class UserLocalizationSettings {
  const UserLocalizationSettings({
    this.language = 'en',
    this.layoutDirection = UserLayoutDirection.ltr,
    this.dateFormat = 'YYYY-MM-DD',
    this.use24Hour = true,
    this.theme = UserThemeMode.system,
    this.timezoneOffset = '+05:30',
    this.units = UserDistanceUnit.km,
    this.defaultLat = 37.7749,
    this.defaultLon = -122.4194,
    this.mapZoom = 10,
  });

  final String language;
  final UserLayoutDirection layoutDirection;
  final String dateFormat;
  final bool use24Hour;
  final UserThemeMode theme;
  final String timezoneOffset;
  final UserDistanceUnit units;
  final double defaultLat;
  final double defaultLon;
  final int mapZoom;

  static const UserLocalizationSettings defaults = UserLocalizationSettings();

  factory UserLocalizationSettings.fromDynamic(dynamic json) {
    final source = _extractLocalizationPayload(json);
    if (source.isEmpty) {
      return defaults;
    }

    final language =
        _readNullableString(source, const ['language', 'languageCode']) ??
            defaults.language;

    final rawDirection = source['layoutDirection'] ?? source['direction'];
    final layoutDirection = UserLayoutDirection.fromValue(rawDirection);

    final dateFormat = _readNullableString(source, const ['dateFormat']) ??
        defaults.dateFormat;

    final use24Hour = _readBool(source, const ['use24Hour']) ??
        UserTimeFormat.fromValue(source['timeFormat']).use24Hour;

    final rawTheme = source['theme'];
    final theme = UserThemeMode.fromValue(rawTheme);

    final timezoneOffset = _normalizeTimezoneOffset(
      _readNullableString(source, const ['timezoneOffset', 'timezone']) ??
          defaults.timezoneOffset,
    );

    final rawUnits = source['units'] ?? source['distanceUnit'];
    final units = UserDistanceUnit.fromValue(rawUnits);

    final defaultLat = _readDouble(
          source,
          const ['defaultLat', 'mapLat'],
        ) ??
        defaults.defaultLat;

    final defaultLon = _readDouble(
          source,
          const ['defaultLon', 'defaultLng', 'mapLng'],
        ) ??
        defaults.defaultLon;

    final mapZoom =
        _readInt(source, const ['mapZoom', 'zoom']) ?? defaults.mapZoom;

    return UserLocalizationSettings(
      language: language,
      layoutDirection: layoutDirection,
      dateFormat: dateFormat,
      use24Hour: use24Hour,
      theme: theme,
      timezoneOffset: timezoneOffset,
      units: units,
      defaultLat: defaultLat,
      defaultLon: defaultLon,
      mapZoom: mapZoom,
    );
  }

  UserLocalizationSettings copyWith({
    String? language,
    UserLayoutDirection? layoutDirection,
    String? dateFormat,
    bool? use24Hour,
    UserThemeMode? theme,
    String? timezoneOffset,
    UserDistanceUnit? units,
    double? defaultLat,
    double? defaultLon,
    int? mapZoom,
  }) {
    return UserLocalizationSettings(
      language: language ?? this.language,
      layoutDirection: layoutDirection ?? this.layoutDirection,
      dateFormat: dateFormat ?? this.dateFormat,
      use24Hour: use24Hour ?? this.use24Hour,
      theme: theme ?? this.theme,
      timezoneOffset: timezoneOffset ?? this.timezoneOffset,
      units: units ?? this.units,
      defaultLat: defaultLat ?? this.defaultLat,
      defaultLon: defaultLon ?? this.defaultLon,
      mapZoom: mapZoom ?? this.mapZoom,
    );
  }

  Map<String, dynamic> toPatchJson() => <String, dynamic>{
        'languageCode': language,
        'direction': layoutDirection.apiValue,
        'dateFormat': dateFormat,
        'theme': theme.apiValue,
        'timezone': timezoneOffset,
        'timeFormat': use24Hour ? '24H' : '12H',
        'distanceUnit': units.apiValue,
        'defaultLat': defaultLat,
        'defaultLon': defaultLon,
        'mapZoom': mapZoom,
      };

  @override
  bool operator ==(Object other) {
    return other is UserLocalizationSettings &&
        other.language == language &&
        other.layoutDirection == layoutDirection &&
        other.dateFormat == dateFormat &&
        other.use24Hour == use24Hour &&
        other.theme == theme &&
        other.timezoneOffset == timezoneOffset &&
        other.units == units &&
        other.defaultLat == defaultLat &&
        other.defaultLon == defaultLon &&
        other.mapZoom == mapZoom;
  }

  @override
  int get hashCode => Object.hash(
        language,
        layoutDirection,
        dateFormat,
        use24Hour,
        theme,
        timezoneOffset,
        units,
        defaultLat,
        defaultLon,
        mapZoom,
      );
}

class UserLanguageOption {
  const UserLanguageOption({
    required this.code,
    required this.label,
  });

  final String code;
  final String label;

  factory UserLanguageOption.fromDynamic(dynamic json) {
    if (json is String) {
      final normalized = json.trim();
      return UserLanguageOption(
        code: normalized,
        label: normalized.toUpperCase(),
      );
    }

    final source = _asMap(json);
    final code =
        _readNullableString(source, const ['code', 'value', 'key']) ?? '';
    final label =
        _readNullableString(source, const ['label', 'name', 'title']) ?? code;
    return UserLanguageOption(code: code, label: label);
  }

  static List<UserLanguageOption> listFromDynamic(dynamic json) {
    final list = _extractList(
      json,
      preferredKeys: const ['languages', 'items', 'data', 'list'],
    );

    final options = list
        .map(UserLanguageOption.fromDynamic)
        .where((item) => item.code.trim().isNotEmpty)
        .toList(growable: false);

    return _distinctByKey(options, (item) => item.code.toLowerCase());
  }

  @override
  bool operator ==(Object other) {
    return other is UserLanguageOption &&
        other.code == code &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(code, label);
}

class UserDateFormatOption {
  const UserDateFormatOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  factory UserDateFormatOption.fromDynamic(dynamic json) {
    if (json is String) {
      final normalized = json.trim();
      return UserDateFormatOption(value: normalized, label: normalized);
    }

    final source = _asMap(json);
    final value =
        _readNullableString(source, const ['value', 'format', 'code']) ?? '';
    final label =
        _readNullableString(source, const ['label', 'name', 'title']) ?? value;
    return UserDateFormatOption(value: value, label: label);
  }

  static List<UserDateFormatOption> listFromDynamic(dynamic json) {
    final list = _extractList(
      json,
      preferredKeys: const ['dateFormats', 'items', 'data', 'list'],
    );

    final options = list
        .map(UserDateFormatOption.fromDynamic)
        .where((item) => item.value.trim().isNotEmpty)
        .toList(growable: false);

    return _distinctByKey(options, (item) => item.value);
  }

  @override
  bool operator ==(Object other) {
    return other is UserDateFormatOption &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(value, label);
}

class UserCountryOption {
  const UserCountryOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static List<UserCountryOption> listFromDynamic(dynamic json) {
    final options = _extractOptionList(json)
        .map((item) {
          final primitive = _parseString(item);
          if (primitive != null) {
            final value = primitive.toUpperCase();
            return UserCountryOption(value: value, label: primitive);
          }

          final source = _asMap(item);
          if (source.isEmpty) {
            return const UserCountryOption(value: '', label: '');
          }

          final value = (_readNullableString(
                    source,
                    const [
                      'countryCode',
                      'country_code',
                      'code',
                      'iso2',
                      'country'
                    ],
                  ) ??
                  '')
              .toUpperCase();
          final label = _readNullableString(
                source,
                const ['name', 'countryName', 'country_name', 'label'],
              ) ??
              value;
          return UserCountryOption(value: value, label: label);
        })
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);

    return _distinctByKey(options, (item) => item.value);
  }

  @override
  bool operator ==(Object other) {
    return other is UserCountryOption &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(value, label);
}

class UserStateOption {
  const UserStateOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static List<UserStateOption> listFromDynamic(dynamic json) {
    final options = _extractOptionList(json)
        .map((item) {
          final primitive = _parseString(item);
          if (primitive != null) {
            return UserStateOption(
              value: primitive.toUpperCase(),
              label: primitive,
            );
          }

          final source = _asMap(item);
          if (source.isEmpty) {
            return const UserStateOption(value: '', label: '');
          }

          final value = (_readNullableString(
                    source,
                    const [
                      'stateCode',
                      'state_code',
                      'code',
                      'iso2',
                      'state',
                      'value'
                    ],
                  ) ??
                  '')
              .toUpperCase();
          final label = _readNullableString(
                source,
                const ['name', 'stateName', 'state_name', 'label'],
              ) ??
              value;
          return UserStateOption(value: value, label: label);
        })
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);

    return _distinctByKey(options, (item) => item.value);
  }

  @override
  bool operator ==(Object other) {
    return other is UserStateOption &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(value, label);
}

class UserCityOption {
  const UserCityOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static List<UserCityOption> listFromDynamic(dynamic json) {
    final options = _extractOptionList(json)
        .map((item) {
          final primitive = _parseString(item);
          if (primitive != null) {
            return UserCityOption(value: primitive, label: primitive);
          }

          final source = _asMap(item);
          if (source.isEmpty) {
            return const UserCityOption(value: '', label: '');
          }

          final value = _readNullableString(
                source,
                const [
                  'name',
                  'cityName',
                  'city_name',
                  'city',
                  'value',
                  'cityId',
                  'city_id',
                  'id',
                ],
              ) ??
              '';
          final label = _readNullableString(
                source,
                const ['name', 'cityName', 'city_name', 'city', 'label'],
              ) ??
              value;
          return UserCityOption(value: value, label: label);
        })
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);

    return _distinctByKey(options, (item) => item.value);
  }

  @override
  bool operator ==(Object other) {
    return other is UserCityOption &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(value, label);
}

class UserMobilePrefixOption {
  const UserMobilePrefixOption({
    required this.value,
    required this.label,
    required this.countryCode,
  });

  final String value;
  final String label;
  final String countryCode;

  static List<UserMobilePrefixOption> listFromDynamic(dynamic json) {
    final options = _extractOptionList(json)
        .map((item) {
          final primitive = _parseString(item);
          if (primitive != null) {
            final value = _normalizeDialCode(primitive);
            return UserMobilePrefixOption(
              value: value,
              label: value,
              countryCode: '',
            );
          }

          final source = _asMap(item);
          if (source.isEmpty) {
            return const UserMobilePrefixOption(
              value: '',
              label: '',
              countryCode: '',
            );
          }

          final countryCode = (_readNullableString(
                    source,
                    const ['countryCode', 'country_code', 'country', 'iso2'],
                  ) ??
                  '')
              .toUpperCase();
          final value = _normalizeDialCode(
            _readNullableString(
                  source,
                  const [
                    'mobilePrefix',
                    'mobile_prefix',
                    'dialCode',
                    'dial_code',
                    'code',
                    'prefix',
                    'value',
                  ],
                ) ??
                '',
          );
          final countryName = _readNullableString(
            source,
            const ['name', 'countryName', 'country_name', 'label'],
          );

          final label = [
            value,
            if (countryCode.isNotEmpty) countryCode else countryName,
          ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

          return UserMobilePrefixOption(
            value: value,
            label: label.isEmpty ? value : label,
            countryCode: countryCode,
          );
        })
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);

    return _distinctByKey(options, (item) => item.value);
  }

  @override
  bool operator ==(Object other) {
    return other is UserMobilePrefixOption &&
        other.value == value &&
        other.label == label &&
        other.countryCode == countryCode;
  }

  @override
  int get hashCode => Object.hash(value, label, countryCode);
}

Map<String, dynamic> _extractProfilePayload(dynamic source) {
  final root = _asMap(source);
  if (root.isEmpty) {
    return const <String, dynamic>{};
  }

  if (_looksLikeProfilePayload(root)) {
    return root;
  }

  for (final key in const ['data', 'profile', 'user', 'result']) {
    final nested = _extractProfilePayload(root[key]);
    if (nested.isNotEmpty) {
      return nested;
    }
  }

  return root;
}

bool _looksLikeProfilePayload(Map<String, dynamic> map) {
  for (final key in const [
    'uid',
    'id',
    'userId',
    'name',
    'email',
    'mobileNumber',
    'phoneNumber',
    'mobile',
    'profileUrl',
    'profile_url',
    'isEmailVerified',
    'isMobileVerified',
    'address',
    'company',
    'companies',
  ]) {
    if (map.containsKey(key)) {
      return true;
    }
  }

  return false;
}

Map<String, dynamic> _extractLocalizationPayload(dynamic source) {
  final root = _asMap(source);
  if (root.isEmpty) {
    return const <String, dynamic>{};
  }

  if (_looksLikeLocalizationPayload(root)) {
    return root;
  }

  for (final key in const ['data', 'settings', 'localization', 'result']) {
    final nested = _extractLocalizationPayload(root[key]);
    if (nested.isNotEmpty) {
      return nested;
    }
  }

  return root;
}

bool _looksLikeLocalizationPayload(Map<String, dynamic> map) {
  for (final key in const [
    'language',
    'languageCode',
    'layoutDirection',
    'direction',
    'dateFormat',
    'use24Hour',
    'timeFormat',
    'theme',
    'timezoneOffset',
    'timezone',
    'units',
    'distanceUnit',
    'defaultLat',
    'mapLat',
    'defaultLon',
    'defaultLng',
    'mapLng',
    'mapZoom',
    'zoom',
  ]) {
    if (map.containsKey(key)) {
      return true;
    }
  }

  return false;
}

Map<String, dynamic> _parseJsonMapIfString(dynamic value) {
  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return const <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(normalized);
      return _asMap(decoded);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  return _asMap(value);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }

  return const <String, dynamic>{};
}

List<dynamic> _extractList(
  dynamic source, {
  List<String> preferredKeys = const <String>['items', 'rows', 'data', 'list'],
}) {
  if (source is List) {
    return source;
  }

  final root = _asMap(source);
  if (root.isEmpty) {
    return const <dynamic>[];
  }

  for (final key in preferredKeys) {
    final value = root[key];
    if (value is List) {
      return value;
    }
  }

  for (final nestedKey in const ['data', 'result', 'payload']) {
    final nested = _asMap(root[nestedKey]);
    if (nested.isEmpty) {
      continue;
    }

    for (final key in preferredKeys) {
      final value = nested[key];
      if (value is List) {
        return value;
      }
    }
  }

  return const <dynamic>[];
}

List<dynamic> _extractOptionList(dynamic source) {
  return _extractList(
    source,
    preferredKeys: const <String>[
      'items',
      'rows',
      'data',
      'list',
      'countries',
      'states',
      'cities',
      'prefixes',
      'languages',
      'dateFormats',
      'timezones',
    ],
  );
}

String? _readNullableString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    final normalized = value?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }

  return null;
}

int? _readInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    final parsed = _toInt(value);
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

double? _readDouble(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    final parsed = _toDouble(value);
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

bool? _readBool(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    final parsed = _toBool(value);
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

DateTime? _readDateTime(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    final parsed = _toDateTime(value);
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

int? _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return int.tryParse(normalized);
}

double? _toDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return double.tryParse(normalized);
}

bool? _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().trim().toLowerCase();
  switch (normalized) {
    case 'true':
    case '1':
    case 'yes':
    case 'y':
    case 'verified':
      return true;
    case 'false':
    case '0':
    case 'no':
    case 'n':
    case 'unverified':
      return false;
    default:
      return null;
  }
}

DateTime? _toDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return DateTime.tryParse(normalized);
}

String? _parseString(dynamic value) {
  if (value is String) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  if (value is num || value is bool) {
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  return null;
}

String _normalizeDialCode(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return '';
  }

  if (normalized.startsWith('+')) {
    return '+${normalized.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';
  }

  final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return '';
  }

  return '+$digits';
}

String? _normalizeOptionalUrl(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return normalized;
  }

  return 'https://$normalized';
}

String _normalizeTimezoneOffset(String value) {
  final normalized = value.trim();
  if (_isTimezoneOffset(normalized)) {
    return normalized;
  }

  return UserLocalizationSettings.defaults.timezoneOffset;
}

bool _isTimezoneOffset(String value) {
  final pattern = RegExp(r'^([+-])(\d{2}):(\d{2})$');
  final match = pattern.firstMatch(value);
  if (match == null) {
    return false;
  }

  final hh = int.tryParse(match.group(2) ?? '');
  final mm = int.tryParse(match.group(3) ?? '');
  if (hh == null || mm == null) {
    return false;
  }

  return hh >= 0 && hh <= 23 && mm >= 0 && mm <= 59;
}

List<T> _distinctByKey<T>(List<T> values, String Function(T value) keyOf) {
  final result = <T>[];
  final seen = <String>{};

  for (final value in values) {
    final key = keyOf(value);
    if (seen.contains(key)) {
      continue;
    }
    seen.add(key);
    result.add(value);
  }

  return result;
}
