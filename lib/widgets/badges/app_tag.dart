import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

// Two variants:
// - neutral: stone background, used for generic labels
// - teal: teal-50 background, used for dietary restrictions and cuisine labels
enum AppTagVariant { neutral, teal }

class AppTag extends StatelessWidget {
  final String label;
  final AppTagVariant variant;

  const AppTag({
    super.key,
    required this.label,
    this.variant = AppTagVariant.neutral,
  });

  ({Color bg, Color border, Color text}) get _colors => switch (variant) {
        AppTagVariant.neutral => (
            bg: AppColors.field,
            border: AppColors.line,
            text: AppColors.ink2,
          ),
        AppTagVariant.teal => (
            bg: AppColors.teal50,
            border: AppColors.teal200,
            text: AppColors.tealDeep,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: AppRadii.fullAll,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
