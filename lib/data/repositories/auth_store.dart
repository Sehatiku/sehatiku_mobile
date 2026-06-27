import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sehatiku_mobile/data/models/auth_models.dart';

/// Persists the active [Session] to SharedPreferences and exposes it
/// as a [ChangeNotifier].
///
/// Use [AuthScope.of] in the widget tree, or [AuthStore.instance] outside of
/// widgets (e.g. inside [AuthInterceptor]).
class AuthStore extends ChangeNotifier {
  AuthStore._();

  static final AuthStore _instance = AuthStore._();
  static AuthStore get instance => _instance;

  static const _key = 'sehatiku_session_v1';

  Session? _session;

  /// The current active session, or null when logged out.
  Session? get session => _session;

  bool get isLoggedIn => _session != null;

  /// Call once at app start before the first frame is drawn.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        _session = Session.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        // Corrupt data — treat as logged out.
        _session = null;
      }
    }
    notifyListeners();
  }

  /// Save a session after a successful login.
  Future<void> save(Session session) async {
    _session = session;
    notifyListeners();
    await _persist();
  }

  /// Update tokens after a silent refresh.
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (_session == null) return;
    _session = _session!.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    // Don't notifyListeners — this is a background operation; no UI needs to
    // rebuild just because the token rotated.
    await _persist();
  }

  /// Delete the session (logout / revoked token).
  Future<void> clear() async {
    _session = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _persist() async {
    if (_session == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_session!.toJson()));
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Exposes [AuthStore] to the widget subtree. Rebuilds dependents on changes.
class AuthScope extends InheritedNotifier<AuthStore> {
  // Not const because notifier is a singleton (not a compile-time constant).
  AuthScope({
    super.key,
    required super.child,
  }) : super(notifier: AuthStore.instance);

  static AuthStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in widget tree');
    return scope!.notifier!;
  }

  // ignore: unused_element
  static AuthStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
}
