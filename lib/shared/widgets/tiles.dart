import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

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
    required this.date,
    required this.score,
    required this.scoreColor,
    required this.scoreBg,
    required this.desc,
    this.last = false,
  });

  final String date;
  final String score;
  final Color scoreColor;
  final Color scoreBg;
  final String desc;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
                            date,
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
                            score,
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      desc,
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
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
