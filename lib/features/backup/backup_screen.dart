import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
  AppSetting? _settings;
  bool _exporting = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final s = await AppDatabase.instance.appSettingsDao.getSettings();
      if (mounted) setState(() => _settings = s);
    } catch (_) {}
  }

  // ── Export ──────────────────────────────────────────────────────────────────

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final path = await BackupService.exportBackupToExcel();
      if (path == null) return; // user cancelled folder picker
      await _loadSettings();
      if (mounted) {
        final fileName = path.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved successfully: $fileName'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 5),
            showCloseIcon: true,
            closeIconColor: Colors.white,
            action: SnackBarAction(
              label: 'Show in Folder',
              textColor: Colors.white,
              onPressed: () => Process.run('explorer.exe', ['/select,', path]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Import / Restore ────────────────────────────────────────────────────────

  Future<void> _import() async {
    // Step 1: pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
      dialogTitle: 'Open PayVault Excel Backup (.xlsx)',
      lockParentWindow: true,
    );
    if (result == null || !mounted) return;
    final path = result.files.single.path;
    if (path == null) return;

    // Step 2: parse file (show loading)
    setState(() => _importing = true);
    ExcelBackupMeta meta;
    try {
      meta = await BackupService.parseExcelBackup(path);
    } catch (e) {
      if (mounted) {
        setState(() => _importing = false);
        final msg = e is FormatException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 8),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _importing = false);

    // Step 3: confirmation dialog
    final confirmed = await _showRestoreDialog(meta);
    if (confirmed != true || !mounted) return;

    // Step 4: restore (show loading again)
    setState(() => _importing = true);
    try {
      await BackupService.restoreFromExcelData(meta);
      if (mounted) {
        setState(() => _importing = false);
        _showRestoreSuccessDialog(meta);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _importing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  Future<bool?> _showRestoreDialog(ExcelBackupMeta meta) {
    final dateStr = DateFormat('MMM d, yyyy  •  hh:mm a').format(meta.backupDate);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 26),
            SizedBox(width: 10),
            Text('Restore Backup?'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This backup contains:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _BulletRow('${meta.totalEmployees} Employees'),
              _BulletRow('${meta.totalComponents} Salary Components'),
              _BulletRow('${meta.totalPayrollRecords} Payroll Records'),
              const SizedBox(height: 12),
              _InfoRow('Backup Date', dateStr),
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
                        'WARNING: All current data will be permanently deleted and '
                        'replaced with this backup. This cannot be undone.',
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
            child: const Text('Restore Now'),
          ),
        ],
      ),
    );
  }

  void _showRestoreSuccessDialog(ExcelBackupMeta meta) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 26),
            SizedBox(width: 10),
            Text('Restore Complete!'),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow('Employees restored', '${meta.totalEmployees}'),
              const SizedBox(height: 6),
              _InfoRow('Salary components restored', '${meta.totalComponents}'),
              const SizedBox(height: 6),
              _InfoRow('Payroll records restored', '${meta.totalPayrollRecords}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.refresh, size: 15, color: Color(0xFF2E7D32)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please restart the app to ensure all data loads correctly.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
            onPressed: () => exit(0),
            child: const Text('Restart App'),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lastDate = _settings?.lastBackupDate;
    final lastDt = lastDate != null ? DateTime.tryParse(lastDate) : null;
    final lastBackupText = lastDt != null
        ? DateFormat('MMM d, yyyy  •  hh:mm a').format(lastDt)
        : 'Never';
    final busy = _exporting || _importing;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Text(
                'Backup & Restore',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Export all data to an Excel file and restore from it anytime.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
              ),
              const SizedBox(height: 28),

              // ── Backup Card ───────────────────────────────────────────────
              _ActionCard(
                icon: Icons.save_alt_outlined,
                iconBg: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1565C0),
                cardBorder: const Color(0xFF90CAF9),
                title: 'Export Backup to Excel',
                subtitle: 'Last backup: $lastBackupText',
                buttonLabel: 'Backup Now',
                buttonColor: const Color(0xFF1565C0),
                loading: _exporting,
                onPressed: busy ? null : _export,
              ),
              const SizedBox(height: 16),

              // ── Restore Card ──────────────────────────────────────────────
              _ActionCard(
                icon: Icons.restore_outlined,
                iconBg: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFE65100),
                cardBorder: const Color(0xFFFFB74D),
                title: 'Restore from Excel Backup',
                subtitle: '⚠️  This will replace ALL current data',
                buttonLabel: 'Restore Backup',
                buttonColor: const Color(0xFFD32F2F),
                loading: _importing,
                onPressed: busy ? null : _import,
              ),
              const SizedBox(height: 28),

              // ── Tip ───────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E2A1A)
                      : const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF388E3C)
                        : const Color(0xFFA5D6A7),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 18, color: Color(0xFF388E3C)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Keep your backup file in a safe location like a USB drive '
                        'or external hard disk. Backup regularly to avoid data loss.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF2E7D32),
                              height: 1.5,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.cardBorder,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonColor,
    required this.loading,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconBg, iconColor, cardBorder;
  final String title, subtitle, buttonLabel;
  final Color buttonColor;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
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
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onPressed,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Text('  •  ',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(text),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
