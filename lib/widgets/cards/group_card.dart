import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../lists/app_list_row.dart';
import 'app_card.dart';

class GroupCard extends StatelessWidget {
  final String name;
  final int memberCount;
  final int threshold;
  final VoidCallback? onTap;

  const GroupCard({
    super.key,
    required this.name,
    required this.memberCount,
    required this.threshold,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: AppListRow(
        title: name,
        subtitle: '$memberCount members · threshold: $threshold',
        leading: AppAvatar(initials: name.isNotEmpty ? name[0] : '?'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.ink4, size: 20),
        showDivider: false,
      ),
    );
  }
}
