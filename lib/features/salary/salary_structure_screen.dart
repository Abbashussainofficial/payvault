import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/salary_calculator.dart';
import 'allowance_form.dart';

class SalaryStructureScreen extends StatefulWidget {
  final Employee employee;

  const SalaryStructureScreen({required this.employee, super.key});

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

  Future<void> _editBaseSalary() async {
    final ctrl = TextEditingController(
      text: _employee.baseSalary > 0
          ? _employee.baseSalary.toStringAsFixed(0)
          : '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Edit Base Salary'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Base Salary (PKR)',
                prefixText: 'PKR ',
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

  Future<void> _addComponent(String type) async {
    await showAllowanceForm(
      context: context,
      employee: _employee,
      componentType: type,
    );
  }

  Future<void> _editComponent(SalaryComponent c) async {
    await showAllowanceForm(
      context: context,
      employee: _employee,
      componentType: c.componentType,
      component: c,
    );
  }

  Future<void> _deleteComponent(SalaryComponent c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
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
    final updated = c.copyWith(isActive: !c.isActive);
    await AppDatabase.instance.salaryComponentsDao.updateComponent(updated);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Salary Structure'),
            Text(
              _employee.fullName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<SalaryComponent>>(
        stream: AppDatabase.instance.salaryComponentsDao
            .watchComponentsByEmployee(_employee.id),
        builder: (context, snapshot) {
          final components = snapshot.data ?? [];
          final allowances =
              components.where((c) => c.componentType == 'allowance').toList();
          final deductions =
              components.where((c) => c.componentType == 'deduction').toList();

          final totalAllow =
              SalaryCalculator.totalAllowances(allowances, _employee.baseSalary);
          final totalDeduct =
              SalaryCalculator.totalDeductions(deductions, _employee.baseSalary);
          final netSalary = _employee.baseSalary + totalAllow - totalDeduct;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Base Salary card ──────────────────────────────────
                      _BaseSalaryCard(
                        baseSalary: _employee.baseSalary,
                        onEdit: _editBaseSalary,
                        cs: cs,
                      ),
                      const SizedBox(height: 24),

                      // ── Allowances section ────────────────────────────────
                      _SectionHeader(
                        title: 'Allowances',
                        count: allowances.length,
                        color: const Color(0xFF2E7D32),
                        onAdd: () => _addComponent('allowance'),
                      ),
                      const SizedBox(height: 10),
                      if (allowances.isEmpty)
                        _EmptySection(
                          label: 'No allowances added',
                          onAdd: () => _addComponent('allowance'),
                          cs: cs,
                        )
                      else
                        ...allowances.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ComponentTile(
                              component: c,
                              baseSalary: _employee.baseSalary,
                              onEdit: () => _editComponent(c),
                              onDelete: () => _deleteComponent(c),
                              onToggleActive: () => _toggleActive(c),
                              cs: cs,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ── Deductions section ────────────────────────────────
                      _SectionHeader(
                        title: 'Deductions',
                        count: deductions.length,
                        color: Theme.of(context).colorScheme.error,
                        onAdd: () => _addComponent('deduction'),
                      ),
                      const SizedBox(height: 10),
                      if (deductions.isEmpty)
                        _EmptySection(
                          label: 'No deductions added',
                          onAdd: () => _addComponent('deduction'),
                          cs: cs,
                        )
                      else
                        ...deductions.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ComponentTile(
                              component: c,
                              baseSalary: _employee.baseSalary,
                              onEdit: () => _editComponent(c),
                              onDelete: () => _deleteComponent(c),
                              onToggleActive: () => _toggleActive(c),
                              cs: cs,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Summary card (pinned bottom) ──────────────────────────────
              _SummaryCard(
                baseSalary: _employee.baseSalary,
                totalAllowances: totalAllow,
                totalDeductions: totalDeduct,
                netSalary: netSalary,
                cs: cs,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Base salary card ──────────────────────────────────────────────────────────

class _BaseSalaryCard extends StatelessWidget {
  final double baseSalary;
  final VoidCallback onEdit;
  final ColorScheme cs;

  const _BaseSalaryCard({
    required this.baseSalary,
    required this.onEdit,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_outlined, color: cs.primary, size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Base Salary',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                NumberFormat.currency(
                  locale: 'en_PK',
                  symbol: 'PKR ',
                  decimalDigits: 0,
                ).format(baseSalary),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onAdd,
          icon: Icon(Icons.add, size: 16, color: cs.primary),
          label: Text('Add', style: TextStyle(color: cs.primary)),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        ),
      ],
    );
  }
}

// ── Empty section placeholder ─────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  final String label;
  final VoidCallback onAdd;
  final ColorScheme cs;

  const _EmptySection({
    required this.label,
    required this.onAdd,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, size: 18, color: cs.onSurface.withValues(alpha: 0.35)),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Component tile ────────────────────────────────────────────────────────────

class _ComponentTile extends StatelessWidget {
  final SalaryComponent component;
  final double baseSalary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final ColorScheme cs;

  const _ComponentTile({
    required this.component,
    required this.baseSalary,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.cs,
  });

  static final _fmt = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'PKR ',
    decimalDigits: 0,
  );

  bool get _isFrozen => component.freezeMode != 'not_frozen';
  bool get _isAllowance => component.componentType == 'allowance';

  Color get _accentColor => _isAllowance ? const Color(0xFF2E7D32) : cs.error;

  String get _valueLabel =>
      component.valueType == 'percentage'
          ? '${component.value.toStringAsFixed(component.value == component.value.roundToDouble() ? 0 : 1)}%'
          : _fmt.format(component.value);

  String get _freezeLabel {
    switch (component.freezeMode) {
      case 'frozen_on_amount':
        return 'Frozen: ${_fmt.format(component.frozenAmount ?? 0)}';
      case 'frozen_on_base':
        return 'On base: ${_fmt.format(component.frozenBase ?? 0)}';
      default:
        return 'Live';
    }
  }

  @override
  Widget build(BuildContext context) {
    final calculatedAmount = SalaryCalculator.calculateComponent(
      component,
      baseSalary,
    );

    final tileColor = !component.isActive
        ? cs.surfaceContainerHighest.withValues(alpha: 0.3)
        : _isFrozen
            ? Colors.blue.withValues(alpha: 0.04)
            : null;

    final borderColor = !component.isActive
        ? cs.outlineVariant.withValues(alpha: 0.3)
        : _isFrozen
            ? Colors.blue.withValues(alpha: 0.3)
            : cs.outlineVariant.withValues(alpha: 0.5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Freeze icon ───────────────────────────────────────────────
            Tooltip(
              message: _freezeLabel,
              child: Icon(
                _isFrozen ? Icons.ac_unit : Icons.lock_open_outlined,
                size: 18,
                color:
                    _isFrozen
                        ? Colors.blue.withValues(
                          alpha: component.isActive ? 0.9 : 0.4,
                        )
                        : const Color(0xFF2E7D32).withValues(
                          alpha: component.isActive ? 0.8 : 0.3,
                        ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Name + code ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    component.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: component.isActive
                          ? null
                          : cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  if (component.classificationCode != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      component.classificationCode!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                  if (_isFrozen) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.ac_unit,
                          size: 10,
                          color: Colors.blue.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _freezeLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.blue.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Value + calculated ────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _valueLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(
                      alpha: component.isActive ? 0.55 : 0.3,
                    ),
                  ),
                ),
                Text(
                  _fmt.format(calculatedAmount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: component.isActive
                        ? _accentColor
                        : cs.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // ── Actions ───────────────────────────────────────────────────
            IconButton(
              tooltip: 'Edit',
              icon: Icon(Icons.edit_outlined, size: 16, color: cs.primary),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, size: 16, color: cs.error),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),

            // ── Active toggle ─────────────────────────────────────────────
            Switch(
              value: component.isActive,
              onChanged: (_) => onToggleActive(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double baseSalary;
  final double totalAllowances;
  final double totalDeductions;
  final double netSalary;
  final ColorScheme cs;

  const _SummaryCard({
    required this.baseSalary,
    required this.totalAllowances,
    required this.totalDeductions,
    required this.netSalary,
    required this.cs,
  });

  static final _fmt = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'PKR ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryRow(
            label: 'Base Salary',
            amount: baseSalary,
            color: cs.onSurface.withValues(alpha: 0.7),
            fmt: _fmt,
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: '+ Allowances',
            amount: totalAllowances,
            color: const Color(0xFF2E7D32),
            fmt: _fmt,
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: '− Deductions',
            amount: totalDeductions,
            color: cs.error,
            fmt: _fmt,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: cs.outlineVariant),
          ),
          Row(
            children: [
              Text(
                'Net Salary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _fmt.format(netSalary),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final NumberFormat fmt;

  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
        const Spacer(),
        Text(
          fmt.format(amount),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
