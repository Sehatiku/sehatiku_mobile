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
    this.unit = '',
  });

  final String name;
  final Color color;
  final List<HealthRecord> records;
  final List<double> values;
  final String averageText;
  final String highText;
  final String lowText;
  final bool lowerIsBetter;
  final String unit;

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
    case 2:
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
        unit: 'mmHg',
      );
    case 3:
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
        unit: 'kg',
      );
    case 4:
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
        unit: '%',
      );
    case 1:
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
        unit: 'mg/dL',
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

  Color _tabColor(int index) {
    return const [
      AppColors.primary, // Baseline
      AppColors.primary, // Gula Darah
      AppColors.pink,    // Tekanan Darah
      AppColors.violet,  // Berat Badan
      AppColors.green,   // Kepatuhan Obat
    ][index];
  }

  Widget _buildCustomTabBar(BuildContext context) {
    final colors = AppColors.of(context);
    final tabs = const [
      'Baseline',
      'Gula Darah',
      'Tekanan Darah',
      'Berat Badan',
      'Kepatuhan Obat',
    ];
    final icons = const [
      Icons.assignment_ind_rounded,
      Icons.water_drop_rounded,
      Icons.monitor_heart_rounded,
      Icons.scale_rounded,
      Icons.medication_rounded,
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        itemBuilder: (context, i) {
          final isSelected = widget.progressIndex == i;
          final color = _tabColor(i);
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onProgress(i),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? color.withValues(alpha: 0.12) 
                      : colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                        ? color.withValues(alpha: 0.45) 
                        : colors.line,
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[i],
                        size: 15,
                        color: isSelected ? color : colors.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tabs[i],
                        style: TextStyle(
                          color: isSelected ? color : colors.text,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final store = HealthScope.of(context);
    
    final Widget view;
    if (widget.progressIndex == 0) {
      view = _buildBaselineView(store);
    } else {
      final count = const [7, 30, 365][widget.rangeIndex];
      final recs = store.recent(count);
      final metric = _metricFor(widget.progressIndex, recs);
      final color = metric.color;
      final values = metric.values;
      final hasChart = values.length >= 2;
      final trend = trendInfo(values, lowerIsBetter: metric.lowerIsBetter);
      view = AppScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              title: 'Progres Kesehatan',
              subtitle: 'Pantau tren Anda dari waktu ke waktu',
            ),
            const SizedBox(height: 18),
            _buildCustomTabBar(context),
            const SizedBox(height: 18),
            AppCard(
              padding: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      _RangeSelector(
                        selectedIndex: widget.rangeIndex,
                        onChanged: widget.onRange,
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
                            ? TrendChart(
                                color: color,
                                values: values,
                                dates: metric.records.map((r) => r.date).toList(),
                                unit: metric.unit,
                              )
                            : _CreativeChartEmpty(color: color),
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
              childAspectRatio: 1.5,
              children: [
                _ProgressStatCard(
                  label: 'Tertinggi',
                  value: metric.highText,
                  color: AppColors.pink,
                  icon: Icons.trending_up_rounded,
                  metricIndex: widget.progressIndex,
                ),
                _ProgressStatCard(
                  label: 'Terendah',
                  value: metric.lowText,
                  color: AppColors.green,
                  icon: Icons.trending_down_rounded,
                  metricIndex: widget.progressIndex,
                ),
                _ProgressStatCard(
                  label: 'Rata-rata',
                  value: metric.averageText,
                  color: AppColors.primary,
                  icon: Icons.functions_rounded,
                  metricIndex: widget.progressIndex,
                ),
                _ProgressStatCard(
                  label: 'Tren',
                  value: hasChart ? trend.label : '—',
                  color: hasChart ? trend.color : AppColors.of(context).muted,
                  icon: hasChart ? trend.icon : Icons.timeline_rounded,
                  metricIndex: widget.progressIndex,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _syncHistory,
      child: view,
    );
  }

  Widget _buildBaselineView(HealthStore store) {
    final baselines = store.baselineHistory;
    final hasBaselines = baselines.isNotEmpty;

    // Determine disease type to show the most relevant trend chart
    final profile = DashboardService.instance.cachedDashboard?.profile;
    final disease = profile?.diseaseType ?? 'both';

    List<double> chartValues = [];
    List<DateTime> chartDates = [];
    String chartTitle = '';
    Color chartColor = AppColors.primary;

    if (disease == 'hypertension') {
      chartValues = baselines
          .where((e) => e.systolic != null)
          .map((e) => e.systolic!.toDouble())
          .toList()
          .reversed
          .toList();
      chartDates = baselines
          .where((e) => e.systolic != null)
          .map((e) => e.date)
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
      chartDates = baselines
          .where((e) => e.bloodSugar != null)
          .map((e) => e.date)
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
          _buildCustomTabBar(context),
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
                            ? TrendChart(
                                color: chartColor,
                                values: chartValues,
                                dates: chartDates,
                                unit: disease == 'hypertension' ? 'mmHg' : 'mg/dL',
                              )
                            : _CreativeChartEmpty(color: chartColor),
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
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: baselines.length,
              itemBuilder: (context, index) {
                final entry = baselines[index];
                final isLatest = index == 0;
                final isLast = index == baselines.length - 1;
                
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 20,
                              bottom: 0,
                              child: Container(
                                width: 2,
                                color: isLast 
                                  ? Colors.transparent 
                                  : AppColors.of(context).line,
                              ),
                            ),
                            Positioned(
                              top: 14,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isLatest ? AppColors.primary : AppColors.of(context).muted.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                  border: isLatest ? Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    width: 4,
                                    strokeAlign: BorderSide.strokeAlignOutside,
                                  ) : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () => _showBaselineDetail(entry),
                            borderRadius: BorderRadius.circular(22),
                            child: AppCard(
                              padding: 16,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              formatLongDate(entry.date),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            if (isLatest)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'Terbaru',
                                                  style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 6,
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
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.of(context).muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
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
        color: c.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Baseline Aktif Saat Ini',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              'Ditetapkan pada ${formatLongDate(entry.date)}',
              style: TextStyle(
                color: AppColors.of(context).muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line.withValues(alpha: 0.5)),
            ),
            child: Row(
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
            color: color.withValues(alpha: 0.1),
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

  String _translateBmi(String? category) {
    if (category == null) return '—';
    return switch (category.toLowerCase()) {
      'underweight' => 'Berat Badan Kurang',
      'normal' => 'Normal',
      'overweight' => 'Kelebihan Berat Badan',
      'obese' => 'Obesitas',
      _ => category,
    };
  }

  Color _colorForBmi(String? category) {
    if (category == null) return AppColors.primary;
    return switch (category.toLowerCase()) {
      'normal' => AppColors.green,
      'overweight' => AppColors.amber,
      'underweight' || 'obese' => AppColors.red,
      _ => AppColors.primary,
    };
  }

  String _translateHypertension(String? status) {
    if (status == null) return '—';
    return switch (status.toLowerCase()) {
      'normal' => 'Normal',
      'prehypertension' => 'Prehipertensi',
      'stage1' => 'Hipertensi Derajat 1',
      'stage2' => 'Hipertensi Derajat 2',
      'crisis' => 'Krisis Hipertensi',
      _ => status,
    };
  }

  Color _colorForHypertension(String? status) {
    if (status == null) return AppColors.primary;
    return switch (status.toLowerCase()) {
      'normal' => AppColors.green,
      'prehypertension' => AppColors.amber,
      'stage1' || 'stage2' || 'crisis' => AppColors.red,
      _ => AppColors.primary,
    };
  }

  String _translateDiabetes(String? status) {
    if (status == null) return '—';
    return switch (status.toLowerCase()) {
      'normal' => 'Normal',
      'prediabetes' => 'Prediabetes',
      'controlled' => 'Terkontrol',
      'uncontrolled' => 'Tidak Terkontrol',
      _ => status,
    };
  }

  Color _colorForDiabetes(String? status) {
    if (status == null) return AppColors.primary;
    return switch (status.toLowerCase()) {
      'normal' || 'controlled' => AppColors.green,
      'prediabetes' => AppColors.amber,
      'uncontrolled' => AppColors.red,
      _ => AppColors.primary,
    };
  }

  String _translateCvd(String? category) {
    if (category == null) return '—';
    return switch (category.toLowerCase()) {
      'low' => 'Rendah',
      'moderate' => 'Sedang',
      'high' => 'Tinggi',
      'very_high' => 'Sangat Tinggi',
      _ => category,
    };
  }

  Color _colorForCvd(String? category) {
    if (category == null) return AppColors.primary;
    return switch (category.toLowerCase()) {
      'low' => AppColors.green,
      'moderate' => AppColors.amber,
      'high' || 'very_high' => AppColors.red,
      _ => AppColors.primary,
    };
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tint(color, 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext ctx, String label, String value, {Widget? badge}) {
    final c = AppColors.of(ctx);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: c.muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                badge,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCategoryCard(
    BuildContext ctx, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final c = AppColors.of(ctx);
    return AppCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: c.line, height: 1),
          const SizedBox(height: 4),
          ...items,
        ],
      ),
    );
  }

  void _showBaselineDetail(BaselineEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = AppColors.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 30,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Baseline Klinis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatLongDate(entry.date),
                          style: TextStyle(
                            color: c.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: c.muted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              if (entry.recordedByNakesName != null && entry.recordedByNakesName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 14, color: c.muted),
                    const SizedBox(width: 6),
                    Text(
                      'Pemeriksa: ${entry.recordedByNakesName}',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.notes != null && entry.notes!.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.tint(AppColors.primary, 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.tint(AppColors.primary, 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catatan Pemeriksa',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.notes!,
                                style: TextStyle(
                                  color: c.text,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildDetailCategoryCard(
                        ctx,
                        title: 'Antropometri & Tanda Vital',
                        icon: Icons.monitor_heart_rounded,
                        iconColor: AppColors.pink,
                        items: [
                          if (entry.bmi != null)
                            _buildDetailRow(
                              ctx,
                              'Indeks Massa Tubuh (BMI)',
                              '${entry.bmi}',
                              badge: _buildStatusBadge(
                                _translateBmi(entry.bmiCategory),
                                _colorForBmi(entry.bmiCategory),
                              ),
                            ),
                          if (entry.systolic != null && entry.diastolic != null)
                            _buildDetailRow(
                              ctx,
                              'Tekanan Darah',
                              '${entry.systolic}/${entry.diastolic} mmHg',
                              badge: _buildStatusBadge(
                                _translateHypertension(entry.hypertensionStatus),
                                _colorForHypertension(entry.hypertensionStatus),
                              ),
                            ),
                          if (entry.weight != null)
                            _buildDetailRow(
                              ctx,
                              'Berat Badan',
                              '${entry.weight} kg',
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildDetailCategoryCard(
                        ctx,
                        title: 'Metabolik & Gula Darah',
                        icon: Icons.water_drop_rounded,
                        iconColor: AppColors.primary,
                        items: [
                          if (entry.bloodSugar != null)
                            _buildDetailRow(
                              ctx,
                              'Gula Darah Puasa',
                              '${entry.bloodSugar} mg/dL',
                              badge: _buildStatusBadge(
                                _translateDiabetes(entry.diabetesStatus),
                                _colorForDiabetes(entry.diabetesStatus),
                              ),
                            ),
                          if (entry.hba1cPct != null)
                            _buildDetailRow(
                              ctx,
                              'HbA1c',
                              '${entry.hba1cPct}%',
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildDetailCategoryCard(
                        ctx,
                        title: 'Profil Lipid (Kolesterol)',
                        icon: Icons.analytics_rounded,
                        iconColor: AppColors.violet,
                        items: [
                          if (entry.totalCholesterolMgdl != null)
                            _buildDetailRow(
                              ctx,
                              'Total Kolesterol',
                              '${entry.totalCholesterolMgdl} mg/dL',
                            ),
                          if (entry.ldlMgdl != null)
                            _buildDetailRow(
                              ctx,
                              'LDL (Kolesterol Jahat)',
                              '${entry.ldlMgdl} mg/dL',
                            ),
                          if (entry.hdlMgdl != null)
                            _buildDetailRow(
                              ctx,
                              'HDL (Kolesterol Baik)',
                              '${entry.hdlMgdl} mg/dL',
                            ),
                          if (entry.triglyceridesMgdl != null)
                            _buildDetailRow(
                              ctx,
                              'Trigliserida',
                              '${entry.triglyceridesMgdl} mg/dL',
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildDetailCategoryCard(
                        ctx,
                        title: 'Risiko Kardiovaskular (CVD)',
                        icon: Icons.speed_rounded,
                        iconColor: AppColors.orange,
                        items: [
                          if (entry.cvdRisk10yrPct != null)
                            _buildDetailRow(
                              ctx,
                              'Skor Risiko 10-Tahun',
                              '${entry.cvdRisk10yrPct}%',
                              badge: _buildStatusBadge(
                                _translateCvd(entry.cvdRiskCategory),
                                _colorForCvd(entry.cvdRiskCategory),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildDetailCategoryCard(
                        ctx,
                        title: 'Fungsi Ginjal',
                        icon: Icons.health_and_safety_rounded,
                        iconColor: AppColors.green,
                        items: [
                          if (entry.egfr != null)
                            _buildDetailRow(
                              ctx,
                              'eGFR',
                              '${entry.egfr} mL/min/1.73m²',
                            ),
                          if (entry.uacr != null)
                            _buildDetailRow(
                              ctx,
                              'UACR',
                              '${entry.uacr} mg/g',
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Creative Custom Widgets for Health Progress Screen
// ─────────────────────────────────────────────────────────────────────────────

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.line),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selectedIndex == i ? colors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selectedIndex == i
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  const ['7 Hari', '30 Hari', 'Semua'][i],
                  style: TextStyle(
                    color: selectedIndex == i ? colors.text : colors.muted,
                    fontSize: 11,
                    fontWeight: selectedIndex == i ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressStatCard extends StatelessWidget {
  const _ProgressStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.metricIndex = 1,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final int metricIndex;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    // Parse value and unit dynamically to look extremely neat
    String displayValue = value;
    String? displayUnit;
    
    if (value != '—') {
      if (value.endsWith(' mg/dL')) {
        displayValue = value.replaceAll(' mg/dL', '');
        displayUnit = 'mg/dL';
      } else if (value.endsWith(' kg')) {
        displayValue = value.replaceAll(' kg', '');
        displayUnit = 'kg';
      } else if (value.endsWith('%')) {
        displayValue = value.replaceAll('%', '');
        displayUnit = '%';
      } else if (value.endsWith(' hari')) {
        displayValue = value.replaceAll(' hari', '');
        displayUnit = 'hari';
      } else {
        // Appends units for raw numbers
        if (label != 'Tren') {
          if (metricIndex == 1) displayUnit = 'mg/dL';
          if (metricIndex == 2) displayUnit = 'mmHg';
          if (metricIndex == 3) displayUnit = 'kg';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  displayValue,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                if (displayUnit != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    displayUnit,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreativeChartEmpty extends StatelessWidget {
  const _CreativeChartEmpty({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.elevated.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GhostChartPainter(color: color),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.1),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Butuh Catatan Tambahan',
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Butuh minimal 2 catatan untuk menampilkan grafik tren harian Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
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

class _GhostChartPainter extends CustomPainter {
  const _GhostChartPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final w = size.width;
    final h = size.height;

    // Draw horizontal grid lines
    paint.color = color.withValues(alpha: 0.06);
    for (var i = 1; i <= 3; i++) {
      final y = h * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }

    // Draw vertical dotted line grid
    for (var i = 1; i <= 6; i++) {
      final x = w * (i / 7);
      _drawDottedLine(canvas, Offset(x, 0), Offset(x, h), color.withValues(alpha: 0.04));
    }

    // Draw curvy dashed ghost chart line
    final path = Path();
    path.moveTo(0, h * 0.7);
    path.cubicTo(w * 0.2, h * 0.8, w * 0.3, h * 0.2, w * 0.5, h * 0.5);
    path.cubicTo(w * 0.7, h * 0.8, w * 0.85, h * 0.25, w, h * 0.4);

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, path, linePaint);
  }

  void _drawDottedLine(Canvas canvas, Offset p1, Offset p2, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    const double dashHeight = 4, dashSpace = 4;
    double startY = p1.dy;
    while (startY < p2.dy) {
      canvas.drawLine(Offset(p1.dx, startY), Offset(p1.dx, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      const double dashLength = 8.0;
      const double spaceLength = 6.0;
      while (distance < pathMetric.length) {
        final length = math.min(dashLength, pathMetric.length - distance);
        final extract = pathMetric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashLength + spaceLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GhostChartPainter oldDelegate) => oldDelegate.color != color;
}

