import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';

class EmployeeFormScreen extends StatefulWidget {
  final String category;
  final Employee? employee; // null = add mode, non-null = edit mode

  const EmployeeFormScreen({required this.category, this.employee, super.key});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _saveError;

  // Controllers
  late final TextEditingController _empIdCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _designationCtrl;
  late final TextEditingController _departmentCtrl;
  late final TextEditingController _bpsCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _cnicCtrl;
  late final TextEditingController _salaryCtrl;

  DateTime? _joiningDate;
  DateTime? _leavingDate;
  String _status = 'active';

  static const _labels = {
    'pedo': 'PEDO Employees',
    'security': 'Security Guards',
    'alfajar': 'Al Fajar',
  };

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _empIdCtrl = TextEditingController(text: e?.employeeId ?? '');
    _nameCtrl = TextEditingController(text: e?.fullName ?? '');
    _designationCtrl = TextEditingController(text: e?.designation ?? '');
    _departmentCtrl = TextEditingController(text: e?.department ?? '');
    _bpsCtrl = TextEditingController(text: e?.bpsGrade ?? '');
    _contactCtrl = TextEditingController(text: e?.contactNumber ?? '');
    _cnicCtrl = TextEditingController(text: e?.cnic ?? '');
    _salaryCtrl = TextEditingController(
      text: e != null && e.baseSalary > 0 ? e.baseSalary.toStringAsFixed(0) : '',
    );
    _status = e?.status ?? 'active';
    if (e != null) {
      try {
        _joiningDate = DateTime.parse(e.joiningDate);
      } catch (_) {}
      if (e.leavingDate != null) {
        try {
          _leavingDate = DateTime.parse(e.leavingDate!);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _empIdCtrl, _nameCtrl, _designationCtrl, _departmentCtrl,
      _bpsCtrl, _contactCtrl, _cnicCtrl, _salaryCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool isJoining}) async {
    final initial =
        (isJoining ? _joiningDate : _leavingDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isJoining) {
        _joiningDate = picked;
      } else {
        _leavingDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_joiningDate == null) {
      setState(() => _saveError = 'Please select a joining date.');
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      final dao = AppDatabase.instance.employeesDao;

      // Uniqueness check: employeeId within category (excluding self if editing)
      final existing = await dao.getEmployeesByCategory(widget.category);
      final duplicate = existing.any(
        (e) =>
            e.employeeId.trim().toLowerCase() ==
                _empIdCtrl.text.trim().toLowerCase() &&
            (_isEdit ? e.id != widget.employee!.id : true),
      );
      if (duplicate) {
        setState(() {
          _saveError = 'Employee ID already exists in this category.';
          _saving = false;
        });
        return;
      }

      final now = DateTime.now().toIso8601String();
      final salary = double.tryParse(_salaryCtrl.text.trim()) ?? 0.0;

      if (_isEdit) {
        final updated = widget.employee!.copyWith(
          employeeId: _empIdCtrl.text.trim(),
          fullName: _nameCtrl.text.trim(),
          designation: _designationCtrl.text.trim(),
          department: _departmentCtrl.text.trim(),
          bpsGrade: Value(_bpsCtrl.text.trim().isEmpty ? null : _bpsCtrl.text.trim()),
          contactNumber: Value(_contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim()),
          cnic: Value(_cnicCtrl.text.trim().isEmpty ? null : _cnicCtrl.text.trim()),
          joiningDate: _joiningDate!.toIso8601String(),
          leavingDate: Value(_leavingDate?.toIso8601String()),
          status: _status,
          baseSalary: salary,
        );
        await dao.updateEmployee(updated);
      } else {
        await dao.insertEmployee(
          EmployeesCompanion(
            employeeId: Value(_empIdCtrl.text.trim()),
            fullName: Value(_nameCtrl.text.trim()),
            designation: Value(_designationCtrl.text.trim()),
            department: Value(_departmentCtrl.text.trim()),
            bpsGrade: Value(_bpsCtrl.text.trim().isEmpty ? null : _bpsCtrl.text.trim()),
            contactNumber: Value(_contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim()),
            cnic: Value(_cnicCtrl.text.trim().isEmpty ? null : _cnicCtrl.text.trim()),
            joiningDate: Value(_joiningDate!.toIso8601String()),
            leavingDate: Value(_leavingDate?.toIso8601String()),
            status: Value(_status),
            category: Value(widget.category),
            baseSalary: Value(salary),
            createdAt: Value(now),
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _saveError = 'Failed to save: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _labels[widget.category] ?? widget.category;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? 'Edit Employee' : 'Add Employee'),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
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
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_saveError != null)
                    _ErrorBanner(message: _saveError!, onDismiss: () => setState(() => _saveError = null)),

                  _SectionTitle('Identity'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'Employee ID',
                          controller: _empIdCtrl,
                          required: true,
                          hint: 'e.g. EMP-001',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Field(
                          label: 'Full Name',
                          controller: _nameCtrl,
                          required: true,
                          hint: 'Full name',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'Designation',
                          controller: _designationCtrl,
                          required: true,
                          hint: 'e.g. Assistant',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Field(
                          label: 'Department',
                          controller: _departmentCtrl,
                          required: false,
                          hint: 'e.g. Administration',
                        ),
                      ),
                    ],
                  ),
                  if (widget.category == 'pedo') ...[
                    const SizedBox(height: 16),
                    _Field(
                      label: 'BPS Grade',
                      controller: _bpsCtrl,
                      required: false,
                      hint: 'e.g. BPS-17',
                    ),
                  ],

                  const SizedBox(height: 24),
                  _SectionTitle('Contact'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'Contact Number',
                          controller: _contactCtrl,
                          required: false,
                          hint: '03XX-XXXXXXX',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _CnicField(controller: _cnicCtrl),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _SectionTitle('Employment'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: 'Joining Date',
                          date: _joiningDate,
                          required: true,
                          onTap: () => _pickDate(isJoining: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _DatePickerField(
                          label: 'Leaving Date',
                          date: _leavingDate,
                          required: false,
                          onTap: () => _pickDate(isJoining: false),
                          onClear:
                              _leavingDate != null
                                  ? () => setState(() => _leavingDate = null)
                                  : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: const InputDecoration(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'active',
                                  child: Text('Active'),
                                ),
                                DropdownMenuItem(
                                  value: 'left',
                                  child: Text('Left'),
                                ),
                              ],
                              onChanged:
                                  (v) => setState(() => _status = v ?? _status),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Field(
                          label: 'Base Salary (PKR)',
                          controller: _salaryCtrl,
                          required: false,
                          hint: '0',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: Text(_saving ? 'Saving…' : 'Save Employee'),
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
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Divider(height: 1, color: cs.outlineVariant),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.label,
    required this.controller,
    required this.required,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(hintText: hint),
          validator:
              required
                  ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                  : null,
        ),
      ],
    );
  }
}

class _CnicField extends StatelessWidget {
  final TextEditingController controller;
  const _CnicField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CNIC', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CnicFormatter(),
          ],
          decoration: const InputDecoration(hintText: '00000-0000000-0'),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            final digits = v.replaceAll('-', '');
            if (digits.length != 13) return 'Must be 13 digits';
            return null;
          },
        ),
      ],
    );
  }
}

class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('-', '');
    if (digits.length > 13) return oldValue;

    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) buf.write('-');
      buf.write(digits[i]);
    }
    final result = buf.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool required;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.required,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formatted = date != null ? DateFormat('dd MMM yyyy').format(date!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select date',
              suffixIcon:
                  onClear != null
                      ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: onClear,
                      )
                      : Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
            ),
            child: Text(
              formatted ?? 'Select date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    formatted != null
                        ? cs.onSurface
                        : cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: cs.onErrorContainer),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: cs.onErrorContainer),
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
