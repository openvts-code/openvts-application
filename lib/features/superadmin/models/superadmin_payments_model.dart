enum SuperadminTransactionStatus {
  success,
  pending,
  failed,
}

enum SuperadminPaymentMode {
  cash,
  upi,
  bankTransfer,
  card,
  razorpay,
  stripe,
  wallet,
  other,
}

extension SuperadminTransactionStatusX on SuperadminTransactionStatus {
  String get apiValue {
    switch (this) {
      case SuperadminTransactionStatus.success:
        return 'SUCCESS';
      case SuperadminTransactionStatus.pending:
        return 'PENDING';
      case SuperadminTransactionStatus.failed:
        return 'FAILED';
    }
  }

  String get label {
    switch (this) {
      case SuperadminTransactionStatus.success:
        return 'Success';
      case SuperadminTransactionStatus.pending:
        return 'Pending';
      case SuperadminTransactionStatus.failed:
        return 'Failed';
    }
  }
}

extension SuperadminPaymentModeX on SuperadminPaymentMode {
  String get apiValue {
    switch (this) {
      case SuperadminPaymentMode.cash:
        return 'CASH';
      case SuperadminPaymentMode.upi:
        return 'UPI';
      case SuperadminPaymentMode.bankTransfer:
        return 'BANK_TRANSFER';
      case SuperadminPaymentMode.card:
        return 'CARD';
      case SuperadminPaymentMode.razorpay:
        return 'RAZORPAY';
      case SuperadminPaymentMode.stripe:
        return 'STRIPE';
      case SuperadminPaymentMode.wallet:
        return 'WALLET';
      case SuperadminPaymentMode.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case SuperadminPaymentMode.cash:
        return 'Cash';
      case SuperadminPaymentMode.upi:
        return 'UPI';
      case SuperadminPaymentMode.bankTransfer:
        return 'Bank Transfer';
      case SuperadminPaymentMode.card:
        return 'Card';
      case SuperadminPaymentMode.razorpay:
        return 'Razorpay';
      case SuperadminPaymentMode.stripe:
        return 'Stripe';
      case SuperadminPaymentMode.wallet:
        return 'Wallet';
      case SuperadminPaymentMode.other:
        return 'Other';
    }
  }
}

class SuperadminPaymentAdminOption {
  const SuperadminPaymentAdminOption({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.currency,
  });

  final int uid;
  final String name;
  final String username;
  final String email;
  final String currency;

  String get displayName {
    final normalizedName = name.trim();
    if (normalizedName.isNotEmpty) {
      return normalizedName;
    }

    final normalizedUsername = username.trim();
    if (normalizedUsername.isNotEmpty) {
      return normalizedUsername;
    }

    return uid > 0 ? 'Admin #$uid' : 'Admin';
  }

  factory SuperadminPaymentAdminOption.fromJson(dynamic json) {
    final source = _asMap(json);
    final uid = _firstInt(
          source,
          const ['uid', 'id', '_id', 'adminId', 'admin_id'],
        ) ??
        0;

    return SuperadminPaymentAdminOption(
      uid: uid,
      name: _firstString(
            source,
            const ['Name', 'name', 'fullName', 'full_name', 'displayName'],
          ) ??
          (uid > 0 ? 'Admin #$uid' : 'Admin'),
      username: _firstString(
            source,
            const ['username', 'userName', 'user_name'],
          ) ??
          '',
      email: _firstString(source, const ['email', 'mail']) ?? '',
      currency: _firstString(source, const ['currency', 'currencyCode']) ?? '',
    );
  }

  static List<SuperadminPaymentAdminOption> listFromJson(dynamic json) {
    final list = _extractListPayload(
      json,
      preferredKeys: const ['items', 'rows', 'data', 'admins', 'list'],
    );

    return list
        .map(SuperadminPaymentAdminOption.fromJson)
        .where((item) => item.uid > 0)
        .toList(growable: false);
  }
}

class SuperadminTransactionUser {
  const SuperadminTransactionUser({
    this.uid,
    this.id,
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

  factory SuperadminTransactionUser.fromJson(dynamic json) {
    final source = _asMap(json);
    return SuperadminTransactionUser(
      uid: _firstInt(
        source,
        const ['uid', 'userUid', 'user_uid', 'userId', 'user_id'],
      ),
      id: _firstInt(
        source,
        const ['id', '_id', 'profileId', 'profile_id'],
      ),
      name: _firstString(
            source,
            const ['Name', 'name', 'fullName', 'full_name', 'displayName'],
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

class SuperadminTransaction {
  const SuperadminTransaction({
    required this.id,
    this.fromUserId,
    this.toUserId,
    this.recordedById,
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
    this.createdAt,
    required this.createdAtRaw,
    this.fromUser,
    this.toUser,
    this.recordedBy,
  });

  final String id;
  final int? fromUserId;
  final int? toUserId;
  final int? recordedById;
  final String amount;
  final String currency;
  final String paymentType;
  final SuperadminPaymentMode paymentMode;
  final SuperadminTransactionStatus status;
  final String reference;
  final String provider;
  final String providerRef;
  final String idempotencyKey;
  final String failureCode;
  final String failureMessage;
  final Map<String, dynamic> meta;
  final DateTime? createdAt;
  final String createdAtRaw;
  final SuperadminTransactionUser? fromUser;
  final SuperadminTransactionUser? toUser;
  final SuperadminTransactionUser? recordedBy;

  double? get amountAsDouble {
    final normalized = amount.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  factory SuperadminTransaction.fromJson(dynamic json) {
    final source = _asMap(json);

    final fromUserMap = _firstMap(
      source,
      const ['fromUser', 'from_user', 'from', 'payer', 'payerUser'],
    );
    final toUserMap = _firstMap(
      source,
      const ['toUser', 'to_user', 'to', 'payee', 'payeeUser'],
    );
    final recordedByMap = _firstMap(
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

    final createdAtValue = _firstValue(
      source,
      const ['createdAt', 'created_at', 'updatedAt', 'updated_at', 'date'],
    );

    return SuperadminTransaction(
      id: _firstString(
            source,
            const ['id', '_id', 'transactionId', 'transaction_id'],
          ) ??
          '',
      fromUserId: _firstInt(
            source,
            const ['fromUserId', 'from_user_id', 'payerId', 'payer_id'],
          ) ??
          _firstInt(
            fromUserMap ?? const <String, dynamic>{},
            const ['uid', 'id', 'userId', 'user_id'],
          ),
      toUserId: _firstInt(
            source,
            const ['toUserId', 'to_user_id', 'payeeId', 'payee_id'],
          ) ??
          _firstInt(
            toUserMap ?? const <String, dynamic>{},
            const ['uid', 'id', 'userId', 'user_id'],
          ),
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
            recordedByMap ?? const <String, dynamic>{},
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
        _firstValue(
          source,
          const ['paymentMode', 'payment_mode', 'mode'],
        ),
      ),
      status: _parseTransactionStatus(
        _firstValue(
          source,
          const ['status', 'paymentStatus', 'payment_status', 'state'],
        ),
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
      fromUser:
          fromUserMap == null ? null : SuperadminTransactionUser.fromJson(fromUserMap),
      toUser: toUserMap == null ? null : SuperadminTransactionUser.fromJson(toUserMap),
      recordedBy: recordedByMap == null
          ? null
          : SuperadminTransactionUser.fromJson(recordedByMap),
    );
  }
}

class SuperadminTransactionPage {
  const SuperadminTransactionPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.items,
  });

  final int page;
  final int limit;
  final int total;
  final List<SuperadminTransaction> items;

  bool get hasMore => page * limit < total;

  factory SuperadminTransactionPage.fromJson(
    dynamic json, {
    int defaultPage = 1,
    int defaultLimit = 100,
  }) {
    final payload = _normalizeTransactionsPayload(json);

    if (payload is List) {
      final items = payload
          .map(SuperadminTransaction.fromJson)
          .toList(growable: false);
      final resolvedLimit = defaultLimit <= 0 ? 100 : defaultLimit;
      return SuperadminTransactionPage(
        page: defaultPage <= 0 ? 1 : defaultPage,
        limit: resolvedLimit,
        total: items.length,
        items: items,
      );
    }

    final source = _asMap(payload);
    final itemsList = _extractListPayload(
      source,
      preferredKeys: const ['items', 'transactions', 'rows', 'list', 'data'],
    );

    final items = itemsList
        .map(SuperadminTransaction.fromJson)
        .toList(growable: false);

    final resolvedPage =
        _firstInt(source, const ['page', 'currentPage', 'current_page']) ??
            defaultPage;
    final resolvedLimit =
        _firstInt(source, const ['limit', 'pageSize', 'perPage', 'per_page']) ??
            defaultLimit;
    final resolvedTotal =
        _firstInt(source, const ['total', 'totalCount', 'count']) ??
            items.length;

    return SuperadminTransactionPage(
      page: resolvedPage <= 0 ? 1 : resolvedPage,
      limit: resolvedLimit <= 0 ? 100 : resolvedLimit,
      total: resolvedTotal < 0 ? items.length : resolvedTotal,
      items: items,
    );
  }
}

class SuperadminTransactionsAnalytics {
  const SuperadminTransactionsAnalytics({
    required this.range,
    required this.totalTransactions,
    required this.totalsByCurrency,
    required this.statusBreakdown,
    required this.modeBreakdown,
    required this.dailySeriesByCurrency,
  });

  const SuperadminTransactionsAnalytics.empty()
      : range = '',
        totalTransactions = 0,
        totalsByCurrency = const <SuperadminCurrencyTotal>[],
        statusBreakdown = const <SuperadminTransactionStatus, int>{},
        modeBreakdown = const <SuperadminModeBreakdown>[],
        dailySeriesByCurrency = const <SuperadminDailySeries>[];

  final String range;
  final int totalTransactions;
  final List<SuperadminCurrencyTotal> totalsByCurrency;
  final Map<SuperadminTransactionStatus, int> statusBreakdown;
  final List<SuperadminModeBreakdown> modeBreakdown;
  final List<SuperadminDailySeries> dailySeriesByCurrency;

  factory SuperadminTransactionsAnalytics.fromJson(dynamic json) {
    final source = _normalizeAnalyticsPayload(json);

    return SuperadminTransactionsAnalytics(
      range: _firstString(source, const ['range', 'preset']) ?? '',
      totalTransactions: _firstInt(
            source,
            const ['totalTransactions', 'total', 'count'],
          ) ??
          0,
      totalsByCurrency: _parseTotalsByCurrency(source),
      statusBreakdown: _parseStatusBreakdown(source),
      modeBreakdown: _parseModeBreakdown(source),
      dailySeriesByCurrency: _parseDailySeriesByCurrency(source),
    );
  }
}

class SuperadminCurrencyTotal {
  const SuperadminCurrencyTotal({
    required this.currency,
    required this.totalAmount,
    required this.countSuccess,
  });

  final String currency;
  final String totalAmount;
  final int countSuccess;

  double? get totalAmountAsDouble {
    final normalized = totalAmount.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  factory SuperadminCurrencyTotal.fromJson(dynamic json) {
    final source = _asMap(json);
    return SuperadminCurrencyTotal(
      currency: _firstString(source, const ['currency', 'code']) ?? '',
      totalAmount: _toAmountString(
        _firstValue(
          source,
          const ['totalAmount', 'total_amount', 'amount', 'total'],
        ),
      ),
      countSuccess: _firstInt(
            source,
            const ['countSuccess', 'count_success', 'successCount'],
          ) ??
          0,
    );
  }
}

class SuperadminModeBreakdown {
  const SuperadminModeBreakdown({
    required this.mode,
    required this.count,
  });

  final SuperadminPaymentMode mode;
  final int count;

  factory SuperadminModeBreakdown.fromJson(dynamic json) {
    final source = _asMap(json);
    return SuperadminModeBreakdown(
      mode: _parsePaymentMode(
        _firstValue(source, const ['mode', 'paymentMode', 'payment_mode']),
      ),
      count: _firstInt(source, const ['count', 'total']) ?? 0,
    );
  }
}

class SuperadminDailySeries {
  const SuperadminDailySeries({
    required this.currency,
    required this.points,
  });

  final String currency;
  final List<SuperadminDailyPoint> points;

  factory SuperadminDailySeries.fromJson(dynamic json) {
    final source = _asMap(json);

    final pointsList = _extractListPayload(
      source,
      preferredKeys: const ['points', 'series', 'data', 'items'],
    );

    return SuperadminDailySeries(
      currency: _firstString(source, const ['currency', 'code']) ?? '',
      points:
          pointsList.map(SuperadminDailyPoint.fromJson).toList(growable: false),
    );
  }
}

class SuperadminDailyPoint {
  const SuperadminDailyPoint({
    required this.date,
    required this.totalAmount,
    this.dateTime,
  });

  final String date;
  final String totalAmount;
  final DateTime? dateTime;

  double? get totalAmountAsDouble {
    final normalized = totalAmount.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  factory SuperadminDailyPoint.fromJson(dynamic json) {
    final source = _asMap(json);
    final dateValue = _firstValue(source, const ['date', 'day', 'label']);

    return SuperadminDailyPoint(
      date: _valueAsString(dateValue) ?? '',
      totalAmount: _toAmountString(
        _firstValue(
          source,
          const ['totalAmount', 'total_amount', 'amount', 'total', 'value'],
        ),
      ),
      dateTime: _parseDate(dateValue),
    );
  }
}

class SuperadminRecordPaymentRequest {
  const SuperadminRecordPaymentRequest({
    required this.adminId,
    required this.amount,
    required this.paymentMode,
    this.reference,
  });

  final int adminId;
  final String amount;
  final SuperadminPaymentMode paymentMode;
  final String? reference;

  Map<String, dynamic> toJson() {
    final normalizedReference = reference?.trim();

    return <String, dynamic>{
      'adminId': adminId,
      'amount': amount.trim(),
      'paymentMode': paymentMode.apiValue,
      if (normalizedReference != null && normalizedReference.isNotEmpty)
        'reference': normalizedReference,
    };
  }
}

class SuperadminRecordPaymentResult {
  const SuperadminRecordPaymentResult({
    required this.transaction,
  });

  final SuperadminTransaction transaction;

  factory SuperadminRecordPaymentResult.fromJson(dynamic json) {
    final transaction = SuperadminTransaction.fromJson(
      _extractTransactionPayload(json),
    );

    return SuperadminRecordPaymentResult(
      transaction: transaction,
    );
  }
}

List<SuperadminPaymentAdminOption> parseSuperadminPaymentAdminOptions(
  dynamic json,
) {
  return SuperadminPaymentAdminOption.listFromJson(json);
}

SuperadminTransactionStatus _parseTransactionStatus(dynamic value) {
  final normalized = _normalizeEnumValue(value);
  switch (normalized) {
    case 'SUCCESS':
      return SuperadminTransactionStatus.success;
    case 'FAILED':
      return SuperadminTransactionStatus.failed;
    case 'PENDING':
    default:
      return SuperadminTransactionStatus.pending;
  }
}

SuperadminPaymentMode _parsePaymentMode(dynamic value) {
  final normalized = _normalizeEnumValue(value);
  switch (normalized) {
    case 'CASH':
      return SuperadminPaymentMode.cash;
    case 'UPI':
      return SuperadminPaymentMode.upi;
    case 'BANK_TRANSFER':
      return SuperadminPaymentMode.bankTransfer;
    case 'CARD':
      return SuperadminPaymentMode.card;
    case 'RAZORPAY':
      return SuperadminPaymentMode.razorpay;
    case 'STRIPE':
      return SuperadminPaymentMode.stripe;
    case 'WALLET':
      return SuperadminPaymentMode.wallet;
    case 'OTHER':
    default:
      return SuperadminPaymentMode.other;
  }
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

Map<String, dynamic> _normalizeAnalyticsPayload(dynamic json) {
  final source = _asMap(json);
  if (source.isEmpty) {
    return const <String, dynamic>{};
  }

  if (_containsAnyKey(
    source,
    const [
      'totalsByCurrency',
      'statusBreakdown',
      'modeBreakdown',
      'dailySeriesByCurrency',
      'totalTransactions',
    ],
  )) {
    return source;
  }

  final nestedData = source['data'];
  final nestedMap = _asMap(nestedData);
  if (nestedMap.isNotEmpty) {
    return _normalizeAnalyticsPayload(nestedMap);
  }

  return source;
}

dynamic _normalizeTransactionsPayload(dynamic json) {
  if (json is List) {
    return json;
  }

  final source = _asMap(json);
  if (source.isEmpty) {
    return const <dynamic>[];
  }

  if (_containsAnyKey(source, const ['items', 'transactions', 'rows', 'list']) ||
      _containsAnyKey(source, const ['page', 'limit', 'total'])) {
    return source;
  }

  final nestedData = source['data'];
  if (nestedData is List || nestedData is Map) {
    return _normalizeTransactionsPayload(nestedData);
  }

  return source;
}

List<SuperadminCurrencyTotal> _parseTotalsByCurrency(Map<String, dynamic> source) {
  final list = _extractListPayload(
    source,
    preferredKeys: const ['totalsByCurrency', 'currencyTotals', 'totals'],
  );

  if (list.isNotEmpty) {
    return list
        .map(SuperadminCurrencyTotal.fromJson)
        .toList(growable: false);
  }

  final map = _firstMap(
    source,
    const ['totalsByCurrency', 'currencyTotals', 'totals'],
  );
  if (map == null || map.isEmpty) {
    return const <SuperadminCurrencyTotal>[];
  }

  final items = <SuperadminCurrencyTotal>[];
  for (final entry in map.entries) {
    final valueMap = _asMap(entry.value);
    if (valueMap.isEmpty) {
      final amount = _toAmountString(entry.value);
      items.add(
        SuperadminCurrencyTotal(
          currency: entry.key,
          totalAmount: amount,
          countSuccess: 0,
        ),
      );
      continue;
    }

    items.add(
      SuperadminCurrencyTotal(
        currency: _firstString(valueMap, const ['currency', 'code']) ?? entry.key,
        totalAmount: _toAmountString(
          _firstValue(
            valueMap,
            const ['totalAmount', 'total_amount', 'amount', 'total'],
          ),
        ),
        countSuccess: _firstInt(
              valueMap,
              const ['countSuccess', 'count_success', 'successCount'],
            ) ??
            0,
      ),
    );
  }

  return items;
}

Map<SuperadminTransactionStatus, int> _parseStatusBreakdown(
  Map<String, dynamic> source,
) {
  final list = _extractListPayload(
    source,
    preferredKeys: const ['statusBreakdown', 'statuses', 'statusCounts'],
  );

  final breakdown = <SuperadminTransactionStatus, int>{};

  if (list.isNotEmpty) {
    for (final item in list) {
      final map = _asMap(item);
      if (map.isEmpty) {
        continue;
      }

      final status = _parseTransactionStatus(
        _firstValue(map, const ['status', 'name', 'key', 'label']),
      );
      final count = _firstInt(map, const ['count', 'total', 'value']) ?? 0;
      breakdown[status] = count;
    }

    return breakdown;
  }

  final map = _firstMap(
    source,
    const ['statusBreakdown', 'statuses', 'statusCounts'],
  );
  if (map == null || map.isEmpty) {
    return breakdown;
  }

  for (final entry in map.entries) {
    final status = _parseTransactionStatus(entry.key);
    final count = _numFromDynamic(entry.value)?.toInt() ??
        _firstInt(_asMap(entry.value), const ['count', 'total', 'value']) ??
        0;
    breakdown[status] = count;
  }

  return breakdown;
}

List<SuperadminModeBreakdown> _parseModeBreakdown(Map<String, dynamic> source) {
  final list = _extractListPayload(
    source,
    preferredKeys: const ['modeBreakdown', 'modes', 'paymentModes'],
  );

  if (list.isNotEmpty) {
    return list
        .map(SuperadminModeBreakdown.fromJson)
        .toList(growable: false);
  }

  final map = _firstMap(
    source,
    const ['modeBreakdown', 'modes', 'paymentModes'],
  );
  if (map == null || map.isEmpty) {
    return const <SuperadminModeBreakdown>[];
  }

  return map.entries
      .map(
        (entry) => SuperadminModeBreakdown(
          mode: _parsePaymentMode(entry.key),
          count: _numFromDynamic(entry.value)?.toInt() ??
              _firstInt(
                    _asMap(entry.value),
                    const ['count', 'total', 'value'],
                  ) ??
              0,
        ),
      )
      .toList(growable: false);
}

List<SuperadminDailySeries> _parseDailySeriesByCurrency(
  Map<String, dynamic> source,
) {
  final list = _extractListPayload(
    source,
    preferredKeys: const [
      'dailySeriesByCurrency',
      'dailySeries',
      'seriesByCurrency',
      'series',
    ],
  );

  if (list.isNotEmpty) {
    return list
        .map(SuperadminDailySeries.fromJson)
        .toList(growable: false);
  }

  final map = _firstMap(
    source,
    const [
      'dailySeriesByCurrency',
      'dailySeries',
      'seriesByCurrency',
      'series',
    ],
  );
  if (map == null || map.isEmpty) {
    return const <SuperadminDailySeries>[];
  }

  final output = <SuperadminDailySeries>[];
  for (final entry in map.entries) {
    final points = _extractListPayload(
      entry.value,
      preferredKeys: const ['points', 'series', 'data', 'items'],
    )
        .map(SuperadminDailyPoint.fromJson)
        .toList(growable: false);

    output.add(
      SuperadminDailySeries(
        currency: entry.key,
        points: points,
      ),
    );
  }

  return output;
}

dynamic _extractTransactionPayload(dynamic json) {
  final source = _asMap(json);
  if (source.isEmpty) {
    return json;
  }

  if (_containsAnyKey(
    source,
    const ['id', '_id', 'transactionId', 'paymentMode', 'status'],
  )) {
    return source;
  }

  final firstLevel = _firstMap(
    source,
    const ['transaction', 'item', 'result', 'record', 'data'],
  );
  if (firstLevel != null && firstLevel.isNotEmpty) {
    return _extractTransactionPayload(firstLevel);
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
    return _extractListPayload(nestedData, preferredKeys: preferredKeys);
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

Map<String, dynamic>? _firstMap(Map<String, dynamic> source, List<String> keys) {
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
  final value = _firstValue(source, keys);
  return _valueAsString(value);
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
  final value = _firstValue(source, keys);
  return _numFromDynamic(value)?.toInt();
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
