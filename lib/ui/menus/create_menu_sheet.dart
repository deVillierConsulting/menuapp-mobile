import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cubits/create_menu/create_menu_cubit.dart';
import '../../cubits/create_menu/create_menu_state.dart';
import '../../data/menus_data_source.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

/// Opens the Create Menu bottom sheet, providing its own cubit.
/// Call this instead of constructing CreateMenuSheet directly.
Future<void> showCreateMenuSheet(
  BuildContext context, {
  required int groupId,
  required MenusDataSource dataSource,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
    ),
    builder: (_) => BlocProvider(
      create: (_) => CreateMenuCubit(dataSource: dataSource, groupId: groupId),
      child: const _CreateMenuSheetBody(),
    ),
  );
}

class _CreateMenuSheetBody extends StatelessWidget {
  const _CreateMenuSheetBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateMenuCubit, CreateMenuState>(
      listener: (context, state) {
        if (state is CreateMenuSuccess) {
          Navigator.of(context).pop(); // close sheet
          context.push('/menus/${state.menuId}');
        }
        if (state is CreateMenuError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
          // Let user try again — don't pop the sheet.
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grab handle
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
                Text('New menu', style: AppTextStyles.h2),
                const SizedBox(height: 24),

                BlocBuilder<CreateMenuCubit, CreateMenuState>(
                  builder: (context, state) {
                    if (state is CreateMenuIdle) {
                      return _Form(state: state);
                    }
                    if (state is CreateMenuSubmitting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  final CreateMenuIdle state;
  const _Form({required this.state});

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.state.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        _SectionLabel('Name'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          onChanged: (v) => context.read<CreateMenuCubit>().setName(v),
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: state.defaultName,
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink4),
            filled: true,
            fillColor: AppColors.field,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: AppRadii.smAll,
              borderSide: BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.smAll,
              borderSide: BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.smAll,
              borderSide: BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Date range picker
        _SectionLabel('Date range'),
        const SizedBox(height: 8),
        _TapRow(
          label: '${_fmt(state.startDate)}  →  ${_fmt(state.endDate)}',
          sublabel: '${state.dayCount} ${state.dayCount == 1 ? 'day' : 'days'}',
          onTap: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: DateTimeRange(
                start: state.startDate,
                end: state.endDate,
              ),
              builder: (context, child) => Theme(
                // Minimal Material theme override so the picker uses our accent.
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppColors.accent,
                    onPrimary: AppColors.surface,
                    surface: AppColors.surface,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null && context.mounted) {
              context
                  .read<CreateMenuCubit>()
                  .setDateRange(picked.start, picked.end);
            }
          },
        ),

        const SizedBox(height: 20),

        // Meal count stepper
        _SectionLabel('Meals to plan'),
        const SizedBox(height: 4),
        Text(
          'Breakfast, lunch, dinner — count every meal you want to plan.',
          style: AppTextStyles.caption.copyWith(color: AppColors.ink3),
        ),
        const SizedBox(height: 10),
        _MealStepper(
          count: state.plannedMealCount,
          onChanged: (v) => context.read<CreateMenuCubit>().setMealCount(v),
        ),

        const SizedBox(height: 32),

        // Create button
        SizedBox(
          width: double.infinity,
          child: _PrimaryButton(
            label: 'Create menu',
            onTap: () => context.read<CreateMenuCubit>().submit(),
          ),
        ),
      ],
    );
  }
}

// ---------- Sub-widgets ----------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(color: AppColors.ink3),
    );
  }
}

class _TapRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  const _TapRow({required this.label, required this.sublabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: AppRadii.smAll,
          border: Border.all(color: AppColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 2),
                    Text(sublabel,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.ink3)),
                  ],
                ),
              ),
              Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppColors.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealStepper extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;
  const _MealStepper({required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(
          icon: Icons.remove,
          enabled: count > 1,
          onTap: () => onChanged(count - 1),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 16),
        _StepBtn(
          icon: Icons.add,
          enabled: true,
          onTap: () => onChanged(count + 1),
        ),
        const SizedBox(width: 12),
        Text(
          count == 1 ? 'meal' : 'meals',
          style: AppTextStyles.body.copyWith(color: AppColors.ink2),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.accent : AppColors.field,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? AppColors.surface : AppColors.ink4),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: AppRadii.smAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.surface),
            ),
          ),
        ),
      ),
    );
  }
}
