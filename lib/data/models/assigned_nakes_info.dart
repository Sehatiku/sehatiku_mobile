class AssignedNakesInfo {
  const AssignedNakesInfo({
    required this.fullName,
    required this.specialization,
    required this.hospital,
    required this.whatsappPhone,
    required this.schedule,
    this.waLink,
  });

  final String fullName;
  final String specialization;
  final String hospital;
  final String whatsappPhone;
  final List<Map<String, dynamic>> schedule;
  final String? waLink;

  factory AssignedNakesInfo.fromJson(Map<String, dynamic> json) {
    return AssignedNakesInfo(
      fullName: json['full_name']?.toString().trim() ?? '',
      specialization: json['specialization']?.toString().trim() ?? '',
      hospital: json['hospital']?.toString().trim() ?? '',
      whatsappPhone: json['whatsapp_phone']?.toString().trim() ?? '',
      waLink: _nullableString(json['wa_link']),
      schedule: _parseSchedule(json['schedule']),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isNotEmpty ? text : null;
  }

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'specialization': specialization,
        'hospital': hospital,
        'whatsapp_phone': whatsappPhone,
        if (waLink != null) 'wa_link': waLink,
        'schedule': schedule,
      };

  static List<Map<String, dynamic>> _parseSchedule(dynamic raw) {
    if (raw is List) {
      return raw.map((item) {
        if (item is Map<String, dynamic>) return item;
        if (item is Map) return Map<String, dynamic>.from(item);
        return <String, dynamic>{};
      }).where((m) => m.isNotEmpty).toList();
    }
    return const [];
  }
}
