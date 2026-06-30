import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

class IconCircle extends StatelessWidget {
  const IconCircle({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line),
        ),
        child: Icon(icon, color: c.text),
      ),
    );
  }
}

class FilledIconButton extends StatelessWidget {
  const FilledIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        child: Icon(icon, color: AppColors.violet),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isEnabled = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isEnabled
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF2A8FE0)],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.muted.withValues(alpha: 0.3), colors.muted.withValues(alpha: 0.3)],
              ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .38),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isEnabled ? Colors.white : colors.text.withValues(alpha: 0.5), size: 21),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : colors.text.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
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

class FrostIcon extends StatelessWidget {
  const FrostIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.radius,
    required this.iconSize,
    required this.color,
  });

  final IconData icon;
  final double size;
  final double radius;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: .4)),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
