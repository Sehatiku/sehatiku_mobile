import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/dashboard_models.dart';
import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/data/models/today_status.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
import 'package:sehatiku_mobile/data/services/dashboard_service.dart';
import 'package:sehatiku_mobile/data/services/record_service.dart';
import 'package:sehatiku_mobile/data/services/notification_service.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen widget
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onView,
    this.onViewRecordWithDate,
    this.fullName,
  });

  final ValueChanged<MainView> onView;
  final void Function(DateTime)? onViewRecordWithDate;
  final String? fullName;

  static bool hasShownMissingLogsThisSession = false;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PatientDashboard? _dashboard;
  bool _loading = true;
  String? _error;
  PatientTodayStatus? _todayStatus;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _dashboard = DashboardService.instance.cachedDashboard;
    _loading = _dashboard == null;
    _fetch();
  }

  Future<void> _fetch() async {
    if (_dashboard == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }
    try {
      final data = await DashboardService.instance.fetchDashboard();
      if (mounted) setState(() => _dashboard = data);

      // Fetch unread notification count
      try {
        final count = await NotificationService.instance.fetchUnreadCount();
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }
      } catch (unreadError) {
        debugPrint('Failed to fetch unread notifications count: $unreadError');
      }

      // Silent fetch of today-status to check for missing logs since yesterday
      try {
        final status = await RecordService.instance.fetchTodayStatus();
        if (mounted) {
          setState(() {
            _todayStatus = status;
          });
        }
        if (mounted && !DashboardScreen.hasShownMissingLogsThisSession) {
          DashboardScreen.hasShownMissingLogsThisSession = true;
          final days = status.daysSinceLastLog;
          if (days == null || days >= 2) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showMissingLogsDialog(status);
            });
          }
        }
      } catch (statusError) {
        debugPrint('Failed to fetch today-status: $statusError');
      }

      // Sync recent records for dashboard charts
      try {
        final entries = await RecordService.instance.fetchHistory(limit: 7);
        if (mounted) await HealthScope.of(context).mergeHistory(entries);
      } catch (_) {}
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMissingLogsDialog(PatientTodayStatus status) {
    final colors = AppColors.of(context);
    final DateTime targetDate;
    String dateMsg = '';

    if (status.daysSinceLastLog == null) {
      targetDate = HealthRecord.dayOf(DateTime.now());
      dateMsg = 'Anda belum pernah mengisi catatan harian Anda. Yuk, mulai isi sekarang!';
    } else {
      final lastLogDate = DateTime.tryParse(status.lastLoggedAt ?? '');
      if (lastLogDate != null) {
        final firstMissed = HealthRecord.dayOf(lastLogDate).add(const Duration(days: 1));
        targetDate = firstMissed;
        
        final todayNormalized = HealthRecord.dayOf(DateTime.now());
        final missedDaysCount = todayNormalized.difference(firstMissed).inDays;
        if (missedDaysCount <= 1) {
          dateMsg = 'Anda belum mengisi catatan harian untuk tanggal ${formatLongDate(firstMissed)}. Harap lengkapi catatan harian Anda.';
        } else {
          dateMsg = 'Anda belum mengisi catatan harian sejak tanggal ${formatLongDate(firstMissed)}. Harap lengkapi catatan harian Anda.';
        }
      } else {
        targetDate = HealthRecord.dayOf(DateTime.now().subtract(const Duration(days: 1)));
        dateMsg = 'Anda belum mengisi catatan harian untuk kemarin. Harap lengkapi catatan harian Anda.';
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: .15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.amber,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Catatan Terlewat!',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  dateMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.muted,
                          side: BorderSide(color: colors.line),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Nanti Saja',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primary2],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            if (widget.onViewRecordWithDate != null) {
                              widget.onViewRecordWithDate!(targetDate);
                            } else {
                              widget.onView(MainView.catatan);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Isi Sekarang',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = HealthScope.of(context);
    final colors = AppColors.of(context);
    final now = DateTime.now();

    final displayName =
        _dashboard?.profile.fullName ?? widget.fullName ?? 'Pengguna';
    final firstName = displayName.split(' ').first;

    final latest = store.latest;
    final today = store.today;
    final recentRecords = store.recent(7);
    final bsRecords = recentRecords.where((r) => r.bloodSugar != null).toList();
    final bsValues = bsRecords.map((r) => r.bloodSugar!.toDouble()).toList();
    final bsTrend = trendInfo(bsValues, lowerIsBetter: true);
    final bpRecords = recentRecords.where((r) => r.systolic != null).toList();
    final bpValues = bpRecords.map((r) => r.systolic!.toDouble()).toList();
    final bpTrend = trendInfo(bpValues, lowerIsBetter: true);
    final diseaseType = _dashboard?.profile.diseaseType;
    final showBS = diseaseType != 'hypertension';
    final showBP = diseaseType == 'hypertension' || diseaseType == 'both';

    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _Header(
            firstName: firstName,
            date: now,
            colors: colors,
            unreadCount: _unreadCount,
            onNotification: () => widget.onView(MainView.notifikasi),
          ),
          const SizedBox(height: 22),

          if (store.hasPendingSync) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: .3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sync_problem_rounded,
                    color: AppColors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Beberapa catatan belum tersinkronisasi ke server.',
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_todayStatus != null && (_todayStatus!.daysSinceLastLog == null || _todayStatus!.daysSinceLastLog! >= 2)) ...[
            _MissedLogsBanner(
              status: _todayStatus!,
              colors: colors,
              onTap: () {
                final DateTime targetDate;
                if (_todayStatus!.daysSinceLastLog == null) {
                  targetDate = HealthRecord.dayOf(DateTime.now());
                } else {
                  final lastLogDate = DateTime.tryParse(_todayStatus!.lastLoggedAt ?? '');
                  if (lastLogDate != null) {
                    targetDate = HealthRecord.dayOf(lastLogDate).add(const Duration(days: 1));
                  } else {
                    targetDate = HealthRecord.dayOf(DateTime.now().subtract(const Duration(days: 1)));
                  }
                }
                if (widget.onViewRecordWithDate != null) {
                  widget.onViewRecordWithDate!(targetDate);
                } else {
                  widget.onView(MainView.catatan);
                }
              },
            ),
            const SizedBox(height: 16),
          ],

          // ── AI Risk Card (from API) or local score card ──────────────────────
          // Only show _ApiRiskCard when the ML model has actually produced a
          // score (scoredAt != null). When scoredAt is null the backend returns
          // score=0 and risk_label="" which would crash on riskLabel[0].
          if (_loading)
            const _LoadingCard()
          else if (_dashboard != null && _dashboard!.risk.scoredAt != null)
            InkWell(
              onTap: () => widget.onView(MainView.ai),
              borderRadius: BorderRadius.circular(28),
              child: _ApiRiskCard(dashboard: _dashboard!),
            )
          else
            InkWell(
              onTap: () => widget.onView(MainView.ai),
              borderRadius: BorderRadius.circular(28),
              child: HealthScoreCard(record: latest),
            ),
          const SizedBox(height: 20),

          // ── Aksi Cepat (Quick Actions) ───────────────────────────────────────
          _QuickActionsRow(onView: widget.onView),
          const SizedBox(height: 24),

          // ── Latest measurements (from API) ──────────────────────────────────
          if (_dashboard != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                    child: SectionTitle(title: 'Pengukuran Terakhir')),
                if (_error != null)
                  GestureDetector(
                    onTap: _fetch,
                    child: const Text('Muat ulang',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 13),
            _MeasurementGrid(
              dashboard: _dashboard!,
              latest: latest,
              onView: widget.onView,
            ),
            const SizedBox(height: 8),
          ] else if (!_loading) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                    child: SectionTitle(title: 'Ringkasan Terakhir')),
                const SizedBox(width: 8),
                Text(
                  latest != null
                      ? formatShortDate(latest.date)
                      : 'Belum ada data',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            if (latest == null)
              _EmptyDataCard(onView: widget.onView)
            else
              _LocalSummaryGrid(record: latest),
          ],

          if (today == null && _dashboard == null && !_loading) ...[
            const SizedBox(height: 14),
            _TodayPromptCard(onView: widget.onView),
          ],

          // ── Daily Checklist ──────────────────────────────────────────────────
          if (!_loading) ...[
            const SizedBox(height: 24),
            const SectionTitle(title: 'Cek Harian'),
            const SizedBox(height: 13),
            _DailyChecklistCard(
              dashboard: _dashboard,
              today: today,
              onView: widget.onView,
            ),
          ],

          // ── Streak & logging (from API) ──────────────────────────────────────
          if (_dashboard != null) ...[
            const SizedBox(height: 14),
            _StreakCard(
              logging: _dashboard!.logging,
              loggedTodayOverride: _todayStatus?.loggedToday,
            ),
          ],
          const SizedBox(height: 28),

          // ── Motivasi Hari Ini ────────────────────────────────────────────────
          const SectionTitle(title: 'Motivasi Hari Ini'),
          const SizedBox(height: 13),
          const _MotivationCard(),
          const SizedBox(height: 24),

          // ── Education teaser ─────────────────────────────────────────────────
          _EducationTeaser(onView: widget.onView),
          const SizedBox(height: 26),

          // ── AI insight banner ────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => widget.onView(MainView.ai),
            child: GradientPanel(
              radius: 26,
              colors: const [
                AppColors.violet,
                Color(0xFF9B7BFF),
                AppColors.cyan
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 7),
                        Text('Insight AI Hari Ini',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _dashboard != null && _dashboard!.recommendations.isNotEmpty
                        ? '"${_dashboard!.recommendations.first}"'
                        : '"Kondisi Anda stabil. Pertahankan pola makan rendah garam hari ini."',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Text('Lihat detail',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 17),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Health trend charts ──────────────────────────────────────────────
          if (showBS)
            _MetricChartCard(
              label: 'Gula Darah',
              values: bsValues,
              records: bsRecords,
              trend: bsTrend,
              color: AppColors.primary,
            ),
          if (showBS && showBP) const SizedBox(height: 12),
          if (showBP)
            _MetricChartCard(
              label: 'Tekanan Darah (Sistolik)',
              values: bpValues,
              records: bpRecords,
              trend: bpTrend,
              color: AppColors.pink,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New: Compact Quick Actions Row
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.onView});

  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SmallActionItem(
            icon: Icons.edit_note_rounded,
            label: 'Catat',
            gradient: const [AppColors.primary, AppColors.cyan],
            onTap: () => onView(MainView.catatan),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SmallActionItem(
            icon: Icons.history_rounded,
            label: 'Riwayat',
            gradient: const [AppColors.green, AppColors.lime],
            onTap: () => onView(MainView.riwayat),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SmallActionItem(
            icon: Icons.menu_book_rounded,
            label: 'Edukasi',
            gradient: const [AppColors.violet, AppColors.cyan],
            onTap: () => onView(MainView.edukasi),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SmallActionItem(
            icon: Icons.medical_services_rounded,
            label: 'Dokter',
            gradient: const [AppColors.pink, Color(0xFFFF9472)],
            onTap: () => onView(MainView.dokter),
          ),
        ),
      ],
    );
  }
}

class _SmallActionItem extends StatelessWidget {
  const _SmallActionItem({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: .22),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New: Header widget
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.firstName,
    required this.date,
    required this.colors,
    required this.unreadCount,
    required this.onNotification,
  });

  final String firstName;
  final DateTime date;
  final AppColors colors;
  final int unreadCount;
  final VoidCallback onNotification;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo3.png',
          width: 52,
          height: 52,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hallo $firstName 👋',
                style: TextStyle(
                    color: colors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                formatLongDate(date),
                style: TextStyle(
                    color: colors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconCircle(
              icon: Icons.notifications_rounded,
              onTap: onNotification,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 10,
                right: 11,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.background, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New: Daily Checklist Card
// ─────────────────────────────────────────────────────────────────────────────

class _DailyChecklistCard extends StatelessWidget {
  const _DailyChecklistCard({
    required this.dashboard,
    required this.today,
    required this.onView,
  });

  final PatientDashboard? dashboard;
  final HealthRecord? today;
  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final bool medicineDone = today?.medicineTaken ?? false;
    final bool glucoseDone =
        _isMeasuredToday(dashboard?.latestMeasurements.glucose?.measuredAt) ||
        today?.bloodSugar != null;
    final bool bpDone =
        _isMeasuredToday(dashboard?.latestMeasurements.bloodPressure?.measuredAt) ||
        (today?.systolic != null && today!.systolic! > 0);

    final doneCount =
        [medicineDone, glucoseDone, bpDone].where((b) => b).length;
    final allDone = doneCount == 3;
    final progressColor = allDone ? AppColors.green : AppColors.primary;

    return AppCard(
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      allDone
                          ? Icons.task_alt_rounded
                          : Icons.checklist_rounded,
                      color: progressColor,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    allDone ? 'Semua Selesai!' : 'Cek Harian',
                    style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: allDone
                      ? AppColors.green.withValues(alpha: .15)
                      : AppColors.amber.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$doneCount / 3',
                  style: TextStyle(
                    color: allDone ? AppColors.green : AppColors.amber,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: doneCount / 3,
              minHeight: 6,
              backgroundColor: colors.line,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 16),
          // Checklist items
          _ChecklistItem(
            icon: Icons.medication_rounded,
            label: 'Minum Obat',
            done: medicineDone,
            doneLabel: 'Sudah diminum hari ini',
            pendingLabel: 'Belum diminum',
            color: AppColors.violet,
          ),
          const SizedBox(height: 10),
          _ChecklistItem(
            icon: Icons.water_drop_rounded,
            label: 'Catat Gula Darah',
            done: glucoseDone,
            doneLabel: dashboard?.latestMeasurements.glucose != null
                ? '${dashboard!.latestMeasurements.glucose!.value} mg/dL'
                : 'Tercatat',
            pendingLabel: 'Belum tercatat',
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _ChecklistItem(
            icon: Icons.favorite_rounded,
            label: 'Tekanan Darah',
            done: bpDone,
            doneLabel: dashboard?.latestMeasurements.bloodPressure != null
                ? '${dashboard!.latestMeasurements.bloodPressure!.systolic}/'
                    '${dashboard!.latestMeasurements.bloodPressure!.diastolic} mmHg'
                : 'Tercatat',
            pendingLabel: 'Belum tercatat',
            color: AppColors.pink,
          ),
          if (!allDone) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => onView(MainView.catatan),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Lengkapi Sekarang',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.icon,
    required this.label,
    required this.done,
    required this.doneLabel,
    required this.pendingLabel,
    required this.color,
  });

  final IconData icon;
  final String label;
  final bool done;
  final String doneLabel;
  final String pendingLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: done ? color.withValues(alpha: .13) : colors.elevated,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: done ? color : colors.muted, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5)),
              const SizedBox(height: 1),
              Text(
                done ? doneLabel : pendingLabel,
                style: TextStyle(
                  color: done ? color : colors.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Icon(
          done
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: done ? color : colors.muted,
          size: 22,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New: Education Teaser
// ─────────────────────────────────────────────────────────────────────────────

class _EducationTeaser extends StatelessWidget {
  const _EducationTeaser({required this.onView});

  final ValueChanged<MainView> onView;

  static const _topics = [
    _EduTopic(
      icon: Icons.restaurant_rounded,
      color: AppColors.green,
      category: 'Nutrisi',
      title: 'Pola Makan Sehat untuk Penderita Diabetes',
      imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=500&auto=format&fit=crop&q=80',
    ),
    _EduTopic(
      icon: Icons.favorite_rounded,
      color: AppColors.pink,
      category: 'Tekanan Darah',
      title: 'Cara Cek & Kontrol Tekanan Darah di Rumah',
      imageUrl: 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=500&auto=format&fit=crop&q=80',
    ),
    _EduTopic(
      icon: Icons.medication_rounded,
      color: AppColors.violet,
      category: 'Obat-obatan',
      title: 'Pentingnya Minum Obat Setiap Hari',
      imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&auto=format&fit=crop&q=80',
    ),
    _EduTopic(
      icon: Icons.directions_run_rounded,
      color: AppColors.amber,
      category: 'Aktivitas',
      title: 'Olahraga Ringan yang Aman untuk Lansia',
      imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500&auto=format&fit=crop&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: SectionTitle(title: 'Tips Kesehatan')),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onView(MainView.edukasi),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _topics.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _EduCard(
              topic: _topics[i],
              onTap: () => onView(MainView.edukasi),
            ),
          ),
        ),
      ],
    );
  }
}

class _EduTopic {
  const _EduTopic({
    required this.icon,
    required this.color,
    required this.category,
    required this.title,
    required this.imageUrl,
  });

  final IconData icon;
  final Color color;
  final String category;
  final String title;
  final String imageUrl;
}

class _EduCard extends StatelessWidget {
  const _EduCard({required this.topic, required this.onTap});

  final _EduTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 164,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.line),
          boxShadow: const [
            BoxShadow(
                color: Color(0x18000000),
                blurRadius: 20,
                offset: Offset(0, 8),
                spreadRadius: -4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              child: Image.network(
                topic.imageUrl,
                height: 82,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 82,
                  color: topic.color.withValues(alpha: .12),
                  child: Center(
                    child: Icon(topic.icon, color: topic.color, size: 24),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.category,
                      style: TextStyle(
                          color: topic.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        topic.title,
                        style: TextStyle(
                            color: colors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                            height: 1.3),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// API-driven widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Risk card populated from the backend AI score.
class _ApiRiskCard extends StatelessWidget {
  const _ApiRiskCard({required this.dashboard});

  final PatientDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final risk = dashboard.risk;
    final score = risk.score;

    final Color accentColor = switch (risk.status) {
      'bahaya' => AppColors.red,
      'waswas' => AppColors.amber,
      _ => AppColors.green,
    };

    final String statusEmoji = switch (risk.status) {
      'bahaya' => '⚠️',
      'waswas' => '⚡',
      _ => '✅',
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor,
            Color.lerp(accentColor, AppColors.primary, 0.55)!,
            AppColors.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: .40),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        children: [
          ScoreRing(
            progress: score / 100,
            color: Colors.white,
            size: 124,
            stroke: 14,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1),
                ),
                const Text('dari 100',
                    style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Health Score AI',
                    style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(statusEmoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 7),
                        Text(
                          risk.status == 'bahaya'
                              ? 'Bahaya'
                              : (risk.status == 'waswas' ? 'Waswas' : 'Aman'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (risk.mainFactor.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Faktor utama: ${risk.mainFactor}',
                      style: const TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 12.5,
                          height: 1.4)),
                ],
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text('Skor AI — bukan diagnosis',
                            style: TextStyle(
                                color: Color(0xF2FFFFFF),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid showing glucose + blood pressure from the API response.
class _MeasurementGrid extends StatelessWidget {
  const _MeasurementGrid({
    required this.dashboard,
    required this.latest,
    required this.onView,
  });

  final PatientDashboard dashboard;
  final HealthRecord? latest;
  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final m = dashboard.latestMeasurements;
    final glucose = m.glucose?.value ?? latest?.bloodSugar;
    final systolic = m.bloodPressure?.systolic ?? latest?.systolic;
    final diastolic = m.bloodPressure?.diastolic ?? latest?.diastolic;
    final hasGlucose = glucose != null;
    final hasBP = systolic != null && diastolic != null;

    if (!hasGlucose && !hasBP) {
      return AppCard(
        padding: 18,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.sensors_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Belum ada data pengukuran',
                      style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(
                    'Kirim data via WhatsApp atau gunakan tombol Catat di bawah.',
                    style: TextStyle(
                        color: colors.muted, fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 13,
      crossAxisSpacing: 13,
      childAspectRatio: 1.4,
      children: [
        SummaryCard(
          icon: Icons.water_drop_rounded,
          label: 'Gula Darah',
          value: hasGlucose ? '$glucose' : '—',
          unit: 'mg/dL',
          status: hasGlucose ? bloodSugarStatus(glucose) : 'Belum tercatat',
          statusColor: hasGlucose
              ? bloodSugarColor(glucose)
              : AppColors.of(context).muted,
          iconColor: AppColors.primary,
        ),
        SummaryCard(
          icon: Icons.favorite_rounded,
          label: 'Tekanan Darah',
          value: hasBP ? '$systolic/$diastolic' : '—',
          status: hasBP
              ? bloodPressureStatus(systolic, diastolic)
              : 'Belum tercatat',
          statusColor: hasBP
              ? bloodPressureColor(systolic, diastolic)
              : AppColors.of(context).muted,
          iconColor: AppColors.pink,
        ),
        SummaryCard(
          icon: Icons.medical_information_rounded,
          label: 'Penyakit',
          value: _diseaseLabel(dashboard.profile.diseaseType),
          status: 'Terdaftar',
          statusColor: AppColors.violet,
          iconColor: AppColors.violet,
        ),
        SummaryCard(
          icon: Icons.cake_rounded,
          label: 'Usia',
          value: '${dashboard.profile.age}',
          unit: 'tahun',
          status: 'Dari profil',
          statusColor: AppColors.of(context).muted,
          iconColor: AppColors.cyan,
        ),
      ],
    );
  }

  static String _diseaseLabel(String type) => switch (type) {
        'diabetes_t2' => 'Diabetes T2',
        'hypertension' => 'Hipertensi',
        'both' => 'DM + HT',
        _ => type,
      };
}

/// Streak & logging status card with 7-day week view.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.logging, this.loggedTodayOverride});

  final DashboardLogging logging;
  final bool? loggedTodayOverride;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final loggedToday = loggedTodayOverride ?? logging.loggedToday;
    final Color streakColor =
        logging.streakDays >= 7 ? AppColors.lime : AppColors.amber;
    final now = DateTime.now();

    return AppCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: streakColor.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.local_fire_department_rounded,
                    color: streakColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loggedToday
                          ? 'Sudah catat hari ini ✅'
                          : 'Belum catat hari ini',
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      logging.streakDays > 0
                          ? '🔥 Streak ${logging.streakDays} hari berturut-turut'
                          : 'Mulai streak hari ini!',
                      style: TextStyle(color: colors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 7-day calendar dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final daysAgo = 6 - i;
              final day = now.subtract(Duration(days: daysAgo));
              final label = _shortDay(day.weekday);
              final isFilled = loggedToday
                  ? daysAgo < logging.streakDays
                  : (daysAgo > 0 && daysAgo <= logging.streakDays);
              final isToday = daysAgo == 0;
              return _DayDot(
                label: label,
                filled: isFilled,
                isToday: isToday,
                color: streakColor,
                colors: colors,
              );
            }),
          ),
        ],
      ),
    );
  }

  static String _shortDay(int weekday) {
    const names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return names[weekday - 1];
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.filled,
    required this.isToday,
    required this.color,
    required this.colors,
  });

  final String label;
  final bool filled;
  final bool isToday;
  final Color color;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isToday ? color : colors.muted,
            fontSize: 10.5,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color.withValues(alpha: .18) : colors.elevated,
            border: Border.all(
              color: isToday ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: filled
                ? Icon(Icons.check_rounded, color: color, size: 14)
                : null,
          ),
        ),
      ],
    );
  }
}

/// Motivasi sehat harian untuk pengguna.
class _MotivationCard extends StatelessWidget {
  const _MotivationCard();

  static const List<String> _motivations = [
    'Kesehatan adalah kekayaan terbesar. Jaga dirimu hari ini untuk masa depan yang lebih baik.',
    'Setiap langkah kecil yang kamu ambil hari ini adalah investasi untuk tubuh yang lebih sehat besok.',
    'Kesehatan bukanlah tujuan akhir, melainkan perjalanan disiplin yang penuh cinta terhadap diri sendiri.',
    'Tubuhmu adalah rumah bagimu. Rawatlah dengan baik agar ia nyaman untuk ditinggali.',
    'Makan sehat dan bergerak aktif bukan bentuk hukuman, melainkan tanda penghargaan untuk tubuhmu.',
    'Mulailah hari ini dengan senyuman dan komitmen untuk menjaga kesehatan tubuh serta pikiran.',
    'Tidur yang cukup adalah kunci kesegaran pikiran. Berikan hak istirahat yang layak untuk tubuhmu.',
    'Setiap tetes keringat dan kepatuhan minum obat adalah bukti perjuanganmu menuju kesembuhan.',
    'Kesehatan yang baik dimulai dari pikiran yang damai. Jangan lupa luangkan waktu untuk relaksasi.',
    'Jangan membandingkan progresmu dengan orang lain. Yang terpenting, kamu lebih sehat dari kemarin.',
    'Disiplin hari ini adalah kedamaian pikiran esok hari. Tetap semangat memantau kesehatanmu!',
    'Air putih, udara segar, dan pikiran positif adalah obat alami terbaik untuk tubuhmu.',
    'Kesehatan tidak selalu datang dari obat-obatan. Seringkali ia datang dari kedamaian hati dan pikiran.',
    'Tubuhmu mendengar apa pun yang dikatakan oleh pikiranmu. Tetaplah berpikir positif hari ini.',
    'Jangan tunggu sakit baru menghargai kesehatan. Jaga pola hidup sehat mulai detik ini.',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final now = DateTime.now();
    final dayCode = now.year * 1000 + now.month * 100 + now.day;
    final quoteIndex = dayCode % _motivations.length;
    final motivationText = _motivations[quoteIndex];

    final itemColor = AppColors.violet; // elegant violet for motivation
    final itemIcon = Icons.wb_sunny_rounded; // sun icon for motivation/inspiration

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: itemColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: itemColor.withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: itemColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(itemIcon, color: itemColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  motivationText,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading card.
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fallback local-data widgets (kept for when API isn't available)
// ─────────────────────────────────────────────────────────────────────────────

/// Original score card backed by locally-computed [HealthRecord.score].
class HealthScoreCard extends StatelessWidget {
  const HealthScoreCard({super.key, this.record});

  final HealthRecord? record;

  @override
  Widget build(BuildContext context) {
    final score = record?.score ?? 0;
    final label = record?.statusLabel ?? 'Belum ada';
    final subtitle = record == null
        ? 'Catat data harian pertama Anda untuk melihat skor.'
        : _scoreInsight(score);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.green, Color(0xFF13A8B8), AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: .45),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        children: [
          ScoreRing(
            progress: score / 100,
            color: Colors.white,
            size: 124,
            stroke: 14,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$score',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        height: 1)),
                const Text('dari 100',
                    style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Kesehatan Terkini',
                    style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(30),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Dot(color: Color(0xFFC9FF8F)),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 12.5,
                        height: 1.45)),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text('Bukan diagnosis medis',
                            style: TextStyle(
                                color: Color(0xF2FFFFFF),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _isMeasuredToday(String? isoDate) {
  if (isoDate == null) return false;
  final d = DateTime.tryParse(isoDate);
  if (d == null) return false;
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

String _scoreInsight(int score) {
  if (score >= 85) {
    return 'Kondisi Anda sangat baik. Pertahankan kebiasaan ini.';
  }
  if (score >= 70) return 'Kondisi Anda baik. Sedikit perbaikan akan membantu.';
  if (score >= 60) return 'Perlu perhatian pada beberapa indikator hari ini.';
  return 'Beberapa indikator perlu diperhatikan. Tetap jaga pola hidup.';
}

/// 2×2 grid backed by local [HealthRecord] data.
class _LocalSummaryGrid extends StatelessWidget {
  const _LocalSummaryGrid({required this.record});

  final HealthRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 13,
      crossAxisSpacing: 13,
      childAspectRatio: 1.4,
      children: [
        SummaryCard(
          icon: Icons.water_drop_rounded,
          label: 'Gula Darah',
          value: record.bloodSugar?.toString() ?? '—',
          unit: 'mg/dL',
          status: bloodSugarStatus(record.bloodSugar),
          statusColor: bloodSugarColor(record.bloodSugar),
          iconColor: AppColors.primary,
        ),
        SummaryCard(
          icon: Icons.favorite_rounded,
          label: 'Tekanan Darah',
          value: record.bloodPressure,
          status: bloodPressureStatus(record.systolic, record.diastolic),
          statusColor: bloodPressureColor(record.systolic, record.diastolic),
          iconColor: AppColors.pink,
        ),
        SummaryCard(
          icon: Icons.monitor_weight_rounded,
          label: 'Berat Badan',
          value: record.weight != null
              ? record.weight!.toStringAsFixed(record.weight! % 1 == 0 ? 0 : 1)
              : '—',
          unit: 'kg',
          status: 'Tercatat',
          statusColor: colors.muted,
          iconColor: AppColors.violet,
        ),
        SummaryCard(
          icon: Icons.medication_rounded,
          label: 'Obat',
          value: record.medicineTaken
              ? (record.medicineName.isNotEmpty
                  ? record.medicineName
                  : 'Diminum')
              : 'Terlewat',
          status: record.medicineTaken
              ? (record.medicineTime.isNotEmpty
                  ? 'Diminum jam ${record.medicineTime}'
                  : 'Tepat waktu')
              : 'Belum diminum',
          statusColor: record.medicineTaken ? AppColors.lime : AppColors.red,
          iconColor: record.medicineTaken ? AppColors.lime : AppColors.red,
          valueIcon: record.medicineTaken
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
        ),
      ],
    );
  }
}

class _EmptyDataCard extends StatelessWidget {
  const _EmptyDataCard({required this.onView});

  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      padding: 22,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.edit_note_rounded,
                color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 14),
          Text('Belum ada catatan kesehatan',
              style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5)),
          const SizedBox(height: 6),
          Text(
            'Mulai catat gula darah, tekanan, dan obat harian Anda untuk melihat ringkasan dan skor di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Catat Sekarang',
            icon: Icons.add_rounded,
            onPressed: () => onView(MainView.catatan),
          ),
        ],
      ),
    );
  }
}

class _TodayPromptCard extends StatelessWidget {
  const _TodayPromptCard({required this.onView});

  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onView(MainView.catatan),
      child: AppCard(
        padding: 16,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.today_rounded,
                  color: AppColors.green, size: 23),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Belum mencatat hari ini',
                      style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text('Ketuk untuk mengisi catatan harian.',
                      style: TextStyle(color: colors.muted, fontSize: 12.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.muted),
          ],
        ),
      ),
    );
  }
}



class _MissedLogsBanner extends StatelessWidget {
  const _MissedLogsBanner({
    required this.status,
    required this.colors,
    required this.onTap,
  });

  final PatientTodayStatus status;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String dateMsg = '';
    if (status.daysSinceLastLog == null) {
      dateMsg = 'Anda belum pernah mengisi catatan harian.';
    } else {
      final lastLogDate = DateTime.tryParse(status.lastLoggedAt ?? '');
      if (lastLogDate != null) {
        final firstMissed = HealthRecord.dayOf(lastLogDate).add(const Duration(days: 1));
        final todayNormalized = HealthRecord.dayOf(DateTime.now());
        final missedDaysCount = todayNormalized.difference(firstMissed).inDays;
        if (missedDaysCount <= 1) {
          dateMsg = 'Belum mengisi catatan tanggal ${formatShortDate(firstMissed)}.';
        } else {
          dateMsg = 'Belum mengisi catatan sejak ${formatShortDate(firstMissed)}.';
        }
      } else {
        dateMsg = 'Belum mengisi catatan untuk kemarin.';
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.red.withValues(alpha: .25),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: .15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.red,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Harian Terlewat',
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateMsg,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Isi',
                  style: TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.red,
                  size: 11,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChartCard extends StatelessWidget {
  const _MetricChartCard({
    required this.label,
    required this.values,
    required this.records,
    required this.trend,
    required this.color,
  });

  final String label;
  final List<double> values;
  final List<HealthRecord> records;
  final TrendInfo trend;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$label · ${values.length} catatan',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(trend.icon, color: trend.color, size: 15),
                  const SizedBox(width: 3),
                  Text(
                    trend.label,
                    style: TextStyle(
                        color: trend.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: values.length < 2
                ? const ChartEmpty()
                : TrendChart(color: color, values: values),
          ),
          const SizedBox(height: 6),
          if (values.length >= 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: records
                  .map((r) => Text(
                        dayName(r.date).substring(0, 3),
                        style: TextStyle(
                            color: colors.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
