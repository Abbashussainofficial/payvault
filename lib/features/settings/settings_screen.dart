import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/auth_provider.dart';
import '../../shared/theme/theme_provider.dart';
import '../../shared/widgets/sidebar.dart';

class SettingsScreen extends StatelessWidget {
  final ValueChanged<String>? onNavigate;
  const SettingsScreen({this.onNavigate, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text('Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Icon(Icons.calendar_today_outlined, size: 17, color: cs.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 12),
                Icon(Icons.access_time_outlined, size: 17, color: cs.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: const Color(0xFF1565C0),
                      child: const Text('A', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 7),
                    Text('Admin User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  ]),
                ),
              ],
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AppearanceSection(),
                      const SizedBox(height: 16),
                      _SecuritySection(),
                      const SizedBox(height: 16),
                      _BackupSection(onNavigate: onNavigate),
                      const SizedBox(height: 16),
                      const _AboutSection(),
                      const SizedBox(height: 24),
                      // Footer
                      Column(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '© 2024 PayVault Offline. All rights reserved.',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appearance ────────────────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SettingsCard(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      children: [
        // Theme Mode
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme Mode',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('Switch between Light and Dark mode',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  _ThemeToggle(
                    label: 'Light',
                    icon: Icons.wb_sunny_outlined,
                    selected: !themeProvider.isDark,
                    onTap: () { if (themeProvider.isDark) themeProvider.toggle(); },
                    cs: cs, isDark: isDark,
                  ),
                  const SizedBox(width: 4),
                  _ThemeToggle(
                    label: 'Dark',
                    icon: Icons.dark_mode_outlined,
                    selected: themeProvider.isDark,
                    onTap: () { if (!themeProvider.isDark) themeProvider.toggle(); },
                    cs: cs, isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        // Compact View
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Compact View',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('Maximize data density in tables',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Switch(
              value: themeProvider.isCompact,
              onChanged: (_) => themeProvider.toggleCompact(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  final bool isDark;
  const _ThemeToggle({required this.label, required this.icon, required this.selected, required this.onTap, required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? (isDark ? const Color(0xFF2A2A3E) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.45)),
            const SizedBox(width: 5),
            Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? cs.onSurface : cs.onSurface.withValues(alpha: 0.55),
              )),
          ],
        ),
      ),
    );
  }
}

// ── Security ──────────────────────────────────────────────────────────────────

class _SecuritySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _SettingsCard(
      title: 'Security',
      icon: Icons.security_outlined,
      children: [
        // Change password row
        InkWell(
          onTap: () => _showChangePasswordDialog(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lock_outline, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Change Admin Password',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                      Text('Update your security credentials',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        // 2FA row
        Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phonelink_lock_outlined, size: 18, color: Color(0xFF1565C0)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Two-Factor Authentication',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  Text('Offline physical key required',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3)),
              ),
              child: const Text('ENABLED',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF27AE60), letterSpacing: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        // Security question
        InkWell(
          onTap: () => _showChangeSecurityDialog(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.help_outline, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security Question',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                      Text('Update your password recovery question and answer',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => _ChangePasswordDialog(auth: context.read<AuthProvider>()));
  }

  void _showChangeSecurityDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => _ChangeSecurityDialog(auth: context.read<AuthProvider>()));
  }
}

// ── Backup ────────────────────────────────────────────────────────────────────

class _BackupSection extends StatelessWidget {
  final ValueChanged<String>? onNavigate;
  const _BackupSection({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SettingsCard(
      title: 'Backup & Restore',
      icon: Icons.cloud_upload_outlined,
      trailing: Text(
        'Last: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
      ),
      children: [
        Row(
          children: [
            Expanded(child: _BackupCard(
              icon: Icons.file_download_outlined,
              iconColor: const Color(0xFF27AE60),
              title: 'Export Data',
              subtitle: 'Download .pvault database',
              isDark: isDark, cs: cs,
              onTap: onNavigate != null ? () => onNavigate!(NavRoute.backup) : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: _BackupCard(
              icon: Icons.file_upload_outlined,
              iconColor: const Color(0xFF1565C0),
              title: 'Import Backup',
              subtitle: 'Restore from local file',
              isDark: isDark, cs: cs,
              onTap: onNavigate != null ? () => onNavigate!(NavRoute.backup) : null,
            )),
          ],
        ),
      ],
    );
  }
}

class _BackupCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback? onTap;

  const _BackupCard({required this.icon, required this.iconColor, required this.title,
    required this.subtitle, required this.isDark, required this.cs, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}

// ── About ─────────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  void _openWebsite() {
    Process.run('cmd', ['/c', 'start', '', 'https://www.adivantech.com']);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _SettingsCard(
      title: 'About PayVault',
      icon: Icons.info_outline,
      children: [
        _AboutRow(label: 'Version', value: '1.0.0 (Production Build)', cs: cs),
        const SizedBox(height: 12),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        _AboutRow(label: 'Developer', value: 'Abbas Hussain', cs: cs),
        const SizedBox(height: 12),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        _AboutRow(label: 'Company', value: 'Adivantech (Pvt) Ltd.', cs: cs),
        const SizedBox(height: 12),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text('Website',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                )),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _openWebsite,
                child: Text(
                  'www.adivantech.com',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: cs.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  const _AboutRow({required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)))),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Shared card ───────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: cs.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (trailing != null) ...[const Spacer(), trailing!],
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ── Dialogs ───────────────────────────────────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  final AuthProvider auth;
  const _ChangePasswordDialog({required this.auth});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  String? _error;
  bool _loading = false;

  @override
  void dispose() { _currentCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_newCtrl.text.length < 4) { setState(() => _error = 'New password must be at least 4 characters.'); return; }
    if (_newCtrl.text != _confirmCtrl.text) { setState(() => _error = 'New passwords do not match.'); return; }
    setState(() { _loading = true; _error = null; });
    final ok = await widget.auth.changePassword(currentPassword: _currentCtrl.text, newPassword: _newCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully.'), backgroundColor: Colors.green));
    } else {
      setState(() { _error = widget.auth.errorMessage ?? 'Failed to change password.'; _loading = false; });
      widget.auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentCtrl, obscureText: _obscureCurrent, autofocus: true,
              decoration: InputDecoration(
                labelText: 'Current Password', prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newCtrl, obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password', prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.lock_outline)),
              onSubmitted: (_) => _loading ? null : _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Update Password'),
        ),
      ],
    );
  }
}

class _ChangeSecurityDialog extends StatefulWidget {
  final AuthProvider auth;
  const _ChangeSecurityDialog({required this.auth});

  @override
  State<_ChangeSecurityDialog> createState() => _ChangeSecurityDialogState();
}

class _ChangeSecurityDialogState extends State<_ChangeSecurityDialog> {
  static const _questions = [
    'What was the name of your first pet?',
    'What city were you born in?',
    "What is your mother's maiden name?",
    'What was the name of your first school?',
    'What is your favorite book?',
  ];

  String? _selectedQuestion;
  final _answerCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void initState() { super.initState(); _selectedQuestion = widget.auth.securityQuestion; }

  @override
  void dispose() { _answerCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_selectedQuestion == null || _selectedQuestion!.isEmpty) { setState(() => _error = 'Please select a security question.'); return; }
    if (_answerCtrl.text.trim().isEmpty) { setState(() => _error = 'Please enter an answer.'); return; }
    setState(() { _loading = true; _error = null; });
    final ok = await widget.auth.changeSecurityQuestion(question: _selectedQuestion!, answer: _answerCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Security question updated.'), backgroundColor: Colors.green));
    } else {
      setState(() { _error = widget.auth.errorMessage ?? 'Failed to update.'; _loading = false; });
      widget.auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Security Question'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Security Question', prefixIcon: Icon(Icons.help_outline),
                isDense: true, border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: DropdownButton<String>(
                value: _questions.contains(_selectedQuestion) ? _selectedQuestion : null,
                isExpanded: true, isDense: true, underline: const SizedBox.shrink(),
                hint: const Text('Select a question'),
                items: _questions.map((q) => DropdownMenuItem(value: q, child: Text(q, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedQuestion = v),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerCtrl, autofocus: true,
              decoration: const InputDecoration(labelText: 'Your Answer', prefixIcon: Icon(Icons.question_answer_outlined)),
              onSubmitted: (_) => _loading ? null : _submit(),
            ),
            if (_error != null) ...[const SizedBox(height: 12), _ErrorBanner(message: _error!)],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFEB2B2)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 15, color: Color(0xFFE53E3E)),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 13))),
      ]),
    );
  }
}
