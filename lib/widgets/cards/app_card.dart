import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_shadows.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lgAll,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.line2),
        ),
        boxShadow: e1,
      ),
      // ClipRRect keeps the tap ripple (if onTap is set) inside the rounded corners.
      child: ClipRRect(
        borderRadius: AppRadii.lgAll,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                splashColor: AppColors.field,
                highlightColor: AppColors.field,
                child: Padding(padding: padding, child: child),
              )
            : Padding(padding: padding, child: child),
      ),
    );
  }
}
