import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../shared/widgets/sidebar.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _DashboardData {
  final int pedoCount, securityCount, alfajarCount;
  final double pedoPayroll, securityPayroll, alfajarPayroll;
  final List<Employee> recentEmployees;
  final List<double> chartTotals;   // 6 values oldest→newest
  final List<String> chartLabels;   // 'Jan','Feb',…
  final int pendingApprovals;

  const _DashboardData({
    required this.pedoCount,
    required this.securityCount,
    required this.alfajarCount,
    required this.pedoPayroll,
    required this.securityPayroll,
    required this.alfajarPayroll,
    required this.recentEmployees,
    required this.chartTotals,
    required this.chartLabels,
    required this.pendingApprovals,
  });

  int get totalEmployees => pedoCount + securityCount + alfajarCount;
  double get totalNetSalary => pedoPayroll + securityPayroll + alfajarPayroll;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  final ValueChanged<String>? onNavigate;
  const DashboardScreen({this.onNavigate, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _DashboardData? _data;
  bool _loading = true;
  String? _error;
  final _db = AppDatabase.instance;

  static const _monthNames = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final all = await _db.employeesDao.getActiveEmployees();
      final currentPayroll = await _db.payrollRecordsDao.getRecordsByMonthYear(now.month, now.year);

      final empMap = {for (final e in all) e.id: e};
      int pedoC = 0, secC = 0, alfC = 0;
      double pedoP = 0, secP = 0, alfP = 0;

      for (final e in all) {
        switch (e.category) {
          case 'pedo': pedoC++;
          case 'security': secC++;
          case 'alfajar': alfC++;
        }
      }
      for (final r in currentPayroll) {
        final emp = empMap[r.employeeId];
        if (emp == null) continue;
        switch (emp.category) {
          case 'pedo': pedoP += r.netSalary;
          case 'security': secP += r.netSalary;
          case 'alfajar': alfP += r.netSalary;
        }
      }

      // 6-month chart data
      final chartTotals = <double>[];
      final chartLabels = <String>[];
      for (int i = 5; i >= 0; i--) {
        final dt = DateTime(now.year, now.month - i, 1);
        final records = i == 0
            ? currentPayroll
            : await _db.payrollRecordsDao.getRecordsByMonthYear(dt.month, dt.year);
        chartTotals.add(records.fold(0.0, (s, r) => s + r.netSalary));
        chartLabels.add(_monthNames[dt.month - 1]);
      }

      // Pending approvals = active employees with no payroll this month
      final processedIds = currentPayroll.map((r) => r.employeeId).toSet();
      final pending = all.where((e) => !processedIds.contains(e.id)).length;

      final sorted = [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _data = _DashboardData(
            pedoCount: pedoC,
            securityCount: secC,
            alfajarCount: alfC,
            pedoPayroll: pedoP,
            securityPayroll: secP,
            alfajarPayroll: alfP,
            recentEmployees: sorted.take(5).toList(),
            chartTotals: chartTotals,
            chartLabels: chartLabels,
            pendingApprovals: pending,
          );
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(
                  error: _error!,
                  onRetry: () { setState(() { _loading = true; _error = null; }); _load(); },
                )
              : _Body(
                  data: _data!,
                  monthLabel: monthLabel,
                  onNavigate: widget.onNavigate,
                ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final _DashboardData data;
  final String monthLabel;
  final ValueChanged<String>? onNavigate;

  const _Body({required this.data, required this.monthLabel, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(monthLabel: monthLabel),
          const SizedBox(height: 24),
          _CategoryCards(data: data, onNavigate: onNavigate),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _ExpenditureChart(data: data)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _RecentActivity(employees: data.recentEmployees)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _BottomStats(data: data),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String monthLabel;
  const _Header({required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payroll Overview', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Manage and monitor payroll across all departments.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.55)),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'CURRENT PERIOD',
              style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.45),
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              monthLabel,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.primary),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Category cards ────────────────────────────────────────────────────────────

class _CategoryCards extends StatelessWidget {
  final _DashboardData data;
  final ValueChanged<String>? onNavigate;
  const _CategoryCards({required this.data, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final fmtPay = NumberFormat('#,##0', 'en_US');

    return Row(
      children: [
        Expanded(
          child: _CatCard(
            badge: 'PUBLIC SECTOR',
            badgeColor: const Color(0xFF1565C0),
            title: 'PEDO',
            icon: Icons.account_balance_outlined,
            employeeCount: data.pedoCount,
            payroll: data.pedoPayroll,
            fmt: fmt,
            fmtPay: fmtPay,
            onTap: () => onNavigate?.call(NavRoute.cat('pedo', 'list')),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _CatCard(
            badge: 'EXTERNAL AGENCY',
            badgeColor: const Color(0xFF0D7377),
            title: 'Security Guards',
            icon: Icons.shield_outlined,
            employeeCount: data.securityCount,
            payroll: data.securityPayroll,
            fmt: fmt,
            fmtPay: fmtPay,
            onTap: () => onNavigate?.call(NavRoute.cat('security', 'list')),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _CatCard(
            badge: 'CONTRACTUAL',
            badgeColor: const Color(0xFF2E7D32),
            title: 'Al Fajar',
            icon: Icons.cleaning_services_outlined,
            employeeCount: data.alfajarCount,
            payroll: data.alfajarPayroll,
            fmt: fmt,
            fmtPay: fmtPay,
            onTap: () => onNavigate?.call(NavRoute.cat('alfajar', 'list')),
          ),
        ),
      ],
    );
  }
}

class _CatCard extends StatelessWidget {
  final String badge, title;
  final Color badgeColor;
  final IconData icon;
  final int employeeCount;
  final double payroll;
  final NumberFormat fmt, fmtPay;
  final VoidCallback onTap;

  const _CatCard({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.icon,
    required this.employeeCount,
    required this.payroll,
    required this.fmt,
    required this.fmtPay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: isDark ? 0.25 : 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? badgeColor.withValues(alpha: 0.9) : badgeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: badgeColor, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Employees',
                        style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fmt.format(employeeCount),
                        style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Monthly Payroll',
                        style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payroll > 0 ? 'Rs. ${fmtPay.format(payroll)}' : '—',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payroll Expenditure History chart ─────────────────────────────────────────

class _ExpenditureChart extends StatelessWidget {
  final _DashboardData data;
  const _ExpenditureChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.compact(locale: 'en_US');

    final totals = data.chartTotals;
    final labels = data.chartLabels;
    final maxVal = totals.fold(0.0, (m, v) => v > m ? v : m);
    final chartMax = maxVal > 0 ? maxVal * 1.25 : 100000.0;
    final hasData = maxVal > 0;

    final spots = List.generate(totals.length, (i) => FlSpot(i.toDouble(), totals[i]));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Payroll Expenditure History', style: tt.headlineSmall),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.onSurface.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Last 6 Months', style: tt.labelSmall),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: hasData
                  ? LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: chartMax,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: cs.primary,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                                radius: 4,
                                color: cs.primary,
                                strokeWidth: 2,
                                strokeColor: isDark ? const Color(0xFF252537) : Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  cs.primary.withValues(alpha: 0.15),
                                  cs.primary.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 52,
                              getTitlesWidget: (v, _) => v == 0
                                  ? const SizedBox.shrink()
                                  : Text(
                                      fmt.format(v),
                                      style: tt.labelSmall?.copyWith(fontSize: 10),
                                    ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    labels[i],
                                    style: tt.labelSmall?.copyWith(fontSize: 11),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                              'Rs. ${fmt.format(s.y)}',
                              TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.show_chart, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 8),
                          Text('No payroll data yet', style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4))),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent activity ───────────────────────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  final List<Employee> employees;
  const _RecentActivity({required this.employees});

  static const _catLabels = {'pedo': 'PEDO', 'security': 'Security', 'alfajar': 'Al Fajar'};
  static const _catColors = {
    'pedo': Color(0xFF1565C0),
    'security': Color(0xFF0D7377),
    'alfajar': Color(0xFF2E7D32),
  };

  String _relativeDate(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        return 'Today at ${DateFormat('hh:mm a').format(dt)}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else {
        return DateFormat('MMM d, yyyy').format(dt);
      }
    } catch (_) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity', style: tt.headlineSmall),
            const SizedBox(height: 16),
            if (employees.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 40, color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 8),
                      Text('No activity yet', style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
              )
            else ...[
              ...employees.map((e) {
                final catColor = _catColors[e.category] ?? cs.primary;
                final catLabel = _catLabels[e.category] ?? e.category;
                final dateStr = _relativeDate(e.createdAt);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person_add_outlined, size: 18, color: catColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: tt.bodySmall?.copyWith(color: cs.onSurface),
                                children: [
                                  TextSpan(text: e.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const TextSpan(text: ' added to '),
                                  TextSpan(text: catLabel, style: TextStyle(fontWeight: FontWeight.w600, color: catColor)),
                                  const TextSpan(text: ' category.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(dateStr, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.45))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'View All Activity',
                  style: tt.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Bottom stats row ──────────────────────────────────────────────────────────

class _BottomStats extends StatelessWidget {
  final _DashboardData data;
  const _BottomStats({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.compact(locale: 'en_US');

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_outline,
            iconColor: const Color(0xFF1565C0),
            label: 'Total Employees',
            value: '${data.totalEmployees}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFF2E7D32),
            label: 'Total Net Salary',
            value: data.totalNetSalary > 0 ? 'Rs. ${fmt.format(data.totalNetSalary)}' : '—',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.pending_actions_outlined,
            iconColor: const Color(0xFFE67E22),
            label: 'Pending Approvals',
            value: '${data.pendingApprovals}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF27AE60),
            label: 'System Status',
            value: 'Online',
            valueColor: const Color(0xFF27AE60),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text('Failed to load dashboard', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(error, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }
}
