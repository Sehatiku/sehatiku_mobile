class Consultation {
  const Consultation({
    required this.id,
    required this.patientId,
    required this.complaintSince,
    required this.complaintType,
    required this.complaintDetail,
    required this.status,
    this.nakesNote,
    this.repliedAt,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final String complaintSince;
  final String complaintType;
  final String complaintDetail;
  final String status; // 'open' | 'replied'
  final String? nakesNote;
  final DateTime? repliedAt;
  final DateTime createdAt;

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      complaintSince: json['complaint_since']?.toString() ?? '',
      complaintType: json['complaint_type']?.toString() ?? '',
      complaintDetail: json['complaint_detail']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? '',
      nakesNote: _nullableString(json['nakes_note']),
      repliedAt: json['replied_at'] != null && json['replied_at'].toString().isNotEmpty
          ? DateTime.parse(json['replied_at'].toString())
          : null,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isNotEmpty ? text : null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'complaint_since': complaintSince,
        'complaint_type': complaintType,
        'complaint_detail': complaintDetail,
        'status': status,
        if (nakesNote != null) 'nakes_note': nakesNote,
        if (repliedAt != null) 'replied_at': repliedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
