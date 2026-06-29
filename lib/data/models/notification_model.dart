class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.nakesName,
    this.nakesNote,
    this.consultationId,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final String? nakesName;
  final String? nakesNote;
  final String? consultationId;
  final bool isRead;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final type = (json['message_type'] ?? json['type'] ?? '').toString().trim();
    
    // Extract nested data if it exists
    final nestedData = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null);

    final nakesName = (nestedData?['nakes_name'] ?? json['nakes_name'])?.toString().trim();
    final consultationId = (nestedData?['consultation_id'] ?? json['consultation_id'])?.toString().trim();

    // Determine title
    String title = json['title']?.toString().trim() ?? '';
    if (title.isEmpty) {
      if (type == 'consultation_reply') {
        title = nakesName != null && nakesName.isNotEmpty ? 'Balasan dari $nakesName' : 'Balasan Konsultasi';
      } else {
        title = 'Notifikasi';
      }
    }

    // Determine message (prioritize body/message/content/nakes_note)
    String message = (json['body'] ?? json['message'] ?? json['desc'] ?? json['content'] ?? json['nakes_note'] ?? '').toString().trim();
    if (message.isEmpty && type == 'consultation_reply') {
      message = (nestedData?['nakes_note'] ?? '').toString().trim();
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: title,
      message: message,
      type: type,
      createdAt: () {
        try {
          if (json['created_at'] != null && json['created_at'].toString().isNotEmpty) {
            return DateTime.parse(json['created_at'].toString());
          }
        } catch (_) {}
        return DateTime.now();
      }(),
      nakesName: nakesName,
      nakesNote: (json['nakes_note'] ?? nestedData?['nakes_note'])?.toString().trim() ?? (type == 'consultation_reply' ? message : null),
      consultationId: consultationId,
      isRead: json['is_read'] as bool? ?? json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
        if (nakesName != null) 'nakes_name': nakesName,
        if (nakesNote != null) 'nakes_note': nakesNote,
        if (consultationId != null) 'consultation_id': consultationId,
      };
}
