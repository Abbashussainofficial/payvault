import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../shared/widgets/sidebar.dart';

// ── Activity item ─────────────────────────────────────────────────────────────

class _ActivityItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final String meta;

  const _ActivityItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.meta,
  });
}

// ── Data model ────────────────────────────────────────────────────────────────

class _DashboardData {
  final int pedoCount, securityCount, alfajarCount;
  final double pedoPayroll, securityPayroll, alfajarPayroll;
  final double pedoPrevPayroll, securityPrevPayroll, alfajarPrevPayroll;
  final List<_ActivityItem> activities;
  final int pendingApprovals;

  const _DashboardData({
    required this.pedoCount,
    required this.securityCount,
    required this.alfajarCount,
    required this.pedoPayroll,
    required this.securityPayroll,
    required this.alfajarPayroll,
    required this.pedoPrevPayroll,
    required this.securityPrevPayroll,
    required this.alfajarPrevPayroll,
    required this.activities,
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

  static const _catLabels = {
    'pedo': 'PEDO',
    'security': 'Security Guards',
    'alfajar': 'Al Fajar',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _relTime(String? iso) {
    if (iso == null) return 'Recently • By Admin';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago • By Admin';
      if (diff.inHours < 24) return '${diff.inHours} hours ago • By Admin';
      if (diff.inDays == 1) return 'Yesterday • By Admin';
      return '${DateFormat('MMM d, yyyy').format(dt)} • By Admin';
    } catch (_) {
      return 'Recently • By Admin';
    }
  }

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final all = await _db.employeesDao.getActiveEmployees();
      final currentPayroll =
          await _db.payrollRecordsDao.getRecordsByMonthYear(now.month, now.year);

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
      for (final r in currentPayroll) {
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

      // Previous month payroll by category
      final prevDt = DateTime(now.year, now.month - 1, 1);
      final prevPayroll = await _db.payrollRecordsDao
          .getRecordsByMonthYear(prevDt.month, prevDt.year);
      double pedoPrev = 0, secPrev = 0, alfPrev = 0;
      for (final r in prevPayroll) {
        final emp = empMap[r.employeeId];
        if (emp == null) continue;
        switch (emp.category) {
          case 'pedo':
            pedoPrev += r.netSalary;
          case 'security':
            secPrev += r.netSalary;
          case 'alfajar':
            alfPrev += r.netSalary;
        }
      }

      // Build activity list
      final activities = <_ActivityItem>[];

      // Payroll processed – one per category, most recent processedAt
      final payrollTs = <String, String>{};
      for (final r in currentPayroll) {
        final cat = empMap[r.employeeId]?.category;
        if (cat != null) payrollTs[cat] ??= r.processedAt;
      }
      const payrollColors = {
        'pedo': Color(0xFF27AE60),
        'security': Color(0xFF0D7377),
        'alfajar': Color(0xFF2E7D32),
      };
      for (final cat in ['pedo', 'security', 'alfajar']) {
        if (payrollTs.containsKey(cat)) {
          activities.add(_ActivityItem(
            icon: Icons.check_circle_outline,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: payrollColors[cat] ?? const Color(0xFF27AE60),
            title: 'Payroll Processed: ${_catLabels[cat]}',
            description:
                'Monthly batch for ${DateFormat('MMM yyyy').format(now)} finalized.',
            meta: _relTime(payrollTs[cat]),
          ));
        }
      }

      // Recent employees added
      const empColors = {
        'pedo': Color(0xFF1565C0),
        'security': Color(0xFF0D7377),
        'alfajar': Color(0xFF2E7D32),
      };
      final sorted = [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      for (final e in sorted.take(3)) {
        final c = empColors[e.category] ?? const Color(0xFF1565C0);
        activities.add(_ActivityItem(
          icon: Icons.person_add_outlined,
          iconBg: c.withValues(alpha: 0.1),
          iconColor: c,
          title: 'New Employee Added',
          description: '${e.fullName} joined ${_catLabels[e.category] ?? e.category}.',
          meta: _relTime(e.createdAt),
        ));
      }

      // Static backup entry
      activities.add(const _ActivityItem(
        icon: Icons.cloud_done_outlined,
        iconBg: Color(0xFFE3F2FD),
        iconColor: Color(0xFF1565C0),
        title: 'Backup Completed',
        description: 'Local backup successful. Data secured.',
        meta: 'Today • System Auto',
      ));

      // Pending approvals
      final processedIds = currentPayroll.map((r) => r.employeeId).toSet();
      final pending = all.where((e) => !processedIds.contains(e.id)).length;

      if (mounted) {
        setState(() {
          _data = _DashboardData(
            pedoCount: pedoC,
            securityCount: secC,
            alfajarCount: alfC,
            pedoPayroll: pedoP,
            securityPayroll: secP,
            alfajarPayroll: alfP,
            pedoPrevPayroll: pedoPrev,
            securityPrevPayroll: secPrev,
            alfajarPrevPayroll: alfPrev,
            activities: activities.take(5).toList(),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.onNavigate?.call(NavRoute.cat('pedo', 'payroll')),
        backgroundColor: const Color(0xFF1B2235),
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add, size: 18),
        label: const Text(
          'Run New Payroll',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(
                  error: _error!,
                  onRetry: () {
                    setState(() { _loading = true; _error = null; });
                    _load();
                  },
                )
              : _Body(data: _data!, onNavigate: widget.onNavigate),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final _DashboardData data;
  final ValueChanged<String>? onNavigate;

  const _Body({required this.data, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: 24),
          _CategoryCards(data: data, onNavigate: onNavigate),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _ComparisonChart(data: data)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _RecentActivity(activities: data.activities)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _BottomStats(data: data),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final dateStr = DateFormat('MMM d, yyyy').format(now);
    final timeStr = DateFormat('HH:mm').format(now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              'Centralized salary monitoring and auditing.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
        const Spacer(),
        // Date chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(20),
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 13, color: cs.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 6),
              Text(dateStr, style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Clock icon box
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(8),
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
          ),
          child: Icon(Icons.access_time_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.55)),
        ),
        const SizedBox(width: 12),
        // System Stable badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF27AE60).withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'System Stable',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF4CAF50) : const Color(0xFF276749),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF27AE60),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Live Sync Active • $timeStr',
                    style: tt.labelSmall?.copyWith(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF66BB6A) : const Color(0xFF2F855A),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

    return Row(
      children: [
        Expanded(
          child: _CatCard(
            title: 'PEDO Employees',
            ghostIcon: Icons.assignment_outlined,
            employeeCount: data.pedoCount,
            payroll: data.pedoPayroll,
            trendIcon: Icons.trending_up,
            accentColor: const Color(0xFF1565C0),
            fmt: fmt,
            onTap: () => onNavigate?.call(NavRoute.cat('pedo', 'list')),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _CatCard(
            title: 'Security Guards',
            ghostIcon: Icons.shield_outlined,
            employeeCount: data.securityCount,
            payroll: data.securityPayroll,
            trendIcon: Icons.arrow_forward,
            accentColor: const Color(0xFF0D7377),
            fmt: fmt,
            onTap: () => onNavigate?.call(NavRoute.cat('security', 'list')),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _CatCard(
            title: 'Al Fajar',
            ghostIcon: Icons.grid_view_outlined,
            employeeCount: data.alfajarCount,
            payroll: data.alfajarPayroll,
            trendIcon: Icons.trending_up,
            accentColor: const Color(0xFF2E7D32),
            fmt: fmt,
            onTap: () => onNavigate?.call(NavRoute.cat('alfajar', 'list')),
          ),
        ),
      ],
    );
  }
}

class _CatCard extends StatelessWidget {
  final String title;
  final IconData ghostIcon;
  final int employeeCount;
  final double payroll;
  final IconData trendIcon;
  final Color accentColor;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _CatCard({
    required this.title,
    required this.ghostIcon,
    required this.employeeCount,
    required this.payroll,
    required this.trendIcon,
    required this.accentColor,
    required this.fmt,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(
                    ghostIcon,
                    size: 52,
                    color: cs.onSurface.withValues(alpha: isDark ? 0.05 : 0.07),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    fmt.format(employeeCount),
                    style: tt.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 38,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Staff',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.45)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MONTHLY PAYROLL',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.45),
                            letterSpacing: 0.7,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          payroll > 0 ? 'PKR ${fmt.format(payroll)}' : 'PKR —',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(trendIcon, size: 16, color: accentColor),
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

// ── Payroll Comparison Chart ──────────────────────────────────────────────────

class _ComparisonChart extends StatelessWidget {
  final _DashboardData data;
  const _ComparisonChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.compact(locale: 'en_US');

    final currentColor = cs.primary;
    final prevColor = cs.primary.withValues(alpha: 0.28);

    final allVals = [
      data.pedoPayroll, data.securityPayroll, data.alfajarPayroll,
      data.pedoPrevPayroll, data.securityPrevPayroll, data.alfajarPrevPayroll,
    ];
    final maxVal = allVals.fold(0.0, (m, v) => v > m ? v : m);
    final chartMax = maxVal > 0 ? maxVal * 1.3 : 100000.0;

    BarChartGroupData makeGroup(int x, double cur, double prev) {
      return BarChartGroupData(
        x: x,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: cur,
            color: currentColor,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: prev,
            color: prevColor,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Payroll Comparison (PKR)', style: tt.headlineSmall),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendDot(color: currentColor),
                    const SizedBox(width: 5),
                    Text('Current', style: tt.labelSmall),
                    const SizedBox(width: 14),
                    _LegendDot(color: prevColor),
                    const SizedBox(width: 5),
                    Text('Previous', style: tt.labelSmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: chartMax,
                  barGroups: [
                    makeGroup(0, data.pedoPayroll, data.pedoPrevPayroll),
                    makeGroup(1, data.securityPayroll, data.securityPrevPayroll),
                    makeGroup(2, data.alfajarPayroll, data.alfajarPrevPayroll),
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
                          const labels = ['PEDO', 'Guards', 'Al Fajar'];
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
                  barTouchData: BarTouchData(enabled: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Recent Activity ───────────────────────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  final List<_ActivityItem> activities;
  const _RecentActivity({required this.activities});

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
                Text('Recent Activity', style: tt.headlineSmall),
                const Spacer(),
                Text(
                  'View All Logs',
                  style: tt.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 40, color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 8),
                      Text(
                        'No activity yet',
                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...activities.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isLast = i == activities.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item.iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, size: 17, color: item.iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: tt.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.description,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.meta,
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.38),
                                fontSize: 10,
                              ),
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

// ── Bottom Stats ──────────────────────────────────────────────────────────────

class _BottomStats extends StatelessWidget {
  final _DashboardData data;
  const _BottomStats({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.compact(locale: 'en_US');
    final totalStr = data.totalNetSalary > 0
        ? 'PKR ${fmt.format(data.totalNetSalary)}'
        : 'PKR —';

    return Row(
      children: [
        Expanded(
          child: _DarkStatCard(
            icon: Icons.people_alt_outlined,
            label: 'TOTAL EMPLOYEES',
            value: '${data.totalEmployees} Active',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _NormalStatCard(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: const Color(0xFF1B2235),
            iconColor: Colors.white,
            label: 'TOTAL PAYROLL',
            value: totalStr,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _DangerStatCard(
            icon: Icons.warning_amber_outlined,
            label: 'PENDING SALARIES',
            value: '${data.pendingApprovals} Pending',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _NormalStatCard(
            icon: Icons.cloud_done_outlined,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF27AE60),
            label: 'BACKUP STATUS',
            value: 'Secured & Encrypted',
          ),
        ),
      ],
    );
  }
}

class _DarkStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DarkStatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2235),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NormalStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label, value;

  const _NormalStatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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

class _DangerStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DangerStatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const red = Color(0xFFE53E3E);
    final bg = isDark ? const Color(0xFF3D1A1A) : const Color(0xFFFFF5F5);
    final border = red.withValues(alpha: isDark ? 0.3 : 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_outlined, size: 22, color: red),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.labelSmall?.copyWith(
                    color: red.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: red),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
