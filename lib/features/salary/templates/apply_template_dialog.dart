import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/database.dart';

Future<bool?> showApplyTemplateDialog({
  required BuildContext context,
  required Employee employee,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ApplyTemplateDialog(employee: employee),
  );
}

class _ApplyTemplateDialog extends StatefulWidget {
  final Employee employee;
  const _ApplyTemplateDialog({required this.employee});

  @override
  State<_ApplyTemplateDialog> createState() => _ApplyTemplateDialogState();
}

class _ApplyTemplateDialogState extends State<_ApplyTemplateDialog> {
  final _db = AppDatabase.instance;

  List<SalaryTemplate> _templates = [];
  Map<int, List<SalaryTemplateItem>> _templateItems = {};
  SalaryTemplate? _selected;
  bool _loadingTemplates = true;

  int _step = 1;
  String _applyMode = 'add';
  List<_ItemDraft> _drafts = [];
  bool _applying = false;
  int _existingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _loadExistingCount();
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    final templates = await _db.salaryTemplatesDao.getAllTemplates();
    final map = <int, List<SalaryTemplateItem>>{};
    for (final t in templates) {
      map[t.id] = await _db.salaryTemplatesDao.getItemsByTemplate(t.id);
    }
    if (mounted) {
      setState(() {
        _templates = templates;
        _templateItems = map;
        _loadingTemplates = false;
      });
    }
  }

  Future<void> _loadExistingCount() async {
    final comps = await _db.salaryComponentsDao.getComponentsByEmployee(widget.employee.id);
    if (mounted) setState(() => _existingCount = comps.length);
  }

  void _goToStep2() {
    if (_selected == null) return;
    final items = _templateItems[_selected!.id] ?? [];
    // Dispose old drafts before creating new ones
    for (final d in _drafts) {
      d.ctrl.dispose();
    }
    setState(() {
      _drafts = items.map((item) => _ItemDraft.fromTemplateItem(item)).toList();
      _step = 2;
    });
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final dao = _db.salaryComponentsDao;
      if (_applyMode == 'replace') {
        await dao.deleteComponentsByEmployee(widget.employee.id);
      }

      int baseSortOrder = 0;
      if (_applyMode == 'add') {
        final existing = await dao.getComponentsByEmployee(widget.employee.id);
        if (existing.isNotEmpty) {
          baseSortOrder = existing.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
        }
      }

      for (int i = 0; i < _drafts.length; i++) {
        final d = _drafts[i];
        await dao.insertComponent(SalaryComponentsCompanion(
          employeeId: Value(widget.employee.id),
          name: Value(d.name),
          componentType: Value(d.componentType),
          allowanceSection: Value(d.allowanceSection),
          valueType: Value(d.valueType),
          value: Value(d.amount),
          classificationCode: Value(d.classificationCode),
          freezeMode: const Value('not_frozen'),
          isActive: Value(d.isActive),
          sortOrder: Value(baseSortOrder + i),
        ));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Template applied! ${_drafts.length} items added to ${widget.employee.fullName}'),
        backgroundColor: Colors.green.shade700,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 620),
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined,
                      size: 22, color: Color(0xFF1B2235)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step == 1
                            ? 'Apply Template'
                            : 'Apply: ${_selected?.templateName ?? ''}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'To: ${widget.employee.fullName}',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Step $_step of 2',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.primary)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: Icon(Icons.close,
                        size: 20,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: _step == 1
                  ? _buildStep1(cs, isDark)
                  : _buildStep2(cs, isDark),
            ),

            // ── Footer ───────────────────────────────────────────────────────
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              child: Row(
                children: [
                  if (_step == 2)
                    OutlinedButton(
                      onPressed:
                          _applying ? null : () => setState(() => _step = 1),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      child:
                          const Text('Back', style: TextStyle(fontSize: 13)),
                    ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child:
                        const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  if (_step == 1)
                    FilledButton.icon(
                      onPressed: _selected == null ? null : _goToStep2,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Next',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B2235),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF1B2235).withValues(alpha: 0.3),
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _applying ? null : _apply,
                      icon: _applying
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(
                        _applying ? 'Applying…' : 'Apply to Employee',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B2235),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Template picker ────────────────────────────────────────────────

  Widget _buildStep1(ColorScheme cs, bool isDark) {
    if (_loadingTemplates) return const Center(child: CircularProgressIndicator());
    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined,
                size: 40, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('No templates available.',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 6),
            Text('Create a template first from the Templates section.',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _templates.length,
      itemBuilder: (_, i) {
        final t = _templates[i];
        final items = _templateItems[t.id] ?? [];
        final allowCount =
            items.where((x) => x.componentType == 'allowance').length;
        final dedCount =
            items.where((x) => x.componentType == 'deduction').length;
        final isSelected = _selected?.id == t.id;

        return InkWell(
          onTap: () => setState(() => _selected = t),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1B2235).withValues(alpha: 0.06)
                  : (isDark ? const Color(0xFF2A2A3E) : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1B2235)
                    : cs.outlineVariant.withValues(alpha: 0.4),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                _RadioDot(selected: isSelected),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.templateName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      if (t.description != null &&
                          t.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(t.description!,
                            style: TextStyle(
                                fontSize: 11,
                                color:
                                    cs.onSurface.withValues(alpha: 0.5))),
                      ],
                      const SizedBox(height: 6),
                      Row(children: [
                        _chip('$allowCount Allowances',
                            const Color(0xFF27AE60)),
                        const SizedBox(width: 6),
                        _chip('$dedCount Deductions', const Color(0xFFE53E3E)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Step 2: Review & set amounts ───────────────────────────────────────────

  Widget _buildStep2(ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Apply mode selector
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          color: isDark
              ? const Color(0xFF1E1E2E)
              : const Color(0xFFF8FAFC),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apply Mode',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.65))),
              const SizedBox(height: 8),
              Row(children: [
                _modeOption(
                  'add',
                  'Add to existing',
                  'Keeps $_existingCount existing component${_existingCount == 1 ? '' : 's'}, adds template items',
                  cs,
                ),
                const SizedBox(width: 12),
                _modeOption(
                  'replace',
                  'Replace existing',
                  _existingCount > 0
                      ? 'Removes $_existingCount existing component${_existingCount == 1 ? '' : 's'} first'
                      : 'No existing components to remove',
                  cs,
                  warning: _existingCount > 0,
                ),
              ]),
            ],
          ),
        ),
        Divider(
            height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),

        // Warning hint
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Text(
            'Set the actual amount for each item. Fields highlighted in orange still show the template default.',
            style: TextStyle(
                fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ),

        // Items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            itemCount: _drafts.length,
            itemBuilder: (_, i) =>
                _buildDraftRow(_drafts[i], i, cs, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildDraftRow(
      _ItemDraft d, int index, ColorScheme cs, bool isDark) {
    final sectionLabel = d.componentType == 'deduction'
        ? 'Deduction'
        : d.allowanceSection == 'other'
            ? 'Other'
            : 'Regular';
    final sectionColor = d.componentType == 'deduction'
        ? const Color(0xFFE53E3E)
        : d.allowanceSection == 'other'
            ? const Color(0xFF7B68EE)
            : const Color(0xFF27AE60);
    final isDefault = d.amount == d.defaultValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: sectionColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(5),
              border:
                  Border.all(color: sectionColor.withValues(alpha: 0.2)),
            ),
            child: Text(sectionLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: sectionColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                if (d.classificationCode != null)
                  Text(d.classificationCode!,
                      style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontFamily: 'monospace')),
              ],
            ),
          ),
          Text(
            d.valueType == 'percentage' ? '%' : 'Fixed',
            style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.45)),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 140,
            child: TextField(
              controller: d.ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 9),
                hintText: d.valueType == 'percentage' ? '0' : '0',
                suffixText: d.valueType == 'percentage' ? '%' : 'PKR',
                filled: isDefault,
                fillColor: Colors.orange.withValues(alpha: 0.08),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDefault
                        ? Colors.orange.withValues(alpha: 0.5)
                        : cs.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: cs.primary),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v) ?? 0.0;
                setState(() {
                  _drafts[index] = d.withAmount(parsed);
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: d.isActive,
            onChanged: (v) {
              setState(() => _drafts[index] = d.withActive(v));
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _modeOption(String value, String label, String desc, ColorScheme cs,
      {bool warning = false}) {
    final selected = _applyMode == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _applyMode = value),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF1B2235).withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1B2235)
                  : cs.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 4),
                child: _RadioDot(selected: selected),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(desc,
                        style: TextStyle(
                          fontSize: 11,
                          color: warning && selected
                              ? Colors.orange.shade700
                              : cs.onSurface.withValues(alpha: 0.5),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Item draft model ──────────────────────────────────────────────────────────

class _ItemDraft {
  final String name;
  final String componentType;
  final String? allowanceSection;
  final String valueType;
  final double defaultValue;
  final double amount;
  final String? classificationCode;
  final bool isActive;
  final TextEditingController ctrl;

  _ItemDraft._({
    required this.name,
    required this.componentType,
    this.allowanceSection,
    required this.valueType,
    required this.defaultValue,
    required this.amount,
    this.classificationCode,
    required this.isActive,
    required this.ctrl,
  });

  factory _ItemDraft.fromTemplateItem(SalaryTemplateItem item) {
    final ctrl = TextEditingController(
        text: item.defaultValue.toStringAsFixed(0));
    return _ItemDraft._(
      name: item.name,
      componentType: item.componentType,
      allowanceSection: item.allowanceSection,
      valueType: item.valueType,
      defaultValue: item.defaultValue,
      amount: item.defaultValue,
      classificationCode: item.classificationCode,
      isActive: item.isActive,
      ctrl: ctrl,
    );
  }

  _ItemDraft withAmount(double newAmount) {
    ctrl.value = ctrl.value.copyWith(text: newAmount.toStringAsFixed(0));
    return _ItemDraft._(
      name: name,
      componentType: componentType,
      allowanceSection: allowanceSection,
      valueType: valueType,
      defaultValue: defaultValue,
      amount: newAmount,
      classificationCode: classificationCode,
      isActive: isActive,
      ctrl: ctrl,
    );
  }

  _ItemDraft withActive(bool newActive) => _ItemDraft._(
    name: name,
    componentType: componentType,
    allowanceSection: allowanceSection,
    valueType: valueType,
    defaultValue: defaultValue,
    amount: amount,
    classificationCode: classificationCode,
    isActive: newActive,
    ctrl: ctrl,
  );
}

// ── Custom radio dot (avoids deprecated Radio widget) ─────────────────────────

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF1B2235) : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 5 : 2,
        ),
      ),
    );
  }
}
