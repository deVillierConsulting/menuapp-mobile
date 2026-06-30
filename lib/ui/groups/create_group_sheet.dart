import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cubits/create_group/create_group_cubit.dart';
import '../../cubits/create_group/create_group_state.dart';
import '../../data/groups_data_source.dart';
import '../../session/app_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

Future<void> showCreateGroupSheet(
  BuildContext context, {
  required GroupsDataSource dataSource,
  required AppSession session,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
    ),
    builder: (_) => BlocProvider(
      create: (_) => CreateGroupCubit(dataSource: dataSource, session: session),
      child: const _CreateGroupSheetBody(),
    ),
  );
}

class _CreateGroupSheetBody extends StatelessWidget {
  const _CreateGroupSheetBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateGroupCubit, CreateGroupState>(
      listener: (context, state) {
        if (state is CreateGroupSuccess) {
          Navigator.of(context).pop();
          context.push('/groups/${state.groupId}');
        }
        if (state is CreateGroupError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Padding(
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
                Text('New group', style: AppTextStyles.h2),
                const SizedBox(height: 24),
                BlocBuilder<CreateGroupCubit, CreateGroupState>(
                  builder: (context, state) {
                    if (state is CreateGroupSubmitting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final idle = state is CreateGroupIdle
                        ? state
                        : const CreateGroupIdle();
                    return _Form(state: idle);
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
  final CreateGroupIdle state;
  const _Form({required this.state});

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.state.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Group name'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => context.read<CreateGroupCubit>().setName(v),
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'e.g. The Johnson Family',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink4),
            filled: true,
            fillColor: AppColors.field,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: _PrimaryButton(
            label: 'Create group',
            enabled: state.canSubmit,
            onTap: () => context.read<CreateGroupCubit>().submit(),
          ),
        ),
      ],
    );
  }
}


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

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _PrimaryButton(
      {required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: enabled ? AppColors.accent : AppColors.line2,
          borderRadius: AppRadii.smAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: enabled ? AppColors.surface : AppColors.ink4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
