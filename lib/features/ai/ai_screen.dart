import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';

import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

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
    final foreLabel = const ['7 hari', '30 hari', '90 hari'][forecastIndex];
    final latest = HealthScope.of(context).latest;
    final risk = latest?.riskPercent ?? 0;
    final hasData = latest != null;
    final riskColor = !hasData
        ? AppColors.muted
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
                  children: const [
                    RecommendTile(
                      icon: Icons.restaurant_rounded,
                      color: AppColors.lime,
                      bg: Color(0xFFE7F7EC),
                      title: 'Kurangi asupan garam',
                      desc: 'Maksimal 1 sendok teh per hari',
                      trailing: RecommendCheck(),
                    ),
                    _DividerLine(),
                    RecommendTile(
                      icon: Icons.water_drop_rounded,
                      color: AppColors.cyan,
                      bg: Color(0xFFEAF6FF),
                      title: 'Minum 2 liter air',
                      desc: 'Sekitar 8 gelas hari ini',
                      trailing: RecommendBadge(
                        text: '5/8',
                        color: AppColors.cyan,
                      ),
                    ),
                    _DividerLine(),
                    RecommendTile(
                      icon: Icons.directions_walk_rounded,
                      color: AppColors.lime,
                      bg: Color(0xFFE7F7EC),
                      title: 'Jalan kaki 30 menit',
                      desc: 'Pagi atau sore hari',
                      trailing: RecommendCheck(),
                    ),
                    _DividerLine(),
                    RecommendTile(
                      icon: Icons.bedtime_rounded,
                      color: AppColors.violet,
                      bg: Color(0xFFF0EBFF),
                      title: 'Tidur sebelum 22.00',
                      desc: 'Target 7-8 jam',
                      trailing: RecommendBadge(
                        text: 'Nanti',
                        color: AppColors.muted,
                      ),
                    ),
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
                      trackColor: const Color(0xFFEEF3F9),
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$risk%',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'risiko',
                            style: TextStyle(
                              color: AppColors.muted,
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
                            style: const TextStyle(
                              color: Color(0xFF5A6B7D),
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
    return const Divider(
      color: Color(0xFFEEF3F9),
      height: 1,
      indent: 12,
      endIndent: 12,
    );
  }
}

