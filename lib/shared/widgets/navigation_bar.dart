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

    // 1. Ambient structural shadow.
    final ambientShadow = Paint()
      ..color = colors.line.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(path, ambientShadow);
    canvas.restore();

    // 2. Wide glowing brand shadow for high-end floating feel.
    final brandShadow = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.save();
    canvas.translate(0, 12);
    canvas.drawPath(path, brandShadow);
    canvas.restore();

    // Adaptive gradient background matching the current theme surface.
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.surface.withValues(alpha: 0.90),
          colors.background.withValues(alpha: 0.80),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, fill);

    // Hairline border gradient for dynamic glass refraction.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(
            alpha: colors.text == AppColors.dark.text ? 0.22 : 0.45,
          ),
          colors.line.withValues(alpha: 0.35),
          AppColors.primary.withValues(alpha: 0.15),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
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

    // Apply gradient color mask to the icon when active.
    Widget iconWidget = Icon(
      selected ? activeIcon : icon,
      color: selected ? Colors.white : idleColor,
      size: 20,
    );

    if (selected) {
      iconWidget = ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppColors.primary, AppColors.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Icon(
          activeIcon,
          color: Colors.white,
          size: 21,
        ),
      );
    }

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
                // Smooth elastic scale animation for active tab.
                AnimatedScale(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  scale: selected ? 1.10 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: 44,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: selected
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 1.0,
                            )
                          : Border.all(
                              color: Colors.transparent,
                              width: 1.0,
                            ),
                    ),
                    child: iconWidget,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: Text(label, textAlign: TextAlign.center),
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
    with TickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  late final AnimationController _rotate = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _bob.dispose();
    _rotate.dispose();
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
          animation: Listenable.merge([_bob, _rotate]),
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_bob.value);
            final rotationAngle = _rotate.value * 2 * 3.141592653589793;
            // Gentle vertical bob + breathing glow
            return Transform.translate(
              offset: Offset(0, -4 * t),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                scale: widget.selected ? 1.08 : 1.0,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // The glowing rotating outer ring (aura)
                    Transform.rotate(
                      angle: rotationAngle,
                      child: Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.0),
                              AppColors.primary.withValues(alpha: 0.45),
                              AppColors.violet.withValues(alpha: 0.45),
                              AppColors.primary.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.4, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // The main button body
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.violet],
                        ),
                        boxShadow: [
                          // Thick ring matching the background theme
                          BoxShadow(
                            color: c.background,
                            spreadRadius: 3,
                          ),
                          // Premium soft glowing shadow
                          BoxShadow(
                            color: AppColors.violet.withValues(alpha: .4 + .15 * t),
                            blurRadius: 14 + 10 * t,
                            offset: Offset(0, 6 + 4 * t),
                          ),
                        ],
                      ),
                      child: Transform.scale(
                        // Twinkling sparkle.
                        scale: 0.94 + 0.1 * t,
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
