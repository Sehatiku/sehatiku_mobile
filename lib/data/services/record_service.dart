import 'package:dio/dio.dart';
import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/data/models/history_entry.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';

/// Service for patient actor to save health logs and fetch history.
class RecordService {
  RecordService._();
  static final RecordService instance = RecordService._();

  /// POST /api/v1/patients/records
  ///
  /// Throws [ApiException] on failure.
  Future<void> saveRecord(HealthRecord record) async {
    try {
      final body = <String, dynamic>{
        'recorded_at': record.date.toIso8601String(),
      };
      if (record.bloodSugar != null) body['blood_sugar'] = record.bloodSugar;
      if (record.systolic != null) body['systolic'] = record.systolic;
      if (record.diastolic != null) body['diastolic'] = record.diastolic;
      if (record.weight != null) body['weight'] = record.weight;
      if (record.medicineTaken) body['medicine_taken'] = true;
      if (record.meals.isNotEmpty) body['meals'] = record.meals.join(', ');
      await ApiClient.instance.post('/api/v1/patients/records', data: body);
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }

  /// GET /api/v1/patients/records/history
  ///
  /// Throws [ApiException] on failure.
  Future<List<HistoryEntry>> fetchHistory({int limit = 30}) async {
    try {
      final resp = await ApiClient.instance.get(
        '/api/v1/patients/records/history',
        queryParameters: {'limit': limit},
      );
      final rawList = resp.data['data'] as List<dynamic>;
      return rawList
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }
}
