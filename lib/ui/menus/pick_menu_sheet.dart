import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/pick_menu/pick_menu_cubit.dart';
import '../../data/menus_data_source.dart';
import '../../data/models/active_menu_summary.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../widgets/states/error_state.dart';

Future<void> showPickMenuSheet(
  BuildContext context, {
  required int recipeId,
  required MenusDataSource menusDataSource,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider(
      create: (_) => PickMenuCubit(
        dataSource: menusDataSource,
        recipeId: recipeId,
      )..load(),
      child: const _PickMenuSheetBody(),
    ),
  );
}

class _PickMenuSheetBody extends StatelessWidget {
  const _PickMenuSheetBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: AppRadii.fullAll,
                  ),
                  child: const SizedBox(width: 36, height: 4),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add to menu', style: AppTextStyles.h2),
              const SizedBox(height: 6),
              Text(
                'Choose a menu that\'s currently being planned.',
                style: AppTextStyles.body.copyWith(color: AppColors.ink3),
              ),
              const SizedBox(height: 20),
              BlocBuilder<PickMenuCubit, PickMenuState>(
                builder: (context, state) {
                  if (state is PickMenuLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (state is PickMenuError) {
                    return ErrorState(
                      message: state.message,
                      onRetry: () => context.read<PickMenuCubit>().load(),
                    );
                  }
                  if (state is PickMenuLoaded) {
                    if (state.menus.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No active menus. Create one from a group first.',
                          style: AppTextStyles.body.copyWith(color: AppColors.ink3),
                        ),
                      );
                    }
                    return Column(
                      children: state.menus
                          .map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _MenuRow(
                                  menu: m,
                                  added: state.addedMenuIds.contains(m.menuId),
                                  onTap: () => context
                                      .read<PickMenuCubit>()
                                      .addToMenu(m.menuId),
                                ),
                              ))
                          .toList(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final ActiveMenuSummary menu;
  final bool added;
  final VoidCallback onTap;

  const _MenuRow({
    required this.menu,
    required this.added,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: added ? null : onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.smAll,
          border: Border.all(color: added ? AppColors.ok : AppColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(menu.displayName, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${menu.groupName} · ${menu.dateRange}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.ink3),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: added
                    ? Icon(Icons.check_circle_rounded,
                        key: const ValueKey('added'), color: AppColors.ok, size: 26)
                    : Icon(Icons.add_circle_outline_rounded,
                        key: const ValueKey('add'), color: AppColors.accent, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
