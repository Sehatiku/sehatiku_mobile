import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onContinue,
      child: Container(
        key: const ValueKey('splash'),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF1AA1C4), AppColors.green],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -60,
              child: SoftCircle(size: 280, opacity: .12),
            ),
            const Positioned(
              bottom: 60,
              left: -70,
              child: SoftCircle(size: 230, opacity: .10),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: 118, onColor: true),
                  const SizedBox(height: 26),
                  const Text(
                    'Sehatiku',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(
                    width: 260,
                    child: Text(
                      'Pendamping Kesehatan Anda Setiap Hari',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: 54,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                      backgroundColor: Color(0x4DFFFFFF),
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Ketuk untuk lanjut',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
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
