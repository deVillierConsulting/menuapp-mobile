import 'package:flutter/painting.dart';
import 'app_colors.dart';

// All styles use the platform default font (SF Pro on iOS, Roboto on Android).
// Flutter resolves this automatically — no fontFamily needed.
// Mono uses the platform monospace for numbers and identifiers.

class AppTextStyles {
  AppTextStyles._();

  // Large hero numbers — vote counts, big stats
  static const display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.6,
    height: 40 / 34,
    color: AppColors.ink,
  );

  // Screen titles — large collapsing header
  static const h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 26 / 22,
    color: AppColors.ink,
  );

  // Card and section titles
  static const h2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 22 / 16,
    color: AppColors.ink,
  );

  // Default reading size for descriptions, lists
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
    color: AppColors.ink2,
  );

  // Slightly emphasized body — list primary lines
  static const bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 22 / 15,
    color: AppColors.ink,
  );

  // Metadata, timestamps, secondary info
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: AppColors.ink3,
  );

  // Field labels, overlines — always uppercase in usage
  static const label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    height: 14 / 11,
    color: AppColors.ink3,
  );

  // Button label
  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.surface,
  );

  // Monospace — vote counts, thresholds, IDs, numeric data
  static const mono = TextStyle(
    fontFamily: 'Courier',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static const monoSmall = TextStyle(
    fontFamily: 'Courier',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.ink2,
  );
}
