import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class InsightTile extends StatelessWidget {
  const InsightTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: 15,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      color: c.muted,
                      height: 1.45,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorTile extends StatelessWidget {
  const DoctorTile({
    super.key,
    required this.name,
    required this.role,
    required this.time,
    required this.color,
  });

  final String name;
  final String role;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(Icons.local_hospital_rounded, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(role, style: TextStyle(color: c.muted)),
                  const SizedBox(height: 7),
                  Text(
                    time,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class TimelineTile extends StatelessWidget {
  const TimelineTile({
    super.key,
    required this.title,
    required this.desc,
    required this.time,
  });

  final String title;
  final String desc;
  final String time;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.task_alt_rounded, color: AppColors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(color: c.muted, height: 1.4),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: c.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleTile extends StatelessWidget {
  const ArticleTile({
    super.key,
    required this.icon,
    required this.category,
    required this.title,
    required this.time,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String category;
  final String title;
  final String time;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AppCard(
          padding: 15,
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TextStyle(color: c.muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileRow extends StatelessWidget {
  const ProfileRow({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = AppColors.primary,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class RecommendTile extends StatelessWidget {
  const RecommendTile({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: c.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(color: c.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class RecommendCheck extends StatelessWidget {
  const RecommendCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.check_circle_rounded,
      color: AppColors.lime,
      size: 22,
    );
  }
}

class RecommendBadge extends StatelessWidget {
  const RecommendBadge({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
    );
  }
}

class NotifCard extends StatelessWidget {
  const NotifCard({
    super.key,
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.desc,
    required this.time,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String desc;
  final String time;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  color: color,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(21, 17, 17, 17),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.tint(color),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: c.text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                              Text(
                                time,
                                style: TextStyle(
                                  color: c.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            desc,
                            style: TextStyle(
                              color: c.muted,
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
        ),
      ),
    );
  }
}

class HistoryNode extends StatelessWidget {
  const HistoryNode({
    super.key,
    required this.record,
    this.last = false,
  });

  final HealthRecord record;
  final bool last;

  Widget _buildMetricChip(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? c.elevated : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? c.line : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: c.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: c.text,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scoreColor = record.statusColor;
    final scoreBg = record.statusBg;
    final scoreLabel = record.statusLabel;

    final chips = <Widget>[];

    // 1. Blood Sugar
    if (record.bloodSugar != null) {
      final tag = bloodSugarTagLabels[record.bloodSugarTag];
      final tagStr = tag != null ? ' ($tag)' : '';
      chips.add(_buildMetricChip(
        context,
        icon: Icons.water_drop_rounded,
        color: bloodSugarColor(record.bloodSugar),
        label: 'Gula: ',
        value: '${record.bloodSugar} mg/dL$tagStr',
      ));
    }

    // 2. Blood Pressure
    if (record.systolic != null && record.diastolic != null) {
      chips.add(_buildMetricChip(
        context,
        icon: Icons.favorite_rounded,
        color: bloodPressureColor(record.systolic, record.diastolic),
        label: 'TD: ',
        value: '${record.systolic}/${record.diastolic} mmHg',
      ));
    }

    // 3. Weight
    if (record.weight != null) {
      final w = record.weight!.toStringAsFixed(record.weight! % 1 == 0 ? 0 : 1);
      chips.add(_buildMetricChip(
        context,
        icon: Icons.scale_rounded,
        color: AppColors.primary,
        label: 'Berat: ',
        value: '$w kg',
      ));
    }

    // 4. Medicine
    final String medValue;
    if (record.medicineTaken) {
      if (record.medicineName.isNotEmpty) {
        final timeStr = record.medicineTime.isNotEmpty ? ' (${record.medicineTime})' : '';
        medValue = '${record.medicineName}$timeStr';
      } else {
        medValue = 'Tepat Waktu';
      }
    } else {
      medValue = 'Terlewat';
    }
    chips.add(_buildMetricChip(
      context,
      icon: Icons.medication_rounded,
      color: record.medicineTaken ? AppColors.green : AppColors.red,
      label: 'Obat: ',
      value: medValue,
    ));

    // 5. Activity
    if (record.active30 || record.activityMinutes > 0) {
      final actValue = record.activityType.isNotEmpty
          ? '${record.activityType} (${record.activityMinutes} mnt)'
          : '${record.activityMinutes} mnt';
      chips.add(_buildMetricChip(
        context,
        icon: Icons.directions_run_rounded,
        color: record.activityMinutes >= 30 ? AppColors.green : AppColors.orange,
        label: 'Aktivitas: ',
        value: actValue,
      ));
    }

    // 6. Sleep
    if (record.sleepHours != null) {
      final sh = record.sleepHours!.toStringAsFixed(record.sleepHours! % 1 == 0 ? 0 : 1);
      chips.add(_buildMetricChip(
        context,
        icon: Icons.bedtime_rounded,
        color: AppColors.violet,
        label: 'Tidur: ',
        value: '${sh}j',
      ));
    }

    // 7. Stress Level
    final stressLabel = record.stressIndex == 0
        ? 'Santai'
        : record.stressIndex == 2
            ? 'Tinggi'
            : 'Normal';
    final stressColor = record.stressIndex == 0
        ? AppColors.green
        : record.stressIndex == 2
            ? AppColors.red
            : AppColors.primary;
    final stressEmoji = record.stressIndex == 0
        ? '😌'
        : record.stressIndex == 2
            ? '😣'
            : '😐';
    chips.add(_buildMetricChip(
      context,
      icon: Icons.psychology_rounded,
      color: stressColor,
      label: 'Stres: ',
      value: '$stressEmoji $stressLabel',
    ));

    // 8. Smoking & Alcohol
    if (record.smoke) {
      chips.add(_buildMetricChip(
        context,
        icon: Icons.smoking_rooms_rounded,
        color: AppColors.orange,
        label: 'Merokok: ',
        value: 'Ya',
      ));
    }
    if (record.alcohol) {
      chips.add(_buildMetricChip(
        context,
        icon: Icons.local_bar_rounded,
        color: AppColors.orange,
        label: 'Alkohol: ',
        value: 'Ya',
      ));
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 20),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: scoreColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.background, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor,
                      blurRadius: 0,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 2, color: c.line),
                ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: AppCard(
                padding: 17,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            formatLongDate(record.date),
                            style: TextStyle(
                              color: c.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: scoreBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Skor ${record.score} • $scoreLabel',
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chips,
                    ),
                    if (record.note.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? c.background.withValues(alpha: 0.3)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? c.line.withValues(alpha: 0.5)
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.sticky_note_2_rounded,
                              size: 16,
                              color: c.muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                record.note,
                                style: TextStyle(
                                  color: c.text.withValues(alpha: 0.85),
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

