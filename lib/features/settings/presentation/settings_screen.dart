import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/theme_provider.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.labelLarge),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Theme Section ─────────────────────────────────────────────
          _SectionHeader(title: 'Tampilan'),
          const SizedBox(height: 12),
          _ThemeToggleTile(),
          const SizedBox(height: 32),

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
  // ...existing code...
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.border),
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
          title: Text(title,
              style: AppTextStyles.labelMedium.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary)),
          subtitle: subtitle != null
              ? Text(subtitle!, style: AppTextStyles.bodySmall)
              : null,
          trailing: trailing ??
              (onTap != null
                  ? const Icon(Icons.chevron_right,
                      color: AppColors.textDisabled)
                  : null),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme Toggle Tile
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeToggleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          'Mode Tampilan',
          style: AppTextStyles.labelMedium.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary),
        ),
        subtitle: Text(
          themeMode == ThemeMode.dark
              ? 'Mode Gelap'
              : themeMode == ThemeMode.light
                  ? 'Mode Terang'
                  : 'Ikuti Sistem',
          style: AppTextStyles.bodySmall,
        ),
        trailing: PopupMenuButton<ThemeMode>(
          initialValue: themeMode,
          onSelected: (m) => ref.read(themeProvider.notifier).setThemeMode(m),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: ThemeMode.light,
              child: Row(children: [
                Icon(Icons.light_mode_outlined, size: 18),
                SizedBox(width: 10),
                Text('Mode Terang'),
              ]),
            ),
            const PopupMenuItem(
              value: ThemeMode.dark,
              child: Row(children: [
                Icon(Icons.dark_mode_outlined, size: 18),
                SizedBox(width: 10),
                Text('Mode Gelap'),
              ]),
            ),
            const PopupMenuItem(
              value: ThemeMode.system,
              child: Row(children: [
                Icon(Icons.brightness_auto_outlined, size: 18),
                SizedBox(width: 10),
                Text('Ikuti Sistem'),
              ]),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.expand_more_rounded,
                color: AppColors.primary, size: 20),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
