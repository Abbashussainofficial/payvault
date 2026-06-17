import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../core/database/database.dart';
import 'print_service.dart';

class PrintScreen extends StatefulWidget {
  final String category;
  const PrintScreen({required this.category, super.key});

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  final _db = AppDatabase.instance;

  static const _catLabels = {
    'pedo': 'PEDO Employees',
    'security': 'Security Guards',
    'alfajar': 'Al Fajar',
  };

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  // State
  late int _month;
  late int _year;
  List<Employee> _employees = [];
  Map<int, PayrollRecord> _recordMap = {};
  Employee? _selectedEmployee;
  final _vNoCtrl = TextEditingController();

  bool _loadingEmployees = true;
  bool _generatingPdf = false;
  bool _bulkPrinting = false;
  Uint8List? _previewBytes;

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

  @override
  void dispose() {
    _vNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loadingEmployees = true; _previewBytes = null; });
    try {
      final emps = await _db.employeesDao
          .getEmployeesByCategory(widget.category);
      final records = await _db.payrollRecordsDao
          .getRecordsByMonthYear(_month, _year);
      final rMap = {for (final r in records) r.employeeId: r};

      // Keep selected employee valid
      final stillValid = _selectedEmployee != null &&
          emps.any((e) => e.id == _selectedEmployee!.id);

      setState(() {
        _employees = emps;
        _recordMap = rMap;
        if (!stillValid) _selectedEmployee = null;
        _loadingEmployees = false;
      });
    } catch (_) {
      setState(() => _loadingEmployees = false);
    }
  }

  void _shiftMonth(int delta) {
    var m = _month + delta;
    var y = _year;
    if (m > 12) { m = 1; y++; }
    if (m < 1)  { m = 12; y--; }
    setState(() {
      _month = m;
      _year = y;
      _previewBytes = null;
    });
    _loadData();
  }

  List<Employee> get _processedEmployees =>
      _employees.where((e) => _recordMap.containsKey(e.id)).toList();

  Future<void> _generatePreview() async {
    final emp = _selectedEmployee;
    if (emp == null) return;
    final record = _recordMap[emp.id];
    if (record == null) {
      _showSnack('No payroll record for this employee in the selected month.',
          isError: true);
      return;
    }
    setState(() { _generatingPdf = true; _previewBytes = null; });
    try {
      final bytes = widget.category == 'pedo'
          ? await PrintService.generatePedoPayBill(
              employee: emp,
              record: record,
              month: _month,
              year: _year,
              vNo: _vNoCtrl.text.trim(),
            )
          : await PrintService.generateStandardPayslip(
              employee: emp,
              record: record,
              month: _month,
              year: _year,
              category: widget.category,
            );
      setState(() => _previewBytes = bytes);
    } catch (e) {
      _showSnack('PDF error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _printSingle() async {
    final bytes = _previewBytes;
    if (bytes == null) return;
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _bulkPrint() async {
    final processed = _processedEmployees;
    if (processed.isEmpty) {
      _showSnack('No processed records for ${_monthNames[_month - 1]} $_year.',
          isError: true);
      return;
    }
    setState(() => _bulkPrinting = true);
    try {
      final items = processed
          .map((e) => (employee: e, record: _recordMap[e.id]!))
          .toList();
      final bytes = await PrintService.generateBulk(
        items: items,
        month: _month,
        year: _year,
        category: widget.category,
      );
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      _showSnack('Bulk print error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _bulkPrinting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : null,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(cs),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left control panel
                SizedBox(
                  width: 320,
                  child: _buildControlPanel(cs),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: cs.outlineVariant,
                ),
                // Right preview panel
                Expanded(child: _buildPreviewPanel(cs)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Print & Reports',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _catLabels[widget.category] ?? widget.category,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(width: 28),
          IconButton(
            onPressed: () => _shiftMonth(-1),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
          ),
          SizedBox(
            width: 150,
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
        ],
      ),
    );
  }

  // ── Control panel ─────────────────────────────────────────────────────────

  Widget _buildControlPanel(ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final processed = _processedEmployees;

    return Container(
      color: isDark ? cs.surfaceContainerLowest : cs.surfaceContainerLowest,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Single employee section ────────────────────────────────────────
          Text(
            'SINGLE EMPLOYEE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),

          // Employee dropdown
          if (_loadingEmployees)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Select Employee',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: DropdownButton<Employee>(
                value: _selectedEmployee,
                isExpanded: true,
                isDense: true,
                underline: const SizedBox.shrink(),
                hint: Text(
                  'Choose employee',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                items: _employees.map((e) {
                  final hasRecord = _recordMap.containsKey(e.id);
                  return DropdownMenuItem(
                    value: e,
                    child: Row(children: [
                      Icon(
                        hasRecord
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        size: 14,
                        color: hasRecord
                            ? Colors.green.shade600
                            : cs.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${e.employeeId} — ${e.fullName}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasRecord
                                ? null
                                : cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ]),
                  );
                }).toList(),
                onChanged: (e) => setState(() {
                  _selectedEmployee = e;
                  _previewBytes = null;
                }),
              ),
            ),

          const SizedBox(height: 10),

          // V.No field (PEDO only)
          if (widget.category == 'pedo') ...[
            TextField(
              controller: _vNoCtrl,
              decoration: const InputDecoration(
                labelText: 'V.No (optional)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Selected employee payroll info
          if (_selectedEmployee != null) ...[
            Builder(builder: (context) {
              final rec = _recordMap[_selectedEmployee!.id];
              if (rec == null) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(children: [
                    Icon(Icons.warning_amber_outlined,
                        size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'No payroll record for this month.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ]),
                );
              }
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _infoRow('Base', _currency.format(rec.baseSalary), cs),
                    _infoRow('Allowances',
                        '+${_currency.format(rec.totalAllowances)}', cs,
                        valueColor: Colors.green.shade700),
                    _infoRow('Deductions',
                        '−${_currency.format(rec.totalDeductions)}', cs,
                        valueColor: Colors.red.shade600),
                    const Divider(height: 12),
                    _infoRow('Net', _currency.format(rec.netSalary), cs,
                        bold: true, valueColor: cs.primary),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // Preview + Print buttons
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedEmployee == null || _generatingPdf
                    ? null
                    : _generatePreview,
                icon: _generatingPdf
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.preview_outlined, size: 16),
                label: const Text('Preview'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _previewBytes == null ? null : _printSingle,
                icon: const Icon(Icons.print_outlined, size: 16),
                label: const Text('Print'),
              ),
            ),
          ]),

          const SizedBox(height: 24),
          Divider(color: cs.outlineVariant),
          const SizedBox(height: 16),

          // ── Bulk print section ────────────────────────────────────────────
          Text(
            'BULK PRINT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthNames[_month - 1]} $_year',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${processed.length} of ${_employees.length} employees processed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (processed.isEmpty || _bulkPrinting)
                  ? null
                  : _bulkPrint,
              icon: _bulkPrinting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.print_outlined, size: 16),
              label: Text(
                'Bulk Print All  (${processed.length})',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    ColorScheme cs, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ]),
    );
  }

  // ── Preview panel ─────────────────────────────────────────────────────────

  Widget _buildPreviewPanel(ColorScheme cs) {
    if (_previewBytes != null) {
      return PdfPreview(
        key: ValueKey(_previewBytes.hashCode),
        build: (format) async => _previewBytes!,
        allowPrinting: true,
        allowSharing: false,
        canChangePageFormat: false,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName:
            '${widget.category}_payslip_${_monthNames[_month - 1]}_$_year.pdf',
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 64,
            color: cs.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'PDF Preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select an employee with a payroll record,\nthen tap Preview.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
