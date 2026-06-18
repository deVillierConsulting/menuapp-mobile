import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

enum AppBadgeVariant { ok, warn, danger, info, teal, muted }

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;

  const AppBadge({
    super.key,
    required this.label,
    required this.variant,
  });

  // Each variant resolves to a dot color and an optional text color override.
  // Text defaults to ink — only teal and muted deviate.
  ({Color dot, Color text}) get _colors => switch (variant) {
        AppBadgeVariant.ok => (dot: AppColors.ok, text: AppColors.ink),
        AppBadgeVariant.warn => (dot: AppColors.warn, text: AppColors.ink),
        AppBadgeVariant.danger => (dot: AppColors.danger, text: AppColors.ink),
        AppBadgeVariant.info => (dot: AppColors.accent, text: AppColors.ink),
        AppBadgeVariant.teal => (dot: AppColors.teal, text: AppColors.tealDeep),
        AppBadgeVariant.muted => (dot: AppColors.ink4, text: AppColors.ink3),
      };

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.fullAll,
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.dot,
                borderRadius: AppRadii.fullAll,
              ),
              child: const SizedBox(width: 7, height: 7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
