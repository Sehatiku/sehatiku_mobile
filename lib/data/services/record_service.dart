import 'dart:math';

import 'package:dio/dio.dart';
import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/data/models/health_score.dart';
import 'package:sehatiku_mobile/data/models/history_entry.dart';
import 'package:sehatiku_mobile/data/models/today_status.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';

/// Service for patient actor to save health records and fetch history.
class RecordService {
  RecordService._();
  static final RecordService instance = RecordService._();

  /// ML inference can take up to 60 s on cold start; give 90 s headroom.
  static const _kScoreTimeout = Duration(seconds: 90);

  HealthScore? _cachedScore;

  HealthScore? get cachedScore => _cachedScore;

  void clearCache() {
    _cachedScore = null;
  }

  /// GET /api/v1/patients/records/today-status
  ///
  /// Throws [ApiException] on failure.
  Future<PatientTodayStatus> fetchTodayStatus() async {
    try {
      final resp = await ApiClient.instance.get('/api/v1/patients/records/today-status');
      return PatientTodayStatus.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }

  /// Returns noon UTC for the given calendar date so the date is unambiguous
  /// across all time-zones.
  ///
  /// For *today* in time-zones ahead of UTC (e.g. WIB = UTC+7) noon UTC can
  /// still be in the future (12:00Z = 19:00 WIB), and the backend rejects a
  /// future `recorded_at` with HTTP 400. Clamp to "now" so the timestamp is
  /// never in the future.
  String _recordedAt(DateTime date) {
    final nowUtc = DateTime.now().toUtc();
    var ts = DateTime.utc(date.year, date.month, date.day, 12, 0, 0);
    if (ts.isAfter(nowUtc)) ts = nowUtc;
    return ts.toIso8601String();
  }

  /// POST /api/v1/patients/records
  ///
  /// Returns the [HealthScore] embedded in the 201 response, or null if the
  /// backend omitted it (no baseline yet, ML unavailable).
  /// Throws [ApiException] on failure.
  Future<HealthScore?> saveRecord(HealthRecord record) async {
    try {
      final body = <String, dynamic>{
        'recorded_at': _recordedAt(record.date),
      };
      if (record.bloodSugar != null) body['blood_sugar'] = record.bloodSugar;
      if (record.systolic != null) body['systolic'] = record.systolic;
      if (record.diastolic != null) body['diastolic'] = record.diastolic;
      if (record.weight != null) body['weight'] = record.weight;
      if (record.medicineTaken) body['medicine_taken'] = true;
      if (record.meals.isNotEmpty) body['meals'] = record.meals.join(', ');

      final resp = await ApiClient.instance.post(
        '/api/v1/patients/records',
        data: body,
        options: Options(receiveTimeout: _kScoreTimeout),
      );

      final raw = resp.data['data'];
      if (raw is! Map) return null;
      final scoreMap = raw['score'];
      if (scoreMap is! Map) return null;
      final score = HealthScore.fromJson(Map<String, dynamic>.from(scoreMap));
      _cachedScore = score;
      return score;
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }

  /// GET /api/v1/patients/health-score
  ///
  /// Re-computes the score on demand (e.g. after submitting sleep/activity via
  /// [submitHealthLog], or from a "Hitung Ulang" button).
  /// Throws [ApiException] with statusCode 422 if no clinical baseline exists.
  Future<HealthScore> fetchHealthScore({bool forceRefresh = false}) async {
    if (_cachedScore != null && !forceRefresh) {
      return _cachedScore!;
    }
    try {
      final resp = await ApiClient.instance.get(
        '/api/v1/patients/health-score',
        options: Options(receiveTimeout: _kScoreTimeout),
      );
      final raw = resp.data['data'];
      final score = HealthScore.fromJson(
          raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw as Map));
      _cachedScore = score;
      return score;
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }

  /// POST /api/v1/patients/health-logs
  ///
  /// Sends a single lifestyle metric (sleep, activity, stress, smoking, alcohol).
  /// Each call must use a fresh [Idempotency-Key] (UUID) to prevent duplicates.
  ///
  /// Relevant [metricType] values for ML scoring:
  ///   'sleep' (hours, 0–24), 'activity' (min/day, 0–1440),
  ///   'stress' (scale 1–10), 'smoking' (0/1), 'alcohol' (0/1).
  Future<void> submitHealthLog({
    required String metricType,
    double? valueNumeric,
    String? valueText,
    required DateTime measuredAt,
  }) async {
    try {
      final body = <String, dynamic>{
        'metric_type': metricType,
        'measured_at': measuredAt.toUtc().toIso8601String(),
        if (valueNumeric != null) 'value_numeric': valueNumeric,
        if (valueText != null) 'value_text': valueText,
      };
      await ApiClient.instance.post(
        '/api/v1/patients/health-logs',
        data: body,
        options: Options(
          headers: {'Idempotency-Key': _generateUuid()},
        ),
      );
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

  /// RFC 4122 UUID v4 generated with a cryptographically secure RNG.
  static String _generateUuid() {
    final rng = Random.secure();
    final b = List<int>.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String hex(List<int> bytes) =>
        bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return '${hex(b.sublist(0, 4))}-${hex(b.sublist(4, 6))}-'
        '${hex(b.sublist(6, 8))}-${hex(b.sublist(8, 10))}-${hex(b.sublist(10))}';
  }
}
