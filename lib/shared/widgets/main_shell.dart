import 'package:flutter/material.dart';

import '../../core/database/database.dart';
import '../../features/backup/backup_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/employees/employee_form_screen.dart';
import '../../features/employees/employee_list_screen.dart';
import '../../features/payroll/payroll_screen.dart';
import '../../features/printing/print_screen.dart';
import '../../features/salary/salary_structure_screen.dart';
import '../../features/settings/settings_screen.dart';
import 'sidebar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _route = NavRoute.dashboard;
  Employee? _selectedEmployee;

  void _setRoute(String route) {
    if (route == _route) return;
    setState(() => _route = route);
  }

  void _viewEmployee(Employee emp) {
    setState(() {
      _selectedEmployee = emp;
      _route = NavRoute.cat(emp.category, 'salary');
    });
  }

  Widget _buildPage() {
    final cat = NavRoute.categoryOf(_route);
    final section = NavRoute.sectionOf(_route);

    return switch (_route) {
      NavRoute.dashboard => DashboardScreen(onNavigate: _setRoute),
      NavRoute.settings => SettingsScreen(onNavigate: _setRoute),
      NavRoute.backup => const BackupScreen(),
      _ when cat.isNotEmpty => switch (section) {
          'list' => EmployeeListScreen(
              category: cat,
              onViewEmployee: _viewEmployee,
            ),
          'add' => EmployeeFormScreen(category: cat),
          'payroll' => PayrollScreen(category: cat),
          'reports' => PrintScreen(category: cat),
          'salary' when _selectedEmployee != null => SalaryStructureScreen(
              employee: _selectedEmployee!,
              onBack: () => _setRoute(NavRoute.cat(cat, 'list')),
            ),
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
    );
  }
}
