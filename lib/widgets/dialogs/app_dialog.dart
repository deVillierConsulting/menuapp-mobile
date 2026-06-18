import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_button.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String? body;
  final Widget? icon;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final AppButtonStyle confirmStyle;

  const AppDialog({
    super.key,
    required this.title,
    this.body,
    this.icon,
    this.confirmLabel = 'Confirm',
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.confirmStyle = AppButtonStyle.primary,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? body,
    Widget? icon,
    String confirmLabel = 'Confirm',
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    AppButtonStyle confirmStyle = AppButtonStyle.primary,
  }) {
    return showDialog<T>(
      context: context,
      // Tapping outside dismisses the dialog.
      barrierDismissible: cancelLabel != null,
      builder: (_) => AppDialog(
        title: title,
        body: body,
        icon: icon,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmStyle: confirmStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.lgAll),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Center(child: icon!),
              const SizedBox(height: 16),
            ],
            Text(title, style: AppTextStyles.h2, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                style: AppTextStyles.body.copyWith(color: AppColors.ink3),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: confirmLabel,
              style: confirmStyle,
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
            ),
            if (cancelLabel != null) ...[
              const SizedBox(height: 8),
              AppButton(
                label: cancelLabel!,
                style: AppButtonStyle.ghost,
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
