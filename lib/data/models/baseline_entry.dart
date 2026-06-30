class BaselineEntry {
  const BaselineEntry({
    required this.date,
    this.id,
    this.recordedByNakesName,
    this.notes,
    this.bmi,
    this.bmiCategory,
    this.systolic,
    this.diastolic,
    this.hypertensionStatus,
    this.bloodSugar,
    this.hba1cPct,
    this.diabetesStatus,
    this.totalCholesterolMgdl,
    this.hdlMgdl,
    this.ldlMgdl,
    this.triglyceridesMgdl,
    this.cvdRisk10yrPct,
    this.cvdRiskCategory,
    this.egfr,
    this.uacr,
    this.weight,
  });

  final DateTime date;
  final String? id;
  final String? recordedByNakesName;
  final String? notes;
  final double? bmi;
  final String? bmiCategory;
  final int? systolic;
  final int? diastolic;
  final String? hypertensionStatus;
  final int? bloodSugar;
  final double? hba1cPct;
  final String? diabetesStatus;
  final int? totalCholesterolMgdl;
  final int? hdlMgdl;
  final int? ldlMgdl;
  final int? triglyceridesMgdl;
  final double? cvdRisk10yrPct;
  final String? cvdRiskCategory;
  final int? egfr;
  final int? uacr;
  final double? weight;

  factory BaselineEntry.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String? ??
        json['recorded_at'] as String? ??
        json['created_at'] as String? ??
        DateTime.now().toIso8601String();
    final parsedDate = DateTime.parse(dateStr);
    return BaselineEntry(
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      id: json['id'] as String?,
      recordedByNakesName: json['recorded_by_nakes_name'] as String?,
      notes: json['notes'] as String?,
      bmi: (json['bmi'] as num?)?.toDouble(),
      bmiCategory: json['bmi_category'] as String?,
      systolic: json['systolic'] as int? ?? json['systolic_bp_mmhg'] as int?,
      diastolic: json['diastolic'] as int? ?? json['diastolic_bp_mmhg'] as int?,
      hypertensionStatus: json['hypertension_status'] as String?,
      bloodSugar: json['blood_sugar'] as int? ??
          json['glucose'] as int? ??
          json['fasting_blood_sugar'] as int? ??
          json['fasting_glucose_mgdl'] as int?,
      hba1cPct: (json['hba1c_pct'] as num?)?.toDouble(),
      diabetesStatus: json['diabetes_status'] as String?,
      totalCholesterolMgdl: json['total_cholesterol_mgdl'] as int?,
      hdlMgdl: json['hdl_mgdl'] as int?,
      ldlMgdl: json['ldl_mgdl'] as int?,
      triglyceridesMgdl: json['triglycerides_mgdl'] as int?,
      cvdRisk10yrPct: (json['cvd_risk_10yr_pct'] as num?)?.toDouble(),
      cvdRiskCategory: json['cvd_risk_category'] as String?,
      egfr: json['egfr'] as int?,
      uacr: json['uacr'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'id': id,
      'recorded_by_nakes_name': recordedByNakesName,
      'notes': notes,
      'bmi': bmi,
      'bmi_category': bmiCategory,
      'systolic': systolic,
      'diastolic': diastolic,
      'hypertension_status': hypertensionStatus,
      'blood_sugar': bloodSugar,
      'hba1c_pct': hba1cPct,
      'diabetes_status': diabetesStatus,
      'total_cholesterol_mgdl': totalCholesterolMgdl,
      'hdl_mgdl': hdlMgdl,
      'ldl_mgdl': ldlMgdl,
      'triglycerides_mgdl': triglyceridesMgdl,
      'cvd_risk_10yr_pct': cvdRisk10yrPct,
      'cvd_risk_category': cvdRiskCategory,
      'egfr': egfr,
      'uacr': uacr,
      'weight': weight,
    };
  }
}
