import 'package:flutter/material.dart';
import 'colors.dart';

/// ShiftSnap type scale
/// Source: SHIFTSNAP — DESIGN SYSTEM, Step B
class AppTextStyles {
  AppTextStyles._();

  /// Header (22sp, Bold, White) — App bar title.
  static const TextStyle header = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.surface,
  );

  /// Section Title (18sp, Bold, Navy/White) — "Next Shift", "Upcoming Shift".
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  /// Highlight (20sp, Bold, Dark Slate) — Shift dates in cards.
  static const TextStyle highlight = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Body (16sp, Regular) — Shift times, button text, inputs.
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  /// Caption (13sp, Regular, Muted) — "Your Next Shift", "Morning Shift".
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  /// Countdown text — Amber, small, bold.
  static const TextStyle countdown = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );
}