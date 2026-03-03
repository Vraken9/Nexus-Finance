import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: _buildTextTheme(dark: false),
        appBarTheme: _buildAppBarTheme(dark: false),
        cardTheme: _buildCardTheme(dark: false),
        inputDecorationTheme: _buildInputDecorationTheme(dark: false),
        elevatedButtonTheme: _buildElevatedButtonTheme(),
        dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
        extensions: const [],
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.surfaceDark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: _buildTextTheme(dark: true),
        appBarTheme: _buildAppBarTheme(dark: true),
        cardTheme: _buildCardTheme(dark: true),
        inputDecorationTheme: _buildInputDecorationTheme(dark: true),
        elevatedButtonTheme: _buildElevatedButtonTheme(),
        dividerTheme: const DividerThemeData(color: AppColors.borderDark, thickness: 1),
        extensions: const [],
      );

  // ── Sub-themes ─────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme({required bool dark}) => TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        titleLarge: AppTextStyles.labelLarge,
        titleMedium: AppTextStyles.labelMedium,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelSmall: AppTextStyles.labelSmall,
      );

  static AppBarTheme _buildAppBarTheme({required bool dark}) => AppBarTheme(
        backgroundColor: dark ? AppColors.backgroundDark : AppColors.background,
        foregroundColor: dark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        centerTitle: false,
      );

  static CardThemeData _buildCardTheme({required bool dark}) => CardThemeData(
        color: dark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: dark ? AppColors.borderDark : AppColors.border),
        ),
        margin: EdgeInsets.zero,
      );

  static InputDecorationTheme _buildInputDecorationTheme({required bool dark}) {
    final radius = BorderRadius.circular(14);
    final borderColor = dark ? AppColors.borderDark : AppColors.border;
    final fillColor = dark ? AppColors.surfaceDark : AppColors.surface;
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.error)),
      labelStyle: AppTextStyles.labelMedium,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: AppTextStyles.labelLarge,
        ),
      );
}
