import 'package:file_picker/file_picker.dart';

class AdminDriverDetails {
  const AdminDriverDetails({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.mobilePrefix,
    required this.mobile,
    required this.isActive,
    required this.isVerified,
    required this.countryCode,
    required this.createdAt,
    required this.updatedAt,
    required this.address,
    required this.attributes,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String mobilePrefix;
  final String mobile;
  final bool isActive;
  final bool isVerified;
  final String countryCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AdminDriverAddress address;
  final Map<String, dynamic> attributes;

  String get roleLabel => 'Driver';

  factory AdminDriverDetails.fromJson(dynamic raw, {String? fallbackId}) {
    final source = _extractDataMap(_asMap(raw));
    final addressMap =
        _firstMap(source, const ['address']) ?? const <String, dynamic>{};

    final mobilePrefix = _firstString(source, const [
          'mobilePrefix',
          'mobile_prefix',
          'mobileCode',
          'mobile_code',
          'phonePrefix',
          'phone_prefix',
        ]) ??
        '';
    final mobile = _firstString(source, const [
          'mobile',
          'mobileNumber',
          'mobile_number',
          'phone',
          'phoneNumber',
          'phone_number',
        ]) ??
        '';

    return AdminDriverDetails(
      id: _firstString(source, const [
            'id',
            'uid',
            '_id',
            'driverId',
            'driver_id',
          ]) ??
          (fallbackId?.trim().isNotEmpty == true ? fallbackId!.trim() : ''),
      name: _firstString(source, const [
            'firstName',
            'first_name',
            'name',
            'Name',
            'fullName',
            'full_name',
            'displayName',
            'display_name',
          ]) ??
          '-',
      username:
          _firstString(source, const ['username', 'userName', 'user_name']) ??
              '-',
      email: _firstString(source, const ['email', 'Email']) ?? '-',
      phone: _composePhone(
        fallbackPhone: _firstString(source, const [
          'phone',
          'phoneNumber',
          'phone_number',
          'mobileDisplay',
          'mobile_display',
        ]),
        prefix: mobilePrefix,
        number: mobile,
      ),
      mobilePrefix: mobilePrefix,
      mobile: mobile,
      isActive: _parseBool(
            _firstValue(source, const [
              'isActive',
              'is_active',
              'isactive',
              'active',
              'status',
            ]),
          ) ??
          true,
      isVerified: _parseBool(
            _firstValue(source, const [
              'isVerified',
              'is_verified',
              'verified',
              'isEmailVerified',
              'is_email_verified',
            ]),
          ) ??
          false,
      countryCode: _firstString(source, const [
            'countryCode',
            'country_code',
            'country',
          ]) ??
          '-',
      createdAt: _firstDate(source, const [
        'createdAt',
        'created_at',
        'created',
        'joinedAt',
        'joined_at',
      ]),
      updatedAt: _firstDate(source, const [
        'updatedAt',
        'updated_at',
        'updated',
      ]),
      address: AdminDriverAddress.fromJson(addressMap, source),
      attributes: _firstMap(source, const ['attributes', 'meta']) ??
          const <String, dynamic>{},
    );
  }
}

class AdminDriverAddress {
  const AdminDriverAddress({
    required this.id,
    required this.addressLine,
    required this.countryCode,
    required this.stateCode,
    required this.cityId,
    required this.pincode,
    required this.fullAddress,
  });

  final String id;
  final String addressLine;
  final String countryCode;
  final String stateCode;
  final String cityId;
  final String pincode;
  final String fullAddress;

  factory AdminDriverAddress.fromJson(
    Map<String, dynamic> address,
    Map<String, dynamic> root,
  ) {
    final addressLine = _firstString(address, const [
          'addressLine',
          'address_line',
          'address',
        ]) ??
        _firstString(root, const ['address', 'addressLine', 'address_line']) ??
        '-';
    final city = _firstString(address, const ['cityId', 'city_id', 'city']) ??
        _firstString(root, const ['city', 'cityId', 'city_id']) ??
        '-';
    final state =
        _firstString(address, const ['stateCode', 'state_code', 'state']) ??
            _firstString(root, const [
              'StateCode',
              'stateCode',
              'state_code',
              'state',
            ]) ??
            '-';
    final country = _firstString(address, const [
          'countryCode',
          'country_code',
          'country',
        ]) ??
        _firstString(root, const ['countryCode', 'country_code', 'country']) ??
        '-';
    final pin =
        _firstString(address, const ['pincode', 'pinCode', 'pin_code']) ??
            _firstString(root, const ['pincode', 'pinCode', 'pin_code']) ??
            '-';

    return AdminDriverAddress(
      id: _firstString(address, const ['id', '_id']) ?? '-',
      addressLine: addressLine,
      countryCode: country,
      stateCode: state,
      cityId: city,
      pincode: pin,
      fullAddress: _firstString(
              address, const ['fullAddress', 'full_address']) ??
          [addressLine, city, state, country, pin]
              .where((value) => value.trim().isNotEmpty && value.trim() != '-')
              .join(', '),
    );
  }
}

class AdminDriverUpdateRequest {
  const AdminDriverUpdateRequest({
    required this.name,
    required this.mobilePrefix,
    required this.mobile,
    required this.email,
    required this.username,
    required this.countryCode,
    required this.stateCode,
    required this.city,
    required this.address,
    required this.pincode,
    required this.attributes,
  });

  final String name;
  final String mobilePrefix;
  final String mobile;
  final String email;
  final String username;
  final String countryCode;
  final String stateCode;
  final String city;
  final String address;
  final String pincode;
  final Map<String, dynamic> attributes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name.trim(),
      'mobilePrefix': mobilePrefix.trim(),
      'mobile': mobile.trim(),
      'email': email.trim(),
      'username': username.trim(),
      'countryCode': countryCode.trim(),
      'StateCode': stateCode.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'pincode': pincode.trim(),
      'attributes': attributes,
    };
  }
}

class AdminDriverDocument {
  const AdminDriverDocument({
    required this.id,
    required this.title,
    required this.docTypeId,
    required this.docTypeName,
    required this.description,
    required this.tags,
    required this.associateType,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    required this.fileUrl,
    required this.expiryAt,
    required this.isVisible,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String title;
  final String docTypeId;
  final String docTypeName;
  final String description;
  final String tags;
  final String associateType;
  final String fileName;
  final String fileType;
  final String filePath;
  final String fileUrl;
  final DateTime? expiryAt;
  final bool isVisible;
  final DateTime? createdAt;
  final String status;

  factory AdminDriverDocument.fromJson(dynamic raw) {
    final source = _extractDataMap(_asMap(raw));
    return AdminDriverDocument(
      id: _firstString(source, const ['id', '_id', 'docId', 'doc_id']) ?? '',
      title: _firstString(source, const ['title', 'name']) ?? '-',
      docTypeId: _firstString(source, const [
            'docTypeId',
            'docTypeID',
            'documentTypeId',
          ]) ??
          '-',
      docTypeName: _firstString(source, const [
            'docTypeName',
            'docType',
            'documentType',
          ]) ??
          '-',
      description: _firstString(source, const ['description']) ?? '-',
      tags: _parseTags(source['tags']),
      associateType: _firstString(source, const ['associateType']) ?? '-',
      fileName: _firstString(source, const ['fileName', 'filename']) ?? '-',
      fileType:
          _firstString(source, const ['fileType', 'mimetype', 'mimeType']) ??
              '-',
      filePath:
          _firstString(source, const ['filePath', 'filepath', 'path']) ?? '',
      fileUrl: _firstString(source, const ['fileUrl', 'url']) ?? '',
      expiryAt: _firstDate(source, const ['expiryAt', 'expiry_at']),
      isVisible:
          _parseBool(_firstValue(source, const ['isVisible', 'is_visible'])) ??
              true,
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      status: _firstString(source, const ['status']) ?? 'PENDING',
    );
  }

  static List<AdminDriverDocument> listFromJson(dynamic json) {
    final list = _extractList(json, keys: const ['documents', 'docs', 'items']);
    return list
        .map(_asMap)
        .where((e) => e.isNotEmpty)
        .map(AdminDriverDocument.fromJson)
        .where((e) => e.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminDriverDocumentType {
  const AdminDriverDocumentType({
    required this.id,
    required this.name,
    required this.docFor,
  });

  final String id;
  final String name;
  final String docFor;

  factory AdminDriverDocumentType.fromJson(dynamic raw) {
    final source = _extractDataMap(_asMap(raw));
    return AdminDriverDocumentType(
      id: _firstString(source, const ['id', '_id']) ?? '',
      name: _firstString(source, const ['name', 'title']) ?? '-',
      docFor: _firstString(source, const ['docFor', 'doc_for']) ?? 'DRIVER',
    );
  }

  static List<AdminDriverDocumentType> listFromJson(dynamic json) {
    final list = _extractList(
      json,
      keys: const ['documenttypes', 'documentTypes', 'items'],
    );
    return list
        .map(_asMap)
        .where((e) => e.isNotEmpty)
        .map(AdminDriverDocumentType.fromJson)
        .where((e) => e.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminDriverLinkedUser {
  const AdminDriverLinkedUser({
    required this.id,
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.phone,
    required this.isActive,
    required this.assignedAt,
  });

  final String id;
  final String uid;
  final String name;
  final String username;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String phone;
  final bool? isActive;
  final DateTime? assignedAt;

  factory AdminDriverLinkedUser.fromJson(dynamic raw) {
    final source = _extractDataMap(_asMap(raw));
    final prefix = _firstString(source, const [
          'mobilePrefix',
          'mobile_prefix',
          'phonePrefix',
          'phone_prefix',
        ]) ??
        '';
    final mobile = _firstString(source, const [
          'mobileNumber',
          'mobile_number',
          'mobile',
          'phoneNumber',
          'phone_number',
          'phone',
        ]) ??
        '';

    return AdminDriverLinkedUser(
      id: _firstString(source, const [
            'id',
            '_id',
            'userId',
            'user_id',
            'uid',
          ]) ??
          '',
      uid: _firstString(source, const ['uid', 'id', '_id']) ?? '',
      name: _firstString(source, const ['name', 'fullName', 'displayName']) ??
          '-',
      username:
          _firstString(source, const ['username', 'userName', 'user_name']) ??
              '-',
      email: _firstString(source, const ['email']) ?? '-',
      mobilePrefix: prefix,
      mobileNumber: mobile,
      phone: _composePhone(
        fallbackPhone: _firstString(source, const ['phone', 'mobileDisplay']),
        prefix: prefix,
        number: mobile,
      ),
      isActive: _parseBool(
        _firstValue(source, const [
          'isActive',
          'is_active',
          'status',
          'active',
        ]),
      ),
      assignedAt: _firstDate(source, const [
        'assignedAt',
        'assigned_at',
        'createdAt',
        'created_at',
      ]),
    );
  }

  static List<AdminDriverLinkedUser> listFromJson(dynamic json) {
    final list = _extractList(
      json,
      keys: const ['users', 'linkedUsers', 'items'],
    );
    return list
        .map(_asMap)
        .where((e) => e.isNotEmpty)
        .map(AdminDriverLinkedUser.fromJson)
        .where((e) => e.id.isNotEmpty || e.uid.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminDriverDocumentUpsertRequest {
  const AdminDriverDocumentUpsertRequest({
    required this.driverId,
    required this.title,
    required this.docTypeId,
    required this.isVisible,
    required this.tags,
    required this.description,
    this.expiryAt,
    this.file,
  });

  final String driverId;
  final String title;
  final String docTypeId;
  final bool isVisible;
  final String tags;
  final String description;
  final DateTime? expiryAt;
  final PlatformFile? file;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

Map<String, dynamic> _extractDataMap(Map<String, dynamic> root) {
  final data = root['data'];
  if (data is Map<String, dynamic>) {
    final nested = data['data'];
    if (nested is Map<String, dynamic>) return nested;
    return data;
  }
  return root;
}

List<dynamic> _extractList(dynamic source, {required List<String> keys}) {
  if (source is List) return source;
  final map = _asMap(source);
  for (final key in keys) {
    final value = map[key];
    if (value is List) return value;
  }
  final data = map['data'];
  if (data is List) return data;
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      final value = data[key];
      if (value is List) return value;
    }
    final nested = data['data'];
    if (nested is List) return nested;
  }
  return const <dynamic>[];
}

Map<String, dynamic>? _firstMap(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return _asMap(value);
  }
  return null;
}

String? _firstString(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return null;
}

dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (source.containsKey(key)) return source[key];
  }
  return null;
}

bool? _parseBool(dynamic raw) {
  if (raw is bool) {
    return raw;
  }
  if (raw is num) {
    if (raw == 1) {
      return true;
    }
    if (raw == 0) {
      return false;
    }
  }
  if (raw is String) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) {
      return null;
    }
    if (v == 'true' || v == 'active' || v == 'enabled' || v == '1') {
      return true;
    }
    if (v == 'false' || v == 'inactive' || v == 'disabled' || v == '0') {
      return false;
    }
  }
  return null;
}

DateTime? _firstDate(Map<String, dynamic> source, List<String> keys) {
  final raw = _firstString(source, keys);
  if (raw == null) {
    return null;
  }
  return DateTime.tryParse(raw);
}

String _composePhone({
  required String? fallbackPhone,
  required String prefix,
  required String number,
}) {
  final fb = fallbackPhone?.trim() ?? '';
  if (fb.isNotEmpty) {
    return fb;
  }
  final n = number.trim();
  if (n.isEmpty) return '-';
  final p = prefix.trim();
  if (p.isEmpty) return n;
  return '$p $n';
}

String _parseTags(dynamic raw) {
  if (raw is List) {
    final parts =
        raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty);
    return parts.join(', ');
  }
  if (raw is String && raw.trim().isNotEmpty) return raw.trim();
  return '-';
}
