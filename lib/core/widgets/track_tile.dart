import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/db/database.dart';
import '../format/duration_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'artwork_image.dart';
import 'source_badge.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({super.key, required this.track, this.onTap, this.trailing});

  final Track track;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final duration = track.durationMs;
    final subtitle = [
      if (track.artist case final artist? when artist.isNotEmpty) artist,
      if (duration != null) formatTrackDuration(Duration(milliseconds: duration)),
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              ArtworkImage(url: track.artworkUrl, size: 48),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.title,
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: text.bodyMedium?.copyWith(color: colors.mutedForeground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (track.unavailableReason != null) ...[
                Tooltip(
                  message: track.unavailableReason!,
                  child: Icon(
                    LucideIcons.triangleAlert,
                    size: 18,
                    color: colors.destructive,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              SourceBadge(source: track.source),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
