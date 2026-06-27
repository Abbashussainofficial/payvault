import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/database/database.dart';
import '../../shared/theme/theme_provider.dart';
import '../backup/excel_export_service.dart';
import 'employee_detail_screen.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  final String category;
  final ValueChanged<Employee>? onViewEmployee;
  const EmployeeListScreen({required this.category, this.onViewEmployee, super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _tabIndex = 0;
  int _page = 0;
  static const _pageSize = 10;
  String? _filterBps;
  String _filterDept = '';
  bool get _hasActiveFilter => _filterBps != null || _filterDept.isNotEmpty;

  // Current-month payroll lock status: employeeId → true if locked
  Set<int> _lockedThisMonth = {};
  StreamSubscription<List<PayrollRecord>>? _payrollSub;

  static const _labels = {
    'pedo': 'PEDO Employees',
    'security': 'Security Guards',
    'alfajar': 'Al Fajar',
  };

  static const _avatarColors = [
    Color(0xFF1565C0), Color(0xFF2E7D32), Color(0xFF6A1B9A),
    Color(0xFFAD1457), Color(0xFF00695C), Color(0xFFE65100),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _page = 0;
    }));
    final now = DateTime.now();
    _payrollSub = AppDatabase.instance.payrollRecordsDao
        .watchRecordsByMonthYear(now.month, now.year)
        .listen(_onPayrollUpdate);
  }

  void _onPayrollUpdate(List<PayrollRecord> records) {
    if (!mounted) return;
    setState(() {
      _lockedThisMonth = records
          .where((r) => r.isLocked)
          .map((r) => r.employeeId)
          .toSet();
    });
  }

  @override
  void dispose() {
    _payrollSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Employee> _applyFilters(List<Employee> all) {
    var list = switch (_tabIndex) {
      1 => all.where((e) => e.status == 'active').toList(),
      2 => all.where((e) => e.status == 'left').toList(),
      _ => [...all],
    };
    if (_searchQuery.isNotEmpty) {
      list = list.where((e) =>
        e.employeeId.toLowerCase().contains(_searchQuery) ||
        e.fullName.toLowerCase().contains(_searchQuery) ||
        (e.cnic?.toLowerCase().contains(_searchQuery) ?? false),
      ).toList();
    }
    if (_filterBps != null) {
      list = list.where((e) => e.bpsGrade == _filterBps).toList();
    }
    if (_filterDept.isNotEmpty) {
      list = list.where((e) =>
        e.designation.toLowerCase().contains(_filterDept.toLowerCase()),
      ).toList();
    }
    return list;
  }

  Future<void> _confirmDelete(Employee emp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee?'),
        content: Text(
          'This will permanently delete ${emp.fullName} and cannot be undone. '
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
    await db.payrollRecordsDao.deleteRecordsByEmployee(emp.id);
    await db.salaryComponentsDao.deleteComponentsByEmployee(emp.id);
    await db.employeesDao.deleteEmployee(emp.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee deleted successfully')),
      );
    }
  }

  void _pushDetail(Employee emp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeDetailScreen(employee: emp, category: widget.category),
      ),
    );
  }

  void _pushEdit(Employee emp) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => EmployeeFormScreen(category: widget.category, employee: emp)),
  );

  void _pushAdd() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => EmployeeFormScreen(category: widget.category)),
  );

  Future<void> _showFilterDialog(BuildContext ctx, List<Employee> all) async {
    final grades = all
        .where((e) => e.bpsGrade != null && e.bpsGrade!.isNotEmpty)
        .map((e) => e.bpsGrade!)
        .toSet()
        .toList()
      ..sort();

    final result = await showDialog<({String? bps, String dept})>(
      context: ctx,
      builder: (_) => _FilterDialog(
        grades: grades,
        initialBps: _filterBps,
        initialDesignation: _filterDept,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _filterBps = result.bps;
        _filterDept = result.dept;
        _page = 0;
      });
    }
  }

  Future<void> _exportCsv(List<Employee> employees) async {
    if (employees.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No employees to export.')),
        );
      }
      return;
    }

    const header = 'Employee ID,Full Name,Designation,Department,BPS Grade,CNIC,Base Salary,Status,Joining Date\n';
    String esc(String? s) => '"${(s ?? '').replaceAll('"', '""')}"';
    final rows = employees.map((e) => [
      esc(e.employeeId),
      esc(e.fullName),
      esc(e.designation),
      esc(e.department),
      esc(e.bpsGrade),
      esc(e.cnic),
      e.baseSalary.toStringAsFixed(0),
      esc(e.status),
      esc(e.joiningDate),
    ].join(',')).join('\n');

    try {
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fname = '${widget.category}_employees_'
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
      final file = File('${dir.path}${Platform.pathSeparator}$fname');
      await file.writeAsString(header + rows);
      await Process.run('cmd', ['/c', 'start', '', file.path]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported: $fname')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    try {
      final path = await ExcelExportService.exportAllEmployees(widget.category);
      if (!mounted) return;
      if (path == null) return; // user cancelled the save dialog
      final fileName = path.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Saved: $fileName'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Show in Folder',
          onPressed: () => Process.run('explorer.exe', ['/select,', path]),
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCategoryPopup(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (_) => _CategoryPopupDialog(category: category),
    );
  }

  Color _avatarColor(String name) =>
      _avatarColors[name.codeUnits.first % _avatarColors.length];

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = context.watch<ThemeProvider>().isCompact;
    final label = _labels[widget.category] ?? widget.category;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F7FA),
      body: StreamBuilder<List<Employee>>(
        stream: AppDatabase.instance.employeesDao.watchEmployeesByCategory(widget.category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? [];
          final filtered = _applyFilters(all);
          final activeCount = all.where((e) => e.status == 'active').length;
          final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 9999);
          final safePage = _page.clamp(0, totalPages - 1);
          final start = safePage * _pageSize;
          final end = (start + _pageSize).clamp(0, filtered.length);
          final pageItems = filtered.sublist(start, end);

          return Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Container(
                color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                padding: const EdgeInsets.fromLTRB(24, 14, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.calendar_today_outlined, size: 17, color: cs.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time_outlined, size: 17, color: cs.onSurface.withValues(alpha: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Category tabs + search + status filters
                    Row(
                      children: [
                        _CatTab(
                          label: 'PEDO Employees',
                          active: widget.category == 'pedo',
                          onTap: widget.category == 'pedo' ? null : () => _showCategoryPopup(context, 'pedo'),
                          cs: cs,
                        ),
                        const SizedBox(width: 6),
                        _CatTab(
                          label: 'Security Guards',
                          active: widget.category == 'security',
                          onTap: widget.category == 'security' ? null : () => _showCategoryPopup(context, 'security'),
                          cs: cs,
                        ),
                        const SizedBox(width: 6),
                        _CatTab(
                          label: 'Al Fajar',
                          active: widget.category == 'alfajar',
                          onTap: widget.category == 'alfajar' ? null : () => _showCategoryPopup(context, 'alfajar'),
                          cs: cs,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search by ID, Name or CNIC...',
                              hintStyle: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                              prefixIcon: Icon(Icons.search, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                                      onPressed: _searchController.clear,
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: cs.outlineVariant)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: cs.outlineVariant)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8FAFC),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _FilterTab(label: 'All', selected: _tabIndex == 0, onTap: () => setState(() { _tabIndex = 0; _page = 0; })),
                        const SizedBox(width: 2),
                        _FilterTab(label: 'Active', selected: _tabIndex == 1, onTap: () => setState(() { _tabIndex = 1; _page = 0; })),
                        const SizedBox(width: 2),
                        _FilterTab(label: 'Left', selected: _tabIndex == 2, onTap: () => setState(() { _tabIndex = 2; _page = 0; })),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Toolbar ─────────────────────────────────────────────────────
              Container(
                color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                padding: const EdgeInsets.fromLTRB(24, 0, 20, 14),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showFilterDialog(context, all),
                      icon: Icon(
                        _hasActiveFilter ? Icons.filter_alt : Icons.filter_list,
                        size: 15,
                        color: _hasActiveFilter ? cs.primary : null,
                      ),
                      label: Text(
                        _hasActiveFilter ? 'Filter •' : 'Filter',
                        style: TextStyle(
                          fontSize: 13,
                          color: _hasActiveFilter ? cs.primary : null,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        side: BorderSide(
                          color: _hasActiveFilter ? cs.primary : cs.outlineVariant,
                        ),
                        foregroundColor: _hasActiveFilter
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _exportCsv(filtered),
                      icon: const Icon(Icons.file_download_outlined, size: 15),
                      label: const Text('Export CSV', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        side: BorderSide(color: cs.outlineVariant),
                        foregroundColor: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _exportExcel,
                      icon: const Icon(Icons.table_chart_outlined, size: 15),
                      label: const Text('Export Excel', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        side: BorderSide(color: cs.outlineVariant),
                        foregroundColor: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _pushAdd,
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      label: const Text('Add New Employee', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B2235),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ──────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    children: [
                      // Table card
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            children: [
                              // Table header
                              _tableHeader(context, cs, isDark),

                              // Rows
                              Expanded(
                                child: filtered.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.people_outline, size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
                                            const SizedBox(height: 12),
                                            Text(
                                              _searchQuery.isNotEmpty ? 'No employees match your search' : 'No employees yet',
                                              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: pageItems.length,
                                        separatorBuilder: (_, _) => Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
                                        itemBuilder: (_, i) => _TableRow(
                                          employee: pageItems[i],
                                          initials: _initials(pageItems[i].fullName),
                                          avatarColor: _avatarColor(pageItems[i].fullName),
                                          onView: () => _pushDetail(pageItems[i]),
                                          onEdit: () => _pushEdit(pageItems[i]),
                                          onDelete: () => _confirmDelete(pageItems[i]),
                                          payrollLocked: _lockedThisMonth.contains(pageItems[i].id),
                                          cs: cs,
                                          isDark: isDark,
                                          isCompact: isCompact,
                                        ),
                                      ),
                              ),

                              // Pagination
                              if (filtered.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                                  decoration: BoxDecoration(
                                    border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35))),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Showing ${start + 1} to $end of ${filtered.length} entries',
                                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                                      ),
                                      const Spacer(),
                                      _PageNav(current: safePage, total: totalPages, onPage: (p) => setState(() => _page = p), cs: cs),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Stat cards
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Expanded(child: _StatCard(
                              icon: Icons.group_outlined, iconBg: const Color(0xFFE3F2FD), iconColor: const Color(0xFF1565C0),
                              label: 'TOTAL STRENGTH', value: all.length.toString(), isDark: isDark, cs: cs,
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: _StatCard(
                              icon: Icons.person_outline, iconBg: const Color(0xFFE8F5E9), iconColor: const Color(0xFF2E7D32),
                              label: 'ACTIVE THIS MONTH', value: activeCount.toString(), isDark: isDark, cs: cs,
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: _StatCard(
                              icon: Icons.credit_card_outlined, iconBg: const Color(0xFFE3F2FD), iconColor: const Color(0xFF1565C0),
                              label: 'PAYROLL STATUS', value: 'Verified', isDark: isDark, cs: cs,
                            )),
                          ],
                        ),
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

  Widget _tableHeader(BuildContext context, ColorScheme cs, bool isDark) {
    final style = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
      color: cs.onSurface.withValues(alpha: 0.55),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35))),
      ),
      child: Row(
        children: [
          Expanded(flex: 14, child: Text('EMPLOYEE ID', style: style)),
          Expanded(flex: 24, child: Text('FULL NAME', style: style)),
          Expanded(flex: 28, child: Text('DESIGNATION', style: style)),
          Expanded(flex: 16, child: Text('STATUS', style: style)),
          Expanded(flex: 18, child: Text('ACTIONS', style: style)),
        ],
      ),
    );
  }
}

// ── Filter tab ────────────────────────────────────────────────────────────────

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2,
              width: selected ? 24 : 0,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Table row ─────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final Employee employee;
  final String initials;
  final Color avatarColor;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool? payrollLocked;
  final ColorScheme cs;
  final bool isDark;
  final bool isCompact;

  const _TableRow({
    required this.employee,
    required this.initials,
    required this.avatarColor,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    this.payrollLocked,
    required this.cs,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = employee.status == 'active';

    return InkWell(
      onTap: onView,
      hoverColor: cs.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: isCompact ? 7 : 14),
        child: Row(
          children: [
            // Employee ID
            Expanded(
              flex: 14,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    employee.employeeId,
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0), fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),

            // Full Name
            Expanded(
              flex: 24,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: avatarColor,
                    child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      employee.fullName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Designation
            Expanded(
              flex: 28,
              child: Text(
                employee.designation,
                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.65)),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Status
            Expanded(
              flex: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? const Color(0xFF27AE60) : const Color(0xFFE53E3E),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF27AE60).withValues(alpha: 0.1)
                              : const Color(0xFFE53E3E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: isActive ? const Color(0xFF27AE60) : const Color(0xFFE53E3E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (payrollLocked != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: payrollLocked!
                            ? const Color(0xFF27AE60).withValues(alpha: 0.1)
                            : const Color(0xFFED8936).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: payrollLocked!
                              ? const Color(0xFF27AE60).withValues(alpha: 0.3)
                              : const Color(0xFFED8936).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            payrollLocked! ? Icons.lock_outline : Icons.hourglass_empty_outlined,
                            size: 10,
                            color: payrollLocked!
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFED8936),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            payrollLocked! ? 'Processed' : 'Pending',
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: payrollLocked!
                                  ? const Color(0xFF27AE60)
                                  : const Color(0xFFED8936),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            Expanded(
              flex: 18,
              child: _EmployeeActionButtons(
                onView: onView,
                onEdit: onEdit,
                onDelete: onDelete,
                isDark: isDark,
                cs: cs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pagination ────────────────────────────────────────────────────────────────

class _PageNav extends StatelessWidget {
  final int current;
  final int total;
  final ValueChanged<int> onPage;
  final ColorScheme cs;
  const _PageNav({required this.current, required this.total, required this.onPage, required this.cs});

  @override
  Widget build(BuildContext context) {
    // Show at most 5 page buttons
    final start = (current - 2).clamp(0, (total - 5).clamp(0, total));
    final end = (start + 5).clamp(0, total);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavBtn(icon: Icons.chevron_left, onTap: current > 0 ? () => onPage(current - 1) : null, cs: cs),
        const SizedBox(width: 4),
        for (int i = start; i < end; i++) ...[
          _PageBtn(number: i + 1, selected: i == current, onTap: () => onPage(i), cs: cs),
          const SizedBox(width: 4),
        ],
        if (end < total) ...[
          Text('...', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(width: 4),
          _PageBtn(number: total, selected: current == total - 1, onTap: () => onPage(total - 1), cs: cs),
          const SizedBox(width: 4),
        ],
        _NavBtn(icon: Icons.chevron_right, onTap: current < total - 1 ? () => onPage(current + 1) : null, cs: cs),
      ],
    );
  }
}

class _PageBtn extends StatelessWidget {
  final int number;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _PageBtn({required this.number, required this.selected, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: selected ? null : Border.all(color: cs.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? Colors.white : cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final ColorScheme cs;
  const _NavBtn({required this.icon, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: onTap == null ? 0.3 : 1.0)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: onTap == null ? cs.onSurface.withValues(alpha: 0.2) : cs.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }
}

// ── Category tab chip ─────────────────────────────────────────────────────────

class _CatTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final ColorScheme cs;
  const _CatTab({required this.label, required this.active, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? cs.primary : cs.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.white : cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ── Category popup dialog ─────────────────────────────────────────────────────

class _CategoryPopupDialog extends StatelessWidget {
  final String category;

  static const _labels = {
    'pedo': 'PEDO Employees',
    'security': 'Security Guards',
    'alfajar': 'Al Fajar',
  };

  static const _avatarColors = [
    Color(0xFF1565C0), Color(0xFF2E7D32), Color(0xFF6A1B9A),
    Color(0xFFAD1457), Color(0xFF00695C), Color(0xFFE65100),
  ];

  const _CategoryPopupDialog({required this.category});

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _avatarColor(String name) =>
      _avatarColors[name.codeUnits.first % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = _labels[category] ?? category;
    final headerStyle = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
      color: cs.onSurface.withValues(alpha: 0.55),
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 580),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 20, color: cs.primary),
                  const SizedBox(width: 10),
                  Text(label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),

            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  Expanded(flex: 14, child: Text('EMPLOYEE ID', style: headerStyle)),
                  Expanded(flex: 24, child: Text('FULL NAME', style: headerStyle)),
                  Expanded(flex: 28, child: Text('DESIGNATION', style: headerStyle)),
                  Expanded(flex: 16, child: Text('STATUS', style: headerStyle)),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),

            // Employee rows
            Expanded(
              child: StreamBuilder<List<Employee>>(
                stream: AppDatabase.instance.employeesDao.watchEmployeesByCategory(category),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final employees = snapshot.data ?? [];
                  if (employees.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 10),
                          Text('No employees in this category',
                            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 14)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: employees.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
                    itemBuilder: (_, i) {
                      final emp = employees[i];
                      final isActive = emp.status == 'active';
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => EmployeeDetailScreen(
                              employee: emp,
                              category: category,
                            ),
                          ));
                        },
                        hoverColor: cs.primary.withValues(alpha: 0.04),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                          child: Row(
                          children: [
                            Expanded(
                              flex: 14,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1565C0).withValues(alpha: isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    emp.employeeId,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                      color: Color(0xFF1565C0), fontFamily: 'monospace'),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 24,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: _avatarColor(emp.fullName),
                                    child: Text(_initials(emp.fullName),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(emp.fullName,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                                      overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 28,
                              child: Text(emp.designation,
                                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.65)),
                                overflow: TextOverflow.ellipsis),
                            ),
                            Expanded(
                              flex: 16,
                              child: Row(
                                children: [
                                  Container(
                                    width: 7, height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive ? const Color(0xFF27AE60) : const Color(0xFFE53E3E),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isActive ? const Color(0xFF27AE60) : const Color(0xFFE53E3E))
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.w600,
                                        color: isActive ? const Color(0xFF27AE60) : const Color(0xFFE53E3E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Footer
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter dialog ─────────────────────────────────────────────────────────────

class _FilterDialog extends StatefulWidget {
  final List<String> grades;
  final String? initialBps;
  final String initialDesignation;

  const _FilterDialog({
    required this.grades,
    required this.initialBps,
    required this.initialDesignation,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  String? _bps;
  late final TextEditingController _deptCtrl;

  @override
  void initState() {
    super.initState();
    _bps = widget.initialBps;
    _deptCtrl = TextEditingController(text: widget.initialDesignation);
  }

  @override
  void dispose() {
    _deptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Employees'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BPS Grade', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            InputDecorator(
              decoration: const InputDecoration(isDense: true),
              child: DropdownButton<String?>(
                value: _bps,
                isExpanded: true,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Grades')),
                  ...widget.grades.map(
                    (g) => DropdownMenuItem(value: g, child: Text(g)),
                  ),
                ],
                onChanged: (v) => setState(() => _bps = v),
              ),
            ),
            const SizedBox(height: 16),
            Text('Designation', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _deptCtrl,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Filter by designation...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, (bps: null, dept: '')),
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            (bps: _bps, dept: _deptCtrl.text.trim()),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

// ── Employee action buttons [👁 | ✎ | 🗑] ────────────────────────────────────

class _EmployeeActionButtons extends StatelessWidget {
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDark;
  final ColorScheme cs;

  const _EmployeeActionButtons({
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final divColor = isDark ? Colors.grey.shade600 : Colors.grey.shade300;
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
            icon: const Icon(Icons.visibility_outlined, size: 16),
            onPressed: onView,
            tooltip: 'View',
            color: Colors.blue.shade600,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Container(width: 1, height: 14, color: divColor),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: onEdit,
            tooltip: 'Edit',
            color: Colors.orange.shade600,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Container(width: 1, height: 14, color: divColor),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
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

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;
  final ColorScheme cs;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.15) : iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
