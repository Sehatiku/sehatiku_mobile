import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/theme/app_colors.dart';

/// A single day's health log. One record per calendar day; saving again on the
/// same day overwrites the previous entry for that day.
class HealthRecord {
  HealthRecord({
    required this.date,
    this.healthScore,
    this.apiStatus,
    this.apiStatusLabel,
    // Physiological
    this.bloodSugar,
    this.bloodSugarTag = '',
    this.systolic,
    this.diastolic,
    this.weight,
    this.medicineTaken = false,
    this.medicineName = '',
    this.medicineTime = '',
    // Lifestyle
    Set<String>? meals,
    this.portion = '',
    this.active30 = false,
    this.activityType = '',
    this.activityMinutes = 0,
    this.sleepHours,
    this.sleepQuality = 1,
    this.stressIndex = 1,
    this.smoke = false,
    this.alcohol = false,
    this.note = '',
  }) : meals = meals ?? <String>{};

  /// Always normalised to midnight so one record maps to one calendar day.
  final DateTime date;

  /// Custom precomputed score and status from API/DB.
  final int? healthScore;
  final String? apiStatus;
  final String? apiStatusLabel;

  // --- Physiological ---
  final int? bloodSugar;

  /// Measurement timing tag for [bloodSugar], e.g. 'puasa', 'sesudah_makan'.
  /// Empty when not specified. See `bloodSugarTagLabels`.
  final String bloodSugarTag;
  final int? systolic;
  final int? diastolic;
  final double? weight;
  final bool medicineTaken;
  final String medicineName;
  final String medicineTime;

  // --- Lifestyle (daily quick choices) ---

  /// Food categories eaten today. See `foodCategories`.
  final Set<String> meals;

  /// Portion size key, e.g. 'sedang'. Empty when not specified.
  final String portion;

  /// Whether the user did ≥30 minutes of physical activity today.
  final bool active30;
  final String activityType;
  final int activityMinutes;

  /// Sleep duration in hours; null when not logged.
  final double? sleepHours;

  /// Sleep quality, indexed 0..2 (Buruk/Cukup/Nyenyak).
  final int sleepQuality;

  final int stressIndex;
  final bool smoke;
  final bool alcohol;
  final String note;

  static DateTime dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Transparent rule-based wellness score (0-100). This is a heuristic for the
  /// demo, not a medical diagnosis.
  int get score {
    if (healthScore != null) return healthScore!;
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
    if (!active30) s -= 8;

    // Sleep only counts when the user actually logged a duration.
    final sh = sleepHours;
    if (sh != null) {
      if (sh < 6) {
        s -= 8;
      } else if (sh > 9) {
        s -= 4;
      }
      if (sleepQuality == 0) {
        s -= 6;
      } else if (sleepQuality == 1) {
        s -= 2;
      }
    }

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
    if (apiStatusLabel != null && apiStatusLabel!.isNotEmpty) {
      final val = apiStatusLabel!;
      return '${val[0].toUpperCase()}${val.substring(1)}';
    }
    if (apiStatus != null && apiStatus!.isNotEmpty) {
      final val = apiStatus!;
      return '${val[0].toUpperCase()}${val.substring(1)}';
    }
    final sc = score;
    if (sc >= 80) return 'Aman';
    if (sc >= 60) return 'Perhatian';
    return 'Waspada';
  }

  Color get statusColor {
    if (apiStatus != null && apiStatus!.isNotEmpty) {
      return switch (apiStatus) {
        'bahaya' => AppColors.red,
        'waswas' => AppColors.amber,
        _ => AppColors.lime,
      };
    }
    final sc = score;
    if (sc >= 80) return AppColors.lime;
    if (sc >= 60) return AppColors.amber;
    return AppColors.red;
  }

  Color get statusBg {
    if (apiStatus != null && apiStatus!.isNotEmpty) {
      return switch (apiStatus) {
        'bahaya' => const Color(0xFFFFEEF0),
        'waswas' => const Color(0xFFFFF8E6),
        _ => const Color(0xFFE7F7EC),
      };
    }
    final sc = score;
    if (sc >= 80) return const Color(0xFFE7F7EC);
    if (sc >= 60) return const Color(0xFFFFF8E6);
    return const Color(0xFFFFEEF0);
  }

  String get bloodPressure =>
      (systolic != null && diastolic != null) ? '$systolic/$diastolic' : '—';

  HealthRecord copyWith({
    int? healthScore,
    String? apiStatus,
    String? apiStatusLabel,
    int? bloodSugar,
    String? bloodSugarTag,
    int? systolic,
    int? diastolic,
    double? weight,
    bool? medicineTaken,
    String? medicineName,
    String? medicineTime,
    Set<String>? meals,
    String? portion,
    bool? active30,
    String? activityType,
    int? activityMinutes,
    double? sleepHours,
    int? sleepQuality,
    int? stressIndex,
    bool? smoke,
    bool? alcohol,
    String? note,
  }) {
    return HealthRecord(
      date: date,
      healthScore: healthScore ?? this.healthScore,
      apiStatus: apiStatus ?? this.apiStatus,
      apiStatusLabel: apiStatusLabel ?? this.apiStatusLabel,
      bloodSugar: bloodSugar ?? this.bloodSugar,
      bloodSugarTag: bloodSugarTag ?? this.bloodSugarTag,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      weight: weight ?? this.weight,
      medicineTaken: medicineTaken ?? this.medicineTaken,
      medicineName: medicineName ?? this.medicineName,
      medicineTime: medicineTime ?? this.medicineTime,
      meals: meals ?? this.meals,
      portion: portion ?? this.portion,
      active30: active30 ?? this.active30,
      activityType: activityType ?? this.activityType,
      activityMinutes: activityMinutes ?? this.activityMinutes,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      stressIndex: stressIndex ?? this.stressIndex,
      smoke: smoke ?? this.smoke,
      alcohol: alcohol ?? this.alcohol,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'healthScore': healthScore,
    'apiStatus': apiStatus,
    'apiStatusLabel': apiStatusLabel,
    'bloodSugar': bloodSugar,
    'bloodSugarTag': bloodSugarTag,
    'systolic': systolic,
    'diastolic': diastolic,
    'weight': weight,
    'medicineTaken': medicineTaken,
    'medicineName': medicineName,
    'medicineTime': medicineTime,
    'meals': meals.toList(),
    'portion': portion,
    'active30': active30,
    'activityType': activityType,
    'activityMinutes': activityMinutes,
    'sleepHours': sleepHours,
    'sleepQuality': sleepQuality,
    'stressIndex': stressIndex,
    'smoke': smoke,
    'alcohol': alcohol,
    'note': note,
  };

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      date: dayOf(DateTime.parse(json['date'] as String)),
      healthScore: json['healthScore'] as int?,
      apiStatus: json['apiStatus'] as String?,
      apiStatusLabel: json['apiStatusLabel'] as String?,
      bloodSugar: json['bloodSugar'] as int?,
      bloodSugarTag: json['bloodSugarTag'] as String? ?? '',
      systolic: json['systolic'] as int?,
      diastolic: json['diastolic'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      medicineTaken: json['medicineTaken'] as bool? ?? false,
      medicineName: json['medicineName'] as String? ?? '',
      medicineTime: json['medicineTime'] as String? ?? '',
      meals: (json['meals'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toSet(),
      portion: json['portion'] as String? ?? '',
      // Migrate legacy records that stored activity minutes instead of a flag.
      active30:
          json['active30'] as bool? ??
          ((json['activityMinutes'] as int?) ?? 0) >= 30,
      activityType: json['activityType'] as String? ?? '',
      activityMinutes: json['activityMinutes'] as int? ?? 0,
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      sleepQuality: json['sleepQuality'] as int? ?? 1,
      stressIndex: json['stressIndex'] as int? ?? 1,
      smoke: json['smoke'] as bool? ?? false,
      alcohol: json['alcohol'] as bool? ?? false,
      note: json['note'] as String? ?? '',
    );
  }
}
