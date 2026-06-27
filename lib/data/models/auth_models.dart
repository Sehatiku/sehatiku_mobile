/// Typed response models for the Sehatiku auth API endpoints.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Token bundle  (shared across all actor login responses)
// ─────────────────────────────────────────────────────────────────────────────

class TokenBundle {
  const TokenBundle({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;

  /// Seconds until the access token expires (typically 900 = 15 min).
  final int expiresIn;

  factory TokenBundle.fromJson(Map<String, dynamic> json) => TokenBundle(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        expiresIn: json['expires_in'] as int,
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient login  —  POST /api/v1/patients/auth/login
// ─────────────────────────────────────────────────────────────────────────────

class PatientLoginResponse {
  const PatientLoginResponse({
    required this.token,
    required this.patientId,
    required this.faksesId,
    required this.fullName,
  });

  final TokenBundle token;
  final String patientId;
  final String faksesId;
  final String fullName;

  factory PatientLoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PatientLoginResponse(
      token: TokenBundle.fromJson(data['token'] as Map<String, dynamic>),
      patientId: data['patient_id'] as String,
      faksesId: data['faskes_id'] as String,
      fullName: data['full_name'] as String,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nakes login  —  POST /api/v1/nakes/auth/login
// ─────────────────────────────────────────────────────────────────────────────

class NakesLoginResponse {
  const NakesLoginResponse({
    required this.token,
    required this.nakesId,
    required this.faksesId,
    required this.fullName,
    required this.role,
  });

  final TokenBundle token;
  final String nakesId;
  final String faksesId;
  final String fullName;

  /// 'dokter' | 'kader' | 'admin'
  final String role;

  factory NakesLoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return NakesLoginResponse(
      token: TokenBundle.fromJson(data['token'] as Map<String, dynamic>),
      nakesId: data['nakes_id'] as String,
      faksesId: data['faskes_id'] as String,
      fullName: data['full_name'] as String,
      role: data['role'] as String,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Token refresh  —  POST /api/v1/auth/refresh
// ─────────────────────────────────────────────────────────────────────────────

class RefreshResponse {
  const RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory RefreshResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return RefreshResponse(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      expiresIn: data['expires_in'] as int,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Persisted session  (what AuthStore stores in SharedPreferences)
// ─────────────────────────────────────────────────────────────────────────────

/// Which actor type owns this session.
enum ActorType { patient, nakes }

class Session {
  const Session({
    required this.actorType,
    required this.actorId,
    required this.faksesId,
    required this.fullName,
    required this.accessToken,
    required this.refreshToken,
    this.role,
  });

  final ActorType actorType;
  final String actorId;
  final String faksesId;
  final String fullName;
  final String accessToken;
  final String refreshToken;

  /// Only set for nakes sessions ('dokter' | 'kader' | 'admin').
  final String? role;

  Session copyWith({
    String? accessToken,
    String? refreshToken,
  }) =>
      Session(
        actorType: actorType,
        actorId: actorId,
        faksesId: faksesId,
        fullName: fullName,
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        role: role,
      );

  Map<String, dynamic> toJson() => {
        'actor_type': actorType.name,
        'actor_id': actorId,
        'faskes_id': faksesId,
        'full_name': fullName,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        if (role != null) 'role': role,
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        actorType: ActorType.values.firstWhere(
          (e) => e.name == json['actor_type'],
          orElse: () => ActorType.patient,
        ),
        actorId: json['actor_id'] as String,
        faksesId: json['faskes_id'] as String,
        fullName: json['full_name'] as String,
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        role: json['role'] as String?,
      );
}
