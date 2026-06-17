import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/auth_provider.dart';
import '../theme/theme_provider.dart';

// ── Navigation model ─────────────────────────────────────────────────────────

/// Flat string-based route IDs:
///   'dashboard', 'settings', 'backup'
///   '{category}.{section}'  → e.g. 'pedo.list', 'security.payroll'
/// Categories: pedo | security | alfajar
/// Sections:   list | add | payroll | reports
class NavRoute {
  const NavRoute._();

  static const dashboard = 'dashboard';
  static const settings = 'settings';
  static const backup = 'backup';

  static String cat(String category, String section) => '$category.$section';

  static String categoryOf(String route) =>
      route.contains('.') ? route.split('.').first : '';

  static String sectionOf(String route) =>
      route.contains('.') ? route.split('.').last : route;
}

// ── Private data models ───────────────────────────────────────────────────────

class _Cat {
  final String id, label;
  final IconData icon;
  final Color color;
  const _Cat(this.id, this.label, this.icon, this.color);
}

class _Sub {
  final String label, section;
  final IconData icon;
  const _Sub(this.label, this.icon, this.section);
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class Sidebar extends StatefulWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteChanged;

  const Sidebar({
    required this.currentRoute,
    required this.onRouteChanged,
    super.key,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final Map<String, bool> _expanded = {
    'pedo': true,
    'security': false,
    'alfajar': false,
  };

  static const _cats = [
    _Cat('pedo', 'PEDO Employees', Icons.account_balance_outlined, Color(0xFF1565C0)),
    _Cat('security', 'Security Guards', Icons.shield_outlined, Color(0xFF2E7D32)),
    _Cat('alfajar', 'Al Fajar', Icons.star_outline, Color(0xFF6A1B9A)),
  ];

  static const _subs = [
    _Sub('Employee List', Icons.people_outline, 'list'),
    _Sub('Add Employee', Icons.person_add_outlined, 'add'),
    _Sub('Payroll', Icons.payments_outlined, 'payroll'),
    _Sub('Print & Reports', Icons.print_outlined, 'reports'),
  ];

  @override
  void initState() {
    super.initState();
    _syncExpansion(widget.currentRoute);
  }

  @override
  void didUpdateWidget(Sidebar old) {
    super.didUpdateWidget(old);
    if (old.currentRoute != widget.currentRoute) {
      _syncExpansion(widget.currentRoute);
    }
  }

  void _syncExpansion(String route) {
    final cat = NavRoute.categoryOf(route);
    if (cat.isNotEmpty && _expanded.containsKey(cat) && !_expanded[cat]!) {
      setState(() => _expanded[cat] = true);
    }
  }

  bool _isActive(String routeId) => widget.currentRoute == routeId;
  bool _isCatActive(String catId) => widget.currentRoute.startsWith('$catId.');

  // ── Builders ──────────────────────────────────────────────────────────────

  Widget _logo(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Text(
            'PayVault',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    double leftPad = 14,
    double iconSize = 19,
    TextStyle? labelStyle,
    Color? activeColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveActive = activeColor ?? cs.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: EdgeInsets.only(left: leftPad, right: 8, top: 9, bottom: 9),
        decoration: BoxDecoration(
          color: isActive
              ? effectiveActive.withValues(alpha: isDark ? 0.18 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: iconSize,
              color: isActive
                  ? effectiveActive
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: (labelStyle ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
                  color: isActive
                      ? effectiveActive
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categorySection(BuildContext context, _Cat cat) {
    final isExpanded = _expanded[cat.id] ?? false;
    final isCatActive = _isCatActive(cat.id);

    return Column(
      children: [
        // Category header
        InkWell(
          onTap: () => setState(() => _expanded[cat.id] = !isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            padding: const EdgeInsets.only(left: 14, right: 8, top: 9, bottom: 9),
            decoration: BoxDecoration(
              color: isCatActive && !isExpanded
                  ? cat.color.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  cat.icon,
                  size: 19,
                  color: isCatActive ? cat.color : Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isCatActive
                          ? cat.color
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: isCatActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0.25 : 0,
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Sub-items with animated expand
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: isExpanded
              ? Column(
                  children: _subs.map((sub) {
                    final routeId = NavRoute.cat(cat.id, sub.section);
                    return _navItem(
                      context,
                      icon: sub.icon,
                      label: sub.label,
                      isActive: _isActive(routeId),
                      onTap: () => widget.onRouteChanged(routeId),
                      leftPad: 34,
                      iconSize: 16,
                      activeColor: cat.color,
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _bottomControls(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.read<AuthProvider>();
    final isDark = themeProvider.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              label: isDark ? 'Light' : 'Dark',
              onTap: themeProvider.toggle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: Icons.logout_outlined,
              label: 'Sign Out',
              onTap: auth.logout,
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? const Color(0xFF252537) : Colors.white;

    return SizedBox(
      width: 220,
      child: Material(
        color: sidebarBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _logo(context),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerTheme.color,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _navItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    isActive: _isActive(NavRoute.dashboard),
                    onTap: () => widget.onRouteChanged(NavRoute.dashboard),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'CATEGORIES',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ..._cats.map((cat) => _categorySection(context, cat)),
                  const SizedBox(height: 4),
                  Divider(
                    indent: 16,
                    endIndent: 16,
                    height: 16,
                    color: Theme.of(context).dividerTheme.color,
                  ),
                  _navItem(
                    context,
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isActive: _isActive(NavRoute.settings),
                    onTap: () => widget.onRouteChanged(NavRoute.settings),
                  ),
                  _navItem(
                    context,
                    icon: Icons.cloud_upload_outlined,
                    label: 'Backup',
                    isActive: _isActive(NavRoute.backup),
                    onTap: () => widget.onRouteChanged(NavRoute.backup),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerTheme.color,
            ),
            _bottomControls(context),
          ],
        ),
      ),
    );
  }
}

// ── Bottom action button ───────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFE53E3E)
        : Theme.of(context).iconTheme.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: (color ?? Colors.grey).withValues(alpha: 0.06),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
