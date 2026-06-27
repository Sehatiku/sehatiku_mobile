
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sehatiku_mobile/core/core.dart';

class FloatingNav extends StatelessWidget {
  const FloatingNav({super.key, required this.view, required this.onView});

  final MainView view;
  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Notched bar background.
          Positioned(
            left: 0,
            right: 0,
            top: 18,
            bottom: 0,
            child: CustomPaint(painter: _NotchedBarPainter()),
          ),
          // Tab items (left pair + spacer for the notch + right pair).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 68,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  _CuteNavItem(
                    icon: Icons.home_outlined,
                    label: 'Beranda',
                    selected: view == MainView.beranda,
                    onTap: () => onView(MainView.beranda),
                  ),
                  _CuteNavItem(
                    icon: Icons.edit_note_rounded,
                    label: 'Catat',
                    selected: view == MainView.catatan,
                    onTap: () => onView(MainView.catatan),
                  ),
                  const SizedBox(width: 72),
                  _CuteNavItem(
                    icon: Icons.insert_chart_outlined_rounded,
                    label: 'Progres',
                    selected: view == MainView.progres,
                    onTap: () => onView(MainView.progres),
                  ),
                  _CuteNavItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profil',
                    selected: view == MainView.profil,
                    onTap: () => onView(MainView.profil),
                  ),
                ],
              ),
            ),
          ),
          // Centre FAB nested in the notch.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _SparkleFab(
                selected: view == MainView.ai,
                onTap: () => onView(MainView.ai),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the rounded bar with a centre notch carved into the top edge.
class _NotchedBarPainter extends CustomPainter {
  const _NotchedBarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const r = 26.0;
    final cx = w / 2;
    // Notch control points are taken from the source SVG (358px wide); scale
    // horizontally so the notch keeps its proportions on any screen width.
    final sx = w / 358.0;

    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(cx - 59 * sx, 0)
      ..cubicTo(cx - 39 * sx, 0, cx - 35 * sx, 30, cx, 30)
      ..cubicTo(cx + 35 * sx, 30, cx + 39 * sx, 0, cx + 59 * sx, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: const Radius.circular(r))
      ..close();

    // Soft purple drop shadow.
    final shadow = Paint()
      ..color = const Color(0x385B4FD6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.save();
    canvas.translate(0, 10);
    canvas.drawPath(path, shadow);
    canvas.restore();

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFFBFAFF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _NotchedBarPainter oldDelegate) => false;
}

class _CuteNavItem extends StatelessWidget {
  const _CuteNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF5B53EF);
    const idleColor = Color(0xFFAAB0C8);
    final color = selected ? activeColor : idleColor;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Dot that pops in just above the chip when active.
                Positioned(
                  top: 1,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    scale: selected ? 1 : 0,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6173FF), Color(0xFF9333EA)],
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Only the chip lifts + grows when this tab is active.
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutBack,
                      offset: selected ? const Offset(0, -0.12) : Offset.zero,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,
                        scale: selected ? 1.08 : 1,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                          width: 42,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: selected
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFDDE6FF),
                                      Color(0xFFECE2FF),
                                    ],
                                  )
                                : null,
                          ),
                          child: Icon(icon, color: color, size: 23),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 240),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        height: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: Text(label, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Raised AI button with a gentle, continuous "breathing" glow so it always
/// feels alive, plus a pop when it becomes the active tab.
class _SparkleFab extends StatefulWidget {
  const _SparkleFab({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SparkleFab> createState() => _SparkleFabState();
}

class _SparkleFabState extends State<_SparkleFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: 'AI',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _bob,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_bob.value);
            // Gentle bob + tilt so the FAB always feels alive.
            return Transform.translate(
              offset: Offset(0, -5 * t),
              child: Transform.rotate(
                angle: -0.07 * t,
                child: Transform.scale(
                  scale: widget.selected ? 1.05 : 1.0,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6173FF), Color(0xFF7C3AED)],
                      ),
                      boxShadow: [
                        // Cream ring so the FAB reads as punched through the bar.
                        const BoxShadow(
                          color: Color(0xFFF7F1FF),
                          spreadRadius: 6,
                        ),
                        BoxShadow(
                          color: const Color(0xFF6C48F0).withValues(alpha: .55),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Transform.scale(
                      // Twinkling sparkle.
                      scale: 0.92 + 0.16 * t,
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

