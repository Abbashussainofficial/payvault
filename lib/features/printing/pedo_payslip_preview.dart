import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/payroll_snapshot.dart';
import '../../core/utils/salary_calculator.dart';

/// On-screen pixel-perfect preview of the official KPK PEDO Government Pay Bill.
class PedoPayslipPreview extends StatelessWidget {
  final Employee employee;
  final List<PayrollComponent> regularAllowances;
  final List<PayrollComponent> otherAllowances;
  final List<PayrollComponent> deductions;
  final double baseSalary;
  final int month;
  final int year;
  final String vNo;
  final String date;

  const PedoPayslipPreview({
    super.key,
    required this.employee,
    required this.regularAllowances,
    required this.otherAllowances,
    required this.deductions,
    required this.baseSalary,
    required this.month,
    required this.year,
    this.vNo = '',
    this.date = '',
  });

  factory PedoPayslipPreview.fromRecord({
    Key? key,
    required Employee employee,
    required PayrollRecord record,
    required int month,
    required int year,
    String vNo = '',
  }) {
    final comps = PayrollComponent.parseSnapshot(record.salarySnapshot);
    final regular = comps
        .where((c) => c.type == 'allowance' && (c.section == 'regular' || c.section == null))
        .toList();
    final other = comps
        .where((c) => c.type == 'allowance' && c.section == 'other')
        .toList();
    final deductions = comps.where((c) => c.type == 'deduction').toList();
    return PedoPayslipPreview(
      key: key,
      employee: employee,
      regularAllowances: regular,
      otherAllowances: other,
      deductions: deductions,
      baseSalary: record.baseSalary,
      month: month,
      year: year,
      vNo: vNo,
      date: record.processedAt,
    );
  }

  factory PedoPayslipPreview.fromComponents({
    Key? key,
    required Employee employee,
    required List<SalaryComponent> components,
    required int month,
    required int year,
    String vNo = '',
  }) {
    final base = employee.baseSalary;
    final regular = components
        .where((c) => c.componentType == 'allowance' && c.isActive &&
                      (c.allowanceSection == 'regular' || c.allowanceSection == null))
        .map((c) => PayrollComponent(
              name: c.name,
              code: c.classificationCode,
              type: 'allowance',
              section: 'regular',
              amount: SalaryCalculator.calculateComponent(c, base),
            ))
        .toList();
    final other = components
        .where((c) => c.componentType == 'allowance' && c.isActive &&
                      c.allowanceSection == 'other')
        .map((c) => PayrollComponent(
              name: c.name,
              code: c.classificationCode,
              type: 'allowance',
              section: 'other',
              amount: SalaryCalculator.calculateComponent(c, base),
            ))
        .toList();
    final deductions = components
        .where((c) => c.componentType == 'deduction' && c.isActive)
        .map((c) => PayrollComponent(
              name: c.name,
              code: c.classificationCode,
              type: 'deduction',
              amount: SalaryCalculator.calculateComponent(c, base),
            ))
        .toList();
    return PedoPayslipPreview(
      key: key,
      employee: employee,
      regularAllowances: regular,
      otherAllowances: other,
      deductions: deductions,
      baseSalary: base,
      month: month,
      year: year,
      vNo: vNo,
    );
  }

  // ── Constants ────────────────────────────────────────────────────────────────

  static final _numFmt = NumberFormat('#,##0', 'en_US');
  String _f(double v) => _numFmt.format(v.round());
  String _amtOrDash(double v) => v <= 0 ? '-' : _f(v);

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const double _codeW = 112.0;
  static const double _rateW = 90.0;
  static const double _amtW  = 90.0;
  static const double _vPad  = 3.5;
  static const double _hPad  = 5.0;

  static const TextStyle _ts = TextStyle(
    fontFamily: 'Times New Roman',
    fontSize: 9.5,
    color: Colors.black,
    height: 1.35,
    decoration: TextDecoration.none,
  );

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final totRegular = regularAllowances.fold(0.0, (s, c) => s + c.amount);
    final totOther   = otherAllowances.fold(0.0, (s, c) => s + c.amount);
    final totDeduct  = deductions.fold(0.0, (s, c) => s + c.amount);
    final gross      = baseSalary + totRegular + totOther;
    final net        = gross - totDeduct;
    final period     = '${_months[month - 1]}-$year';
    final dateStr    = _fmtDate(date);

    return ColoredBox(
      color: const Color(0xFF9E9E9E),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(34, 18, 34, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(dateStr),
                    const SizedBox(height: 9),
                    _buildTable(period, totRegular, gross, totDeduct, net),
                    const SizedBox(height: 34),
                    _buildSignature(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(String dateStr) {
    final bpsStr  = employee.bpsGrade != null ? 'BPS-${employee.bpsGrade}' : '';
    final vNoStr  = vNo.isEmpty ? '_________' : vNo;
    final dtStr   = dateStr.isEmpty ? '_________' : dateStr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // V. No / Date — top right
        Align(
          alignment: Alignment.topRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('V. No. $vNoStr', style: _ts.copyWith(fontSize: 9)),
              Text('Date   $dtStr',  style: _ts.copyWith(fontSize: 9)),
            ],
          ),
        ),
        const SizedBox(height: 2),

        // Title
        Text(
          'PAY BILL OF GOVERNMENT OFFICER,',
          style: _ts.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        Text(
          'GOVERNMENT OF K. P. K',
          style: _ts.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),

        // Disclaimer
        Text(
          'Note:-Government accepts no responsibility for any fraud, miss-appropriation in '
          'respect of money or cheque bill made over to a messenger.',
          style: _ts.copyWith(fontSize: 8.5),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 5),

        // Name line — name/designation/dept underlined
        RichText(
          text: TextSpan(
            style: _ts.copyWith(fontSize: 9.5),
            children: [
              const TextSpan(text: 'Name of Government Officer  '),
              TextSpan(
                text: '${employee.fullName}  ${employee.designation}  ${employee.department}',
                style: _ts.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.black,
                  decorationThickness: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),

        // BPS / scale centered bold
        if (bpsStr.isNotEmpty)
          Text(
            '($bpsStr)  (${_f(baseSalary)})',
            style: _ts.copyWith(fontSize: 9.5, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 2),

        Text(
          'B/Head: Revenue/Profit of PEDO, Service Charged Levied on Expenditure incurred on',
          style: _ts.copyWith(fontSize: 9.5),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 56),
          child: Text('Dev: Scheme of PEDO.', style: _ts.copyWith(fontSize: 9.5)),
        ),
        Text(
          'Detailed Function.',
          style: _ts.copyWith(fontSize: 9.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Main pay table ───────────────────────────────────────────────────────────

  Widget _buildTable(
    String period,
    double totRegular,
    double gross,
    double totDeduct,
    double net,
  ) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 0.7)),
      child: Column(
        children: [
          // Header row — border below (thick)
          _headRow(),

          // Pay period rows — NO borders
          _dataRow('Pay for the Month of $period', '00000', 'Rs.', ''),
          _dataRow('', '011000', _f(baseSalary), _f(baseSalary)),

          // "Pay....." + "Total Basic Salary" two-liner — border below
          _twoLineRow(),

          // Blank row with code 02000 — no border
          _dataRow('', '02000', '', ''),

          // "Regular Allowance-" with code 02200 — no border
          _labelRow('Regular Allowance-', '02200', underline: true),

          // Dynamic regular allowances — no borders
          for (final c in regularAllowances)
            _dataRow(_dotPad(c.name), c.code ?? '', _f(c.amount), _f(c.amount)),

          // Total Regular Allowances — border below
          _dataRow(
            'Total Regular Allowances', '02000',
            _f(totRegular), _f(totRegular),
            bold: true, hasBorder: true,
          ),

          // Budget code rows — border below each
          _dataRow('', '03000', '', '', hasBorder: true),
          _dataRow('', '00000', _f(gross), _f(gross), bold: true, hasBorder: true),

          // Other Allowance section — no border
          _sectionRow('Other Allowance', underline: true),

          // Dynamic other allowances (indented) — border on last; placeholder if empty
          if (otherAllowances.isNotEmpty)
            for (int i = 0; i < otherAllowances.length; i++)
              _dataRow(
                _dotPad(otherAllowances[i].name),
                otherAllowances[i].code ?? '',
                _f(otherAllowances[i].amount),
                _f(otherAllowances[i].amount),
                indent: true,
                hasBorder: i == otherAllowances.length - 1,
              )
          else
            _dataRow('', '', '', '', indent: true, hasBorder: true),

          // Less-Fund deduction section — no border
          _sectionRow('Less -Fund deduction', underline: true),

          // Dynamic deductions (indented) — border only on last
          for (int i = 0; i < deductions.length; i++)
            _dataRow(
              _dotPad(deductions[i].name),
              deductions[i].code ?? '',
              _amtOrDash(deductions[i].amount),
              _amtOrDash(deductions[i].amount),
              indent: true,
              hasBorder: i == deductions.length - 1,
            ),

          // Summary rows — border below each
          _dataRow(
            'Total Deduction:................................',
            '', _f(totDeduct), _f(totDeduct),
            bold: true, hasBorder: true,
          ),
          _dataRow(
            'Net Claim......................................',
            '', _f(net), _f(net),
            bold: true, hasBorder: true,
          ),

          // Total Net Amount Payable — NO inner border (outer table bottom is the line)
          _dataRow(
            'Total Net Amount Payable.......................',
            '', _f(net), _f(net),
            bold: true, center: true,
          ),
        ],
      ),
    );
  }

  // ── Row builders ─────────────────────────────────────────────────────────────

  Widget _headRow() {
    return _withBorder(
      hasBorder: true,
      thick: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(child: SizedBox()),
            _vl(),
            SizedBox(width: _codeW, child: _cell('Classification\nCode', bold: true, center: true)),
            _vl(),
            SizedBox(width: _rateW, child: _cell('Monthly Rate', bold: true, center: true)),
            _vl(),
            SizedBox(width: _amtW,  child: _cell('Amount', bold: true, center: true)),
          ],
        ),
      ),
    );
  }

  Widget _twoLineRow() {
    return _withBorder(
      hasBorder: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pay ..........................................', style: _ts),
                    Text('Total Basic  Salary', style: _ts.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            _vl(),
            SizedBox(width: _codeW, child: _cell('01100', center: true)),
            _vl(),
            SizedBox(width: _rateW, child: _cell(_f(baseSalary), right: true, bold: true)),
            _vl(),
            SizedBox(width: _amtW,  child: _cell(_f(baseSalary), right: true, bold: true)),
          ],
        ),
      ),
    );
  }

  // Standard 4-column data row — hasBorder: false by default
  Widget _dataRow(
    String desc,
    String code,
    String rate,
    String amt, {
    bool bold = false,
    bool center = false,
    bool hasBorder = false,
    bool indent = false,
  }) {
    return _withBorder(
      hasBorder: hasBorder,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _cell(desc, bold: bold, center: center, extraLeft: indent ? 10.0 : 0)),
            _vl(),
            SizedBox(width: _codeW, child: _cell(code, center: true)),
            _vl(),
            SizedBox(width: _rateW, child: _cell(rate, right: true, bold: bold)),
            _vl(),
            SizedBox(width: _amtW,  child: _cell(amt,  right: true, bold: bold)),
          ],
        ),
      ),
    );
  }

  // Label + code row (for section headers that have a code in the code column)
  Widget _labelRow(String label, String code, {bool underline = false, bool hasBorder = false}) {
    return _withBorder(
      hasBorder: hasBorder,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _cell(label, bold: true, underline: underline)),
            _vl(),
            SizedBox(width: _codeW, child: _cell(code, center: true)),
            _vl(),
            SizedBox(width: _rateW, child: _cell('')),
            _vl(),
            SizedBox(width: _amtW,  child: _cell('')),
          ],
        ),
      ),
    );
  }

  // Full-width section header with vertical column separators — never has a bottom border
  Widget _sectionRow(String label, {bool underline = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _cell(label, bold: true, underline: underline)),
          _vl(),
          SizedBox(width: _codeW, child: _cell('', center: true)),
          _vl(),
          SizedBox(width: _rateW, child: _cell('')),
          _vl(),
          SizedBox(width: _amtW,  child: _cell('')),
        ],
      ),
    );
  }

  // ── Primitives ───────────────────────────────────────────────────────────────

  Widget _withBorder({required Widget child, bool hasBorder = false, bool thick = false}) {
    if (!hasBorder) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black, width: thick ? 0.65 : 0.35),
        ),
      ),
      child: child,
    );
  }

  Widget _cell(
    String text, {
    bool bold = false,
    bool center = false,
    bool right = false,
    bool underline = false,
    double extraLeft = 0,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(_hPad + extraLeft, _vPad, _hPad, _vPad),
      child: Text(
        text,
        textAlign: right ? TextAlign.right : (center ? TextAlign.center : TextAlign.left),
        style: _ts.copyWith(
          fontWeight: bold ? FontWeight.bold : null,
          decoration: underline ? TextDecoration.underline : TextDecoration.none,
          decorationColor: Colors.black,
          decorationThickness: 1.2,
        ),
      ),
    );
  }

  Widget _vl() => Container(width: 0.5, color: Colors.black);

  // ── Footer ───────────────────────────────────────────────────────────────────

  Widget _buildSignature() {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 165, height: 0.8, color: Colors.black),
          const SizedBox(height: 4),
          Text('Signature of Officer', style: _ts.copyWith(fontSize: 9.5)),
        ],
      ),
    );
  }

  // ── Utilities ────────────────────────────────────────────────────────────────

  String _fmtDate(String raw) {
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
  }

  String _dotPad(String name) {
    if (name.length >= 38) return name;
    if (name.length >= 28) return '$name..........';
    return '$name......................';
  }
}
