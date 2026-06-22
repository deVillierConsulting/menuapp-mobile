import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final Color? selectedColor;
  final double verticalPadding;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.selectedColor,
    this.verticalPadding = 8,
  });

  @override
  Widget build(BuildContext context) {
    final fill = selectedColor ?? AppColors.accent;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!selected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: verticalPadding),
          decoration: BoxDecoration(
            color: selected ? fill : AppColors.surface,
            borderRadius: AppRadii.fullAll,
            border: Border.all(
              color: selected ? fill : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: selected ? AppColors.surface : AppColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
