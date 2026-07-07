import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

class TrendChart extends StatefulWidget {
  const TrendChart({
    super.key,
    required this.color,
    this.variant = 0,
    this.values,
    this.dates,
    this.unit = '',
  });

  final Color color;
  final int variant;
  final List<double>? values;
  final List<DateTime>? dates;
  final String unit;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _selectedIndex;

  void _handleTouch(Offset localPosition, double width, int dataLength) {
    if (width <= 0 || dataLength < 2) return;
    final fraction = localPosition.dx / width;
    final index = (fraction * (dataLength - 1)).round().clamp(0, dataLength - 1);
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final data = widget.values;
    final hasData = data != null && data.length >= 2;

    if (!hasData) {
      return CustomPaint(
        painter: TrendPainter(
          color: widget.color,
          gridColor: colors.line,
          variant: widget.variant,
          values: widget.values,
          dates: widget.dates,
          unit: widget.unit,
          selectedIndex: null,
          textColor: colors.text,
          mutedColor: colors.muted,
        ),
        child: const SizedBox.expand(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onPanStart: (details) => _handleTouch(details.localPosition, width, data.length),
          onPanUpdate: (details) => _handleTouch(details.localPosition, width, data.length),
          onPanEnd: (_) => setState(() => _selectedIndex = null),
          onPanCancel: () => setState(() => _selectedIndex = null),
          onTapDown: (details) => _handleTouch(details.localPosition, width, data.length),
          onTapUp: (_) => setState(() => _selectedIndex = null),
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: TrendPainter(
              color: widget.color,
              gridColor: colors.line,
              variant: widget.variant,
              values: widget.values,
              dates: widget.dates,
              unit: widget.unit,
              selectedIndex: _selectedIndex,
              textColor: colors.text,
              mutedColor: colors.muted,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class TrendPainter extends CustomPainter {
  TrendPainter({
    required this.color,
    required this.gridColor,
    required this.variant,
    required this.textColor,
    required this.mutedColor,
    this.values,
    this.dates,
    this.unit = '',
    this.selectedIndex,
  });

  final Color color;
  final Color gridColor;
  final int variant;
  final List<double>? values;
  final List<DateTime>? dates;
  final String unit;
  final int? selectedIndex;
  final Color textColor;
  final Color mutedColor;

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

  String _formatTooltipDate(DateTime d) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw extremely subtle grid lines
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final fractions = _fractions();
    final points = List.generate(fractions.length, (i) {
      return Offset(
        size.width * i / (fractions.length - 1),
        size.height * fractions[i],
      );
    });

    if (points.isEmpty) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final dx = p1.dx - p0.dx;
      path.cubicTo(
        p0.dx + dx / 3,
        p0.dy,
        p1.dx - dx / 3,
        p1.dy,
        p1.dx,
        p1.dy,
      );
    }

    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Premium subtle gradient fill
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .28), color.withValues(alpha: .0)],
        ).createShader(Offset.zero & size),
    );

    // Thick glowing main curve line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Only draw normal dots if there are fewer than 15 data points, or if hovered.
    if (points.length < 15) {
      for (var i = 0; i < points.length; i++) {
        if (i == selectedIndex) continue;
        final point = points[i];
        canvas.drawCircle(point, 4.5, Paint()..color = Colors.white);
        canvas.drawCircle(
          point,
          4.5,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }

    // Draw active hovered/dragged state
    if (selectedIndex != null && selectedIndex! < points.length) {
      final selectedPoint = points[selectedIndex!];
      
      // Draw vertical guide line
      final cursorPaint = Paint()
        ..color = color.withValues(alpha: 0.18)
        ..strokeWidth = 1.2;
      
      // Dashed vertical line
      double startY = 0;
      const double dashHeight = 4.0;
      const double dashSpace = 4.0;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(selectedPoint.dx, startY),
          Offset(selectedPoint.dx, startY + dashHeight),
          cursorPaint,
        );
        startY += dashHeight + dashSpace;
      }

      // Draw highlighted outer glow ring
      canvas.drawCircle(
        selectedPoint,
        11,
        Paint()..color = color.withValues(alpha: 0.28),
      );
      // Draw highlighted inner ring
      canvas.drawCircle(
        selectedPoint,
        6,
        Paint()..color = color,
      );
      // Draw white center
      canvas.drawCircle(
        selectedPoint,
        3.2,
        Paint()..color = Colors.white,
      );

      // Tooltip dimensions
      double tooltipW = 96.0;
      double tooltipH = 46.0;
      double tooltipX = selectedPoint.dx.clamp(tooltipW / 2 + 6, size.width - tooltipW / 2 - 6);
      double tooltipY = (selectedPoint.dy - tooltipH - 12).clamp(6.0, size.height - tooltipH - 6);

      final tooltipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX - tooltipW / 2, tooltipY, tooltipW, tooltipH),
        const Radius.circular(10),
      );

      // Tooltip Card background (slate-900 look with glow border)
      final bgPaint = Paint()
        ..color = const Color(0xEE0F172A)
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(tooltipRect, bgPaint);
      canvas.drawRRect(tooltipRect, borderPaint);

      // Construct metrics texts
      String valueStr = '';
      if (values != null && selectedIndex! < values!.length) {
        final val = values![selectedIndex!];
        final displayVal = (val % 1 == 0) ? '${val.toInt()}' : val.toStringAsFixed(1);
        valueStr = '$displayVal $unit';
      }

      String dateStr = '';
      if (dates != null && selectedIndex! < dates!.length) {
        final d = dates![selectedIndex!];
        dateStr = _formatTooltipDate(d);
      }

      // Draw value text (Top)
      final valPainter = TextPainter(
        text: TextSpan(
          text: valueStr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: tooltipW);

      // Draw date text (Bottom)
      final datePainter = TextPainter(
        text: TextSpan(
          text: dateStr,
          style: const TextStyle(
            color: Color(0xFF94A3B8), // slate-400
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: tooltipW);

      valPainter.paint(
        canvas,
        Offset(
          tooltipX - valPainter.width / 2,
          tooltipY + 8,
        ),
      );
      datePainter.paint(
        canvas,
        Offset(
          tooltipX - datePainter.width / 2,
          tooltipY + 26,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrendPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.variant != variant ||
        oldDelegate.textColor != textColor ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.selectedIndex != selectedIndex ||
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
    final colors = AppColors.of(context);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.pale,
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
              style: TextStyle(
                color: colors.muted,
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
