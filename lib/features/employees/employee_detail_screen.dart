import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/salary_calculator.dart';
import '../salary/salary_structure_screen.dart';
import 'employee_form_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;
  final String category;

  const EmployeeDetailScreen({
    required this.employee,
    required this.category,
    super.key,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late Employee _employee;
  late final TabController _tabController;

  List<SalaryComponent> _components = [];
  List<PayrollRecord> _payrollHistory = [];
  bool _loadingComponents = true;
  bool _loadingPayroll = true;

  static const _categoryLabels = {
    'pedo': 'PEDO Employees',
    'security': 'Security Guards',
    'alfajar': 'Al Fajar',
  };

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = AppDatabase.instance;
    final components = await db.salaryComponentsDao
        .getComponentsByEmployee(_employee.id);
    final payroll = await db.payrollRecordsDao
        .getRecordsByEmployee(_employee.id);

    if (!mounted) return;
    setState(() {
      _components = components;
      _payrollHistory = payroll
        ..sort((a, b) {
          final cmp = b.year.compareTo(a.year);
          return cmp != 0 ? cmp : b.month.compareTo(a.month);
        });
      _loadingComponents = false;
      _loadingPayroll = false;
    });
  }

  Future<void> _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => EmployeeFormScreen(
              category: widget.category,
              employee: _employee,
            ),
      ),
    );
    if (!mounted) return;
    final updated = await AppDatabase.instance.employeesDao
        .getEmployeeById(_employee.id);
    if (updated != null && mounted) {
      setState(() => _employee = updated);
    }
  }

  Future<void> _printPayslip() async {
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => _MonthPickerDialog(
            initialMonth: selectedMonth,
            initialYear: selectedYear,
            onChanged: (m, y) {
              selectedMonth = m;
              selectedYear = y;
            },
          ),
    );

    if (confirmed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Print payslip for ${DateFormat('MMMM yyyy').format(DateTime(selectedYear, selectedMonth))} — coming soon',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = _employee.status == 'active';

    return Scaffold(
      appBar: AppBar(
        title: Text(_employee.fullName),
        actions: [
          TextButton.icon(
            onPressed: _printPayslip,
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('Print Payslip'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // ── Profile header ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            color: cs.primaryContainer.withValues(alpha: 0.35),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: cs.primary.withValues(alpha: 0.15),
                  child: Text(
                    _employee.fullName.isNotEmpty
                        ? _employee.fullName[0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _employee.fullName,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _StatusChip(isActive: isActive, cs: cs),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _employee.designation,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _IdBadge(id: _employee.employeeId, cs: cs),
                          const SizedBox(width: 8),
                          _IdBadge(
                            id: _categoryLabels[widget.category] ??
                                widget.category,
                            cs: cs,
                            secondary: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Base Salary',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'en_PK',
                        symbol: 'PKR ',
                        decimalDigits: 0,
                      ).format(_employee.baseSalary),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Info cards ────────────────────────────────────────────────────
          _InfoCardsRow(employee: _employee, cs: cs),

          // ── Tabs ─────────────────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Salary Structure'),
              Tab(text: 'Payroll History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SalaryStructureTab(
                  components: _components,
                  loading: _loadingComponents,
                  employee: _employee,
                  cs: cs,
                  onManageStructure: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalaryStructureScreen(employee: _employee),
                      ),
                    );
                    _loadData();
                  },
                ),
                _PayrollHistoryTab(
                  records: _payrollHistory,
                  loading: _loadingPayroll,
                  cs: cs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info cards row ────────────────────────────────────────────────────────────

class _InfoCardsRow extends StatelessWidget {
  final Employee employee;
  final ColorScheme cs;

  const _InfoCardsRow({required this.employee, required this.cs});

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _InfoCard(
              icon: Icons.badge_outlined,
              label: 'Department',
              value: employee.department.isEmpty ? '—' : employee.department,
              cs: cs,
            ),
            _InfoCard(
              icon: Icons.phone_outlined,
              label: 'Contact',
              value: employee.contactNumber ?? '—',
              cs: cs,
            ),
            _InfoCard(
              icon: Icons.credit_card_outlined,
              label: 'CNIC',
              value: employee.cnic ?? '—',
              cs: cs,
            ),
            _InfoCard(
              icon: Icons.calendar_today_outlined,
              label: 'Joined',
              value: _fmt(employee.joiningDate),
              cs: cs,
            ),
            if (employee.leavingDate != null)
              _InfoCard(
                icon: Icons.event_busy_outlined,
                label: 'Left On',
                value: _fmt(employee.leavingDate),
                cs: cs,
              ),
            if (employee.bpsGrade != null)
              _InfoCard(
                icon: Icons.grade_outlined,
                label: 'BPS Grade',
                value: employee.bpsGrade!,
                cs: cs,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Salary Structure tab ──────────────────────────────────────────────────────

class _SalaryStructureTab extends StatelessWidget {
  final List<SalaryComponent> components;
  final bool loading;
  final Employee employee;
  final ColorScheme cs;
  final VoidCallback onManageStructure;

  const _SalaryStructureTab({
    required this.components,
    required this.loading,
    required this.employee,
    required this.cs,
    required this.onManageStructure,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (components.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 56,
              color: cs.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'No salary components configured',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onManageStructure,
              icon: const Icon(Icons.tune_outlined, size: 18),
              label: const Text('Manage Salary Structure'),
            ),
          ],
        ),
      );
    }

    final allowances =
        components
            .where((c) => c.componentType == 'allowance' && c.isActive)
            .toList();
    final deductions =
        components
            .where((c) => c.componentType == 'deduction' && c.isActive)
            .toList();

    final totalAllowances = SalaryCalculator.totalAllowances(
      allowances,
      employee.baseSalary,
    );
    final totalDeductions = SalaryCalculator.totalDeductions(
      deductions,
      employee.baseSalary,
    );
    final net = employee.baseSalary + totalAllowances - totalDeductions;
    final fmt = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'PKR ',
      decimalDigits: 0,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _SummaryChip(label: 'Base', amount: employee.baseSalary, color: cs.primary, cs: cs),
                _SummaryChip(label: 'Allowances', amount: totalAllowances, color: const Color(0xFF2E7D32), cs: cs),
                _SummaryChip(label: 'Deductions', amount: totalDeductions, color: cs.error, cs: cs),
                _SummaryChip(label: 'Net Salary', amount: net, color: cs.primary, cs: cs, bold: true),
              ],
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onManageStructure,
              icon: const Icon(Icons.tune_outlined, size: 16),
              label: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (allowances.isNotEmpty) ...[
          _ComponentSection(
            title: 'Allowances',
            color: const Color(0xFF2E7D32),
            components: allowances,
            baseSalary: employee.baseSalary,
            cs: cs,
            fmt: fmt,
          ),
          const SizedBox(height: 16),
        ],
        if (deductions.isNotEmpty)
          _ComponentSection(
            title: 'Deductions',
            color: cs.error,
            components: deductions,
            baseSalary: employee.baseSalary,
            cs: cs,
            fmt: fmt,
          ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final ColorScheme cs;
  final bool bold;

  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.cs,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bold ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: bold ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          Text(
            NumberFormat.compact().format(amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<SalaryComponent> components;
  final double baseSalary;
  final ColorScheme cs;
  final NumberFormat fmt;

  const _ComponentSection({
    required this.title,
    required this.color,
    required this.components,
    required this.baseSalary,
    required this.cs,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...components.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(c.name, style: Theme.of(context).textTheme.bodySmall),
                ),
                if (c.valueType == 'percentage')
                  Text(
                    '${c.value.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                const SizedBox(width: 12),
                Text(
                  fmt.format(db.calculateSalaryComponent(c, baseSalary)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Payroll History tab ───────────────────────────────────────────────────────

class _PayrollHistoryTab extends StatelessWidget {
  final List<PayrollRecord> records;
  final bool loading;
  final ColorScheme cs;

  const _PayrollHistoryTab({
    required this.records,
    required this.loading,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: cs.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'No payroll records',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      );
    }

    final fmt = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'PKR ',
      decimalDigits: 0,
    );

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = records[i];
        final monthLabel = DateFormat('MMMM yyyy').format(
          DateTime(r.year, r.month),
        );
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_outlined,
                  size: 20,
                  color: cs.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    monthLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (r.isLocked)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Locked',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fmt.format(r.netSalary),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    Text(
                      '+${fmt.format(r.totalAllowances)}  −${fmt.format(r.totalDeductions)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Month picker dialog ───────────────────────────────────────────────────────

class _MonthPickerDialog extends StatefulWidget {
  final int initialMonth;
  final int initialYear;
  final void Function(int month, int year) onChanged;

  const _MonthPickerDialog({
    required this.initialMonth,
    required this.initialYear,
    required this.onChanged,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _month;
  late int _year;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth;
    _year = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Month'),
      content: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _month,
              decoration: const InputDecoration(labelText: 'Month'),
              items: List.generate(
                12,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(_months[i]),
                ),
              ),
              onChanged: (v) {
                _month = v ?? _month;
                widget.onChanged(_month, _year);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _year,
              decoration: const InputDecoration(labelText: 'Year'),
              items: List.generate(10, (i) {
                final y = DateTime.now().year - 5 + i;
                return DropdownMenuItem(value: y, child: Text('$y'));
              }),
              onChanged: (v) {
                _year = v ?? _year;
                widget.onChanged(_month, _year);
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Print'),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isActive;
  final ColorScheme cs;

  const _StatusChip({required this.isActive, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            isActive
                ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                : cs.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Left',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color:
              isActive ? const Color(0xFF2E7D32) : cs.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IdBadge extends StatelessWidget {
  final String id;
  final ColorScheme cs;
  final bool secondary;

  const _IdBadge({required this.id, required this.cs, this.secondary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            secondary
                ? cs.secondaryContainer.withValues(alpha: 0.6)
                : cs.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        id,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color:
              secondary ? cs.onSecondaryContainer : cs.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
