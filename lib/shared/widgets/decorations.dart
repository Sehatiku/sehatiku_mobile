import 'package:flutter/material.dart';
import 'package:sehatiku_mobile/core/core.dart';

/// Small solid status dot used inside badges and pills.
class Dot extends StatelessWidget {
  const Dot({super.key, required this.color, this.size = 9});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    required this.size,
    this.radius,
    this.onColor = false,
  });

  final double size;
  final double? radius;

  /// When true, renders the white logo mark on a frosted translucent badge —
  /// for use on coloured / gradient backgrounds. Otherwise renders the full
  /// colour logo on a solid white badge — for use on light surfaces.
  final bool onColor;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.28;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.15),
      decoration: onColor
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(r),
              border: Border.all(color: Colors.white.withValues(alpha: .4)),
            )
          : BoxDecoration(
              color: AppColors.of(context).elevated,
              borderRadius: BorderRadius.circular(r),
              border: Border.all(color: AppColors.of(context).line),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x40000000),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.08),
                ),
              ],
            ),
      child: Image.asset(
        onColor ? 'assets/images/logowhite.png' : 'assets/images/logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class SoftCircle extends StatelessWidget {
  const SoftCircle({super.key, required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

