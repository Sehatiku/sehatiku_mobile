import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import 'package:sehatiku_mobile/core/core.dart';

/// Floating bottom navigation with a centered AI orb and soft glass surface.
class FloatingNav extends StatelessWidget {
  const FloatingNav({super.key, required this.view, required this.onView});

  final MainView view;
  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: 82,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 66,
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: .84),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: colors.line.withValues(alpha: .9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .12),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        _NavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: 'Beranda',
                          selected: view == MainView.beranda,
                          onTap: () => onView(MainView.beranda),
                        ),
                        _NavItem(
                          icon: Icons.edit_note_outlined,
                          activeIcon: Icons.edit_note_rounded,
                          label: 'Catat',
                          selected: view == MainView.catatan,
                          onTap: () => onView(MainView.catatan),
                        ),
                        const SizedBox(width: 74),
                        _NavItem(
                          icon: Icons.insert_chart_outlined_rounded,
                          activeIcon: Icons.insert_chart_rounded,
                          label: 'Progres',
                          selected: view == MainView.progres,
                          onTap: () => onView(MainView.progres),
                        ),
                        _NavItem(
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
              ),
            ),
          ),
          Positioned(
            top: -10,
            child: _SparkleFab(
              selected: view == MainView.ai,
              onTap: () => onView(MainView.ai),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
    final labelColor = selected ? c.text : idleColor;

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
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 46,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.11)
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.20)
                            : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      selected ? activeIcon : icon,
                      color: selected ? AppColors.primary : idleColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10.5,
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

/// Raised AI button with a gentle, continuous glow.
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
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.violet],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: c.background,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color:
                                AppColors.violet.withValues(alpha: .4 + .15 * t),
                            blurRadius: 14 + 10 * t,
                            offset: Offset(0, 6 + 4 * t),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: .12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .28),
                          ),
                        ),
                        child: Transform.scale(
                          scale: 0.94 + 0.1 * t,
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
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
