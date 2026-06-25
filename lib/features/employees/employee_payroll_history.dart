import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/database.dart';
import '../../core/utils/payroll_snapshot.dart';
import '../backup/excel_export_service.dart';
import '../printing/print_service.dart';

// ── Data ──────────────────────────────────────────────────────────────────────

class _MonthEntry {
  final int month;
  final int year;
  final PayrollRecord? record;

  const _MonthEntry({required this.month, required this.year, this.record});

  bool get hasRecord => record != null;
  bool get isLocked => record?.isLocked ?? false;
}

// ── Widget ────────────────────────────────────────────────────────────────────

class EmployeePayrollHistoryTab extends StatefulWidget {
  final Employee employee;
  final String category;

  const EmployeePayrollHistoryTab({
    required this.employee,
    required this.category,
    super.key,
  });

  @override
  State<EmployeePayrollHistoryTab> createState() => _EmployeePayrollHistoryTabState();
}

class _EmployeePayrollHistoryTabState extends State<EmployeePayrollHistoryTab> {
  final _db = AppDatabase.instance;

  List<_MonthEntry> _entries = [];
  bool _loading = true;
  final Set<String> _expanded = {}; // keys: "year-month"

  final _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final records = await _db.payrollRecordsDao.getRecordsByEmployee(widget.employee.id);
      final recordMap = {for (final r in records) '${r.year}-${r.month}': r};
      _entries = _buildEntries(recordMap);
    } catch (_) {
      _entries = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_MonthEntry> _buildEntries(Map<String, PayrollRecord> recordMap) {
    final now = DateTime.now();
    DateTime? joining;
    try {
      joining = DateTime.parse(widget.employee.joiningDate);
    } catch (_) {}

    // Earliest month to show: joining month (or 2 years ago if no joining date)
    final earliest = joining != null
        ? DateTime(joining.year, joining.month)
        : DateTime(now.year - 2, now.month);

    final entries = <_MonthEntry>[];
    var cursor = DateTime(now.year, now.month);

    while (!cursor.isBefore(earliest)) {
      final key = '${cursor.year}-${cursor.month}';
      entries.add(_MonthEntry(month: cursor.month, year: cursor.year, record: recordMap[key]));
      // Move back one month
      cursor = cursor.month == 1
          ? DateTime(cursor.year - 1, 12)
          : DateTime(cursor.year, cursor.month - 1);
    }

    return entries;
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> get _stats {
    final processed = _entries.where((e) => e.isLocked).toList();
    if (processed.isEmpty) return {'count': 0, 'avg': 0.0, 'last': null};
    final avg = processed.fold(0.0, (s, e) => s + (e.record?.netSalary ?? 0)) / processed.length;
    final last = processed.first; // already sorted most-recent first
    String? lastDate;
    try {
      if (last.record?.processedAt != null) {
        lastDate = DateFormat('d MMM yyyy').format(DateTime.parse(last.record!.processedAt));
      }
    } catch (_) {}
    return {'count': processed.length, 'avg': avg, 'last': lastDate};
  }

  // ── Unlock ─────────────────────────────────────────────────────────────────

  Future<void> _unlock(_MonthEntry entry) async {
    if (entry.record == null) return;
    final monthLabel = '${_monthNames[entry.month - 1]} ${entry.year}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlock Payroll'),
        content: Text(
          'Unlock ${widget.employee.fullName}\'s $monthLabel payroll?\n\n'
          'This allows reprocessing from the Payroll screen.',
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
    await _db.payrollRecordsDao.unlockRecord(entry.record!.id);
    await _loadData();
  }

  // ── Print ──────────────────────────────────────────────────────────────────

  Future<void> _print(_MonthEntry entry) async {
    if (entry.record == null) return;
    final cs = Theme.of(context).colorScheme;
    try {
      Uint8List bytes;
      if (widget.category == 'pedo') {
        bytes = await PrintService.generatePedoPayBill(
          employee: widget.employee,
          record: entry.record!,
          month: entry.month,
          year: entry.year,
          vNo: '',
        );
      } else {
        bytes = await PrintService.generateStandardPayslip(
          employee: widget.employee,
          record: entry.record!,
          month: entry.month,
          year: entry.year,
          category: widget.category,
        );
      }
      final dir = await getTemporaryDirectory();
      final fileName = '${widget.category}_${widget.employee.employeeId}'
          '_${_monthNames[entry.month - 1]}_${entry.year}.pdf';
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await Process.run('cmd', ['/c', 'start', '', file.path]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print error: $e'), backgroundColor: cs.error),
        );
      }
    }
  }

  // ── Excel export ───────────────────────────────────────────────────────────

  Future<void> _exportExcel(_MonthEntry entry) async {
    if (entry.record == null) return;
    try {
      final path = await ExcelExportService.exportMonthlySingleEmployee(
          widget.employee, entry.month, entry.year);
      if (path != null && mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
              SizedBox(width: 10),
              Text('Export Successful'),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('File saved to:'),
                const SizedBox(height: 6),
                Text(path,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Process.run(
                    'explorer.exe', ['/select,', path]),
                child: const Text('Show in Folder'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) return const Center(child: CircularProgressIndicator());

    final stats = _stats;
    final processedCount = stats['count'] as int;
    final avgNet = stats['avg'] as double;
    final lastDate = stats['last'] as String?;

    return Column(
      children: [
        // ── Stats bar ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: isDark ? const Color(0xFF2A2A3E) : cs.surface,
          child: Row(
            children: [
              _StatPill(
                icon: Icons.receipt_long_outlined,
                label: 'Months Processed',
                value: '$processedCount',
                color: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 12),
              _StatPill(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Avg Net Salary',
                value: processedCount > 0 ? _currency.format(avgNet) : '—',
                color: const Color(0xFF27AE60),
              ),
              const SizedBox(width: 12),
              _StatPill(
                icon: Icons.event_available_outlined,
                label: 'Last Processed',
                value: lastDate ?? '—',
                color: const Color(0xFFED8936),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),

        // ── Month list ───────────────────────────────────────────────────────
        Expanded(
          child: _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Text('No payroll history available.',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.45))),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  itemCount: _entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildMonthCard(_entries[i], cs, isDark),
                ),
        ),
      ],
    );
  }

  Widget _buildMonthCard(_MonthEntry entry, ColorScheme cs, bool isDark) {
    final monthLabel = '${_monthNames[entry.month - 1]} ${entry.year}';
    final key = '${entry.year}-${entry.month}';
    final isExpanded = _expanded.contains(key);

    if (!entry.hasRecord) {
      // Not-processed placeholder
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3E).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.radio_button_unchecked_outlined, size: 16,
              color: cs.onSurface.withValues(alpha: 0.25)),
            const SizedBox(width: 12),
            Text(monthLabel,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.35))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Not Processed',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.35))),
            ),
          ],
        ),
      );
    }

    final r = entry.record!;
    final statusColor = entry.isLocked ? const Color(0xFF27AE60) : const Color(0xFFED8936);
    final statusLabel = entry.isLocked ? 'Locked' : 'Unlocked';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // ── Summary row ──────────────────────────────────────────────────
          InkWell(
            onTap: entry.isLocked ? () => setState(() {
              if (isExpanded) { _expanded.remove(key); } else { _expanded.add(key); }
            }) : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Month + year
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(monthLabel,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '+${_currency.format(r.totalAllowances)}  −${_currency.format(r.totalDeductions)}',
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Net salary
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_currency.format(r.netSalary),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary)),
                      Text('Basic: ${_currency.format(r.baseSalary)}',
                        style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
                          size: 11, color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Action icons
                  if (entry.isLocked) ...[
                    _ActionIcon(
                      icon: Icons.print_outlined,
                      tooltip: 'Print Payslip',
                      onTap: () => _print(entry),
                    ),
                    _ActionIcon(
                      icon: Icons.file_download_outlined,
                      tooltip: 'Export to Excel',
                      onTap: () => _exportExcel(entry),
                    ),
                    _ActionIcon(
                      icon: Icons.lock_open_outlined,
                      tooltip: 'Unlock for Reprocessing',
                      color: const Color(0xFFED8936),
                      onTap: () => _unlock(entry),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ] else ...[
                    _ActionIcon(
                      icon: Icons.lock_outline,
                      tooltip: 'Process in Payroll screen to lock',
                      color: cs.onSurface.withValues(alpha: 0.3),
                      onTap: null,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Expanded breakdown ───────────────────────────────────────────
          if (isExpanded && entry.isLocked) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
            _buildBreakdown(r, cs, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdown(PayrollRecord r, ColorScheme cs, bool isDark) {
    final components = PayrollComponent.parseSnapshot(r.salarySnapshot);
    final allowances = components.where((c) => c.type == 'allowance').toList();
    final deductions = components.where((c) => c.type == 'deduction').toList();

    Widget row(String label, double amount, {Color? color, bool bold = false}) {
      final style = TextStyle(
        fontSize: 12,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: color ?? cs.onSurface.withValues(alpha: bold ? 0.9 : 0.75),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text(_currency.format(amount), style: style.copyWith(color: color)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Basic
          row('Basic Salary', r.baseSalary),
          if (allowances.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Allowances', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: const Color(0xFF27AE60).withValues(alpha: 0.8), letterSpacing: 0.5)),
            const SizedBox(height: 4),
            ...allowances.map((c) => row(c.name, c.amount, color: const Color(0xFF27AE60))),
          ],
          if (deductions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Deductions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: cs.error.withValues(alpha: 0.8), letterSpacing: 0.5)),
            const SizedBox(height: 4),
            ...deductions.map((c) => row(c.name, c.amount, color: cs.error)),
          ],
          Divider(height: 20, color: cs.outlineVariant.withValues(alpha: 0.4)),
          row('Total Allowances', r.totalAllowances, color: const Color(0xFF27AE60), bold: true),
          row('Total Deductions', r.totalDeductions, color: cs.error, bold: true),
          row('Net Salary', r.netSalary, color: cs.primary, bold: true),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500)),
                  const SizedBox(height: 1),
                  Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                    overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionIcon({required this.icon, required this.tooltip, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16,
            color: onTap == null
                ? cs.onSurface.withValues(alpha: 0.25)
                : (color ?? cs.onSurface.withValues(alpha: 0.55))),
        ),
      ),
    );
  }
}
