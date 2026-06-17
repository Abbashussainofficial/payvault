import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/database/database.dart';
import '../../core/utils/payroll_snapshot.dart';

class PrintService {
  PrintService._();

  static final _num = NumberFormat('#,##0', 'en_US');
  static String _fmt(double v) => _num.format(v.round());

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _catLabels = {
    'pedo': 'PEDO Employees',
    'security': 'Security Guards',
    'alfajar': 'Al Fajar',
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  static Future<Uint8List> generatePedoPayBill({
    required Employee employee,
    required PayrollRecord record,
    required int month,
    required int year,
    String vNo = '',
  }) async {
    final doc = pw.Document();
    doc.addPage(_buildPedoPage(
      employee: employee,
      record: record,
      month: month,
      year: year,
      vNo: vNo,
    ));
    return doc.save();
  }

  static Future<Uint8List> generateStandardPayslip({
    required Employee employee,
    required PayrollRecord record,
    required int month,
    required int year,
    required String category,
  }) async {
    final doc = pw.Document();
    doc.addPage(_buildStandardPage(
      employee: employee,
      record: record,
      month: month,
      year: year,
      categoryLabel: _catLabels[category] ?? category,
    ));
    return doc.save();
  }

  static Future<Uint8List> generateBulk({
    required List<({Employee employee, PayrollRecord record})> items,
    required int month,
    required int year,
    required String category,
  }) async {
    final doc = pw.Document();
    final isPedo = category == 'pedo';
    final catLabel = _catLabels[category] ?? category;
    for (final item in items) {
      doc.addPage(
        isPedo
            ? _buildPedoPage(
                employee: item.employee,
                record: item.record,
                month: month,
                year: year,
              )
            : _buildStandardPage(
                employee: item.employee,
                record: item.record,
                month: month,
                year: year,
                categoryLabel: catLabel,
              ),
      );
    }
    return doc.save();
  }

  // ── PEDO Pay Bill page ─────────────────────────────────────────────────────

  static pw.Page _buildPedoPage({
    required Employee employee,
    required PayrollRecord record,
    required int month,
    required int year,
    String vNo = '',
  }) {
    final comps = PayrollComponent.parseSnapshot(record.salarySnapshot);
    final allowances = comps.where((c) => c.type == 'allowance').toList();
    final deductions = comps.where((c) => c.type == 'deduction').toList();
    final monthUpper = _monthNames[month - 1].toUpperCase();
    final dateStr = DateFormat('dd-MM-yyyy')
        .format(DateTime.tryParse(record.processedAt) ?? DateTime.now());

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // V.No & date (top right)
          pw.Align(
            alignment: pw.Alignment.topRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('V.No: $vNo',
                    style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text('Date: $dateStr',
                    style: const pw.TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
          pw.SizedBox(height: 6),

          // Title
          pw.Center(
            child: pw.Text(
              'PAY BILL OF GOVERNMENT OFFICER, GOVERNMENT OF K. P. K',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Note: The pay bill should be forwarded to the D.D.O who will fill in the '
              'amount payable after checking and sign it.',
              style: pw.TextStyle(
                  fontSize: 7.5,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 10),

          // Employee info block
          _pedoInfoRow(
            'Name of Government Officer:',
            '${employee.fullName}    ${employee.designation}    ${employee.department}',
          ),
          _pedoInfoRow(
            'BPS: ${employee.bpsGrade ?? '-'}',
            '    Contact: ${employee.contactNumber ?? '-'}',
          ),
          _pedoInfoRow('B/Head:', 'Revenue/Profit of PEDO'),
          pw.Text('Detailed Function.',
              style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 12),

          // Main table
          _buildPedoTable(
            record: record,
            allowances: allowances,
            deductions: deductions,
            monthUpper: monthUpper,
            year: year,
          ),
          pw.SizedBox(height: 28),

          // Signature
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('________________________',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 2),
                pw.Text('Signature of Officer',
                    style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pedoInfoRow(String label, String value) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(children: [
          pw.Text('$label ',
              style:
                  pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ]),
      );

  static pw.Widget _buildPedoTable({
    required PayrollRecord record,
    required List<PayrollComponent> allowances,
    required List<PayrollComponent> deductions,
    required String monthUpper,
    required int year,
  }) {
    const colWidths = {
      0: pw.FlexColumnWidth(3.5),
      1: pw.FixedColumnWidth(90.0),
      2: pw.FixedColumnWidth(68.0),
      3: pw.FixedColumnWidth(78.0),
    };
    const border = pw.TableBorder(
      top: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
      bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
      left: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
      right: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
      horizontalInside: pw.BorderSide(color: PdfColors.grey400, width: 0.4),
      verticalInside: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
    );

    pw.TableRow head(List<String> cells) => pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColors.grey300),
          children: cells
              .map((c) => _pCell(c,
                  bold: true, fontSize: 8.5, vPad: 3))
              .toList(),
        );

    pw.TableRow data(String desc, String code, String rate, String amt,
            {bool bold = false}) =>
        pw.TableRow(children: [
          _pCell(desc, bold: bold),
          _pCell(code, align: pw.TextAlign.center),
          _pCell(rate, align: pw.TextAlign.right),
          _pCell(amt, bold: bold, align: pw.TextAlign.right),
        ]);

    pw.TableRow section(String label, {bool underline = false}) =>
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _pCell(
              label,
              bold: true,
              underline: underline,
            ),
            pw.Container(),
            pw.Container(),
            pw.Container(),
          ],
        );

    return pw.Table(
      border: border,
      columnWidths: colWidths,
      children: [
        head(['Description', 'Classification Code', 'Monthly Rate', 'Amount']),
        data('Pay for the Month of $monthUpper $year', '00000', 'Rs.', ''),
        data('Pay', '011000', '', _fmt(record.baseSalary)),
        data('Personal Pay', '01100', '', ''),
        data('Total Basic Salary', '', '', _fmt(record.baseSalary),
            bold: true),
        section('Regular Allowance:', underline: true),
        ...allowances.map(
          (c) => data(c.name, c.code ?? '', '', _fmt(c.amount)),
        ),
        data('Total Regular Allowances', '02000, 03000, 00000', '',
            _fmt(record.totalAllowances),
            bold: true),
        section('Other Allowance:'),
        section('Less - Fund deduction', underline: true),
        ...deductions.map(
          (c) => data(c.name, c.code ?? '', '', _fmt(c.amount)),
        ),
        data('Total Deduction:', '', '', _fmt(record.totalDeductions),
            bold: true),
        data('Net Claim', '', '', _fmt(record.netSalary), bold: true),
        data('Total Net Amount Payable', '', '', _fmt(record.netSalary),
            bold: true),
      ],
    );
  }

  // ── Standard Payslip page ──────────────────────────────────────────────────

  static pw.Page _buildStandardPage({
    required Employee employee,
    required PayrollRecord record,
    required int month,
    required int year,
    required String categoryLabel,
  }) {
    final comps = PayrollComponent.parseSnapshot(record.salarySnapshot);
    final allowances = comps.where((c) => c.type == 'allowance').toList();
    final deductions = comps.where((c) => c.type == 'deduction').toList();
    final monthName = _monthNames[month - 1];

    // How many middle rows to generate (zip allowances with remaining deductions)
    final maxRows = allowances.length > (deductions.length - 1).clamp(0, 999)
        ? allowances.length
        : (deductions.length - 1).clamp(0, 999);

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Header banner
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'SALARY SLIP',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '$categoryLabel  —  $monthName $year',
                  style: const pw.TextStyle(
                      fontSize: 9.5, color: PdfColors.blueGrey200),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Employee details grid
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _detail('Name', employee.fullName),
                      _detail('Employee ID', employee.employeeId),
                      _detail('Designation', employee.designation),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _detail('Department', employee.department),
                      _detail('CNIC', employee.cnic ?? '—'),
                      _detail('Contact', employee.contactNumber ?? '—'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Earnings / Deductions table
          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.grey400, width: 0.5),
            children: [
              // Column headers
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey100),
                children: [
                  _tHead('EARNINGS'),
                  _tHead('AMOUNT (Rs.)', align: pw.TextAlign.right),
                  _tHead('DEDUCTIONS'),
                  _tHead('AMOUNT (Rs.)', align: pw.TextAlign.right),
                ],
              ),
              // Base salary row + first deduction
              pw.TableRow(children: [
                _tCell('Basic Salary', bold: true),
                _tCell(_fmt(record.baseSalary),
                    bold: true, align: pw.TextAlign.right),
                _tCell(deductions.isNotEmpty ? deductions[0].name : ''),
                _tCell(
                  deductions.isNotEmpty ? _fmt(deductions[0].amount) : '',
                  align: pw.TextAlign.right,
                ),
              ]),
              // Allowance rows zipped with remaining deductions
              ...List.generate(maxRows, (i) {
                final allow =
                    i < allowances.length ? allowances[i] : null;
                final deduct = (i + 1) < deductions.length
                    ? deductions[i + 1]
                    : null;
                return pw.TableRow(children: [
                  _tCell(allow?.name ?? ''),
                  _tCell(
                    allow != null ? _fmt(allow.amount) : '',
                    align: pw.TextAlign.right,
                  ),
                  _tCell(deduct?.name ?? ''),
                  _tCell(
                    deduct != null ? _fmt(deduct.amount) : '',
                    align: pw.TextAlign.right,
                  ),
                ]);
              }),
              // Totals row
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _tCell('Total Earnings', bold: true),
                  _tCell(
                    _fmt(record.baseSalary + record.totalAllowances),
                    bold: true,
                    align: pw.TextAlign.right,
                  ),
                  _tCell('Total Deductions', bold: true),
                  _tCell(
                    _fmt(record.totalDeductions),
                    bold: true,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // Net payable bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              border: pw.Border(
                left: pw.BorderSide(
                    color: PdfColors.blueGrey800, width: 4),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'NET SALARY PAYABLE',
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Rs. ${_fmt(record.netSalary)}',
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.Spacer(),

          // Signature line
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _sigBlock('Employee Signature'),
              _sigBlock('Authorized Signature'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shared cell builders ───────────────────────────────────────────────────

  static pw.Widget _pCell(
    String text, {
    bool bold = false,
    bool underline = false,
    double fontSize = 8.5,
    pw.TextAlign align = pw.TextAlign.left,
    double vPad = 2,
  }) =>
      pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: vPad),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            decoration:
                underline ? pw.TextDecoration.underline : pw.TextDecoration.none,
          ),
        ),
      );

  static pw.Widget _detail(String label, String value) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(children: [
          pw.Text('$label: ',
              style: pw.TextStyle(
                  fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 8.5)),
        ]),
      );

  static pw.Widget _tHead(String text,
          {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
              fontSize: 8.5, fontWeight: pw.FontWeight.bold),
        ),
      );

  static pw.Widget _tCell(String text,
          {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight:
                bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  static pw.Widget _sigBlock(String label) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('________________________',
              style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 2),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ],
      );
}
