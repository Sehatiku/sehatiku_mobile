import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/dashboard_models.dart';
import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
import 'package:sehatiku_mobile/data/services/dashboard_service.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen widget
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onView, this.fullName});

  final ValueChanged<MainView> onView;
  final String? fullName;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PatientDashboard? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await DashboardService.instance.fetchDashboard();
      if (mounted) setState(() => _dashboard = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = HealthScope.of(context);
    final colors = AppColors.of(context);

    final displayName = _dashboard?.profile.fullName ?? widget.fullName ?? 'Pengguna';
    final firstName = displayName.split(' ').first;
    final initials = displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final latest = store.latest;
    final today = store.today;
    final bsRecords =
        store.recent(7).where((r) => r.bloodSugar != null).toList();
    final bsValues = bsRecords.map((r) => r.bloodSugar!.toDouble()).toList();
    final bsTrend = trendInfo(bsValues, lowerIsBetter: true);

    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.violet, AppColors.cyan],
                  ),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: .6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: .35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${greeting()},',
                        style: TextStyle(color: colors.muted, fontSize: 13)),
                    Text('$firstName 👋',
                        style: TextStyle(
                            color: colors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Stack(
                children: [
                  IconCircle(
                    icon: Icons.notifications_rounded,
                    onTap: () => widget.onView(MainView.notifikasi),
                  ),
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: colors.background, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          // ── AI Risk Card (from API) or local score card ───────────────────
          if (_loading)
            const _LoadingCard()
          else if (_dashboard != null)
            _ApiRiskCard(dashboard: _dashboard!)
          else
            HealthScoreCard(record: latest),
          const SizedBox(height: 24),

          // ── Latest measurements (from API) ─────────────────────────────────
          if (_dashboard != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: SectionTitle(title: 'Pengukuran Terakhir')),
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

          // ── Streak & logging (from API) ────────────────────────────────────
          if (_dashboard != null) ...[
            const SizedBox(height: 14),
            _StreakCard(logging: _dashboard!.logging),
          ],
          const SizedBox(height: 28),

          // ── Recommendations (from API) ─────────────────────────────────────
          if (_dashboard != null && _dashboard!.recommendations.isNotEmpty) ...[
            const SectionTitle(title: 'Rekomendasi Hari Ini'),
            const SizedBox(height: 13),
            _RecommendationsCard(recommendations: _dashboard!.recommendations),
            const SizedBox(height: 24),
          ],

          // ── Quick actions ──────────────────────────────────────────────────
          const SectionTitle(title: 'Aksi Cepat'),
          const SizedBox(height: 13),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 13,
            crossAxisSpacing: 13,
            childAspectRatio: 1.25,
            children: [
              BigAction(
                icon: Icons.edit_note_rounded,
                label: 'Catat Hari Ini',
                colors: const [AppColors.primary, AppColors.cyan],
                onTap: () => widget.onView(MainView.catatan),
              ),
              BigAction(
                icon: Icons.history_rounded,
                label: 'Riwayat',
                colors: const [AppColors.green, AppColors.lime],
                onTap: () => widget.onView(MainView.riwayat),
              ),
              BigAction(
                icon: Icons.menu_book_rounded,
                label: 'Edukasi',
                colors: const [AppColors.violet, AppColors.cyan],
                onTap: () => widget.onView(MainView.edukasi),
              ),
              BigAction(
                icon: Icons.medical_services_rounded,
                label: 'Hubungi Dokter',
                colors: const [AppColors.pink, Color(0xFFFF9472)],
                onTap: () => widget.onView(MainView.dokter),
              ),
            ],
          ),
          const SizedBox(height: 26),
          // ── AI insight banner ──────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => widget.onView(MainView.ai),
            child: GradientPanel(
              radius: 26,
              colors: const [AppColors.violet, Color(0xFF9B7BFF), AppColors.cyan],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
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
                    _dashboard != null &&
                            _dashboard!.recommendations.isNotEmpty
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

          // ── Blood sugar chart (local data) ─────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Gula Darah · ${bsValues.length} catatan',
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
                        Icon(bsTrend.icon, color: bsTrend.color, size: 15),
                        const SizedBox(width: 3),
                        Text(bsTrend.label,
                            style: TextStyle(
                                color: bsTrend.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  child: bsValues.length < 2
                      ? const ChartEmpty()
                      : TrendChart(
                          color: AppColors.primary, values: bsValues),
                ),
                const SizedBox(height: 6),
                if (bsValues.length >= 2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: bsRecords
                        .map((r) => Text(dayName(r.date).substring(0, 3),
                            style: TextStyle(
                                color: colors.muted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600)))
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Motivational quote ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: colors.surface,
              border: Border.all(
                  color: AppColors.green.withValues(alpha: .22)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -4,
                  right: 0,
                  child: Icon(Icons.format_quote_rounded,
                      size: 36,
                      color: AppColors.green.withValues(alpha: .35)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text(
                    'Kesehatan adalah investasi terbaik untuk masa depan Anda.',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.55,
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
                const Text('Risiko AI Terkini',
                    style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: .35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(statusEmoji,
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          '${risk.riskLabel[0].toUpperCase()}${risk.riskLabel.substring(1)} · ${risk.status}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_rounded,
                            color: Colors.white, size: 14),
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
  const _MeasurementGrid({required this.dashboard, required this.onView});

  final PatientDashboard dashboard;
  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final m = dashboard.latestMeasurements;
    final hasGlucose = m.glucose != null;
    final hasBP = m.bloodPressure != null;

    // Both null → waiting for WhatsApp ingestion
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
                    style:
                        TextStyle(color: colors.muted, fontSize: 12.5, height: 1.4),
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
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 13,
      crossAxisSpacing: 13,
      childAspectRatio: 1.4,
      children: [
        SummaryCard(
          icon: Icons.water_drop_rounded,
          label: 'Gula Darah',
          value: hasGlucose ? '${m.glucose!.value}' : '—',
          unit: 'mg/dL',
          status: hasGlucose
              ? bloodSugarStatus(m.glucose!.value)
              : 'Belum tercatat',
          statusColor: hasGlucose
              ? bloodSugarColor(m.glucose!.value)
              : AppColors.of(context).muted,
          iconColor: AppColors.primary,
        ),
        SummaryCard(
          icon: Icons.favorite_rounded,
          label: 'Tekanan Darah',
          value: hasBP
              ? '${m.bloodPressure!.systolic}/${m.bloodPressure!.diastolic}'
              : '—',
          status: hasBP
              ? bloodPressureStatus(
                  m.bloodPressure!.systolic, m.bloodPressure!.diastolic)
              : 'Belum tercatat',
          statusColor: hasBP
              ? bloodPressureColor(
                  m.bloodPressure!.systolic, m.bloodPressure!.diastolic)
              : AppColors.of(context).muted,
          iconColor: AppColors.pink,
        ),
        // Disease type badge
        SummaryCard(
          icon: Icons.medical_information_rounded,
          label: 'Penyakit',
          value: _diseaseLabel(dashboard.profile.diseaseType),
          status: 'Terdaftar',
          statusColor: AppColors.violet,
          iconColor: AppColors.violet,
        ),
        // Age
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

/// Streak & logging status card.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.logging});

  final DashboardLogging logging;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final Color streakColor =
        logging.streakDays >= 7 ? AppColors.lime : AppColors.amber;

    return AppCard(
      padding: 16,
      child: Row(
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
                  logging.loggedToday
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
    );
  }
}

/// Recommendations from the AI / SHAP factors.
class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.recommendations});

  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recommendations.asMap().entries.map((entry) {
          final idx = entry.key;
          final text = entry.value;
          return Padding(
            padding: EdgeInsets.only(
                bottom: idx < recommendations.length - 1 ? 12 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text('${idx + 1}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(text,
                      style: TextStyle(
                          color: colors.text,
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }).toList(),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: .35)),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_rounded,
                            color: Colors.white, size: 14),
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

String _scoreInsight(int score) {
  if (score >= 85) return 'Kondisi Anda sangat baik. Pertahankan kebiasaan ini.';
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
              ? record.weight!.toStringAsFixed(
                  record.weight! % 1 == 0 ? 0 : 1)
              : '—',
          unit: 'kg',
          status: 'Tercatat',
          statusColor: colors.muted,
          iconColor: AppColors.violet,
        ),
        SummaryCard(
          icon: Icons.medication_rounded,
          label: 'Obat',
          value: record.medicineTaken ? 'Diminum' : 'Terlewat',
          status: record.medicineTaken ? 'Tepat waktu' : 'Belum diminum',
          statusColor:
              record.medicineTaken ? AppColors.lime : AppColors.red,
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
                      style:
                          TextStyle(color: colors.muted, fontSize: 12.5)),
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
