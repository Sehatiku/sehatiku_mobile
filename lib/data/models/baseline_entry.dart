class BaselineEntry {
  const BaselineEntry({
    required this.date,
    this.bloodSugar,
    this.systolic,
    this.diastolic,
    this.weight,
  });

  final DateTime date;
  final int? bloodSugar;
  final int? systolic;
  final int? diastolic;
  final double? weight;

  factory BaselineEntry.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String? ??
        json['recorded_at'] as String? ??
        json['created_at'] as String? ??
        DateTime.now().toIso8601String();
    final parsedDate = DateTime.parse(dateStr);
    return BaselineEntry(
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      bloodSugar: json['blood_sugar'] as int? ??
          json['glucose'] as int? ??
          json['fasting_blood_sugar'] as int?,
      systolic: json['systolic'] as int?,
      diastolic: json['diastolic'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'blood_sugar': bloodSugar,
      'systolic': systolic,
      'diastolic': diastolic,
      'weight': weight,
    };
  }
}
