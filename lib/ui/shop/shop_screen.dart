import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../cubits/shop/shop_cubit.dart';
import '../../cubits/shop/shop_state.dart';
import '../../data/models/shop_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../widgets/nav/app_page_header.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ShopCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<ShopCubit, ShopState>(
        builder: (context, state) {
          if (state is ShopLoading) return const _Loading();
          if (state is ShopError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<ShopCubit>().load(),
            );
          }
          if (state is ShopLoaded) {
            return _Loaded(items: state.items);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  final List<ShopItem> items;

  const _Loaded({required this.items});

  List<Widget> _buildRows(
      List<ShopItem> pending, ValueChanged<ShopItem> onToggle) {
    final rows = <Widget>[];
    String? currentCategory;
    for (final item in pending) {
      if (item.category != currentCategory) {
        currentCategory = item.category;
        if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
        rows.add(_CategoryHeader(label: currentCategory));
        rows.add(const SizedBox(height: 6));
      }
      rows.add(_ShopItemTile(item: item, onToggle: () => onToggle(item)));
      rows.add(const SizedBox(height: 8));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return CustomScrollView(
        slivers: [
          AppPageHeader(title: 'Shop', showBack: false),
          SliverFillRemaining(
            child: EmptyState(
              icon: LucideIcons.shoppingCart,
              title: 'Nothing to shop for',
              body: 'Finalize a menu to build your grocery list.',
            ),
          ),
        ],
      );
    }

    final pending = items.where((i) => !i.checked).toList();
    final done = items.where((i) => i.checked).toList();
    final cubit = context.read<ShopCubit>();

    return CustomScrollView(
      slivers: [
        AppPageHeader(title: 'Shop', showBack: false),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(
              pending.isEmpty
                  ? 'All picked up!'
                  : '${pending.length} item${pending.length == 1 ? '' : 's'} remaining',
              style: AppTextStyles.body.copyWith(color: AppColors.ink3),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, done.isEmpty ? 48 : 8),
          sliver: SliverList.list(
            children: _buildRows(pending, cubit.toggle),
          ),
        ),
        if (done.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            sliver: SliverToBoxAdapter(
              child: _GotItSection(items: done, onToggle: cubit.toggle),
            ),
          ),
      ],
    );
  }
}

class _GotItSection extends StatelessWidget {
  final List<ShopItem> items;
  final ValueChanged<ShopItem> onToggle;

  const _GotItSection({required this.items, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Remove the default ExpansionTile divider lines.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: EdgeInsets.zero,
        title: Text(
          'Got it (${items.length})',
          style: AppTextStyles.body.copyWith(color: AppColors.ink3),
        ),
        trailing: Icon(LucideIcons.chevronDown, size: 18, color: AppColors.ink4),
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ShopItemTile(item: item, onToggle: () => onToggle(item)),
                ))
            .toList(),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String label;
  const _CategoryHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: AppColors.ink3,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ShopItemTile extends StatelessWidget {
  final ShopItem item;
  final VoidCallback onToggle;

  const _ShopItemTile({required this.item, required this.onToggle});

  String get _quantity {
    if (item.totalQuantity == null) return '';
    final qty = item.totalQuantity! % 1 == 0
        ? item.totalQuantity!.toInt().toString()
        : item.totalQuantity.toString();
    return item.unit != null ? '$qty ${item.unit}' : qty;
  }

  @override
  Widget build(BuildContext context) {
    final checked = item.checked;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: AppRadii.smAll,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.ingredientName,
                        style: AppTextStyles.body.copyWith(
                          color: checked ? AppColors.ink4 : AppColors.ink,
                          decoration:
                              checked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(
                        item.sources.map((s) => s.groupName).join(' · '),
                        style:
                            AppTextStyles.caption.copyWith(color: AppColors.ink4),
                      ),
                    ],
                  ),
                ),
                if (_quantity.isNotEmpty)
                  Text(
                    _quantity,
                    style: AppTextStyles.body.copyWith(color: AppColors.ink3),
                  ),
              ],
            ),
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
