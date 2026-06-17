import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/payroll_snapshot.dart';
import '../../core/utils/salary_calculator.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _EmpRow {
  final Employee employee;
  final PayrollRecord? record;
  final List<SalaryComponent> components;

  const _EmpRow({
    required this.employee,
    this.record,
    required this.components,
  });

  bool get isProcessed => record != null;
  bool get isLocked => record?.isLocked ?? false;

  double get baseSalary => record?.baseSalary ?? employee.baseSalary;
  double get totalAllowances =>
      record?.totalAllowances ??
      SalaryCalculator.totalAllowances(components, employee.baseSalary);
  double get totalDeductions =>
      record?.totalDeductions ??
      SalaryCalculator.totalDeductions(components, employee.baseSalary);
  double get netSalary =>
      record?.netSalary ??
      SalaryCalculator.net(employee.baseSalary, components, components);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class PayrollScreen extends StatefulWidget {
  final String category;
  const PayrollScreen({required this.category, super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final _db = AppDatabase.instance;

  late int _month;
  late int _year;
  List<_EmpRow> _rows = [];
  bool _loading = true;
  bool _processing = false;

  static const _catLabels = {
    'pedo': 'PEDO Employees',
    'security': 'Security Guards',
    'alfajar': 'Al Fajar',
  };

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  final _currency = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'PKR ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final employees = await _db.employeesDao
          .getEmployeesByCategory(widget.category);
      final records = await _db.payrollRecordsDao
          .getRecordsByMonthYear(_month, _year);
      final recordMap = {for (final r in records) r.employeeId: r};

      final rows = <_EmpRow>[];
      for (final emp in employees) {
        final comps = await _db.salaryComponentsDao
            .getComponentsByEmployee(emp.id);
        rows.add(_EmpRow(
          employee: emp,
          record: recordMap[emp.id],
          components: comps,
        ));
      }
      if (mounted) setState(() { _rows = rows; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isLocked =>
      _rows.isNotEmpty && _rows.every((r) => r.isLocked);
  bool get _isProcessed =>
      _rows.isNotEmpty && _rows.every((r) => r.isProcessed);

  void _shiftMonth(int delta) {
    var m = _month + delta;
    var y = _year;
    if (m > 12) { m = 1; y++; }
    if (m < 1)  { m = 12; y--; }
    setState(() { _month = m; _year = y; });
    _loadData();
  }

  Future<void> _processPayroll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Process Payroll'),
        content: Text(
          'Process and lock payroll for ${_monthNames[_month - 1]} $_year?\n\n'
          'Salary records for all ${_rows.length} employees will be saved '
          'and cannot be changed afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Process & Lock'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _processing = true);
    try {
      final now = DateTime.now().toIso8601String();
      for (final row in _rows) {
        if (row.isProcessed) continue;
        final emp = row.employee;
        final comps = row.components;
        final base = emp.baseSalary;

        final activeAllow = comps
            .where((c) => c.isActive && c.componentType == 'allowance')
            .toList();
        final activeDeduct = comps
            .where((c) => c.isActive && c.componentType == 'deduction')
            .toList();

        final totalAllow =
            SalaryCalculator.totalAllowances(comps, base);
        final totalDeduct =
            SalaryCalculator.totalDeductions(comps, base);
        final net = SalaryCalculator.net(base, comps, comps);

        final snapshot = [
          ...activeAllow.map((c) => PayrollComponent(
            name: c.name,
            code: c.classificationCode,
            type: 'allowance',
            amount: SalaryCalculator.calculateComponent(c, base),
          )),
          ...activeDeduct.map((c) => PayrollComponent(
            name: c.name,
            code: c.classificationCode,
            type: 'deduction',
            amount: SalaryCalculator.calculateComponent(c, base),
          )),
        ];

        await _db.payrollRecordsDao.insertRecord(
          PayrollRecordsCompanion(
            employeeId: Value(emp.id),
            month: Value(_month),
            year: Value(_year),
            baseSalary: Value(base),
            totalAllowances: Value(totalAllow),
            totalDeductions: Value(totalDeduct),
            netSalary: Value(net),
            salarySnapshot: Value(PayrollComponent.encodeSnapshot(snapshot)),
            isLocked: const Value(true),
            processedAt: Value(now),
          ),
        );
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Payroll processed for ${_monthNames[_month - 1]} $_year',
          ),
          backgroundColor: Colors.green.shade700,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalNet =
        _rows.fold(0.0, (s, r) => s + r.netSalary);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(cs),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? Center(
                        child: Text(
                          'No employees in this category.',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(child: _buildTable(cs)),
                          _buildFooter(cs, totalNet),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs) {
    final label = _catLabels[widget.category] ?? widget.category;

    Widget statusChip() {
      if (_isLocked) {
        return _Chip(
          icon: Icons.lock,
          label: 'Locked',
          color: Colors.orange.shade700,
        );
      }
      if (_isProcessed) {
        return _Chip(
          icon: Icons.check_circle_outline,
          label: 'Processed',
          color: Colors.green.shade700,
        );
      }
      if (_rows.any((r) => r.isProcessed)) {
        return _Chip(
          icon: Icons.warning_amber_outlined,
          label: 'Partial',
          color: Colors.amber.shade700,
        );
      }
      return _Chip(
        icon: Icons.radio_button_unchecked,
        label: 'Not Processed',
        color: cs.onSurface.withValues(alpha: 0.45),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payroll',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(width: 28),
          // Month navigator
          IconButton(
            onPressed: () => _shiftMonth(-1),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
          ),
          SizedBox(
            width: 160,
            child: Text(
              '${_monthNames[_month - 1]}  $_year',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () => _shiftMonth(1),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
          ),
          const SizedBox(width: 12),
          statusChip(),
          const Spacer(),
          if (!_isLocked && _rows.isNotEmpty)
            FilledButton.icon(
              onPressed: _processing ? null : _processPayroll,
              icon: _processing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_outlined, size: 18),
              label: Text(_isProcessed ? 'Re-Process' : 'Process Payroll'),
            )
          else if (_isLocked)
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_outline, size: 16),
              label: const Text('Locked'),
            ),
        ],
      ),
    );
  }

  // ── Table ─────────────────────────────────────────────────────────────────

  Widget _buildTable(ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 1,
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark
                  ? cs.surfaceContainerHighest
                  : cs.surfaceContainerLowest,
            ),
            columnSpacing: 24,
            headingTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Employee ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Base Salary'), numeric: true),
              DataColumn(label: Text('Allowances'), numeric: true),
              DataColumn(label: Text('Deductions'), numeric: true),
              DataColumn(label: Text('Net Salary'), numeric: true),
              DataColumn(label: Text('Status')),
            ],
            rows: List.generate(_rows.length, (i) {
              final row = _rows[i];
              return DataRow(
                cells: [
                  DataCell(Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  )),
                  DataCell(Text(
                    row.employee.employeeId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  )),
                  DataCell(Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.employee.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        row.employee.designation,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  )),
                  DataCell(Text(_currency.format(row.baseSalary))),
                  DataCell(Text(
                    _currency.format(row.totalAllowances),
                    style: TextStyle(color: Colors.green.shade700),
                  )),
                  DataCell(Text(
                    _currency.format(row.totalDeductions),
                    style: TextStyle(color: Colors.red.shade600),
                  )),
                  DataCell(Text(
                    _currency.format(row.netSalary),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  )),
                  DataCell(_statusCell(row, cs)),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _statusCell(_EmpRow row, ColorScheme cs) {
    if (row.isLocked) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock, size: 14, color: Colors.orange.shade700),
        const SizedBox(width: 4),
        Text(
          'Locked',
          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
        ),
      ]);
    }
    if (row.isProcessed) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_outline, size: 14, color: Colors.green.shade700),
        const SizedBox(width: 4),
        Text(
          'Processed',
          style: TextStyle(fontSize: 12, color: Colors.green.shade700),
        ),
      ]);
    }
    return Text(
      '—',
      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.35)),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(ColorScheme cs, double totalNet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalGross = _rows.fold(
      0.0,
      (s, r) => s + r.baseSalary + r.totalAllowances,
    );
    final totalDeduct = _rows.fold(0.0, (s, r) => s + r.totalDeductions);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest
            : cs.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: cs.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_rows.length} employees  ·  ${_monthNames[_month - 1]} $_year',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          _FooterItem(
            label: 'Total Gross',
            value: _currency.format(totalGross),
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 32),
          _FooterItem(
            label: 'Total Deductions',
            value: _currency.format(totalDeduct),
            color: Colors.red.shade600,
          ),
          const SizedBox(width: 32),
          _FooterItem(
            label: 'Total Net Payroll',
            value: _currency.format(totalNet),
            color: cs.primary,
            large: true,
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

class _FooterItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool large;
  const _FooterItem({
    required this.label,
    required this.value,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 16 : 13,
            fontWeight: large ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
