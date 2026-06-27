import 'package:flutter/material.dart';

enum Stage { splash, onboarding, login, app }

enum MainView {
  beranda,
  catatan,
  ai,
  progres,
  profil,
  dokter,
  riwayat,
  notifikasi,
  edukasi,
}

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
