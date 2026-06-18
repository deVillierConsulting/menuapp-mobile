import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

// The four button roles in MenuApp.
// Style is passed in — the widget itself is style-agnostic.
enum AppButtonStyle { primary, secondary, ghost, destructive }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed; // null = disabled
  final AppButtonStyle style;
  final bool expand; // true = full-width
  final Widget? leading; // optional icon to the left of label

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.expand = false,
    this.leading,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null;

  // Each style resolves to three decoration states: default, pressed, disabled.
  // We express "WidgetStateProperty" manually as a simple method here.
  BoxDecoration _decoration() {
    if (_disabled) return _disabledDecoration();
    if (_pressed) return _pressedDecoration();
    return _defaultDecoration();
  }

  BoxDecoration _defaultDecoration() {
    return switch (widget.style) {
      AppButtonStyle.primary => BoxDecoration(
          color: AppColors.accent,
          borderRadius: AppRadii.fullAll,
        ),
      AppButtonStyle.secondary => BoxDecoration(
          color: AppColors.field,
          borderRadius: AppRadii.fullAll,
          border: Border.all(color: AppColors.line),
        ),
      AppButtonStyle.ghost => BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppRadii.fullAll,
        ),
      AppButtonStyle.destructive => BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.fullAll,
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
    };
  }

  BoxDecoration _pressedDecoration() {
    return switch (widget.style) {
      AppButtonStyle.primary => BoxDecoration(
          // Darken accent ~8% on press — signals the tap registered.
          color: AppColors.accentDeep,
          borderRadius: AppRadii.fullAll,
        ),
      AppButtonStyle.secondary => BoxDecoration(
          color: AppColors.line,
          borderRadius: AppRadii.fullAll,
          border: Border.all(color: AppColors.line),
        ),
      AppButtonStyle.ghost => BoxDecoration(
          color: AppColors.field,
          borderRadius: AppRadii.fullAll,
        ),
      AppButtonStyle.destructive => BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: AppRadii.fullAll,
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
    };
  }

  BoxDecoration _disabledDecoration() => BoxDecoration(
        color: AppColors.field,
        borderRadius: AppRadii.fullAll,
      );

  TextStyle _labelStyle() {
    if (_disabled) {
      return AppTextStyles.button.copyWith(color: AppColors.ink4);
    }
    return switch (widget.style) {
      AppButtonStyle.primary =>
        AppTextStyles.button.copyWith(color: AppColors.surface),
      AppButtonStyle.secondary =>
        AppTextStyles.button.copyWith(color: AppColors.ink2),
      AppButtonStyle.ghost =>
        AppTextStyles.button.copyWith(color: AppColors.ink2),
      AppButtonStyle.destructive =>
        AppTextStyles.button.copyWith(color: AppColors.danger),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Semantics wraps the whole button so screen readers announce
    // the label and disabled state correctly.
    return Semantics(
      button: true,
      enabled: !_disabled,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: _disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: _disabled ? null : () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: widget.expand ? double.infinity : null,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: _decoration(),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: 18,
                    color: _labelStyle().color,
                  ),
                  child: widget.leading!,
                ),
                const SizedBox(width: 8),
              ],
              Text(widget.label, style: _labelStyle()),
            ],
          ),
        ),
      ),
    );
  }
}
