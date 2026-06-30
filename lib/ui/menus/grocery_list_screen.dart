import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/grocery_list/grocery_list_cubit.dart';
import '../../cubits/grocery_list/grocery_list_state.dart';
import '../../data/models/grocery_list.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../widgets/nav/app_page_header.dart';
import '../../widgets/states/error_state.dart';

class GroceryListScreen extends StatefulWidget {
  final int menuId;
  const GroceryListScreen({super.key, required this.menuId});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GroceryListCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<GroceryListCubit, GroceryListState>(
        builder: (context, state) {
          if (state is GroceryListLoading) return const _Loading();
          if (state is GroceryListError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<GroceryListCubit>().load(),
            );
          }
          if (state is GroceryListLoaded) {
            return _Loaded(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  final GroceryListLoaded state;
  const _Loaded({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = state.groceryList.items;
    final checked = state.checkedIds;
    final remaining = items.where((i) => !checked.contains(i.groceryListItemId)).length;

    return CustomScrollView(
      slivers: [
        AppPageHeader(
          title: 'Grocery list',
          showBack: true,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Text(
              remaining == 0
                  ? 'All picked up!'
                  : '$remaining item${remaining == 1 ? '' : 's'} remaining',
              style: AppTextStyles.body.copyWith(color: AppColors.ink3),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = items[i];
              final isChecked = checked.contains(item.groceryListItemId);
              return _GroceryItem(
                item: item,
                checked: isChecked,
                onToggle: () => context
                    .read<GroceryListCubit>()
                    .toggleItem(item.groceryListItemId),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GroceryItem extends StatelessWidget {
  final GroceryListItem item;
  final bool checked;
  final VoidCallback onToggle;

  const _GroceryItem({
    required this.item,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: checked ? AppColors.field : AppColors.surface,
          borderRadius: AppRadii.smAll,
          border: Border.all(
            color: checked ? AppColors.ok.withValues(alpha: 0.4) : AppColors.line,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: checked ? AppColors.ok : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: checked ? AppColors.ok : AppColors.line2,
                    width: 1.5,
                  ),
                ),
                child: checked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.ingredientName,
                  style: AppTextStyles.body.copyWith(
                    color: checked ? AppColors.ink4 : AppColors.ink,
                    decoration: checked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (item.displayQuantity.isNotEmpty)
                Text(
                  item.displayQuantity,
                  style: AppTextStyles.body.copyWith(color: AppColors.ink3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverAppBar.large(title: Text('')),
        SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}
