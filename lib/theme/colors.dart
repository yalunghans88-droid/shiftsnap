import 'package:flutter/material.dart';

/// ShiftSnap color palette
/// Source: SHIFTSNAP — DESIGN SYSTEM, Step A
class AppColors {
  AppColors._();

  /// Primary — Deep Navy. App bar, FAB, primary buttons, header text.
  static const Color primary = Color(0xFF0D3B66);

  /// Secondary/Accent — Warm Amber. Left borders on shift cards,
  /// countdown text, modal accent borders.
  static const Color accent = Color(0xFFF4A261);

  /// Surface — White. Standard shift cards, modals, camera overlay.
  static const Color surface = Color(0xFFFFFFFF);

  /// Background — Black/Dark. Backdrop behind white surfaces.
  static const Color background = Color(0xFF000000);

  /// Error/Destructive — Soft Red. Delete icons, "Discard" button.
  static const Color error = Color(0xFFE76F51);

  /// Text — Dark Slate. Standard typography on white surfaces.
  static const Color textPrimary = Color(0xFF1E293B);
}