import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/auth_models.dart';
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
    this.session,
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
    this.recordDate,
    this.onViewRecordWithDate,
  });

  /// The active session — null only in edge-cases before auth is resolved.
  final Session? session;
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
  final Future<void> Function() onLogout;
  final DateTime? recordDate;
  final void Function(DateTime)? onViewRecordWithDate;

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
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.of(context).background),
          ),
        ),
        SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (view) {
              MainView.beranda => DashboardScreen(
                onView: onView,
                onViewRecordWithDate: onViewRecordWithDate,
                fullName: session?.fullName,
              ),
              MainView.catatan => RecordScreen(
                onSaved: onAction,
                onView: onView,
                initialDate: recordDate,
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
                fullName: session?.fullName,
              ),
              MainView.dokter => DoctorScreen(
                onBack: () => onView(MainView.beranda),
                onAction: onAction,
              ),
              MainView.riwayat => HistoryScreen(
                onBack: () => onView(MainView.beranda),
                onViewRecordWithDate: onViewRecordWithDate,
              ),
              MainView.notifikasi => NotificationScreen(
                onBack: () => onView(MainView.beranda),
                onNavigate: onView,
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
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? -100 : 18,
            child: FloatingNav(view: view, onView: onView),
          ),
      ],
    );
  }
}
