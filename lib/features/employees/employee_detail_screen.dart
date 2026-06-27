import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/salary_calculator.dart';
import '../salary/salary_structure_screen.dart';
import 'employee_form_screen.dart';
import 'employee_payroll_history.dart';

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
  bool _loadingComponents = true;

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
    final components = await db.salaryComponentsDao.getComponentsByEmployee(_employee.id);
    if (!mounted) return;
    setState(() {
      _components = components;
      _loadingComponents = false;
    });
  }

  Future<void> _deleteEmployee() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee?'),
        content: Text(
          'This will permanently delete ${_employee.fullName} and cannot be undone. '
          'Their payroll history will also be deleted.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final db = AppDatabase.instance;
    await db.payrollRecordsDao.deleteRecordsByEmployee(_employee.id);
    await db.salaryComponentsDao.deleteComponentsByEmployee(_employee.id);
    await db.employeesDao.deleteEmployee(_employee.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Employee deleted successfully')),
    );
    Navigator.of(context).pop();
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
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _deleteEmployee,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
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
                        symbol: 'Rs. ',
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
                EmployeePayrollHistoryTab(
                  employee: _employee,
                  category: widget.category,
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPedo = employee.category == 'pedo';
    final fmt = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 0);

    final activeAllowances = components
        .where((c) => c.componentType == 'allowance' && c.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final regularAllowances = isPedo
        ? activeAllowances
            .where((c) => c.allowanceSection == 'regular' || c.allowanceSection == null)
            .toList()
        : activeAllowances;

    final otherAllowances = isPedo
        ? activeAllowances.where((c) => c.allowanceSection == 'other').toList()
        : <SalaryComponent>[];

    final activeDeductions = components
        .where((c) => c.componentType == 'deduction' && c.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final visibleDeductions = activeDeductions
        .where((c) => SalaryCalculator.calculateComponent(c, employee.baseSalary) > 0)
        .toList();

    final totalAllowances = SalaryCalculator.totalAllowances(activeAllowances, employee.baseSalary);
    final totalDeductions = SalaryCalculator.totalDeductions(activeDeductions, employee.baseSalary);
    final net = employee.baseSalary + totalAllowances - totalDeductions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Summary cards + Manage ─────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Basic Salary',
                      value: fmt.format(employee.baseSalary),
                      bg: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF3F4F6),
                      labelColor: isDark ? Colors.white54 : const Color(0xFF6B7280),
                      valueColor: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Total Allowances',
                      value: '+ ${fmt.format(totalAllowances)}',
                      bg: isDark ? const Color(0xFF1A2E1A) : const Color(0xFFE8F5E9),
                      labelColor: isDark ? Colors.white54 : const Color(0xFF6B7280),
                      valueColor: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Total Deductions',
                      value: '- ${fmt.format(totalDeductions)}',
                      bg: isDark ? const Color(0xFF2E1A1A) : const Color(0xFFFFEBEE),
                      labelColor: isDark ? Colors.white54 : const Color(0xFF6B7280),
                      valueColor: const Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Net Salary',
                      value: fmt.format(net),
                      bg: const Color(0xFF1B2235),
                      labelColor: Colors.white54,
                      valueColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: onManageStructure,
                    icon: const Icon(Icons.tune_outlined, size: 16),
                    label: const Text('Manage'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Allowance sections ─────────────────────────────────────────
              if (isPedo) ...[
                _SectionCards(
                  title: 'Regular Allowances',
                  count: regularAllowances.length,
                  accentColor: const Color(0xFF27AE60),
                  amountColor: const Color(0xFF1565C0),
                  components: regularAllowances,
                  baseSalary: employee.baseSalary,
                  isDark: isDark,
                  cs: cs,
                ),
                const SizedBox(height: 24),
                _SectionCards(
                  title: 'Other Allowances',
                  count: otherAllowances.length,
                  accentColor: const Color(0xFF7B68EE),
                  amountColor: const Color(0xFF7B68EE),
                  components: otherAllowances,
                  baseSalary: employee.baseSalary,
                  isDark: isDark,
                  cs: cs,
                ),
                const SizedBox(height: 24),
              ] else ...[
                _SectionCards(
                  title: 'Allowances',
                  count: activeAllowances.length,
                  accentColor: const Color(0xFF27AE60),
                  amountColor: const Color(0xFF1565C0),
                  components: activeAllowances,
                  baseSalary: employee.baseSalary,
                  isDark: isDark,
                  cs: cs,
                ),
                const SizedBox(height: 24),
              ],

              // ── Deductions (zero-value hidden) ─────────────────────────────
              if (visibleDeductions.isNotEmpty) ...[
                _SectionCards(
                  title: 'Deductions',
                  count: visibleDeductions.length,
                  accentColor: const Color(0xFFE53E3E),
                  amountColor: const Color(0xFFE53E3E),
                  components: visibleDeductions,
                  baseSalary: employee.baseSalary,
                  isDark: isDark,
                  cs: cs,
                ),
                const SizedBox(height: 24),
              ],

              // ── Net salary banner ──────────────────────────────────────────
              _NetBanner(
                baseSalary: employee.baseSalary,
                totalAllowances: totalAllowances,
                totalDeductions: totalDeductions,
                net: net,
                fmt: fmt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color bg;
  final Color labelColor;
  final Color valueColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.bg,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: labelColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionCards extends StatelessWidget {
  final String title;
  final int count;
  final Color accentColor;
  final Color amountColor;
  final List<SalaryComponent> components;
  final double baseSalary;
  final bool isDark;
  final ColorScheme cs;

  const _SectionCards({
    required this.title,
    required this.count,
    required this.accentColor,
    required this.amountColor,
    required this.components,
    required this.baseSalary,
    required this.isDark,
    required this.cs,
  });


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accentColor),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count Items',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (components.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Text(
              'No items',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          )
        else
          ...components.map(
            (c) => _ComponentCardTile(
              component: c,
              baseSalary: baseSalary,
              amountColor: amountColor,
              isDark: isDark,
              cs: cs,
            ),
          ),
      ],
    );
  }
}

// ── Component card tile with hover effect ─────────────────────────────────────

class _ComponentCardTile extends StatefulWidget {
  final SalaryComponent component;
  final double baseSalary;
  final Color amountColor;
  final bool isDark;
  final ColorScheme cs;

  const _ComponentCardTile({
    required this.component,
    required this.baseSalary,
    required this.amountColor,
    required this.isDark,
    required this.cs,
  });

  @override
  State<_ComponentCardTile> createState() => _ComponentCardTileState();
}

class _ComponentCardTileState extends State<_ComponentCardTile> {
  bool _hovered = false;

  static final _fmt = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    final c = widget.component;
    final calculated = SalaryCalculator.calculateComponent(c, widget.baseSalary);
    final isFrozen = c.freezeMode != 'not_frozen';
    final dotColor = isFrozen ? const Color(0xFF1565C0) : const Color(0xFF27AE60);
    final valueLabel = c.valueType == 'percentage'
        ? '${c.value.toStringAsFixed(0)}%'
        : 'Rs. ${_fmt.format(c.value)}';
    final cs = widget.cs;

    final baseBorderColor = isFrozen
        ? const Color(0xFF1565C0).withValues(alpha: 0.2)
        : cs.outlineVariant.withValues(alpha: 0.3);
    final hoverBorderColor = isFrozen
        ? const Color(0xFF1565C0).withValues(alpha: 0.4)
        : Colors.blue.shade200;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDark
                ? (isFrozen ? const Color(0xFF1E1E3E) : const Color(0xFF2A2A3E))
                : (_hovered
                    ? Colors.grey.shade50
                    : (isFrozen ? const Color(0xFFF0F4FF) : Colors.white)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered && !widget.isDark ? hoverBorderColor : baseBorderColor,
            ),
            boxShadow: widget.isDark
                ? null
                : _hovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Value: $valueLabel',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Rs. ${_fmt.format(calculated)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.amountColor,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isFrozen
                      ? const Color(0xFF1565C0).withValues(alpha: 0.1)
                      : const Color(0xFF27AE60).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFrozen
                        ? const Color(0xFF1565C0).withValues(alpha: 0.25)
                        : const Color(0xFF27AE60).withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  isFrozen ? 'FROZEN' : 'LIVE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isFrozen ? const Color(0xFF1565C0) : const Color(0xFF27AE60),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetBanner extends StatelessWidget {
  final double baseSalary;
  final double totalAllowances;
  final double totalDeductions;
  final double net;
  final NumberFormat fmt;

  const _NetBanner({
    required this.baseSalary,
    required this.totalAllowances,
    required this.totalDeductions,
    required this.net,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2235),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FormulaBlock(value: fmt.format(baseSalary), label: 'Basic', valueColor: Colors.white),
              _OpText('+'),
              _FormulaBlock(value: fmt.format(totalAllowances), label: 'Allowances', valueColor: const Color(0xFF4ADE80)),
              _OpText('−'),
              _FormulaBlock(value: fmt.format(totalDeductions), label: 'Deductions', valueColor: const Color(0xFFFC8181)),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 18),
          Text(
            'NET SALARY',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(net),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF4ADE80)),
          ),
        ],
      ),
    );
  }
}

class _FormulaBlock extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _FormulaBlock({required this.value, required this.label, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }
}

class _OpText extends StatelessWidget {
  final String op;
  const _OpText(this.op);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        op,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w300,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
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
