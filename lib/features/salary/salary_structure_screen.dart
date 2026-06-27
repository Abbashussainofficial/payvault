import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/salary_calculator.dart';
import '../printing/pedo_payslip_preview.dart';
import '../printing/standard_payslip_preview.dart';
import 'allowance_form.dart';
import 'templates/apply_template_dialog.dart';

class SalaryStructureScreen extends StatefulWidget {
  final Employee employee;
  final VoidCallback? onBack;
  const SalaryStructureScreen({required this.employee, this.onBack, super.key});

  @override
  State<SalaryStructureScreen> createState() => _SalaryStructureScreenState();
}

class _SalaryStructureScreenState extends State<SalaryStructureScreen> {
  late Employee _employee;

  // Cached component list so callbacks can reference section data without
  // being inside the StreamBuilder closure.
  List<SalaryComponent> _lastComponents = [];

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

  // ── Base salary ─────────────────────────────────────────────────────────────

  Future<void> _editBaseSalary() async {
    final ctrl = TextEditingController(
      text: _employee.baseSalary > 0
          ? _employee.baseSalary.toStringAsFixed(0)
          : '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Base Salary'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Base Salary (Rs.)',
            prefixText: 'Rs. ',
          ),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update'),
          ),
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

  // ── Pay bill codes (PEDO only) ───────────────────────────────────────────────

  Future<void> _editPayCodes() async {
    final monthCtrl = TextEditingController(
      text: _employee.basicMonthCode ?? '',
    );
    final code1Ctrl = TextEditingController(
      text: _employee.basicPayCode1 ?? '',
    );
    final code2Ctrl = TextEditingController(
      text: _employee.basicPayCode2 ?? '',
    );
    final grossCtrl = TextEditingController(
      text: _employee.grossClaimCode ?? '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pay Bill Classification Codes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'These codes appear in the Classification Code column of the official pay bill.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: monthCtrl,
              decoration: const InputDecoration(
                labelText: 'Month Row Code',
                hintText: 'e.g. 00000',
                helperText: '"Pay for the Month of …" row',
              ),
              onSubmitted: (_) => FocusScope.of(ctx).nextFocus(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: code1Ctrl,
              decoration: const InputDecoration(
                labelText: 'Pay Code 1',
                hintText: 'e.g. 011000',
                helperText: 'First basic salary amount row',
              ),
              onSubmitted: (_) => FocusScope.of(ctx).nextFocus(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: code2Ctrl,
              decoration: const InputDecoration(
                labelText: 'Pay Code 2',
                hintText: 'e.g. 01100',
                helperText: '"Pay … / Total Basic Salary" two-line row',
              ),
              onSubmitted: (_) => FocusScope.of(ctx).nextFocus(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: grossCtrl,
              decoration: const InputDecoration(
                labelText: 'Gross Claim Code (Optional)',
                hintText: 'e.g. 00000',
                helperText: '"Gross claim-Establishment charges" row',
              ),
              onSubmitted: (_) => Navigator.pop(ctx, true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    String? n(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final updated = _employee.copyWith(
      basicMonthCode: Value(n(monthCtrl)),
      basicPayCode1: Value(n(code1Ctrl)),
      basicPayCode2: Value(n(code2Ctrl)),
      grossClaimCode: Value(n(grossCtrl)),
    );
    await AppDatabase.instance.employeesDao.updateEmployee(updated);
    if (!mounted) return;
    setState(() => _employee = updated);
  }

  // ── Component CRUD ───────────────────────────────────────────────────────────

  Future<void> _addComponent(String type, {String? allowanceSection}) async {
    // Compute next sortOrder for this section so new items always land at bottom
    final sectionComps = _lastComponents.where((c) {
      if (c.componentType != type) return false;
      if (type == 'allowance') return c.allowanceSection == allowanceSection;
      return true; // deduction — one section
    }).toList();
    final nextSortOrder = sectionComps.isEmpty
        ? 0
        : sectionComps.fold(0, (m, c) => c.sortOrder > m ? c.sortOrder : m) + 1;

    await showAllowanceForm(
      context: context,
      employee: _employee,
      componentType: type,
      allowanceSection: allowanceSection,
      nextSortOrder: nextSortOrder,
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
          TextButton(
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
    if (ok != true) return;
    await AppDatabase.instance.salaryComponentsDao.deleteComponent(c.id);
  }

  Future<void> _toggleActive(SalaryComponent c) async {
    await AppDatabase.instance.salaryComponentsDao.updateComponent(
      c.copyWith(isActive: !c.isActive),
    );
  }

  // ── Reorder ──────────────────────────────────────────────────────────────────

  /// Moves [c] up or down within [section] by reassigning sequential sortOrders
  /// to every item in the section (normalises any duplicates) then committing
  /// in a single batch so the stream fires exactly once.
  Future<void> _moveComponent(
    SalaryComponent c,
    List<SalaryComponent> section,
    bool up,
  ) async {
    final idx = section.indexWhere((s) => s.id == c.id);
    final targetIdx = up ? idx - 1 : idx + 1;
    if (idx < 0 || targetIdx < 0 || targetIdx >= section.length) return;

    // Build the new order by swapping positions
    final reordered = List<SalaryComponent>.from(section);
    reordered.removeAt(idx);
    reordered.insert(targetIdx, c);

    // Write all sortOrders in one batch — single stream emission
    await AppDatabase.instance.batch((batch) {
      for (var i = 0; i < reordered.length; i++) {
        batch.update(
          AppDatabase.instance.salaryComponents,
          SalaryComponentsCompanion(sortOrder: Value(i)),
          where: (t) => t.id.equals(reordered[i].id),
        );
      }
    });
  }

  // ── Payslip preview ──────────────────────────────────────────────────────────

  void _showPayslipPreview(List<SalaryComponent> components) {
    final now = DateTime.now();
    final isPedo = _employee.category == 'pedo';
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
          body: isPedo
              ? PedoPayslipPreview.fromComponents(
                  employee: _employee,
                  components: components,
                  month: now.month,
                  year: now.year,
                )
              : StandardPayslipPreview(
                  employee: _employee,
                  month: now.month,
                  year: now.year,
                  category: _employee.category,
                  // null = draft mode; streams live components from DB
                ),
        ),
      ),
    );
  }

  // ── Formatters ───────────────────────────────────────────────────────────────

  static final _fmt = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 2,
  );
  static final _fmtShort = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _employee.status == 'active';

    return Material(
      color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F7FA),
      child: StreamBuilder<List<SalaryComponent>>(
        stream: AppDatabase.instance.salaryComponentsDao
            .watchComponentsByEmployee(_employee.id),
        builder: (context, snapshot) {
          final components = snapshot.data ?? [];
          // Keep cached copy so callbacks (add/move) can use it without being
          // inside the builder closure.
          _lastComponents = components;

          final isPedo = _employee.category == 'pedo';
          final allowances = components
              .where((c) => c.componentType == 'allowance')
              .toList();
          final deductions = components
              .where((c) => c.componentType == 'deduction')
              .toList();

          // PEDO: split allowances; both lists are already sorted by sortOrder (DAO order).
          final regularAllowances = isPedo
              ? allowances
                    .where(
                      (c) =>
                          c.allowanceSection == 'regular' ||
                          c.allowanceSection == null,
                    )
                    .toList()
              : allowances;
          final otherAllowances = isPedo
              ? allowances.where((c) => c.allowanceSection == 'other').toList()
              : <SalaryComponent>[];

          // ── Computed totals (recalculated on every stream emission or setState) ──
          final totalRegular = SalaryCalculator.totalAllowances(
            regularAllowances,
            _employee.baseSalary,
          );
          // Gross Claim is display-only — exclude from net salary
          final otherForNet = otherAllowances
              .where((c) => !c.name.toLowerCase().contains('gross claim'))
              .toList();
          final totalOther = SalaryCalculator.totalAllowances(
            otherForNet,
            _employee.baseSalary,
          );
          final totalAllow = totalRegular + totalOther;
          final totalDeduct = SalaryCalculator.totalDeductions(
            deductions,
            _employee.baseSalary,
          );
          final netSalary = _employee.baseSalary + totalAllow - totalDeduct;
          final activeAllowances = allowances.where((c) => c.isActive).length;
          final activeDeductions = deductions.where((c) => c.isActive).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header bar ─────────────────────────────────────────────────
              Container(
                color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _goBack,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 15,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PAYROLL DASHBOARD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Salary Structure',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 17,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.access_time_outlined,
                      size: 17,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 14),
                    _adminChip(cs),
                  ],
                ),
              ),

              // ── Scrollable content ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Employee card ────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A3E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(
                                0xFF1565C0,
                              ).withValues(alpha: 0.12),
                              child: const Icon(
                                Icons.person_outline,
                                size: 28,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _employee.fullName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
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
                                        isActive
                                            ? 'Active Contract'
                                            : 'Inactive',
                                        isActive
                                            ? const Color(0xFF27AE60)
                                            : cs.error,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _editBaseSalary,
                              icon: const Icon(Icons.edit_outlined, size: 15),
                              label: const Text(
                                'Edit Base Salary',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1B2235),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showPayslipPreview(components),
                                icon: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 15,
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                ),
                                label: Text(
                                  'Payslip Preview',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  side: BorderSide(color: cs.outlineVariant),
                                ),
                              ),
                              if (_employee.category == 'pedo') ...[
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => showApplyTemplateDialog(
                                    context: context,
                                    employee: _employee,
                                  ),
                                  icon: const Icon(
                                    Icons.description_outlined,
                                    size: 15,
                                    color: Color(0xFF1B2235),
                                  ),
                                  label: const Text(
                                    'Apply Template',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1B2235),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF1B2235),
                                    ),
                                  ),
                                ),
                              ],  // closes if (pedo) ...[
                            ],    // closes outer ...[
                          ],      // closes Row children
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Base salary card ──────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A3E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Base Monthly Salary',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurface.withValues(
                                            alpha: 0.55,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _fmt.format(_employee.baseSalary),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1B2235),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_employee.bpsGrade != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF27AE60,
                                      ).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF27AE60,
                                        ).withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified_outlined,
                                          size: 15,
                                          color: Color(0xFF27AE60),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Approved ${_employee.bpsGrade}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF27AE60),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            // ── Pay bill codes row (PEDO only) ─────────────
                            if (_employee.category == 'pedo') ...[
                              const SizedBox(height: 14),
                              Divider(
                                height: 1,
                                color: cs.outlineVariant.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    'Pay Bill Codes',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _codeChip(
                                    'Month',
                                    _employee.basicMonthCode,
                                    cs,
                                  ),
                                  const SizedBox(width: 8),
                                  _codeChip(
                                    'Pay 1',
                                    _employee.basicPayCode1,
                                    cs,
                                  ),
                                  const SizedBox(width: 8),
                                  _codeChip(
                                    'Pay 2',
                                    _employee.basicPayCode2,
                                    cs,
                                  ),
                                  const SizedBox(width: 8),
                                  _codeChip(
                                    'Gross Claim',
                                    _employee.grossClaimCode,
                                    cs,
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: _editPayCodes,
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 13,
                                      color: cs.onSurface.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                    label: Text(
                                      'Edit Codes',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurface.withValues(
                                          alpha: 0.55,
                                        ),
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Allowances + Deductions ───────────────────────────
                      if (isPedo) ...[
                        _ComponentTable(
                          title: 'Regular Allowances',
                          activeCount: regularAllowances
                              .where((c) => c.isActive)
                              .length,
                          headerColor: const Color(0xFF27AE60),
                          amountColor: const Color(0xFF1565C0),
                          components: regularAllowances,
                          baseSalary: _employee.baseSalary,
                          onAdd: () => _addComponent(
                            'allowance',
                            allowanceSection: 'regular',
                          ),
                          onEdit: _editComponent,
                          onDelete: _deleteComponent,
                          onToggle: _toggleActive,
                          onMoveUp: (c) =>
                              _moveComponent(c, regularAllowances, true),
                          onMoveDown: (c) =>
                              _moveComponent(c, regularAllowances, false),
                          isDark: isDark,
                          cs: cs,
                        ),
                        const SizedBox(height: 16),
                        _ComponentTable(
                          title: 'Other Allowances',
                          activeCount: otherAllowances
                              .where((c) => c.isActive)
                              .length,
                          headerColor: const Color(0xFF7B68EE),
                          amountColor: const Color(0xFF7B68EE),
                          components: otherAllowances,
                          baseSalary: _employee.baseSalary,
                          onAdd: () => _addComponent(
                            'allowance',
                            allowanceSection: 'other',
                          ),
                          onEdit: _editComponent,
                          onDelete: _deleteComponent,
                          onToggle: _toggleActive,
                          onMoveUp: (c) =>
                              _moveComponent(c, otherAllowances, true),
                          onMoveDown: (c) =>
                              _moveComponent(c, otherAllowances, false),
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
                          onMoveUp: (c) => _moveComponent(c, deductions, true),
                          onMoveDown: (c) =>
                              _moveComponent(c, deductions, false),
                          isDark: isDark,
                          cs: cs,
                        ),
                      ] else ...[
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
                                  onMoveUp: (c) =>
                                      _moveComponent(c, allowances, true),
                                  onMoveDown: (c) =>
                                      _moveComponent(c, allowances, false),
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
                                  onMoveUp: (c) =>
                                      _moveComponent(c, deductions, true),
                                  onMoveDown: (c) =>
                                      _moveComponent(c, deductions, false),
                                  isDark: isDark,
                                  cs: cs,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Monthly summary card (dark navy) ──────────────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2235),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Monthly Calculation Summary',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    isPedo
                                        ? 'Formula: Base + Regular + Other − Deductions'
                                        : 'Formula: Base + Allowances − Deductions',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            if (isPedo) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Regular Allowances',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Other Allowances',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Deductions',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '+ ${_fmtShort.format(totalRegular)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4ADE80),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '+',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _fmtShort.format(totalOther),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF60A5FA),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '−',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _fmtShort.format(totalDeduct),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFFC8181),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'ESTIMATED NET SALARY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1.1,
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fmtShort.format(netSalary),
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4ADE80),
                                    ),
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
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Text(
                                        'Total Deductions',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '+ ${_fmtShort.format(totalAllow)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4ADE80),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        '−',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        _fmtShort.format(totalDeduct),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFFC8181),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'ESTIMATED NET SALARY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1.1,
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fmtShort.format(netSalary),
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4ADE80),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Footer row ────────────────────────────────────────
                      Row(
                        children: [
                          Text(
                            'Last updated by Admin  •  ${_employee.designation}',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              side: BorderSide(color: cs.outlineVariant),
                              foregroundColor: cs.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history, size: 15),
                                SizedBox(width: 6),
                                Text(
                                  'View Change Log',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: _goBack,
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                            ),
                            label: const Text(
                              'Finalize & Close',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1B2235),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _codeChip(String label, String? value, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 10,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value?.isNotEmpty == true ? value! : '—',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value?.isNotEmpty == true
                    ? cs.onSurface.withValues(alpha: 0.8)
                    : cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
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
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin User',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              Text(
                'System Manager',
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
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
  final ValueChanged<SalaryComponent> onMoveUp;
  final ValueChanged<SalaryComponent> onMoveDown;
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
    required this.onMoveUp,
    required this.onMoveDown,
    required this.isDark,
    required this.cs,
  });

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
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: headerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$activeCount Active Items',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: headerColor,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Column header row — 5 columns: Name | Value | Calculated | Status | Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('NAME', style: _hStyle(cs))),
                SizedBox(
                  width: 100,
                  child: Text(
                    'VALUE',
                    style: _hStyle(cs),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'CALCULATED',
                    style: _hStyle(cs),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'STATUS',
                    style: _hStyle(cs),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 152),
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
                    Icon(
                      Icons.add_circle_outline,
                      size: 28,
                      color: cs.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No ${title.toLowerCase()} added',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Component rows
          ...components.asMap().entries.map(
            (entry) => _ComponentRow(
              component: entry.value,
              index: entry.key,
              total: components.length,
              baseSalary: baseSalary,
              amountColor: amountColor,
              onEdit: onEdit,
              onDelete: onDelete,
              onMoveUp: onMoveUp,
              onMoveDown: onMoveDown,
              isDark: isDark,
              cs: cs,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _hStyle(ColorScheme cs) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: cs.onSurface.withValues(alpha: 0.45),
  );
}

// ── Grouped action buttons [▲ | ▼ | ✎ | 🗑] ────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDark;

  const _ActionButtons({
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final divColor = isDark ? Colors.grey.shade600 : Colors.grey.shade300;
    final activeColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final disabledColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, size: 18),
            onPressed: onMoveUp,
            tooltip: 'Move Up',
            color: onMoveUp != null ? activeColor : disabledColor,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Container(width: 1, height: 16, color: divColor),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            onPressed: onMoveDown,
            tooltip: 'Move Down',
            color: onMoveDown != null ? activeColor : disabledColor,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Container(width: 1, height: 16, color: divColor),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
            tooltip: 'Edit',
            color: Colors.blue.shade600,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Container(width: 1, height: 16, color: divColor),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
            tooltip: 'Delete',
            color: Colors.red.shade400,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ── Component row with hover effect ──────────────────────────────────────────

class _ComponentRow extends StatefulWidget {
  final SalaryComponent component;
  final int index;
  final int total;
  final double baseSalary;
  final Color amountColor;
  final ValueChanged<SalaryComponent> onEdit;
  final ValueChanged<SalaryComponent> onDelete;
  final ValueChanged<SalaryComponent> onMoveUp;
  final ValueChanged<SalaryComponent> onMoveDown;
  final bool isDark;
  final ColorScheme cs;

  const _ComponentRow({
    required this.component,
    required this.index,
    required this.total,
    required this.baseSalary,
    required this.amountColor,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.isDark,
    required this.cs,
  });

  @override
  State<_ComponentRow> createState() => _ComponentRowState();
}

class _ComponentRowState extends State<_ComponentRow> {
  bool _hovered = false;

  static final _fmt = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.component;
    final isFirst = widget.index == 0;
    final isLast = widget.index == widget.total - 1;
    final calculated = SalaryCalculator.calculateComponent(c, widget.baseSalary);
    final isFrozen = c.freezeMode != 'not_frozen';
    final valueLabel = c.valueType == 'percentage'
        ? '${c.value.toStringAsFixed(0)}%'
        : _fmt.format(c.value);
    final cs = widget.cs;

    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: _hovered
                ? (widget.isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF8FAFC))
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    c.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.isActive
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.38),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    valueLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    _fmt.format(calculated),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.isActive
                          ? widget.amountColor
                          : cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
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
                            const Icon(
                              Icons.ac_unit,
                              size: 9,
                              color: Color(0xFF1565C0),
                            ),
                          if (!isFrozen)
                            const Icon(
                              Icons.circle,
                              size: 6,
                              color: Color(0xFF27AE60),
                            ),
                          const SizedBox(width: 4),
                          Text(
                            isFrozen ? 'FROZEN' : 'LIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
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
                SizedBox(
                  width: 152,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _ActionButtons(
                      onMoveUp: isFirst ? null : () => widget.onMoveUp(c),
                      onMoveDown: isLast ? null : () => widget.onMoveDown(c),
                      onEdit: () => widget.onEdit(c),
                      onDelete: () => widget.onDelete(c),
                      isDark: widget.isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.25)),
      ],
    );
  }
}
