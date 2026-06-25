import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';

class EmployeeFormScreen extends StatefulWidget {
  final String category;
  final Employee? employee;
  const EmployeeFormScreen({required this.category, this.employee, super.key});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _saveError;

  late final TextEditingController _empIdCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _designationCtrl;
  late final TextEditingController _departmentCtrl; // shown as "Father's Name"
  late final TextEditingController _contactCtrl;
  late final TextEditingController _bpsCtrl;
  late final TextEditingController _cnicCtrl;
  late final TextEditingController _salaryCtrl;

  DateTime? _joiningDate;
  DateTime? _leavingDate;
  String _status = 'active';
  int? _bpsGrade;            // 1-22, stored in bpsGrade as "BPS-X"

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
    _contactCtrl = TextEditingController(text: e?.contactNumber ?? '');
    _cnicCtrl = TextEditingController(text: e?.cnic ?? '');
    _salaryCtrl = TextEditingController(
      text: e != null && e.baseSalary > 0 ? e.baseSalary.toStringAsFixed(0) : '',
    );
    _bpsCtrl = TextEditingController(text: e?.bpsGrade ?? '');
    _status = e?.status ?? 'active';

    // Parse BPS grade number from stored string (e.g. "BPS-17" → 17)
    if (e?.bpsGrade != null) {
      final match = RegExp(r'(\d+)').firstMatch(e!.bpsGrade!);
      _bpsGrade = int.tryParse(match?.group(1) ?? '');
    }

    if (e != null) {
      try { _joiningDate = DateTime.parse(e.joiningDate); } catch (_) {}
      if (e.leavingDate != null) {
        try { _leavingDate = DateTime.parse(e.leavingDate!); } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_empIdCtrl, _nameCtrl, _designationCtrl, _departmentCtrl, _contactCtrl, _bpsCtrl, _cnicCtrl, _salaryCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool isJoining}) async {
    final initial = (isJoining ? _joiningDate : _leavingDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
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
    setState(() { _saving = true; _saveError = null; });
    try {
      final dao = AppDatabase.instance.employeesDao;
      final existing = await dao.getEmployeesByCategory(widget.category);
      final duplicate = existing.any(
        (e) => e.employeeId.trim().toLowerCase() == _empIdCtrl.text.trim().toLowerCase()
            && (_isEdit ? e.id != widget.employee!.id : true),
      );
      if (duplicate) {
        setState(() { _saveError = 'Employee ID already exists in this category.'; _saving = false; });
        return;
      }

      final now = DateTime.now().toIso8601String();
      final salary = double.tryParse(_salaryCtrl.text.trim()) ?? 0.0;
      final bpsStr = _bpsGrade != null ? 'BPS-$_bpsGrade' : (_bpsCtrl.text.trim().isEmpty ? null : _bpsCtrl.text.trim());
      final contactStr = _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim();

      if (_isEdit) {
        final updated = widget.employee!.copyWith(
          employeeId: _empIdCtrl.text.trim(),
          fullName: _nameCtrl.text.trim(),
          designation: _designationCtrl.text.trim(),
          department: _departmentCtrl.text.trim(),
          bpsGrade: Value(bpsStr),
          contactNumber: Value(contactStr),
          cnic: Value(_cnicCtrl.text.trim().isEmpty ? null : _cnicCtrl.text.trim()),
          joiningDate: _joiningDate!.toIso8601String(),
          leavingDate: Value(_leavingDate?.toIso8601String()),
          status: _status,
          baseSalary: salary,
        );
        await dao.updateEmployee(updated);
      } else {
        await dao.insertEmployee(EmployeesCompanion(
          employeeId: Value(_empIdCtrl.text.trim()),
          fullName: Value(_nameCtrl.text.trim()),
          designation: Value(_designationCtrl.text.trim()),
          department: Value(_departmentCtrl.text.trim()),
          bpsGrade: Value(bpsStr),
          contactNumber: Value(contactStr),
          cnic: Value(_cnicCtrl.text.trim().isEmpty ? null : _cnicCtrl.text.trim()),
          joiningDate: Value(_joiningDate!.toIso8601String()),
          leavingDate: Value(_leavingDate?.toIso8601String()),
          status: Value(_status),
          category: Value(widget.category),
          baseSalary: Value(salary),
          createdAt: Value(now),
        ));
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() { _saveError = 'Failed to save: $e'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catLabel = _labels[widget.category] ?? widget.category;
    final pageTitle = _isEdit ? 'Edit Employee' : 'Add New Employee';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ── Header bar ───────────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.arrow_back_ios_new, size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pageTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      '$catLabel / Registration',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.calendar_today_outlined, size: 17, color: cs.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 14),
                Icon(Icons.access_time_outlined, size: 17, color: cs.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: const Color(0xFF1565C0),
                        child: const Text('A', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 7),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface)),
                          Text('Systems Manager', style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withValues(alpha: isDark ? 0.15 : 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Employee Registration Protocol',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Please ensure all financial data, specifically BPS grades and Base Salary, match the current fiscal budget records. CNIC verification is mandatory for payroll processing.',
                                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.65), height: 1.45),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Error banner
                        if (_saveError != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: cs.onErrorContainer, size: 18),
                                const SizedBox(width: 10),
                                Expanded(child: Text(_saveError!, style: TextStyle(color: cs.onErrorContainer))),
                                IconButton(
                                  icon: Icon(Icons.close, size: 16, color: cs.onErrorContainer),
                                  onPressed: () => setState(() => _saveError = null),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Main form card
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Card header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                                child: Row(
                                  children: [
                                    Icon(Icons.person_add_alt_1_outlined, size: 18, color: cs.primary),
                                    const SizedBox(width: 8),
                                    Text('Employee Details',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: cs.outlineVariant.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text('Step 1 of 2',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
                                    ),
                                  ],
                                ),
                              ),

                              Divider(height: 20, indent: 20, endIndent: 20, color: cs.outlineVariant.withValues(alpha: 0.4)),

                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Row 1: Employee ID + Full Name
                                    Row(children: [
                                      Expanded(child: _IconField(
                                        label: 'Employee ID', controller: _empIdCtrl, required: true,
                                        hint: 'PV-2024-001', icon: Icons.fingerprint,
                                      )),
                                      const SizedBox(width: 16),
                                      Expanded(child: _IconField(
                                        label: 'Full Name', controller: _nameCtrl, required: true,
                                        hint: 'John Doe', icon: Icons.person_outline,
                                      )),
                                    ]),
                                    const SizedBox(height: 16),

                                    // Row 2: Designation (left) + Contact Number (right)
                                    Row(children: [
                                      Expanded(child: _IconField(
                                        label: 'Designation', controller: _designationCtrl, required: true,
                                        hint: 'Senior Accountant', icon: Icons.work_outline,
                                      )),
                                      const SizedBox(width: 16),
                                      Expanded(child: _PhoneField(controller: _contactCtrl)),
                                    ]),
                                    const SizedBox(height: 16),

                                    // Row 3: Father's Name + BPS Grade
                                    Row(children: [
                                      Expanded(child: _IconField(
                                        label: "Father's Name", controller: _departmentCtrl, required: false,
                                        hint: 'Richard Doe', icon: Icons.people_outline,
                                      )),
                                      const SizedBox(width: 16),
                                      Expanded(child: _BpsDropdown(
                                        selected: _bpsGrade,
                                        onChanged: (v) => setState(() => _bpsGrade = v),
                                      )),
                                    ]),
                                    const SizedBox(height: 16),

                                    // Row 4: CNIC + Date of Joining
                                    Row(children: [
                                      Expanded(child: _CnicIconField(controller: _cnicCtrl)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _DateIconField(
                                        label: 'Date of Joining *', date: _joiningDate,
                                        icon: Icons.event_available_outlined,
                                        onTap: () => _pickDate(isJoining: true),
                                        onClear: null,
                                      )),
                                    ]),
                                    const SizedBox(height: 16),

                                    // Row 5: Base Salary (full width)
                                    _SalaryField(controller: _salaryCtrl),

                                    const SizedBox(height: 4),
                                    Text(
                                      'The base salary will be used for calculating annual increments and bonuses.',
                                      style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                                    ),

                                    // Status (for edit mode)
                                    if (_isEdit) ...[
                                      const SizedBox(height: 16),
                                      Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
                                      const SizedBox(height: 16),
                                      Row(children: [
                                        Expanded(child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Status', style: Theme.of(context).textTheme.labelMedium),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<String>(
                                              initialValue: _status,
                                              decoration: const InputDecoration(),
                                              items: const [
                                                DropdownMenuItem(value: 'active', child: Text('Active')),
                                                DropdownMenuItem(value: 'left', child: Text('Left')),
                                              ],
                                              onChanged: (v) => setState(() => _status = v ?? _status),
                                            ),
                                          ],
                                        )),
                                        const SizedBox(width: 16),
                                        Expanded(child: _DateIconField(
                                          label: 'Leaving Date', date: _leavingDate,
                                          icon: Icons.event_busy_outlined,
                                          onTap: () => _pickDate(isJoining: false),
                                          onClear: _leavingDate != null ? () => setState(() => _leavingDate = null) : null,
                                        )),
                                      ]),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                side: BorderSide(color: cs.outlineVariant),
                              ),
                              child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_outlined, size: 17),
                              label: Text(_saving ? 'Saving…' : 'Save Employee', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1B2235),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field widgets ─────────────────────────────────────────────────────────────

class _IconField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final String hint;
  final IconData icon;

  const _IconField({
    required this.label,
    required this.controller,
    required this.required,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 17, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
        ),
      ],
    );
  }
}

class _BpsDropdown extends StatelessWidget {
  final int? selected;
  final ValueChanged<int?> onChanged;
  const _BpsDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BPS Grade', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: selected,
          decoration: InputDecoration(
            hintText: 'Select BPS Grade (1 - 22)',
            prefixIcon: Icon(Icons.settings_outlined, size: 17,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          items: List.generate(22, (i) => i + 1).map((g) =>
            DropdownMenuItem(value: g, child: Text('BPS Grade $g')),
          ).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CnicIconField extends StatelessWidget {
  final TextEditingController controller;
  const _CnicIconField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CNIC Number', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, _CnicFormatter()],
          decoration: InputDecoration(
            hintText: 'XXXXX-XXXXXXX-X',
            prefixIcon: Icon(Icons.badge_outlined, size: 17,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            if (v.replaceAll('-', '').length != 13) return 'Must be 13 digits';
            return null;
          },
        ),
      ],
    );
  }
}

class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('-', '');
    if (digits.length > 13) return oldValue;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) buf.write('-');
      buf.write(digits[i]);
    }
    final result = buf.toString();
    return TextEditingValue(text: result, selection: TextSelection.collapsed(offset: result.length));
  }
}

class _DateIconField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateIconField({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formatted = date != null ? DateFormat('MM/dd/yyyy').format(date!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'mm/dd/yyyy',
              prefixIcon: Icon(icon, size: 17, color: cs.onSurface.withValues(alpha: 0.4)),
              suffixIcon: onClear != null
                  ? IconButton(icon: const Icon(Icons.clear, size: 15), onPressed: onClear)
                  : null,
            ),
            child: Text(
              formatted ?? 'mm/dd/yyyy',
              style: TextStyle(
                fontSize: 14,
                color: formatted != null ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Number', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
          decoration: InputDecoration(
            hintText: '03XX-XXXXXXX',
            prefixIcon: Icon(Icons.phone_outlined, size: 17,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final digits = v.replaceAll(RegExp(r'\D'), '');
            if (digits.length < 10 || digits.length > 15) return 'Enter a valid phone number';
            return null;
          },
        ),
      ],
    );
  }
}

class _SalaryField extends StatelessWidget {
  final TextEditingController controller;
  const _SalaryField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Base Salary (PKR)', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 17, color: cs.onSurface.withValues(alpha: 0.4)),
            suffixText: 'PKR',
            suffixStyle: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
