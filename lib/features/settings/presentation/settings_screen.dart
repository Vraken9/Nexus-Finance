import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../shared/providers/repository_providers.dart';
import '../domain/export_service.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// SettingsScreen
///
/// App-level settings: export, account management, and app info.
/// ─────────────────────────────────────────────────────────────────────────
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.labelLarge),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Export Section ────────────────────────────────────────────
          _SectionHeader(title: 'Export'),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.table_chart_outlined,
            title: AppStrings.exportCSV,
            subtitle: 'Save this month\'s transactions as CSV to /Documents',
            onTap: _isExporting ? null : () => _exportCSV(context),
            trailing: _isExporting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 32),

          // ── About ─────────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Nexus Finance',
            subtitle: 'Version 1.0.0 • Built with Flutter & Isar',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Future<void> _exportCSV(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final now = DateTime.now();
      final txns = ref
          .read(transactionRepositoryProvider)
          .getByMonth(now);

      const service = ExportService();
      final path = await service.exportCSV(txns, now);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $path'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.exportFailed),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Local widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: AppTextStyles.chipLabel.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary)),
          subtitle: subtitle != null
              ? Text(subtitle!, style: AppTextStyles.bodySmall)
              : null,
          trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.textDisabled) : null),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}
