import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import 'template_edit_screen.dart';

class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({super.key});

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  final _db = AppDatabase.instance;
  List<SalaryTemplate> _templates = [];
  Map<int, List<SalaryTemplateItem>> _itemsMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final templates = await _db.salaryTemplatesDao.getAllTemplates();
    final map = <int, List<SalaryTemplateItem>>{};
    for (final t in templates) {
      map[t.id] = await _db.salaryTemplatesDao.getItemsByTemplate(t.id);
    }
    if (mounted) {
      setState(() {
        _templates = templates;
        _itemsMap = map;
        _loading = false;
      });
    }
  }

  Future<void> _createNew() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TemplateEditScreen()),
    );
    if (result == true) _loadData();
  }

  Future<void> _edit(SalaryTemplate t) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TemplateEditScreen(template: t)),
    );
    if (result == true) _loadData();
  }

  Future<void> _rename(SalaryTemplate t) async {
    final ctrl = TextEditingController(text: t.templateName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Template'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Template Name'),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rename')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = ctrl.text.trim();
    if (name.isEmpty || name == t.templateName) return;
    await _db.salaryTemplatesDao.updateTemplate(
      t.copyWith(templateName: name, updatedAt: DateTime.now().toIso8601String()),
    );
    _loadData();
  }

  Future<void> _duplicate(SalaryTemplate t) async {
    final now = DateTime.now().toIso8601String();
    final newId = await _db.salaryTemplatesDao.insertTemplate(
      SalaryTemplatesCompanion(
        templateName: Value('${t.templateName} - Copy'),
        description: Value(t.description),
        category: Value(t.category),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final items = await _db.salaryTemplatesDao.getItemsByTemplate(t.id);
    for (final item in items) {
      await _db.salaryTemplatesDao.insertItem(SalaryTemplateItemsCompanion(
        templateId: Value(newId),
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
    if (!mounted) return;
    final newTemplate = await _db.salaryTemplatesDao.getTemplateById(newId);
    if (newTemplate == null || !mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TemplateEditScreen(template: newTemplate)),
    );
    if (result == true || result == null) _loadData();
  }

  Future<void> _delete(SalaryTemplate t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Delete "${t.templateName}"?\n\nThis will NOT affect any employees who already had this template applied.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
    await _db.salaryTemplatesDao.deleteItemsByTemplate(t.id);
    await _db.salaryTemplatesDao.deleteTemplate(t.id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PEDO EMPLOYEES',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text('Salary Templates',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _createNew,
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('Create New Template', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _templates.isEmpty
                    ? _buildEmptyState(cs, isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _templates.length,
                        itemBuilder: (_, i) => _buildCard(_templates[i], cs, isDark),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.description_outlined, size: 36, color: cs.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text('No templates yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(
            'Create your first template to speed up employee salary setup.',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _createNew,
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Create Template', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B2235),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(SalaryTemplate t, ColorScheme cs, bool isDark) {
    final items = _itemsMap[t.id] ?? [];
    final allowanceCount = items.where((i) => i.componentType == 'allowance').length;
    final deductionCount = items.where((i) => i.componentType == 'deduction').length;
    final updatedDate = DateFormat('d MMM yyyy').format(DateTime.tryParse(t.updatedAt) ?? DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1B2235).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_outlined, size: 22, color: Color(0xFF1B2235)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.templateName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  if (t.description != null && t.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(t.description!,
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                  ],
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _chip('$allowanceCount Allowances', const Color(0xFF27AE60)),
                      const SizedBox(width: 6),
                      _chip('$deductionCount Deductions', const Color(0xFFE53E3E)),
                      const SizedBox(width: 10),
                      Text(
                        'Updated $updatedDate',
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionBtn(Icons.edit_outlined, 'Edit', () => _edit(t), cs),
                _actionBtn(Icons.drive_file_rename_outline, 'Rename', () => _rename(t), cs),
                _actionBtn(Icons.copy_outlined, 'Duplicate', () => _duplicate(t), cs),
                _actionBtn(Icons.delete_outline, 'Delete', () => _delete(t), cs, color: cs.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _actionBtn(IconData icon, String tooltip, VoidCallback onTap, ColorScheme cs, {Color? color}) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 17, color: color ?? cs.onSurface.withValues(alpha: 0.5)),
      visualDensity: VisualDensity.compact,
    );
  }
}
