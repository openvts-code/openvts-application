import '../../../shared/models/user_role.dart';

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.username = '',
    this.profileUrl,
    this.phoneNumber,
    this.accountStatus,
    this.isVerified,
    this.mobilePrefix,
    this.mobileNumber,
    this.addressLine,
    this.countryCode,
    this.stateCode,
    this.cityName,
    this.pincode,
  });

  static const _unset = Object();

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String username;
  final String? profileUrl;
  final String? phoneNumber;
  final String? accountStatus;
  final bool? isVerified;
  final String? mobilePrefix;
  final String? mobileNumber;
  final String? addressLine;
  final String? countryCode;
  final String? stateCode;
  final String? cityName;
  final String? pincode;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    final mobilePrefix = _firstNonEmptyString([
      json['mobilePrefix'],
      json['mobile_prefix'],
      json['phonePrefix'],
      json['phone_prefix'],
    ]);
    final mobileNumber = _firstNonEmptyString([
      json['mobileNumber'],
      json['mobile_number'],
      json['mobile'],
      json['phoneNumber'],
      json['phone_number'],
      json['phone'],
      json['whatsappNumber'],
      json['whatsapp_number'],
    ]);
    final explicitPhoneNumber = _firstNonEmptyString([
      json['phoneDisplay'],
      json['phone_display'],
      json['contactNumber'],
      json['contact_number'],
      json['phone'],
      json['phoneNumber'],
      json['phone_number'],
      json['mobile'],
      json['mobileNumber'],
      json['mobile_number'],
      json['whatsapp'],
      json['whatsappNumber'],
      json['whatsapp_number'],
    ]);

    return CurrentUser(
      id: _firstNonEmptyString([
            json['id'],
            json['userId'],
            json['user_id'],
            json['uid'],
          ]) ??
          '',
      name: _firstNonEmptyString([
            json['name'],
            json['displayName'],
            json['display_name'],
            json['fullName'],
            json['full_name'],
            json['username'],
          ]) ??
          'OpenVTS User',
      email: _firstNonEmptyString([
            json['email'],
            json['primaryEmail'],
            json['primary_email'],
          ]) ??
          '',
      role: UserRole.fromString(
        _firstNonEmptyString([
          json['role'],
          json['userRole'],
          json['user_role'],
        ]),
      ),
      username: _firstNonEmptyString([
            json['username'],
            json['userName'],
            json['user_name'],
          ]) ??
          '',
      profileUrl: _firstNonEmptyString([
        json['profileUrl'],
        json['profileURL'],
        json['profile_url'],
        json['profileImage'],
        json['profile_image_url'],
        json['profile_image'],
        json['profilePicture'],
        json['profile_picture'],
        json['profilePhoto'],
        json['profile_photo'],
        json['profilePath'],
        json['profile_path'],
        json['profile'],
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
        json['filePath'],
        json['file_path'],
        json['filepath'],
      ]),
      phoneNumber: explicitPhoneNumber ??
          _composePhoneNumber(mobilePrefix, mobileNumber),
      accountStatus: _firstNonEmptyString([
        json['accountStatus'],
        json['account_status'],
        json['status'],
        json['userStatus'],
        json['user_status'],
      ]),
      isVerified: _parseBool(
        json['isVerified'] ??
            json['is_verified'] ??
            json['verified'] ??
            json['emailVerified'] ??
            json['email_verified'] ??
            json['mobileVerified'] ??
            json['mobile_verified'],
      ),
      mobilePrefix: mobilePrefix,
      mobileNumber: mobileNumber,
      addressLine: _firstNonEmptyString([
        json['addressLine'],
        json['address_line'],
        json['address'],
        json['streetAddress'],
        json['street_address'],
      ]),
      countryCode: _firstNonEmptyString([
        json['countryCode'],
        json['country_code'],
        json['country'],
      ]),
      stateCode: _firstNonEmptyString([
        json['stateCode'],
        json['state_code'],
        json['state'],
      ]),
      cityName: _firstNonEmptyString([
        json['cityName'],
        json['city_name'],
        json['city'],
      ]),
      pincode: _firstNonEmptyString([
        json['pincode'],
        json['pinCode'],
        json['pin_code'],
        json['postalCode'],
        json['postal_code'],
        json['zip'],
      ]),
    );
  }

  CurrentUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? username,
    Object? profileUrl = _unset,
    Object? phoneNumber = _unset,
    Object? accountStatus = _unset,
    Object? isVerified = _unset,
    Object? mobilePrefix = _unset,
    Object? mobileNumber = _unset,
    Object? addressLine = _unset,
    Object? countryCode = _unset,
    Object? stateCode = _unset,
    Object? cityName = _unset,
    Object? pincode = _unset,
  }) {
    return CurrentUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      username: username ?? this.username,
      profileUrl: identical(profileUrl, _unset)
          ? this.profileUrl
          : profileUrl as String?,
      phoneNumber: identical(phoneNumber, _unset)
          ? this.phoneNumber
          : phoneNumber as String?,
      accountStatus: identical(accountStatus, _unset)
          ? this.accountStatus
          : accountStatus as String?,
      isVerified:
          identical(isVerified, _unset) ? this.isVerified : isVerified as bool?,
      mobilePrefix: identical(mobilePrefix, _unset)
          ? this.mobilePrefix
          : mobilePrefix as String?,
      mobileNumber: identical(mobileNumber, _unset)
          ? this.mobileNumber
          : mobileNumber as String?,
      addressLine: identical(addressLine, _unset)
          ? this.addressLine
          : addressLine as String?,
      countryCode: identical(countryCode, _unset)
          ? this.countryCode
          : countryCode as String?,
      stateCode:
          identical(stateCode, _unset) ? this.stateCode : stateCode as String?,
      cityName:
          identical(cityName, _unset) ? this.cityName : cityName as String?,
      pincode: identical(pincode, _unset) ? this.pincode : pincode as String?,
    );
  }

  String? get resolvedPhoneNumber {
    return phoneNumber ?? _composePhoneNumber(mobilePrefix, mobileNumber);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.apiValue,
      'username': username,
      'profileUrl': profileUrl,
      'phoneNumber': phoneNumber,
      'accountStatus': accountStatus,
      'isVerified': isVerified,
      'mobilePrefix': mobilePrefix,
      'mobileNumber': mobileNumber,
      'addressLine': addressLine,
      'countryCode': countryCode,
      'stateCode': stateCode,
      'cityName': cityName,
      'pincode': pincode,
    };
  }

  static String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final normalized = value?.toString().trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase();
    switch (normalized) {
      case '1':
      case 'true':
      case 'yes':
      case 'verified':
      case 'approved':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'pending':
      case 'unverified':
        return false;
      default:
        return null;
    }
  }

  static String? _composePhoneNumber(String? prefix, String? number) {
    final normalizedPrefix = prefix?.trim();
    final normalizedNumber = number?.trim();

    if (normalizedNumber == null || normalizedNumber.isEmpty) {
      return null;
    }

    if (normalizedPrefix == null || normalizedPrefix.isEmpty) {
      return normalizedNumber;
    }

    return '$normalizedPrefix $normalizedNumber';
  }
}
