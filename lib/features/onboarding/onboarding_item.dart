import 'package:flutter/material.dart';

/// A single onboarding slide (icon, copy, and its gradient/blob colours).
class OnboardingItem {
  const OnboardingItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.colors,
    required this.blob,
  });

  final IconData icon;
  final String title;
  final String desc;
  final List<Color> colors;
  final Color blob;
}
