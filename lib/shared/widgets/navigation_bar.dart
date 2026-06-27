import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sehatiku_mobile/core/core.dart';

/// Floating notched bottom navigation with a raised AI button nested in the
/// centre notch. Active tabs lift their icon into a brand-gradient pill.
class FloatingNav extends StatelessWidget {
  const FloatingNav({super.key, required this.view, required this.onView});

  final MainView view;
  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: 86,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glassmorphic notched bar background.
          Positioned(
            left: 0,
            right: 0,
            top: 18,
            bottom: 0,
            child: ClipPath(
              clipper: const _NotchedBarClipper(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: CustomPaint(
                  painter: _NotchedBarPainter(colors: colors),
                  child: Container(),
                ),
              ),
            ),
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
                    activeIcon: Icons.home_rounded,
                    label: 'Beranda',
                    selected: view == MainView.beranda,
                    onTap: () => onView(MainView.beranda),
                  ),
                  _CuteNavItem(
                    icon: Icons.edit_note_outlined,
                    activeIcon: Icons.edit_note_rounded,
                    label: 'Catat',
                    selected: view == MainView.catatan,
                    onTap: () => onView(MainView.catatan),
                  ),
                  const SizedBox(width: 72),
                  _CuteNavItem(
                    icon: Icons.insert_chart_outlined_rounded,
                    activeIcon: Icons.insert_chart_rounded,
                    label: 'Progres',
                    selected: view == MainView.progres,
                    onTap: () => onView(MainView.progres),
                  ),
                  _CuteNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
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

/// Custom clipper to clip the background of the notched bar for BackdropFilter.
class _NotchedBarClipper extends CustomClipper<Path> {
  const _NotchedBarClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    const r = 26.0;
    final cx = w / 2;
    final sx = w / 358.0;

    return Path()
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
  }

  @override
  bool shouldReclip(covariant _NotchedBarClipper oldClipper) => false;
}

/// Paints the rounded bar with a centre notch carved into the top edge.
class _NotchedBarPainter extends CustomPainter {
  const _NotchedBarPainter({required this.colors});

  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const r = 26.0;
    final cx = w / 2;
    // Notch control points are scaled horizontally to keep proportions.
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

    // Soft brand-tinted drop shadow.
    final shadow = Paint()
      ..color = AppColors.primary.withValues(alpha: .14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.save();
    canvas.translate(0, 10);
    canvas.drawPath(path, shadow);
    canvas.restore();

    // Adaptive gradient background matching the current theme surface.
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.surface.withValues(alpha: 0.88),
          colors.background.withValues(alpha: 0.78),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, fill);

    // Hairline top edge for a crisp, premium finish.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = colors.line;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _NotchedBarPainter oldDelegate) => oldDelegate.colors != colors;
}

class _CuteNavItem extends StatelessWidget {
  const _CuteNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final idleColor = c.muted;
    final labelColor = selected ? AppColors.primary : idleColor;
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Active icon lifts into a brand-gradient pill; idle stays flat.
                AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  offset: selected ? const Offset(0, -0.06) : Offset.zero,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    width: selected ? 46 : 40,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: selected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.primary, AppColors.violet],
                            )
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: .38),
                                blurRadius: 14,
                                offset: const Offset(0, 7),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      selected ? activeIcon : icon,
                      color: selected ? Colors.white : idleColor,
                      size: 21,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 240),
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: Text(label, textAlign: TextAlign.center),
                ),
                // Glowing indicator dot below active item
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(top: 3),
                  width: selected ? 5 : 0,
                  height: selected ? 5 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
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
/// feels alive, plus a subtle lift when it becomes the active tab.
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
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
            // Gentle vertical bob + breathing glow — no spin, keeps it elegant.
            return Transform.translate(
              offset: Offset(0, -4 * t),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                scale: widget.selected ? 1.06 : 1.0,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.violet],
                    ),
                    boxShadow: [
                      // Ring matching the active background theme.
                      BoxShadow(
                        color: c.background,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: AppColors.violet.withValues(alpha: .45 + .18 * t),
                        blurRadius: 18 + 12 * t,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Transform.scale(
                    // Twinkling sparkle.
                    scale: 0.94 + 0.12 * t,
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 26,
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
