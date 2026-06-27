import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({
    super.key,
    required this.onBack,
    required this.selectedFilter,
    required this.onFilter,
    required this.onAction,
  });

  final VoidCallback onBack;
  final int selectedFilter;
  final ValueChanged<int> onFilter;
  final ValueChanged<String> onAction;

  static const _filters = ['Semua', 'Diabetes', 'Hipertensi', 'Nutrisi'];

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Edukasi Kesehatan',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _filters.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: PillTab(
                      label: _filters[i],
                      selected: selectedFilter == i,
                      compact: true,
                      onTap: () => onFilter(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GradientPanel(
            radius: 24,
            colors: const [AppColors.primary, AppColors.green],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 6),
                      Text(
                        'Pilihan Hari Ini',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mengelola Gula Darah di Rumah dengan Tepat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Color(0xD9FFFFFF),
                      size: 15,
                    ),
                    SizedBox(width: 5),
                    Text(
                      '5 menit baca',
                      style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Artikel untuk Anda'),
          const SizedBox(height: 12),
          ArticleTile(
            icon: Icons.restaurant_rounded,
            category: 'NUTRISI',
            title: '5 Makanan Penurun Tekanan Darah Alami',
            time: '4 menit baca',
            color: AppColors.primary,
            onTap: () => onAction('Membuka artikel nutrisi.'),
          ),
          ArticleTile(
            icon: Icons.directions_walk_rounded,
            category: 'AKTIVITAS',
            title: 'Olahraga Aman untuk Penderita Diabetes',
            time: '6 menit baca',
            color: AppColors.green,
            onTap: () => onAction('Membuka artikel aktivitas.'),
          ),
          ArticleTile(
            icon: Icons.medication_rounded,
            category: 'OBAT',
            title: 'Pentingnya Minum Obat Tepat Waktu',
            time: '3 menit baca',
            color: AppColors.violet,
            onTap: () => onAction('Membuka artikel obat.'),
          ),
          ArticleTile(
            icon: Icons.bedtime_rounded,
            category: 'TIDUR & STRES',
            title: 'Cara Tidur Berkualitas untuk Kontrol Gula',
            time: '5 menit baca',
            color: AppColors.orange,
            onTap: () => onAction('Membuka artikel tidur & stres.'),
          ),
        ],
      ),
    );
  }
}
