class HistoryEntry {
  const HistoryEntry({
    required this.date,
    this.bloodSugar,
    this.systolic,
    this.diastolic,
    this.weight,
    this.healthScore,
    this.status,
    this.statusLabel,
  });

  final DateTime date;
  final int? bloodSugar;
  final int? systolic;
  final int? diastolic;
  final double? weight;
  final int? healthScore;
  final String? status;
  final String? statusLabel;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    // Parse YYYY-MM-DD date.
    final dateStr = json['date'] as String;
    final parsedDate = DateTime.parse(dateStr);
    return HistoryEntry(
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      bloodSugar: json['blood_sugar'] != null ? (json['blood_sugar'] as num).toInt() : null,
      systolic: json['systolic'] != null ? (json['systolic'] as num).toInt() : null,
      diastolic: json['diastolic'] != null ? (json['diastolic'] as num).toInt() : null,
      weight: (json['weight'] as num?)?.toDouble(),
      healthScore: json['health_score'] != null
          ? (json['health_score'] as num).toInt()
          : (json['score'] as num?)?.toInt(),
      status: json['status'] as String?,
      statusLabel: json['status_label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'blood_sugar': bloodSugar,
      'systolic': systolic,
      'diastolic': diastolic,
      'weight': weight,
      if (healthScore != null) 'health_score': healthScore,
      if (status != null) 'status': status,
      if (statusLabel != null) 'status_label': statusLabel,
    };
  }
}
