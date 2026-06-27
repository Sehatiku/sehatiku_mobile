import 'package:dio/dio.dart';

import 'package:sehatiku_mobile/data/models/dashboard_models.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';

/// Wraps all dashboard-related API calls for the patient actor.
class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  /// GET /api/v1/patients/dashboard
  ///
  /// Requires a valid patient Bearer JWT (attached automatically by
  /// [AuthInterceptor]).  Throws [ApiException] on any API error.
  Future<PatientDashboard> fetchDashboard() async {
    try {
      final resp = await ApiClient.instance.get(
        '/api/v1/patients/dashboard',
      );
      return PatientDashboard.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }
}
