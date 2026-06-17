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

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your PayVault preferences.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 28),
              _AppearanceSection(),
              const SizedBox(height: 16),
              _SecuritySection(),
              const SizedBox(height: 16),
              _BackupLinkSection(onNavigate: onNavigate),
              const SizedBox(height: 16),
              const _AboutSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Appearance ────────────────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return _SettingsCard(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      children: [
        _SettingsRow(
          label: 'Dark mode',
          subtitle: themeProvider.isDark ? 'Currently using dark theme' : 'Currently using light theme',
          trailing: Switch(
            value: themeProvider.isDark,
            onChanged: (_) => themeProvider.toggle(),
          ),
        ),
      ],
    );
  }
}

// ── Security ──────────────────────────────────────────────────────────────────

class _SecuritySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Security',
      icon: Icons.security_outlined,
      children: [
        _SettingsRow(
          label: 'Change Password',
          subtitle: 'Update your login password.',
          trailing: OutlinedButton.icon(
            icon: const Icon(Icons.lock_reset_outlined, size: 16),
            label: const Text('Change'),
            onPressed: () => _showChangePasswordDialog(context),
          ),
        ),
        const Divider(height: 24),
        _SettingsRow(
          label: 'Security Question',
          subtitle: 'Update your password recovery question and answer.',
          trailing: OutlinedButton.icon(
            icon: const Icon(Icons.help_outline, size: 16),
            label: const Text('Update'),
            onPressed: () => _showChangeSecurityDialog(context),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ChangePasswordDialog(
        auth: context.read<AuthProvider>(),
      ),
    );
  }

  void _showChangeSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ChangeSecurityDialog(
        auth: context.read<AuthProvider>(),
      ),
    );
  }
}

// ── Backup Link ───────────────────────────────────────────────────────────────

class _BackupLinkSection extends StatelessWidget {
  final ValueChanged<String>? onNavigate;
  const _BackupLinkSection({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Backup & Restore',
      icon: Icons.cloud_upload_outlined,
      children: [
        _SettingsRow(
          label: 'Manage Backups',
          subtitle: 'Export data to a .pvault file or restore from a backup.',
          trailing: FilledButton.icon(
            icon: const Icon(Icons.open_in_new, size: 15),
            label: const Text('Open Backup'),
            onPressed: onNavigate != null
                ? () => onNavigate!(NavRoute.backup)
                : null,
          ),
        ),
      ],
    );
  }
}

// ── About ─────────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return _SettingsCard(
      title: 'About',
      icon: Icons.info_outline,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PayVault',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
                Text(
                  'Version 1.0.0',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Offline Salary Management System',
          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'PayVault is a secure, fully offline desktop application for managing employee payroll across multiple categories. All data is stored locally on your device.',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(icon: Icons.people_outline, label: 'PEDO Employees'),
            _Pill(icon: Icons.shield_outlined, label: 'Security Guards'),
            _Pill(icon: Icons.star_outline, label: 'Al Fajar'),
            _Pill(icon: Icons.lock_outline, label: 'Fully Offline'),
          ],
        ),
      ],
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
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newCtrl.text.length < 4) {
      setState(() => _error = 'New password must be at least 4 characters.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await widget.auth.changePassword(
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _error = widget.auth.errorMessage ?? 'Failed to change password.';
        _loading = false;
      });
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
              controller: _currentCtrl,
              obscureText: _obscureCurrent,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
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
  void initState() {
    super.initState();
    _selectedQuestion = widget.auth.securityQuestion;
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedQuestion == null || _selectedQuestion!.isEmpty) {
      setState(() => _error = 'Please select a security question.');
      return;
    }
    if (_answerCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter an answer.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await widget.auth.changeSecurityQuestion(
      question: _selectedQuestion!,
      answer: _answerCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security question updated.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _error = widget.auth.errorMessage ?? 'Failed to update.';
        _loading = false;
      });
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
                labelText: 'Security Question',
                prefixIcon: Icon(Icons.help_outline),
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: DropdownButton<String>(
                value: _questions.contains(_selectedQuestion)
                    ? _selectedQuestion
                    : null,
                isExpanded: true,
                isDense: true,
                underline: const SizedBox.shrink(),
                hint: const Text('Select a question'),
                items: _questions
                    .map((q) => DropdownMenuItem(
                          value: q,
                          child: Text(
                            q,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedQuestion = v),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Your Answer',
                prefixIcon: Icon(Icons.question_answer_outlined),
              ),
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ── Shared layout widgets ─────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
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

class _SettingsRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final Widget trailing;

  const _SettingsRow({
    required this.label,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        trailing,
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 15, color: Color(0xFFE53E3E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
