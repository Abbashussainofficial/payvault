import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/auth_provider.dart';
import '../theme/theme_provider.dart';

// ── Navigation model ─────────────────────────────────────────────────────────

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
  const _Cat(this.id, this.label, this.icon);
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
    _Cat('pedo', 'PEDO Employees', Icons.people_outline),
    _Cat('security', 'Security Guards', Icons.shield_outlined),
    _Cat('alfajar', 'Al Fajar', Icons.star_outline),
  ];

  List<_Sub> _subsForCat(String catId) => [
    const _Sub('Add Employee', Icons.person_add_outlined, 'add'),
    const _Sub('Payroll', Icons.payments_outlined, 'payroll'),
    const _Sub('Print & Reports', Icons.print_outlined, 'reports'),
    if (catId == 'pedo') const _Sub('Templates', Icons.description_outlined, 'templates'),
  ];

  @override
  void initState() {
    super.initState();
    _syncExpansion(widget.currentRoute);
  }

  @override
  void didUpdateWidget(Sidebar old) {
    super.didUpdateWidget(old);
    if (old.currentRoute != widget.currentRoute) _syncExpansion(widget.currentRoute);
  }

  void _syncExpansion(String route) {
    final cat = NavRoute.categoryOf(route);
    if (cat.isNotEmpty && _expanded.containsKey(cat) && !_expanded[cat]!) {
      setState(() => _expanded[cat] = true);
    }
  }

  bool _isActive(String routeId) => widget.currentRoute == routeId;
  bool _isCatActive(String catId) => widget.currentRoute.startsWith('$catId.');

  // ── Theme helpers ─────────────────────────────────────────────────────────

  Color _bg(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
      ? const Color(0xFF1E1E2E)
      : Colors.white;

  Color _activeItemBg(BuildContext ctx) => Theme.of(ctx).colorScheme.primary;

  Color _inactiveText(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
      ? const Color(0xFF94A3B8)
      : const Color(0xFF475569);

  Color _inactiveIcon(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
      ? const Color(0xFF64748B)
      : const Color(0xFF94A3B8);

  Color _sectionLabel(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
      ? const Color(0xFF4A5568)
      : const Color(0xFFB0BEC5);

  Color _divider(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFFE8ECF0);

  Color _hoverBg(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.05)
      : const Color(0xFFF1F5F9);

  // ── Logo ──────────────────────────────────────────────────────────────────

  Widget _logo(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PayVault',
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Salary Management',
                  style: TextStyle(color: subColor, fontSize: 10, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Nav item ──────────────────────────────────────────────────────────────

  Widget _navItem(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    double leftPad = 14,
    double iconSize = 18,
  }) {
    final activeBg = _activeItemBg(ctx);
    final inactiveText = _inactiveText(ctx);
    final inactiveIcon = _inactiveIcon(ctx);
    final hover = _hoverBg(ctx);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: isActive ? Colors.transparent : hover,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: EdgeInsets.only(left: leftPad, right: 8, top: 9, bottom: 9),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: iconSize, color: isActive ? Colors.white : inactiveIcon),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : inactiveText,
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

  // ── Category section ──────────────────────────────────────────────────────

  Widget _categorySection(BuildContext ctx, _Cat cat) {
    final isExpanded = _expanded[cat.id] ?? false;
    final isCatActive = _isCatActive(cat.id);
    final activeBg = _activeItemBg(ctx);
    final inactiveText = _inactiveText(ctx);
    final inactiveIcon = _inactiveIcon(ctx);
    final sectionColor = _sectionLabel(ctx);

    // When expanded + active: show primary-color text/icon on transparent bg
    // When collapsed + active: show white text/icon on primary-color bg
    final iconColor = isCatActive
        ? (isExpanded ? activeBg : Colors.white)
        : inactiveIcon;
    final textColor = isCatActive
        ? (isExpanded ? activeBg : Colors.white)
        : inactiveText;
    final chevronColor = isCatActive
        ? (isExpanded ? activeBg : Colors.white)
        : sectionColor;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() => _expanded[cat.id] = !isExpanded);
            widget.onRouteChanged(NavRoute.cat(cat.id, 'list'));
          },
          borderRadius: BorderRadius.circular(8),
          hoverColor: _hoverBg(ctx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            padding: const EdgeInsets.only(left: 14, right: 8, top: 9, bottom: 9),
            decoration: BoxDecoration(
              color: isCatActive && !isExpanded ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(cat.icon, size: 18, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat.label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isCatActive ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0.25 : 0,
                  child: Icon(Icons.chevron_right, size: 16, color: chevronColor),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: isExpanded
              ? Column(
                  children: _subsForCat(cat.id).map((sub) {
                    final routeId = NavRoute.cat(cat.id, sub.section);
                    return _navItem(
                      ctx,
                      icon: sub.icon,
                      label: sub.label,
                      isActive: _isActive(routeId),
                      onTap: () => widget.onRouteChanged(routeId),
                      leftPad: 34,
                      iconSize: 15,
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Admin profile / bottom ─────────────────────────────────────────────────

  Widget _adminProfile(BuildContext ctx) {
    final themeProvider = ctx.watch<ThemeProvider>();
    final auth = ctx.read<AuthProvider>();
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1A1A2E);
    final subColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final divColor = _divider(ctx);

    return Column(
      children: [
        Divider(height: 1, thickness: 1, color: divColor),
        // Profile row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1565C0),
                child: const Text(
                  'A',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Profile',
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Super Administrator',
                      style: TextStyle(color: subColor, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Theme toggle as small icon
              Tooltip(
                message: isDark ? 'Light mode' : 'Dark mode',
                child: InkWell(
                  onTap: themeProvider.toggle,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 16,
                      color: subColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Logout row
        InkWell(
          onTap: auth.logout,
          hoverColor: const Color(0xFFFFE5E5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: const [
                Icon(Icons.logout_outlined, size: 16, color: Color(0xFFE53E3E)),
                SizedBox(width: 10),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFE53E3E),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Material(
        color: _bg(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _logo(context),
            Divider(height: 1, thickness: 1, color: _divider(context)),
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
                      style: TextStyle(
                        color: _sectionLabel(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ..._cats.map((cat) => _categorySection(context, cat)),
                  const SizedBox(height: 4),
                  Divider(indent: 16, endIndent: 16, height: 16, color: _divider(context)),
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
            _adminProfile(context),
          ],
        ),
      ),
    );
  }
}
