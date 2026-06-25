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
    final comps           = PayrollComponent.parseSnapshot(record.salarySnapshot);
    final regularAllow    = comps.where((c) => c.type == 'allowance' && (c.section == 'regular' || c.section == null)).toList();
    final otherAllow      = comps.where((c) => c.type == 'allowance' && c.section == 'other').toList();
    final deductions      = comps.where((c) => c.type == 'deduction').toList();
    final totRegular      = regularAllow.fold(0.0, (s, c) => s + c.amount);
    final totOther        = otherAllow.fold(0.0, (s, c) => s + c.amount);
    final period          = '${_monthNames[month - 1]}-$year';
    final gross           = record.baseSalary + totRegular + totOther;
    final net             = record.netSalary;
    final bpsStr     = employee.bpsGrade != null ? 'BPS-${employee.bpsGrade}' : '';
    final dateStr    = record.processedAt.isEmpty
        ? '_________'
        : DateFormat('dd-MM-yyyy')
            .format(DateTime.tryParse(record.processedAt) ?? DateTime.now());
    final vNoStr = vNo.isEmpty ? '_________' : vNo;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // V. No / Date — top right
          pw.Align(
            alignment: pw.Alignment.topRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('V. No. $vNoStr', style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text('Date   $dateStr', style: const pw.TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
          pw.SizedBox(height: 4),

          // Title — two centered bold lines
          pw.Text(
            'PAY BILL OF GOVERNMENT OFFICER,',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            'GOVERNMENT OF K. P. K',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),

          // Disclaimer
          pw.Text(
            'Note:-Government accepts no responsibility for any fraud, miss-appropriation in '
            'respect of money or cheque bill made over to a messenger.',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 4),

          // Name line — name/designation/dept underlined
          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 9),
              children: [
                const pw.TextSpan(text: 'Name of Government Officer  '),
                pw.TextSpan(
                  text: '${employee.fullName}  ${employee.designation}  ${employee.department}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 2),

          // BPS / scale — centered
          if (bpsStr.isNotEmpty)
            pw.Text(
              '($bpsStr)  (${_fmt(employee.baseSalary)})',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          pw.SizedBox(height: 2),

          pw.Text(
            'B/Head: Revenue/Profit of PEDO, Service Charged Levied on Expenditure incurred on',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 48),
            child: pw.Text('Dev: Scheme of PEDO.', style: const pw.TextStyle(fontSize: 9)),
          ),
          pw.Text(
            'Detailed Function.',
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),

          // Main table
          _buildPedoTable(
            record: record,
            regularAllowances: regularAllow,
            otherAllowances: otherAllow,
            totRegular: totRegular,
            deductions: deductions,
            period: period,
            gross: gross,
            net: net,
          ),
          pw.SizedBox(height: 28),

          // Signature
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 140,
                  height: 0.8,
                  decoration: const pw.BoxDecoration(color: PdfColors.black),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Signature of Officer', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPedoTable({
    required PayrollRecord record,
    required List<PayrollComponent> regularAllowances,
    required List<PayrollComponent> otherAllowances,
    required double totRegular,
    required List<PayrollComponent> deductions,
    required String period,
    required double gross,
    required double net,
  }) {
    const colWidths = {
      0: pw.FlexColumnWidth(3.8),
      1: pw.FixedColumnWidth(86.0),
      2: pw.FixedColumnWidth(70.0),
      3: pw.FixedColumnWidth(70.0),
    };

    // Outer border only — selective inner borders via row decoration
    const border = pw.TableBorder(
      top:              pw.BorderSide(color: PdfColors.black, width: 0.6),
      bottom:           pw.BorderSide(color: PdfColors.black, width: 0.6),
      left:             pw.BorderSide(color: PdfColors.black, width: 0.6),
      right:            pw.BorderSide(color: PdfColors.black, width: 0.6),
      horizontalInside: pw.BorderSide.none,
      verticalInside:   pw.BorderSide(color: PdfColors.black, width: 0.5),
    );

    // Bottom-border decoration for rows that need it
    const rowBorderDeco = pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.black, width: 0.4),
      ),
    );

    String amtOrDash(double v) => v <= 0 ? '-' : _fmt(v);

    // Standard 4-column data row
    pw.TableRow dr(
      String desc,
      String code,
      String rate,
      String amt, {
      bool bold = false,
      bool hasBorder = false,
      bool indent = false,
      bool centerDesc = false,
    }) =>
        pw.TableRow(
          decoration: hasBorder ? rowBorderDeco : null,
          children: [
            _pCell(desc, bold: bold, indent: indent,
                align: centerDesc ? pw.TextAlign.center : pw.TextAlign.left),
            _pCell(code, align: pw.TextAlign.center),
            _pCell(rate, align: pw.TextAlign.right, bold: bold),
            _pCell(amt,  align: pw.TextAlign.right, bold: bold),
          ],
        );

    // Section header row — bold+underline label, empty other cells, no border
    pw.TableRow sr(String label, {bool underline = false}) => pw.TableRow(
      children: [
        _pCell(label, bold: true, underline: underline),
        _pCell('', align: pw.TextAlign.center),
        _pCell(''),
        _pCell(''),
      ],
    );

    // Label + code row (e.g. "Regular Allowance-" with code 02200)
    pw.TableRow lr(String label, String code, {bool underline = false}) => pw.TableRow(
      children: [
        _pCell(label, bold: true, underline: underline),
        _pCell(code, align: pw.TextAlign.center),
        _pCell(''),
        _pCell(''),
      ],
    );

    return pw.Table(
      border: border,
      columnWidths: colWidths,
      children: [
        // Header — border below (thick)
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, width: 0.6),
            ),
          ),
          children: [
            _pCell('', bold: true, vPad: 3),
            _pCell('Classification\nCode', bold: true, align: pw.TextAlign.center, vPad: 3),
            _pCell('Monthly Rate',         bold: true, align: pw.TextAlign.center, vPad: 3),
            _pCell('Amount',               bold: true, align: pw.TextAlign.center, vPad: 3),
          ],
        ),

        // Pay period rows — no borders
        dr('Pay for the Month of $period', '00000', 'Rs.', ''),
        dr('', '011000', _fmt(record.baseSalary), _fmt(record.baseSalary)),

        // "Pay....." + "Total Basic Salary" two-liner — border below
        pw.TableRow(
          decoration: rowBorderDeco,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Pay ..........................................',
                      style: const pw.TextStyle(fontSize: 8.5)),
                  pw.Text('Total Basic  Salary',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            _pCell('01100', align: pw.TextAlign.center),
            _pCell(_fmt(record.baseSalary), align: pw.TextAlign.right, bold: true),
            _pCell(_fmt(record.baseSalary), align: pw.TextAlign.right, bold: true),
          ],
        ),

        // Blank row with code 02000 — no border
        dr('', '02000', '', ''),

        // "Regular Allowance-" with code 02200 — no border
        lr('Regular Allowance-', '02200', underline: true),

        // Dynamic regular allowances — no borders
        ...regularAllowances.map((c) => dr(c.name, c.code ?? '', _fmt(c.amount), _fmt(c.amount))),

        // Total Regular Allowances — border below
        dr('Total Regular Allowances', '02000',
            _fmt(totRegular), _fmt(totRegular),
            bold: true, hasBorder: true),

        // Budget code rows — border below each
        dr('', '03000', '', '', hasBorder: true),
        dr('', '00000', _fmt(gross), _fmt(gross), bold: true, hasBorder: true),

        // Other Allowance — no border
        sr('Other Allowance', underline: true),

        // Dynamic other allowances (indented) — border on last; placeholder if empty
        ...List.generate(
          otherAllowances.isNotEmpty ? otherAllowances.length : 1,
          (i) {
            if (otherAllowances.isEmpty) {
              return dr('', '', '', '', indent: true, hasBorder: true);
            }
            final c = otherAllowances[i];
            return dr(c.name, c.code ?? '', _fmt(c.amount), _fmt(c.amount),
                indent: true, hasBorder: i == otherAllowances.length - 1);
          },
        ),

        // Less-Fund deduction — no border
        sr('Less -Fund deduction', underline: true),

        // Dynamic deductions (indented) — border only on last
        ...List.generate(deductions.length, (i) => dr(
          deductions[i].name,
          deductions[i].code ?? '',
          amtOrDash(deductions[i].amount),
          amtOrDash(deductions[i].amount),
          indent: true,
          hasBorder: i == deductions.length - 1,
        )),

        // Summary rows — border below each
        dr('Total Deduction:................................', '',
            _fmt(record.totalDeductions), _fmt(record.totalDeductions),
            bold: true, hasBorder: true),
        dr('Net Claim......................................', '',
            _fmt(net), _fmt(net),
            bold: true, hasBorder: true),

        // Total Net Amount Payable — no inner border (outer table bottom is the line)
        dr('Total Net Amount Payable.......................',  '',
            _fmt(net), _fmt(net),
            bold: true, centerDesc: true),
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
    bool indent = false,
  }) =>
      pw.Padding(
        padding: pw.EdgeInsets.fromLTRB(indent ? 14 : 4, vPad, 4, vPad),
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
