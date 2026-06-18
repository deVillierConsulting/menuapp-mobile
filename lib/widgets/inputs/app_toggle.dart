import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final toggle = Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: _Track(value: value),
      ),
    );

    if (label == null) return toggle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label!, style: AppTextStyles.body),
        const SizedBox(width: 10),
        toggle,
      ],
    );
  }
}

class _Track extends StatelessWidget {
  final bool value;
  static const _trackW = 48.0;
  static const _trackH = 28.0;
  static const _thumbD = 22.0;
  static const _padding = 3.0;

  const _Track({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _trackW,
      height: _trackH,
      decoration: BoxDecoration(
        color: value ? AppColors.accent : AppColors.line,
        borderRadius: BorderRadius.circular(_trackH / 2),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            top: _padding,
            left: value ? _trackW - _thumbD - _padding : _padding,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const SizedBox(width: _thumbD, height: _thumbD),
            ),
          ),
        ],
      ),
    );
  }
}
