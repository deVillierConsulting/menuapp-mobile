import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

class AppListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;   // typically an AppAvatar
  final Widget? trailing;  // badge, chevron, value text
  final VoidCallback? onTap;
  final bool showDivider;

  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          splashColor: AppColors.field,
          highlightColor: AppColors.field,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.bodyMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: AppColors.line2),
      ],
    );
  }
}

// Companion widget — the circular avatar used as AppListRow's leading slot.
// Lives here because it has no use outside of list contexts.
class AppAvatar extends StatelessWidget {
  final String initials;

  const AppAvatar({super.key, required this.initials});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.accent200,
        borderRadius: AppRadii.fullAll,
      ),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text(
            initials.toUpperCase(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.accentDeep,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
