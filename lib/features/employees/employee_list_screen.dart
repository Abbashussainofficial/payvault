import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import 'employee_detail_screen.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  final String category;
  const EmployeeListScreen({required this.category, super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _labels = {
    'pedo': 'PEDO Employees',
    'security': 'Security Guards',
    'alfajar': 'Al Fajar',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Employee> _applyFilters(List<Employee> all) {
    var list = switch (_tabController.index) {
      1 => all.where((e) => e.status == 'active').toList(),
      2 => all.where((e) => e.status == 'left').toList(),
      _ => all,
    };
    if (_searchQuery.isEmpty) return list;
    return list
        .where(
          (e) =>
              e.employeeId.toLowerCase().contains(_searchQuery) ||
              e.fullName.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  Future<void> _confirmDelete(Employee emp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Employee'),
            content: Text(
              'Permanently delete ${emp.fullName}?\nThis will also remove all salary components.',
            ),
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
    if (ok != true || !mounted) return;
    await AppDatabase.instance.salaryComponentsDao
        .deleteComponentsByEmployee(emp.id);
    await AppDatabase.instance.employeesDao.deleteEmployee(emp.id);
  }

  void _pushDetail(Employee emp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                EmployeeDetailScreen(employee: emp, category: widget.category),
      ),
    );
  }

  void _pushEdit(Employee emp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                EmployeeFormScreen(category: widget.category, employee: emp),
      ),
    );
  }

  void _pushAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeFormScreen(category: widget.category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _labels[widget.category] ?? widget.category;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            color: cs.surface,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage employees and their records',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Search bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or employee ID…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _searchController.clear,
                        )
                        : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // ── Tabs ───────────────────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Active'),
              Tab(text: 'Left'),
            ],
          ),

          // ── List ───────────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Employee>>(
              stream: AppDatabase.instance.employeesDao
                  .watchEmployeesByCategory(widget.category),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading employees',
                      style: TextStyle(color: cs.error),
                    ),
                  );
                }

                final filtered = _applyFilters(snapshot.data ?? []);

                if (filtered.isEmpty) {
                  return _EmptyState(
                    hasSearch: _searchQuery.isNotEmpty,
                    onAdd: _pushAdd,
                    cs: cs,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder:
                      (_, i) => _EmployeeTile(
                        employee: filtered[i],
                        onView: () => _pushDetail(filtered[i]),
                        onEdit: () => _pushEdit(filtered[i]),
                        onDelete: () => _confirmDelete(filtered[i]),
                      ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pushAdd,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Employee'),
      ),
    );
  }
}

// ── Tile ─────────────────────────────────────────────────────────────────────

class _EmployeeTile extends StatelessWidget {
  final Employee employee;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeTile({
    required this.employee,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = employee.status == 'active';

    String formattedDate = employee.joiningDate;
    try {
      formattedDate = DateFormat('dd MMM yyyy').format(
        DateTime.parse(employee.joiningDate),
      );
    } catch (_) {}

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ID badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  employee.employeeId,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name + designation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employee.designation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),

              // Joining date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Joined',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Status chip
              Container(
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
                        isActive
                            ? const Color(0xFF2E7D32)
                            : cs.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'View',
                    icon: Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: cs.primary,
                    ),
                    onPressed: onView,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    icon: Icon(Icons.edit_outlined, size: 18, color: cs.primary),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;
  final ColorScheme cs;

  const _EmptyState({
    required this.hasSearch,
    required this.onAdd,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: cs.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No employees match your search' : 'No employees yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Add First Employee'),
            ),
          ],
        ],
      ),
    );
  }
}
