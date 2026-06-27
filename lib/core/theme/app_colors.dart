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
  static const Color primary  = Color(0xFF4F8EFF);
  static const Color primary2 = Color(0xFF60A5FA);
  static const Color green    = Color(0xFF10D9A0);
  static const Color lime     = Color(0xFF84CC16);
  static const Color violet   = Color(0xFFA78BFA);
  static const Color cyan     = Color(0xFF22D3EE);
  static const Color amber    = Color(0xFFFBBF24);
  static const Color orange   = Color(0xFFFB923C);
  static const Color red      = Color(0xFFF87171);
  static const Color pink     = Color(0xFFF472B6);
  static const Color whatsapp = Color(0xFF25D366);

  // ── Palette presets ────────────────────────────────────────────────────────
  static const AppColors dark = AppColors._(
    background: Color(0xFF0B0F1A),
    surface:    Color(0xFF131B2E),
    elevated:   Color(0xFF1C2640),
    text:       Color(0xFFE8EFF8),
    muted:      Color(0xFF8899B4),
    line:       Color(0xFF243354),
  );

  static const AppColors light = AppColors._(
    background: Color(0xFFF4F9FF),
    surface:    Color(0xFFFFFFFF),
    elevated:   Color(0xFFEEF3FA),
    text:       Color(0xFF1A2540),
    muted:      Color(0xFF6B7A94),
    line:       Color(0xFFDDE7F5),
  );

  // ── Context accessor ───────────────────────────────────────────────────────
  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  // ── Helpers ────────────────────────────────────────────────────────────────
  static Color tint(Color c, [double opacity = 0.16]) =>
      c.withValues(alpha: opacity);
}
