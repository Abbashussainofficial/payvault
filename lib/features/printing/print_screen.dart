import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/database.dart';
import '../backup/excel_export_service.dart';
import 'pedo_payslip_preview.dart';
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

  late int _month;
  late int _year;
  List<Employee> _employees = [];
  Map<int, PayrollRecord> _recordMap = {};
  Employee? _selectedEmployee;
  final _vNoCtrl = TextEditingController();
  bool _bulkMode = false;

  bool _loadingEmployees = true;
  bool _generating = false;
  bool _bulkGenerating = false;
  bool _exportingExcel = false;
  String? _lastPdfPath;
  String? _lastPdfLabel;

  final _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _loadData();
    _vNoCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _vNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loadingEmployees = true; _lastPdfPath = null; _lastPdfLabel = null; });
    try {
      final emps = await _db.employeesDao.getEmployeesByCategory(widget.category);
      final records = await _db.payrollRecordsDao.getRecordsByMonthYear(_month, _year);
      final rMap = {for (final r in records) r.employeeId: r};
      final stillValid = _selectedEmployee != null && emps.any((e) => e.id == _selectedEmployee!.id);
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

  List<Employee> get _processedEmployees =>
      _employees.where((e) => _recordMap.containsKey(e.id)).toList();

  Future<void> _openPdfFile(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Process.run('cmd', ['/c', 'start', '', file.path]);
    if (mounted) setState(() { _lastPdfPath = file.path; _lastPdfLabel = fileName; });
  }

  Future<void> _generateAndOpen() async {
    final emp = _selectedEmployee;
    if (emp == null) return;
    final record = _recordMap[emp.id];
    if (record == null) {
      await _showNotProcessedDialog(emp.fullName);
      return;
    }
    setState(() => _generating = true);
    try {
      final bytes = widget.category == 'pedo'
          ? await PrintService.generatePedoPayBill(employee: emp, record: record, month: _month, year: _year, vNo: _vNoCtrl.text.trim())
          : await PrintService.generateStandardPayslip(employee: emp, record: record, month: _month, year: _year, category: widget.category);
      final fileName = '${widget.category}_${emp.employeeId}_${_monthNames[_month - 1]}_$_year.pdf';
      await _openPdfFile(bytes, fileName);
    } catch (e) {
      _showSnack('PDF error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _showNotProcessedDialog(String empName) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.hourglass_empty_outlined, size: 32, color: Color(0xFFED8936)),
        title: const Text('Not Processed Yet'),
        content: Text(
          '$empName\'s payroll for ${_monthNames[_month - 1]} $_year hasn\'t been processed.\n\n'
          'Go to the Payroll screen to process and lock this month\'s payroll first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkOpen() async {
    final processed = _processedEmployees;
    if (processed.isEmpty) {
      await _showBulkNotProcessedDialog();
      return;
    }
    setState(() => _bulkGenerating = true);
    try {
      final items = processed.map((e) => (employee: e, record: _recordMap[e.id]!)).toList();
      final bytes = await PrintService.generateBulk(items: items, month: _month, year: _year, category: widget.category);
      final fileName = '${widget.category}_bulk_${_monthNames[_month - 1]}_$_year.pdf';
      await _openPdfFile(bytes, fileName);
    } catch (e) {
      _showSnack('Bulk PDF error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _bulkGenerating = false);
    }
  }

  Future<void> _showBulkNotProcessedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.hourglass_empty_outlined, size: 32, color: Color(0xFFED8936)),
        title: const Text('No Processed Records'),
        content: Text(
          'No employees have been processed for ${_monthNames[_month - 1]} $_year.\n\n'
          'Go to the Payroll screen to process and lock payroll first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _reopenLast() async {
    final path = _lastPdfPath;
    if (path == null) return;
    await Process.run('cmd', ['/c', 'start', '', path]);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : null,
    ));
  }

  void _showExcelSuccess(String path) {
    if (!mounted) return;
    final fileName = path.split(Platform.pathSeparator).last;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Saved: $fileName'),
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: 'Show in Folder',
        onPressed: () => Process.run('explorer.exe', ['/select,', path]),
      ),
    ));
  }

  Future<void> _exportEmployee() async {
    final emp = _selectedEmployee;
    if (emp == null) return;
    setState(() => _exportingExcel = true);
    try {
      final path = await ExcelExportService.exportSingleEmployee(emp);
      if (path != null) _showExcelSuccess(path);
    } catch (e) {
      _showSnack('Excel export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  Future<void> _exportMonthlyEmployee() async {
    final emp = _selectedEmployee;
    if (emp == null) return;
    final record = _recordMap[emp.id];
    if (record == null) {
      await _showNotProcessedDialog(emp.fullName);
      return;
    }
    setState(() => _exportingExcel = true);
    try {
      final path = await ExcelExportService.exportMonthlySingleEmployee(emp, _month, _year);
      if (path != null) _showExcelSuccess(path);
    } catch (e) {
      _showSnack('Excel export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  Future<void> _exportAllEmployees() async {
    setState(() => _exportingExcel = true);
    try {
      final path = await ExcelExportService.exportAllEmployees(widget.category);
      if (path != null) _showExcelSuccess(path);
    } catch (e) {
      _showSnack('Excel export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  Future<void> _exportMonthlyAll() async {
    setState(() => _exportingExcel = true);
    try {
      final path = await ExcelExportService.exportMonthlyAllEmployees(
          widget.category, _month, _year);
      if (path != null) _showExcelSuccess(path);
    } catch (e) {
      _showSnack('Excel export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catLabel = _catLabels[widget.category] ?? widget.category;
    final processed = _processedEmployees;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text('Print Management',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text('·', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 18)),
                const SizedBox(width: 8),
                Text(catLabel, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55))),
                const Spacer(),
                Icon(Icons.calendar_today_outlined, size: 17, color: cs.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 12),
                Icon(Icons.access_time_outlined, size: 17, color: cs.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 14),
                _adminChip(cs),
              ],
            ),
          ),

          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left panel
                SizedBox(
                  width: 340,
                  child: Container(
                    color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tabs
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: _TabBtn(label: 'Single Slip', selected: !_bulkMode,
                                onTap: () => setState(() { _bulkMode = false; }), cs: cs)),
                              Expanded(child: _TabBtn(label: 'Bulk Print', selected: _bulkMode,
                                onTap: () => setState(() { _bulkMode = true; }), cs: cs)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (!_bulkMode) ...[
                          // ── Single slip controls ───────────────────────
                          Text('Select Employee', style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 6),
                          if (_loadingEmployees)
                            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                          else
                            InputDecorator(
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: DropdownButton<Employee>(
                                value: _selectedEmployee,
                                isExpanded: true,
                                isDense: true,
                                underline: const SizedBox.shrink(),
                                hint: Text('Search Employee ID or Name...',
                                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.45))),
                                items: _employees.map((e) {
                                  final hasRecord = _recordMap.containsKey(e.id);
                                  return DropdownMenuItem(
                                    value: e,
                                    child: Row(children: [
                                      Icon(
                                        hasRecord ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                                        size: 14,
                                        color: hasRecord ? Colors.green.shade600 : cs.onSurface.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text('${e.employeeId} — ${e.fullName}',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13, color: hasRecord ? null : cs.onSurface.withValues(alpha: 0.45)))),
                                    ]),
                                  );
                                }).toList(),
                                onChanged: (e) => setState(() => _selectedEmployee = e),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Month/Year row
                          Row(
                            children: [
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Month/Year', style: Theme.of(context).textTheme.labelMedium),
                                  const SizedBox(height: 6),
                                  InputDecorator(
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: DropdownButton<int>(
                                      value: _month,
                                      isExpanded: true,
                                      isDense: true,
                                      underline: const SizedBox.shrink(),
                                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                                      items: List.generate(12, (i) => i + 1).map((m) =>
                                        DropdownMenuItem(value: m, child: Text(_monthNames[m - 1]))).toList(),
                                      onChanged: (v) { if (v != null) { setState(() => _month = v); _loadData(); } },
                                    ),
                                  ),
                                ],
                              )),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Year', style: Theme.of(context).textTheme.labelMedium),
                                  const SizedBox(height: 6),
                                  InputDecorator(
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: DropdownButton<int>(
                                      value: _year,
                                      isExpanded: true,
                                      isDense: true,
                                      underline: const SizedBox.shrink(),
                                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                                      items: List.generate(6, (i) => DateTime.now().year - 2 + i).map((y) =>
                                        DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                                      onChanged: (v) { if (v != null) { setState(() => _year = v); _loadData(); } },
                                    ),
                                  ),
                                ],
                              )),
                            ],
                          ),

                          if (widget.category == 'pedo') ...[
                            const SizedBox(height: 12),
                            Text('V.No (optional)', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _vNoCtrl,
                              decoration: const InputDecoration(isDense: true, hintText: 'Voucher number'),
                            ),
                          ],

                          if (_selectedEmployee != null) ...[
                            const SizedBox(height: 12),
                            Builder(builder: (context) {
                              final rec = _recordMap[_selectedEmployee!.id];
                              if (rec == null) {
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(children: [
                                    Icon(Icons.warning_amber_outlined, size: 14, color: Colors.orange.shade700),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text('No payroll record for this month.',
                                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700))),
                                  ]),
                                );
                              }
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(children: [
                                  _infoRow('Base', _currency.format(rec.baseSalary), cs),
                                  _infoRow('Allowances', '+${_currency.format(rec.totalAllowances)}', cs, color: Colors.green.shade700),
                                  _infoRow('Deductions', '−${_currency.format(rec.totalDeductions)}', cs, color: Colors.red.shade600),
                                  const Divider(height: 12),
                                  _infoRow('Net', _currency.format(rec.netSalary), cs, bold: true, color: cs.primary),
                                ]),
                              );
                            }),
                          ],

                          const Spacer(),

                          // Print to PDF button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: (_selectedEmployee == null || _generating || _bulkGenerating)
                                  ? null : _generateAndOpen,
                              icon: _generating
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                              label: Text(_generating ? 'Generating…' : 'Print to PDF',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1B2235),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Export to Excel dropdown (single mode)
                          _ExcelMenuButton(
                            loading: _exportingExcel,
                            disabled: _generating || _bulkGenerating || _exportingExcel,
                            items: [
                              _ExcelMenuItem(
                                icon: Icons.person_outline,
                                label: 'Export Profile + History',
                                enabled: _selectedEmployee != null,
                                onTap: _exportEmployee,
                              ),
                              _ExcelMenuItem(
                                icon: Icons.calendar_month_outlined,
                                label: 'Export This Month\'s Payslip',
                                enabled: _selectedEmployee != null &&
                                    _recordMap.containsKey(_selectedEmployee?.id),
                                onTap: _exportMonthlyEmployee,
                              ),
                            ],
                          ),
                        ] else ...[
                          // ── Bulk print controls ────────────────────────
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_monthNames[_month - 1]} $_year',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('${processed.length} of ${_employees.length} employees processed',
                                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: (processed.isEmpty || _bulkGenerating || _generating)
                                  ? null : _bulkOpen,
                              icon: _bulkGenerating
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                              label: Text(_bulkGenerating ? 'Generating…' : 'Print to PDF  (${processed.length})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1B2235),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Export to Excel dropdown (bulk mode)
                          _ExcelMenuButton(
                            loading: _exportingExcel,
                            disabled: _generating || _bulkGenerating || _exportingExcel,
                            items: [
                              _ExcelMenuItem(
                                icon: Icons.people_outline,
                                label: 'Export All Employees List',
                                enabled: _employees.isNotEmpty,
                                onTap: _exportAllEmployees,
                              ),
                              _ExcelMenuItem(
                                icon: Icons.table_rows_outlined,
                                label: 'Export This Month\'s Payroll',
                                enabled: processed.isNotEmpty,
                                onTap: _exportMonthlyAll,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),

                // Right: status / preview
                Expanded(child: _buildStatusPanel(cs, isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPanel(ColorScheme cs, bool isDark) {
    // Show PDF-opened success banner above the preview
    if (_lastPdfPath != null) {
      return Column(
        children: [
          // Success bar
          Container(
            color: const Color(0xFF27AE60).withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF27AE60)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PDF saved: ${_lastPdfLabel ?? ""}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF27AE60), fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _reopenLast,
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Reopen', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
          // Preview below the banner
          Expanded(child: _previewOrPlaceholder(cs, isDark)),
        ],
      );
    }

    return _previewOrPlaceholder(cs, isDark);
  }

  Widget _previewOrPlaceholder(ColorScheme cs, bool isDark) {
    // Live PEDO payslip preview when employee + record are available
    if (!_bulkMode && widget.category == 'pedo' && _selectedEmployee != null) {
      final rec = _recordMap[_selectedEmployee!.id];
      if (rec != null) {
        return PedoPayslipPreview.fromRecord(
          employee: _selectedEmployee!,
          record: rec,
          month: _month,
          year: _year,
          vNo: _vNoCtrl.text.trim(),
        );
      }
    }

    // No preview available — show placeholder
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF0F4F8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.picture_as_pdf_outlined, size: 48, color: cs.primary.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 20),
          Text(
            'Live Preview',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 6),
          Text(
            widget.category == 'pedo'
                ? 'Select a processed employee to see\nthe payslip preview here.'
                : 'Select an employee and month,\nthen tap Print to PDF.',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, ColorScheme cs, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color)),
      ]),
    );
  }

  Widget _adminChip(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: const Color(0xFF1565C0),
            child: const Text('A', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 7),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Admin User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface)),
            Text('Finance Department', style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
          ]),
        ],
      ),
    );
  }
}

// ── Excel export menu ─────────────────────────────────────────────────────────

class _ExcelMenuItem {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _ExcelMenuItem({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });
}

class _ExcelMenuButton extends StatelessWidget {
  final bool loading;
  final bool disabled;
  final List<_ExcelMenuItem> items;

  const _ExcelMenuButton({
    required this.loading,
    required this.disabled,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<int>(
      enabled: !disabled,
      onSelected: (idx) => items[idx].onTap(),
      offset: const Offset(0, -8),
      itemBuilder: (ctx) => items
          .asMap()
          .entries
          .map((e) => PopupMenuItem<int>(
                value: e.key,
                enabled: e.value.enabled,
                child: Row(children: [
                  Icon(e.value.icon, size: 16,
                      color: e.value.enabled
                          ? Theme.of(ctx).colorScheme.onSurface
                          : Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.35)),
                  const SizedBox(width: 8),
                  Text(e.value.label,
                      style: TextStyle(
                          fontSize: 13,
                          color: e.value.enabled
                              ? null
                              : Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.35))),
                ]),
              ))
          .toList(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface.withValues(alpha: 0.6)),
              )
            else
              Icon(Icons.table_chart_outlined, size: 15, color: cs.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              loading ? 'Exporting…' : 'Export to Excel',
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: disabled ? 0.4 : 0.8)),
            ),
            const SizedBox(width: 4),
            if (!loading)
              Icon(Icons.arrow_drop_down, size: 18,
                  color: cs.onSurface.withValues(alpha: disabled ? 0.3 : 0.6)),
          ],
        ),
      ),
    );
  }
}

// ── Tab button ────────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _TabBtn({required this.label, required this.selected, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? (isDark ? const Color(0xFF2A2A3E) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))] : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? cs.onSurface : cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
