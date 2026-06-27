import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

import 'package:sehatiku_mobile/features/onboarding/onboarding_item.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.index,
    required this.onDot,
    required this.onSkip,
    required this.onNext,
  });

  final int index;
  final ValueChanged<int> onDot;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  static const items = [
    OnboardingItem(
      icon: Icons.insert_chart_rounded,
      title: 'Pantau Kesehatan Lebih Mudah',
      desc:
          'Catat gula darah, tekanan, dan obat harian Anda dalam satu tempat yang rapi dan jelas.',
      colors: [AppColors.primary, AppColors.cyan],
      blob: Color(0xFFBCDFFF),
    ),
    OnboardingItem(
      icon: Icons.psychology_alt_rounded,
      title: 'AI Membantu Memahami Kondisi Anda',
      desc:
          'Dapatkan analisis dan rekomendasi personal berbasis Machine Learning setiap hari.',
      colors: [AppColors.violet, AppColors.cyan],
      blob: Color(0xFFDCD2FF),
    ),
    OnboardingItem(
      icon: Icons.spa_rounded,
      title: 'Mulai Hidup Lebih Sehat Hari Ini',
      desc:
          'Bangun kebiasaan sehat dengan pengingat lembut dan pendampingan menyeluruh.',
      colors: [AppColors.green, AppColors.lime],
      blob: Color(0xFFBFF0DF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final item = items[index];
    final compact = MediaQuery.sizeOf(context).height < 700;
    final visualSize = compact ? 196.0 : 248.0;
    final cardSize = compact ? 150.0 : 188.0;
    final cardRadius = compact ? 36.0 : 46.0;
    final iconSize = compact ? 76.0 : 96.0;
    return SafeArea(
      key: const ValueKey('onboarding'),
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, compact ? 8 : 18, 28, 28),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onSkip, child: const Text('Lewati')),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: visualSize,
                        height: visualSize,
                        decoration: BoxDecoration(
                          color: item.blob.withValues(alpha: .5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Transform.rotate(
                        angle: -math.pi / 30,
                        child: Container(
                          width: cardSize,
                          height: cardSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(cardRadius),
                            gradient: LinearGradient(colors: item.colors),
                            boxShadow: [
                              BoxShadow(
                                color: item.colors.first.withValues(alpha: .35),
                                blurRadius: 54,
                                offset: const Offset(0, 24),
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: math.pi / 30,
                            child: Icon(
                              item.icon,
                              color: Colors.white,
                              size: iconSize,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 22 : 44),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.of(context).text,
                      fontSize: compact ? 24 : 27,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  Text(
                    item.desc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.of(context).muted,
                      fontSize: compact ? 14 : 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                items.length,
                (i) => GestureDetector(
                  onTap: () => onDot(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: index == i ? 26 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == i
                          ? AppColors.primary
                          : AppColors.of(context).line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 18 : 28),
            PrimaryButton(
              label: index < 2 ? 'Lanjut' : 'Mulai Sekarang',
              icon: Icons.arrow_forward_rounded,
              onPressed: onNext,
            ),
            if (index == 2)
              TextButton(
                onPressed: onSkip,
                child: const Text(
                  'Masuk',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
