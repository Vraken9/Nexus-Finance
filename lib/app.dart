import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/transactions/presentation/transactions_screen.dart';
import 'shared/providers/isar_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/services/dummy_seed_service.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// NexusApp
///
/// Root widget wrapped in [ProviderScope]. Watches [isarProvider] so the app
/// waits for the database to be fully open before rendering any feature screen.
/// ─────────────────────────────────────────────────────────────────────────
class NexusApp extends ConsumerWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Nexus Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const _AppShell(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App shell with bottom navigation
// ─────────────────────────────────────────────────────────────────────────────

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell();

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    DashboardScreen(),
    TransactionsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Block rendering until Isar is ready.
    final isarState = ref.watch(isarProvider);

    return isarState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Text('Failed to open database: $err',
              style: AppTextStyles.bodyMedium),
        ),
      ),
      data: (_) {
        // Seed dummy February 2026 data once when DB is ready (safe no-op if already present).
        scheduleMicrotask(() => DummySeedService.ensureFebruary2026(ref));
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: _NexusNavBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom bottom nav bar
// ─────────────────────────────────────────────────────────────────────────────

class _NexusNavBar extends StatelessWidget {
  const _NexusNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.grid_view_rounded, label: 'Dashboard'),
    (icon: Icons.receipt_long_outlined, label: 'Transactions'),
    (icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isSelected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withAlpha(20)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textDisabled,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textDisabled,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
