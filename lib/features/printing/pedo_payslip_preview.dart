import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/utils/payroll_snapshot.dart';
import '../../core/utils/salary_calculator.dart';

/// On-screen pixel-perfect preview of the official KPK PEDO Government Pay Bill.
class PedoPayslipPreview extends StatelessWidget {
  final Employee employee;
  final List<PayrollComponent> regularAllowances;
  // All Other Allowances — Gross Claim (user-entered, sortOrder=0) plus any additional
  final List<PayrollComponent> otherAllowances;
  final List<PayrollComponent> deductions;
  final double baseSalary;
  final int month;
  final int year;
  final String vNo;
  final String date;
  // Pay bill classification codes (optional; fall back to KPK defaults if null)
  final String? basicMonthCode;
  final String? basicPayCode1;
  final String? basicPayCode2;
  final String? grossClaimCode;

  const PedoPayslipPreview({
    super.key,
    required this.employee,
    required this.regularAllowances,
    required this.otherAllowances,
    required this.deductions,
    required this.baseSalary,
    required this.month,
    required this.year,
    this.basicMonthCode,
    this.basicPayCode1,
    this.basicPayCode2,
    this.grossClaimCode,
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
    final ps = PayrollSnapshot.parse(record.salarySnapshot);
    final comps = ps.components;

    final regular = comps
        .where((c) => c.type == 'allowance' && (c.section == 'regular' || c.section == null))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // User-added other allowances only (Gross Claim is auto-calculated, not stored)
    final allOther = comps
        .where((c) => c.type == 'allowance' && c.section == 'other' &&
                      !c.name.toLowerCase().contains('gross claim'))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final deds = comps.where((c) => c.type == 'deduction').toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return PedoPayslipPreview(
      key: key,
      employee: employee,
      regularAllowances: regular,
      otherAllowances: allOther,
      deductions: deds,
      baseSalary: record.baseSalary,
      month: month,
      year: year,
      vNo: vNo,
      date: record.processedAt,
      // Use codes from snapshot (preserves historical state); fall back to employee
      basicMonthCode: ps.basicMonthCode ?? employee.basicMonthCode,
      basicPayCode1: ps.basicPayCode1 ?? employee.basicPayCode1,
      basicPayCode2: ps.basicPayCode2 ?? employee.basicPayCode2,
      grossClaimCode: employee.grossClaimCode,
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
    // Components from the DAO are already sorted by sortOrder
    final regular = components
        .where((c) => c.componentType == 'allowance' && c.isActive &&
                      (c.allowanceSection == 'regular' || c.allowanceSection == null))
        .map((c) => PayrollComponent(
              name: c.name,
              code: c.classificationCode,
              type: 'allowance',
              section: 'regular',
              amount: SalaryCalculator.calculateComponent(c, base),
              sortOrder: c.sortOrder,
            ))
        .toList();
    // User-added other allowances (Gross Claim is auto-calculated, not stored)
    final allOther = components
        .where((c) => c.componentType == 'allowance' && c.isActive &&
                      c.allowanceSection == 'other')
        .map((c) => PayrollComponent(
              name: c.name,
              code: c.classificationCode,
              type: 'allowance',
              section: 'other',
              amount: SalaryCalculator.calculateComponent(c, base),
              sortOrder: c.sortOrder,
            ))
        .toList();
    final deds = components
        .where((c) => c.componentType == 'deduction' && c.isActive)
        .map((c) => PayrollComponent(
              name: c.name,
              code: c.classificationCode,
              type: 'deduction',
              amount: SalaryCalculator.calculateComponent(c, base),
              sortOrder: c.sortOrder,
            ))
        .toList();

    return PedoPayslipPreview(
      key: key,
      employee: employee,
      regularAllowances: regular,
      otherAllowances: allOther,
      deductions: deds,
      baseSalary: base,
      month: month,
      year: year,
      vNo: vNo,
      basicMonthCode: employee.basicMonthCode,
      basicPayCode1: employee.basicPayCode1,
      basicPayCode2: employee.basicPayCode2,
      grossClaimCode: employee.grossClaimCode,
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
    final totRegular   = regularAllowances.fold(0.0, (s, c) => s + c.amount);
    final totDeduct    = deductions.fold(0.0, (s, c) => s + c.amount);
    final totUserOther = otherAllowances.fold(0.0, (s, c) => s + c.amount);
    final grossClaimAmt = baseSalary + totRegular + totUserOther;
    final net    = baseSalary + totRegular + totUserOther - totDeduct;
    final period = '${_months[month - 1]}-$year';
    final dateStr = _fmtDate(date);

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
                    _buildTable(period, totRegular, totDeduct, net, grossClaimAmt),
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
        Text(
          'Note:-Government accepts no responsibility for any fraud, miss-appropriation in '
          'respect of money or cheque bill made over to a messenger.',
          style: _ts.copyWith(fontSize: 8.5),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 5),
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
    double totDeduct,
    double net,
    double grossClaimAmt,
  ) {
    // Filter zero-amount deductions
    final visibleDeductions = deductions.where((d) => d.amount > 0).toList();
    // Resolved codes — user-configured values with KPK standard defaults
    final mCode  = basicMonthCode?.isNotEmpty == true ? basicMonthCode! : '00000';
    final p1Code = basicPayCode1?.isNotEmpty  == true ? basicPayCode1!  : '011000';
    final p2Code = basicPayCode2?.isNotEmpty  == true ? basicPayCode2!  : '01100';

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 0.7)),
      child: Column(
        children: [
          _headRow(),
          _dataRow('Pay for the Month of $period', mCode, 'Rs.', ''),
          _dataRow('', p1Code, _f(baseSalary), _f(baseSalary)),
          _twoLineRow(p2Code),
          _labelRow('Regular Allowance-', '02200', underline: true),

          for (final c in regularAllowances)
            _dataRow(_dotPad(c.name), c.code ?? '', _f(c.amount), _f(c.amount)),

          _dataRow(
            'Total Regular Allowances', '02000',
            _f(totRegular), _f(totRegular),
            bold: true, hasBorder: true,
          ),

          _sectionRow('Other Allowance', underline: true),

          // Gross Claim — always auto-calculated (never stored in components)
          _dataRow(
            _dotPad('Gross claim-Establishment charges'),
            grossClaimCode ?? '',
            _f(grossClaimAmt),
            _f(grossClaimAmt),
            indent: true,
            hasBorder: otherAllowances.isEmpty,
          ),

          // User-added other allowances
          for (int i = 0; i < otherAllowances.length; i++)
            _dataRow(
              _dotPad(otherAllowances[i].name),
              otherAllowances[i].code ?? '',
              _f(otherAllowances[i].amount),
              _f(otherAllowances[i].amount),
              indent: true,
              hasBorder: i == otherAllowances.length - 1,
            ),

          _sectionRow('Less -Fund deduction', underline: true),

          // Deductions — skip zero-amount rows
          for (int i = 0; i < visibleDeductions.length; i++)
            _dataRow(
              _dotPad(visibleDeductions[i].name),
              visibleDeductions[i].code ?? '',
              _amtOrDash(visibleDeductions[i].amount),
              _amtOrDash(visibleDeductions[i].amount),
              indent: true,
              hasBorder: i == visibleDeductions.length - 1,
            ),

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

  Widget _twoLineRow(String code) {
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
            SizedBox(width: _codeW, child: _cell(code, center: true)),
            _vl(),
            SizedBox(width: _rateW, child: _cell(_f(baseSalary), right: true, bold: true)),
            _vl(),
            SizedBox(width: _amtW,  child: _cell(_f(baseSalary), right: true, bold: true)),
          ],
        ),
      ),
    );
  }

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
