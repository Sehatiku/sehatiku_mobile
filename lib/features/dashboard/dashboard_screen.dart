import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onView});

  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    final store = HealthScope.of(context);
    final latest = store.latest;
    final today = store.today;
    final hasData = latest != null;
    final bsRecords = store
        .recent(7)
        .where((r) => r.bloodSugar != null)
        .toList();
    final bsValues = bsRecords.map((r) => r.bloodSugar!.toDouble()).toList();
    final bsTrend = trendInfo(bsValues, lowerIsBetter: true);
    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: .35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  'LV',
                  style: TextStyle(
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
                    Text(
                      '${greeting()},',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'Lavinia 👋',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  IconCircle(
                    icon: Icons.notifications_rounded,
                    onTap: () => onView(MainView.notifikasi),
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
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          HealthScoreCard(record: latest),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: SectionTitle(title: 'Ringkasan Terakhir')),
              const SizedBox(width: 8),
              Text(
                hasData ? formatShortDate(latest.date) : 'Belum ada data',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (!hasData)
            _EmptyDataCard(onView: onView)
          else
            GridView.count(
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
                  value: latest.bloodSugar?.toString() ?? '—',
                  unit: 'mg/dL',
                  status: bloodSugarStatus(latest.bloodSugar),
                  statusColor: bloodSugarColor(latest.bloodSugar),
                  iconColor: AppColors.primary,
                ),
                SummaryCard(
                  icon: Icons.favorite_rounded,
                  label: 'Tekanan Darah',
                  value: latest.bloodPressure,
                  status: bloodPressureStatus(
                    latest.systolic,
                    latest.diastolic,
                  ),
                  statusColor: bloodPressureColor(
                    latest.systolic,
                    latest.diastolic,
                  ),
                  iconColor: AppColors.pink,
                ),
                SummaryCard(
                  icon: Icons.monitor_weight_rounded,
                  label: 'Berat Badan',
                  value: latest.weight != null
                      ? latest.weight!.toStringAsFixed(
                          latest.weight! % 1 == 0 ? 0 : 1,
                        )
                      : '—',
                  unit: 'kg',
                  status: 'Tercatat',
                  statusColor: AppColors.muted,
                  iconColor: AppColors.violet,
                ),
                SummaryCard(
                  icon: Icons.medication_rounded,
                  label: 'Obat',
                  value: latest.medicineTaken ? 'Diminum' : 'Terlewat',
                  status: latest.medicineTaken
                      ? 'Tepat waktu'
                      : 'Belum diminum',
                  statusColor: latest.medicineTaken
                      ? AppColors.lime
                      : AppColors.red,
                  iconColor: latest.medicineTaken
                      ? AppColors.lime
                      : AppColors.red,
                  valueIcon: latest.medicineTaken
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                ),
              ],
            ),
          if (today == null) ...[
            const SizedBox(height: 14),
            _TodayPromptCard(onView: onView),
          ],
          const SizedBox(height: 28),
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
                onTap: () => onView(MainView.catatan),
              ),
              BigAction(
                icon: Icons.history_rounded,
                label: 'Riwayat',
                colors: const [AppColors.green, AppColors.lime],
                onTap: () => onView(MainView.riwayat),
              ),
              BigAction(
                icon: Icons.menu_book_rounded,
                label: 'Edukasi',
                colors: const [AppColors.violet, AppColors.cyan],
                onTap: () => onView(MainView.edukasi),
              ),
              BigAction(
                icon: Icons.medical_services_rounded,
                label: 'Hubungi Dokter',
                colors: const [AppColors.pink, Color(0xFFFF9472)],
                onTap: () => onView(MainView.dokter),
              ),
            ],
          ),
          const SizedBox(height: 26),
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => onView(MainView.ai),
            child: GradientPanel(
              radius: 26,
              colors: const [
                AppColors.violet,
                Color(0xFF9B7BFF),
                AppColors.cyan,
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Insight AI Hari Ini',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '"Kondisi Anda stabil. Pertahankan pola makan rendah garam hari ini."',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Text(
                        'Lihat detail',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: 16,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.alarm_rounded,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minum Obat Metformin',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hari ini, pukul 09.00',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '09:00',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                        style: const TextStyle(
                          color: AppColors.text,
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
                        Text(
                          bsTrend.label,
                          style: TextStyle(
                            color: bsTrend.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  child: bsValues.length < 2
                      ? const ChartEmpty()
                      : TrendChart(color: AppColors.primary, values: bsValues),
                ),
                const SizedBox(height: 6),
                if (bsValues.length >= 2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: bsRecords
                        .map(
                          (r) => Text(
                            dayName(r.date).substring(0, 3),
                            style: const TextStyle(
                              color: Color(0xFF9AA9BB),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFDFF3EC), Color(0xFFEAF2FE)],
              ),
              border: Border.all(color: AppColors.green.withValues(alpha: .12)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -4,
                  right: 0,
                  child: Icon(
                    Icons.format_quote_rounded,
                    size: 36,
                    color: AppColors.green.withValues(alpha: .3),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: Text(
                    'Kesehatan adalah investasi terbaik untuk masa depan Anda.',
                    style: TextStyle(
                      color: Color(0xFF1F5E4F),
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
                Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const Text(
                  'dari 100',
                  style: TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Kesehatan Terkini',
                  style: TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Dot(color: Color(0xFFC9FF8F)),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'Bukan diagnosis medis',
                          style: TextStyle(
                            color: Color(0xF2FFFFFF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
  if (score >= 85) {
    return 'Kondisi Anda sangat baik. Pertahankan kebiasaan ini.';
  }
  if (score >= 70) return 'Kondisi Anda baik. Sedikit perbaikan akan membantu.';
  if (score >= 60) return 'Perlu perhatian pada beberapa indikator hari ini.';
  return 'Beberapa indikator perlu diperhatikan. Tetap jaga pola hidup.';
}



/// Shown on the dashboard when no records exist yet.
class _EmptyDataCard extends StatelessWidget {
  const _EmptyDataCard({required this.onView});

  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: 22,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada catatan kesehatan',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mulai catat gula darah, tekanan, dan obat harian Anda untuk melihat ringkasan dan skor di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
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

/// Nudges the user to log today's data when only older records exist.
class _TodayPromptCard extends StatelessWidget {
  const _TodayPromptCard({required this.onView});

  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
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
                color: const Color(0xFFE7F7EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.today_rounded,
                color: AppColors.green,
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum mencatat hari ini',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ketuk untuk mengisi catatan harian.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC2CEDB)),
          ],
        ),
      ),
    );
  }
}
