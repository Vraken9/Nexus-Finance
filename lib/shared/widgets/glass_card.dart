import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// GlassCard
///
/// A frosted-glass card built with [BackdropFilter] and [ImageFilter.blur].
/// Used for the dashboard balance hero and summary cards.
///
/// [blur]        – sigma for the Gaussian blur (default 10)
/// [borderRadius]– corner radius (default 24)
/// [padding]     – inner padding (default 20)
/// ─────────────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(20),
    this.gradient,
  });

  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.glassFill,
                    AppColors.glassFill.withAlpha(8),
                  ],
                ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
