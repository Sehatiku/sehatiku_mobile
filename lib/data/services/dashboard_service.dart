import 'package:dio/dio.dart';

import 'package:sehatiku_mobile/data/models/dashboard_models.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';

/// Wraps all dashboard-related API calls for the patient actor.
class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  PatientDashboard? _cachedDashboard;

  PatientDashboard? get cachedDashboard => _cachedDashboard;

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
}
