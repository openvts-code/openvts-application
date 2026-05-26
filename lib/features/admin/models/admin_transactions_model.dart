enum AdminTransactionStatus { success, pending, failed }

enum AdminPaymentMode {
  cash,
  upi,
  bankTransfer,
  card,
  razorpay,
  stripe,
  wallet,
  other,
}

enum AdminPaymentType { credit, debit, unknown }

extension AdminTransactionStatusX on AdminTransactionStatus {
  String get apiValue {
    return switch (this) {
      AdminTransactionStatus.success => 'SUCCESS',
      AdminTransactionStatus.pending => 'PENDING',
      AdminTransactionStatus.failed => 'FAILED',
    };
  }

  String get label {
    return switch (this) {
      AdminTransactionStatus.success => 'Success',
      AdminTransactionStatus.pending => 'Pending',
      AdminTransactionStatus.failed => 'Failed',
    };
  }
}

extension AdminPaymentModeX on AdminPaymentMode {
  String get apiValue {
    return switch (this) {
      AdminPaymentMode.cash => 'CASH',
      AdminPaymentMode.upi => 'UPI',
      AdminPaymentMode.bankTransfer => 'BANK_TRANSFER',
      AdminPaymentMode.card => 'CARD',
      AdminPaymentMode.razorpay => 'RAZORPAY',
      AdminPaymentMode.stripe => 'STRIPE',
      AdminPaymentMode.wallet => 'WALLET',
      AdminPaymentMode.other => 'OTHER',
    };
  }

  String get label {
    return switch (this) {
      AdminPaymentMode.cash => 'Cash',
      AdminPaymentMode.upi => 'UPI',
      AdminPaymentMode.bankTransfer => 'Bank Transfer',
      AdminPaymentMode.card => 'Card',
      AdminPaymentMode.razorpay => 'Razorpay',
      AdminPaymentMode.stripe => 'Stripe',
      AdminPaymentMode.wallet => 'Wallet',
      AdminPaymentMode.other => 'Other',
    };
  }
}

extension AdminPaymentTypeX on AdminPaymentType {
  String get label {
    return switch (this) {
      AdminPaymentType.credit => 'Credit',
      AdminPaymentType.debit => 'Debit',
      AdminPaymentType.unknown => 'Unknown',
    };
  }
}

class AdminTransactionUser {
  const AdminTransactionUser({
    this.uid,
    this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.profileUrl,
  });

  final String? uid;
  final String? id;
  final String name;
  final String username;
  final String email;
  final String profileUrl;

  String get displayName {
    final n = name.trim();
    if (n.isNotEmpty) return n;
    final u = username.trim();
    if (u.isNotEmpty) return u;
    return '—';
  }

  factory AdminTransactionUser.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminTransactionUser(
      uid: _firstString(source, const ['uid', 'userUid', 'user_uid']),
      id: _firstString(source, const ['id', '_id', 'userId', 'user_id']),
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

class AdminTransaction {
  const AdminTransaction({
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
  final String? fromUserId;
  final String? toUserId;
  final String? recordedById;
  final String amount;
  final String currency;
  final AdminPaymentType paymentType;
  final AdminPaymentMode paymentMode;
  final AdminTransactionStatus status;
  final String reference;
  final String provider;
  final String providerRef;
  final String idempotencyKey;
  final String failureCode;
  final String failureMessage;
  final Map<String, dynamic> meta;
  final DateTime? createdAt;
  final String createdAtRaw;
  final AdminTransactionUser? fromUser;
  final AdminTransactionUser? toUser;
  final AdminTransactionUser? recordedBy;

  String get amountDisplay {
    final n = amount.trim();
    if (n.isEmpty) {
      return currency.trim().isEmpty ? '0' : '${currency.trim()} 0';
    }
    return currency.trim().isEmpty ? n : '${currency.trim()} $n';
  }

  String get counterpartyName {
    final to = toUser?.displayName ?? '';
    if (to.trim().isNotEmpty && to.trim() != '—') return to;
    return '—';
  }

  String get recordedByName {
    final name = recordedBy?.displayName ?? '';
    return name.trim().isEmpty ? '—' : name;
  }

  String get referenceDisplay => _dash(reference);
  String get providerDisplay => _dash(provider);

  factory AdminTransaction.fromJson(dynamic json) {
    final source = _asMap(json);

    final createdAtValue = _firstValue(
      source,
      const ['createdAt', 'created_at', 'date'],
    );

    final fromUserMap = _firstMap(source, const ['fromUser', 'from_user']);
    final toUserMap = _firstMap(source, const ['toUser', 'to_user']);
    final recordedByMap =
        _firstMap(source, const ['recordedBy', 'recorded_by']);

    return AdminTransaction(
      id: _firstString(
            source,
            const ['id', 'uid', 'transactionId', 'transaction_id'],
          ) ??
          '',
      fromUserId: _firstString(source, const ['fromUserId', 'from_user_id']),
      toUserId: _firstString(source, const ['toUserId', 'to_user_id']),
      recordedById:
          _firstString(source, const ['recordedById', 'recorded_by_id']),
      amount: _toAmount(_firstValue(
          source, const ['amount', 'transactionAmount', 'transaction_amount'])),
      currency: _firstString(source, const ['currency']) ?? '',
      paymentType: _parsePaymentType(
        _firstValue(
          source,
          const [
            'paymentType',
            'payment_type',
            'transactionType',
            'transaction_type'
          ],
        ),
      ),
      paymentMode: _parsePaymentMode(
        _firstValue(source, const ['paymentMode', 'payment_mode', 'mode']),
      ),
      status: _parseStatus(
        _firstValue(source,
            const ['status', 'transactionStatus', 'transaction_status']),
      ),
      reference: _firstString(
            source,
            const [
              'reference',
              'ref',
              'transactionReference',
              'transaction_reference'
            ],
          ) ??
          '',
      provider: _firstString(
            source,
            const [
              'provider',
              'gateway',
              'serviceProvider',
              'service_provider'
            ],
          ) ??
          '',
      providerRef: _firstString(
            source,
            const ['providerRef', 'provider_ref', 'gatewayRef', 'gateway_ref'],
          ) ??
          '',
      idempotencyKey:
          _firstString(source, const ['idempotencyKey', 'idempotency_key']) ??
              '',
      failureCode:
          _firstString(source, const ['failureCode', 'failure_code']) ?? '',
      failureMessage:
          _firstString(source, const ['failureMessage', 'failure_message']) ??
              '',
      meta: _firstMap(source, const ['meta', 'metadata']) ??
          const <String, dynamic>{},
      createdAt: _toDate(createdAtValue),
      createdAtRaw: createdAtValue?.toString().trim() ?? '',
      fromUser: fromUserMap == null
          ? null
          : AdminTransactionUser.fromJson(fromUserMap),
      toUser:
          toUserMap == null ? null : AdminTransactionUser.fromJson(toUserMap),
      recordedBy: recordedByMap == null
          ? null
          : AdminTransactionUser.fromJson(recordedByMap),
    );
  }

  static List<AdminTransaction> listFromJson(dynamic json) {
    final list = _extractListPayload(json);
    return list
        .map(AdminTransaction.fromJson)
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class AdminTransactionPage {
  const AdminTransactionPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<AdminTransaction> items;
  final int page;
  final int limit;
  final int total;

  factory AdminTransactionPage.fromJson(
    dynamic json, {
    int defaultPage = 1,
    int defaultLimit = 100,
  }) {
    final root = _asMap(json);
    final data = _extractPageMap(root);
    final items = AdminTransaction.listFromJson(data);

    final page = _firstInt(data, const ['page']) ??
        _firstInt(root, const ['page']) ??
        defaultPage;
    final limit = _firstInt(data, const ['limit']) ??
        _firstInt(root, const ['limit']) ??
        defaultLimit;
    final total = _firstInt(data, const ['total', 'count']) ??
        _firstInt(root, const ['total', 'count']) ??
        items.length;

    return AdminTransactionPage(
      items: items,
      page: page <= 0 ? defaultPage : page,
      limit: limit <= 0 ? defaultLimit : limit,
      total: total < items.length ? items.length : total,
    );
  }
}

Map<String, dynamic> _extractPageMap(Map<String, dynamic> root) {
  if (root.isEmpty) return const <String, dynamic>{};

  final nestedData = root['data'];
  if (nestedData is Map<String, dynamic>) {
    if (nestedData['data'] is Map<String, dynamic>) {
      return nestedData['data'] as Map<String, dynamic>;
    }
    if (nestedData.containsKey('items') || nestedData.containsKey('page')) {
      return nestedData;
    }
  }

  if (root.containsKey('items') || root.containsKey('page')) {
    return root;
  }

  if (nestedData is List) {
    return <String, dynamic>{'items': nestedData};
  }

  return root;
}

List<dynamic> _extractListPayload(dynamic json) {
  if (json is List) return json;

  final root = _asMap(json);
  if (root.isEmpty) return const <dynamic>[];

  for (final key in const ['items', 'data']) {
    final value = root[key];
    if (value is List) return value;
  }

  final data = root['data'];
  if (data is Map<String, dynamic>) {
    for (final key in const ['items', 'data']) {
      final value = data[key];
      if (value is List) return value;
    }
  }

  return const <dynamic>[];
}

Map<String, dynamic>? _firstMap(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
  }
  return null;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return const <String, dynamic>{};
}

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return null;
}

int? _firstInt(Map<String, dynamic> map, List<String> keys) {
  final text = _firstString(map, keys);
  if (text == null) return null;
  return int.tryParse(text);
}

dynamic _firstValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map.containsKey(key)) return map[key];
  }
  return null;
}

String _toAmount(dynamic value) {
  if (value == null) return '';
  if (value is num) return value.toString();
  return value.toString().trim();
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

AdminTransactionStatus _parseStatus(dynamic value) {
  final n = value?.toString().trim().toUpperCase() ?? '';
  if (n == 'SUCCESS') return AdminTransactionStatus.success;
  if (n == 'PENDING') return AdminTransactionStatus.pending;
  return AdminTransactionStatus.failed;
}

AdminPaymentMode _parsePaymentMode(dynamic value) {
  final n = value?.toString().trim().toUpperCase() ?? '';
  if (n == 'CASH') return AdminPaymentMode.cash;
  if (n == 'UPI') return AdminPaymentMode.upi;
  if (n == 'BANK_TRANSFER') return AdminPaymentMode.bankTransfer;
  if (n == 'CARD') return AdminPaymentMode.card;
  if (n == 'RAZORPAY') return AdminPaymentMode.razorpay;
  if (n == 'STRIPE') return AdminPaymentMode.stripe;
  if (n == 'WALLET') return AdminPaymentMode.wallet;
  return AdminPaymentMode.other;
}

AdminPaymentType _parsePaymentType(dynamic value) {
  final n = value?.toString().trim().toUpperCase() ?? '';
  if (n == 'CREDIT') return AdminPaymentType.credit;
  if (n == 'DEBIT') return AdminPaymentType.debit;
  return AdminPaymentType.unknown;
}

String _dash(String value) {
  final n = value.trim();
  return n.isEmpty ? '—' : n;
}
