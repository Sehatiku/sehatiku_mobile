/// Typed response models for GET /api/v1/patients/dashboard
library;

// ─────────────────────────────────────────────────────────────────────────────
// Sub-models
// ─────────────────────────────────────────────────────────────────────────────

class DashboardProfile {
  const DashboardProfile({
    required this.fullName,
    required this.age,
    required this.diseaseType,
    this.companionName,
    this.companionPhone,
    this.assignedNakesName,
  });

  final String fullName;
  final int age;

  /// 'diabetes_t2' | 'hypertension' | 'both'
  final String diseaseType;

  /// Nama pendamping/kontak darurat dari field `companion_name`.
  final String? companionName;

  /// Nomor WA pendamping dari field `companion_phone`.
  final String? companionPhone;

  /// Nama nakes penanggung jawab dari field `assigned_nakes_name`.
  final String? assignedNakesName;

  /// Formatted "Nama · nomor" untuk ditampilkan di profil. Null jika belum ada.
  String? get emergencyContactDisplay {
    final name = companionName;
    final phone = companionPhone;
    if (name == null || name.trim().isEmpty) return null;
    if (phone == null || phone.trim().isEmpty) return name;
    return '$name · $phone';
  }

  factory DashboardProfile.fromJson(Map<String, dynamic> json) =>
      DashboardProfile(
        fullName: json['full_name'] as String,
        age: json['age'] as int,
        diseaseType: json['disease_type'] as String,
        companionName: json['companion_name'] as String?,
        companionPhone: json['companion_phone'] as String?,
        assignedNakesName: json['assigned_nakes_name'] as String?,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class DashboardRisk {
  const DashboardRisk({
    required this.score,
    required this.riskLabel,
    required this.status,
    required this.statusLabel,
    required this.mainFactor,
    required this.topPenalties,
    this.message,
    this.scoredAt,
  });

  final int score;

  /// 'kritis' | 'sedang' | 'rendah'
  final String riskLabel;

  /// 'bahaya' | 'waswas' | 'aman'
  final String status;

  /// Display label: 'Sehat' | 'Waswas' | 'Parah'
  final String statusLabel;

  /// Indonesian label for top SHAP factor, empty if no score yet.
  final String mainFactor;

  /// Ready-to-display Indonesian penalty strings — show as-is, no post-processing.
  final List<String> topPenalties;

  /// Ready-to-display Indonesian message from the ML model.
  final String? message;

  /// ISO 8601 — null if no score yet.
  final String? scoredAt;

  factory DashboardRisk.fromJson(Map<String, dynamic> json) => DashboardRisk(
        score: json['score'] as int? ?? 0,
        riskLabel: json['risk_label'] as String? ?? '',
        status: json['status'] as String? ?? '',
        statusLabel: json['status_label'] as String? ?? '',
        mainFactor: json['main_factor'] as String? ?? '',
        topPenalties: (json['top_penalties'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        message: json['message'] as String?,
        scoredAt: json['scored_at'] as String?,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class GlucoseMeasurement {
  const GlucoseMeasurement({required this.value, required this.measuredAt});

  final int value;
  final String measuredAt;

  factory GlucoseMeasurement.fromJson(Map<String, dynamic> json) =>
      GlucoseMeasurement(
        value: (json['value'] as num).toInt(),
        measuredAt: json['measured_at'] as String,
      );
}

class BloodPressureMeasurement {
  const BloodPressureMeasurement({
    required this.systolic,
    required this.diastolic,
    required this.measuredAt,
  });

  final int systolic;
  final int diastolic;
  final String measuredAt;

  factory BloodPressureMeasurement.fromJson(Map<String, dynamic> json) =>
      BloodPressureMeasurement(
        systolic: (json['systolic'] as num).toInt(),
        diastolic: (json['diastolic'] as num).toInt(),
        measuredAt: json['measured_at'] as String,
      );
}

class LatestMeasurements {
  const LatestMeasurements({this.glucose, this.bloodPressure});

  /// null if no glucose log yet.
  final GlucoseMeasurement? glucose;

  /// null if no blood pressure log yet.
  final BloodPressureMeasurement? bloodPressure;

  factory LatestMeasurements.fromJson(Map<String, dynamic> json) {
    final g = json['glucose'];
    final bp = json['blood_pressure'];
    return LatestMeasurements(
      glucose: g != null
          ? GlucoseMeasurement.fromJson(g as Map<String, dynamic>)
          : null,
      bloodPressure: bp != null
          ? BloodPressureMeasurement.fromJson(bp as Map<String, dynamic>)
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class DashboardLogging {
  const DashboardLogging({
    required this.loggedToday,
    required this.streakDays,
  });

  final bool loggedToday;
  final int streakDays;

  factory DashboardLogging.fromJson(Map<String, dynamic> json) =>
      DashboardLogging(
        loggedToday: json['logged_today'] as bool,
        streakDays: json['streak_days'] as int,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Root response
// ─────────────────────────────────────────────────────────────────────────────

class PatientDashboard {
  const PatientDashboard({
    required this.profile,
    required this.risk,
    required this.latestMeasurements,
    required this.logging,
    required this.recommendations,
  });

  final DashboardProfile profile;
  final DashboardRisk risk;
  final LatestMeasurements latestMeasurements;
  final DashboardLogging logging;
  final List<String> recommendations;

  factory PatientDashboard.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final profileJson = data['profile'] as Map<String, dynamic>?;
    final riskJson = data['risk'] as Map<String, dynamic>?;
    final latestMeasurementsJson = data['latest_measurements'] as Map<String, dynamic>?;
    final loggingJson = data['logging'] as Map<String, dynamic>?;
    final recommendationsJson = data['recommendations'] as List<dynamic>?;

    return PatientDashboard(
      profile: profileJson != null
          ? DashboardProfile.fromJson(profileJson)
          : const DashboardProfile(fullName: 'Pengguna', age: 0, diseaseType: ''),
      risk: riskJson != null
          ? DashboardRisk.fromJson(riskJson)
          : const DashboardRisk(
              score: 0,
              riskLabel: '',
              status: '',
              statusLabel: '',
              mainFactor: '',
              topPenalties: [],
            ),
      latestMeasurements: latestMeasurementsJson != null
          ? LatestMeasurements.fromJson(latestMeasurementsJson)
          : const LatestMeasurements(),
      logging: loggingJson != null
          ? DashboardLogging.fromJson(loggingJson)
          : const DashboardLogging(loggedToday: false, streakDays: 0),
      recommendations: recommendationsJson != null
          ? recommendationsJson.map((e) => e as String).toList()
          : const [],
    );
  }
}
