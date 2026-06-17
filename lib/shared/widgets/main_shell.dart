import 'package:flutter/material.dart';

import '../../features/backup/backup_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/employees/employee_form_screen.dart';
import '../../features/employees/employee_list_screen.dart';
import '../../features/payroll/payroll_screen.dart';
import '../../features/printing/print_screen.dart';
import '../../features/settings/settings_screen.dart';
import 'sidebar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _route = NavRoute.dashboard;

  void _setRoute(String route) {
    if (route == _route) return;
    setState(() => _route = route);
  }

  Widget _buildPage() {
    final cat = NavRoute.categoryOf(_route);
    final section = NavRoute.sectionOf(_route);

    return switch (_route) {
      NavRoute.dashboard => DashboardScreen(onNavigate: _setRoute),
      NavRoute.settings => SettingsScreen(onNavigate: _setRoute),
      NavRoute.backup => const BackupScreen(),
      _ when cat.isNotEmpty => switch (section) {
          'list' => EmployeeListScreen(category: cat),
          'add' => EmployeeFormScreen(category: cat),
          'payroll' => PayrollScreen(category: cat),
          'reports' => PrintScreen(category: cat),
          _ => DashboardScreen(onNavigate: _setRoute),
        },
      _ => DashboardScreen(onNavigate: _setRoute),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(currentRoute: _route, onRouteChanged: _setRoute),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).dividerTheme.color,
          ),
          Expanded(
            child: Column(
              children: [
                _ContentTopBar(currentRoute: _route, onNavigate: _setRoute),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerTheme.color,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_route),
                      child: _buildPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Content top bar ───────────────────────────────────────────────────────────

class _ContentTopBar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;

  const _ContentTopBar({required this.currentRoute, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final isHome = currentRoute == NavRoute.dashboard;

    return Container(
      height: 56,
      color: isDark ? const Color(0xFF252537) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 210,
            height: 36,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search records...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 17, color: cs.onSurface.withValues(alpha: 0.4)),
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF4F6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),
          // Tabs
          _TopTab(label: 'Home', active: isHome, onTap: () => onNavigate(NavRoute.dashboard)),
          _TopTab(label: 'Reports', active: false, onTap: () {}),
          _TopTab(label: 'Analytics', active: false, onTap: () {}),
          const Spacer(),
          // Icon buttons
          _IconBtn(icon: Icons.notifications_outlined, onTap: () {}, tooltip: 'Notifications'),
          const SizedBox(width: 2),
          _IconBtn(icon: Icons.help_outline, onTap: () {}, tooltip: 'Help'),
          const SizedBox(width: 12),
          // Disburse Salary button
          ElevatedButton.icon(
            onPressed: () {
              final cat = NavRoute.categoryOf(currentRoute);
              onNavigate(cat.isNotEmpty
                  ? NavRoute.cat(cat, 'payroll')
                  : NavRoute.cat('pedo', 'payroll'));
            },
            icon: const Icon(Icons.payments_outlined, size: 15),
            label: const Text('Disburse Salary'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B2235),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 36),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF1565C0),
            child: const Text(
              'A',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TopTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textColor = active
        ? cs.primary
        : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? cs.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
        ),
      ),
    );
  }
}
