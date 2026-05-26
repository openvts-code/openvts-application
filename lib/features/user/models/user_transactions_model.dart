enum UserTransactionStatus {
  success,
  pending,
  failed,
}

extension UserTransactionStatusX on UserTransactionStatus {
  String get apiValue {
    switch (this) {
      case UserTransactionStatus.success:
        return 'SUCCESS';
      case UserTransactionStatus.pending:
        return 'PENDING';
      case UserTransactionStatus.failed:
        return 'FAILED';
    }
  }

  String get label {
    switch (this) {
      case UserTransactionStatus.success:
        return 'Success';
      case UserTransactionStatus.pending:
        return 'Pending';
      case UserTransactionStatus.failed:
        return 'Failed';
    }
  }
}

enum UserPaymentMode {
  cash,
  upi,
  bankTransfer,
  card,
  razorpay,
  stripe,
  wallet,
  other,
}

extension UserPaymentModeX on UserPaymentMode {
  String get apiValue {
    switch (this) {
      case UserPaymentMode.cash:
        return 'CASH';
      case UserPaymentMode.upi:
        return 'UPI';
      case UserPaymentMode.bankTransfer:
        return 'BANK_TRANSFER';
      case UserPaymentMode.card:
        return 'CARD';
      case UserPaymentMode.razorpay:
        return 'RAZORPAY';
      case UserPaymentMode.stripe:
        return 'STRIPE';
      case UserPaymentMode.wallet:
        return 'WALLET';
      case UserPaymentMode.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case UserPaymentMode.cash:
        return 'Cash';
      case UserPaymentMode.upi:
        return 'UPI';
      case UserPaymentMode.bankTransfer:
        return 'Bank Transfer';
      case UserPaymentMode.card:
        return 'Card';
      case UserPaymentMode.razorpay:
        return 'Razorpay';
      case UserPaymentMode.stripe:
        return 'Stripe';
      case UserPaymentMode.wallet:
        return 'Wallet';
      case UserPaymentMode.other:
        return 'Other';
    }
  }
}

class UserTransactionParty {
  const UserTransactionParty({
    required this.uid,
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.profileUrl,
  });

  final int? uid;
  final int? id;
  final String name;
  final String username;
  final String email;
  final String profileUrl;

  String get displayName {
    final normalizedName = name.trim();
    if (normalizedName.isNotEmpty) {
      return normalizedName;
    }

    final normalizedUsername = username.trim();
    if (normalizedUsername.isNotEmpty) {
      return normalizedUsername;
    }

    return '—';
  }

  factory UserTransactionParty.fromJson(dynamic json) {
    final source = _asMap(json);

    return UserTransactionParty(
      uid: _firstInt(source, const ['uid', 'userUid', 'user_uid']),
      id: _firstInt(source, const ['id', '_id', 'userId', 'user_id']),
      name: _firstString(
            source,
            const ['name', 'Name', 'fullName', 'full_name', 'displayName'],
          ) ??
          '',
      username: _firstString(
            source,
            const ['username', 'userName', 'user_name'],
          ) ??
          '',
      email: _firstString(source, const ['email', 'mail']) ?? '',
      profileUrl: _firstString(
            source,
            const ['profileUrl', 'profile_url', 'avatar', 'avatarUrl'],
          ) ??
          '',
    );
  }
}

class UserTransactionPlan {
  const UserTransactionPlan({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
  });

  final int? id;
  final String name;
  final int? durationDays;
  final String price;

  double? get priceAsDouble {
    final normalized = price.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  factory UserTransactionPlan.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserTransactionPlan(
      id: _firstInt(source, const ['id', '_id', 'planId', 'plan_id']),
      name: _firstString(source, const ['name', 'title', 'label']) ?? '',
      durationDays: _firstInt(
        source,
        const ['durationDays', 'duration_days', 'days'],
      ),
      price: _toAmountString(
        _firstValue(source, const ['price', 'amount', 'value']),
      ),
    );
  }
}

class UserTransactionVehicle {
  const UserTransactionVehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.plan,
  });

  final int? id;
  final String name;
  final String plateNumber;
  final UserTransactionPlan? plan;

  factory UserTransactionVehicle.fromJson(dynamic json) {
    final source = _asMap(json);
    final planMap = _firstMap(
      source,
      const ['plan', 'pricingPlan', 'pricing_plan'],
    );

    return UserTransactionVehicle(
      id: _firstInt(source, const ['id', '_id', 'vehicleId', 'vehicle_id']),
      name: _firstString(source, const ['name', 'vehicleName']) ?? '',
      plateNumber: _firstString(
            source,
            const ['plateNumber', 'plate_number', 'registrationNumber'],
          ) ??
          '',
      plan: planMap == null ? null : UserTransactionPlan.fromJson(planMap),
    );
  }
}

class UserTransaction {
  const UserTransaction({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.recordedById,
    required this.amount,
    required this.currency,
    required this.paymentType,
    required this.paymentMode,
    required this.status,
    required this.reference,
    required this.provider,
    required this.providerRef,
    required this.idempotencyKey,
    required this.failureCode,
    required this.failureMessage,
    required this.meta,
    required this.createdAt,
    required this.createdAtRaw,
    required this.fromUser,
    required this.toUser,
    required this.recordedBy,
    required this.vehicle,
    required this.plan,
  });

  final String id;
  final int? fromUserId;
  final int? toUserId;
  final int? recordedById;
  final String amount;
  final String currency;
  final String paymentType;
  final UserPaymentMode paymentMode;
  final UserTransactionStatus status;
  final String reference;
  final String provider;
  final String providerRef;
  final String idempotencyKey;
  final String failureCode;
  final String failureMessage;
  final Map<String, dynamic> meta;
  final DateTime? createdAt;
  final String createdAtRaw;
  final UserTransactionParty? fromUser;
  final UserTransactionParty? toUser;
  final UserTransactionParty? recordedBy;
  final UserTransactionVehicle? vehicle;
  final UserTransactionPlan? plan;

  double? get amountAsDouble {
    final normalized = amount.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  factory UserTransaction.fromJson(dynamic json) {
    final source = _asMap(json);

    final fromUserPayload = _firstValue(
      source,
      const ['fromUser', 'from_user', 'from', 'payer', 'payerUser'],
    );
    final toUserPayload = _firstValue(
      source,
      const ['toUser', 'to_user', 'to', 'payee', 'payeeUser'],
    );
    final recordedByPayload = _firstValue(
      source,
      const [
        'recordedBy',
        'recorded_by',
        'recordedByUser',
        'recorded_by_user',
        'createdBy',
        'created_by',
      ],
    );

    final fromUserMap = _asMap(fromUserPayload);
    final toUserMap = _asMap(toUserPayload);
    final recordedByMap = _asMap(recordedByPayload);
    final vehicleMap = _firstMap(
      source,
      const ['vehicle', 'vehicleData', 'vehicle_data'],
    );
    final rootPlanMap = _firstMap(
      source,
      const ['plan', 'pricingPlan', 'pricing_plan'],
    );
    final vehiclePlanMap = vehicleMap == null
        ? null
        : _firstMap(
            vehicleMap,
            const ['plan', 'pricingPlan', 'pricing_plan'],
          );

    final createdAtValue = _firstValue(
      source,
      const ['createdAt', 'created_at', 'updatedAt', 'updated_at', 'date'],
    );

    return UserTransaction(
      id: _firstString(
            source,
            const ['id', '_id', 'transactionId', 'transaction_id'],
          ) ??
          '',
      fromUserId: _firstInt(
            source,
            const ['fromUserId', 'from_user_id', 'payerId', 'payer_id'],
          ) ??
          _firstInt(fromUserMap, const ['uid', 'id', 'userId', 'user_id']),
      toUserId: _firstInt(
            source,
            const ['toUserId', 'to_user_id', 'payeeId', 'payee_id'],
          ) ??
          _firstInt(toUserMap, const ['uid', 'id', 'userId', 'user_id']),
      recordedById: _firstInt(
            source,
            const [
              'recordedById',
              'recorded_by_id',
              'createdById',
              'created_by_id',
            ],
          ) ??
          _firstInt(
            recordedByMap,
            const ['uid', 'id', 'userId', 'user_id'],
          ),
      amount: _toAmountString(
        _firstValue(
          source,
          const ['amount', 'totalAmount', 'total_amount', 'value'],
        ),
      ),
      currency: _firstString(source, const ['currency', 'currencyCode']) ?? '',
      paymentType: _firstString(
            source,
            const ['paymentType', 'payment_type', 'type'],
          ) ??
          '',
      paymentMode: _parsePaymentMode(
        _firstValue(source, const ['paymentMode', 'payment_mode', 'mode']),
      ),
      status: _parseTransactionStatus(
        _firstValue(source, const ['status', 'paymentStatus', 'state']),
      ),
      reference: _firstString(source, const ['reference', 'ref']) ?? '',
      provider: _firstString(source, const ['provider', 'gateway']) ?? '',
      providerRef: _firstString(
            source,
            const ['providerRef', 'provider_ref', 'gatewayRef', 'gateway_ref'],
          ) ??
          '',
      idempotencyKey: _firstString(
            source,
            const ['idempotencyKey', 'idempotency_key'],
          ) ??
          '',
      failureCode: _firstString(
            source,
            const ['failureCode', 'failure_code', 'errorCode', 'error_code'],
          ) ??
          '',
      failureMessage: _firstString(
            source,
            const [
              'failureMessage',
              'failure_message',
              'errorMessage',
              'error_message',
            ],
          ) ??
          '',
      meta: _firstMap(source, const ['meta', 'metadata']) ??
          const <String, dynamic>{},
      createdAt: _parseDate(createdAtValue),
      createdAtRaw: _valueAsString(createdAtValue) ?? '',
      fromUser: _partyFromDynamic(fromUserPayload),
      toUser: _partyFromDynamic(toUserPayload),
      recordedBy: _partyFromDynamic(recordedByPayload),
      vehicle: vehicleMap == null
          ? null
          : UserTransactionVehicle.fromJson(vehicleMap),
      plan: rootPlanMap == null && vehiclePlanMap == null
          ? null
          : UserTransactionPlan.fromJson(rootPlanMap ?? vehiclePlanMap),
    );
  }
}

class UserTransactionPage {
  const UserTransactionPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.items,
  });

  final int page;
  final int limit;
  final int total;
  final List<UserTransaction> items;

  bool get hasMore => page * limit < total;

  factory UserTransactionPage.fromJson(
    dynamic json, {
    int defaultPage = 1,
    int defaultLimit = 100,
  }) {
    final payload = _normalizeTransactionsPayload(json);

    if (payload is List) {
      final items =
          payload.map(UserTransaction.fromJson).toList(growable: false);

      final resolvedPage = defaultPage <= 0 ? 1 : defaultPage;
      final resolvedLimit = defaultLimit <= 0 ? 100 : defaultLimit;

      return UserTransactionPage(
        page: resolvedPage,
        limit: resolvedLimit,
        total: items.length,
        items: items,
      );
    }

    final source = _asMap(payload);
    final itemsList = _extractListPayload(
      source,
      preferredKeys: const [
        'items',
        'transactions',
        'rows',
        'list',
        'array',
        'data',
      ],
    );

    final items =
        itemsList.map(UserTransaction.fromJson).toList(growable: false);

    final resolvedPage =
        _firstInt(source, const ['page', 'currentPage', 'current_page']) ??
            defaultPage;
    final resolvedLimit = _firstInt(
          source,
          const ['limit', 'pageSize', 'perPage', 'per_page'],
        ) ??
        defaultLimit;
    final resolvedTotal =
        _firstInt(source, const ['total', 'totalCount', 'count']) ??
            items.length;

    return UserTransactionPage(
      page: resolvedPage <= 0 ? 1 : resolvedPage,
      limit: resolvedLimit <= 0 ? 100 : resolvedLimit,
      total: resolvedTotal < 0 ? items.length : resolvedTotal,
      items: items,
    );
  }
}

UserTransactionStatus _parseTransactionStatus(dynamic value) {
  switch (_normalizeEnumValue(value)) {
    case 'SUCCESS':
      return UserTransactionStatus.success;
    case 'FAILED':
      return UserTransactionStatus.failed;
    case 'PENDING':
    default:
      return UserTransactionStatus.pending;
  }
}

UserPaymentMode _parsePaymentMode(dynamic value) {
  switch (_normalizeEnumValue(value)) {
    case 'CASH':
      return UserPaymentMode.cash;
    case 'UPI':
      return UserPaymentMode.upi;
    case 'BANK_TRANSFER':
      return UserPaymentMode.bankTransfer;
    case 'CARD':
      return UserPaymentMode.card;
    case 'RAZORPAY':
      return UserPaymentMode.razorpay;
    case 'STRIPE':
      return UserPaymentMode.stripe;
    case 'WALLET':
      return UserPaymentMode.wallet;
    case 'OTHER':
    default:
      return UserPaymentMode.other;
  }
}

UserTransactionParty? _partyFromDynamic(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return UserTransactionParty(
      uid: null,
      id: null,
      name: normalized,
      username: '',
      email: '',
      profileUrl: '',
    );
  }

  final map = _asMap(value);
  if (map.isEmpty) {
    return null;
  }

  return UserTransactionParty.fromJson(map);
}

String _normalizeEnumValue(dynamic value) {
  final raw = _valueAsString(value) ?? '';
  if (raw.isEmpty) {
    return '';
  }

  return raw.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
}

String _toAmountString(dynamic value) {
  if (value == null) {
    return '0';
  }

  if (value is String) {
    final normalized = value.replaceAll(',', '').trim();
    return normalized.isEmpty ? '0' : normalized;
  }

  if (value is num) {
    return value.toString();
  }

  final normalized = value.toString().trim();
  return normalized.isEmpty ? '0' : normalized;
}

dynamic _normalizeTransactionsPayload(dynamic json) {
  if (json is List) {
    return json;
  }

  final source = _asMap(json);
  if (source.isEmpty) {
    return const <dynamic>[];
  }

  if (_containsAnyKey(
          source, const ['items', 'transactions', 'rows', 'list', 'array']) ||
      _containsAnyKey(source, const ['page', 'limit', 'total'])) {
    return source;
  }

  for (final key in const ['data', 'result', 'payload', 'response']) {
    final nested = source[key];
    if (nested is List || nested is Map) {
      return _normalizeTransactionsPayload(nested);
    }
  }

  if (source.length == 1) {
    final onlyValue = source.values.first;
    if (onlyValue is List || onlyValue is Map) {
      return _normalizeTransactionsPayload(onlyValue);
    }
  }

  return source;
}

List<dynamic> _extractListPayload(
  dynamic value, {
  List<String> preferredKeys = const <String>[],
}) {
  if (value is List) {
    return value;
  }

  final source = _asMap(value);
  if (source.isEmpty) {
    return const <dynamic>[];
  }

  for (final key in preferredKeys) {
    final candidate = source[key];
    if (candidate is List) {
      return candidate;
    }
  }

  final nestedData = source['data'];
  if (nestedData is List) {
    return nestedData;
  }

  if (nestedData is Map) {
    final nested = _extractListPayload(
      nestedData,
      preferredKeys: preferredKeys,
    );
    if (nested.isNotEmpty) {
      return nested;
    }
  }

  for (final entry in source.entries) {
    final candidate = entry.value;
    if (candidate is List) {
      return candidate;
    }
    if (candidate is Map) {
      final nested = _extractListPayload(
        candidate,
        preferredKeys: preferredKeys,
      );
      if (nested.isNotEmpty) {
        return nested;
      }
    }
  }

  return const <dynamic>[];
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

Map<String, dynamic>? _firstMap(
    Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final map = _asMap(source[key]);
    if (map.isNotEmpty) {
      return map;
    }
  }

  return null;
}

dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (source.containsKey(key)) {
      return source[key];
    }
  }

  return null;
}

String? _firstString(Map<String, dynamic> source, List<String> keys) {
  return _valueAsString(_firstValue(source, keys));
}

String? _valueAsString(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  if (value is num || value is bool) {
    return value.toString();
  }

  return null;
}

int? _firstInt(Map<String, dynamic> source, List<String> keys) {
  return _numFromDynamic(_firstValue(source, keys))?.toInt();
}

num? _numFromDynamic(dynamic value) {
  if (value is num) {
    return value;
  }

  if (value is String) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return num.tryParse(normalized);
  }

  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  if (value is num) {
    final raw = value.toInt();
    if (raw <= 0) {
      return null;
    }

    final millis = raw > 9999999999 ? raw : raw * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(normalized);
  }

  return null;
}

bool _containsAnyKey(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (source.containsKey(key)) {
      return true;
    }
  }

  return false;
}
