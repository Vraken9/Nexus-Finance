import 'package:flutter/material.dart';

/// Nexus Finance design-system color tokens.
/// Every color is defined as a [Color] constant — no magic numbers elsewhere.
abstract final class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0F172A); // Slate Blue/Dark
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color expense = Color(0xFFF43F5E); // Rose Red
  static const Color background = Color(0xFFF8FAFC); // Cool White

  // ── Surface & Borders ─────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // ── Chart ─────────────────────────────────────────────────────────────────
  static const Color chartLine = Color(0xFF0F172A);
  static const Color chartFillStart = Color(0x550F172A); // 33 % opacity
  static const Color chartFillEnd = Color(0x000F172A); // 0  % opacity

  // ── Transaction type accent ───────────────────────────────────────────────
  static const Color transfer = Color(0xFF3B82F6); // Slate Blue for transfers

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

  // ── Glass card overlay ────────────────────────────────────────────────────
  static const Color glassFill = Color(0x1AFFFFFF); // 10 % white
  static const Color glassBorder = Color(0x33FFFFFF); // 20 % white
}
