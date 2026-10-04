import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../sources/source_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Source logo in its brand color; never color alone (MASTER.md).
class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.source, this.showLabel = false});

  final SourceType source;
  final bool showLabel;

  static IconData iconFor(SourceType source) => switch (source) {
        SourceType.spotify => SimpleIcons.spotify,
        SourceType.youtube => SimpleIcons.youtube,
        SourceType.soundcloud => SimpleIcons.soundcloud,
      };

  @override
  Widget build(BuildContext context) {
    final color = AppColors.of(context).sourceColor(source);
    final icon = Icon(iconFor(source), size: 16, color: color);
    if (!showLabel) {
      return Semantics(label: source.displayName, child: ExcludeSemantics(child: icon));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: icon),
        const SizedBox(width: AppSpacing.xs),
        Text(
          source.displayName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
