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

// ── Sidebar colours (always dark navy regardless of app theme) ────────────────

const _kNavBg = Color(0xFF1B2235);
const _kActiveBg = Color(0xFF253050);
const _kActiveAccent = Color(0xFF4A9EFF);
const _kTextActive = Colors.white;
const _kTextInactive = Color(0xFFB0B8CC);
const _kDivider = Color(0x1AFFFFFF);
const _kSectionLabel = Color(0xFF8899BB);

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
    _Cat('pedo', 'Employees', Icons.people_outline),
    _Cat('security', 'Security Guards', Icons.shield_outlined),
    _Cat('alfajar', 'Al Fajar', Icons.star_outline),
  ];

  static const _subs = [
    _Sub('Employee List', Icons.list_outlined, 'list'),
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

  Widget _logo() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'PayVault',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.2),
              ),
              SizedBox(height: 1),
              Text(
                'Payroll Management',
                style: TextStyle(color: _kSectionLabel, fontSize: 10, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    double leftPad = 14,
    double iconSize = 18,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: EdgeInsets.only(left: leftPad, right: 8, top: 9, bottom: 9),
        decoration: BoxDecoration(
          color: isActive ? _kActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: iconSize, color: isActive ? _kActiveAccent : _kTextInactive),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? _kTextActive : _kTextInactive,
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

  Widget _categorySection(_Cat cat) {
    final isExpanded = _expanded[cat.id] ?? false;
    final isCatActive = _isCatActive(cat.id);

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded[cat.id] = !isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            padding: const EdgeInsets.only(left: 14, right: 8, top: 9, bottom: 9),
            decoration: BoxDecoration(
              color: isCatActive && !isExpanded ? _kActiveBg : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(cat.icon, size: 18, color: isCatActive ? _kActiveAccent : _kTextInactive),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat.label,
                    style: TextStyle(
                      color: isCatActive ? _kTextActive : _kTextInactive,
                      fontWeight: isCatActive ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0.25 : 0,
                  child: const Icon(Icons.chevron_right, size: 16, color: _kSectionLabel),
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
                  children: _subs.map((sub) {
                    final routeId = NavRoute.cat(cat.id, sub.section);
                    return _navItem(
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

  Widget _bottomControls() {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.read<AuthProvider>();
    final isDark = themeProvider.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _SidebarButton(
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              label: isDark ? 'Light' : 'Dark',
              onTap: themeProvider.toggle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SidebarButton(
              icon: Icons.logout_outlined,
              label: 'Logout',
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
    return SizedBox(
      width: 220,
      child: Material(
        color: _kNavBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _logo(),
            const Divider(height: 1, thickness: 1, color: _kDivider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _navItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    isActive: _isActive(NavRoute.dashboard),
                    onTap: () => widget.onRouteChanged(NavRoute.dashboard),
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'CATEGORIES',
                      style: TextStyle(color: _kSectionLabel, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                    ),
                  ),
                  ..._cats.map((cat) => _categorySection(cat)),
                  const SizedBox(height: 4),
                  const Divider(indent: 16, endIndent: 16, height: 16, color: _kDivider),
                  _navItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isActive: _isActive(NavRoute.settings),
                    onTap: () => widget.onRouteChanged(NavRoute.settings),
                  ),
                  _navItem(
                    icon: Icons.cloud_upload_outlined,
                    label: 'Backup',
                    isActive: _isActive(NavRoute.backup),
                    onTap: () => widget.onRouteChanged(NavRoute.backup),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _kDivider),
            _bottomControls(),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar bottom button ─────────────────────────────────────────────────────

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFFC8181) : _kTextInactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF253050),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
