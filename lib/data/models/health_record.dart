import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/theme/app_colors.dart';

/// A single day's health log. One record per calendar day; saving again on the
/// same day overwrites the previous entry for that day.
class HealthRecord {
  HealthRecord({
    required this.date,
    this.bloodSugar,
    this.systolic,
    this.diastolic,
    this.weight,
    this.medicineTaken = false,
    Set<String>? meals,
    this.activity = 'none',
    this.activityMinutes = 0,
    this.stressIndex = 1,
    this.smoke = false,
    this.alcohol = false,
    this.note = '',
  }) : meals = meals ?? <String>{};

  /// Always normalised to midnight so one record maps to one calendar day.
  final DateTime date;
  final int? bloodSugar;
  final int? systolic;
  final int? diastolic;
  final double? weight;
  final bool medicineTaken;
  final Set<String> meals;
  final String activity;
  final int activityMinutes;
  final int stressIndex;
  final bool smoke;
  final bool alcohol;
  final String note;

  static DateTime dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Transparent rule-based wellness score (0-100). This is a heuristic for the
  /// demo, not a medical diagnosis.
  int get score {
    var s = 100.0;

    final bs = bloodSugar;
    if (bs != null) {
      if (bs >= 180) {
        s -= 28;
      } else if (bs >= 140) {
        s -= 14;
      } else if (bs < 70) {
        s -= 16;
      } else if (bs > 130) {
        s -= 6;
      }
    }

    final sys = systolic;
    final dia = diastolic;
    if (sys != null && dia != null) {
      if (sys >= 140 || dia >= 90) {
        s -= 22;
      } else if (sys >= 130 || dia >= 85) {
        s -= 10;
      }
    }

    if (!medicineTaken) s -= 15;
    if (activity == 'none' || activityMinutes == 0) s -= 8;
    if (stressIndex == 2) {
      s -= 8;
    } else if (stressIndex == 1) {
      s -= 3;
    }
    if (smoke) s -= 10;
    if (alcohol) s -= 6;
    if (meals.isEmpty) s -= 4;

    return s.clamp(0, 100).round();
  }

  /// Estimated complication-risk percentage derived from the score.
  int get riskPercent => ((100 - score) * 0.6).round().clamp(0, 100);

  String get statusLabel {
    final sc = score;
    if (sc >= 80) return 'Aman';
    if (sc >= 60) return 'Perhatian';
    return 'Waspada';
  }

  Color get statusColor {
    final sc = score;
    if (sc >= 80) return AppColors.lime;
    if (sc >= 60) return AppColors.amber;
    return AppColors.red;
  }

  Color get statusBg {
    final sc = score;
    if (sc >= 80) return const Color(0xFFE7F7EC);
    if (sc >= 60) return const Color(0xFFFFF8E6);
    return const Color(0xFFFFEEF0);
  }

  String get bloodPressure =>
      (systolic != null && diastolic != null) ? '$systolic/$diastolic' : '—';

  HealthRecord copyWith({
    int? bloodSugar,
    int? systolic,
    int? diastolic,
    double? weight,
    bool? medicineTaken,
    Set<String>? meals,
    String? activity,
    int? activityMinutes,
    int? stressIndex,
    bool? smoke,
    bool? alcohol,
    String? note,
  }) {
    return HealthRecord(
      date: date,
      bloodSugar: bloodSugar ?? this.bloodSugar,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      weight: weight ?? this.weight,
      medicineTaken: medicineTaken ?? this.medicineTaken,
      meals: meals ?? this.meals,
      activity: activity ?? this.activity,
      activityMinutes: activityMinutes ?? this.activityMinutes,
      stressIndex: stressIndex ?? this.stressIndex,
      smoke: smoke ?? this.smoke,
      alcohol: alcohol ?? this.alcohol,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'bloodSugar': bloodSugar,
    'systolic': systolic,
    'diastolic': diastolic,
    'weight': weight,
    'medicineTaken': medicineTaken,
    'meals': meals.toList(),
    'activity': activity,
    'activityMinutes': activityMinutes,
    'stressIndex': stressIndex,
    'smoke': smoke,
    'alcohol': alcohol,
    'note': note,
  };

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      date: dayOf(DateTime.parse(json['date'] as String)),
      bloodSugar: json['bloodSugar'] as int?,
      systolic: json['systolic'] as int?,
      diastolic: json['diastolic'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      medicineTaken: json['medicineTaken'] as bool? ?? false,
      meals: (json['meals'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toSet(),
      activity: json['activity'] as String? ?? 'none',
      activityMinutes: json['activityMinutes'] as int? ?? 0,
      stressIndex: json['stressIndex'] as int? ?? 1,
      smoke: json['smoke'] as bool? ?? false,
      alcohol: json['alcohol'] as bool? ?? false,
      note: json['note'] as String? ?? '',
    );
  }
}
