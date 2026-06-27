import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Notifikasi',
      onBack: onBack,
      child: Column(
        children: const [
          NotifCard(
            icon: Icons.alarm_rounded,
            color: AppColors.orange,
            bg: Color(0xFFFFF3E0),
            title: 'Pengingat Obat',
            desc: 'Saatnya minum Metformin pukul 09.00.',
            time: '2m',
          ),
          NotifCard(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.violet,
            bg: Color(0xFFF0EBFF),
            title: 'Peringatan AI',
            desc: 'Tekanan darah cenderung naik. Kurangi garam hari ini.',
            time: '1j',
          ),
          NotifCard(
            icon: Icons.event_rounded,
            color: AppColors.primary,
            bg: Color(0xFFEAF2FE),
            title: 'Janji Dokter',
            desc: 'Konsultasi dengan dr. Surya, besok pukul 10.00.',
            time: '3j',
          ),
          NotifCard(
            icon: Icons.task_alt_rounded,
            color: AppColors.lime,
            bg: Color(0xFFE7F7EC),
            title: 'Catatan Harian',
            desc: 'Data kesehatan hari ini berhasil disimpan. Skor 87!',
            time: '5j',
          ),
        ],
      ),
    );
  }
}

