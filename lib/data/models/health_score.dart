/// Response model for health score from POST /records and GET /health-score.
class HealthScore {
  const HealthScore({
    required this.healthScore,
    required this.status,
    required this.statusLabel,
    required this.message,
    required this.topPenalties,
    required this.scoredAt,
  });

  /// Numeric score 1–100.
  final double healthScore;

  /// 'aman' | 'waswas' | 'bahaya'
  final String status;

  /// Display label: 'Sehat' | 'Waswas' | 'Parah'
  final String statusLabel;

  /// Ready-to-display Indonesian message from the ML model.
  final String message;

  /// Ready-to-display Indonesian penalty strings — show as-is, no post-processing.
  final List<String> topPenalties;

  final String scoredAt;

  factory HealthScore.fromJson(Map<String, dynamic> json) {
    return HealthScore(
      healthScore: (json['health_score'] as num).toDouble(),
      status: json['status'] as String,
      statusLabel: json['status_label'] as String,
      message: json['message'] as String,
      topPenalties: (json['top_penalties'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      scoredAt: json['scored_at'] as String,
    );
  }
}
