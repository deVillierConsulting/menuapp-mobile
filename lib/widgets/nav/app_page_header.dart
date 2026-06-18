import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// A sliver — must be placed inside a [CustomScrollView].
class AppPageHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final List<Widget> actions;

  const AppPageHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar.large(
      automaticallyImplyLeading: showBack,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppColors.accent,
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(title),
      titleTextStyle: AppTextStyles.h2.copyWith(color: AppColors.ink),
      // Large title (collapsed into the expandable area below).
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: AppTextStyles.display.copyWith(color: AppColors.ink),
        ),
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedTitleScale: 1.0,
      ),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      actions: actions,
    );
  }
}
