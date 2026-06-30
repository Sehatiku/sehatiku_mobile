import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

import 'package:sehatiku_mobile/data/models/baseline_entry.dart';
import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
import 'package:sehatiku_mobile/data/services/dashboard_service.dart';
import 'package:sehatiku_mobile/data/services/record_service.dart';
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

class ProgressScreen extends StatefulWidget {
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
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _syncHistory();
  }

  @override
  void didUpdateWidget(ProgressScreen old) {
    super.didUpdateWidget(old);
    if (old.rangeIndex != widget.rangeIndex) {
      _syncHistory();
    }
  }

  Future<void> _syncHistory() async {
    // API max is 90; map rangeIndex → limit (week=7, month=30, year=90).
    final limit = const [7, 30, 90][widget.rangeIndex];
    if (!mounted) return;
    setState(() => _syncing = true);
    try {
      final entries = await RecordService.instance.fetchHistory(limit: limit);
      if (mounted) await HealthScope.of(context).mergeHistory(entries);

      final baselines = await RecordService.instance.fetchBaselineHistory();
      if (mounted) await HealthScope.of(context).mergeBaselineHistory(baselines);
    } catch (_) {
      // Show whatever local data is available if the fetch fails.
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = HealthScope.of(context);
    
    if (widget.progressIndex == 4) {
      return _buildBaselineView(store);
    }

    final count = const [7, 30, 365][widget.rangeIndex];
    final recs = store.recent(count);
    final metric = _metricFor(widget.progressIndex, recs);
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
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: PillTab(
                      label: const [
                        'Gula Darah',
                        'Tekanan Darah',
                        'Berat Badan',
                        'Kepatuhan Obat',
                        'Baseline',
                      ][i],
                      selected: widget.progressIndex == i,
                      onTap: () => widget.onProgress(i),
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
                Column(
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
                const SizedBox(height: 16),
                SizedBox(
                  height: 170,
                  child: _syncing && !hasChart
                      ? Center(
                          child: CircularProgressIndicator(
                            color: color,
                            strokeWidth: 2.5,
                          ),
                        )
                      : hasChart
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
        ],
      ),
    );
  }

  Widget _buildBaselineView(HealthStore store) {
    final baselines = store.baselineHistory;
    final hasBaselines = baselines.isNotEmpty;

    // Determine disease type to show the most relevant trend chart
    final profile = DashboardService.instance.cachedDashboard?.profile;
    final disease = profile?.diseaseType ?? 'both';

    List<double> chartValues = [];
    String chartTitle = '';
    Color chartColor = AppColors.primary;

    if (disease == 'hypertension') {
      chartValues = baselines
          .where((e) => e.systolic != null)
          .map((e) => e.systolic!.toDouble())
          .toList()
          .reversed
          .toList();
      chartTitle = 'Baseline Tekanan Darah (Sistolik)';
      chartColor = AppColors.pink;
    } else {
      chartValues = baselines
          .where((e) => e.bloodSugar != null)
          .map((e) => e.bloodSugar!.toDouble())
          .toList()
          .reversed
          .toList();
      chartTitle = 'Baseline Gula Darah';
      chartColor = AppColors.primary;
    }

    final hasChart = chartValues.length >= 2;

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
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: PillTab(
                      label: const [
                        'Gula Darah',
                        'Tekanan Darah',
                        'Berat Badan',
                        'Kepatuhan Obat',
                        'Baseline',
                      ][i],
                      selected: widget.progressIndex == i,
                      onTap: () => widget.onProgress(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!hasBaselines) ...[
            const AppCard(
              padding: 24,
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_ind_rounded,
                      size: 48,
                      color: Color(0xFFB6C3D2),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Belum Ada Baseline Klinis',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Hubungi fasilitas kesehatan Anda untuk menetapkan baseline klinis pertama Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            _buildLatestBaselineCard(baselines.first),
            const SizedBox(height: 16),
            AppCard(
              padding: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$chartTitle · Riwayat Tren',
                    style: TextStyle(
                      color: AppColors.of(context).muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 170,
                    child: _syncing && !hasChart
                        ? Center(
                            child: CircularProgressIndicator(
                              color: chartColor,
                              strokeWidth: 2.5,
                            ),
                          )
                        : hasChart
                            ? TrendChart(color: chartColor, values: chartValues)
                            : const ChartEmpty(),
                  ),
                  const SizedBox(height: 8),
                  if (hasChart)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatShortDate(chartValues.isEmpty ? DateTime.now() : baselines.last.date),
                          style: const TextStyle(
                            color: Color(0xFF9AA9BB),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          formatShortDate(chartValues.isEmpty ? DateTime.now() : baselines.first.date),
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
            const SizedBox(height: 20),
            Text(
              'Riwayat Baseline',
              style: TextStyle(
                color: AppColors.of(context).text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: baselines.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = baselines[index];
                return AppCard(
                  padding: 16,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.tint(AppColors.primary),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.analytics_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatLongDate(entry.date),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                if (entry.bloodSugar != null)
                                  _buildBaselineSmallStat(
                                    'Gula Darah:',
                                    '${entry.bloodSugar} mg/dL',
                                  ),
                                if (entry.systolic != null && entry.diastolic != null)
                                  _buildBaselineSmallStat(
                                    'TD:',
                                    '${entry.systolic}/${entry.diastolic} mmHg',
                                  ),
                                if (entry.weight != null)
                                  _buildBaselineSmallStat(
                                    'Berat:',
                                    '${entry.weight} kg',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLatestBaselineCard(BaselineEntry entry) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Baseline Aktif Saat Ini',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ditetapkan pada ${formatLongDate(entry.date)}',
            style: TextStyle(
              color: AppColors.of(context).muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (entry.bloodSugar != null)
                _buildLatestBaselineItem(
                  icon: Icons.water_drop_rounded,
                  color: AppColors.primary,
                  label: 'Gula Darah',
                  value: '${entry.bloodSugar}',
                  unit: 'mg/dL',
                ),
              if (entry.systolic != null && entry.diastolic != null)
                _buildLatestBaselineItem(
                  icon: Icons.monitor_heart_rounded,
                  color: AppColors.pink,
                  label: 'Tekanan Darah',
                  value: '${entry.systolic}/${entry.diastolic}',
                  unit: 'mmHg',
                ),
              if (entry.weight != null)
                _buildLatestBaselineItem(
                  icon: Icons.scale_rounded,
                  color: AppColors.violet,
                  label: 'Berat Badan',
                  value: '${entry.weight}',
                  unit: 'kg',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestBaselineItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.tint(color),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.of(context).muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.of(context).text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: AppColors.of(context).muted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBaselineSmallStat(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.of(context).muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.of(context).text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

