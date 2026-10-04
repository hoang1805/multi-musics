import 'package:flutter/material.dart';

import '../../sources/source_type.dart';

/// Color tokens from design-system/multi-musics/MASTER.md.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.muted,
    required this.border,
    required this.onBackground,
    required this.mutedForeground,
    required this.accent,
    required this.onAccent,
    required this.destructive,
    required this.sourceSpotify,
    required this.sourceYouTube,
    required this.sourceSoundCloud,
  });

  static const dark = AppColors(
    background: Color(0xFF0B0B16),
    surface: Color(0xFF1B1B30),
    muted: Color(0xFF27273B),
    border: Color(0xFF312E81),
    onBackground: Color(0xFFF8FAFC),
    mutedForeground: Color(0xFF94A3B8),
    accent: Color(0xFF818CF8),
    onAccent: Color(0xFF0B0B16),
    destructive: Color(0xFFEF4444),
    sourceSpotify: Color(0xFF1DB954),
    sourceYouTube: Color(0xFFFF0033),
    sourceSoundCloud: Color(0xFFFF5500),
  );

  final Color background;
  final Color surface;
  final Color muted;
  final Color border;
  final Color onBackground;
  final Color mutedForeground;
  final Color accent;
  final Color onAccent;
  final Color destructive;
  final Color sourceSpotify;
  final Color sourceYouTube;
  final Color sourceSoundCloud;

  Color sourceColor(SourceType source) => switch (source) {
        SourceType.spotify => sourceSpotify,
        SourceType.youtube => sourceYouTube,
        SourceType.soundcloud => sourceSoundCloud,
      };

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? muted,
    Color? border,
    Color? onBackground,
    Color? mutedForeground,
    Color? accent,
    Color? onAccent,
    Color? destructive,
    Color? sourceSpotify,
    Color? sourceYouTube,
    Color? sourceSoundCloud,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      onBackground: onBackground ?? this.onBackground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      destructive: destructive ?? this.destructive,
      sourceSpotify: sourceSpotify ?? this.sourceSpotify,
      sourceYouTube: sourceYouTube ?? this.sourceYouTube,
      sourceSoundCloud: sourceSoundCloud ?? this.sourceSoundCloud,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      muted: l(muted, other.muted),
      border: l(border, other.border),
      onBackground: l(onBackground, other.onBackground),
      mutedForeground: l(mutedForeground, other.mutedForeground),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      destructive: l(destructive, other.destructive),
      sourceSpotify: l(sourceSpotify, other.sourceSpotify),
      sourceYouTube: l(sourceYouTube, other.sourceYouTube),
      sourceSoundCloud: l(sourceSoundCloud, other.sourceSoundCloud),
    );
  }
}
