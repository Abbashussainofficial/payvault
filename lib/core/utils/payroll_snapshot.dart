import 'dart:convert';

class PayrollComponent {
  final String name;
  final String? code;
  final String type; // 'allowance' or 'deduction'
  final double amount;
  // 'regular' or 'other' for pedo allowances; null otherwise
  final String? section;

  const PayrollComponent({
    required this.name,
    this.code,
    required this.type,
    required this.amount,
    this.section,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'type': type,
    'amount': amount,
    if (section != null) 'section': section,
  };

  static PayrollComponent fromJson(Map<String, dynamic> j) => PayrollComponent(
    name: j['name'] as String,
    code: j['code'] as String?,
    type: j['type'] as String,
    amount: (j['amount'] as num).toDouble(),
    section: j['section'] as String?,
  );

  static List<PayrollComponent> parseSnapshot(String jsonStr) {
    if (jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String encodeSnapshot(List<PayrollComponent> components) =>
      jsonEncode(components.map((c) => c.toJson()).toList());
}
