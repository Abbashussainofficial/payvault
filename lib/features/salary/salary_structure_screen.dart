import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/salary_calculator.dart';
import '../printing/pedo_payslip_preview.dart';
import 'allowance_form.dart';

class SalaryStructureScreen extends StatefulWidget {
  final Employee employee;
  final VoidCallback? onBack;
  const SalaryStructureScreen({required this.employee, this.onBack, super.key});

  @override
  State<SalaryStructureScreen> createState() => _SalaryStructureScreenState();
}

class _SalaryStructureScreenState extends State<SalaryStructureScreen> {
  late Employee _employee;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _editBaseSalary() async {
    final ctrl = TextEditingController(
      text: _employee.baseSalary > 0 ? _employee.baseSalary.toStringAsFixed(0) : '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Base Salary'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: const InputDecoration(labelText: 'Base Salary (PKR)', prefixText: 'PKR '),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final newSalary = double.tryParse(ctrl.text.trim());
    if (newSalary == null || newSalary == _employee.baseSalary) return;
    final updated = _employee.copyWith(baseSalary: newSalary);
    await AppDatabase.instance.employeesDao.updateEmployee(updated);
    if (!mounted) return;
    setState(() => _employee = updated);
  }

  Future<void> _addComponent(String type, {String? allowanceSection}) async {
    await showAllowanceForm(
      context: context,
      employee: _employee,
      componentType: type,
      allowanceSection: allowanceSection,
    );
  }

  Future<void> _editComponent(SalaryComponent c) async {
    await showAllowanceForm(
      context: context,
      employee: _employee,
      componentType: c.componentType,
      component: c,
      allowanceSection: c.allowanceSection,
    );
  }

  Future<void> _deleteComponent(SalaryComponent c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Component'),
        content: Text('Delete "${c.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
    if (ok != true) return;
    await AppDatabase.instance.salaryComponentsDao.deleteComponent(c.id);
  }

  Future<void> _toggleActive(SalaryComponent c) async {
    await AppDatabase.instance.salaryComponentsDao.updateComponent(c.copyWith(isActive: !c.isActive));
  }

  void _showPayslipPreview(List<SalaryComponent> components) {
    final now = DateTime.now();
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Payslip Preview — ${_employee.fullName}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            leading: const CloseButton(),
            backgroundColor: const Color(0xFF1B2235),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: PedoPayslipPreview.fromComponents(
            employee: _employee,
            components: components,
            month: now.month,
            year: now.year,
          ),
        ),
      ),
    );
  }

  static final _fmt = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 2);
  static final _fmtShort = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _employee.status == 'active';

    return Material(
      color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F7FA),
      child: StreamBuilder<List<SalaryComponent>>(
        stream: AppDatabase.instance.salaryComponentsDao.watchComponentsByEmployee(_employee.id),
        builder: (context, snapshot) {
          final components = snapshot.data ?? [];
          final isPedo = _employee.category == 'pedo';
          final allowances = components.where((c) => c.componentType == 'allowance').toList();
          final deductions = components.where((c) => c.componentType == 'deduction').toList();

          // For PEDO, split allowances into regular and other sections
          final regularAllowances = isPedo
              ? allowances.where((c) => c.allowanceSection == 'regular' || c.allowanceSection == null).toList()
              : allowances;
          final otherAllowances = isPedo
              ? allowances.where((c) => c.allowanceSection == 'other').toList()
              : <SalaryComponent>[];

          final totalRegular = SalaryCalculator.totalAllowances(regularAllowances, _employee.baseSalary);
          final totalOther = SalaryCalculator.totalAllowances(otherAllowances, _employee.baseSalary);
          final totalAllow = totalRegular + totalOther;
          final totalDeduct = SalaryCalculator.totalDeductions(deductions, _employee.baseSalary);
          final netSalary = _employee.baseSalary + totalAllow - totalDeduct;
          final activeAllowances = allowances.where((c) => c.isActive).length;
          final activeDeductions = deductions.where((c) => c.isActive).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header bar ────────────────────────────────────────────────────
              Container(
                color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _goBack,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.arrow_back_ios_new, size: 15,
                            color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PAYROLL DASHBOARD',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Salary Structure',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today_outlined, size: 17, color: cs.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time_outlined, size: 17, color: cs.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 14),
                    _adminChip(cs),
                  ],
                ),
              ),

              // ── Scrollable content ────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Employee card ───────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.12),
                              child: const Icon(Icons.person_outline, size: 28, color: Color(0xFF1565C0)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _employee.fullName,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Row(
                                    children: [
                                      _badge(
                                        'ID: ${_employee.employeeId}',
                                        const Color(0xFF1565C0),
                                      ),
                                      const SizedBox(width: 8),
                                      _badge(
                                        isActive ? 'Active Contract' : 'Inactive',
                                        isActive ? const Color(0xFF27AE60) : cs.error,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _editBaseSalary,
                              icon: const Icon(Icons.edit_outlined, size: 15),
                              label: const Text('Edit Structure', style: TextStyle(fontSize: 13)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1B2235),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            if (_employee.category == 'pedo') ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _showPayslipPreview(components),
                                icon: Icon(Icons.receipt_long_outlined, size: 15,
                                    color: cs.onSurface.withValues(alpha: 0.7)),
                                label: Text('Payslip Preview',
                                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7))),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  side: BorderSide(color: cs.outlineVariant),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Base salary card ────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Base Monthly Salary',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurface.withValues(alpha: 0.55),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _fmt.format(_employee.baseSalary),
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF1B2235),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_employee.bpsGrade != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF27AE60).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF27AE60).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_outlined, size: 15, color: Color(0xFF27AE60)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Approved ${_employee.bpsGrade}',
                                      style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF27AE60),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Allowances + Deductions ─────────────────────────────
                      if (isPedo) ...[
                        // PEDO: 3 stacked sections
                        _ComponentTable(
                          title: 'Regular Allowances',
                          activeCount: regularAllowances.where((c) => c.isActive).length,
                          headerColor: const Color(0xFF27AE60),
                          amountColor: const Color(0xFF1565C0),
                          components: regularAllowances,
                          baseSalary: _employee.baseSalary,
                          onAdd: () => _addComponent('allowance', allowanceSection: 'regular'),
                          onEdit: _editComponent,
                          onDelete: _deleteComponent,
                          onToggle: _toggleActive,
                          isDark: isDark,
                          cs: cs,
                        ),
                        const SizedBox(height: 16),
                        _ComponentTable(
                          title: 'Other Allowances',
                          activeCount: otherAllowances.where((c) => c.isActive).length,
                          headerColor: const Color(0xFF7B68EE),
                          amountColor: const Color(0xFF7B68EE),
                          components: otherAllowances,
                          baseSalary: _employee.baseSalary,
                          onAdd: () => _addComponent('allowance', allowanceSection: 'other'),
                          onEdit: _editComponent,
                          onDelete: _deleteComponent,
                          onToggle: _toggleActive,
                          isDark: isDark,
                          cs: cs,
                        ),
                        const SizedBox(height: 16),
                        _ComponentTable(
                          title: 'Deductions',
                          activeCount: activeDeductions,
                          headerColor: const Color(0xFFE53E3E),
                          amountColor: const Color(0xFFE53E3E),
                          components: deductions,
                          baseSalary: _employee.baseSalary,
                          onAdd: () => _addComponent('deduction'),
                          onEdit: _editComponent,
                          onDelete: _deleteComponent,
                          onToggle: _toggleActive,
                          isDark: isDark,
                          cs: cs,
                        ),
                      ] else ...[
                        // Security / Al Fajar: side-by-side layout (unchanged)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _ComponentTable(
                                  title: 'Allowances',
                                  activeCount: activeAllowances,
                                  headerColor: const Color(0xFF27AE60),
                                  amountColor: const Color(0xFF1565C0),
                                  components: allowances,
                                  baseSalary: _employee.baseSalary,
                                  onAdd: () => _addComponent('allowance'),
                                  onEdit: _editComponent,
                                  onDelete: _deleteComponent,
                                  onToggle: _toggleActive,
                                  isDark: isDark,
                                  cs: cs,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ComponentTable(
                                  title: 'Deductions',
                                  activeCount: activeDeductions,
                                  headerColor: const Color(0xFFE53E3E),
                                  amountColor: const Color(0xFFE53E3E),
                                  components: deductions,
                                  baseSalary: _employee.baseSalary,
                                  onAdd: () => _addComponent('deduction'),
                                  onEdit: _editComponent,
                                  onDelete: _deleteComponent,
                                  onToggle: _toggleActive,
                                  isDark: isDark,
                                  cs: cs,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Monthly summary card (dark navy) ────────────────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2235),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: title + formula
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Monthly Calculation Summary',
                                    style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    isPedo
                                        ? 'Formula: Base + Regular + Other − Deductions'
                                        : 'Formula: Base + Allowances − Deductions',
                                    style: TextStyle(
                                      fontSize: 11, color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right: totals + net salary
                            if (isPedo) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text('Regular Allowances',
                                          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5))),
                                      const SizedBox(width: 16),
                                      Text('Other Allowances',
                                          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5))),
                                      const SizedBox(width: 16),
                                      Text('Deductions',
                                          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5))),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '+ ${_fmtShort.format(totalRegular)}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4ADE80)),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('+', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
                                      const SizedBox(width: 10),
                                      Text(
                                        _fmtShort.format(totalOther),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF60A5FA)),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('−', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
                                      const SizedBox(width: 10),
                                      Text(
                                        _fmtShort.format(totalDeduct),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFFC8181)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text('ESTIMATED NET SALARY',
                                      style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: Colors.white.withValues(alpha: 0.45))),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fmtShort.format(netSalary),
                                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF4ADE80)),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Total Allowances',
                                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                                      ),
                                      const SizedBox(width: 24),
                                      Text(
                                        'Total Deductions',
                                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '+ ${_fmtShort.format(totalAllow)}',
                                        style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4ADE80),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text('−', style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.4))),
                                      const SizedBox(width: 14),
                                      Text(
                                        _fmtShort.format(totalDeduct),
                                        style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFFC8181),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'ESTIMATED NET SALARY',
                                    style: TextStyle(
                                      fontSize: 10, letterSpacing: 1.1, color: Colors.white.withValues(alpha: 0.45),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fmtShort.format(netSalary),
                                    style: const TextStyle(
                                      fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF4ADE80),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Footer row ──────────────────────────────────────────
                      Row(
                        children: [
                          Text(
                            'Last updated by Admin  •  ${_employee.designation}',
                            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              side: BorderSide(color: cs.outlineVariant),
                              foregroundColor: cs.onSurface.withValues(alpha: 0.6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history, size: 15),
                                SizedBox(width: 6),
                                Text('View Change Log', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: _goBack,
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text(
                              'Finalize & Close',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1B2235),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _adminChip(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 13,
            backgroundColor: Color(0xFF1565C0),
            child: Text('A', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin User',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface)),
              Text('System Manager',
                  style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Component table ────────────────────────────────────────────────────────────

class _ComponentTable extends StatelessWidget {
  final String title;
  final int activeCount;
  final Color headerColor;
  final Color amountColor;
  final List<SalaryComponent> components;
  final double baseSalary;
  final VoidCallback onAdd;
  final ValueChanged<SalaryComponent> onEdit;
  final ValueChanged<SalaryComponent> onDelete;
  final ValueChanged<SalaryComponent> onToggle;
  final bool isDark;
  final ColorScheme cs;

  const _ComponentTable({
    required this.title,
    required this.activeCount,
    required this.headerColor,
    required this.amountColor,
    required this.components,
    required this.baseSalary,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.isDark,
    required this.cs,
  });

  static final _fmt = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 3, height: 16,
                  decoration: BoxDecoration(
                    color: headerColor, borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: headerColor),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$activeCount Active Items',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: headerColor),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.add_circle_outline, size: 18, color: cs.primary),
                  ),
                ),
              ],
            ),
          ),

          // Column header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('NAME', style: _hStyle(cs))),
                Expanded(flex: 2, child: Text('VALUE', style: _hStyle(cs), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('CALCULATED', style: _hStyle(cs), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('STATUS', style: _hStyle(cs), textAlign: TextAlign.center)),
                const SizedBox(width: 64),
              ],
            ),
          ),

          // Empty state
          if (components.isEmpty)
            InkWell(
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(Icons.add_circle_outline, size: 28, color: cs.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    Text(
                      'No ${title.toLowerCase()} added',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
            ),

          // Component rows
          ...components.map((c) {
            final calculated = SalaryCalculator.calculateComponent(c, baseSalary);
            final isFrozen = c.freezeMode != 'not_frozen';
            final valueLabel = c.valueType == 'percentage'
                ? '${c.value.toStringAsFixed(0)}%'
                : _fmt.format(c.value);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    children: [
                      // Name
                      Expanded(
                        flex: 3,
                        child: Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: c.isActive
                                ? cs.onSurface
                                : cs.onSurface.withValues(alpha: 0.38),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Value
                      Expanded(
                        flex: 2,
                        child: Text(
                          valueLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55)),
                        ),
                      ),
                      // Calculated
                      Expanded(
                        flex: 2,
                        child: Text(
                          _fmt.format(calculated),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: c.isActive
                                ? amountColor
                                : cs.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      // Status badge
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isFrozen)
                                  const Icon(Icons.ac_unit, size: 9, color: Color(0xFF1565C0)),
                                if (!isFrozen)
                                  const Icon(Icons.circle, size: 6, color: Color(0xFF27AE60)),
                                const SizedBox(width: 4),
                                Text(
                                  isFrozen ? 'FROZEN' : 'LIVE',
                                  style: TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                                    color: isFrozen
                                        ? const Color(0xFF1565C0)
                                        : const Color(0xFF27AE60),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Edit + Delete actions
                      SizedBox(
                        width: 64,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => onEdit(c),
                              icon: Icon(Icons.edit_outlined, size: 15,
                                  color: cs.onSurface.withValues(alpha: 0.45)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => onDelete(c),
                              icon: Icon(Icons.delete_outline, size: 15,
                                  color: cs.error.withValues(alpha: 0.65)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.25)),
              ],
            );
          }),
        ],
      ),
    );
  }

  TextStyle _hStyle(ColorScheme cs) => TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
    color: cs.onSurface.withValues(alpha: 0.45),
  );
}
