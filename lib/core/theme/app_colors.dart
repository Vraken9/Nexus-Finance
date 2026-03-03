import 'package:flutter/material.dart';

/// Nexus Finance design-system color tokens.
/// Every color is defined as a [Color] constant — no magic numbers elsewhere.
abstract final class AppColors {
  // ── Brand (shared) ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0F172A); // Slate Blue/Dark
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color expense = Color(0xFFF43F5E); // Rose Red

  // ── Light mode ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // ── Dark mode ─────────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF273348);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textDisabledDark = Color(0xFF475569);

  // ── Chart ─────────────────────────────────────────────────────────────────
  static const Color chartLine = Color(0xFF0F172A);
  static const Color chartFillStart = Color(0x550F172A);
  static const Color chartFillEnd = Color(0x000F172A);
  static const Color chartLineDark = Color(0xFF94A3B8);
  static const Color chartFillStartDark = Color(0x5594A3B8);
  static const Color chartFillEndDark = Color(0x0094A3B8);

  // ── Transaction type accent ───────────────────────────────────────────────
  static const Color transfer = Color(0xFF3B82F6);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

  // ── Glass card overlay ────────────────────────────────────────────────────
  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
}
