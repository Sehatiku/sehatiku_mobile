import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
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
    final risk = latest?.riskPercent ?? 0;
    final hasData = latest != null;
    final riskColor = !hasData
        ? c.muted
        : risk < 15
            ? AppColors.lime
            : risk < 30
                ? AppColors.amber
                : AppColors.red;
    final riskLabel = !hasData
        ? 'Belum ada data'
        : risk < 15
            ? 'Risiko Rendah'
            : risk < 30
                ? 'Risiko Sedang'
                : 'Risiko Tinggi';
    final riskDesc = !hasData
        ? 'Catat data harian Anda agar AI dapat memperkirakan risiko komplikasi.'
        : risk < 15
            ? 'Indikator diabetes & hipertensi Anda terkendali dengan baik.'
            : risk < 30
                ? 'Beberapa indikator perlu diperhatikan minggu ini.'
                : 'Beberapa indikator berisiko. Pertimbangkan konsultasi dengan dokter Anda.';

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
    } else {
      recommendationItems.add(_RecommendationItem(
        icon: Icons.water_drop_rounded,
        color: AppColors.cyan,
        bg: AppColors.tint(AppColors.cyan),
        title: 'Minum 2 liter air',
        desc: 'Sekitar 8 gelas hari ini untuk hidrasi optimal.',
        trailing: const RecommendBadge(text: '5/8', color: AppColors.cyan),
      ));
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
              : 'Metformin telah diminum sesuai petunjuk dokter.',
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
              : 'Metformin belum tercatat diminum hari ini.',
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
              colors: [AppColors.violet, Color(0xFF6F78F0), AppColors.green],
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
