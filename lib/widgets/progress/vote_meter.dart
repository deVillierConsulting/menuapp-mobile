import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

class VoteMeter extends StatelessWidget {
  final int votes;       // current approval count
  final int total;       // total members who can vote
  final int threshold;   // votes needed to pass

  const VoteMeter({
    super.key,
    required this.votes,
    required this.total,
    required this.threshold,
  });

  bool get _passed => votes >= threshold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: vote count on left, threshold on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$votes of $total approved',
              style: AppTextStyles.caption.copyWith(
                color: _passed ? AppColors.ok : AppColors.ink2,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'threshold: $threshold',
              style: AppTextStyles.monoSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Track(votes: votes, total: total, threshold: threshold, passed: _passed),
      ],
    );
  }
}

class _Track extends StatelessWidget {
  final int votes;
  final int total;
  final int threshold;
  final bool passed;

  const _Track({
    required this.votes,
    required this.total,
    required this.threshold,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    // Guard against divide-by-zero if total is somehow 0.
    final fillFraction = total > 0 ? (votes / total).clamp(0.0, 1.0) : 0.0;
    final markerFraction = total > 0 ? (threshold / total).clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final fillWidth = trackWidth * fillFraction;
        // Centre the 2px marker on its calculated position.
        final markerLeft = (trackWidth * markerFraction) - 1;

        return Stack(
          children: [
            // Background track
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.field,
                borderRadius: AppRadii.fullAll,
              ),
            ),
            // Fill bar — color shifts to green once threshold is passed
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: 8,
              width: fillWidth,
              decoration: BoxDecoration(
                color: passed ? AppColors.ok : AppColors.accent,
                borderRadius: AppRadii.fullAll,
              ),
            ),
            // Threshold marker — a hairline that shows where approval happens
            Positioned(
              left: markerLeft,
              child: Container(
                width: 2,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.ink3,
                  borderRadius: AppRadii.fullAll,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
