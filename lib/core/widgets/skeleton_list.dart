import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Placeholder rows the same height as a TrackTile (56).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 8});

  final int count;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.of(context).muted;
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: muted,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
        );

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, _) => SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            children: [
              bar(48, 48),
              const SizedBox(width: AppSpacing.md),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(160, 12),
                  const SizedBox(height: AppSpacing.sm),
                  bar(96, 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
