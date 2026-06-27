import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/salary_calculator.dart';

Future<bool?> showAllowanceForm({
  required BuildContext context,
  required Employee employee,
  required String componentType,
  SalaryComponent? component,
  String? allowanceSection,
  int nextSortOrder = 0,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AllowanceFormDialog(
      employee: employee,
      componentType: componentType,
      component: component,
      allowanceSection: allowanceSection,
      nextSortOrder: nextSortOrder,
    ),
  );
}

class _AllowanceFormDialog extends StatefulWidget {
  final Employee employee;
  final String componentType;
  final SalaryComponent? component;
  final String? allowanceSection;
  final int nextSortOrder;

  const _AllowanceFormDialog({
    required this.employee,
    required this.componentType,
    required this.component,
    this.allowanceSection,
    this.nextSortOrder = 0,
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

  late String _valueType;
  late String _freezeMode;
  late bool _isActive;
  late int _sortOrder;

  bool get _isEdit => widget.component != null;
  bool get _isAllowance => widget.componentType == 'allowance';
  bool get _isPedo => widget.employee.category == 'pedo';
  double get _baseSalary => widget.employee.baseSalary;

  // Section from the existing component (edit) or the button that was tapped (add)
  String? get _effectiveSection =>
      _isEdit ? widget.component!.allowanceSection : widget.allowanceSection;

  double get _previewAmount {
    final v = double.tryParse(_valueCtrl.text.trim()) ?? 0.0;
    return SalaryCalculator.previewAmount(valueType: _valueType, value: v, baseSalary: _baseSalary);
  }

  static final _fmt = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final c = widget.component;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _codeCtrl = TextEditingController(text: c?.classificationCode ?? '');
    _valueCtrl = TextEditingController(
      text: c != null ? c.value.toStringAsFixed(0) : '',
    );
    _valueType = c?.valueType ?? 'percentage';
    _freezeMode = c?.freezeMode ?? 'not_frozen';
    _isActive = c?.isActive ?? true;
    _sortOrder = c?.sortOrder ?? widget.nextSortOrder;
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
    setState(() { _saving = true; _error = null; });

    try {
      final dao = AppDatabase.instance.salaryComponentsDao;
      final value = double.tryParse(_valueCtrl.text.trim()) ?? 0.0;
      final now = DateTime.now().toIso8601String();
      final code = _isPedo && _codeCtrl.text.trim().isNotEmpty
          ? _codeCtrl.text.trim()
          : null;

      double? frozenAmount;
      double? frozenBase;
      String? freezeDate;

      switch (_freezeMode) {
        case 'frozen_on_amount':
          frozenAmount = _previewAmount;
          freezeDate = now;
        case 'frozen_on_base':
          frozenBase = _baseSalary;
          freezeDate = now;
        default:
          break;
      }

      if (_isEdit) {
        await dao.updateComponent(widget.component!.copyWith(
          name: _nameCtrl.text.trim(),
          classificationCode: Value(code),
          allowanceSection: Value(_effectiveSection),
          valueType: _valueType,
          value: value,
          freezeMode: _freezeMode,
          frozenAmount: Value(frozenAmount),
          frozenBase: Value(frozenBase),
          freezeDate: Value(freezeDate),
          isActive: _isActive,
          sortOrder: _sortOrder,
        ));
      } else {
        await dao.insertComponent(SalaryComponentsCompanion(
          employeeId: Value(widget.employee.id),
          name: Value(_nameCtrl.text.trim()),
          componentType: Value(widget.componentType),
          classificationCode: Value(code),
          allowanceSection: Value(_effectiveSection),
          valueType: Value(_valueType),
          value: Value(value),
          freezeMode: Value(_freezeMode),
          frozenAmount: Value(frozenAmount),
          frozenBase: Value(frozenBase),
          freezeDate: Value(freezeDate),
          isActive: Value(_isActive),
          sortOrder: Value(_sortOrder),
        ));
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = 'Failed to save: $e'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _isEdit
        ? 'Edit ${_isAllowance ? 'Allowance' : 'Deduction'}'
        : 'Add New ${_isAllowance ? 'Allowance' : 'Deduction'}';
    final saveLabel = _isEdit ? 'Save Changes' : (_isAllowance ? 'Add Allowance' : 'Add Deduction');

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Dialog header ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: Icon(Icons.close, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),

                // ── Form body ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_error!, style: TextStyle(color: cs.onErrorContainer, fontSize: 13)),
                        ),
                      ],

                      // Section banner — shown for pedo allowances
                      if (_isAllowance && _effectiveSection != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: _effectiveSection == 'regular'
                                ? const Color(0xFF27AE60).withValues(alpha: isDark ? 0.15 : 0.08)
                                : const Color(0xFF7B68EE).withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: _effectiveSection == 'regular'
                                  ? const Color(0xFF27AE60).withValues(alpha: 0.3)
                                  : const Color(0xFF7B68EE).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.label_outline,
                                size: 15,
                                color: _effectiveSection == 'regular'
                                    ? const Color(0xFF27AE60)
                                    : const Color(0xFF7B68EE),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _effectiveSection == 'regular'
                                    ? 'Adding to: Regular Allowances'
                                    : 'Adding to: Other Allowances',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _effectiveSection == 'regular'
                                      ? const Color(0xFF27AE60)
                                      : const Color(0xFF7B68EE),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Name field
                      Text(
                        _isAllowance ? 'Allowance Name' : 'Deduction Name',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          hintText: _isAllowance ? 'e.g. Utility Allowance' : 'e.g. Income Tax',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Classification code — pedo only
                      if (_isPedo) ...[
                        Text(
                          'Classification Code (Optional)',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _codeCtrl,
                          decoration: const InputDecoration(hintText: 'e.g. 02200'),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Type + Value in a row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Type toggle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Type', style: Theme.of(context).textTheme.labelMedium),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _TypeBtn(
                                      label: 'Percentage',
                                      selected: _valueType == 'percentage',
                                      onTap: () => setState(() => _valueType = 'percentage'),
                                      cs: cs,
                                    ),
                                    const SizedBox(width: 8),
                                    _TypeBtn(
                                      label: 'Fixed',
                                      selected: _valueType == 'fixed',
                                      onTap: () => setState(() => _valueType = 'fixed'),
                                      cs: cs,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Value field
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Value', style: Theme.of(context).textTheme.labelMedium),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _valueCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  decoration: InputDecoration(
                                    hintText: _valueType == 'percentage' ? '10' : '5000',
                                    suffixText: _valueType == 'percentage' ? '%' : 'PKR',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    if (double.tryParse(v.trim()) == null) return 'Invalid number';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Live Preview
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: isDark ? 0.15 : 0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bar_chart_outlined, size: 18, color: const Color(0xFF1565C0)),
                            const SizedBox(width: 10),
                            Text('Live Preview',
                              style: TextStyle(fontSize: 13, color: const Color(0xFF1565C0), fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Calculated: ${_fmt.format(_previewAmount)}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1565C0)),
                                ),
                                Text(
                                  'Based on standard base salary',
                                  style: TextStyle(fontSize: 11, color: const Color(0xFF1565C0).withValues(alpha: 0.65)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Freeze Settings
                      Text('Freeze Settings', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 10),
                      _RadioOption(
                        label: 'Not Frozen',
                        selected: _freezeMode == 'not_frozen',
                        onTap: () => setState(() => _freezeMode = 'not_frozen'),
                        cs: cs,
                      ),
                      const SizedBox(height: 8),
                      _RadioOption(
                        label: 'Freeze on Amount',
                        selected: _freezeMode == 'frozen_on_amount',
                        onTap: () => setState(() => _freezeMode = 'frozen_on_amount'),
                        cs: cs,
                      ),
                      const SizedBox(height: 8),
                      _RadioOption(
                        label: 'Freeze on Base',
                        selected: _freezeMode == 'frozen_on_base',
                        onTap: () => setState(() => _freezeMode = 'frozen_on_base'),
                        cs: cs,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // ── Footer buttons ───────────────────────────────────────
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                          side: BorderSide(color: cs.outlineVariant),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(_isEdit ? Icons.check : Icons.add, size: 17),
                        label: Text(
                          _saving ? 'Saving…' : saveLabel,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1B2235),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Type toggle button ────────────────────────────────────────────────────────

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _TypeBtn({required this.label, required this.selected, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ── Radio option ──────────────────────────────────────────────────────────────

class _RadioOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _RadioOption({required this.label, required this.selected, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 18,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.35),
                width: selected ? 5 : 2,
              ),
              color: Colors.transparent,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              color: selected ? cs.onSurface : cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
