import 'package:dio/dio.dart';
import 'package:sehatiku_mobile/data/models/assigned_nakes_info.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';

/// Service for patient actor to load assigned nakes info and send consultations.
class ConsultationService {
  ConsultationService._();
  static final ConsultationService instance = ConsultationService._();

  /// GET /api/v1/patients/assigned-nakes
  ///
  /// Throws [ApiException] on failure.
  Future<AssignedNakesInfo> fetchAssignedNakes() async {
    try {
      final resp = await ApiClient.instance.get('/api/v1/patients/assigned-nakes');
      final data = resp.data['data'] as Map<String, dynamic>;
      return AssignedNakesInfo.fromJson(data);
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }

  /// POST /api/v1/patients/consultations
  ///
  /// Throws [ApiException] on failure.
  Future<void> sendConsultation(String complaint) async {
    try {
      await ApiClient.instance.post(
        '/api/v1/patients/consultations',
        data: {'complaint': complaint},
      );
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }
}
