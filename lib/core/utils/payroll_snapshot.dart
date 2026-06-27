import 'dart:convert';

class PayrollComponent {
  final String name;
  final String? code;
  final String type; // 'allowance' or 'deduction'
  final double amount;
  // 'regular' or 'other' for pedo allowances; null otherwise
  final String? section;
  // true for Gross Claim row — display-only, never counted in totals
  final bool isAutoCalculated;
  // Position within the section — used to preserve user-defined order
  final int sortOrder;

  const PayrollComponent({
    required this.name,
    this.code,
    required this.type,
    required this.amount,
    this.section,
    this.isAutoCalculated = false,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'type': type,
    'amount': amount,
    if (section != null) 'section': section,
    if (isAutoCalculated) 'isAutoCalculated': true,
    if (sortOrder != 0) 'sortOrder': sortOrder,
  };

  static PayrollComponent fromJson(Map<String, dynamic> j) => PayrollComponent(
    name: j['name'] as String,
    code: j['code'] as String?,
    type: j['type'] as String,
    amount: (j['amount'] as num).toDouble(),
    section: j['section'] as String?,
    isAutoCalculated: j['isAutoCalculated'] as bool? ?? false,
    sortOrder: j['sortOrder'] as int? ?? 0,
  );

  // Legacy flat-array parse — kept for non-PEDO records and backward compat
  static List<PayrollComponent> parseSnapshot(String jsonStr) {
    if (jsonStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      } else if (decoded is Map<String, dynamic>) {
        final list = decoded['components'] as List? ?? [];
        return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Legacy encoder for non-PEDO records (flat array, no codes)
  static String encodeSnapshot(List<PayrollComponent> components) =>
      jsonEncode(components.map((c) => c.toJson()).toList());
}

/// Extended snapshot used by PEDO pay bill — includes basic pay bill codes and
/// preserves component sort order. Backward-compatible with the old flat-array
/// format written by earlier versions of the app.
class PayrollSnapshot {
  final List<PayrollComponent> components;
  final String? basicMonthCode;
  final String? basicPayCode1;
  final String? basicPayCode2;

  const PayrollSnapshot({
    required this.components,
    this.basicMonthCode,
    this.basicPayCode1,
    this.basicPayCode2,
  });

  static PayrollSnapshot parse(String jsonStr) {
    if (jsonStr.isEmpty) return const PayrollSnapshot(components: []);
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        // Old flat-array format
        return PayrollSnapshot(
          components: decoded
              .map((e) => PayrollComponent.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      } else if (decoded is Map<String, dynamic>) {
        final list = decoded['components'] as List? ?? [];
        return PayrollSnapshot(
          components: list
              .map((e) => PayrollComponent.fromJson(e as Map<String, dynamic>))
              .toList(),
          basicMonthCode: decoded['basicMonthCode'] as String?,
          basicPayCode1: decoded['basicPayCode1'] as String?,
          basicPayCode2: decoded['basicPayCode2'] as String?,
        );
      }
      return const PayrollSnapshot(components: []);
    } catch (_) {
      return const PayrollSnapshot(components: []);
    }
  }

  String encode() => jsonEncode({
    'components': components.map((c) => c.toJson()).toList(),
    if (basicMonthCode != null) 'basicMonthCode': basicMonthCode,
    if (basicPayCode1 != null) 'basicPayCode1': basicPayCode1,
    if (basicPayCode2 != null) 'basicPayCode2': basicPayCode2,
  });
}
