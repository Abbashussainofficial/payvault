import '../database/database.dart';

/// Pure salary calculation logic. Mirrors the freeze rules in AppDatabase
/// but lives separately so UI code can call it without referencing the DB class.
class SalaryCalculator {
  SalaryCalculator._();

  /// Effective value of one component, respecting its freeze mode.
  static double calculateComponent(
    SalaryComponent c,
    double baseSalary,
  ) {
    switch (c.freezeMode) {
      case 'frozen_on_amount':
        return c.frozenAmount ?? 0.0;

      case 'frozen_on_base':
        final base = c.frozenBase ?? 0.0;
        // Fixed components don't change regardless of base
        return c.valueType == 'percentage' ? base * c.value / 100 : c.value;

      default: // 'not_frozen'
        return c.valueType == 'percentage'
            ? baseSalary * c.value / 100
            : c.value;
    }
  }

  /// Sum of all *active* allowances (gross = base + allowances).
  static double totalAllowances(
    List<SalaryComponent> allowances,
    double baseSalary,
  ) =>
      allowances
          .where((c) => c.isActive && c.componentType == 'allowance')
          .fold(0.0, (sum, c) => sum + calculateComponent(c, baseSalary));

  /// Sum of all *active* deductions.
  static double totalDeductions(
    List<SalaryComponent> deductions,
    double baseSalary,
  ) =>
      deductions
          .where((c) => c.isActive && c.componentType == 'deduction')
          .fold(0.0, (sum, c) => sum + calculateComponent(c, baseSalary));

  /// Gross = base + active allowances.
  static double gross(double baseSalary, List<SalaryComponent> allowances) =>
      baseSalary + totalAllowances(allowances, baseSalary);

  /// Net = gross − active deductions.
  static double net(
    double baseSalary,
    List<SalaryComponent> allowances,
    List<SalaryComponent> deductions,
  ) =>
      gross(baseSalary, allowances) - totalDeductions(deductions, baseSalary);

  /// Preview: compute what amount will be locked for "frozen_on_amount".
  /// Uses raw form values (before saving to DB).
  static double previewAmount({
    required String valueType,
    required double value,
    required double baseSalary,
  }) =>
      valueType == 'percentage' ? baseSalary * value / 100 : value;
}
