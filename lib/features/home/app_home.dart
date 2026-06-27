import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/features/ai/ai_screen.dart';
import 'package:sehatiku_mobile/features/dashboard/dashboard_screen.dart';
import 'package:sehatiku_mobile/features/doctor/doctor_screen.dart';
import 'package:sehatiku_mobile/features/education/education_screen.dart';
import 'package:sehatiku_mobile/features/history/history_screen.dart';
import 'package:sehatiku_mobile/features/notification/notification_screen.dart';
import 'package:sehatiku_mobile/features/profile/profile_screen.dart';
import 'package:sehatiku_mobile/features/progress/progress_screen.dart';
import 'package:sehatiku_mobile/features/record/record_screen.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class AppHome extends StatelessWidget {
  const AppHome({
    super.key,
    required this.view,
    required this.progressIndex,
    required this.rangeIndex,
    required this.forecastIndex,
    required this.educationFilter,
    required this.darkMode,
    required this.onView,
    required this.onProgress,
    required this.onRange,
    required this.onForecast,
    required this.onEducationFilter,
    required this.onDarkMode,
    required this.onAction,
    required this.onLogout,
  });

  final MainView view;
  final int progressIndex;
  final int rangeIndex;
  final int forecastIndex;
  final int educationFilter;
  final bool darkMode;
  final ValueChanged<MainView> onView;
  final ValueChanged<int> onProgress;
  final ValueChanged<int> onRange;
  final ValueChanged<int> onForecast;
  final ValueChanged<int> onEducationFilter;
  final ValueChanged<bool> onDarkMode;
  final ValueChanged<String> onAction;
  final VoidCallback onLogout;

  bool get _showNav => {
    MainView.beranda,
    MainView.catatan,
    MainView.ai,
    MainView.progres,
    MainView.profil,
  }.contains(view);

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('app'),
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE9F3FF),
                  Color(0xFFF4F9FF),
                  Color(0xFFFBFDFF),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (view) {
              MainView.beranda => DashboardScreen(onView: onView),
              MainView.catatan => RecordScreen(
                onSaved: onAction,
                onView: onView,
              ),
              MainView.ai => AiScreen(
                forecastIndex: forecastIndex,
                onForecast: onForecast,
                onAction: onAction,
              ),
              MainView.progres => ProgressScreen(
                progressIndex: progressIndex,
                rangeIndex: rangeIndex,
                onProgress: onProgress,
                onRange: onRange,
              ),
              MainView.profil => ProfileScreen(
                darkMode: darkMode,
                onDarkMode: onDarkMode,
                onLogout: onLogout,
                onAction: onAction,
                onDoctor: () => onView(MainView.dokter),
              ),
              MainView.dokter => DoctorScreen(
                onBack: () => onView(MainView.beranda),
                onAction: onAction,
              ),
              MainView.riwayat => HistoryScreen(
                onBack: () => onView(MainView.beranda),
              ),
              MainView.notifikasi => NotificationScreen(
                onBack: () => onView(MainView.beranda),
              ),
              MainView.edukasi => EducationScreen(
                onBack: () => onView(MainView.beranda),
                selectedFilter: educationFilter,
                onFilter: onEducationFilter,
                onAction: onAction,
              ),
            },
          ),
        ),
        if (_showNav)
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: FloatingNav(view: view, onView: onView),
          ),
      ],
    );
  }
}
