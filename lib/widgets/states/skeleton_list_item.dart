import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';

class SkeletonListItem extends StatefulWidget {
  const SkeletonListItem({super.key});

  @override
  State<SkeletonListItem> createState() => _SkeletonListItemState();
}

class _SkeletonListItemState extends State<SkeletonListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, // SingleTickerProviderStateMixin supplies the Ticker
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true); // pulse: 0.3 → 1.0 → 0.3 → ...

    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // stops the ticker before State is torn down
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: child,
      ),
      // child is built once and reused every frame — only the Opacity changes.
      child: const _SkeletonContent(),
    );
  }
}

// The static skeleton shape — mirrors GroupCard layout exactly.
class _SkeletonContent extends StatelessWidget {
  const _SkeletonContent();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.line2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar placeholder
            const _Bone(width: 40, height: 40, radius: AppRadii.full),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title line
                  _Bone(width: double.infinity, height: 14, radius: AppRadii.xs),
                  const SizedBox(height: 8),
                  // Subtitle line — shorter to look like real text
                  _Bone(
                    width: double.infinity,
                    height: 11,
                    radius: AppRadii.xs,
                    widthFactor: 0.6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Trailing chevron placeholder
            const _Bone(width: 16, height: 16, radius: AppRadii.xs),
          ],
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final double widthFactor; // shrinks width to simulate shorter text lines

  const _Bone({
    required this.width,
    required this.height,
    required this.radius,
    this.widthFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: width == double.infinity ? widthFactor : null,
      child: Container(
        width: width == double.infinity ? null : width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
