class HistoryEntry {
  const HistoryEntry({
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

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    // Parse YYYY-MM-DD date.
    final dateStr = json['date'] as String;
    final parsedDate = DateTime.parse(dateStr);
    return HistoryEntry(
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      bloodSugar: json['blood_sugar'] as int?,
      systolic: json['systolic'] as int?,
      diastolic: json['diastolic'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'blood_sugar': bloodSugar,
      'systolic': systolic,
      'diastolic': diastolic,
      'weight': weight,
    };
  }
}
