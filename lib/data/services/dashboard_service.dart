import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:sehatiku_mobile/data/models/dashboard_models.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';

class AiSummaryResponse {
  final String narrative;
  final List<int> availableWindows;

  const AiSummaryResponse({
    required this.narrative,
    required this.availableWindows,
  });
}

/// Wraps all dashboard-related API calls for the patient actor.
class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  PatientDashboard? _cachedDashboard;
  AiSummaryResponse? _cachedAiSummary;

  PatientDashboard? get cachedDashboard => _cachedDashboard;
  AiSummaryResponse? get cachedAiSummary => _cachedAiSummary;

  void clearCache() {
    _cachedDashboard = null;
    _cachedAiSummary = null;
  }

  /// GET /api/v1/patients/dashboard
  Future<PatientDashboard> fetchDashboard() async {
    try {
      final resp = await ApiClient.instance.get('/api/v1/patients/dashboard');
      final dashboard =
          PatientDashboard.fromJson(resp.data as Map<String, dynamic>);
      _cachedDashboard = dashboard;
      return dashboard;
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }

  /// GET /api/v1/patients/summary
  ///
  /// Fetches an AI-generated explanation/summary of health logs for a given timeframe in days.
  Future<AiSummaryResponse> fetchAiSummary(int days) async {
    try {
      final resp = await ApiClient.instance.get(
        '/api/v1/patients/summary',
        queryParameters: {'window': days},
      );
      debugPrint('DEBUG: fetchAiSummary response: ${resp.data}');
      final envelope = resp.data as Map<String, dynamic>;
      final data = envelope['data'] as Map<String, dynamic>;
      
      final List<int> availableWindows = (data['available_windows'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [7]; // fallback to [7]

      final bool available = data['available'] as bool? ?? false;
      if (!available) {
        final summary = AiSummaryResponse(
          narrative: 'Penjelasan AI belum tersedia untuk periode $days hari terakhir. Silakan catat data kesehatan Anda secara rutin.',
          availableWindows: availableWindows,
        );
        _cachedAiSummary = summary;
        return summary;
      }
      
      final summary = AiSummaryResponse(
        narrative: data['narrative'] as String? ?? 'Penjelasan AI tidak tersedia.',
        availableWindows: availableWindows,
      );
      _cachedAiSummary = summary;
      return summary;
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }
}
