import 'package:flutter_test/flutter_test.dart';
import 'package:sehatiku_mobile/data/models/assigned_nakes_info.dart';
import 'package:sehatiku_mobile/data/models/history_entry.dart';

void main() {
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
}
