import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_typography.dart';

// A tab definition — icon pair (outline/filled) + label.
// Outline = inactive, filled = active.
class _NavTab {
  final IconData icon;
  final IconData iconActive;
  final String label;

  const _NavTab({
    required this.icon,
    required this.iconActive,
    required this.label,
  });
}

const _tabs = [
  _NavTab(
    icon: LucideIcons.users,
    iconActive: LucideIcons.users,
    label: 'Groups',
  ),
  _NavTab(
    icon: LucideIcons.bookOpen,
    iconActive: LucideIcons.bookOpen,
    label: 'Recipes',
  ),
  _NavTab(
    icon: LucideIcons.shoppingCart,
    iconActive: LucideIcons.shoppingCart,
    label: 'Shop',
  ),
];

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // SafeArea padding keeps the bar above the home indicator on iPhone.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.fullAll,
            border: Border.all(color: AppColors.line),
            boxShadow: e2,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < _tabs.length; i++)
                  _NavItem(
                    tab: _tabs[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tab.label,
      selected: active,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? tab.iconActive : tab.icon,
                size: 22,
                color: active ? AppColors.ink : AppColors.ink4,
              ),
              const SizedBox(height: 3),
              Text(
                tab.label,
                style: AppTextStyles.label.copyWith(
                  color: active ? AppColors.accentDeep : AppColors.ink4,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
