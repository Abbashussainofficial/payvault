import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/database.dart';

class TemplateEditScreen extends StatefulWidget {
  final SalaryTemplate? template;
  const TemplateEditScreen({this.template, super.key});

  @override
  State<TemplateEditScreen> createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends State<TemplateEditScreen> {
  final _db = AppDatabase.instance;
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  List<SalaryTemplateItem> _regularItems = [];
  List<SalaryTemplateItem> _otherItems = [];
  List<SalaryTemplateItem> _deductionItems = [];

  bool get _isEdit => widget.template != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.template!.templateName;
      _descCtrl.text = widget.template!.description ?? '';
      _loadItems();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await _db.salaryTemplatesDao.getItemsByTemplate(widget.template!.id);
    if (!mounted) return;
    setState(() {
      _regularItems = items.where((i) => i.componentType == 'allowance' && i.allowanceSection == 'regular').toList();
      _otherItems = items.where((i) => i.componentType == 'allowance' && i.allowanceSection == 'other').toList();
      _deductionItems = items.where((i) => i.componentType == 'deduction').toList();
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template name is required')),
      );
      return;
    }
    final totalItems = _regularItems.length + _otherItems.length + _deductionItems.length;
    if (totalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to save the template')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now().toIso8601String();
      if (_isEdit) {
        await _db.salaryTemplatesDao.updateTemplate(
          widget.template!.copyWith(
            templateName: name,
            description: Value(_descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim()),
            updatedAt: now,
          ),
        );
      } else {
        final newId = await _db.salaryTemplatesDao.insertTemplate(SalaryTemplatesCompanion(
          templateName: Value(name),
          description: Value(_descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim()),
          category: const Value('pedo'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
        // Insert in-memory items for new template
        final allItems = [
          ..._regularItems.map((i) => i.copyWith(templateId: newId)),
          ..._otherItems.map((i) => i.copyWith(templateId: newId)),
          ..._deductionItems.map((i) => i.copyWith(templateId: newId)),
        ];
        for (final item in allItems) {
          await _db.salaryTemplatesDao.insertItem(SalaryTemplateItemsCompanion(
            templateId: Value(item.templateId),
            name: Value(item.name),
            componentType: Value(item.componentType),
            allowanceSection: Value(item.allowanceSection),
            valueType: Value(item.valueType),
            defaultValue: Value(item.defaultValue),
            classificationCode: Value(item.classificationCode),
            sortOrder: Value(item.sortOrder),
            isActive: Value(item.isActive),
          ));
        }
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addItem(String componentType, String? allowanceSection) async {
    final item = await showDialog<_TemplateItemDraft>(
      context: context,
      builder: (_) => _TemplateItemDialog(
        componentType: componentType,
        allowanceSection: allowanceSection,
      ),
    );
    if (item == null || !mounted) return;

    if (_isEdit) {
      // Save directly to DB
      final sortOrder = _getNextSortOrder(componentType, allowanceSection);
      final id = await _db.salaryTemplatesDao.insertItem(SalaryTemplateItemsCompanion(
        templateId: Value(widget.template!.id),
        name: Value(item.name),
        componentType: Value(componentType),
        allowanceSection: Value(allowanceSection),
        valueType: Value(item.valueType),
        defaultValue: Value(item.defaultValue),
        classificationCode: Value(item.classificationCode),
        sortOrder: Value(sortOrder),
        isActive: const Value(true),
      ));
      final inserted = SalaryTemplateItem(
        id: id,
        templateId: widget.template!.id,
        name: item.name,
        componentType: componentType,
        allowanceSection: allowanceSection,
        valueType: item.valueType,
        defaultValue: item.defaultValue,
        classificationCode: item.classificationCode,
        sortOrder: sortOrder,
        isActive: true,
      );
      setState(() {
        if (componentType == 'allowance' && allowanceSection == 'regular') {
          _regularItems = [..._regularItems, inserted];
        } else if (componentType == 'allowance' && allowanceSection == 'other') {
          _otherItems = [..._otherItems, inserted];
        } else {
          _deductionItems = [..._deductionItems, inserted];
        }
      });
    } else {
      // Store in-memory until save
      final sortOrder = _getNextSortOrder(componentType, allowanceSection);
      final draft = SalaryTemplateItem(
        id: 0,
        templateId: 0,
        name: item.name,
        componentType: componentType,
        allowanceSection: allowanceSection,
        valueType: item.valueType,
        defaultValue: item.defaultValue,
        classificationCode: item.classificationCode,
        sortOrder: sortOrder,
        isActive: true,
      );
      setState(() {
        if (componentType == 'allowance' && allowanceSection == 'regular') {
          _regularItems = [..._regularItems, draft];
        } else if (componentType == 'allowance' && allowanceSection == 'other') {
          _otherItems = [..._otherItems, draft];
        } else {
          _deductionItems = [..._deductionItems, draft];
        }
      });
    }
  }

  int _getNextSortOrder(String componentType, String? allowanceSection) {
    if (componentType == 'allowance' && allowanceSection == 'regular') return _regularItems.length;
    if (componentType == 'allowance' && allowanceSection == 'other') return _otherItems.length;
    return _deductionItems.length;
  }

  Future<void> _editItem(SalaryTemplateItem existing) async {
    final draft = await showDialog<_TemplateItemDraft>(
      context: context,
      builder: (_) => _TemplateItemDialog(
        componentType: existing.componentType,
        allowanceSection: existing.allowanceSection,
        existing: existing,
      ),
    );
    if (draft == null || !mounted) return;

    final updated = existing.copyWith(
      name: draft.name,
      valueType: draft.valueType,
      defaultValue: draft.defaultValue,
      classificationCode: Value(draft.classificationCode),
    );

    if (_isEdit && existing.id != 0) {
      await _db.salaryTemplatesDao.updateItem(updated);
    }

    setState(() {
      _replaceInList(existing, updated);
    });
  }

  void _replaceInList(SalaryTemplateItem old, SalaryTemplateItem updated) {
    _regularItems = _regularItems.map((i) => i.id == old.id && i.sortOrder == old.sortOrder ? updated : i).toList();
    _otherItems = _otherItems.map((i) => i.id == old.id && i.sortOrder == old.sortOrder ? updated : i).toList();
    _deductionItems = _deductionItems.map((i) => i.id == old.id && i.sortOrder == old.sortOrder ? updated : i).toList();
  }

  Future<void> _deleteItem(SalaryTemplateItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${item.name}" from template?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (_isEdit && item.id != 0) {
      await _db.salaryTemplatesDao.deleteItem(item.id);
    }
    setState(() {
      _regularItems = _regularItems.where((i) => i != item).toList();
      _otherItems = _otherItems.where((i) => i != item).toList();
      _deductionItems = _deductionItems.where((i) => i != item).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalItems = _regularItems.length + _otherItems.length + _deductionItems.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header
          Container(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context, false),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.arrow_back_ios_new, size: 15, color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEdit ? 'Edit Template' : 'New Template',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined, size: 17),
                  label: Text(
                    _saving ? 'Saving…' : 'Save Template',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
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
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Name + Description card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Template Name *', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(hintText: 'e.g. Grade 17 - Standard Package'),
                        ),
                        const SizedBox(height: 14),
                        Text('Description (Optional)', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(hintText: 'Brief description of this template'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Regular Allowances section
                  _SectionTable(
                    title: 'Regular Allowances',
                    headerColor: const Color(0xFF27AE60),
                    items: _regularItems,
                    onAdd: () => _addItem('allowance', 'regular'),
                    onEdit: _editItem,
                    onDelete: _deleteItem,
                    isDark: isDark,
                    cs: cs,
                  ),
                  const SizedBox(height: 16),

                  // Other Allowances section
                  _SectionTable(
                    title: 'Other Allowances',
                    headerColor: const Color(0xFF7B68EE),
                    items: _otherItems,
                    onAdd: () => _addItem('allowance', 'other'),
                    onEdit: _editItem,
                    onDelete: _deleteItem,
                    isDark: isDark,
                    cs: cs,
                  ),
                  const SizedBox(height: 16),

                  // Deductions section
                  _SectionTable(
                    title: 'Deductions',
                    headerColor: const Color(0xFFE53E3E),
                    items: _deductionItems,
                    onAdd: () => _addItem('deduction', null),
                    onEdit: _editItem,
                    onDelete: _deleteItem,
                    isDark: isDark,
                    cs: cs,
                  ),
                  const SizedBox(height: 16),

                  // Summary footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 10),
                        Text(
                          '$totalItems items total: ${_regularItems.length} Regular + ${_otherItems.length} Other Allowances + ${_deductionItems.length} Deductions',
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55)),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.save_outlined, size: 16),
                          label: const Text('Save Template', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1B2235),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        ],
      ),
    );
  }
}

// ── Section table ─────────────────────────────────────────────────────────────

class _SectionTable extends StatelessWidget {
  final String title;
  final Color headerColor;
  final List<SalaryTemplateItem> items;
  final VoidCallback onAdd;
  final ValueChanged<SalaryTemplateItem> onEdit;
  final ValueChanged<SalaryTemplateItem> onDelete;
  final bool isDark;
  final ColorScheme cs;

  const _SectionTable({
    required this.title,
    required this.headerColor,
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(width: 3, height: 16,
                    decoration: BoxDecoration(color: headerColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: headerColor)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${items.length} items',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: headerColor)),
                ),
                const Spacer(),
                InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.add_circle_outline, size: 18, color: cs.primary),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 4, child: _hText('NAME', cs)),
                Expanded(flex: 2, child: _hText('CODE', cs)),
                Expanded(flex: 2, child: _hText('TYPE', cs, center: true)),
                Expanded(flex: 2, child: _hText('DEFAULT VALUE', cs, center: true)),
                const SizedBox(width: 76),
              ],
            ),
          ),
          if (items.isEmpty)
            InkWell(
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(Icons.add_circle_outline, size: 28, color: cs.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    Text('No items yet — tap + to add',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              ),
            ),
          ...items.map((item) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(item.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.classificationCode ?? '—',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5),
                            fontFamily: 'monospace'),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.valueType == 'percentage' ? '%' : 'Rs.',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.valueType == 'percentage'
                            ? '${item.defaultValue.toStringAsFixed(0)}%'
                            : 'Rs. ${item.defaultValue.toStringAsFixed(0)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.7)),
                      ),
                    ),
                    SizedBox(
                      width: 76,
                      child: _TemplateItemActionButtons(
                        onEdit: () => onEdit(item),
                        onDelete: () => onDelete(item),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.25)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _hText(String text, ColorScheme cs, {bool center = false}) => Text(
    text,
    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
        color: cs.onSurface.withValues(alpha: 0.45)),
    textAlign: center ? TextAlign.center : TextAlign.start,
  );
}

// ── Template item action buttons [✎ | 🗑] ────────────────────────────────────

class _TemplateItemActionButtons extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDark;

  const _TemplateItemActionButtons({
    required this.onEdit,
    required this.onDelete,
    required this.isDark,
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
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: onEdit,
            tooltip: 'Edit',
            color: Colors.blue.shade600,
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

// ── Template item dialog ──────────────────────────────────────────────────────

class _TemplateItemDraft {
  final String name;
  final String valueType;
  final double defaultValue;
  final String? classificationCode;
  _TemplateItemDraft({required this.name, required this.valueType, required this.defaultValue, this.classificationCode});
}

class _TemplateItemDialog extends StatefulWidget {
  final String componentType;
  final String? allowanceSection;
  final SalaryTemplateItem? existing;
  const _TemplateItemDialog({required this.componentType, this.allowanceSection, this.existing});

  @override
  State<_TemplateItemDialog> createState() => _TemplateItemDialogState();
}

class _TemplateItemDialogState extends State<_TemplateItemDialog> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  String _valueType = 'percentage';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _codeCtrl.text = widget.existing!.classificationCode ?? '';
      _valueCtrl.text = widget.existing!.defaultValue.toStringAsFixed(0);
      _valueType = widget.existing!.valueType;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final value = double.tryParse(_valueCtrl.text.trim()) ?? 0.0;
    if (name.isEmpty) return;
    Navigator.pop(context, _TemplateItemDraft(
      name: name,
      valueType: _valueType,
      defaultValue: value,
      classificationCode: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAllowance = widget.componentType == 'allowance';
    final sectionLabel = widget.allowanceSection == 'regular'
        ? 'Regular Allowance'
        : widget.allowanceSection == 'other'
            ? 'Other Allowance'
            : 'Deduction';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.existing != null ? 'Edit $sectionLabel' : 'Add $sectionLabel',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(isAllowance ? 'Allowance Name' : 'Deduction Name',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: isAllowance ? 'e.g. House Rent' : 'e.g. Income Tax',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 14),
                  Text('Classification Code (Optional)',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. 02200'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _typeBtn('Percentage', 'percentage', cs),
                                const SizedBox(width: 8),
                                _typeBtn('Fixed', 'fixed', cs),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Default Value', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _valueCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              decoration: InputDecoration(
                                hintText: _valueType == 'percentage' ? '10' : '5000',
                                suffixText: _valueType == 'percentage' ? '%' : 'PKR',
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Default value is a suggested starting point — you set the actual amount per employee when applying.',
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2235),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      widget.existing != null ? 'Save Changes' : 'Add Item',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _typeBtn(String label, String value, ColorScheme cs) {
    final selected = _valueType == value;
    return InkWell(
      onTap: () => setState(() => _valueType = value),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 1.5 : 1),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
        )),
      ),
    );
  }
}
