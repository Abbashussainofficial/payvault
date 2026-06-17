import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import 'backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _db = AppDatabase.instance;
  AppSetting? _settings;
  bool _loading = true;
  bool _exporting = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _db.appSettingsDao.getSettings();
    if (mounted) {
      setState(() {
        _settings = s;
        _loading = false;
      });
    }
  }

  Future<void> _export() async {
    final path = await BackupService.chooseSavePath();
    if (path == null || !mounted) return;
    setState(() => _exporting = true);
    try {
      await BackupService.exportTo(path);
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved: $path'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _import() async {
    final path = await BackupService.chooseImportPath();
    if (path == null || !mounted) return;

    setState(() => _importing = true);
    try {
      final meta = await BackupService.parseFile(path);
      if (!mounted) return;

      final confirmed = await _showRestoreDialog(meta);
      if (confirmed != true) {
        if (mounted) setState(() => _importing = false);
        return;
      }

      await BackupService.restoreFrom(meta);
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<bool?> _showRestoreDialog(BackupMeta meta) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100)),
            SizedBox(width: 10),
            Text('Restore Backup?'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently replace ALL current data with the backup.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                'Backup date',
                DateFormat('MMM d, yyyy  •  hh:mm a').format(meta.exportedAt),
              ),
              _InfoRow('Employees', '${meta.employeeCount}'),
              _InfoRow('Salary components', '${meta.componentCount}'),
              _InfoRow('Payroll records', '${meta.recordCount}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 15, color: Color(0xFFE65100)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. Export a new backup first if you want to keep current data.',
                        style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateReminderDays(int days) async {
    await _db.appSettingsDao.updateBackupReminder(days);
    await _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _SectionCard(
                      title: 'Backup Status',
                      child: _buildStatusSection(context),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Actions',
                      child: _buildActionsSection(context),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Backup Reminder',
                      child: _buildReminderSection(context),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backup & Restore',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Export all data to a .pvault file or restore from a previous backup.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lastDate = _settings?.lastBackupDate;
    final lastDt = lastDate != null ? DateTime.tryParse(lastDate) : null;
    final hasBackup = lastDt != null;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasBackup
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            hasBackup ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: hasBackup ? Colors.green.shade600 : Colors.orange.shade700,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasBackup ? 'Last backup' : 'No backup found',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                hasBackup
                    ? DateFormat('EEEE, MMM d, yyyy  •  hh:mm a').format(lastDt)
                    : 'Export a backup to keep your data safe.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              if (hasBackup) ...[
                const SizedBox(height: 8),
                _DaysAgoChip(lastDt: lastDt),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final busy = _exporting || _importing;

    return Column(
      children: [
        _ActionTile(
          icon: Icons.upload_file_outlined,
          iconColor: cs.primary,
          title: 'Export Backup',
          subtitle: 'Save all employees, salary data, and payroll records to a .pvault file.',
          loading: _exporting,
          onTap: busy ? null : _export,
          buttonLabel: 'Export',
          buttonColor: cs.primary,
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.download_outlined,
          iconColor: const Color(0xFFE65100),
          title: 'Import / Restore Backup',
          subtitle: 'Replace all current data with the contents of a .pvault backup file.',
          loading: _importing,
          onTap: busy ? null : _import,
          buttonLabel: 'Import',
          buttonColor: const Color(0xFFD32F2F),
        ),
      ],
    );
  }

  Widget _buildReminderSection(BuildContext context) {
    const options = {
      1: 'Daily',
      7: 'Weekly',
      14: 'Every 2 weeks',
      30: 'Monthly',
      0: 'Off',
    };
    final current = _settings?.backupReminderDays ?? 7;
    final dropdownValue = options.containsKey(current) ? current : 7;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remind me to backup',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 2),
              Text(
                'A reminder will appear on the dashboard when backup is overdue.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        InputDecorator(
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: DropdownButton<int>(
            value: dropdownValue,
            isDense: true,
            underline: const SizedBox.shrink(),
            items: options.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) {
              if (v != null) _updateReminderDays(v);
            },
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DaysAgoChip extends StatelessWidget {
  const _DaysAgoChip({required this.lastDt});
  final DateTime lastDt;

  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(lastDt).inDays;
    final label = days == 0
        ? 'Today'
        : days == 1
            ? 'Yesterday'
            : '$days days ago';
    final isOverdue = days >= 14;

    return Chip(
      avatar: Icon(
        isOverdue ? Icons.warning_amber_outlined : Icons.check_circle_outline,
        size: 14,
        color: isOverdue ? Colors.orange.shade700 : Colors.green.shade600,
      ),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onTap,
    required this.buttonLabel,
    required this.buttonColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback? onTap;
  final String buttonLabel;
  final Color buttonColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 90,
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: buttonColor),
                    onPressed: onTap,
                    child: Text(buttonLabel),
                  ),
          ),
        ],
      ),
    );
  }
}
