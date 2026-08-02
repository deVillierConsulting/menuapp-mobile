import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/invite/invite_cubit.dart';
import '../../cubits/invite/invite_state.dart';
import '../../cubits/groups/groups_cubit.dart';
import '../../data/models/invite_preview.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InviteCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InviteCubit, InviteState>(
      listener: (context, state) {
        if (state is InviteJoined) {
          // Refresh the groups list so the new group appears immediately.
          context.read<GroupsCubit>().loadGroups();
          // Navigate into the group we just joined.
          context.go('/groups/${state.groupId}');
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: switch (state) {
            InviteLoading() => const _LoadingView(),
            InvitePreviewLoaded(:final preview) =>
              _PreviewView(preview: preview),
            InviteJoining(:final preview) =>
              _JoiningView(preview: preview),
            InviteJoined() => const _LoadingView(), // brief flicker before nav
            InviteError() => _ErrorView(state: state),
          },
        ),
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

// ── Preview ───────────────────────────────────────────────────────────────────

class _PreviewView extends StatelessWidget {
  final InvitePreview preview;
  const _PreviewView({required this.preview});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close / dismiss
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close_rounded),
              color: AppColors.ink3,
              onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
            ),
          ),
          const Spacer(),

          // Group avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                preview.groupName.isNotEmpty
                    ? preview.groupName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentDeep),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            preview.groupName,
            style: AppTextStyles.h1.copyWith(fontSize: 26),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          if (preview.inviterName != null)
            Text(
              '${preview.inviterName} invited you',
              style: AppTextStyles.body.copyWith(color: AppColors.ink2),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),

          // Quick stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Stat(
                value: '${preview.memberCount}',
                label: preview.memberCount == 1 ? 'member' : 'members',
              ),
              _Divider(),
              _Stat(
                value: '${preview.mealsPerWeek}',
                label: 'meals/week',
              ),
            ],
          ),

          const Spacer(),

          FilledButton(
            onPressed: () => context.read<InviteCubit>().join(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Join group',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            child: Text('Not now',
                style: AppTextStyles.body.copyWith(color: AppColors.ink3)),
          ),
        ],
      ),
    );
  }
}

// ── Joining (in-flight) ───────────────────────────────────────────────────────

class _JoiningView extends StatelessWidget {
  final InvitePreview preview;
  const _JoiningView({required this.preview});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Joining ${preview.groupName}…', style: AppTextStyles.body),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final InviteError state;
  const _ErrorView({required this.state});

  @override
  Widget build(BuildContext context) {
    final (emoji, headline, body) = switch (state.kind) {
      InviteErrorKind.expired => (
          '⏰',
          'Invite expired',
          'This link is no longer valid. Ask your group for a fresh invite.',
        ),
      InviteErrorKind.alreadyMember => (
          '✅',
          'Already a member',
          "You're already in this group. Head to Groups to see it.",
        ),
      InviteErrorKind.notFound => (
          '🔍',
          'Invite not found',
          'This invite link doesn\'t exist or has already been used.',
        ),
      InviteErrorKind.network => (
          '📡',
          'Connection error',
          state.message,
        ),
    };

    final canRetry = state.kind == InviteErrorKind.network;
    final goToGroups = state.kind == InviteErrorKind.alreadyMember;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close_rounded),
              color: AppColors.ink3,
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
          ),
          const Spacer(),
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          Text(headline,
              style: AppTextStyles.h1, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(body,
              style: AppTextStyles.body.copyWith(color: AppColors.ink2),
              textAlign: TextAlign.center),
          const Spacer(),
          if (canRetry)
            FilledButton(
              onPressed: () => context.read<InviteCubit>().load(),
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Try again'),
            )
          else if (goToGroups)
            FilledButton(
              onPressed: () => context.go('/home'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size.fromHeight(52)),
              child: const Text('Go home'),
            )
          else
            FilledButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              child: const Text('Dismiss'),
            ),
        ],
      ),
    );
  }
}

// ── Helper sub-widgets ────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.h1.copyWith(fontSize: 22)),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.ink3)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: AppColors.line,
      margin: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
