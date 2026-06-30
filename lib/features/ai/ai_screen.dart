import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';
import 'package:sehatiku_mobile/data/services/dashboard_service.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';
import 'package:sehatiku_mobile/data/services/record_service.dart';

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

class AiScreen extends StatefulWidget {
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
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final Map<int, String> _summaries = {};
  final Map<int, bool> _loading = {};
  final Map<int, String?> _errors = {};
  List<int> _availableWindows = [7];

  @override
  void initState() {
    super.initState();
    _fetchSummaryForIndex(widget.forecastIndex);
    _fetchHealthScore();
  }

  @override
  void didUpdateWidget(AiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forecastIndex != oldWidget.forecastIndex) {
      _fetchSummaryForIndex(widget.forecastIndex);
    }
  }

  Future<void> _fetchHealthScore() async {
    try {
      await RecordService.instance.fetchHealthScore(forceRefresh: true);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('DEBUG: Error fetching health score in AiScreen: $e');
    }
  }

  Future<void> _fetchSummaryForIndex(int index) async {
    final days = const [7, 14, 30][index];
    if (_summaries.containsKey(days)) return; // Already cached

    setState(() {
      _loading[days] = true;
      _errors[days] = null;
    });

    try {
      final res = await DashboardService.instance.fetchAiSummary(days);
      if (mounted) {
        setState(() {
          _summaries[days] = res.narrative;
          _availableWindows = res.availableWindows;
          _loading[days] = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errors[days] = e.message;
          _loading[days] = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errors[days] = 'Gagal memuat penjelasan AI. Silakan coba lagi.';
          _loading[days] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final forecastIndex = widget.forecastIndex;
    final onForecast = widget.onForecast;
    final c = AppColors.of(context);
    final latest = HealthScope.of(context).latest;
    final today = HealthScope.of(context).today;

    final List<int> enabledPillIndices = [];
    if (_availableWindows.contains(7)) enabledPillIndices.add(0);
    if (_availableWindows.contains(14)) enabledPillIndices.add(1);
    if (_availableWindows.contains(30)) enabledPillIndices.add(2);
    if (enabledPillIndices.isEmpty) enabledPillIndices.add(0);

    // Prefer API risk data; fall back to locally computed heuristic.
    final apiDashboard = DashboardService.instance.cachedDashboard;
    final apiRisk = apiDashboard?.risk;
    final cachedScore = RecordService.instance.cachedScore;

    final hasApiScore = cachedScore != null || (apiRisk != null && apiRisk.scoredAt != null);
    final hasData = hasApiScore || latest != null;

    final int risk;
    final Color riskColor;
    final String riskLabel;
    final String riskDesc;
    final List<String> penalties;

    if (cachedScore != null) {
      risk = cachedScore.healthScore.round();
      riskColor = switch (cachedScore.status) {
        'bahaya' => AppColors.red,
        'waswas' => AppColors.amber,
        _ => AppColors.lime,
      };
      final label = cachedScore.statusLabel;
      riskLabel = label.isNotEmpty
          ? label
          : (cachedScore.status == 'bahaya' ? 'Parah' : (cachedScore.status == 'waswas' ? 'Waswas' : 'Sehat'));
      riskDesc = cachedScore.message;
      penalties = cachedScore.topPenalties;
    } else if (apiRisk != null && apiRisk.scoredAt != null) {
      // Dart promotes apiRisk to non-null here via the hasApiScore check.
      risk = apiRisk.score;
      riskColor = switch (apiRisk.status) {
        'bahaya' => AppColors.red,
        'waswas' => AppColors.amber,
        _ => AppColors.lime,
      };
      final label = apiRisk.statusLabel;
      riskLabel = label.isNotEmpty
          ? label
          : (apiRisk.status == 'bahaya'
              ? 'Parah'
              : (apiRisk.status == 'waswas' ? 'Waswas' : 'Sehat'));
      riskDesc = (apiRisk.message != null && apiRisk.message!.isNotEmpty)
          ? apiRisk.message!
          : (apiRisk.mainFactor.isNotEmpty
              ? 'Faktor utama: ${apiRisk.mainFactor}'
              : _riskStatusDesc(apiRisk.status));
      penalties = apiRisk.topPenalties;
    } else if (!hasData) {
      risk = 0;
      riskColor = c.muted;
      riskLabel = 'Belum ada data';
      riskDesc = 'Catat data harian Anda agar AI dapat memperkirakan skor kesehatan Anda.';
      penalties = const [];
    } else {
      final localScore = latest?.score ?? 0;
      risk = localScore;
      riskColor = localScore >= 80
          ? AppColors.lime
          : localScore >= 60
              ? AppColors.amber
              : AppColors.red;
      riskLabel = localScore >= 80
          ? 'Sehat'
          : localScore >= 60
              ? 'Waswas'
              : 'Parah';
      riskDesc = localScore >= 80
          ? 'Indikator diabetes & hipertensi Anda terkendali dengan baik.'
          : localScore >= 60
              ? 'Beberapa indikator perlu diperhatikan minggu ini.'
              : 'Beberapa indikator berisiko. Pertimbangkan konsultasi dengan dokter Anda.';
      penalties = const [];
    }



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
              // Health Score Section (Moved above AI Summary)
              const SectionTitle(title: 'Health Score'),
              const SizedBox(height: 13),
              AppCard(
                padding: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                                '$risk',
                                style: TextStyle(
                                  color: c.text,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'skor',
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
                              Text(
                                'Skor Kesehatan Anda',
                                style: TextStyle(
                                  color: c.muted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                riskLabel,
                                style: TextStyle(
                                  color: riskColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      riskDesc,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                    if (penalties.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Faktor yang Perlu Diperhatikan',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...penalties.map((penalty) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    penalty,
                                    style: TextStyle(
                                      color: c.text,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // AI Summary Section
              SegmentedPills(
                labels: const ['7 Hari', '14 Hari', '30 Hari'],
                selected: forecastIndex,
                onTap: onForecast,
                enabledIndices: enabledPillIndices,
              ),
              const SizedBox(height: 16),
              GradientPanel(
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
                    () {
                      final days = const [7, 14, 30][forecastIndex];
                      final isLoading = _loading[days] ?? false;
                      final errorMessage = _errors[days];
                      final summary = _summaries[days];

                      if (!hasData) {
                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 13),
                            Text(
                              'Belum ada penjelasan, harus isi data',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        );
                      }

                      if (isLoading) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 16, bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Mengambil penjelasan AI...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (errorMessage != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 13),
                            Text(
                              errorMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _fetchSummaryForIndex(forecastIndex),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Coba Lagi'),
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
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 13),
                          Text(
                            summary != null ? '"$summary"' : 'Tidak ada penjelasan AI.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      );
                    }(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Rekomendasi Section (Below AI Summary)
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
