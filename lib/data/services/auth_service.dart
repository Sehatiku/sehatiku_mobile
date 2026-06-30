import 'package:dio/dio.dart';

import 'package:sehatiku_mobile/data/models/auth_models.dart';
import 'package:sehatiku_mobile/data/repositories/auth_store.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';
import 'package:sehatiku_mobile/data/services/record_service.dart';

/// Wraps all auth-related API calls for both patient and nakes actors.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Patient login ──────────────────────────────────────────────────────────

  /// POST /api/v1/patients/auth/login
  ///
  /// On success, persists the session to [AuthStore] and returns it.
  /// Throws [ApiException] on any API error.
  Future<Session> loginPatient({
    required String username,
    required String password,
  }) async {
    try {
      final resp = await ApiClient.instance.post(
        '/api/v1/patients/auth/login',
        data: {'username': username, 'password': password},
      );
      final parsed = PatientLoginResponse.fromJson(
        resp.data as Map<String, dynamic>,
      );
      final session = Session(
        actorType: ActorType.patient,
        actorId: parsed.patientId,
        faksesId: parsed.faksesId,
        fullName: parsed.fullName,
        accessToken: parsed.token.accessToken,
        refreshToken: parsed.token.refreshToken,
      );
      await AuthStore.instance.save(session);
      return session;
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }

  // ── Nakes login ────────────────────────────────────────────────────────────

  /// POST /api/v1/nakes/auth/login
  ///
  /// On success, persists the session to [AuthStore] and returns it.
  /// Throws [ApiException] on any API error.
  Future<Session> loginNakes({
    required String username,
    required String password,
  }) async {
    try {
      final resp = await ApiClient.instance.post(
        '/api/v1/nakes/auth/login',
        data: {'username': username, 'password': password},
      );
      final parsed = NakesLoginResponse.fromJson(
        resp.data as Map<String, dynamic>,
      );
      final session = Session(
        actorType: ActorType.nakes,
        actorId: parsed.nakesId,
        faksesId: parsed.faksesId,
        fullName: parsed.fullName,
        accessToken: parsed.token.accessToken,
        refreshToken: parsed.token.refreshToken,
        role: parsed.role,
      );
      await AuthStore.instance.save(session);
      return session;
    } on DioException catch (e) {
      throw apiExceptionFrom(e);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  /// POST /api/v1/auth/logout
  ///
  /// Revokes the refresh token on the server, then clears the local session.
  /// If the server call fails, the local session is still cleared so the user
  /// is always logged out from the client's perspective.
  Future<void> logout() async {
    final refreshToken = AuthStore.instance.session?.refreshToken;
    if (refreshToken != null) {
      try {
        await ApiClient.instance.post(
          '/api/v1/auth/logout',
          data: {'refresh_token': refreshToken},
        );
      } catch (_) {
        // Fire-and-forget: server error does not block local logout.
      }
    }
    RecordService.instance.clearCache();
    await AuthStore.instance.clear();
  }
}
