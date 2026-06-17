import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';

// ── Parsed backup payload ─────────────────────────────────────────────────────

class BackupMeta {
  final DateTime exportedAt;
  final int employeeCount;
  final int componentCount;
  final int recordCount;
  final List<Map<String, dynamic>> employees;
  final List<Map<String, dynamic>> components;
  final List<Map<String, dynamic>> records;

  const BackupMeta({
    required this.exportedAt,
    required this.employeeCount,
    required this.componentCount,
    required this.recordCount,
    required this.employees,
    required this.components,
    required this.records,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class BackupService {
  BackupService._();

  static final _db = AppDatabase.instance;
  static const _version = 1;

  // ── File dialogs ────────────────────────────────────────────────────────────

  static Future<String?> chooseSavePath() async {
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save PayVault Backup',
      fileName: 'PayVault_$ts.pvault',
      type: FileType.custom,
      allowedExtensions: ['pvault'],
    );
  }

  static Future<String?> chooseImportPath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pvault'],
      allowMultiple: false,
      dialogTitle: 'Open PayVault Backup',
    );
    return result?.files.single.path;
  }

  // ── Export ──────────────────────────────────────────────────────────────────

  static Future<void> exportTo(String path) async {
    final employees = await _db.employeesDao.getAllEmployees();
    final components = await _db.salaryComponentsDao.getAllComponents();
    final records = await _db.payrollRecordsDao.getAllRecords();

    final payload = <String, dynamic>{
      'version': _version,
      'appName': 'PayVault',
      'exportedAt': DateTime.now().toIso8601String(),
      'employees': employees.map(_empToJson).toList(),
      'salaryComponents': components.map(_compToJson).toList(),
      'payrollRecords': records.map(_recToJson).toList(),
    };

    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );

    await _db.appSettingsDao.updateLastBackupDate(DateTime.now().toIso8601String());
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  static Future<BackupMeta> parseFile(String path) async {
    final raw = await File(path).readAsString(encoding: utf8);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    if (json['appName'] != 'PayVault') {
      throw const FormatException('Not a valid PayVault backup file.');
    }
    final version = json['version'] as int? ?? 0;
    if (version != _version) {
      throw FormatException('Unsupported backup version ($version). Expected $_version.');
    }

    final emps = (json['employees'] as List).cast<Map<String, dynamic>>();
    final comps = (json['salaryComponents'] as List).cast<Map<String, dynamic>>();
    final recs = (json['payrollRecords'] as List).cast<Map<String, dynamic>>();
    final exportedAt =
        DateTime.tryParse(json['exportedAt'] as String? ?? '') ?? DateTime.now();

    return BackupMeta(
      exportedAt: exportedAt,
      employeeCount: emps.length,
      componentCount: comps.length,
      recordCount: recs.length,
      employees: emps,
      components: comps,
      records: recs,
    );
  }

  static Future<void> restoreFrom(BackupMeta meta) async {
    await _db.transaction(() async {
      await _db.clearAll();

      for (final e in meta.employees) {
        await _db.into(_db.employees).insert(EmployeesCompanion(
          id: Value(e['id'] as int),
          employeeId: Value(e['employeeId'] as String),
          fullName: Value(e['fullName'] as String),
          designation: Value(e['designation'] as String),
          department: Value(e['department'] as String),
          bpsGrade: Value(e['bpsGrade'] as String?),
          contactNumber: Value(e['contactNumber'] as String?),
          cnic: Value(e['cnic'] as String?),
          joiningDate: Value(e['joiningDate'] as String),
          leavingDate: Value(e['leavingDate'] as String?),
          status: Value(e['status'] as String),
          category: Value(e['category'] as String),
          baseSalary: Value((e['baseSalary'] as num).toDouble()),
          createdAt: Value(e['createdAt'] as String),
        ));
      }

      for (final c in meta.components) {
        await _db.into(_db.salaryComponents).insert(SalaryComponentsCompanion(
          id: Value(c['id'] as int),
          employeeId: Value(c['employeeId'] as int),
          name: Value(c['name'] as String),
          componentType: Value(c['componentType'] as String),
          valueType: Value(c['valueType'] as String),
          value: Value((c['value'] as num).toDouble()),
          classificationCode: Value(c['classificationCode'] as String?),
          freezeMode: Value(c['freezeMode'] as String),
          frozenAmount: Value(
            c['frozenAmount'] == null
                ? null
                : (c['frozenAmount'] as num).toDouble(),
          ),
          frozenBase: Value(
            c['frozenBase'] == null ? null : (c['frozenBase'] as num).toDouble(),
          ),
          freezeDate: Value(c['freezeDate'] as String?),
          isActive: Value(c['isActive'] as bool),
          sortOrder: Value(c['sortOrder'] as int),
        ));
      }

      for (final r in meta.records) {
        await _db.into(_db.payrollRecords).insert(PayrollRecordsCompanion(
          id: Value(r['id'] as int),
          employeeId: Value(r['employeeId'] as int),
          month: Value(r['month'] as int),
          year: Value(r['year'] as int),
          baseSalary: Value((r['baseSalary'] as num).toDouble()),
          totalAllowances: Value((r['totalAllowances'] as num).toDouble()),
          totalDeductions: Value((r['totalDeductions'] as num).toDouble()),
          netSalary: Value((r['netSalary'] as num).toDouble()),
          salarySnapshot: Value(r['salarySnapshot'] as String),
          isLocked: Value(r['isLocked'] as bool),
          processedAt: Value(r['processedAt'] as String),
        ));
      }
    });
  }

  // ── Serializers ─────────────────────────────────────────────────────────────

  static Map<String, dynamic> _empToJson(Employee e) => {
        'id': e.id,
        'employeeId': e.employeeId,
        'fullName': e.fullName,
        'designation': e.designation,
        'department': e.department,
        'bpsGrade': e.bpsGrade,
        'contactNumber': e.contactNumber,
        'cnic': e.cnic,
        'joiningDate': e.joiningDate,
        'leavingDate': e.leavingDate,
        'status': e.status,
        'category': e.category,
        'baseSalary': e.baseSalary,
        'createdAt': e.createdAt,
      };

  static Map<String, dynamic> _compToJson(SalaryComponent c) => {
        'id': c.id,
        'employeeId': c.employeeId,
        'name': c.name,
        'componentType': c.componentType,
        'valueType': c.valueType,
        'value': c.value,
        'classificationCode': c.classificationCode,
        'freezeMode': c.freezeMode,
        'frozenAmount': c.frozenAmount,
        'frozenBase': c.frozenBase,
        'freezeDate': c.freezeDate,
        'isActive': c.isActive,
        'sortOrder': c.sortOrder,
      };

  static Map<String, dynamic> _recToJson(PayrollRecord r) => {
        'id': r.id,
        'employeeId': r.employeeId,
        'month': r.month,
        'year': r.year,
        'baseSalary': r.baseSalary,
        'totalAllowances': r.totalAllowances,
        'totalDeductions': r.totalDeductions,
        'netSalary': r.netSalary,
        'salarySnapshot': r.salarySnapshot,
        'isLocked': r.isLocked,
        'processedAt': r.processedAt,
      };
}
