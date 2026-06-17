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

  const _DashboardData({
    required this.pedoCount,
    required this.securityCount,
    required this.alfajarCount,
    required this.pedoPayroll,
    required this.securityPayroll,
    required this.alfajarPayroll,
    required this.recentEmployees,
  });

  int get totalEmployees => pedoCount + securityCount + alfajarCount;
  double get totalPayroll => pedoPayroll + securityPayroll + alfajarPayroll;
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final all = await _db.employeesDao.getActiveEmployees();
      final payroll = await _db.payrollRecordsDao.getRecordsByMonthYear(now.month, now.year);

      final empMap = {for (final e in all) e.id: e};
      int pedoC = 0, secC = 0, alfC = 0;
      double pedoP = 0, secP = 0, alfP = 0;

      for (final e in all) {
        switch (e.category) {
          case 'pedo':
            pedoC++;
          case 'security':
            secC++;
          case 'alfajar':
            alfC++;
        }
      }
      for (final r in payroll) {
        final emp = empMap[r.employeeId];
        if (emp == null) continue;
        switch (emp.category) {
          case 'pedo':
            pedoP += r.netSalary;
          case 'security':
            secP += r.netSalary;
          case 'alfajar':
            alfP += r.netSalary;
        }
      }

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
              ? _ErrorState(error: _error!, onRetry: () { setState(() { _loading = true; _error = null; }); _load(); })
              : _Body(
                  data: _data!,
                  monthLabel: monthLabel,
                  month: now.month,
                  year: now.year,
                  onNavigate: widget.onNavigate,
                ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final _DashboardData data;
  final String monthLabel;
  final int month, year;
  final ValueChanged<String>? onNavigate;

  const _Body({
    required this.data,
    required this.monthLabel,
    required this.month,
    required this.year,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(monthLabel: monthLabel, onRefresh: null),
          const SizedBox(height: 20),
          _StatsRow(data: data),
          const SizedBox(height: 20),
          _CategoryCards(data: data, onNavigate: onNavigate),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _PayrollChart(data: data)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _RecentActivity(employees: data.recentEmployees)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String monthLabel;
  final VoidCallback? onRefresh;
  const _Header({required this.monthLabel, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to PayVault', style: tt.headlineLarge),
            const SizedBox(height: 2),
            Text(monthLabel, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
          ],
        ),
        const Spacer(),
        if (onRefresh != null)
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
          ),
      ],
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final _DashboardData data;
  const _StatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.compact(locale: 'en_US');
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Total Employees', value: '${data.totalEmployees}', icon: Icons.people_outline, iconColor: const Color(0xFF1565C0))),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Monthly Payroll', value: 'PKR ${fmt.format(data.totalPayroll)}', icon: Icons.account_balance_outlined, iconColor: const Color(0xFF2E7D32))),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'PEDO Staff', value: '${data.pedoCount}', icon: Icons.account_balance_outlined, iconColor: const Color(0xFF1565C0))),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Security + Al Fajar', value: '${data.securityCount + data.alfajarCount}', icon: Icons.shield_outlined, iconColor: const Color(0xFF6A1B9A))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconColor;
  const _StatCard({required this.label, required this.value, required this.icon, required this.iconColor});

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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final fmt = NumberFormat.compact(locale: 'en_US');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CatCard(
            label: 'PEDO Employees',
            icon: Icons.account_balance_outlined,
            color: const Color(0xFF1565C0),
            employeeCount: data.pedoCount,
            payroll: data.pedoPayroll,
            fmt: fmt,
            onView: () => onNavigate?.call(NavRoute.cat('pedo', 'list')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CatCard(
            label: 'Security Guards',
            icon: Icons.shield_outlined,
            color: const Color(0xFF2E7D32),
            employeeCount: data.securityCount,
            payroll: data.securityPayroll,
            fmt: fmt,
            onView: () => onNavigate?.call(NavRoute.cat('security', 'list')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CatCard(
            label: 'Al Fajar',
            icon: Icons.star_outline,
            color: const Color(0xFF6A1B9A),
            employeeCount: data.alfajarCount,
            payroll: data.alfajarPayroll,
            fmt: fmt,
            onView: () => onNavigate?.call(NavRoute.cat('alfajar', 'list')),
          ),
        ),
      ],
    );
  }
}

class _CatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int employeeCount;
  final double payroll;
  final NumberFormat fmt;
  final VoidCallback onView;

  const _CatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.employeeCount,
    required this.payroll,
    required this.fmt,
    required this.onView,
  });

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
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Row(
              label: 'Active Employees',
              value: '$employeeCount',
              valueColor: color,
            ),
            const SizedBox(height: 8),
            _Row(
              label: 'Monthly Payroll',
              value: payroll > 0 ? 'PKR ${fmt.format(payroll)}' : '—',
              valueColor: cs.onSurface,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onView,
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: Icon(Icons.arrow_forward, size: 15, color: color),
                label: Text('View Employees', style: TextStyle(color: color, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _Row({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
        Text(value, style: tt.titleSmall?.copyWith(color: valueColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Payroll chart ─────────────────────────────────────────────────────────────

class _PayrollChart extends StatelessWidget {
  final _DashboardData data;
  const _PayrollChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final values = [data.pedoPayroll, data.securityPayroll, data.alfajarPayroll];
    final maxVal = values.fold(0.0, (m, v) => v > m ? v : m);
    final chartMax = maxVal > 0 ? maxVal * 1.3 : 100000.0;
    final hasData = maxVal > 0;

    final colors = [const Color(0xFF1565C0), const Color(0xFF2E7D32), const Color(0xFF6A1B9A)];
    final labels = ['PEDO', 'Security', 'Al Fajar'];
    final fmt = NumberFormat.compact(locale: 'en_US');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payroll by Category', style: tt.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Current month net salaries',
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: hasData
                  ? BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: chartMax,
                        barGroups: List.generate(3, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: values[i],
                                color: colors[i],
                                width: 44,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          );
                        }),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 56,
                              getTitlesWidget: (v, _) => Text(
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
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    labels[i],
                                    style: tt.labelSmall?.copyWith(color: colors[i], fontWeight: FontWeight.w600),
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
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                              'PKR ${fmt.format(rod.toY)}',
                              TextStyle(color: colors[group.x], fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bar_chart_outlined, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 8),
                          Text(
                            'No payroll processed yet',
                            style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
                          ),
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
    'security': Color(0xFF2E7D32),
    'alfajar': Color(0xFF6A1B9A),
  };

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
            const SizedBox(height: 4),
            Text(
              'Latest employees added',
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            if (employees.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 40, color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 8),
                      Text(
                        'No employees yet',
                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...employees.map((e) {
                final catColor = _catColors[e.category] ?? cs.primary;
                final catLabel = _catLabels[e.category] ?? e.category;
                String dateStr = '';
                try {
                  final dt = DateTime.parse(e.createdAt);
                  dateStr = DateFormat('dd MMM yyyy').format(dt);
                } catch (_) {
                  dateStr = e.createdAt;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.fullName, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(catLabel, style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 6),
                                Text(dateStr, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.45))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
