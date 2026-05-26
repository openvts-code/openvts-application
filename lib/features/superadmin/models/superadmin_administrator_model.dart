import 'package:intl/intl.dart';

enum SuperadminAdministratorSortOption {
  recentLogin,
  nameAscending,
  nameDescending,
  vehiclesDescending,
  usersDescending;

  String get label {
    switch (this) {
      case SuperadminAdministratorSortOption.recentLogin:
        return 'Recently active';
      case SuperadminAdministratorSortOption.nameAscending:
        return 'Name A-Z';
      case SuperadminAdministratorSortOption.nameDescending:
        return 'Name Z-A';
      case SuperadminAdministratorSortOption.vehiclesDescending:
        return 'Most vehicles';
      case SuperadminAdministratorSortOption.usersDescending:
        return 'Most users';
    }
  }
}

enum SuperadminAdministratorRoleFilter {
  all,
  superadmin,
  admin;

  String get label {
    switch (this) {
      case SuperadminAdministratorRoleFilter.all:
        return 'All roles';
      case SuperadminAdministratorRoleFilter.superadmin:
        return 'Super Admin';
      case SuperadminAdministratorRoleFilter.admin:
        return 'Admin';
    }
  }
}

enum SuperadminAdministratorStatusFilter {
  all,
  active,
  inactive;

  String get label {
    switch (this) {
      case SuperadminAdministratorStatusFilter.all:
        return 'All statuses';
      case SuperadminAdministratorStatusFilter.active:
        return 'Active';
      case SuperadminAdministratorStatusFilter.inactive:
        return 'Inactive';
    }
  }
}

class SuperadminAdministratorPage {
  const SuperadminAdministratorPage({
    required this.items,
    required this.totalCount,
  });

  final List<SuperadminAdministrator> items;
  final int totalCount;

  factory SuperadminAdministratorPage.fromJson(dynamic json) {
    final map = _asMap(json);
    final list = _extractList(json);
    final items = list
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(SuperadminAdministrator.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);

    final totalCount = _firstInt(
          map,
          const ['total', 'count', 'totalCount', 'records', 'totalRecords'],
        ) ??
        _firstInt(
          _firstMap(map, const ['meta', 'pagination', 'summary']) ??
              const <String, dynamic>{},
          const ['total', 'count', 'totalCount', 'records', 'totalRecords'],
        ) ??
        items.length;

    return SuperadminAdministratorPage(
      items: items,
      totalCount: totalCount,
    );
  }
}

class SuperadminAdministrator {
  const SuperadminAdministrator({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    required this.companyName,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.countryCode,
    required this.countryName,
    required this.stateCode,
    required this.stateName,
    required this.cityName,
    required this.address,
    required this.pincode,
    required this.primaryContact,
    required this.totalVehicles,
    required this.totalUsers,
    required this.totalCredits,
    required this.isActive,
    required this.isVerified,
    required this.lastLoginAt,
    required this.lastLoginText,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String role;
  final String companyName;
  final String mobilePrefix;
  final String mobileNumber;
  final String countryCode;
  final String countryName;
  final String stateCode;
  final String stateName;
  final String cityName;
  final String address;
  final String pincode;
  final String primaryContact;
  final int totalVehicles;
  final int totalUsers;
  final int totalCredits;
  final bool isActive;
  final bool isVerified;
  final DateTime? lastLoginAt;
  final String? lastLoginText;
  final DateTime? createdAt;

  factory SuperadminAdministrator.fromJson(Map<String, dynamic> json) {
    final nestedIdentity = _firstMap(
          json,
          const ['admin', 'user', 'profile', 'details'],
        ) ??
        const <String, dynamic>{};
    final nestedCounts = _firstMap(
          json,
          const ['counts', 'summary', 'stats', 'totals'],
        ) ??
        const <String, dynamic>{};
    final nestedCredits = _firstMap(
          json,
          const ['credits', 'credit', 'wallet', 'subscription', 'licenses'],
        ) ??
        _firstMap(
          nestedCounts,
          const ['credits', 'credit', 'wallet', 'subscription', 'licenses'],
        ) ??
        const <String, dynamic>{};
    final rawRole = _firstString(
          json,
          const [
            'role',
            'userRole',
            'user_role',
            'accountType',
            'adminRole',
            'admin_role',
            'type',
          ],
        ) ??
        _firstString(
          nestedIdentity,
          const ['role', 'userRole', 'user_role', 'type'],
        ) ??
        '';
    final rawCountry = _firstString(
      json,
      const ['countryName', 'country_name', 'countryname', 'country'],
    ) ??
        _firstString(
          nestedIdentity,
          const ['countryName', 'country_name', 'countryname', 'country'],
        );
    final rawState = _firstString(
      json,
      const ['stateName', 'state_name', 'statename', 'state'],
    ) ??
        _firstString(
          nestedIdentity,
          const ['stateName', 'state_name', 'statename', 'state'],
        );
    final rawUsername = _firstString(
          json,
          const ['username', 'userName', 'user_name', 'login'],
        ) ??
        _firstString(
          nestedIdentity,
          const ['username', 'userName', 'user_name', 'login'],
        );
    final rawEmail = _firstString(
          json,
          const ['email', 'mail', 'primaryEmail', 'primary_email'],
        ) ??
        _firstString(
          nestedIdentity,
          const ['email', 'mail', 'primaryEmail', 'primary_email'],
        );
    final rawName = _firstString(
          json,
          const [
            'name',
            'fullName',
            'full_name',
            'displayName',
            'display_name',
            'adminName',
            'admin_name',
            'profileName',
            'profile_name',
          ],
        ) ??
        _firstString(
          nestedIdentity,
          const [
            'name',
            'fullName',
            'full_name',
            'displayName',
            'display_name',
            'adminName',
            'admin_name',
            'profileName',
            'profile_name',
          ],
        ) ??
        _composeName(
          firstName: _firstString(
            json,
            const [
              'firstName',
              'first_name',
              'firstname',
              'givenName',
              'given_name',
            ],
          ),
          lastName: _firstString(
            json,
            const [
              'lastName',
              'last_name',
              'lastname',
              'familyName',
              'family_name',
            ],
          ),
        ) ??
        _composeName(
          firstName: _firstString(
            nestedIdentity,
            const [
              'firstName',
              'first_name',
              'firstname',
              'givenName',
              'given_name',
            ],
          ),
          lastName: _firstString(
            nestedIdentity,
            const [
              'lastName',
              'last_name',
              'lastname',
              'familyName',
              'family_name',
            ],
          ),
        );
    final rawLastLoginValue = _firstValue(
          json,
          const [
            'lastLogin',
            'last_login',
            'lastlogin',
            'lastLoggedIn',
            'last_logged_in',
            'lastLoginAt',
            'lastLoggedInAt',
            'last_logged_in_at',
            'last_login_at',
            'lastSeenAt',
            'last_seen_at',
            'lastSeen',
            'last_seen',
            'lastSeenOn',
            'last_seen_on',
            'loggedInAt',
            'logged_in_at',
            'loginAt',
            'login_at',
            'loginDate',
            'login_date',
            'loginTime',
            'login_time',
          ],
        ) ??
        _firstValue(
          nestedIdentity,
          const [
            'lastLogin',
            'last_login',
            'lastlogin',
            'lastLoggedIn',
            'last_logged_in',
            'lastLoginAt',
            'lastLoggedInAt',
            'last_logged_in_at',
            'last_login_at',
            'lastSeenAt',
            'last_seen_at',
            'lastSeen',
            'last_seen',
            'lastSeenOn',
            'last_seen_on',
            'loggedInAt',
            'logged_in_at',
            'loginAt',
            'login_at',
            'loginDate',
            'login_date',
            'loginTime',
            'login_time',
          ],
        );
    final parsedLastLogin = _parseDateValue(rawLastLoginValue);

    return SuperadminAdministrator(
      id: _firstString(
            json,
            const [
              'id',
              '_id',
              'adminId',
              'adminid',
              'admin_id',
              'userId',
              'user_id',
              'uid',
            ],
          ) ??
          _firstString(
            nestedIdentity,
            const ['id', '_id', 'adminId', 'adminid', 'admin_id', 'uid'],
          ) ??
          '',
      name: rawName ??
          rawUsername ??
          _displayNameFromEmail(rawEmail) ??
          'Unknown administrator',
      username: rawUsername ??
          '—',
      email: rawEmail ??
          '—',
      role: rawRole.trim().isEmpty
          ? (_parseBool(
                    json['isSuperAdmin'] ??
                        json['is_super_admin'] ??
                        json['isAdmin'] ??
                        json['is_admin'],
                  ) ==
                  true
              ? 'superadmin'
              : 'admin')
          : rawRole,
      companyName: _firstString(
            json,
            const [
              'companyName',
              'company_name',
              'companyname',
              'company',
              'organization',
              'organisation',
              'businessName',
              'business_name',
            ],
          ) ??
          _firstString(
            nestedIdentity,
            const [
              'companyName',
              'company_name',
              'companyname',
              'company',
              'organization',
            ],
          ) ??
          '—',
      mobilePrefix: _firstString(
            json,
            const [
              'mobilePrefix',
              'mobile_prefix',
              'mobileprefix',
              'phonePrefix',
              'phone_prefix',
            ],
          ) ??
          _firstString(
            nestedIdentity,
            const [
              'mobilePrefix',
              'mobile_prefix',
              'mobileprefix',
              'phonePrefix',
              'phone_prefix',
            ],
          ) ??
          '',
      mobileNumber: _firstString(
            json,
            const [
              'mobileNumber',
              'mobile_number',
              'mobileNo',
              'mobile_no',
              'phoneNumber',
              'phone_number',
              'phoneNo',
              'phone_no',
              'mobile',
              'phone',
              'contactNumber',
              'contact_number',
            ],
          ) ??
          _firstString(
            nestedIdentity,
            const [
              'mobileNumber',
              'mobile_number',
              'mobileNo',
              'mobile_no',
              'phoneNumber',
              'phone_number',
              'phoneNo',
              'phone_no',
              'mobile',
              'phone',
              'contactNumber',
              'contact_number',
            ],
          ) ??
          '',
      countryCode: _normalizeCountryCode(
            _firstString(
              json,
              const ['countryCode', 'country_code', 'countrycode'],
            ),
          ) ??
          _normalizeCountryCode(
            _firstString(
              nestedIdentity,
              const ['countryCode', 'country_code', 'countrycode'],
            ),
          ) ??
          _normalizeCountryCode(rawCountry) ??
          '',
      countryName: rawCountry != null && rawCountry.trim().length > 2
          ? rawCountry.trim()
          : '',
      stateCode: _firstString(
            json,
            const ['stateCode', 'state_code', 'statecode'],
          ) ??
          _firstString(
            nestedIdentity,
            const ['stateCode', 'state_code', 'statecode'],
          ) ??
          (rawState != null && rawState.trim().length <= 4 ? rawState.trim() : ''),
      stateName: rawState != null && rawState.trim().length > 4
          ? rawState.trim()
          : '',
      cityName: _firstString(
            json,
            const ['cityName', 'city_name', 'cityname', 'city'],
          ) ??
          _firstString(
            nestedIdentity,
            const ['cityName', 'city_name', 'cityname', 'city'],
          ) ??
          '',
      totalVehicles: _firstInt(
            json,
            const [
              'totalVehicles',
              'totalVehicle',
              'totalvehicle',
              'totalDevices',
              'totalDevice',
              'totaldevice',
              'vehicleCount',
              'vehicle_count',
              'deviceCount',
              'device_count',
              'vehiclesCount',
              'devicesCount',
              'vehicles',
              'vehicle',
              'devices',
              'device',
              'assignedVehicles',
              'assigned_vehicles',
              'linkedVehicles',
              'linked_vehicles',
              'adminVehicles',
              'admin_vehicles',
              'allVehicles',
              'allvehicles',
              'allDevices',
              'alldevices',
            ],
          ) ??
          _firstInt(
            nestedCounts,
            const [
              'totalVehicles',
              'totalVehicle',
              'totalDevices',
              'totalDevice',
              'vehicleCount',
              'deviceCount',
              'vehiclesCount',
              'devicesCount',
              'vehicles',
              'vehicle',
              'devices',
              'device',
              'assignedVehicles',
              'linkedVehicles',
              'adminVehicles',
              'allVehicles',
              'allDevices',
            ],
          ) ??
          0,
      totalUsers: _firstInt(
            json,
            const [
              'totalUsers',
              'totalUser',
              'totaluser',
              'userCount',
              'user_count',
              'usersCount',
              'users',
              'allUsers',
              'allusers',
            ],
          ) ??
          _firstInt(
            nestedCounts,
            const [
              'totalUsers',
              'totalUser',
              'userCount',
              'usersCount',
              'users',
              'allUsers',
            ],
          ) ??
          0,
      totalCredits: _firstInt(
            json,
            const [
              'credits',
              'credit',
              'availableCredits',
              'available_credits',
              'assignedCredits',
              'assigned_credits',
              'licensedCredits',
              'licenseCredits',
              'signupCredits',
              'creditBalance',
              'credit_balance',
            ],
          ) ??
          _firstInt(
            nestedCounts,
            const [
              'credits',
              'credit',
              'availableCredits',
              'available_credits',
              'assignedCredits',
              'assigned_credits',
              'licensedCredits',
              'licenseCredits',
              'signupCredits',
              'creditBalance',
              'credit_balance',
            ],
          ) ??
          _firstInt(
            nestedCredits,
            const [
              'credits',
              'credit',
              'availableCredits',
              'available_credits',
              'assignedCredits',
              'assigned_credits',
              'licensedCredits',
              'licenseCredits',
              'signupCredits',
              'creditBalance',
              'credit_balance',
              'balance',
              'available',
              'remaining',
              'count',
              'total',
            ],
          ) ??
          0,
      isActive: _parseBool(
            json['isActive'] ??
                json['is_active'] ??
                json['isactive'] ??
                json['active'] ??
                json['accountStatus'] ??
                json['account_status'] ??
                json['status'],
          ) ??
          _parseBool(
            nestedIdentity['isActive'] ??
                nestedIdentity['is_active'] ??
                nestedIdentity['active'] ??
                nestedIdentity['status'],
          ) ??
          false,
      isVerified: _parseBool(
            json['isVerified'] ??
                json['is_verified'] ??
                json['isverified'] ??
                json['verified'] ??
                json['emailVerified'] ??
                json['email_verified'],
          ) ??
          false,
      lastLoginAt: parsedLastLogin ??
          _firstDate(
            json,
            const [
              'updatedAt',
              'updated_at',
              'createdAt',
              'created_at',
            ],
          ) ??
          _firstDate(
            nestedIdentity,
            const [
              'updatedAt',
              'updated_at',
              'createdAt',
              'created_at',
            ],
          ),
      lastLoginText: parsedLastLogin == null
          ? _stringifyDisplayValue(rawLastLoginValue)
          : null,
      address: _firstString(
            json,
            const [
              'address',
              'addressLine',
              'address_line',
              'fullAddress',
              'full_address',
              'fulladdress',
              'streetAddress',
              'street_address',
            ],
          ) ??
          _firstString(
            nestedIdentity,
            const [
              'address',
              'addressLine',
              'address_line',
              'fullAddress',
              'full_address',
              'fulladdress',
              'streetAddress',
              'street_address',
            ],
          ) ??
          '',
      pincode: _firstString(
            json,
            const [
              'pincode',
              'pinCode',
              'pin_code',
              'postalCode',
              'postal_code',
              'zip',
              'zipCode',
              'zip_code',
            ],
          ) ??
          _firstString(
            nestedIdentity,
            const [
              'pincode',
              'pinCode',
              'pin_code',
              'postalCode',
              'postal_code',
              'zip',
              'zipCode',
              'zip_code',
            ],
          ) ??
          '',
      primaryContact: _firstString(
            json,
            const [
              'primaryContact',
              'primary_contact',
              'primaryContactName',
              'primary_contact_name',
              'primaryName',
              'primary_name',
              'primaryUser',
              'primary_user',
              'parentName',
              'parent_name',
              'parentAdmin',
              'parent_admin',
              'ownerName',
              'owner_name',
              'createdBy',
              'created_by',
            ],
          ) ??
          _firstString(
            nestedIdentity,
            const [
              'primaryContact',
              'primary_contact',
              'primaryContactName',
              'primary_contact_name',
              'primaryName',
              'primary_name',
              'primaryUser',
              'primary_user',
              'parentName',
              'parent_name',
              'parentAdmin',
              'parent_admin',
              'ownerName',
              'owner_name',
              'createdBy',
              'created_by',
            ],
          ) ??
          '',
      createdAt: _firstDate(
            json,
            const [
              'createdAt',
              'created_at',
              'createdOn',
              'created_on',
              'createdDate',
              'created_date',
              'registeredAt',
              'registered_at',
              'registrationDate',
              'registration_date',
            ],
          ) ??
          _firstDate(
            nestedIdentity,
            const [
              'createdAt',
              'created_at',
              'createdOn',
              'created_on',
              'createdDate',
              'created_date',
              'registeredAt',
              'registered_at',
              'registrationDate',
              'registration_date',
            ],
          ),
    );
  }

  SuperadminAdministrator copyWith({
    bool? isActive,
  }) {
    return SuperadminAdministrator(
      id: id,
      name: name,
      username: username,
      email: email,
      role: role,
      companyName: companyName,
      mobilePrefix: mobilePrefix,
      mobileNumber: mobileNumber,
      countryCode: countryCode,
      countryName: countryName,
      stateCode: stateCode,
      stateName: stateName,
      cityName: cityName,
      address: address,
      pincode: pincode,
      primaryContact: primaryContact,
      totalVehicles: totalVehicles,
      totalUsers: totalUsers,
      totalCredits: totalCredits,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified,
      lastLoginAt: lastLoginAt,
      lastLoginText: lastLoginText,
      createdAt: createdAt,
    );
  }

  bool get isSuperAdmin {
    final normalizedRole = role.toLowerCase().replaceAll('_', '');
    return normalizedRole.contains('superadmin');
  }

  String get roleLabel => isSuperAdmin ? 'Super Admin' : 'Admin';

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String get phoneDisplay {
    final prefix = mobilePrefix.trim();
    final number = mobileNumber.trim();
    if (prefix.isEmpty && number.isEmpty) {
      return '—';
    }
    if (prefix.isEmpty) {
      return number;
    }
    if (number.isEmpty) {
      return prefix;
    }
    return '$prefix $number';
  }

  String get fullAddress {
    final parts = <String>[
      if (address.trim().isNotEmpty) address.trim(),
      if (cityName.trim().isNotEmpty) cityName.trim(),
      if (stateName.trim().isNotEmpty)
        stateName.trim()
      else if (stateCode.trim().isNotEmpty)
        stateCode.trim(),
      if (countryName.trim().isNotEmpty)
        countryName.trim()
      else if (countryCode.trim().isNotEmpty)
        countryCode.trim(),
      if (pincode.trim().isNotEmpty) pincode.trim(),
    ];
    return parts.join(', ');
  }

  String get primaryContactDisplay {
    final trimmed = primaryContact.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    if (companyName.trim().isNotEmpty && companyName.trim() != '—') {
      return companyName.trim();
    }
    return '—';
  }

  String get flagEmoji {
    final code = countryCode.trim().toUpperCase();
    if (code.length != 2) {
      return '';
    }

    final first = code.codeUnitAt(0) - 65 + 0x1F1E6;
    final second = code.codeUnitAt(1) - 65 + 0x1F1E6;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    final candidates = <String>[
      name,
      username,
      email,
      roleLabel,
      companyName,
      countryName,
      countryCode,
      stateName,
      stateCode,
      cityName,
    ];

    return candidates.any(
      (value) => value.trim().toLowerCase().contains(normalized),
    );
  }
}

class SuperadminCreateAdministratorRequest {
  const SuperadminCreateAdministratorRequest({
    required this.name,
    required this.username,
    required this.password,
    required this.companyName,
    required this.address,
    required this.country,
    required this.state,
    required this.city,
    this.email,
    this.mobilePrefix,
    this.mobileNumber,
    this.pincode,
    this.credits,
  });

  final String name;
  final String username;
  final String password;
  final String companyName;
  final String address;
  final String country;
  final String state;
  final String city;
  final String? email;
  final String? mobilePrefix;
  final String? mobileNumber;
  final String? pincode;
  final String? credits;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name.trim(),
      'username': username.trim(),
      'password': password,
      'companyName': companyName.trim(),
      'address': address.trim(),
      'country': country.trim(),
      'state': state.trim(),
      'city': city.trim(),
    };

    void addIfNotEmpty(String key, String? value) {
      if (value == null) {
        return;
      }
      final normalized = value.trim();
      if (normalized.isEmpty) {
        return;
      }
      json[key] = normalized;
    }

    addIfNotEmpty('email', email);
    addIfNotEmpty('mobilePrefix', mobilePrefix);
    addIfNotEmpty('mobileNumber', mobileNumber);
    addIfNotEmpty('pincode', pincode);
    addIfNotEmpty('credits', credits);

    return json;
  }
}

class SuperadminCountryOption {
  const SuperadminCountryOption({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  static List<SuperadminCountryOption> listFromJson(dynamic json) {
    return _extractList(json)
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(
          (item) => SuperadminCountryOption(
            code: (_firstString(item, const ['isoCode', 'countryCode', 'code']) ?? '')
                .toUpperCase(),
            name: _firstString(item, const ['name', 'label']) ?? 'Unknown country',
          ),
        )
        .where((item) => item.code.isNotEmpty && item.name.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class SuperadminStateOption {
  const SuperadminStateOption({
    required this.code,
    required this.name,
    required this.countryCode,
  });

  final String code;
  final String name;
  final String countryCode;

  static List<SuperadminStateOption> listFromJson(
    dynamic json, {
    required String countryCode,
  }) {
    return _extractList(json)
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(
          (item) => SuperadminStateOption(
            code: _firstString(item, const ['isoCode', 'stateCode', 'code']) ?? '',
            name: _firstString(item, const ['name', 'label']) ?? 'Unknown state',
            countryCode: (_firstString(
                      item,
                      const ['countryCode', 'country_code'],
                    ) ??
                    countryCode)
                .toUpperCase(),
          ),
        )
        .where((item) => item.code.isNotEmpty && item.name.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class SuperadminCityOption {
  const SuperadminCityOption({
    required this.name,
    required this.countryCode,
    required this.stateCode,
  });

  final String name;
  final String countryCode;
  final String stateCode;

  static List<SuperadminCityOption> listFromJson(dynamic json) {
    return _extractList(json)
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(
          (item) => SuperadminCityOption(
            name: _firstString(item, const ['name', 'label']) ?? 'Unknown city',
            countryCode: (_firstString(
                      item,
                      const ['countryCode', 'country_code'],
                    ) ??
                    '')
                .toUpperCase(),
            stateCode: _firstString(item, const ['stateCode', 'state_code']) ?? '',
          ),
        )
        .where((item) => item.name.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class SuperadminMobilePrefixOption {
  const SuperadminMobilePrefixOption({
    required this.countryCode,
    required this.dialCode,
  });

  final String countryCode;
  final String dialCode;

  static List<SuperadminMobilePrefixOption> listFromJson(dynamic json) {
    return _extractList(json)
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(
          (item) => SuperadminMobilePrefixOption(
            countryCode:
                (_firstString(item, const ['country', 'countryCode']) ?? '')
                    .toUpperCase(),
            dialCode: _normalizeDialCode(
              _firstString(item, const ['code', 'dialCode', 'dial_code']) ?? '',
            ),
          ),
        )
        .where(
          (item) => item.countryCode.isNotEmpty && item.dialCode.isNotEmpty,
        )
        .toList(growable: false);
  }
}

class SuperadminAdministratorLoginOutcome {
  const SuperadminAdministratorLoginOutcome({
    this.accessToken,
    this.refreshToken,
    this.userJson,
    this.message,
    this.redirectUrl,
  });

  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? userJson;
  final String? message;
  final String? redirectUrl;

  bool get hasSession =>
      accessToken != null && accessToken!.trim().isNotEmpty && userJson != null;

  factory SuperadminAdministratorLoginOutcome.fromJson(dynamic json) {
    final map = _asMap(json);
    final nested = _firstMap(map, const ['data', 'result', 'session']) ??
        const <String, dynamic>{};
    final tokens = _firstMap(map, const ['tokens', 'auth']) ??
        _firstMap(nested, const ['tokens', 'auth']) ??
        const <String, dynamic>{};
    final userMap = _firstMap(map, const ['user', 'admin', 'profile']) ??
        _firstMap(nested, const ['user', 'admin', 'profile']);

    return SuperadminAdministratorLoginOutcome(
      accessToken: _firstString(
        map,
        const ['accessToken', 'access_token', 'token', 'jwt'],
      ) ??
          _firstString(
            tokens,
            const ['accessToken', 'access_token', 'token', 'jwt'],
          ),
      refreshToken: _firstString(
        map,
        const ['refreshToken', 'refresh_token'],
      ) ??
          _firstString(
            tokens,
            const ['refreshToken', 'refresh_token'],
          ),
      userJson: userMap == null || userMap.isEmpty ? null : userMap,
      message: _firstString(map, const ['message', 'detail']) ??
          _firstString(nested, const ['message', 'detail']),
      redirectUrl: _firstString(
        map,
        const ['redirectUrl', 'redirect_url', 'redirect', 'url'],
      ) ??
          _firstString(
            nested,
            const ['redirectUrl', 'redirect_url', 'redirect', 'url'],
          ),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  return const <String, dynamic>{};
}

List<dynamic> _extractList(dynamic json) {
  if (json is List) {
    return json;
  }

  final map = _asMap(json);
  for (final key in const [
    'data',
    'items',
    'rows',
    'records',
    'docs',
    'admins',
    'adminsList',
    'adminlist',
    'adminList',
    'list',
    'results',
  ]) {
    final value = map[key];
    if (value is List) {
      return value;
    }
  }

  for (final key in const ['data', 'result', 'payload', 'response']) {
    final nested = map[key];
    if (nested == null || identical(nested, json)) {
      continue;
    }
    final extracted = _extractList(nested);
    if (extracted.isNotEmpty) {
      return extracted;
    }
  }

  if (_looksLikeAdministratorRecord(map)) {
    return <dynamic>[map];
  }

  return const <dynamic>[];
}

bool _looksLikeAdministratorRecord(Map<String, dynamic> json) {
  return json.containsKey('id') ||
      json.containsKey('_id') ||
      json.containsKey('uid') ||
      json.containsKey('adminId') ||
      json.containsKey('adminid') ||
      json.containsKey('username') ||
      json.containsKey('email') ||
      json.containsKey('companyName');
}

dynamic _valueForKey(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) {
    return json[key];
  }

  final normalizedKey = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == normalizedKey) {
      return entry.value;
    }
  }

  return null;
}

Map<String, dynamic>? _firstMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((nestedKey, item) => MapEntry(nestedKey.toString(), item));
    }
  }
  return null;
}

List<dynamic>? _firstList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    if (value is List<dynamic>) {
      return value;
    }
    if (value is Iterable) {
      return value.toList(growable: false);
    }
  }
  return null;
}

dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    if (value != null) {
      return value;
    }
  }
  return null;
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    final normalized = value?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

int? _firstInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    final nestedCount = _countFromContainer(value);
    if (nestedCount != null) {
      return nestedCount;
    }
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      continue;
    }
    final parsed = int.tryParse(normalized);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

int? _countFromContainer(dynamic value) {
  if (value is List || value is Set) {
    return value.length;
  }

  if (value is Iterable) {
    return value.length;
  }

  if (value is Map) {
    final nested = _asMap(value);
    final explicitCount = _firstInt(
      nested,
      const ['count', 'total', 'totalCount', 'records', 'length'],
    );
    if (explicitCount != null) {
      return explicitCount;
    }

    final nestedList = _firstList(
      nested,
      const ['items', 'rows', 'data', 'results', 'docs', 'list'],
    );
    if (nestedList != null) {
      return nestedList.length;
    }
  }

  return null;
}

DateTime? _firstDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    final parsed = _parseDateValue(value);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

String? _displayNameFromEmail(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty || !normalized.contains('@')) {
    return null;
  }

  final localPart = normalized.split('@').first.trim();
  if (localPart.isEmpty) {
    return null;
  }

  return localPart;
}

String? _composeName({
  required String? firstName,
  required String? lastName,
}) {
  final values = [firstName?.trim(), lastName?.trim()]
      .where((value) => value != null && value.isNotEmpty)
      .cast<String>()
      .toList(growable: false);

  if (values.isEmpty) {
    return null;
  }

  return values.join(' ');
}

String? _stringifyDisplayValue(dynamic value) {
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

DateTime? _parseDateValue(dynamic value) {
  if (value is DateTime) {
    return value.toLocal();
  }

  if (value is Map) {
    final map = _asMap(value);
    if (map.isEmpty) {
      return null;
    }

    final directValue = map[r'$date'] ??
        map['date'] ??
        map['value'] ??
        map['timestamp'] ??
        map['datetime'] ??
        map['lastLogin'] ??
        map['lastSeen'];
    final directParsed = _parseDateValue(directValue);
    if (directParsed != null) {
      return directParsed;
    }

    final milliseconds = _parseEpochValue(
      map['milliseconds'] ?? map['millis'] ?? map['ms'],
    );
    if (milliseconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal();
    }

    final seconds = _parseEpochValue(
      map['_seconds'] ?? map['seconds'] ?? map['unix'] ?? map['epoch'],
    );
    if (seconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      ).toLocal();
    }

    final date = map['date']?.toString().trim();
    final time = map['time']?.toString().trim();
    if (date != null && date.isNotEmpty && time != null && time.isNotEmpty) {
      final combined = _parseDateValue('$date $time');
      if (combined != null) {
        return combined;
      }
    }

    return null;
  }

  if (value is num) {
    final intValue = value.toInt();
    if (intValue <= 0) {
      return null;
    }
    final milliseconds = intValue > 9999999999 ? intValue : intValue * 1000;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true)
        .toLocal();
  }

  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  final timezoneNormalized = normalized.replaceFirstMapped(
    RegExp(r'([+-]\d{2})(\d{2})$'),
    (match) => '${match.group(1)}:${match.group(2)}',
  );

  final direct = DateTime.tryParse(timezoneNormalized);
  if (direct != null) {
    return direct.toLocal();
  }

  final digitsOnly = int.tryParse(normalized);
  if (digitsOnly != null) {
    return _parseDateValue(digitsOnly);
  }

  final sanitized = timezoneNormalized
      .replaceAll('•', ' ')
      .replaceAll('·', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  for (final pattern in const [
    'dd MMM yyyy HH:mm',
    'dd MMM yyyy hh:mm a',
    'd MMM yyyy HH:mm',
    'd MMM yyyy hh:mm a',
    'dd MMM yyyy, HH:mm',
    'dd MMM yyyy, hh:mm a',
    'MMM d yyyy HH:mm',
    'MMM d yyyy hh:mm a',
    'MMM d, yyyy HH:mm',
    'MMM d, yyyy hh:mm a',
    'dd-MM-yyyy HH:mm',
    'dd-MM-yyyy hh:mm a',
    'dd/MM/yyyy HH:mm',
    'dd/MM/yyyy hh:mm a',
    'yyyy-MM-dd HH:mm:ss',
    'yyyy-MM-dd HH:mm',
  ]) {
    try {
      return DateFormat(pattern).parseLoose(sanitized).toLocal();
    } catch (_) {
      // Try the next known pattern.
    }
  }

  return null;
}

int? _parseEpochValue(dynamic value) {
  if (value is num) {
    final intValue = value.toInt();
    return intValue > 0 ? intValue : null;
  }

  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  final parsed = int.tryParse(normalized);
  if (parsed == null || parsed <= 0) {
    return null;
  }

  return parsed;
}

bool? _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  final normalized = value?.toString().trim().toLowerCase();
  switch (normalized) {
    case '1':
    case 'true':
    case 'yes':
    case 'active':
    case 'enabled':
    case 'approved':
    case 'verified':
      return true;
    case '0':
    case 'false':
    case 'no':
    case 'inactive':
    case 'disabled':
    case 'pending':
    case 'unverified':
      return false;
    default:
      return null;
  }
}

String _normalizeDialCode(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return '';
  }
  final withoutLeadingPlus = normalized.replaceFirst(RegExp(r'^\++'), '');
  return '+$withoutLeadingPlus';
}

String? _normalizeCountryCode(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.length != 2) {
    return null;
  }
  return normalized;
}