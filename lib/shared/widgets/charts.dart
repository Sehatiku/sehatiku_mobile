import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.color,
    this.variant = 0,
    this.values,
  });

  final Color color;
  final int variant;

  /// Real metric values (oldest -> newest). When null or fewer than two points,
  /// a placeholder demo curve keyed by [variant] is drawn instead.
  final List<double>? values;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TrendPainter(color: color, variant: variant, values: values),
      child: const SizedBox.expand(),
    );
  }
}

class TrendPainter extends CustomPainter {
  TrendPainter({required this.color, required this.variant, this.values});

  final Color color;
  final int variant;
  final List<double>? values;

  /// Maps real metric values to top-fractions (0 = top, 1 = bottom), keeping the
  /// line within a comfortable vertical band.
  List<double> _fractions() {
    final sets = [
      [.78, .55, .62, .42, .48, .32, .28],
      [.45, .50, .40, .54, .44, .48, .38],
      [.58, .52, .56, .50, .46, .42, .40],
      [.72, .48, .40, .30, .24, .18, .14],
    ];
    final data = values;
    if (data == null || data.length < 2) {
      return sets[variant % sets.length];
    }
    final lo = data.reduce(math.min);
    final hi = data.reduce(math.max);
    final span = hi - lo;
    return data.map((v) {
      final norm = span == 0 ? 0.5 : (v - lo) / span;
      // Higher value -> higher on the chart (smaller fraction).
      return 0.82 - 0.64 * norm;
    }).toList();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final values = _fractions();
    final points = List.generate(values.length, (i) {
      return Offset(
        size.width * i / (values.length - 1),
        size.height * values[i],
      );
    });
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      path.cubicTo(p0.dx + 18, p0.dy, p1.dx - 18, p1.dy, p1.dx, p1.dy);
    }

    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .22), color.withValues(alpha: .02)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrendPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.variant != variant ||
        !_sameValues(oldDelegate.values, values);
  }

  static bool _sameValues(List<double>? a, List<double>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.progress,
    required this.color,
    required this.center,
    this.size = 120,
    this.stroke = 16,
    this.trackColor = const Color(0x33FFFFFF),
  });

  final double progress;
  final Color color;
  final Widget center;
  final double size;
  final double stroke;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0, 1),
          color: color,
          trackColor: trackColor,
          stroke: stroke,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..color = trackColor
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.stroke != stroke;
}


/// Placeholder shown inside a chart card when there aren't enough points yet.
class ChartEmpty extends StatelessWidget {
  const ChartEmpty({super.key});

  static const message = 'Butuh minimal 2 catatan untuk menampilkan grafik';

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.pale,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.show_chart_rounded,
            color: Color(0xFFB6C3D2),
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
