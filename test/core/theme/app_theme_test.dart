import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_musics/core/theme/app_colors.dart';
import 'package:multi_musics/core/theme/app_theme.dart';
import 'package:multi_musics/sources/source_type.dart';

void main() {
  final theme = AppTheme.dark();
  final colors = theme.extension<AppColors>()!;

  test('is dark with indigo accent from MASTER.md', () {
    expect(theme.brightness, Brightness.dark);
    expect(colors.accent, const Color(0xFF818CF8));
    expect(theme.colorScheme.primary, const Color(0xFF818CF8));
    expect(theme.scaffoldBackgroundColor, const Color(0xFF0B0B16));
  });

  test('uses Be Vietnam Pro with the specified scale', () {
    expect(theme.textTheme.titleMedium!.fontFamily, contains('BeVietnamPro'));
    expect(theme.textTheme.displaySmall!.fontSize, 28);
    expect(theme.textTheme.displaySmall!.fontWeight, FontWeight.w700);
    expect(theme.textTheme.titleLarge!.fontSize, 22);
    expect(theme.textTheme.titleMedium!.fontSize, 16);
    expect(theme.textTheme.bodyMedium!.fontSize, 14);
    expect(theme.textTheme.labelSmall!.fontSize, 12);
  });

  test('source colors map to brand colors', () {
    expect(colors.sourceColor(SourceType.spotify), const Color(0xFF1DB954));
    expect(colors.sourceColor(SourceType.youtube), const Color(0xFFFF0033));
    expect(colors.sourceColor(SourceType.soundcloud), const Color(0xFFFF5500));
  });
}
