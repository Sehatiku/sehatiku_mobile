import 'package:flutter/material.dart';
import 'package:sehatiku_mobile/core/theme/app_colors.dart';

// Rule-based labels and colours for the health metrics shown across the app.
// These are demo heuristics, not medical diagnoses.

// ---------------------------------------------------------------------------
// Daily-input domain options
// ---------------------------------------------------------------------------

/// Blood-sugar measurement timing tags (key -> label).
const bloodSugarTagLabels = {
  'puasa': 'Puasa',
  'sebelum_makan': 'Sebelum Makan',
  'sesudah_makan': 'Sesudah Makan',
  'sebelum_tidur': 'Sebelum Tidur',
};

/// Stable order of the blood-sugar timing tags for chip rendering.
const bloodSugarTagKeys = [
  'puasa',
  'sebelum_makan',
  'sesudah_makan',
  'sebelum_tidur',
];

/// Food categories captured for the daily meals quick-input.
const foodCategories = [
  'Karbohidrat',
  'Sayur & Buah',
  'Protein',
  'Manis/Gorengan',
];

/// Meal portion sizes (key -> label).
const portionLabels = {
  'kecil': 'Kecil',
  'sedang': 'Sedang',
  'besar': 'Besar',
};

/// Stable order of the portion keys for chip rendering.
const portionKeys = ['kecil', 'sedang', 'besar'];

/// Sleep quality scale, indexed 0..2.
const sleepQualityLabels = ['Buruk', 'Cukup', 'Nyenyak'];

/// Arithmetic mean of [v], or 0 when empty.
double average(List<double> v) =>
    v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

String bloodSugarStatus(int? v) {
  if (v == null) return 'Belum dicatat';
  if (v < 70) return 'Rendah';
  if (v <= 130) return 'Normal';
  if (v <= 180) return 'Tinggi';
  return 'Sangat tinggi';
}

Color bloodSugarColor(int? v) {
  if (v == null) return const Color(0xFF8899B4);
  if (v < 70) return AppColors.amber;
  if (v <= 130) return AppColors.green;
  if (v <= 180) return AppColors.orange;
  return AppColors.red;
}

String bloodPressureStatus(int? sys, int? dia) {
  if (sys == null || dia == null) return 'Belum dicatat';
  if (sys >= 140 || dia >= 90) return 'Tinggi';
  if (sys >= 130 || dia >= 85) return 'Waspada';
  if (sys < 90 || dia < 60) return 'Rendah';
  return 'Optimal';
}

Color bloodPressureColor(int? sys, int? dia) {
  if (sys == null || dia == null) return const Color(0xFF8899B4);
  if (sys >= 140 || dia >= 90) return AppColors.red;
  if (sys >= 130 || dia >= 85) return AppColors.orange;
  if (sys < 90 || dia < 60) return AppColors.amber;
  return AppColors.green;
}

class TrendInfo {
  const TrendInfo(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

/// Summarises the direction of a metric series (oldest -> newest).
/// [lowerIsBetter] flips the colour semantics (e.g. blood sugar going down).
TrendInfo trendInfo(List<double> values, {bool lowerIsBetter = false}) {
  if (values.length < 2) {
    return const TrendInfo(
      'Belum cukup data',
      Color(0xFF8899B4),
      Icons.remove_rounded,
    );
  }
  final delta = values.last - values.first;
  if (delta.abs() < 0.0001) {
    return const TrendInfo(
      'Stabil',
      Color(0xFF8899B4),
      Icons.trending_flat_rounded,
    );
  }
  final goingDown = delta < 0;
  final good = lowerIsBetter ? goingDown : !goingDown;
  return TrendInfo(
    goingDown ? 'Menurun' : 'Meningkat',
    good ? AppColors.green : AppColors.orange,
    goingDown ? Icons.trending_down_rounded : Icons.trending_up_rounded,
  );
}
