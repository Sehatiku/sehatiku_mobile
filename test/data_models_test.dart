import 'package:flutter_test/flutter_test.dart';
import 'package:sehatiku_mobile/data/models/assigned_nakes_info.dart';
import 'package:sehatiku_mobile/data/models/baseline_entry.dart';
import 'package:sehatiku_mobile/data/models/history_entry.dart';
import 'package:sehatiku_mobile/data/models/notification_model.dart';

void main() {
  group('NotificationModel Tests', () {
    test('fromJson parses user notification format successfully', () {
      final json = {
        "id": "8751f824-7a64-4f02-85aa-b685b1c29d2d",
        "message_type": "consultation_reply",
        "nakes_name": "ironmen",
        "nakes_note": "ywd",
        "consultation_id": "4d538d02-6653-480a-96e8-cfc8635d9d1d",
        "created_at": "2026-06-29T08:18:56.72442Z"
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, equals('8751f824-7a64-4f02-85aa-b685b1c29d2d'));
      expect(notif.type, equals('consultation_reply'));
      expect(notif.title, equals('Balasan dari ironmen'));
      expect(notif.message, equals('ywd'));
      expect(notif.nakesName, equals('ironmen'));
      expect(notif.nakesNote, equals('ywd'));
      expect(notif.consultationId, equals('4d538d02-6653-480a-96e8-cfc8635d9d1d'));
      expect(notif.createdAt, equals(DateTime.parse('2026-06-29T08:18:56.72442Z')));
    });

    test('fromJson parses is_read field successfully', () {
      final json1 = {
        "id": "1",
        "message_type": "general",
        "message": "hello",
        "created_at": "2026-06-29T08:18:56Z",
        "is_read": true
      };
      final notif1 = NotificationModel.fromJson(json1);
      expect(notif1.isRead, isTrue);

      final json2 = {
        "id": "2",
        "message_type": "general",
        "message": "hello",
        "created_at": "2026-06-29T08:18:56Z",
        "is_read": false
      };
      final notif2 = NotificationModel.fromJson(json2);
      expect(notif2.isRead, isFalse);

      final json3 = {
        "id": "3",
        "message_type": "general",
        "message": "hello",
        "created_at": "2026-06-29T08:18:56Z"
      };
      final notif3 = NotificationModel.fromJson(json3);
      expect(notif3.isRead, isFalse);
    });

    test('fromJson parses notification with empty nakes_name successfully', () {
      final json = {
        "id": "3bbfedd0-cd2d-449e-b719-f77d2e5b32ba",
        "message_type": "consultation_reply",
        "nakes_name": "",
        "nakes_note": "aaaaa",
        "consultation_id": "6fcb8767-dd52-4646-a9e0-9a0853aaf9a4",
        "created_at": "2026-06-29T07:44:55.365091Z"
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, equals('3bbfedd0-cd2d-449e-b719-f77d2e5b32ba'));
      expect(notif.type, equals('consultation_reply'));
      expect(notif.title, equals('Balasan Konsultasi'));
      expect(notif.message, equals('aaaaa'));
      expect(notif.nakesName, isEmpty);
      expect(notif.nakesNote, equals('aaaaa'));
      expect(notif.consultationId, equals('6fcb8767-dd52-4646-a9e0-9a0853aaf9a4'));
    });
  });

  group('AssignedNakesInfo Model Tests', () {
    test('fromJson parses valid JSON with all fields successfully', () {
      final json = {
        'full_name': 'dr. Surya Wijaya, Sp.PD',
        'specialization': 'Spesialis Penyakit Dalam',
        'hospital': 'RS Permata Sehat',
        'whatsapp_phone': '628123456789',
        'wa_link': 'https://wa.me/628123456789',
        'schedule': [
          {'days': 'Senin - Jumat', 'time': '08.00 - 14.00'},
          {'days': 'Sabtu', 'time': '08.00 - 12.00'}
        ]
      };

      final info = AssignedNakesInfo.fromJson(json);

      expect(info.fullName, equals('dr. Surya Wijaya, Sp.PD'));
      expect(info.specialization, equals('Spesialis Penyakit Dalam'));
      expect(info.hospital, equals('RS Permata Sehat'));
      expect(info.whatsappPhone, equals('628123456789'));
      expect(info.waLink, equals('https://wa.me/628123456789'));
      expect(info.schedule.length, equals(2));
      expect(info.schedule[0]['days'], equals('Senin - Jumat'));
      expect(info.schedule[1]['time'], equals('08.00 - 12.00'));
    });

    test('fromJson handles null/missing fields gracefully', () {
      final json = <String, dynamic>{};

      final info = AssignedNakesInfo.fromJson(json);

      expect(info.fullName, isEmpty);
      expect(info.specialization, isEmpty);
      expect(info.hospital, isEmpty);
      expect(info.whatsappPhone, isEmpty);
      expect(info.waLink, isNull);
      expect(info.schedule, isEmpty);
    });

    test('toJson converts model back to JSON map successfully', () {
      const model = AssignedNakesInfo(
        fullName: 'dr. Surya Wijaya',
        specialization: 'Penyakit Dalam',
        hospital: 'Klinik Sehat',
        whatsappPhone: '628123456',
        waLink: 'https://wa.me/628123456',
        schedule: [
          {'days': 'Senin', 'time': '10.00'}
        ],
      );

      final json = model.toJson();

      expect(json['full_name'], equals('dr. Surya Wijaya'));
      expect(json['specialization'], equals('Penyakit Dalam'));
      expect(json['hospital'], equals('Klinik Sehat'));
      expect(json['whatsapp_phone'], equals('628123456'));
      expect(json['wa_link'], equals('https://wa.me/628123456'));
      expect((json['schedule'] as List).length, equals(1));
    });
  });

  group('HistoryEntry Model Tests', () {
    test('fromJson parses valid history JSON successfully', () {
      final json = {
        'date': '2026-06-28',
        'blood_sugar': 140,
        'systolic': 120,
        'diastolic': 80,
        'weight': 68.5
      };

      final entry = HistoryEntry.fromJson(json);

      expect(entry.date, equals(DateTime(2026, 6, 28)));
      expect(entry.bloodSugar, equals(140));
      expect(entry.systolic, equals(120));
      expect(entry.diastolic, equals(80));
      expect(entry.weight, equals(68.5));
    });

    test('toJson and fromJson round-trip works perfectly', () {
      final original = HistoryEntry(
        date: DateTime(2026, 6, 28),
        bloodSugar: 130,
        systolic: 115,
        diastolic: 75,
        weight: 70.0,
      );

      final json = original.toJson();
      final parsed = HistoryEntry.fromJson(json);

      expect(parsed.date, equals(original.date));
      expect(parsed.bloodSugar, equals(original.bloodSugar));
      expect(parsed.systolic, equals(original.systolic));
      expect(parsed.diastolic, equals(original.diastolic));
      expect(parsed.weight, equals(original.weight));
    });

    test('fromJson handles null values successfully', () {
      final json = {
        'date': '2026-06-28',
        'blood_sugar': null,
        'systolic': null,
        'diastolic': null,
        'weight': null
      };

      final entry = HistoryEntry.fromJson(json);

      expect(entry.date, equals(DateTime(2026, 6, 28)));
      expect(entry.bloodSugar, isNull);
      expect(entry.systolic, isNull);
      expect(entry.diastolic, isNull);
      expect(entry.weight, isNull);
    });
  });

  group('BaselineEntry Model Tests', () {
    test('fromJson parses valid baseline JSON successfully', () {
      final json = {
        'date': '2026-06-30',
        'blood_sugar': 120,
        'systolic': 125,
        'diastolic': 80,
        'weight': 70.0,
      };

      final entry = BaselineEntry.fromJson(json);

      expect(entry.date, equals(DateTime(2026, 6, 30)));
      expect(entry.bloodSugar, equals(120));
      expect(entry.systolic, equals(125));
      expect(entry.diastolic, equals(80));
      expect(entry.weight, equals(70.0));
    });

    test('fromJson falls back to alternative field names', () {
      final json = {
        'recorded_at': '2026-06-15T08:00:00Z',
        'glucose': 130,
        'systolic': 130,
        'diastolic': 85,
        'weight': 72.5,
      };

      final entry = BaselineEntry.fromJson(json);

      expect(entry.date, equals(DateTime(2026, 6, 15)));
      expect(entry.bloodSugar, equals(130));
      expect(entry.systolic, equals(130));
      expect(entry.diastolic, equals(85));
      expect(entry.weight, equals(72.5));
    });

    test('toJson converts model back to JSON map successfully', () {
      final original = BaselineEntry(
        date: DateTime(2026, 6, 30),
        bloodSugar: 120,
        systolic: 125,
        diastolic: 80,
        weight: 70.0,
      );

      final json = original.toJson();
      final parsed = BaselineEntry.fromJson(json);

      expect(parsed.date, equals(original.date));
      expect(parsed.bloodSugar, equals(original.bloodSugar));
      expect(parsed.systolic, equals(original.systolic));
      expect(parsed.diastolic, equals(original.diastolic));
      expect(parsed.weight, equals(original.weight));
    });

    test('fromJson parses full baseline API response successfully', () {
      final json = {
        "id": "e9e94fa5-0357-4ab6-a9b1-78c0cf412e94",
        "recorded_at": "2026-06-29T18:27:34.162044Z",
        "recorded_by_nakes_name": "dr. Surya",
        "notes": "Some notes here",
        "bmi": 31.5,
        "bmi_category": "obese",
        "systolic_bp_mmhg": 158,
        "diastolic_bp_mmhg": 96,
        "hypertension_status": "stage2",
        "fasting_glucose_mgdl": 165,
        "hba1c_pct": 9.2,
        "diabetes_status": "uncontrolled",
        "total_cholesterol_mgdl": 240,
        "hdl_mgdl": 38,
        "ldl_mgdl": 165,
        "triglycerides_mgdl": 220,
        "cvd_risk_10yr_pct": 28.5,
        "cvd_risk_category": "very_high",
        "egfr": 56,
        "uacr": 35
      };

      final entry = BaselineEntry.fromJson(json);

      expect(entry.id, equals("e9e94fa5-0357-4ab6-a9b1-78c0cf412e94"));
      expect(entry.date, equals(DateTime(2026, 6, 29)));
      expect(entry.recordedByNakesName, equals("dr. Surya"));
      expect(entry.notes, equals("Some notes here"));
      expect(entry.bmi, equals(31.5));
      expect(entry.bmiCategory, equals("obese"));
      expect(entry.systolic, equals(158));
      expect(entry.diastolic, equals(96));
      expect(entry.hypertensionStatus, equals("stage2"));
      expect(entry.bloodSugar, equals(165));
      expect(entry.hba1cPct, equals(9.2));
      expect(entry.diabetesStatus, equals("uncontrolled"));
      expect(entry.totalCholesterolMgdl, equals(240));
      expect(entry.hdlMgdl, equals(38));
      expect(entry.ldlMgdl, equals(165));
      expect(entry.triglyceridesMgdl, equals(220));
      expect(entry.cvdRisk10yrPct, equals(28.5));
      expect(entry.cvdRiskCategory, equals("very_high"));
      expect(entry.egfr, equals(56));
      expect(entry.uacr, equals(35));
    });
  });
}
