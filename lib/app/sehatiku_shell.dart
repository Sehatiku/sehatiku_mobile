import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/auth_models.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
import 'package:sehatiku_mobile/data/services/auth_service.dart';
import 'package:sehatiku_mobile/features/auth/login_screen.dart';
import 'package:sehatiku_mobile/features/home/app_home.dart';
import 'package:sehatiku_mobile/features/onboarding/onboarding_screen.dart';
import 'package:sehatiku_mobile/features/splash/splash_screen.dart';

class SehatikuShell extends StatefulWidget {
  const SehatikuShell({
    super.key,
    required this.darkMode,
    required this.onDarkMode,
    /// Pass a non-null session when restoring a persisted login on cold start.
    this.initialSession,
  });

  final bool darkMode;
  final ValueChanged<bool> onDarkMode;
  final Session? initialSession;

  @override
  State<SehatikuShell> createState() => _SehatikuShellState();
}

class _SehatikuShellState extends State<SehatikuShell> {
  Timer? _splashTimer;

  late Stage _stage;
  Session? _session;

  MainView _view = MainView.beranda;
  int _onboardingIndex = 0;
  int _progressIndex = 0;
  int _rangeIndex = 0;
  int _forecastIndex = 0;
  int _educationFilter = 0;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;

    _splashTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted && _stage == Stage.splash) {
        setState(() {
          if (_session != null) {
            // Already logged in — skip onboarding and go straight to app.
            _stage = Stage.app;
          } else {
            _stage = Stage.onboarding;
          }
        });
      }
    });

    // Initialise stage — splash always shows first.
    _stage = Stage.splash;
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  void _onLogin(Session session) {
    FocusScope.of(context).unfocus();
    // Guard: app mobile ini hanya untuk pasien.
    // Akun nakes/dokter harus menggunakan aplikasi lain.
    if (session.actorType != ActorType.patient) {
      _showSnack('Akun ini bukan akun pasien. Gunakan aplikasi Sehatiku untuk tenaga kesehatan.');
      AuthService.instance.logout();
      return;
    }
    setState(() {
      _session = session;
      _stage = Stage.app;
      _view = MainView.beranda;
    });
  }

  Future<void> _onLogout() async {
    await HealthScope.of(context).clear();
    await AuthService.instance.logout();
    if (!mounted) return;
    setState(() {
      _session = null;
      _stage = Stage.login;
      _view = MainView.beranda;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        child: switch (_stage) {
          Stage.splash => SplashScreen(
            onContinue: () => setState(() => _stage = Stage.onboarding),
          ),
          Stage.onboarding => OnboardingScreen(
            index: _onboardingIndex,
            onDot: (value) => setState(() => _onboardingIndex = value),
            onSkip: () => setState(() => _stage = Stage.login),
            onNext: () {
              if (_onboardingIndex < 2) {
                setState(() => _onboardingIndex += 1);
              } else {
                setState(() => _stage = Stage.login);
              }
            },
          ),
          Stage.login => LoginScreen(onLogin: _onLogin),
          Stage.app => AppHome(
            session: _session,
            view: _view,
            progressIndex: _progressIndex,
            rangeIndex: _rangeIndex,
            forecastIndex: _forecastIndex,
            educationFilter: _educationFilter,
            darkMode: widget.darkMode,
            onView: (view) => setState(() => _view = view),
            onProgress: (value) => setState(() => _progressIndex = value),
            onRange: (value) => setState(() => _rangeIndex = value),
            onForecast: (value) => setState(() => _forecastIndex = value),
            onEducationFilter: (value) =>
                setState(() => _educationFilter = value),
            onDarkMode: widget.onDarkMode,
            onAction: _showSnack,
            onLogout: _onLogout,
          ),
        },
      ),
    );
  }
}
