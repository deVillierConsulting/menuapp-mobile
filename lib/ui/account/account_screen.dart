import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../data/groups_data_source.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class AccountScreen extends StatelessWidget {
  final AuthCubit authCubit;
  final GroupsDataSource groupsDataSource;

  const AccountScreen({
    super.key,
    required this.authCubit,
    required this.groupsDataSource,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authCubit,
      child: const _AccountView(),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final name = authState is AuthAuthenticated ? authState.userName : null;
    final email = authState is AuthAuthenticated ? authState.email : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Account', style: AppTextStyles.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.ink,
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Profile ───────────────────────────────────────────────────────
          _SectionHeader('Profile'),
          _InfoTile(
            icon: Icons.person_outline,
            title: name ?? '—',
            subtitle: email,
          ),
          const SizedBox(height: 24),

          // ── Group ─────────────────────────────────────────────────────────
          _SectionHeader('Group'),
          _ActionTile(
            icon: Icons.group_outlined,
            title: 'Manage group',
            onTap: () {
              // TODO: resolve the user's group ID and push /groups/:id
            },
          ),
          const SizedBox(height: 24),

          // ── Settings ──────────────────────────────────────────────────────
          _SectionHeader('Settings'),
          _ActionTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              // TODO: notifications settings
            },
          ),
          _ActionTile(
            icon: Icons.lock_outline,
            title: 'Privacy',
            onTap: () {
              // TODO: privacy policy
            },
          ),
          const SizedBox(height: 24),

          // ── Sign out ──────────────────────────────────────────────────────
          _ActionTile(
            icon: Icons.logout,
            title: 'Sign out',
            destructive: true,
            onTap: () => context.read<AuthCubit>().signOut(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Small shared widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: AppColors.ink3,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _InfoTile({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.ink3),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyMedium),
              if (subtitle != null)
                Text(subtitle!,
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.ink3)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppTextStyles.body.copyWith(color: color))),
            Icon(Icons.chevron_right, size: 18, color: AppColors.ink4),
          ],
        ),
      ),
    );
  }
}
