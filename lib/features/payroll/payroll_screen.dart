import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/payroll_snapshot.dart';
import '../../core/utils/salary_calculator.dart';
import '../employees/employee_detail_screen.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _EmpRow {
  final Employee employee;
  final PayrollRecord? record;
  final List<SalaryComponent> components;

  const _EmpRow({required this.employee, this.record, required this.components});

  bool get isProcessed => record != null;
  bool get isLocked => record?.isLocked ?? false;
  bool get isSelectable => !isLocked;

  double get baseSalary => record?.baseSalary ?? employee.baseSalary;
  double get totalAllowances =>
      record?.totalAllowances ?? SalaryCalculator.totalAllowances(components, employee.baseSalary);
  double get totalDeductions =>
      record?.totalDeductions ?? SalaryCalculator.totalDeductions(components, employee.baseSalary);
  double get netSalary {
    if (record != null) return record!.netSalary;
    final base = employee.baseSalary;
    if (employee.category == 'pedo') {
      final regular = components.where((c) =>
          c.isActive && c.componentType == 'allowance' &&
          (c.allowanceSection == 'regular' || c.allowanceSection == null)).toList();
      // Gross Claim is display-only — exclude from net
      final otherForNet = components.where((c) =>
          c.isActive && c.componentType == 'allowance' &&
          c.allowanceSection == 'other' &&
          !c.name.toLowerCase().contains('gross claim')).toList();
      final deducts = components.where((c) =>
          c.isActive && c.componentType == 'deduction').toList();
      return base +
          SalaryCalculator.totalAllowances(regular, base) +
          SalaryCalculator.totalAllowances(otherForNet, base) -
          SalaryCalculator.totalDeductions(deducts, base);
    }
    return SalaryCalculator.net(base, components, components);
  }
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

  // per-employee selection (only selectable rows can be in here)
  final Set<int> _selectedIds = {};

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  final _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);
  final _currencyShort = NumberFormat.compactCurrency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 1);

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
      final employees = await _db.employeesDao.getEmployeesByCategory(widget.category);
      final records = await _db.payrollRecordsDao.getRecordsByMonthYear(_month, _year);
      final recordMap = {for (final r in records) r.employeeId: r};

      final rows = <_EmpRow>[];
      for (final emp in employees) {
        final comps = await _db.salaryComponentsDao.getComponentsByEmployee(emp.id);
        rows.add(_EmpRow(employee: emp, record: recordMap[emp.id], components: comps));
      }
      if (mounted) {
        setState(() {
          _rows = rows;
          // Keep only selections that still exist and are selectable
          _selectedIds.removeWhere((id) {
            final row = rows.where((r) => r.employee.id == id).firstOrNull;
            return row == null || !row.isSelectable;
          });
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Selection helpers ──────────────────────────────────────────────────────

  List<_EmpRow> get _selectableRows => _rows.where((r) => r.isSelectable).toList();
  List<_EmpRow> get _selectedRows =>
      _rows.where((r) => _selectedIds.contains(r.employee.id) && r.isSelectable).toList();

  bool get _allSelectableSelected {
    final sel = _selectableRows;
    return sel.isNotEmpty && sel.every((r) => _selectedIds.contains(r.employee.id));
  }

  void _toggleSelectAll(bool? val) {
    setState(() {
      if (val == true) {
        _selectedIds.addAll(_selectableRows.map((r) => r.employee.id));
      } else {
        _selectedIds.removeAll(_selectableRows.map((r) => r.employee.id));
      }
    });
  }

  void _toggleRow(int empId, bool? val) {
    setState(() {
      if (val == true) {
        _selectedIds.add(empId);
      } else {
        _selectedIds.remove(empId);
      }
    });
  }

  // ── Processing ─────────────────────────────────────────────────────────────

  Future<void> _processRows(List<_EmpRow> rows) async {
    if (rows.isEmpty) return;
    setState(() => _processing = true);
    try {
      final now = DateTime.now().toIso8601String();
      for (final row in rows) {
        if (row.isLocked) continue;
        final emp = row.employee;
        final comps = row.components;
        final base = emp.baseSalary;
        final isPedo = emp.category == 'pedo';
        final activeAllow = comps.where((c) => c.isActive && c.componentType == 'allowance').toList();
        final activeDeduct = comps.where((c) => c.isActive && c.componentType == 'deduction').toList();

        // For PEDO, split allowances and exclude Gross Claim from net calculation
        final activeRegular = isPedo
            ? activeAllow.where((c) => c.allowanceSection == 'regular' || c.allowanceSection == null).toList()
            : activeAllow;
        final activeOther = isPedo
            ? activeAllow.where((c) => c.allowanceSection == 'other').toList()
            : <SalaryComponent>[];
        // Gross Claim is display-only — exclude from totalAllowances and net
        final activeOtherForNet = isPedo
            ? activeOther.where((c) => !c.name.toLowerCase().contains('gross claim')).toList()
            : activeOther;

        final totalAllow = SalaryCalculator.totalAllowances(activeRegular, base)
            + (isPedo ? SalaryCalculator.totalAllowances(activeOtherForNet, base) : 0.0);
        final totalDeduct = SalaryCalculator.totalDeductions(comps, base);
        final net = base + totalAllow - totalDeduct;

        List<PayrollComponent> snapshot;
        if (isPedo) {
          snapshot = [
            ...activeRegular.map((c) => PayrollComponent(
              name: c.name, code: c.classificationCode, type: 'allowance',
              section: 'regular',
              amount: SalaryCalculator.calculateComponent(c, base),
              sortOrder: c.sortOrder,
            )),
            // All 'other' allowances — Gross Claim (user-entered) stored as normal component
            ...activeOther.map((c) => PayrollComponent(
              name: c.name, code: c.classificationCode, type: 'allowance',
              section: 'other',
              amount: SalaryCalculator.calculateComponent(c, base),
              sortOrder: c.sortOrder,
            )),
            ...activeDeduct.map((c) => PayrollComponent(
              name: c.name, code: c.classificationCode, type: 'deduction',
              amount: SalaryCalculator.calculateComponent(c, base),
              sortOrder: c.sortOrder,
            )),
          ];
        } else {
          snapshot = [
            ...activeAllow.map((c) => PayrollComponent(
              name: c.name, code: c.classificationCode, type: 'allowance',
              section: c.allowanceSection,
              amount: SalaryCalculator.calculateComponent(c, base),
              sortOrder: c.sortOrder,
            )),
            ...activeDeduct.map((c) => PayrollComponent(
              name: c.name, code: c.classificationCode, type: 'deduction',
              amount: SalaryCalculator.calculateComponent(c, base),
              sortOrder: c.sortOrder,
            )),
          ];
        }

        // Encode: PEDO records use PayrollSnapshot (includes pay bill codes);
        // non-PEDO uses the legacy flat-array format.
        final encodedSnapshot = isPedo
            ? PayrollSnapshot(
                components: snapshot,
                basicMonthCode: emp.basicMonthCode,
                basicPayCode1: emp.basicPayCode1,
                basicPayCode2: emp.basicPayCode2,
              ).encode()
            : PayrollComponent.encodeSnapshot(snapshot);

        await _db.payrollRecordsDao.upsertRecord(PayrollRecordsCompanion(
          employeeId: Value(emp.id),
          month: Value(_month),
          year: Value(_year),
          baseSalary: Value(base),
          totalAllowances: Value(totalAllow),
          totalDeductions: Value(totalDeduct),
          netSalary: Value(net),
          salarySnapshot: Value(encodedSnapshot),
          isLocked: const Value(true),
          processedAt: Value(now),
        ));
      }
      _selectedIds.clear();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Processed ${rows.length} employee${rows.length > 1 ? 's' : ''} for ${_monthNames[_month - 1]} $_year'),
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

  Future<void> _processSelected() async {
    final toProcess = _selectedRows.where((r) => !r.isLocked).toList();
    if (toProcess.isEmpty) return;

    if (toProcess.length > 1) {
      final names = toProcess.map((r) => '• ${r.employee.fullName}').join('\n');
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Process Payroll'),
          content: Text(
            'Lock payroll for ${_monthNames[_month - 1]} $_year for:\n\n$names\n\n'
            'Records will be saved and cannot be changed without unlocking.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Process & Lock')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    await _processRows(toProcess);
  }

  Future<void> _processAllPending() async {
    final pending = _rows.where((r) => !r.isLocked).toList();
    if (pending.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Process All Pending'),
        content: Text(
          'Process and lock payroll for ${pending.length} pending employee${pending.length > 1 ? 's' : ''} '
          'for ${_monthNames[_month - 1]} $_year?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Process All')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _processRows(pending);
  }

  // ── Unlock ─────────────────────────────────────────────────────────────────

  Future<void> _unlockEmployee(_EmpRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlock Payroll'),
        content: Text(
          'Unlock ${row.employee.fullName}\'s ${_monthNames[_month - 1]} $_year payroll?\n\n'
          'This allows reprocessing with updated salary data.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFED8936)),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _db.payrollRecordsDao.unlockRecord(row.record!.id);
    await _loadData();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final processedCount = _rows.where((r) => r.isLocked).length;
    final pendingCount = _rows.where((r) => !r.isLocked).length;
    final totalNet = _rows.where((r) => r.isLocked).fold(0.0, (s, r) => s + r.netSalary);
    final totalDeduct = _rows.fold(0.0, (s, r) => s + r.totalDeductions);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
            child: Row(
              children: [
                Text('Payroll Processing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Container(width: 1, height: 20, color: cs.outlineVariant),
                const SizedBox(width: 10),
                Icon(Icons.calendar_today_outlined, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 5),
                Text('${_monthNames[_month - 1]} $_year',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
                const Spacer(),
                Icon(Icons.access_time_outlined, size: 17, color: cs.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 14),
                _adminChip(cs),
              ],
            ),
          ),

          // ── Controls ───────────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: Row(
              children: [
                _MonthDropdown(month: _month, onChanged: (m) { setState(() => _month = m); _loadData(); },
                  monthNames: _monthNames, cs: cs),
                const SizedBox(width: 10),
                _YearDropdown(year: _year, onChanged: (y) { setState(() => _year = y); _loadData(); }, cs: cs),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.filter_alt_outlined, size: 15),
                  label: const Text('Filter Data', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    side: BorderSide(color: cs.outlineVariant),
                    foregroundColor: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // ── Summary strip ──────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                _StatChip(icon: Icons.check_circle_outline, iconColor: const Color(0xFF27AE60),
                  label: 'Processed', value: '$processedCount', isDark: isDark, cs: cs),
                const SizedBox(width: 12),
                _StatChip(icon: Icons.hourglass_empty_outlined, iconColor: const Color(0xFFED8936),
                  label: 'Pending', value: '$pendingCount', isDark: isDark, cs: cs),
                const SizedBox(width: 12),
                _StatChip(icon: Icons.account_balance_wallet_outlined, iconColor: const Color(0xFF1565C0),
                  label: 'Total Payroll This Month', value: _currencyShort.format(totalNet), isDark: isDark, cs: cs),
                const SizedBox(width: 12),
                _StatChip(icon: Icons.remove_circle_outline, iconColor: const Color(0xFFE53E3E),
                  label: 'Total Deductions', value: _currencyShort.format(totalDeduct), isDark: isDark, cs: cs),
              ],
            ),
          ),

          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),

          // ── Table + sticky bottom ──────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? Center(
                        child: Text('No employees in this category.',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.45))),
                      )
                    : Column(
                        children: [
                          // Select-All bar
                          _buildSelectAllBar(cs, isDark),
                          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),

                          // Table
                          Expanded(child: _buildTable(cs, isDark)),

                          // Action buttons (Process All / Process Selected Only)
                          _buildActionButtons(cs, isDark, pendingCount),

                          // Grand total
                          _buildGrandTotal(cs, isDark, totalNet, totalDeduct),

                          // Audit log
                          _buildAuditLog(cs, isDark),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ── Select-All bar ─────────────────────────────────────────────────────────

  Widget _buildSelectAllBar(ColorScheme cs, bool isDark) {
    final selectable = _selectableRows.length;
    final selected = _selectedIds.length;
    return Container(
      color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Checkbox(
            tristate: true,
            value: selectable == 0 ? false : (_allSelectableSelected ? true : (selected > 0 ? null : false)),
            onChanged: selectable == 0 ? null : _toggleSelectAll,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          Text(
            '$selected of $selectable selected',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }

  // ── Table ──────────────────────────────────────────────────────────────────

  Widget _buildTable(ColorScheme cs, bool isDark) {
    final labelStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
      color: cs.onSurface.withValues(alpha: 0.5));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            child: Row(
              children: [
                const SizedBox(width: 36), // checkbox placeholder
                Expanded(flex: 9, child: Text('EMPLOYEE ID', style: labelStyle)),
                Expanded(flex: 15, child: Text('EMPLOYEE', style: labelStyle)),
                Expanded(flex: 10, child: Text('BASIC SALARY', style: labelStyle, textAlign: TextAlign.right)),
                Expanded(flex: 10, child: Text('ALLOWANCES', style: labelStyle, textAlign: TextAlign.right)),
                Expanded(flex: 10, child: Text('DEDUCTIONS', style: labelStyle, textAlign: TextAlign.right)),
                Expanded(flex: 13, child: Text('NET SALARY', style: labelStyle, textAlign: TextAlign.right)),
                Expanded(flex: 8, child: Text('ACTION', style: labelStyle, textAlign: TextAlign.center)),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),

          ..._rows.map((row) => _buildTableRow(row, cs, isDark)),
        ],
      ),
    );
  }

  Widget _buildTableRow(_EmpRow row, ColorScheme cs, bool isDark) {
    final isSelected = _selectedIds.contains(row.employee.id);
    final isLocked = row.isLocked;

    // For locked rows, show the date the record was processed
    String? processedDate;
    if (isLocked && row.record?.processedAt != null) {
      try {
        final dt = DateTime.parse(row.record!.processedAt);
        processedDate = DateFormat('d MMM').format(dt);
      } catch (_) {}
    }

    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => EmployeeDetailScreen(employee: row.employee, category: widget.category),
          )),
          hoverColor: cs.primary.withValues(alpha: 0.04),
          child: Container(
            color: isSelected && !isLocked
                ? cs.primary.withValues(alpha: 0.05)
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox
                SizedBox(
                  width: 36,
                  child: Checkbox(
                    value: isLocked ? false : isSelected,
                    onChanged: isLocked ? null : (v) => _toggleRow(row.employee.id, v),
                    visualDensity: VisualDensity.compact,
                  ),
                ),

                // Employee ID
                Expanded(
                  flex: 9,
                  child: Text(row.employee.employeeId,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Color(0xFF1565C0), fontFamily: 'monospace')),
                ),

                // Name + designation
                Expanded(
                  flex: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.employee.fullName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(row.employee.designation,
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),

                // Basic salary
                Expanded(flex: 10, child: Text(_currency.format(row.baseSalary),
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.75)),
                  textAlign: TextAlign.right)),

                // Allowances
                Expanded(flex: 10, child: Text(_currency.format(row.totalAllowances),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF27AE60), fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right)),

                // Deductions
                Expanded(flex: 10, child: Text(_currency.format(row.totalDeductions),
                  style: const TextStyle(fontSize: 12, color: Color(0xFFE53E3E), fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right)),

                // Net salary with status indicator
                Expanded(
                  flex: 13,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(_currency.format(row.netSalary),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary),
                          textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      if (isLocked) ...[
                        Icon(Icons.lock_outline, size: 12, color: const Color(0xFFED8936).withValues(alpha: 0.85)),
                        if (processedDate != null) ...[
                          const SizedBox(width: 3),
                          Text(processedDate, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.45))),
                        ],
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Pending',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                              color: cs.onSurface.withValues(alpha: 0.5))),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action (unlock)
                Expanded(
                  flex: 8,
                  child: Center(
                    child: isLocked
                        ? OutlinedButton.icon(
                            onPressed: () => _unlockEmployee(row),
                            icon: const Icon(Icons.lock_open_outlined, size: 14),
                            label: const Text('Unlock', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade700,
                              side: BorderSide(color: Colors.orange.shade300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
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

  // ── Action buttons ─────────────────────────────────────────────────────────

  Widget _buildActionButtons(ColorScheme cs, bool isDark, int pendingCount) {
    final selectedCount = _selectedRows.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            onPressed: (selectedCount == 0 || _processing) ? null : _processSelected,
            icon: const Icon(Icons.checklist_outlined, size: 16),
            label: Text(
              selectedCount > 0
                  ? 'Process Selected Only ($selectedCount)'
                  : 'Process Selected Only',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B2235),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF1B2235).withValues(alpha: 0.3),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: (_processing || _loading || pendingCount == 0) ? null : _processAllPending,
            icon: _processing
                ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_circle_outlined, size: 17),
            label: Text(
              pendingCount > 0 ? 'Process All ($pendingCount)' : 'Process All',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B2235),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF1B2235).withValues(alpha: 0.3),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Grand total ────────────────────────────────────────────────────────────

  Widget _buildGrandTotal(ColorScheme cs, bool isDark, double totalNet, double totalDeduct) {
    final totalBase = _rows.fold(0.0, (s, r) => s + r.baseSalary);
    final totalAllow = _rows.fold(0.0, (s, r) => s + r.totalAllowances);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF0F4F8),
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 36),
          const Expanded(flex: 9, child: SizedBox()),
          Expanded(
            flex: 15,
            child: Text('Grand Totals',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
          ),
          Expanded(flex: 10, child: Text(_currency.format(totalBase),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface), textAlign: TextAlign.right)),
          Expanded(flex: 10, child: Text(_currency.format(totalAllow),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF27AE60)), textAlign: TextAlign.right)),
          Expanded(flex: 10, child: Text(_currency.format(totalDeduct),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE53E3E)), textAlign: TextAlign.right)),
          Expanded(flex: 13, child: Text(_currency.format(totalNet),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.primary), textAlign: TextAlign.right)),
          Expanded(flex: 8, child: Center(
            child: Icon(Icons.verified_outlined, size: 18, color: cs.primary.withValues(alpha: 0.7)),
          )),
        ],
      ),
    );
  }

  // ── Audit log ──────────────────────────────────────────────────────────────

  Widget _buildAuditLog(ColorScheme cs, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Audit Log Readiness',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                'All employee data for ${_monthNames[_month - 1]} $_year has been validated.\n'
                'You can proceed with payroll processing to generate bank transfer sheets.',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.55), height: 1.45),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _showAllowancesDialog,
            icon: const Icon(Icons.list_alt_outlined, size: 14),
            label: const Text('Review Allowances', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(color: cs.outlineVariant),
              foregroundColor: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _showDeductionsAuditDialog,
            icon: const Icon(Icons.fact_check_outlined, size: 14),
            label: const Text('View Deductions Audit', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(color: cs.outlineVariant),
              foregroundColor: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showAllowancesDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final fmt = _currency;
        final labelStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
          color: cs.onSurface.withValues(alpha: 0.5));

        final items = <(String, String, String, double)>[];
        double grandTotal = 0;
        for (final row in _rows) {
          for (final c in row.components) {
            if (!c.isActive || c.componentType != 'allowance') continue;
            final amt = SalaryCalculator.calculateComponent(c, row.baseSalary);
            items.add((row.employee.fullName, row.employee.employeeId, c.name, amt));
            grandTotal += amt;
          }
        }

        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                  child: Row(children: [
                    Icon(Icons.list_alt_outlined, size: 20, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Allowances Review — ${_monthNames[_month - 1]} $_year',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                    IconButton(onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 18), visualDensity: VisualDensity.compact),
                  ]),
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(children: [
                    Expanded(flex: 5, child: Text('EMPLOYEE', style: labelStyle)),
                    Expanded(flex: 5, child: Text('ALLOWANCE', style: labelStyle)),
                    Expanded(flex: 3, child: Text('AMOUNT', style: labelStyle, textAlign: TextAlign.right)),
                  ]),
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.25)),
                Expanded(
                  child: items.isEmpty
                      ? Center(child: Text('No allowances configured.',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
                          itemBuilder: (_, i) {
                            final (empName, empId, compName, amt) = items[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Row(children: [
                                Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(empName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  Text(empId, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
                                ])),
                                Expanded(flex: 5, child: Text(compName, style: const TextStyle(fontSize: 12))),
                                Expanded(flex: 3, child: Text(fmt.format(amt),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF27AE60)),
                                  textAlign: TextAlign.right)),
                              ]),
                            );
                          },
                        ),
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(children: [
                    const Text('Grand Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(fmt.format(grandTotal),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF27AE60))),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeductionsAuditDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final fmt = _currency;
        final labelStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
          color: cs.onSurface.withValues(alpha: 0.5));

        final items = <(String, String, String, double)>[];
        double grandTotal = 0;
        for (final row in _rows) {
          for (final c in row.components) {
            if (!c.isActive || c.componentType != 'deduction') continue;
            final amt = SalaryCalculator.calculateComponent(c, row.baseSalary);
            items.add((row.employee.fullName, row.employee.employeeId, c.name, amt));
            grandTotal += amt;
          }
        }

        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                  child: Row(children: [
                    Icon(Icons.fact_check_outlined, size: 20, color: cs.error),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Deductions Audit — ${_monthNames[_month - 1]} $_year',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                    IconButton(onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 18), visualDensity: VisualDensity.compact),
                  ]),
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(children: [
                    Expanded(flex: 5, child: Text('EMPLOYEE', style: labelStyle)),
                    Expanded(flex: 5, child: Text('DEDUCTION', style: labelStyle)),
                    Expanded(flex: 3, child: Text('AMOUNT', style: labelStyle, textAlign: TextAlign.right)),
                  ]),
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.25)),
                Expanded(
                  child: items.isEmpty
                      ? Center(child: Text('No deductions configured.',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
                          itemBuilder: (_, i) {
                            final (empName, empId, compName, amt) = items[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Row(children: [
                                Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(empName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  Text(empId, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
                                ])),
                                Expanded(flex: 5, child: Text(compName, style: const TextStyle(fontSize: 12))),
                                Expanded(flex: 3, child: Text(fmt.format(amt),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.error),
                                  textAlign: TextAlign.right)),
                              ]),
                            );
                          },
                        ),
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(children: [
                    const Text('Grand Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(fmt.format(grandTotal),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.error)),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _adminChip(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF1565C0),
            child: const Text('AD', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 7),
          Text('Admin User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _MonthDropdown extends StatelessWidget {
  final int month;
  final ValueChanged<int> onChanged;
  final List<String> monthNames;
  final ColorScheme cs;
  const _MonthDropdown({required this.month, required this.onChanged, required this.monthNames, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: month,
        underline: const SizedBox.shrink(),
        isDense: true,
        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
        items: List.generate(12, (i) => i + 1).map((m) =>
          DropdownMenuItem(value: m, child: Text(monthNames[m - 1])),
        ).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}

class _YearDropdown extends StatelessWidget {
  final int year;
  final ValueChanged<int> onChanged;
  final ColorScheme cs;
  const _YearDropdown({required this.year, required this.onChanged, required this.cs});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: year,
        underline: const SizedBox.shrink(),
        isDense: true,
        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
        items: List.generate(6, (i) => currentYear - 2 + i).map((y) =>
          DropdownMenuItem(value: y, child: Text('$y')),
        ).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;
  final ColorScheme cs;

  const _StatChip({required this.icon, required this.iconColor, required this.label,
    required this.value, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 1),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
