import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static const fontFamily = 'BeVietnamPro';

  static ThemeData dark() {
    const c = AppColors.dark;
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.destructive,
      onError: c.onBackground,
      surface: c.surface,
      onSurface: c.onBackground,
      onSurfaceVariant: c.mutedForeground,
      surfaceContainerHighest: c.muted,
      outline: c.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );

    final text = base.textTheme.copyWith(
      displaySmall: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      labelSmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ).apply(
      fontFamily: fontFamily,
      bodyColor: c.onBackground,
      displayColor: c.onBackground,
    );

    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      textTheme: text,
      extensions: const [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.accent.withValues(alpha: 0.2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.muted,
        contentTextStyle: text.bodyMedium,
      ),
    );
  }
}
