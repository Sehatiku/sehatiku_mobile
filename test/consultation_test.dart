import 'package:flutter_test/flutter_test.dart';
import 'package:sehatiku_mobile/data/models/consultation.dart';

void main() {
  group('Consultation Model Tests', () {
    test('fromJson parses valid JSON with all fields successfully', () {
      final json = {
        'id': 'consultation-id-123',
        'patient_id': 'patient-id-456',
        'complaint_since': 'Sejak kemarin',
        'complaint_type': 'Pusing dan mual',
        'complaint_detail': 'Detail keluhan pusing mual setelah makan malam.',
        'status': 'replied',
        'nakes_note': 'Silakan minum obat pereda nyeri dan istirahat.',
        'replied_at': '2026-06-29T10:00:00.000Z',
        'created_at': '2026-06-29T08:00:00.000Z',
      };

      final consultation = Consultation.fromJson(json);

      expect(consultation.id, equals('consultation-id-123'));
      expect(consultation.patientId, equals('patient-id-456'));
      expect(consultation.complaintSince, equals('Sejak kemarin'));
      expect(consultation.complaintType, equals('Pusing dan mual'));
      expect(consultation.complaintDetail, equals('Detail keluhan pusing mual setelah makan malam.'));
      expect(consultation.status, equals('replied'));
      expect(consultation.nakesNote, equals('Silakan minum obat pereda nyeri dan istirahat.'));
      expect(consultation.repliedAt, equals(DateTime.parse('2026-06-29T10:00:00.000Z')));
      expect(consultation.createdAt, equals(DateTime.parse('2026-06-29T08:00:00.000Z')));
    });

    test('fromJson handles null/missing optional fields successfully', () {
      final json = {
        'id': 'consultation-id-123',
        'patient_id': 'patient-id-456',
        'complaint_since': 'Sejak kemarin',
        'complaint_type': 'Pusing dan mual',
        'complaint_detail': 'Detail keluhan pusing mual setelah makan malam.',
        'status': 'open',
        'nakes_note': null,
        'replied_at': null,
        'created_at': '2026-06-29T08:00:00.000Z',
      };

      final consultation = Consultation.fromJson(json);

      expect(consultation.id, equals('consultation-id-123'));
      expect(consultation.status, equals('open'));
      expect(consultation.nakesNote, isNull);
      expect(consultation.repliedAt, isNull);
      expect(consultation.createdAt, equals(DateTime.parse('2026-06-29T08:00:00.000Z')));
    });

    test('toJson converts model back to JSON map successfully', () {
      final model = Consultation(
        id: 'consultation-id-123',
        patientId: 'patient-id-456',
        complaintSince: 'Sejak kemarin',
        complaintType: 'Pusing dan mual',
        complaintDetail: 'Detail keluhan pusing mual setelah makan malam.',
        status: 'replied',
        nakesNote: 'Silakan minum obat pereda nyeri dan istirahat.',
        repliedAt: DateTime.parse('2026-06-29T10:00:00.000Z'),
        createdAt: DateTime.parse('2026-06-29T08:00:00.000Z'),
      );

      final json = model.toJson();

      expect(json['id'], equals('consultation-id-123'));
      expect(json['patient_id'], equals('patient-id-456'));
      expect(json['complaint_since'], equals('Sejak kemarin'));
      expect(json['complaint_type'], equals('Pusing dan mual'));
      expect(json['complaint_detail'], equals('Detail keluhan pusing mual setelah makan malam.'));
      expect(json['status'], equals('replied'));
      expect(json['nakes_note'], equals('Silakan minum obat pereda nyeri dan istirahat.'));
      expect(json['replied_at'], equals(DateTime.parse('2026-06-29T10:00:00.000Z').toIso8601String()));
      expect(json['created_at'], equals(DateTime.parse('2026-06-29T08:00:00.000Z').toIso8601String()));
    });
  });
}
