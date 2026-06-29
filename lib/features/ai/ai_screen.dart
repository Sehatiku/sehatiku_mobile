import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
import 'package:sehatiku_mobile/data/services/dashboard_service.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class _RecommendationItem {
  const _RecommendationItem({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.desc,
    required this.trailing,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String desc;
  final Widget trailing;
}

class AiScreen extends StatelessWidget {
  const AiScreen({
    super.key,
    required this.forecastIndex,
    required this.onForecast,
    required this.onAction,
  });

  final int forecastIndex;
  final ValueChanged<int> onForecast;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final foreLabel = const ['7 hari', '30 hari', '90 hari'][forecastIndex];
    final latest = HealthScope.of(context).latest;
    final today = HealthScope.of(context).today;

    // Prefer API risk data; fall back to locally computed heuristic.
    final apiDashboard = DashboardService.instance.cachedDashboard;
    final apiRisk = apiDashboard?.risk;
    final hasApiScore = apiRisk != null && apiRisk.scoredAt != null;
    final hasData = hasApiScore || latest != null;

    final int risk;
    final Color riskColor;
    final String riskLabel;
    final String riskDesc;

    if (hasApiScore) {
      // Dart promotes apiRisk to non-null here via the hasApiScore check.
      risk = apiRisk.score;
      riskColor = switch (apiRisk.status) {
        'bahaya' => AppColors.red,
        'waswas' => AppColors.amber,
        _ => AppColors.lime,
      };
      // Capitalise first letter of riskLabel from API (e.g. 'rendah' → 'Rendah').
      final label = apiRisk.riskLabel;
      riskLabel = label.isEmpty
          ? 'Aman'
          : '${label[0].toUpperCase()}${label.substring(1)}';
      riskDesc = apiRisk.mainFactor.isNotEmpty
          ? 'Faktor utama: ${apiRisk.mainFactor}'
          : _riskStatusDesc(apiRisk.status);
    } else if (!hasData) {
      risk = 0;
      riskColor = c.muted;
      riskLabel = 'Belum ada data';
      riskDesc = 'Catat data harian Anda agar AI dapat memperkirakan risiko komplikasi.';
    } else {
      final localRisk = latest?.riskPercent ?? 0;
      risk = localRisk;
      riskColor = localRisk < 15
          ? AppColors.lime
          : localRisk < 30
              ? AppColors.amber
              : AppColors.red;
      riskLabel = localRisk < 15
          ? 'Risiko Rendah'
          : localRisk < 30
              ? 'Risiko Sedang'
              : 'Risiko Tinggi';
      riskDesc = localRisk < 15
          ? 'Indikator diabetes & hipertensi Anda terkendali dengan baik.'
          : localRisk < 30
              ? 'Beberapa indikator perlu diperhatikan minggu ini.'
              : 'Beberapa indikator berisiko. Pertimbangkan konsultasi dengan dokter Anda.';
    }

    // API recommendations from the ML model (ready-to-display Indonesian text).
    final apiRecommendations = apiDashboard?.recommendations ?? [];

    // Generate dynamic recommendations based on today's logged data in HealthStore
    final List<_RecommendationItem> recommendationItems = [];

    // 1. Blood Sugar Recommendation
    if (today != null && today.bloodSugar != null) {
      final bs = today.bloodSugar!;
      if (bs >= 140) {
        recommendationItems.add(_RecommendationItem(
          icon: Icons.restaurant_rounded,
          color: AppColors.orange,
          bg: AppColors.tint(AppColors.orange),
          title: 'Batasi gula & karbohidrat',
          desc: 'Kadar gula darah hari ini tinggi ($bs mg/dL). Hindari makanan manis.',
          trailing: const RecommendBadge(text: 'Penting', color: AppColors.orange),
        ));
      } else if (bs < 70) {
        recommendationItems.add(_RecommendationItem(
          icon: Icons.restaurant_rounded,
          color: AppColors.red,
          bg: AppColors.tint(AppColors.red),
          title: 'Gula darah rendah ($bs mg/dL)',
          desc: 'Konsumsi gula cepat serap seperti teh manis hangat atau madu.',
          trailing: const RecommendBadge(text: 'Mendesak', color: AppColors.red),
        ));
      } else {
        recommendationItems.add(_RecommendationItem(
          icon: Icons.restaurant_rounded,
          color: AppColors.lime,
          bg: AppColors.tint(AppColors.lime),
          title: 'Pola makan seimbang',
          desc: 'Kadar gula darah terkontrol ($bs mg/dL). Pertahankan nutrisi ini.',
          trailing: const RecommendCheck(),
        ));
      }
    } else {
      recommendationItems.add(_RecommendationItem(
        icon: Icons.restaurant_rounded,
        color: AppColors.lime,
        bg: AppColors.tint(AppColors.lime),
        title: 'Kurangi asupan garam',
        desc: 'Maksimal 1 sendok teh per hari untuk kesehatan jantung.',
        trailing: const RecommendCheck(),
      ));
    }

    // 2. Blood Pressure Recommendation
    if (today != null && today.systolic != null && today.diastolic != null) {
      final sys = today.systolic!;
      final dia = today.diastolic!;
      if (sys >= 130 || dia >= 85) {
        recommendationItems.add(_RecommendationItem(
          icon: Icons.favorite_rounded,
          color: AppColors.red,
          bg: AppColors.tint(AppColors.red),
          title: 'Batasi garam & rileks',
          desc: 'Tekanan darah tinggi ($sys/$dia mmHg). Hindari stress hari ini.',
          trailing: const RecommendBadge(text: 'Peringatan', color: AppColors.red),
        ));
      } else {
        recommendationItems.add(_RecommendationItem(
          icon: Icons.favorite_rounded,
          color: AppColors.lime,
          bg: AppColors.tint(AppColors.lime),
          title: 'Tekanan darah stabil',
          desc: 'Tekanan darah normal ($sys/$dia mmHg). Jaga hidrasi tubuh.',
          trailing: const RecommendCheck(),
        ));
      }
    }

    // 3. Physical Activity Recommendation
    if (today != null) {
      if (today.active30) {
        recommendationItems.add(_RecommendationItem(
          icon: Icons.directions_run_rounded,
          color: AppColors.lime,
          bg: AppColors.tint(AppColors.lime),
          title: 'Target aktivitas tercapai',
          desc: today.activityType.isNotEmpty
              ? 'Hebat! Anda sudah melakukan ${today.activityType} selama ${today.activityMinutes} menit.'
              : 'Hebat! Anda sudah aktif bergerak ≥30 menit hari ini.',
          trailing: const RecommendCheck(),
        ));
      } else {
        recommendationItems.add(_RecommendationItem(
          icon: Icons.directions_walk_rounded,
          color: AppColors.primary,
          bg: AppColors.tint(AppColors.primary),
          title: 'Jalan santai 30 menit',
          desc: 'Aktivitas fisik sedang membantu sensitivitas insulin.',
          trailing: const RecommendBadge(text: 'Nanti', color: AppColors.primary),
        ));
      }
    } else {
      recommendationItems.add(_RecommendationItem(
        icon: Icons.directions_walk_rounded,
        color: AppColors.lime,
        bg: AppColors.tint(AppColors.lime),
        title: 'Jalan kaki 30 menit',
        desc: 'Pagi atau sore hari untuk menjaga sirkulasi darah tetap lancar.',
        trailing: const RecommendCheck(),
      ));
    }

    // 4. Medicine Adherence Recommendation
    if (today != null) {
      if (today.medicineTaken) {
        recommendationItems.add(_RecommendationItem(
          icon: Icons.medication_rounded,
          color: AppColors.lime,
          bg: AppColors.tint(AppColors.lime),
          title: 'Obat harian dikonsumsi',
          desc: today.medicineName.isNotEmpty
              ? '${today.medicineName} telah diminum sesuai petunjuk dokter.'
              : 'Obat harian Anda telah diminum sesuai petunjuk dokter.',
          trailing: const RecommendCheck(),
        ));
      } else {
        recommendationItems.add(_RecommendationItem(
          icon: Icons.medication_rounded,
          color: AppColors.orange,
          bg: AppColors.tint(AppColors.orange),
          title: 'Minum obat harian',
          desc: today.medicineName.isNotEmpty
              ? '${today.medicineName} belum tercatat diminum hari ini.'
              : 'Obat harian Anda belum tercatat diminum hari ini.',
          trailing: const RecommendBadge(text: 'Mendesak', color: AppColors.orange),
        ));
      }
    } else {
      recommendationItems.add(_RecommendationItem(
        icon: Icons.bedtime_rounded,
        color: AppColors.violet,
        bg: AppColors.tint(AppColors.violet),
        title: 'Tidur sebelum 22.00',
        desc: 'Target tidur berkualitas 7-8 jam hari ini.',
        trailing: RecommendBadge(text: 'Rutin', color: c.muted),
      ));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.violet, AppColors.primary],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 7),
                    Text(
                      'Didukung AI & Machine Learning',
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
                'Asisten AI Sehatiku',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Analisis personal dari data kesehatan harian Anda',
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Rekomendasi Hari Ini'),
              const SizedBox(height: 13),
              AppCard(
                padding: 6,
                child: Column(
                  children: [
                    for (int i = 0; i < recommendationItems.length; i++) ...[
                      RecommendTile(
                        icon: recommendationItems[i].icon,
                        color: recommendationItems[i].color,
                        bg: recommendationItems[i].bg,
                        title: recommendationItems[i].title,
                        desc: recommendationItems[i].desc,
                        trailing: recommendationItems[i].trailing,
                      ),
                      if (i < recommendationItems.length - 1)
                        const _DividerLine(),
                    ],
                  ],
                ),
              ),

              // API recommendations from the ML model — display as-is (already
              // in Indonesian and ready to show per API contract).
              if (apiRecommendations.isNotEmpty) ...[
                const SizedBox(height: 14),
                AppCard(
                  padding: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.tint(AppColors.violet),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: AppColors.violet,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dari Sehatiku AI',
                              style: TextStyle(
                                color: c.text,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: c.line, height: 1),
                      ...apiRecommendations.asMap().entries.map((entry) {
                        final isLast =
                            entry.key == apiRecommendations.length - 1;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(top: 5),
                                    decoration: const BoxDecoration(
                                      color: AppColors.violet,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        color: c.text,
                                        fontSize: 13,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast) Divider(color: c.line, height: 1),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const SectionTitle(title: 'Prediksi Risiko'),
              const SizedBox(height: 13),
              AppCard(
                padding: 22,
                child: Row(
                  children: [
                    ScoreRing(
                      progress: risk / 100,
                      color: riskColor,
                      size: 104,
                      stroke: 16,
                      trackColor: c.line,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$risk%',
                            style: TextStyle(
                              color: c.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'risiko',
                            style: TextStyle(
                              color: c.muted,
                              fontSize: 10,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: riskColor.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Dot(color: riskColor),
                                const SizedBox(width: 6),
                                Text(
                                  riskLabel,
                                  style: TextStyle(
                                    color: riskColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            riskDesc,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SegmentedPills(
                labels: const ['7 Hari', '30 Hari', '90 Hari'],
                selected: forecastIndex,
                onTap: onForecast,
              ),
              const SizedBox(height: 16),
              GradientPanel(
                radius: 24,
                colors: const [AppColors.violet, AppColors.cyan],
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
                            'Penjelasan AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      'Berdasarkan tren $foreLabel terakhir, gula darah & tekanan Anda diprediksi tetap stabil bila pola hidup sehat dipertahankan.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => onAction(
                        'Penjelasan lengkap prediksi $foreLabel dibuka.',
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Lihat Penjelasan Lengkap'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.violet,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Maps a `DashboardRisk.status` value to a human-readable description.
String _riskStatusDesc(String status) => switch (status) {
      'bahaya' =>
        'Beberapa indikator berisiko. Pertimbangkan konsultasi dengan dokter Anda.',
      'waswas' => 'Beberapa indikator perlu diperhatikan minggu ini.',
      _ => 'Indikator diabetes & hipertensi Anda terkendali dengan baik.',
    };

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.of(context).line,
      height: 1,
      indent: 12,
      endIndent: 12,
    );
  }
}
