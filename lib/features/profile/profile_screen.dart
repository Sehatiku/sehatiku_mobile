import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.darkMode,
    required this.onDarkMode,
    required this.onLogout,
    required this.onAction,
    required this.onDoctor,
  });

  final bool darkMode;
  final ValueChanged<bool> onDarkMode;
  final VoidCallback onLogout;
  final ValueChanged<String> onAction;
  final VoidCallback onDoctor;

  @override
  Widget build(BuildContext context) {
    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil Saya',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.green],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .4),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .4),
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'LV',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lavinia Putri',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '28 tahun · Gol. Darah O',
                        style: TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                            Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Akun Terverifikasi',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: 18,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.monitor_heart_rounded,
                  iconBg: const Color(0xFFFFEEF2),
                  iconColor: AppColors.pink,
                  label: 'Riwayat Penyakit',
                  value: 'Diabetes Tipe 2, Hipertensi',
                ),
                const Divider(color: Color(0xFFEEF3F9), height: 1),
                _InfoRow(
                  icon: Icons.emergency_rounded,
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: AppColors.orange,
                  label: 'Kontak Darurat',
                  value: 'Andi (Suami) · 0812-3456',
                ),
                const Divider(color: Color(0xFFEEF3F9), height: 1),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onDoctor,
                  child: _InfoRow(
                    icon: Icons.medical_services_rounded,
                    iconBg: const Color(0xFFEAF2FE),
                    iconColor: AppColors.primary,
                    label: 'Dokter Penanggung Jawab',
                    value: 'dr. Surya Wijaya, Sp.PD',
                    trailing: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'PENGATURAN',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: 18,
            child: Column(
              children: [
                ProfileRow(
                  icon: Icons.lock_rounded,
                  label: 'Privasi',
                  onTap: () => onAction('Pengaturan privasi tersedia.'),
                ),
                const Divider(color: Color(0xFFEEF3F9), height: 1),
                ProfileRow(
                  icon: Icons.security_rounded,
                  iconColor: AppColors.green,
                  label: 'Keamanan',
                  onTap: () => onAction('Pengaturan keamanan tersedia.'),
                ),
                const Divider(color: Color(0xFFEEF3F9), height: 1),
                ProfileRow(
                  icon: Icons.language_rounded,
                  iconColor: AppColors.violet,
                  label: 'Bahasa',
                  trailing: const Text(
                    'Indonesia',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () => onAction('Bahasa: Indonesia.'),
                ),
                const Divider(color: Color(0xFFEEF3F9), height: 1),
                ProfileRow(
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF46586B),
                  label: 'Mode Gelap',
                  trailing: Switch(
                    value: darkMode,
                    onChanged: onDarkMode,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Keluar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF5A5A),
                side: const BorderSide(color: Color(0xFFFFD9DF)),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trailing = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailing)
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC2CEDB)),
        ],
      ),
    );
  }
}

