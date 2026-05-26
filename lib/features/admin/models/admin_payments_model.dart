import '../models/admin_users_model.dart';

enum AdminPaymentsRangePreset { thisMonth, last30, thisYear, custom }

enum AdminPaymentStatus { success, pending, failed }

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

extension AdminPaymentStatusX on AdminPaymentStatus {
  String get apiValue => switch (this) {
        AdminPaymentStatus.success => 'SUCCESS',
        AdminPaymentStatus.pending => 'PENDING',
        AdminPaymentStatus.failed => 'FAILED',
      };

  String get label => switch (this) {
        AdminPaymentStatus.success => 'Success',
        AdminPaymentStatus.pending => 'Pending',
        AdminPaymentStatus.failed => 'Failed',
      };
}

extension AdminPaymentModeX on AdminPaymentMode {
  String get apiValue => switch (this) {
        AdminPaymentMode.cash => 'CASH',
        AdminPaymentMode.upi => 'UPI',
        AdminPaymentMode.bankTransfer => 'BANK_TRANSFER',
        AdminPaymentMode.card => 'CARD',
        AdminPaymentMode.razorpay => 'RAZORPAY',
        AdminPaymentMode.stripe => 'STRIPE',
        AdminPaymentMode.wallet => 'WALLET',
        AdminPaymentMode.other => 'OTHER',
      };

  String get label => switch (this) {
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

class AdminPaymentsUserRef {
  const AdminPaymentsUserRef({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
  });

  final String id;
  final String name;
  final String username;
  final String email;

  String get displayName {
    final n = name.trim();
    if (n.isNotEmpty) return n;
    final u = username.trim();
    if (u.isNotEmpty) return u;
    return '—';
  }

  factory AdminPaymentsUserRef.fromJson(dynamic json) {
    final map = _asMap(json);
    return AdminPaymentsUserRef(
      id: _firstString(map, const ['uid', 'id', '_id', 'userId']) ?? '',
      name: _firstString(
            map,
            const ['name', 'Name', 'fullName', 'full_name', 'displayName'],
          ) ??
          '',
      username:
          _firstString(map, const ['username', 'userName', 'user_name']) ?? '',
      email: _firstString(map, const ['email', 'mail']) ?? '',
    );
  }
}

class AdminPaymentTransaction {
  const AdminPaymentTransaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.statusRaw,
    required this.paymentModeRaw,
    required this.paymentType,
    required this.reference,
    required this.provider,
    required this.providerRef,
    required this.createdAt,
    required this.createdAtRaw,
    required this.fromUser,
    required this.toUser,
    required this.recordedBy,
    required this.vehicle,
    required this.meta,
    required this.failureCode,
    required this.failureMessage,
    required this.idempotencyKey,
  });

  final String id;
  final String amount;
  final String currency;
  final String statusRaw;
  final String paymentModeRaw;
  final String paymentType;
  final String reference;
  final String provider;
  final String providerRef;
  final DateTime? createdAt;
  final String createdAtRaw;
  final AdminPaymentsUserRef? fromUser;
  final AdminPaymentsUserRef? toUser;
  final AdminPaymentsUserRef? recordedBy;
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> meta;
  final String failureCode;
  final String failureMessage;
  final String idempotencyKey;

  AdminPaymentStatus get status {
    final n = statusRaw.trim().toUpperCase();
    if (n == 'SUCCESS') return AdminPaymentStatus.success;
    if (n == 'FAILED') return AdminPaymentStatus.failed;
    return AdminPaymentStatus.pending;
  }

  AdminPaymentMode get paymentMode {
    final n = paymentModeRaw.trim().toUpperCase();
    return switch (n) {
      'CASH' => AdminPaymentMode.cash,
      'UPI' => AdminPaymentMode.upi,
      'BANK_TRANSFER' => AdminPaymentMode.bankTransfer,
      'CARD' => AdminPaymentMode.card,
      'RAZORPAY' => AdminPaymentMode.razorpay,
      'STRIPE' => AdminPaymentMode.stripe,
      'WALLET' => AdminPaymentMode.wallet,
      _ => AdminPaymentMode.other,
    };
  }

  String get amountDisplay {
    final a = amount.trim().isEmpty ? '0' : amount.trim();
    final c = currency.trim();
    return c.isEmpty ? a : '$c $a';
  }

  factory AdminPaymentTransaction.fromJson(dynamic json) {
    final source = _asMap(json);
    final createdAtValue =
        _firstValue(source, const ['createdAt', 'created_at', 'date']);
    return AdminPaymentTransaction(
      id: _firstString(
              source, const ['id', 'uid', 'transactionId', 'transaction_id']) ??
          '',
      amount: _amountString(_firstValue(source, const [
        'amount',
        'transactionAmount',
        'transaction_amount',
        'value'
      ])),
      currency: _firstString(source, const ['currency', 'currencyCode']) ?? '',
      statusRaw: _firstString(source,
              const ['status', 'transactionStatus', 'transaction_status']) ??
          '',
      paymentModeRaw:
          _firstString(source, const ['paymentMode', 'payment_mode', 'mode']) ??
              '',
      paymentType: _firstString(source, const [
            'paymentType',
            'payment_type',
            'transactionType',
            'transaction_type'
          ]) ??
          '',
      reference: _firstString(source, const [
            'reference',
            'ref',
            'transactionReference',
            'transaction_reference'
          ]) ??
          '',
      provider: _firstString(source, const [
            'provider',
            'gateway',
            'serviceProvider',
            'service_provider'
          ]) ??
          '',
      providerRef: _firstString(source, const [
            'providerRef',
            'provider_ref',
            'gatewayRef',
            'gateway_ref'
          ]) ??
          '',
      createdAt: _toDate(createdAtValue),
      createdAtRaw: createdAtValue?.toString().trim() ?? '',
      fromUser: _firstMap(source, const ['fromUser', 'from_user']) == null
          ? null
          : AdminPaymentsUserRef.fromJson(
              _firstMap(source, const ['fromUser', 'from_user'])),
      toUser: _firstMap(source, const ['toUser', 'to_user']) == null
          ? null
          : AdminPaymentsUserRef.fromJson(
              _firstMap(source, const ['toUser', 'to_user'])),
      recordedBy: _firstMap(source, const ['recordedBy', 'recorded_by']) == null
          ? null
          : AdminPaymentsUserRef.fromJson(
              _firstMap(source, const ['recordedBy', 'recorded_by'])),
      vehicle:
          _firstMap(source, const ['vehicle']) ?? const <String, dynamic>{},
      meta: _firstMap(source, const ['meta', 'metadata']) ??
          const <String, dynamic>{},
      failureCode:
          _firstString(source, const ['failureCode', 'failure_code']) ?? '',
      failureMessage:
          _firstString(source, const ['failureMessage', 'failure_message']) ??
              '',
      idempotencyKey:
          _firstString(source, const ['idempotencyKey', 'idempotency_key']) ??
              '',
    );
  }
}

class AdminPaymentsPage {
  const AdminPaymentsPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.items,
  });

  final int page;
  final int limit;
  final int total;
  final List<AdminPaymentTransaction> items;

  bool get hasMore => page * limit < total;

  factory AdminPaymentsPage.fromJson(dynamic json,
      {int defaultPage = 1, int defaultLimit = 100}) {
    if (json is List) {
      final items =
          json.map(AdminPaymentTransaction.fromJson).toList(growable: false);
      return AdminPaymentsPage(
          page: defaultPage,
          limit: defaultLimit,
          total: items.length,
          items: items);
    }

    final source = _extractMapPayload(json);
    final list = _extractList(source, preferredKeys: const [
      'items',
      'payments',
      'transactions',
      'rows',
      'data'
    ])
        .map(AdminPaymentTransaction.fromJson)
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);

    return AdminPaymentsPage(
      page: _firstInt(source, const ['page', 'currentPage', 'current_page']) ??
          defaultPage,
      limit: _firstInt(source, const ['limit', 'pageSize', 'perPage']) ??
          defaultLimit,
      total: _firstInt(source, const ['total', 'totalCount', 'count']) ??
          list.length,
      items: list,
    );
  }
}

class AdminPaymentsAnalytics {
  const AdminPaymentsAnalytics({
    required this.range,
    required this.totalTransactions,
    required this.totalsByCurrency,
    required this.statusBreakdown,
    required this.modeBreakdown,
    required this.dailySeriesByCurrency,
  });

  const AdminPaymentsAnalytics.empty()
      : range = '',
        totalTransactions = 0,
        totalsByCurrency = const <AdminCurrencyTotal>[],
        statusBreakdown = const <AdminPaymentStatus, int>{},
        modeBreakdown = const <AdminModeBreakdown>[],
        dailySeriesByCurrency = const <AdminDailySeries>[];

  final String range;
  final int totalTransactions;
  final List<AdminCurrencyTotal> totalsByCurrency;
  final Map<AdminPaymentStatus, int> statusBreakdown;
  final List<AdminModeBreakdown> modeBreakdown;
  final List<AdminDailySeries> dailySeriesByCurrency;

  factory AdminPaymentsAnalytics.fromJson(dynamic json) {
    final source = _extractMapPayload(json);
    final totals =
        _extractList(source, preferredKeys: const ['totalsByCurrency'])
            .map(AdminCurrencyTotal.fromJson)
            .toList(growable: false);

    final modeItems =
        _extractList(source, preferredKeys: const ['modeBreakdown'])
            .map(AdminModeBreakdown.fromJson)
            .toList(growable: false);

    final seriesItems =
        _extractList(source, preferredKeys: const ['dailySeriesByCurrency'])
            .map(AdminDailySeries.fromJson)
            .toList(growable: false);

    final statusMap = _firstMap(source, const ['statusBreakdown']) ??
        const <String, dynamic>{};

    return AdminPaymentsAnalytics(
      range: _firstString(source, const ['range', 'preset']) ?? '',
      totalTransactions:
          _firstInt(source, const ['totalTransactions', 'total', 'count']) ?? 0,
      totalsByCurrency: totals,
      statusBreakdown: <AdminPaymentStatus, int>{
        AdminPaymentStatus.success: _toInt(statusMap['SUCCESS']),
        AdminPaymentStatus.pending: _toInt(statusMap['PENDING']),
        AdminPaymentStatus.failed: _toInt(statusMap['FAILED']),
      },
      modeBreakdown: modeItems,
      dailySeriesByCurrency: seriesItems,
    );
  }
}

class AdminCurrencyTotal {
  const AdminCurrencyTotal({
    required this.currency,
    required this.totalAmount,
    required this.countSuccess,
  });

  final String currency;
  final String totalAmount;
  final int countSuccess;

  double get totalAmountValue => double.tryParse(totalAmount) ?? 0;

  factory AdminCurrencyTotal.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminCurrencyTotal(
      currency: _firstString(source, const ['currency', 'code']) ?? 'USD',
      totalAmount: _amountString(
        _firstValue(
            source, const ['totalAmount', 'total_amount', 'amount', 'total']),
      ),
      countSuccess: _firstInt(source,
              const ['countSuccess', 'count_success', 'successCount']) ??
          0,
    );
  }
}

class AdminModeBreakdown {
  const AdminModeBreakdown({required this.mode, required this.count});

  final AdminPaymentMode mode;
  final int count;

  factory AdminModeBreakdown.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminModeBreakdown(
      mode: _parseMode(
          _firstValue(source, const ['mode', 'paymentMode', 'payment_mode'])),
      count: _firstInt(source, const ['count', 'total']) ?? 0,
    );
  }
}

class AdminDailySeries {
  const AdminDailySeries({required this.currency, required this.points});

  final String currency;
  final List<AdminDailyPoint> points;

  factory AdminDailySeries.fromJson(dynamic json) {
    final source = _asMap(json);
    final points = _extractList(source,
            preferredKeys: const ['points', 'series', 'data', 'items'])
        .map(AdminDailyPoint.fromJson)
        .toList(growable: false);

    return AdminDailySeries(
      currency: _firstString(source, const ['currency', 'code']) ?? 'USD',
      points: points,
    );
  }
}

class AdminDailyPoint {
  const AdminDailyPoint(
      {required this.date, required this.totalAmount, this.dateTime});

  final String date;
  final String totalAmount;
  final DateTime? dateTime;

  double get totalAmountValue => double.tryParse(totalAmount) ?? 0;

  factory AdminDailyPoint.fromJson(dynamic json) {
    final source = _asMap(json);
    final dateValue = _firstValue(source, const ['date', 'day', 'label']);
    return AdminDailyPoint(
      date: dateValue?.toString() ?? '',
      totalAmount: _amountString(_firstValue(source,
          const ['totalAmount', 'total_amount', 'amount', 'total', 'value'])),
      dateTime: _toDate(dateValue),
    );
  }
}

class AdminRenewVehicleOption {
  const AdminRenewVehicleOption({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.vin,
    required this.secondaryExpiry,
    required this.planName,
    required this.planPrice,
    required this.planCurrency,
    required this.planDurationDays,
    required this.isRenewable,
  });

  final String id;
  final String name;
  final String plateNumber;
  final String vin;
  final DateTime? secondaryExpiry;
  final String planName;
  final double planPrice;
  final String planCurrency;
  final int? planDurationDays;
  final bool isRenewable;

  factory AdminRenewVehicleOption.fromJson(dynamic json) {
    final source = _asMap(json);
    final plan = _firstMap(source, const ['plan']) ?? const <String, dynamic>{};
    final planId = _firstString(source, const ['planId', 'plan_id']) ??
        _firstString(plan, const ['id']);
    return AdminRenewVehicleOption(
      id: _firstString(
              source, const ['id', '_id', 'uid', 'vehicleId', 'vehicle_id']) ??
          '',
      name:
          _firstString(source, const ['name', 'vehicleName', 'vehicle_name']) ??
              '',
      plateNumber:
          _firstString(source, const ['plateNumber', 'plate_number']) ?? '',
      vin: _firstString(source, const ['vin']) ?? '',
      secondaryExpiry: _toDate(
          _firstValue(source, const ['secondaryExpiry', 'secondary_expiry'])),
      planName: _firstString(plan, const ['name']) ?? '',
      planPrice: double.tryParse(
              _amountString(_firstValue(plan, const ['price', 'amount']))) ??
          0,
      planCurrency: _firstString(plan, const ['currency']) ?? 'USD',
      planDurationDays:
          _firstInt(plan, const ['durationDays', 'duration_days']),
      isRenewable: (planId ?? '').trim().isNotEmpty &&
          _firstString(plan, const ['name']) != null,
    );
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return <String>[name, plateNumber, planName]
        .any((v) => v.toLowerCase().contains(q));
  }
}

class AdminRenewPaymentRequest {
  const AdminRenewPaymentRequest({
    required this.userId,
    required this.vehicleIds,
    required this.paymentMode,
    this.reference,
    this.amountOverride,
  });

  final String userId;
  final List<String> vehicleIds;
  final AdminPaymentMode paymentMode;
  final String? reference;
  final String? amountOverride;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': int.tryParse(userId) ?? userId,
      'vehicleIds': vehicleIds
          .map((id) => int.tryParse(id) ?? id)
          .toList(growable: false),
      'paymentMode': paymentMode.apiValue,
      if ((reference ?? '').trim().isNotEmpty) 'reference': reference!.trim(),
      if ((amountOverride ?? '').trim().isNotEmpty)
        'amountOverride': amountOverride!.trim(),
    };
  }
}

AdminPaymentMode _parseMode(dynamic value) {
  final n = value?.toString().trim().toUpperCase() ?? '';
  return switch (n) {
    'CASH' => AdminPaymentMode.cash,
    'UPI' => AdminPaymentMode.upi,
    'BANK_TRANSFER' => AdminPaymentMode.bankTransfer,
    'CARD' => AdminPaymentMode.card,
    'RAZORPAY' => AdminPaymentMode.razorpay,
    'STRIPE' => AdminPaymentMode.stripe,
    'WALLET' => AdminPaymentMode.wallet,
    _ => AdminPaymentMode.other,
  };
}

Map<String, dynamic> _extractMapPayload(dynamic json) {
  final root = _asMap(json);
  if (root.isEmpty) return const <String, dynamic>{};

  if (root.containsKey('items') ||
      root.containsKey('totalsByCurrency') ||
      root.containsKey('modeBreakdown')) {
    return root;
  }

  final data = root['data'];
  final dataMap = _asMap(data);
  if (dataMap.isNotEmpty) {
    if (dataMap.containsKey('items') ||
        dataMap.containsKey('totalsByCurrency') ||
        dataMap.containsKey('modeBreakdown')) {
      return dataMap;
    }
    final nested = _asMap(dataMap['data']);
    if (nested.isNotEmpty) return nested;
  }

  return root;
}

List<dynamic> _extractList(Map<String, dynamic> source,
    {required List<String> preferredKeys}) {
  for (final key in preferredKeys) {
    final value = source[key];
    if (value is List) return value;
  }
  return const <dynamic>[];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return const <String, dynamic>{};
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

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final s = value.toString().trim();
    if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
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

String _amountString(dynamic value) {
  if (value == null) return '0';
  if (value is num) return value.toString();
  final t = value.toString().replaceAll(',', '').trim();
  return t.isEmpty ? '0' : t;
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<AdminUserListItem> parseAdminUsers(dynamic json) {
  return AdminUserListItem.listFromJson(json);
}
