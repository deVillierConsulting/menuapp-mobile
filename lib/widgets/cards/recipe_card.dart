import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../badges/app_badge.dart';
import '../badges/app_tag.dart';
import 'app_card.dart';

class RecipeCard extends StatelessWidget {
  final String name;
  final String? cuisine;
  final List<String> dietaryTags; // e.g. ['Gluten-free', 'Vegetarian']
  final AppBadgeVariant? statusVariant; // null = no status badge
  final String? statusLabel;
  final VoidCallback? onTap;

  const RecipeCard({
    super.key,
    required this.name,
    this.cuisine,
    this.dietaryTags = const [],
    this.statusVariant,
    this.statusLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppTextStyles.h2),
          if (cuisine != null) ...[
            const SizedBox(height: 4),
            Text(cuisine!, style: AppTextStyles.caption),
          ],
          // Only render the tag row if there's something to show.
          if (statusVariant != null || dietaryTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (statusVariant != null)
                  AppBadge(label: statusLabel!, variant: statusVariant!),
                ...dietaryTags.map(
                  (tag) => AppTag(label: tag, variant: AppTagVariant.teal),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
