class PatientTodayStatus {
  const PatientTodayStatus({
    required this.loggedToday,
    this.daysSinceLastLog,
    this.lastLoggedAt,
    required this.date,
  });

  final bool loggedToday;
  final int? daysSinceLastLog;
  final String? lastLoggedAt;
  final String date;

  factory PatientTodayStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PatientTodayStatus(
      loggedToday: data['logged_today'] as bool,
      daysSinceLastLog: data['days_since_last_log'] as int?,
      lastLoggedAt: data['last_logged_at'] as String?,
      date: data['date'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'logged_today': loggedToday,
        'days_since_last_log': daysSinceLastLog,
        'last_logged_at': lastLoggedAt,
        'date': date,
      };
}
