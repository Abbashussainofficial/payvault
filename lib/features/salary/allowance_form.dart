import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/salary_calculator.dart';

/// Shows a dialog to add or edit a salary component (allowance or deduction).
/// Returns `true` when a save was performed, `null`/`false` otherwise.
Future<bool?> showAllowanceForm({
  required BuildContext context,
  required Employee employee,
  required String componentType, // 'allowance' | 'deduction'
  SalaryComponent? component,    // null = add mode
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => _AllowanceFormDialog(
          employee: employee,
          componentType: componentType,
          component: component,
        ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _AllowanceFormDialog extends StatefulWidget {
  final Employee employee;
  final String componentType;
  final SalaryComponent? component;

  const _AllowanceFormDialog({
    required this.employee,
    required this.componentType,
    required this.component,
  });

  @override
  State<_AllowanceFormDialog> createState() => _AllowanceFormDialogState();
}

class _AllowanceFormDialogState extends State<_AllowanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _valueCtrl;

  late String _valueType;   // 'percentage' | 'fixed'
  late String _freezeMode;  // 'not_frozen' | 'frozen_on_amount' | 'frozen_on_base'
  late bool _isActive;
  late int _sortOrder;

  bool get _isEdit => widget.component != null;
  bool get _isAllowance => widget.componentType == 'allowance';
  double get _baseSalary => widget.employee.baseSalary;

  // Live preview of the calculated amount based on current form values
  double get _previewAmount {
    final v = double.tryParse(_valueCtrl.text.trim()) ?? 0.0;
    return SalaryCalculator.previewAmount(
      valueType: _valueType,
      value: v,
      baseSalary: _baseSalary,
    );
  }

  @override
  void initState() {
    super.initState();
    final c = widget.component;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _codeCtrl = TextEditingController(text: c?.classificationCode ?? '');
    _valueCtrl = TextEditingController(
      text: c != null ? c.value.toStringAsFixed(c.valueType == 'percentage' ? 2 : 0) : '',
    );
    _valueType = c?.valueType ?? 'percentage';
    _freezeMode = c?.freezeMode ?? 'not_frozen';
    _isActive = c?.isActive ?? true;
    _sortOrder = c?.sortOrder ?? 0;

    _valueCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final dao = AppDatabase.instance.salaryComponentsDao;
      final value = double.tryParse(_valueCtrl.text.trim()) ?? 0.0;
      final now = DateTime.now().toIso8601String();

      // Compute freeze fields
      double? frozenAmount;
      double? frozenBase;
      String? freezeDate;

      switch (_freezeMode) {
        case 'frozen_on_amount':
          frozenAmount = _previewAmount;
          frozenBase = null;
          freezeDate = now;
        case 'frozen_on_base':
          frozenAmount = null;
          frozenBase = _baseSalary;
          freezeDate = now;
        default: // not_frozen
          frozenAmount = null;
          frozenBase = null;
          freezeDate = null;
      }

      if (_isEdit) {
        final updated = widget.component!.copyWith(
          name: _nameCtrl.text.trim(),
          classificationCode: Value(
            _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
          ),
          valueType: _valueType,
          value: value,
          freezeMode: _freezeMode,
          frozenAmount: Value(frozenAmount),
          frozenBase: Value(frozenBase),
          freezeDate: Value(freezeDate),
          isActive: _isActive,
          sortOrder: _sortOrder,
        );
        await dao.updateComponent(updated);
      } else {
        await dao.insertComponent(
          SalaryComponentsCompanion(
            employeeId: Value(widget.employee.id),
            name: Value(_nameCtrl.text.trim()),
            componentType: Value(widget.componentType),
            classificationCode: Value(
              _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
            ),
            valueType: Value(_valueType),
            value: Value(value),
            freezeMode: Value(_freezeMode),
            frozenAmount: Value(frozenAmount),
            frozenBase: Value(frozenBase),
            freezeDate: Value(freezeDate),
            isActive: Value(_isActive),
            sortOrder: Value(_sortOrder),
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'Failed to save: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = _isEdit
        ? 'Edit ${_isAllowance ? 'Allowance' : 'Deduction'}'
        : 'Add ${_isAllowance ? 'Allowance' : 'Deduction'}';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Row(
                    children: [
                      Icon(
                        _isAllowance
                            ? Icons.add_circle_outline
                            : Icons.remove_circle_outline,
                        color: _isAllowance
                            ? const Color(0xFF2E7D32)
                            : cs.error,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context, false),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: cs.onErrorContainer),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Name ──────────────────────────────────────────────────
                  _label(context, 'Name *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. House Rent Allowance',
                    ),
                    validator:
                        (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Classification Code ───────────────────────────────────
                  _label(context, 'Classification Code'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. HRA (optional)',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Value Type toggle ─────────────────────────────────────
                  _label(context, 'Value Type'),
                  const SizedBox(height: 8),
                  _ValueTypeToggle(
                    selected: _valueType,
                    onChanged: (v) => setState(() => _valueType = v),
                    cs: cs,
                  ),
                  const SizedBox(height: 16),

                  // ── Value ─────────────────────────────────────────────────
                  _label(
                    context,
                    _valueType == 'percentage'
                        ? 'Percentage (%) *'
                        : 'Fixed Amount (PKR) *',
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _valueCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      hintText: _valueType == 'percentage' ? '0.00' : '0',
                      suffixText:
                          _valueType == 'percentage' ? '%' : 'PKR',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Freeze Mode ───────────────────────────────────────────
                  _label(context, 'Freeze Mode'),
                  const SizedBox(height: 8),
                  _FreezeModeSelector(
                    selected: _freezeMode,
                    previewAmount: _previewAmount,
                    baseSalary: _baseSalary,
                    onChanged: (v) => setState(() => _freezeMode = v),
                    cs: cs,
                  ),
                  const SizedBox(height: 20),

                  // ── Active toggle ─────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Inactive components are excluded from calculations',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon:
                            _saving
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.save_outlined, size: 18),
                        label: Text(_saving ? 'Saving…' : 'Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.labelMedium,
  );
}

// ── Value type toggle ─────────────────────────────────────────────────────────

class _ValueTypeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final ColorScheme cs;

  const _ValueTypeToggle({
    required this.selected,
    required this.onChanged,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          label: 'Percentage %',
          icon: Icons.percent,
          selected: selected == 'percentage',
          onTap: () => onChanged('percentage'),
          cs: cs,
        ),
        const SizedBox(width: 10),
        _Chip(
          label: 'Fixed Amount',
          icon: Icons.attach_money,
          selected: selected == 'fixed',
          onTap: () => onChanged('fixed'),
          cs: cs,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Freeze mode selector ──────────────────────────────────────────────────────

class _FreezeModeSelector extends StatelessWidget {
  final String selected;
  final double previewAmount;
  final double baseSalary;
  final ValueChanged<String> onChanged;
  final ColorScheme cs;

  const _FreezeModeSelector({
    required this.selected,
    required this.previewAmount,
    required this.baseSalary,
    required this.onChanged,
    required this.cs,
  });

  static final _fmt = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'PKR ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FreezeOption(
          value: 'not_frozen',
          selected: selected,
          icon: Icons.lock_open_outlined,
          iconColor: const Color(0xFF2E7D32),
          title: 'Not Frozen',
          subtitle: 'Recalculates automatically when base salary changes',
          onTap: () => onChanged('not_frozen'),
          cs: cs,
        ),
        const SizedBox(height: 8),
        _FreezeOption(
          value: 'frozen_on_amount',
          selected: selected,
          icon: Icons.ac_unit,
          iconColor: Colors.blue,
          title: 'Freeze on Amount',
          subtitle: selected == 'frozen_on_amount'
              ? 'Will lock at: ${_fmt.format(previewAmount)}'
              : 'Locks the current calculated amount permanently',
          preview:
              selected == 'frozen_on_amount'
                  ? '${_fmt.format(previewAmount)} will be locked'
                  : null,
          onTap: () => onChanged('frozen_on_amount'),
          cs: cs,
        ),
        const SizedBox(height: 8),
        _FreezeOption(
          value: 'frozen_on_base',
          selected: selected,
          icon: Icons.ac_unit,
          iconColor: Colors.indigo,
          title: 'Freeze on Base',
          subtitle: selected == 'frozen_on_base'
              ? 'Will lock base at: ${_fmt.format(baseSalary)}'
              : 'Locks the percentage against the current base salary',
          preview:
              selected == 'frozen_on_base'
                  ? 'Percentage applied to frozen base ${_fmt.format(baseSalary)}'
                  : null,
          onTap: () => onChanged('frozen_on_base'),
          cs: cs,
        ),
      ],
    );
  }
}

class _FreezeOption extends StatelessWidget {
  final String value;
  final String selected;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? preview;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _FreezeOption({
    required this.value,
    required this.selected,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.preview,
    required this.onTap,
    required this.cs,
  });

  bool get _isSelected => value == selected;
  bool get _isFrozen => value != 'not_frozen';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              _isSelected
                  ? (_isFrozen
                      ? Colors.blue.withValues(alpha: 0.06)
                      : cs.primaryContainer.withValues(alpha: 0.5))
                  : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                _isSelected
                    ? (_isFrozen ? Colors.blue.withValues(alpha: 0.5) : cs.primary)
                    : cs.outlineVariant.withValues(alpha: 0.5),
            width: _isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: _isSelected ? iconColor : cs.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          _isSelected
                              ? (_isFrozen ? Colors.blue.shade700 : cs.primary)
                              : cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  if (_isSelected && preview != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        preview!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              _isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: _isSelected
                  ? (_isFrozen ? Colors.blue : cs.primary)
                  : cs.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
