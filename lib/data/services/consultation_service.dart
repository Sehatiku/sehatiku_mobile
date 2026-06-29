import 'package:dio/dio.dart';
import 'package:sehatiku_mobile/data/models/assigned_nakes_info.dart';
import 'package:sehatiku_mobile/data/models/consultation.dart';
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
  Future<void> sendConsultation({
    required String complaintSince,
    required String complaintType,
    required String complaintDetail,
  }) async {
    try {
      await ApiClient.instance.post(
        '/api/v1/patients/consultations',
        data: {
          'complaint_since': complaintSince,
          'complaint_type': complaintType,
          'complaint_detail': complaintDetail,
        },
      );
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }

  /// GET /api/v1/patients/consultations
  ///
  /// Throws [ApiException] on failure.
  Future<List<Consultation>> fetchConsultationHistory() async {
    try {
      final resp = await ApiClient.instance.get('/api/v1/patients/consultations');
      final rawList = resp.data['data'] as List;
      return rawList
          .map((json) => Consultation.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }
}

