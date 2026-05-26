class AdminPlan {
  const AdminPlan({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int? durationDays;
  final num? price;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminPlan.fromJson(dynamic json) {
    final m = _asMap(_extractMap(json));
    return AdminPlan(
      id: (_firstValue(m, const ['id', 'uid', 'planId', 'plan_id']) ?? '')
          .toString(),
      name: _firstString(m, const ['name', 'Name']) ?? '-',
      durationDays: _firstInt(m, const ['durationDays', 'duration_days']),
      price: _firstNum(m, const ['price']),
      currency: _firstString(m, const ['currency']) ?? '',
      createdAt:
          _parseDateTime(_firstValue(m, const ['createdAt', 'created_at'])),
      updatedAt:
          _parseDateTime(_firstValue(m, const ['updatedAt', 'updated_at'])),
    );
  }

  static List<AdminPlan> listFromJson(dynamic json) {
    final list = _asList(json);
    return list
        .map(AdminPlan.fromJson)
        .where((e) => e.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      name,
      currency,
      durationDays?.toString() ?? '',
      price?.toString() ?? '',
    ].join(' ').toLowerCase().contains(q);
  }
}

class AdminCurrencyOption {
  const AdminCurrencyOption({required this.code, required this.name});

  final String code;
  final String? name;

  String get label {
    final c = code.trim();
    final n = (name ?? '').trim();
    if (n.isEmpty) return c;
    return '$c - $n';
  }

  factory AdminCurrencyOption.fromJson(dynamic json) {
    final m = _asMap(json);
    return AdminCurrencyOption(
      code: _firstString(m, const ['code']) ?? '',
      name: _firstString(m, const ['name']),
    );
  }

  static List<AdminCurrencyOption> listFromJson(dynamic json) {
    final root = _extractMap(json);
    final direct = _asList(root['data'] ?? root['currencies'] ?? json);
    return direct
        .map(AdminCurrencyOption.fromJson)
        .where((e) => e.code.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class AdminPlanMutationRequest {
  const AdminPlanMutationRequest({
    required this.name,
    required this.durationDays,
    required this.price,
    required this.currency,
  });

  final String name;
  final int durationDays;
  final num price;
  final String currency;

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'durationDays': durationDays,
        'price': price,
        'currency': currency.trim(),
      };
}

Map<String, dynamic> _extractMap(dynamic json) {
  if (json is Map<String, dynamic>) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
  if (json is Map) {
    return json.map((k, v) => MapEntry(k.toString(), v));
  }
  return const <String, dynamic>{};
}

List<dynamic> _asList(dynamic json) {
  if (json is List) return json;
  final m = _extractMap(json);
  for (final key in const ['planslist', 'plans', 'data', 'items']) {
    final v = m[key];
    if (v is List) return v;
    if (v is Map<String, dynamic>) {
      final nested = v['planslist'] ?? v['plans'] ?? v['data'];
      if (nested is List) return nested;
    }
  }
  return const <dynamic>[];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  return const <String, dynamic>{};
}

dynamic _firstValue(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    if (m.containsKey(k)) return m[k];
  }
  return null;
}

String? _firstString(Map<String, dynamic> m, List<String> keys) {
  final v = _firstValue(m, keys);
  if (v == null) return null;
  final t = v.toString().trim();
  return t.isEmpty ? null : t;
}

num? _firstNum(Map<String, dynamic> m, List<String> keys) {
  final v = _firstValue(m, keys);
  if (v is num) return v;
  if (v == null) return null;
  return num.tryParse(v.toString());
}

int? _firstInt(Map<String, dynamic> m, List<String> keys) {
  final v = _firstValue(m, keys);
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v == null) return null;
  return int.tryParse(v.toString());
}

DateTime? _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    final t = value.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t);
  }
  if (value is int && value > 0) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}
