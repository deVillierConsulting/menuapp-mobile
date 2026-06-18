import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,

    // ColorScheme.fromSeed gives Material widgets a base to work from.
    // Our custom widgets don't read from this — they import AppColors directly.
    // We set it here mainly to suppress Material's default teal/purple.
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      surface: AppColors.surface,
      brightness: Brightness.light,
    ),

    // Strip Material's default styling from widgets we override completely.
    // elevation: 0 + transparent color means our BoxDecoration is what shows.
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Colors.transparent,
      shadowColor: Colors.transparent,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),

    // Propagate our type scale into Material widgets (dialogs, snackbars, etc.)
    // that we don't fully replace, so they stay on-brand.
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.display,
      headlineMedium: AppTextStyles.h1,
      titleLarge: AppTextStyles.h2,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelSmall: AppTextStyles.label,
    ),
  );
}
