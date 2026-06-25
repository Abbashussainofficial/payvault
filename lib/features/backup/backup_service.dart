import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';

// ── JSON backup payload ───────────────────────────────────────────────────────

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

// ── Excel backup metadata ─────────────────────────────────────────────────────

class ExcelBackupMeta {
  final DateTime backupDate;
  final int totalEmployees;
  final int totalComponents;
  final int totalPayrollRecords;
  final List<Map<String, dynamic>> employees;
  final List<Map<String, dynamic>> components;
  final List<Map<String, dynamic>> records;

  const ExcelBackupMeta({
    required this.backupDate,
    required this.totalEmployees,
    required this.totalComponents,
    required this.totalPayrollRecords,
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

  // ── .pvault file dialogs ────────────────────────────────────────────────────

  static Future<String?> chooseImportPath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pvault'],
      allowMultiple: false,
      dialogTitle: 'Open PayVault Backup (.pvault)',
      lockParentWindow: true,
    );
    return result?.files.single.path;
  }

  // ── .pvault JSON export ─────────────────────────────────────────────────────

  static Future<String?> export() async {
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'PayVault_$ts.pvault';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PayVault Backup',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pvault'],
      lockParentWindow: true,
    );

    if (savePath == null) return null;

    final finalPath =
        savePath.toLowerCase().endsWith('.pvault') ? savePath : '$savePath.pvault';
    await exportTo(finalPath);
    return finalPath;
  }

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

  // ── .pvault JSON import ─────────────────────────────────────────────────────

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
            c['frozenAmount'] == null ? null : (c['frozenAmount'] as num).toDouble(),
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

  // ── Excel export ────────────────────────────────────────────────────────────

  /// Shows a folder-picker dialog and writes all data to a .xlsx backup file.
  /// Returns the saved file path, or null if the user cancelled.
  static Future<String?> exportBackupToExcel() async {
    final employees = await _db.employeesDao.getAllEmployees();
    final components = await _db.salaryComponentsDao.getAllComponents();
    final records = await _db.payrollRecordsDao.getAllRecords();

    final excel = Excel.createExcel();
    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

    _buildEmployeesSheet(excel, employees);
    _buildComponentsSheet(excel, components);
    _buildRecordsSheet(excel, records);
    _buildBackupInfoSheet(excel, employees.length, components.length, records.length);

    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose folder to save backup',
      lockParentWindow: true,
    );
    if (dir == null) return null;

    final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final fileName = 'PayVault_Backup_$dateStr.xlsx';
    final filePath = '$dir${Platform.pathSeparator}$fileName';

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to encode Excel file.');
    await File(filePath).writeAsBytes(bytes);

    await _db.appSettingsDao.updateLastBackupDate(DateTime.now().toIso8601String());
    return filePath;
  }

  static void _buildEmployeesSheet(Excel excel, List<Employee> employees) {
    final sheet = excel['Employees'];
    const headers = [
      'id', 'employeeId', 'fullName', 'designation', 'department',
      'bpsGrade', 'contactNumber', 'cnic', 'joiningDate', 'leavingDate',
      'status', 'category', 'baseSalary', 'createdAt',
    ];
    _writeHeader(sheet, headers);
    for (var i = 0; i < employees.length; i++) {
      final e = employees[i];
      _writeRow(sheet, i + 1, [
        IntCellValue(e.id),
        TextCellValue(e.employeeId),
        TextCellValue(e.fullName),
        TextCellValue(e.designation),
        TextCellValue(e.department),
        TextCellValue(e.bpsGrade ?? ''),
        TextCellValue(e.contactNumber ?? ''),
        TextCellValue(e.cnic ?? ''),
        TextCellValue(e.joiningDate),
        TextCellValue(e.leavingDate ?? ''),
        TextCellValue(e.status),
        TextCellValue(e.category),
        DoubleCellValue(e.baseSalary),
        TextCellValue(e.createdAt),
      ]);
    }
  }

  static void _buildComponentsSheet(Excel excel, List<SalaryComponent> components) {
    final sheet = excel['SalaryComponents'];
    const headers = [
      'id', 'employeeId', 'name', 'componentType', 'valueType',
      'value', 'classificationCode', 'freezeMode', 'frozenAmount',
      'frozenBase', 'freezeDate', 'isActive', 'sortOrder',
    ];
    _writeHeader(sheet, headers);
    for (var i = 0; i < components.length; i++) {
      final c = components[i];
      _writeRow(sheet, i + 1, [
        IntCellValue(c.id),
        IntCellValue(c.employeeId),
        TextCellValue(c.name),
        TextCellValue(c.componentType),
        TextCellValue(c.valueType),
        DoubleCellValue(c.value),
        TextCellValue(c.classificationCode ?? ''),
        TextCellValue(c.freezeMode),
        c.frozenAmount != null ? DoubleCellValue(c.frozenAmount!) : null,
        c.frozenBase != null ? DoubleCellValue(c.frozenBase!) : null,
        TextCellValue(c.freezeDate ?? ''),
        IntCellValue(c.isActive ? 1 : 0),
        IntCellValue(c.sortOrder),
      ]);
    }
  }

  static void _buildRecordsSheet(Excel excel, List<PayrollRecord> records) {
    final sheet = excel['PayrollRecords'];
    const headers = [
      'id', 'employeeId', 'month', 'year', 'baseSalary',
      'totalAllowances', 'totalDeductions', 'netSalary',
      'salarySnapshot', 'isLocked', 'processedAt',
    ];
    _writeHeader(sheet, headers);
    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      _writeRow(sheet, i + 1, [
        IntCellValue(r.id),
        IntCellValue(r.employeeId),
        IntCellValue(r.month),
        IntCellValue(r.year),
        DoubleCellValue(r.baseSalary),
        DoubleCellValue(r.totalAllowances),
        DoubleCellValue(r.totalDeductions),
        DoubleCellValue(r.netSalary),
        TextCellValue(r.salarySnapshot),
        IntCellValue(r.isLocked ? 1 : 0),
        TextCellValue(r.processedAt),
      ]);
    }
  }

  static void _buildBackupInfoSheet(
      Excel excel, int empCount, int compCount, int recCount) {
    final sheet = excel['BackupInfo'];
    _writeHeader(sheet, ['Key', 'Value']);
    _writeRow(sheet, 1, [TextCellValue('backupDate'), TextCellValue(DateTime.now().toIso8601String())]);
    _writeRow(sheet, 2, [TextCellValue('appVersion'), TextCellValue('1.0')]);
    _writeRow(sheet, 3, [TextCellValue('totalEmployees'), IntCellValue(empCount)]);
    _writeRow(sheet, 4, [TextCellValue('totalComponents'), IntCellValue(compCount)]);
    _writeRow(sheet, 5, [TextCellValue('totalPayrollRecords'), IntCellValue(recCount)]);
  }

  static void _writeHeader(Sheet sheet, List<String> cols) {
    final style = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('FFBDD7EE'),
    );
    for (var c = 0; c < cols.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(cols[c]);
      cell.cellStyle = style;
    }
  }

  static void _writeRow(Sheet sheet, int row, List<CellValue?> vals) {
    for (var c = 0; c < vals.length; c++) {
      final v = vals[c];
      if (v != null) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row)).value = v;
      }
    }
  }

  // ── Excel import ────────────────────────────────────────────────────────────

  /// Reads and parses a PayVault Excel backup file.
  /// Throws [FormatException] if the file is not a valid PayVault backup.
  static Future<ExcelBackupMeta> parseExcelBackup(String path) async {
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    if (!excel.tables.containsKey('BackupInfo')) {
      throw const FormatException(
          'Invalid backup file. Please select a valid PayVault backup.');
    }

    // Parse BackupInfo
    DateTime backupDate = DateTime.now();
    final infoSheet = excel.tables['BackupInfo']!;
    for (final row in infoSheet.rows.skip(1)) {
      if (row.every((c) => c?.value == null)) continue;
      final key = _rawCell(row.elementAtOrNull(0))?.toString().trim() ?? '';
      final val = _rawCell(row.elementAtOrNull(1))?.toString().trim() ?? '';
      if (key == 'backupDate') {
        backupDate = DateTime.tryParse(val) ?? DateTime.now();
      }
    }

    final employees = _parseSheet(excel.tables['Employees']);
    final components = _parseSheet(excel.tables['SalaryComponents']);
    final records = _parseSheet(excel.tables['PayrollRecords']);

    return ExcelBackupMeta(
      backupDate: backupDate,
      totalEmployees: employees.length,
      totalComponents: components.length,
      totalPayrollRecords: records.length,
      employees: employees,
      components: components,
      records: records,
    );
  }

  static List<Map<String, dynamic>> _parseSheet(Sheet? sheet) {
    if (sheet == null) return [];
    final rows = sheet.rows;
    if (rows.isEmpty) return [];
    final headers = rows[0]
        .map((c) => _rawCell(c)?.toString().trim() ?? '')
        .toList();
    final result = <Map<String, dynamic>>[];
    for (final row in rows.skip(1)) {
      if (row.every((c) => c?.value == null)) continue;
      final map = <String, dynamic>{};
      for (var i = 0; i < headers.length; i++) {
        if (headers[i].isEmpty) continue;
        map[headers[i]] = _rawCell(row.elementAtOrNull(i));
      }
      result.add(map);
    }
    return result;
  }

  /// Clears all data and restores from the parsed Excel backup inside a
  /// single transaction — rolls back automatically on any failure.
  static Future<void> restoreFromExcelData(ExcelBackupMeta meta) async {
    await _db.transaction(() async {
      await _db.clearAll();

      for (final e in meta.employees) {
        await _db.into(_db.employees).insert(EmployeesCompanion(
          id: Value(_toInt(e['id'])),
          employeeId: Value(_toStr(e['employeeId'])),
          fullName: Value(_toStr(e['fullName'])),
          designation: Value(_toStr(e['designation'])),
          department: Value(_toStr(e['department'])),
          bpsGrade: Value(_toNullableStr(e['bpsGrade'])),
          contactNumber: Value(_toNullableStr(e['contactNumber'])),
          cnic: Value(_toNullableStr(e['cnic'])),
          joiningDate: Value(_toStr(e['joiningDate'])),
          leavingDate: Value(_toNullableStr(e['leavingDate'])),
          status: Value(_toStr(e['status'])),
          category: Value(_toStr(e['category'])),
          baseSalary: Value(_toDouble(e['baseSalary'])),
          createdAt: Value(_toStr(e['createdAt'])),
        ));
      }

      for (final c in meta.components) {
        await _db.into(_db.salaryComponents).insert(SalaryComponentsCompanion(
          id: Value(_toInt(c['id'])),
          employeeId: Value(_toInt(c['employeeId'])),
          name: Value(_toStr(c['name'])),
          componentType: Value(_toStr(c['componentType'])),
          valueType: Value(_toStr(c['valueType'])),
          value: Value(_toDouble(c['value'])),
          classificationCode: Value(_toNullableStr(c['classificationCode'])),
          freezeMode: Value(_toStr(c['freezeMode'])),
          frozenAmount: Value(_toNullableDouble(c['frozenAmount'])),
          frozenBase: Value(_toNullableDouble(c['frozenBase'])),
          freezeDate: Value(_toNullableStr(c['freezeDate'])),
          isActive: Value(_toBool(c['isActive'])),
          sortOrder: Value(_toInt(c['sortOrder'])),
        ));
      }

      for (final r in meta.records) {
        await _db.into(_db.payrollRecords).insert(PayrollRecordsCompanion(
          id: Value(_toInt(r['id'])),
          employeeId: Value(_toInt(r['employeeId'])),
          month: Value(_toInt(r['month'])),
          year: Value(_toInt(r['year'])),
          baseSalary: Value(_toDouble(r['baseSalary'])),
          totalAllowances: Value(_toDouble(r['totalAllowances'])),
          totalDeductions: Value(_toDouble(r['totalDeductions'])),
          netSalary: Value(_toDouble(r['netSalary'])),
          salarySnapshot: Value(_toStr(r['salarySnapshot'])),
          isLocked: Value(_toBool(r['isLocked'])),
          processedAt: Value(_toStr(r['processedAt'])),
        ));
      }
    });
  }

  // ── Cell reading helpers ────────────────────────────────────────────────────

  static dynamic _rawCell(Data? cell) {
    if (cell == null) return null;
    final v = cell.value;
    if (v == null) return null;
    if (v is TextCellValue) return v.value.text ?? '';
    if (v is IntCellValue) return v.value;
    if (v is DoubleCellValue) return v.value;
    if (v is BoolCellValue) return v.value;
    return null;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? 0.0;
  }

  static double? _toNullableDouble(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(s);
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is double) return v != 0;
    final s = v.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  static String _toStr(dynamic v) => v?.toString().trim() ?? '';

  static String? _toNullableStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  // ── JSON serializers ────────────────────────────────────────────────────────

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
