import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/payroll_snapshot.dart';
import '../../core/utils/salary_calculator.dart';

class ExcelExportService {
  ExcelExportService._();

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _catLabels = {
    'pedo': 'PEDO Employees',
    'security': 'Security Guards',
    'alfajar': 'Al Fajar',
  };

  static final _db = AppDatabase.instance;
  static final _num = NumberFormat('#,##0', 'en_US');
  static String _fmt(double v) => _num.format(v.round());

  static final _thin = Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: ExcelColor.fromHexString('FF000000'),
  );

  // ── A) Single employee: profile + full payroll history ─────────────────────

  static Future<String?> exportSingleEmployee(Employee emp) async {
    final excel = Excel.createExcel();
    _removeDefaultSheet(excel);

    final profile = excel['Profile'];
    _legacyHeader(profile, 0, ['Field', 'Value']);
    final rows = [
      ['Employee ID', emp.employeeId],
      ['Full Name', emp.fullName],
      ['Designation', emp.designation],
      ['Department', emp.department],
      ['BPS Grade', emp.bpsGrade ?? '-'],
      ['Contact Number', emp.contactNumber ?? '-'],
      ['CNIC', emp.cnic ?? '-'],
      ['Joining Date', emp.joiningDate],
      ['Leaving Date', emp.leavingDate ?? '-'],
      ['Status', emp.status],
      ['Category', emp.category],
    ];
    for (var i = 0; i < rows.length; i++) {
      _legacyRow(profile, i + 1,
          [TextCellValue(rows[i][0]), TextCellValue(rows[i][1])]);
    }
    _legacyRow(profile, rows.length + 1,
        [TextCellValue('Base Salary'), DoubleCellValue(emp.baseSalary)]);

    final history = excel['Payroll History'];
    _legacyHeader(history, 0,
        ['Month', 'Year', 'Base Salary', 'Allowances', 'Deductions', 'Net Salary']);
    final records = await _db.payrollRecordsDao.getRecordsByEmployee(emp.id);
    for (var i = 0; i < records.length; i++) {
      final rec = records[i];
      _legacyRow(history, i + 1, [
        TextCellValue(_monthNames[rec.month - 1]),
        IntCellValue(rec.year),
        DoubleCellValue(rec.baseSalary),
        DoubleCellValue(rec.totalAllowances),
        DoubleCellValue(rec.totalDeductions),
        DoubleCellValue(rec.netSalary),
      ]);
    }

    final safeName = emp.fullName.replaceAll(RegExp(r'[^\w]'), '_');
    return _saveExcel(excel, '${emp.employeeId}_${safeName}_Export.xlsx');
  }

  // ── B) All employees in a category ─────────────────────────────────────────

  static Future<String?> exportAllEmployees(String category) async {
    final excel = Excel.createExcel();
    final label = _catLabels[category] ?? category;
    final sheet = excel[label];

    _legacyHeader(sheet, 0, [
      'Employee ID', 'Full Name', 'Designation', 'Department',
      'Status', 'Base Salary', 'Current Net Salary', 'Joining Date',
    ]);

    final employees = await _db.employeesDao.getEmployeesByCategory(category);
    for (var i = 0; i < employees.length; i++) {
      final emp = employees[i];
      final comps =
          await _db.salaryComponentsDao.getComponentsByEmployee(emp.id);
      final net = SalaryCalculator.net(emp.baseSalary, comps, comps);
      _legacyRow(sheet, i + 1, [
        TextCellValue(emp.employeeId),
        TextCellValue(emp.fullName),
        TextCellValue(emp.designation),
        TextCellValue(emp.department),
        TextCellValue(emp.status),
        DoubleCellValue(emp.baseSalary),
        DoubleCellValue(net),
        TextCellValue(emp.joiningDate),
      ]);
    }

    _removeDefaultSheet(excel);
    final ts = DateFormat('yyyyMMdd').format(DateTime.now());
    return _saveExcel(excel, '${label}_AllEmployees_$ts.xlsx');
  }

  // ── C) Monthly payslip for one employee ────────────────────────────────────

  static Future<String?> exportMonthlySingleEmployee(
      Employee emp, int month, int year) async {
    final record = await _db.payrollRecordsDao.getRecord(emp.id, month, year);
    if (record == null) return null;

    final excel = Excel.createExcel();
    _removeDefaultSheet(excel);

    var sheetName = emp.employeeId;
    if (sheetName.length > 31) sheetName = sheetName.substring(0, 31);
    final sheet = excel[sheetName];

    if (emp.category == 'pedo') {
      _buildPedoPayslip(sheet, emp, record, month, year);
    } else {
      _buildStandardPayslip(
          sheet, emp, record, month, year,
          _catLabels[emp.category] ?? emp.category);
    }

    return _saveExcel(
        excel, '${emp.employeeId}_${_monthNames[month - 1]}_${year}_Payslip.xlsx');
  }

  // ── D) Monthly payroll for all employees in a category ─────────────────────

  static Future<String?> exportMonthlyAllEmployees(
      String category, int month, int year) async {
    final label = _catLabels[category] ?? category;
    final excel = Excel.createExcel();
    _removeDefaultSheet(excel);

    final records =
        await _db.payrollRecordsDao.getRecordsByMonthYear(month, year);
    final recMap = {for (final r in records) r.employeeId: r};
    final employees =
        await _db.employeesDao.getEmployeesByCategory(category);

    // Create Summary sheet first so it appears first
    final summarySheet = excel['Summary'];

    final processed = <({Employee emp, PayrollRecord rec})>[];
    for (final emp in employees) {
      final rec = recMap[emp.id];
      if (rec == null) continue;
      processed.add((emp: emp, rec: rec));

      var sheetName = emp.employeeId;
      if (sheetName.length > 31) sheetName = sheetName.substring(0, 31);
      final sheet = excel[sheetName];

      if (category == 'pedo') {
        _buildPedoPayslip(sheet, emp, rec, month, year);
      } else {
        _buildStandardPayslip(sheet, emp, rec, month, year, label);
      }
    }

    _buildSummarySheet(summarySheet, processed, month, year, label);

    final safeCat = label.replaceAll(' ', '_');
    return _saveExcel(
        excel, '${safeCat}_${_monthNames[month - 1]}_${year}_AllPayslips.xlsx');
  }

  // ── Summary sheet ──────────────────────────────────────────────────────────

  static void _buildSummarySheet(
    Sheet sheet,
    List<({Employee emp, PayrollRecord rec})> items,
    int month,
    int year,
    String catLabel,
  ) {
    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 16);

    // Title
    _merge(sheet, 0, 0, 2, '$catLabel — ${_monthNames[month - 1]} $year',
        bold: true, fontSize: 12, align: HorizontalAlign.Center);

    // Header row
    final hBg = ExcelColor.fromHexString('FFBDD7EE');
    _put(sheet, 1, 0, 'Employee ID',
        bold: true, bg: hBg, top: true, bottom: true, left: true);
    _put(sheet, 1, 1, 'Name',
        bold: true, bg: hBg, top: true, bottom: true);
    _put(sheet, 1, 2, 'Net Salary (Rs.)',
        bold: true, bg: hBg, top: true, bottom: true,
        align: HorizontalAlign.Right);

    double grandTotal = 0;
    int row = 2;
    for (final item in items) {
      grandTotal += item.rec.netSalary;
      _put(sheet, row, 0, item.emp.employeeId, left: true, bottom: true);
      _put(sheet, row, 1, item.emp.fullName, bottom: true);
      _put(sheet, row, 2, _fmt(item.rec.netSalary),
          bottom: true, align: HorizontalAlign.Right);
      row++;
    }

    final totBg = ExcelColor.fromHexString('FFE2EFDA');
    _put(sheet, row, 0, '', bold: true,
        bg: totBg, top: true, bottom: true, left: true);
    _put(sheet, row, 1, 'GRAND TOTAL', bold: true,
        bg: totBg, top: true, bottom: true);
    _put(sheet, row, 2, _fmt(grandTotal), bold: true,
        bg: totBg, top: true, bottom: true, align: HorizontalAlign.Right);
  }

  // ── PEDO Pay Bill ──────────────────────────────────────────────────────────

  static void _buildPedoPayslip(
      Sheet sheet, Employee emp, PayrollRecord record, int month, int year) {
    final comps = PayrollComponent.parseSnapshot(record.salarySnapshot);
    final regularAllowances = comps.where((c) => c.type == 'allowance' && (c.section == 'regular' || c.section == null)).toList();
    final otherAllowances   = comps.where((c) => c.type == 'allowance' && c.section == 'other').toList();
    final deductions        = comps.where((c) => c.type == 'deduction').toList();
    final totRegular        = regularAllowances.fold(0.0, (s, c) => s + c.amount);
    final totOther          = otherAllowances.fold(0.0, (s, c) => s + c.amount);
    final period = '${_monthNames[month - 1]}-$year';
    final gross  = record.baseSalary + totRegular + totOther;
    final net = record.netSalary;
    final bpsStr = emp.bpsGrade != null ? 'BPS-${emp.bpsGrade}' : '';
    final dateStr = record.processedAt.isNotEmpty
        ? DateFormat('dd-MM-yyyy')
            .format(DateTime.tryParse(record.processedAt) ?? DateTime.now())
        : '_________';

    sheet.setColumnWidth(0, 48);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 14);

    int r = 0;

    // V. No. / Date — right aligned in cols 2–3
    _plain(sheet, r, 2, 'V. No. _________', align: HorizontalAlign.Right, sz: 9);
    _plain(sheet, r, 3, 'Date   $dateStr', align: HorizontalAlign.Right, sz: 9);
    r += 2; // +1 blank

    // Title block — all merged A–D
    _merge(sheet, r++, 0, 3, 'PAY BILL OF GOVERNMENT OFFICER,',
        bold: true, fontSize: 11, align: HorizontalAlign.Center);
    _merge(sheet, r++, 0, 3, 'GOVERNMENT OF K. P. K',
        bold: true, fontSize: 11, align: HorizontalAlign.Center);
    _merge(sheet, r++, 0, 3,
        'Note:-Government accepts no responsibility for any fraud, '
        'miss-appropriation in respect of money or cheque bill made '
        'over to a messenger.',
        fontSize: 9);
    _merge(sheet, r++, 0, 3,
        'Name of Government Officer  ${emp.fullName}  '
        '${emp.designation}  ${emp.department}',
        fontSize: 9);
    if (bpsStr.isNotEmpty) {
      _merge(sheet, r, 0, 3,
          '($bpsStr)  (${_fmt(emp.baseSalary)})',
          bold: true, fontSize: 9, align: HorizontalAlign.Center);
    }
    r++;
    _merge(sheet, r++, 0, 3,
        'B/Head: Revenue/Profit of PEDO, Service Charged Levied on '
        'Expenditure incurred on',
        fontSize: 9);
    _merge(sheet, r++, 0, 3, '          Dev: Scheme of PEDO.', fontSize: 9);
    _merge(sheet, r++, 0, 3, 'Detailed Function.',
        fontSize: 9, align: HorizontalAlign.Center);
    r++; // blank spacer before table

    // ── Table ────────────────────────────────────────────────────────────────

    _pedoRow(sheet, r++,
        desc: '', code: 'Classification Code',
        rate: 'Monthly Rate', amt: 'Amount',
        bold: true, top: true, bottom: true,
        codeA: HorizontalAlign.Center,
        rateA: HorizontalAlign.Center,
        amtA: HorizontalAlign.Center,
        bg: ExcelColor.fromHexString('FFD9D9D9'));

    _pedoRow(sheet, r++,
        desc: 'Pay for the Month of $period',
        code: '00000', rate: 'Rs.', amt: '');

    _pedoRow(sheet, r++,
        desc: '', code: '011000',
        rate: _fmt(record.baseSalary), amt: _fmt(record.baseSalary),
        rateA: HorizontalAlign.Right, amtA: HorizontalAlign.Right);

    _pedoRow(sheet, r++,
        desc: 'Pay ..........................................',
        code: '01100',
        rate: _fmt(record.baseSalary), amt: _fmt(record.baseSalary),
        rateA: HorizontalAlign.Right, amtA: HorizontalAlign.Right);

    _pedoRow(sheet, r++,
        desc: 'Total Basic  Salary', code: '', rate: '', amt: '',
        bold: true, bottom: true, descA: HorizontalAlign.Center);

    _pedoRow(sheet, r++, desc: '', code: '02000', rate: '', amt: '');

    _pedoRow(sheet, r++,
        desc: 'Regular Allowance-', code: '02200', rate: '', amt: '',
        bold: true, underline: true);

    for (final c in regularAllowances) {
      _pedoRow(sheet, r++,
          desc: c.name, code: c.code ?? '',
          rate: _fmt(c.amount), amt: _fmt(c.amount),
          rateA: HorizontalAlign.Right, amtA: HorizontalAlign.Right);
    }

    _pedoRow(sheet, r++,
        desc: 'Total Regular Allowances', code: '02000',
        rate: _fmt(totRegular), amt: _fmt(totRegular),
        bold: true, bottom: true,
        rateA: HorizontalAlign.Right, amtA: HorizontalAlign.Right);

    _pedoRow(sheet, r++,
        desc: '', code: '03000', rate: '', amt: '', bottom: true);

    _pedoRow(sheet, r++,
        desc: '', code: '00000',
        rate: _fmt(gross), amt: _fmt(gross),
        bold: true, bottom: true,
        rateA: HorizontalAlign.Right, amtA: HorizontalAlign.Right);

    _pedoRow(sheet, r++,
        desc: 'Other Allowance', code: '', rate: '', amt: '',
        bold: true, underline: true);

    if (otherAllowances.isNotEmpty) {
      for (var i = 0; i < otherAllowances.length; i++) {
        final c = otherAllowances[i];
        _pedoRow(sheet, r++,
            desc: '   ${c.name}', code: c.code ?? '',
            rate: _fmt(c.amount), amt: _fmt(c.amount),
            bottom: i == otherAllowances.length - 1,
            rateA: HorizontalAlign.Right, amtA: HorizontalAlign.Right);
      }
    } else {
      _pedoRow(sheet, r++, desc: '', code: '', rate: '', amt: '', bottom: true);
    }

    _pedoRow(sheet, r++,
        desc: 'Less -Fund deduction', code: '', rate: '', amt: '',
        bold: true, underline: true);

    for (var i = 0; i < deductions.length; i++) {
      final c = deductions[i];
      _pedoRow(sheet, r++,
          desc: '   ${c.name}', code: c.code ?? '',
          rate: c.amount <= 0 ? '-' : _fmt(c.amount),
          amt: c.amount <= 0 ? '-' : _fmt(c.amount),
          bottom: i == deductions.length - 1,
          rateA: HorizontalAlign.Right, amtA: HorizontalAlign.Right);
    }

    _pedoRow(sheet, r++,
        desc: 'Total Deduction:................................',
        code: '',
        rate: _fmt(record.totalDeductions), amt: _fmt(record.totalDeductions),
        bold: true, bottom: true,
        rateA: HorizontalAlign.Right, amtA: HorizontalAlign.Right);

    _pedoRow(sheet, r++,
        desc: 'Net Claim......................................',
        code: '', rate: _fmt(net), amt: _fmt(net),
        bold: true, bottom: true,
        rateA: HorizontalAlign.Right, amtA: HorizontalAlign.Right);

    _pedoRow(sheet, r++,
        desc: '     Total Net Amount Payable.......................',
        code: '', rate: _fmt(net), amt: _fmt(net),
        bold: true, top: true, bottom: true,
        descA: HorizontalAlign.Center,
        rateA: HorizontalAlign.Right, amtA: HorizontalAlign.Right);

    // Footer
    r += 2;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r),
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r));
    final sigLine = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r));
    sigLine.value = TextCellValue('________________________');
    sigLine.cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        fontFamily: 'Times New Roman', fontSize: 9);
    r++;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r),
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r));
    final sigLabel = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r));
    sigLabel.value = TextCellValue('Signature of Officer');
    sigLabel.cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        fontFamily: 'Times New Roman', fontSize: 9);
  }

  // ── Standard Payslip (Security / Al Fajar) ─────────────────────────────────

  static void _buildStandardPayslip(Sheet sheet, Employee emp,
      PayrollRecord record, int month, int year, String catLabel) {
    final comps = PayrollComponent.parseSnapshot(record.salarySnapshot);
    final allowances = comps.where((c) => c.type == 'allowance').toList();
    final deductions = comps.where((c) => c.type == 'deduction').toList();
    final monthName = _monthNames[month - 1];

    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 24);
    sheet.setColumnWidth(3, 14);

    int r = 0;

    // Header block
    _merge(sheet, r++, 0, 3, catLabel,
        bold: true, fontSize: 14, align: HorizontalAlign.Center);
    _merge(sheet, r++, 0, 3, 'SALARY SLIP',
        bold: true, fontSize: 12, align: HorizontalAlign.Center);
    _merge(sheet, r++, 0, 3, 'For the Month of $monthName $year',
        fontSize: 11, align: HorizontalAlign.Center);
    r++; // blank

    // Employee details box
    void detRow(int rowIdx, String lLabel, String lVal,
        String rLabel, String rVal) {
      sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx));
      final lc = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx));
      lc.value = TextCellValue('$lLabel: $lVal');
      lc.cellStyle = CellStyle(fontSize: 10,
          leftBorder: _thin, rightBorder: _thin,
          topBorder: _thin, bottomBorder: _thin);

      sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx),
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx));
      final rc = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx));
      rc.value = TextCellValue('$rLabel: $rVal');
      rc.cellStyle = CellStyle(fontSize: 10,
          rightBorder: _thin, topBorder: _thin, bottomBorder: _thin);
    }

    detRow(r++, 'Employee ID', emp.employeeId, 'Name', emp.fullName);
    detRow(r++, 'Designation', emp.designation, 'Department', emp.department);
    detRow(r++, 'Contact', emp.contactNumber ?? '—', 'Status', emp.status);
    r++; // blank

    // Earnings / Deductions table
    final hBg = ExcelColor.fromHexString('FFD9D9D9');
    _put(sheet, r, 0, 'EARNINGS', bold: true, bg: hBg,
        top: true, bottom: true, left: true);
    _put(sheet, r, 1, 'AMOUNT (Rs.)', bold: true, bg: hBg,
        top: true, bottom: true, align: HorizontalAlign.Right);
    _put(sheet, r, 2, 'DEDUCTIONS', bold: true, bg: hBg,
        top: true, bottom: true);
    _put(sheet, r, 3, 'AMOUNT (Rs.)', bold: true, bg: hBg,
        top: true, bottom: true, align: HorizontalAlign.Right);
    r++;

    // Basic salary + first deduction
    _put(sheet, r, 0, 'Basic Salary', bold: true, left: true);
    _put(sheet, r, 1, _fmt(record.baseSalary),
        bold: true, align: HorizontalAlign.Right);
    _put(sheet, r, 2, deductions.isNotEmpty ? deductions[0].name : '');
    _put(sheet, r, 3,
        deductions.isNotEmpty ? _fmt(deductions[0].amount) : '',
        align: HorizontalAlign.Right);
    r++;

    // Allowances zipped with remaining deductions
    final maxRows = allowances.length >
            (deductions.length - 1).clamp(0, 9999)
        ? allowances.length
        : (deductions.length - 1).clamp(0, 9999);
    for (var i = 0; i < maxRows; i++) {
      final allow = i < allowances.length ? allowances[i] : null;
      final deduct =
          (i + 1) < deductions.length ? deductions[i + 1] : null;
      _put(sheet, r, 0, allow?.name ?? '', left: true);
      _put(sheet, r, 1,
          allow != null ? _fmt(allow.amount) : '',
          align: HorizontalAlign.Right);
      _put(sheet, r, 2, deduct?.name ?? '');
      _put(sheet, r, 3,
          deduct != null ? _fmt(deduct.amount) : '',
          align: HorizontalAlign.Right);
      r++;
    }

    // Totals row
    final totBg = ExcelColor.fromHexString('FFEEEEEE');
    _put(sheet, r, 0, 'Total Earnings', bold: true,
        bg: totBg, top: true, bottom: true, left: true);
    _put(sheet, r, 1,
        _fmt(record.baseSalary + record.totalAllowances),
        bold: true, bg: totBg, top: true, bottom: true,
        align: HorizontalAlign.Right);
    _put(sheet, r, 2, 'Total Deductions', bold: true,
        bg: totBg, top: true, bottom: true);
    _put(sheet, r, 3, _fmt(record.totalDeductions), bold: true,
        bg: totBg, top: true, bottom: true, align: HorizontalAlign.Right);
    r++;
    r++; // blank

    // Net salary bar
    final netBg = ExcelColor.fromHexString('FF1F3864');
    final netFg = ExcelColor.fromHexString('FFFFFFFF');
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r),
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r));
    final nlCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r));
    nlCell.value = TextCellValue('NET SALARY PAYABLE');
    nlCell.cellStyle = CellStyle(bold: true, fontSize: 12,
        backgroundColorHex: netBg, fontColorHex: netFg,
        topBorder: _thin, bottomBorder: _thin,
        leftBorder: _thin, rightBorder: _thin);

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r),
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r));
    final naCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r));
    naCell.value = TextCellValue('Rs. ${_fmt(record.netSalary)}');
    naCell.cellStyle = CellStyle(bold: true, fontSize: 12,
        backgroundColorHex: netBg, fontColorHex: netFg,
        horizontalAlign: HorizontalAlign.Right,
        topBorder: _thin, bottomBorder: _thin, rightBorder: _thin);
    r++;
    r++; // blank

    // Footer
    _plain(sheet, r, 0, 'Signature: ________________', sz: 10);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r),
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r));
    final dateCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r));
    dateCell.value = TextCellValue('Date: ________________');
    dateCell.cellStyle =
        CellStyle(horizontalAlign: HorizontalAlign.Right, fontSize: 10);
  }

  // ── Low-level cell helpers ─────────────────────────────────────────────────

  /// Plain cell — no borders, optional font size and alignment.
  static void _plain(Sheet sheet, int row, int col, String text, {
    int? sz,
    HorizontalAlign align = HorizontalAlign.Left,
  }) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(text);
    if (sz != null) {
      cell.cellStyle = CellStyle(fontSize: sz, horizontalAlign: align,
          fontFamily: 'Times New Roman');
    }
  }

  /// Merge a row range and write text.
  static void _merge(Sheet sheet, int row, int startCol, int endCol,
      String text, {
    bool bold = false,
    int fontSize = 10,
    HorizontalAlign align = HorizontalAlign.Left,
  }) {
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: endCol, rowIndex: row));
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = CellStyle(
        bold: bold, fontSize: fontSize,
        horizontalAlign: align, fontFamily: 'Times New Roman');
  }

  /// Write a PEDO table row (4 columns with selective borders).
  static void _pedoRow(Sheet sheet, int row, {
    required String desc,
    required String code,
    required String rate,
    required String amt,
    bool bold = false,
    bool underline = false,
    bool top = false,
    bool bottom = false,
    HorizontalAlign descA = HorizontalAlign.Left,
    HorizontalAlign codeA = HorizontalAlign.Center,
    HorizontalAlign rateA = HorizontalAlign.Center,
    HorizontalAlign amtA = HorizontalAlign.Center,
    ExcelColor? bg,
  }) {
    CellStyle s(HorizontalAlign align, {bool leftEdge = false}) => bg != null
        ? CellStyle(
            fontFamily: 'Times New Roman',
            fontSize: 10,
            bold: bold,
            underline: underline ? Underline.Single : Underline.None,
            horizontalAlign: align,
            leftBorder: leftEdge ? _thin : null,
            rightBorder: _thin,
            topBorder: top ? _thin : null,
            bottomBorder: bottom ? _thin : null,
            backgroundColorHex: bg,
          )
        : CellStyle(
            fontFamily: 'Times New Roman',
            fontSize: 10,
            bold: bold,
            underline: underline ? Underline.Single : Underline.None,
            horizontalAlign: align,
            leftBorder: leftEdge ? _thin : null,
            rightBorder: _thin,
            topBorder: top ? _thin : null,
            bottomBorder: bottom ? _thin : null,
          );

    _write(sheet, row, 0, desc, s(descA, leftEdge: true));
    _write(sheet, row, 1, code, s(codeA));
    _write(sheet, row, 2, rate, s(rateA));
    _write(sheet, row, 3, amt, s(amtA));
  }

  /// Write a standard payslip table cell (right border always present).
  static void _put(Sheet sheet, int row, int col, String text, {
    bool bold = false,
    bool top = false,
    bool bottom = false,
    bool left = false,
    HorizontalAlign align = HorizontalAlign.Left,
    ExcelColor? bg,
    int fontSize = 10,
  }) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = bg != null
        ? CellStyle(
            bold: bold,
            fontSize: fontSize,
            horizontalAlign: align,
            topBorder: top ? _thin : null,
            bottomBorder: bottom ? _thin : null,
            leftBorder: left ? _thin : null,
            rightBorder: _thin,
            backgroundColorHex: bg,
          )
        : CellStyle(
            bold: bold,
            fontSize: fontSize,
            horizontalAlign: align,
            topBorder: top ? _thin : null,
            bottomBorder: bottom ? _thin : null,
            leftBorder: left ? _thin : null,
            rightBorder: _thin,
          );
  }

  static void _write(Sheet sheet, int row, int col, String text, CellStyle style) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = style;
  }

  // ── Legacy helpers for A / B ───────────────────────────────────────────────

  static void _legacyHeader(Sheet sheet, int row, List<String> cols) {
    for (var c = 0; c < cols.length; c++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = TextCellValue(cols[c]);
      cell.cellStyle = CellStyle(bold: true);
    }
  }

  static void _legacyRow(Sheet sheet, int row, List<CellValue> vals) {
    for (var c = 0; c < vals.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
          .value = vals[c];
    }
  }

  static void _removeDefaultSheet(Excel excel) {
    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');
  }

  static Future<String?> _saveExcel(Excel excel, String fileName) async {
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to encode Excel file.');

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Excel File',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      lockParentWindow: true,
    );
    if (savePath == null) return null;

    final finalPath =
        savePath.toLowerCase().endsWith('.xlsx') ? savePath : '$savePath.xlsx';
    await File(finalPath).writeAsBytes(bytes);
    return finalPath;
  }
}
