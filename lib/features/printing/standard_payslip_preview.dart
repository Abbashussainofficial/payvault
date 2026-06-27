import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/payroll_snapshot.dart';
import '../../core/utils/salary_calculator.dart';

/// Live payslip preview for Security Guards and Al Fajar employees.
///
/// When [record] is provided, renders the locked snapshot (official).
/// When [record] is null, streams live salary components from the DB
/// and renders a DRAFT preview that updates on every component change.
class StandardPayslipPreview extends StatelessWidget {
  final Employee employee;
  final int month;
  final int year;
  // 'security' or 'alfajar'
  final String category;
  // null = draft mode (live components); non-null = official (from snapshot)
  final PayrollRecord? record;

  const StandardPayslipPreview({
    super.key,
    required this.employee,
    required this.month,
    required this.year,
    required this.category,
    this.record,
  });

  static const _catLabels = {
    'security': 'SECURITY GUARDS',
    'alfajar': 'AL FAJAR',
  };

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static final _numFmt = NumberFormat('#,##0', 'en_US');
  static String _f(double v) => 'Rs. ${_numFmt.format(v.round())}';

  @override
  Widget build(BuildContext context) {
    if (record != null) {
      final comps = PayrollComponent.parseSnapshot(record!.salarySnapshot);
      final allowances = comps.where((c) => c.type == 'allowance').toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final deductions = comps.where((c) => c.type == 'deduction').toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return _buildSlip(
        allowances: allowances,
        deductions: deductions,
        baseSalary: record!.baseSalary,
        totalAllowances: record!.totalAllowances,
        totalDeductions: record!.totalDeductions,
        netSalary: record!.netSalary,
        isDraft: false,
        processedAt: record!.processedAt,
      );
    }

    // Draft: watch live salary components and rebuild on every change
    return StreamBuilder<List<SalaryComponent>>(
      stream: AppDatabase.instance.salaryComponentsDao
          .watchComponentsByEmployee(employee.id),
      builder: (context, snapshot) {
        final components = snapshot.data ?? [];
        final base = employee.baseSalary;
        final activeAllow = components
            .where((c) => c.isActive && c.componentType == 'allowance')
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final activeDed = components
            .where((c) => c.isActive && c.componentType == 'deduction')
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final totAllow = SalaryCalculator.totalAllowances(activeAllow, base);
        final totDeduct = SalaryCalculator.totalDeductions(activeDed, base);

        final allowPc = activeAllow
            .map((c) => PayrollComponent(
                  name: c.name,
                  type: 'allowance',
                  amount: SalaryCalculator.calculateComponent(c, base),
                  sortOrder: c.sortOrder,
                ))
            .toList();
        final dedPc = activeDed
            .map((c) => PayrollComponent(
                  name: c.name,
                  type: 'deduction',
                  amount: SalaryCalculator.calculateComponent(c, base),
                  sortOrder: c.sortOrder,
                ))
            .toList();

        return _buildSlip(
          allowances: allowPc,
          deductions: dedPc,
          baseSalary: base,
          totalAllowances: totAllow,
          totalDeductions: totDeduct,
          netSalary: base + totAllow - totDeduct,
          isDraft: true,
          processedAt: null,
        );
      },
    );
  }

  Widget _buildSlip({
    required List<PayrollComponent> allowances,
    required List<PayrollComponent> deductions,
    required double baseSalary,
    required double totalAllowances,
    required double totalDeductions,
    required double netSalary,
    required bool isDraft,
    String? processedAt,
  }) {
    final totalEarnings = baseSalary + totalAllowances;
    final catLabel = _catLabels[category] ?? category.toUpperCase();
    final monthName = _months[month - 1];

    return ColoredBox(
      color: const Color(0xFF9E9E9E),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Stack(
              children: [
                // Paper
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(catLabel, monthName),
                      _buildEmployeeInfo(),
                      _buildTable(
                        allowances, deductions,
                        baseSalary, totalEarnings, totalDeductions,
                      ),
                      _buildNetBar(netSalary),
                      _buildFooter(processedAt),
                    ],
                  ),
                ),
                // DRAFT watermark — diagonal, semi-transparent
                if (isDraft)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Transform.rotate(
                          angle: -0.4,
                          child: Text(
                            'DRAFT',
                            style: TextStyle(
                              fontSize: 90,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.withValues(alpha: 0.12),
                              letterSpacing: 10,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(String catLabel, String monthName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: const Color(0xFF1B2235),
      child: Column(
        children: [
          Text(
            catLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'SALARY SLIP',
            style: TextStyle(
              color: Color(0xFF90CAF9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.5,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            '$monthName  $year',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Employee info ────────────────────────────────────────────────────────

  Widget _buildEmployeeInfo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _infoSection([
              _infoEntry('Employee Name', employee.fullName),
              _infoEntry('Employee ID', employee.employeeId),
              _infoEntry('Designation', employee.designation),
            ]),
          ),
          Container(width: 1, color: Colors.grey.shade200),
          Expanded(
            child: _infoSection([
              _infoEntry('Department', employee.department),
              _infoEntry('Contact', employee.contactNumber ?? '—'),
              _infoEntry('Joining Date', _fmtDate(employee.joiningDate)),
            ], leftPad: 16),
          ),
        ],
      ),
    );
  }

  Widget _infoSection(List<Widget> children, {double leftPad = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: leftPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoEntry(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF546E7A),
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF1B2235),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Earnings / Deductions table ───────────────────────────────────────────

  Widget _buildTable(
    List<PayrollComponent> allowances,
    List<PayrollComponent> deductions,
    double baseSalary,
    double totalEarnings,
    double totalDeductions,
  ) {
    // Zip: Basic Salary row uses deductions[0]; then allowances[i] with deductions[i+1]
    final extraRows = allowances.length > (deductions.length - 1).clamp(0, 9999)
        ? allowances.length
        : (deductions.length - 1).clamp(0, 9999);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 0.7),
        ),
        child: Column(
          children: [
            // Column headers
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _colHeader('EARNINGS')),
                  _vDivider(),
                  Expanded(child: _colHeader('DEDUCTIONS')),
                ],
              ),
            ),
            _hDivider(),
            // Basic Salary + deductions[0]
            _tableRow(
              leftLabel: 'Basic Salary',
              leftAmt: _f(baseSalary),
              rightLabel: deductions.isNotEmpty ? deductions[0].name : '',
              rightAmt: deductions.isNotEmpty ? _f(deductions[0].amount) : '',
              leftBold: true,
            ),
            // Allowances zipped with remaining deductions
            ...List.generate(extraRows, (i) {
              final a = i < allowances.length ? allowances[i] : null;
              final d = (i + 1) < deductions.length ? deductions[i + 1] : null;
              return _tableRow(
                leftLabel: a?.name ?? '',
                leftAmt: a != null ? _f(a.amount) : '',
                rightLabel: d?.name ?? '',
                rightAmt: d != null ? _f(d.amount) : '',
              );
            }),
            // Total row
            _hDivider(),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _totalCell('Total Earnings', _f(totalEarnings))),
                  _vDivider(),
                  Expanded(child: _totalCell('Total Deductions', _f(totalDeductions))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colHeader(String label) {
    return Container(
      color: const Color(0xFFECEFF1),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1B2235),
          letterSpacing: 0.5,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _tableRow({
    required String leftLabel,
    required String leftAmt,
    required String rightLabel,
    required String rightAmt,
    bool leftBold = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _dataCell(leftLabel, leftAmt, bold: leftBold)),
          _vDivider(),
          Expanded(child: _dataCell(rightLabel, rightAmt)),
        ],
      ),
    );
  }

  Widget _dataCell(String label, String amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: label.isEmpty
                    ? Colors.transparent
                    : const Color(0xFF37474F),
                decoration: TextDecoration.none,
              ),
            ),
          ),
          if (amount.isNotEmpty)
            Text(
              amount,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF1B2235),
                decoration: TextDecoration.none,
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalCell(String label, String amount) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B2235),
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2235),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hDivider() =>
      Container(height: 0.7, color: Colors.grey.shade300);

  Widget _vDivider() =>
      Container(width: 0.7, color: Colors.grey.shade300);

  // ── Net salary bar ────────────────────────────────────────────────────────

  Widget _buildNetBar(double netSalary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF1B2235),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'NET SALARY PAYABLE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            _f(netSalary),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // ── Signature / footer ────────────────────────────────────────────────────

  Widget _buildFooter(String? processedAt) {
    final dateStr = processedAt != null && processedAt.isNotEmpty
        ? _fmtDate(processedAt)
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dateStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Processed on $dateStr',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sigBlock('Prepared by'),
              _sigBlock('Date'),
              _sigBlock('Authorized Signature'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sigBlock(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '______________________',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade400,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF546E7A),
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  String _fmtDate(String raw) {
    if (raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day.toString().padLeft(2, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.year}';
  }
}
