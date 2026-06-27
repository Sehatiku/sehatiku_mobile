import 'package:dio/dio.dart';

import 'package:sehatiku_mobile/data/repositories/auth_store.dart';

/// Base URL for the Sehatiku backend.
const String _kBaseUrl = 'https://sehatikubackend-production.up.railway.app';

/// Global Dio instance.  Call [ApiClient.instance] anywhere in the app.
///
/// The [AuthInterceptor] automatically:
///   1. Attaches the Bearer access token to every request that needs it.
///   2. On 401, attempts a single silent token refresh and retries the
///      original request.
///   3. On refresh failure, clears the session and lets the caller handle it
///      (typically by navigating to login).
class ApiClient {
  ApiClient._();

  static Dio? _dio;

  static Dio get instance {
    _dio ??= _build();
    return _dio!;
  }

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _kBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(AuthInterceptor(dio));
    return dio;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Attaches `Authorization: Bearer <token>` and silently refreshes on 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;

  /// Endpoints that must NOT receive a token (avoid infinite refresh loops).
  static const _publicPaths = {
    '/api/v1/patients/auth/login',
    '/api/v1/nakes/auth/login',
    '/api/v1/faskes/auth/login',
    '/api/v1/faskes/auth/register',
    '/api/v1/auth/refresh',
  };

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final path = options.path;
    final isPublic = _publicPaths.any((p) => path.contains(p));

    if (!isPublic) {
      final token = AuthStore.instance.session?.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final requestPath = err.requestOptions.path;

    // Only intercept 401s from non-auth endpoints.
    if (statusCode == 401 &&
        !_publicPaths.any((p) => requestPath.contains(p))) {
      final store = AuthStore.instance;
      final refreshToken = store.session?.refreshToken;

      if (refreshToken != null) {
        try {
          // Attempt silent token refresh.
          final refreshDio = Dio(
            BaseOptions(baseUrl: _kBaseUrl),
          );
          final refreshResponse = await refreshDio.post(
            '/api/v1/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          final data = refreshResponse.data['data'] as Map<String, dynamic>;
          final newAccessToken = data['access_token'] as String;
          final newRefreshToken = data['refresh_token'] as String;

          // Persist the new tokens.
          await store.updateTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // Retry the original request with the new token.
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.fetch(opts);
          handler.resolve(retryResponse);
          return;
        } catch (_) {
          // Refresh itself failed — clear session so the app redirects to login.
          await store.clear();
        }
      }
    }

    handler.next(err);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Convenience wrapper around Dio that surfaces clean error messages.
///
/// Throws an [ApiException] on any non-2xx response.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Extracts a readable error message from a Dio exception.
ApiException apiExceptionFrom(DioException e) {
  final code = e.response?.statusCode ?? 0;
  String msg;
  try {
    final body = e.response?.data;
    if (body is Map) {
      msg = (body['message'] ?? body['error'] ?? 'Terjadi kesalahan')
          .toString();
    } else {
      msg = e.message ?? 'Terjadi kesalahan';
    }
  } catch (_) {
    msg = e.message ?? 'Terjadi kesalahan';
  }
  return ApiException(statusCode: code, message: msg);
}
