import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class _ProgressMetric {
  _ProgressMetric({
    required this.name,
    required this.color,
    required this.records,
    required this.values,
    required this.averageText,
    required this.highText,
    required this.lowText,
    required this.lowerIsBetter,
  });

  final String name;
  final Color color;
  final List<HealthRecord> records;
  final List<double> values;
  final String averageText;
  final String highText;
  final String lowText;
  final bool lowerIsBetter;

  String insight(TrendInfo t, bool hasChart) {
    if (!hasChart) {
      return 'Tambahkan minimal 2 catatan $name untuk melihat analisis tren otomatis.';
    }
    if (t.label == 'Stabil') {
      return '$name Anda relatif stabil dalam ${records.length} catatan terakhir. Pertahankan rutinitas Anda.';
    }
    final good = t.color == AppColors.green;
    final dir = t.label.toLowerCase();
    return good
        ? '$name Anda $dir ke arah yang baik. Konsistensi Anda membuahkan hasil.'
        : '$name Anda $dir. Perhatikan kembali pola makan, aktivitas, dan obat Anda.';
  }
}

_ProgressMetric _metricFor(int index, List<HealthRecord> recs) {
  switch (index) {
    case 1:
      final rs = recs
          .where((r) => r.systolic != null && r.diastolic != null)
          .toList();
      final sys = rs.map((r) => r.systolic!.toDouble()).toList();
      final dia = rs.map((r) => r.diastolic!.toDouble()).toList();
      return _ProgressMetric(
        name: 'Tekanan Darah',
        color: AppColors.pink,
        records: rs,
        values: sys,
        lowerIsBetter: true,
        averageText: rs.isEmpty
            ? '—'
            : '${average(sys).round()}/${average(dia).round()}',
        highText: sys.isEmpty ? '—' : '${sys.reduce(math.max).round()}',
        lowText: sys.isEmpty ? '—' : '${sys.reduce(math.min).round()}',
      );
    case 2:
      final rs = recs.where((r) => r.weight != null).toList();
      final vals = rs.map((r) => r.weight!).toList();
      return _ProgressMetric(
        name: 'Berat Badan',
        color: AppColors.violet,
        records: rs,
        values: vals,
        lowerIsBetter: false,
        averageText: vals.isEmpty ? '—' : '${average(vals).toStringAsFixed(1)} kg',
        highText: vals.isEmpty ? '—' : vals.reduce(math.max).toStringAsFixed(1),
        lowText: vals.isEmpty ? '—' : vals.reduce(math.min).toStringAsFixed(1),
      );
    case 3:
      final rs = recs.toList();
      final vals = rs.map((r) => r.medicineTaken ? 100.0 : 0.0).toList();
      final taken = rs.where((r) => r.medicineTaken).length;
      return _ProgressMetric(
        name: 'Kepatuhan Obat',
        color: AppColors.green,
        records: rs,
        values: vals,
        lowerIsBetter: false,
        averageText: vals.isEmpty ? '—' : '${average(vals).round()}%',
        highText: rs.isEmpty ? '—' : '$taken hari',
        lowText: rs.isEmpty ? '—' : '${rs.length - taken} hari',
      );
    default:
      final rs = recs.where((r) => r.bloodSugar != null).toList();
      final vals = rs.map((r) => r.bloodSugar!.toDouble()).toList();
      return _ProgressMetric(
        name: 'Gula Darah',
        color: AppColors.primary,
        records: rs,
        values: vals,
        lowerIsBetter: true,
        averageText: vals.isEmpty ? '—' : '${average(vals).round()} mg/dL',
        highText: vals.isEmpty ? '—' : '${vals.reduce(math.max).round()}',
        lowText: vals.isEmpty ? '—' : '${vals.reduce(math.min).round()}',
      );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({
    super.key,
    required this.progressIndex,
    required this.rangeIndex,
    required this.onProgress,
    required this.onRange,
  });

  final int progressIndex;
  final int rangeIndex;
  final ValueChanged<int> onProgress;
  final ValueChanged<int> onRange;

  @override
  Widget build(BuildContext context) {
    final store = HealthScope.of(context);
    final count = const [7, 30, 365][rangeIndex];
    final recs = store.recent(count);
    final metric = _metricFor(progressIndex, recs);
    final color = metric.color;
    final values = metric.values;
    final hasChart = values.length >= 2;
    final trend = trendInfo(values, lowerIsBetter: metric.lowerIsBetter);
    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            title: 'Progres Kesehatan',
            subtitle: 'Pantau tren Anda dari waktu ke waktu',
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: PillTab(
                      label: const [
                        'Gula Darah',
                        'Tekanan Darah',
                        'Berat Badan',
                        'Kepatuhan Obat',
                      ][i],
                      selected: progressIndex == i,
                      onTap: () => onProgress(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            padding: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${metric.name} · Rata-rata',
                            style: TextStyle(
                              color: AppColors.of(context).muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metric.averageText,
                            style: TextStyle(
                              color: AppColors.of(context).text,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SegmentedMini(
                      labels: const ['Minggu', 'Bulan', 'Tahun'],
                      selected: rangeIndex,
                      onTap: onRange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 170,
                  child: hasChart
                      ? TrendChart(color: color, values: values)
                      : const ChartEmpty(),
                ),
                const SizedBox(height: 8),
                if (hasChart)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatShortDate(metric.records.first.date),
                        style: const TextStyle(
                          color: Color(0xFF9AA9BB),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatShortDate(metric.records.last.date),
                        style: const TextStyle(
                          color: Color(0xFF9AA9BB),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 13,
            crossAxisSpacing: 13,
            childAspectRatio: 1.9,
            children: [
              StatBox(
                label: 'Tertinggi',
                value: metric.highText,
                color: AppColors.pink,
              ),
              StatBox(
                label: 'Terendah',
                value: metric.lowText,
                color: AppColors.green,
              ),
              StatBox(
                label: 'Rata-rata',
                value: metric.averageText,
                color: AppColors.primary,
              ),
              StatBox(
                label: 'Tren',
                value: hasChart ? trend.label : '—',
                color: hasChart ? trend.color : AppColors.of(context).muted,
                icon: hasChart ? trend.icon : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  AppColors.of(context).surface,
                  AppColors.of(context).elevated,
                ],
              ),
              border: Border.all(
                color: AppColors.of(context).line,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: const LinearGradient(
                      colors: [AppColors.violet, AppColors.cyan],
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analisis AI',
                        style: TextStyle(
                          color: AppColors.violet,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.insight(trend, hasChart),
                        style: TextStyle(
                          color: AppColors.of(context).text,
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
        ],
      ),
    );
  }
}

