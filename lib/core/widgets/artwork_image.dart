import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Cover art with a fixed footprint so layout never jumps while loading.
class ArtworkImage extends StatelessWidget {
  const ArtworkImage({
    super.key,
    required this.url,
    required this.size,
    this.radius = AppSpacing.radiusArtwork,
  });

  final String? url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(size: size);
    final url = this.url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? placeholder
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ColoredBox(
      color: colors.muted,
      child: Center(
        child: Icon(LucideIcons.music, size: size * 0.4, color: colors.mutedForeground),
      ),
    );
  }
}
