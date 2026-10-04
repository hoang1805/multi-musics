import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/artwork_image.dart';

/// 2×2 mosaic when there are 4 artworks, otherwise the first one (or a
/// placeholder).
class PlaylistCover extends StatelessWidget {
  const PlaylistCover({super.key, required this.artworks, required this.size});

  final List<String> artworks;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (artworks.length < 4) {
      return ArtworkImage(
        url: artworks.firstOrNull,
        size: size,
        radius: AppSpacing.radiusCard,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: SizedBox.square(
        dimension: size,
        child: GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            for (final url in artworks.take(4))
              ArtworkImage(url: url, size: size / 2, radius: 0),
          ],
        ),
      ),
    );
  }
}
