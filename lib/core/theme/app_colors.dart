import 'package:flutter/material.dart';

/// Holds the surface/text palette that flips between dark and light modes.
/// Accent colors (primary, green, violet, …) are static const — they read well
/// on both backgrounds and never need to change.
class AppColors {
  const AppColors._({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.text,
    required this.muted,
    required this.line,
  });

  // ── Surface / structural (flips per mode) ──────────────────────────────────
  final Color background;
  final Color surface;
  final Color elevated;

  // ── Typography (flips per mode) ─────────────────────────────────────────────
  final Color text;
  final Color muted;

  // ── Borders / dividers (flips per mode) ────────────────────────────────────
  final Color line;

  /// Alias kept so call-sites that used `AppColors.pale` keep working.
  Color get pale => elevated;

  // ── Static accent colours — same on both themes ────────────────────────────
  static const Color primary  = Color(0xFF2E6BFF);
  static const Color primary2 = Color(0xFF5CC6FF);
  static const Color green    = Color(0xFF1DBF73);
  static const Color lime     = Color(0xFF9DDC4A);
  static const Color violet   = Color(0xFF7C5CFF);
  static const Color cyan     = Color(0xFF18BFD8);
  static const Color amber    = Color(0xFFF0B84B);
  static const Color orange   = Color(0xFFF48B4A);
  static const Color red      = Color(0xFFE85D73);
  static const Color pink     = Color(0xFFF06AA9);
  static const Color whatsapp = Color(0xFF25D366);

  // ── Palette presets ────────────────────────────────────────────────────────
  static const AppColors dark = AppColors._(
    background: Color(0xFF08111F),
    surface:    Color(0xFF101B2C),
    elevated:   Color(0xFF17243A),
    text:       Color(0xFFF4F7FB),
    muted:      Color(0xFF8E9EB5),
    line:       Color(0xFF22314B),
  );

  static const AppColors light = AppColors._(
    background: Color(0xFFF7F5F0),
    surface:    Color(0xFFFFFFFF),
    elevated:   Color(0xFFF0F4F8),
    text:       Color(0xFF132237),
    muted:      Color(0xFF627089),
    line:       Color(0xFFD9E2ED),
  );

  // ── Context accessor ───────────────────────────────────────────────────────
  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  // ── Helpers ────────────────────────────────────────────────────────────────
  static Color tint(Color c, [double opacity = 0.16]) =>
      c.withValues(alpha: opacity);
}
