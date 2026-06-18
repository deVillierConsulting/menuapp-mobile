import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

enum AppSnackbarVariant { info, success, error }

class AppSnackbar {
  // Not instantiable — static helpers only.
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarVariant variant = AppSnackbarVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context)
      // Dismiss any existing snackbar before showing the new one.
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // Transparent so our DecoratedBox owns the appearance.
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Push above the nav bar.
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: _SnackbarContent(
            message: message,
            variant: variant,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
        ),
      );
  }
}

class _SnackbarContent extends StatelessWidget {
  final String message;
  final AppSnackbarVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SnackbarContent({
    required this.message,
    required this.variant,
    this.actionLabel,
    this.onAction,
  });

  Color get _background => switch (variant) {
        AppSnackbarVariant.success => AppColors.ok,
        AppSnackbarVariant.error   => AppColors.danger,
        AppSnackbarVariant.info    => AppColors.ink,
      };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _background,
        borderRadius: AppRadii.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(color: AppColors.surface),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionLabel!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.surface,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.surface,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
