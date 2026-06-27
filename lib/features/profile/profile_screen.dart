import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/auth_models.dart';
import 'package:sehatiku_mobile/data/models/dashboard_models.dart';
import 'package:sehatiku_mobile/data/repositories/auth_store.dart';
import 'package:sehatiku_mobile/data/services/dashboard_service.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.darkMode,
    required this.onDarkMode,
    required this.onLogout,
    required this.onAction,
    required this.onDoctor,
    this.fullName,
  });

  final bool darkMode;
  final ValueChanged<bool> onDarkMode;
  final Future<void> Function() onLogout;
  final ValueChanged<String> onAction;
  final VoidCallback onDoctor;

  /// Display name from the active session. Falls back gracefully if null.
  final String? fullName;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  PatientDashboard? _dashboard;

  @override
  void initState() {
    super.initState();
    _fetchIfPatient();
  }

  Future<void> _fetchIfPatient() async {
    final session = AuthStore.instance.session;
    if (session == null || session.actorType != ActorType.patient) return;
    try {
      final data = await DashboardService.instance.fetchDashboard();
      if (mounted) setState(() => _dashboard = data);
    } catch (_) {
      // Profile still renders without API data — fail silently.
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        _dashboard?.profile.fullName ?? widget.fullName ?? 'Pengguna';
    final initials = displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final String ageAndDisease = _buildSubtitle();

    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil Saya',
            style: TextStyle(
              color: AppColors.of(context).text,
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
                  child: Text(
                    initials,
                    style: const TextStyle(
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
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ageAndDisease,
                        style: const TextStyle(
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
                  iconBg: AppColors.tint(AppColors.pink),
                  iconColor: AppColors.pink,
                  label: 'Riwayat Penyakit',
                  value: _diseaseLabel(_dashboard?.profile.diseaseType),
                ),
                Divider(color: AppColors.of(context).line, height: 1),
                _InfoRow(
                  icon: Icons.emergency_rounded,
                  iconBg: AppColors.tint(AppColors.orange),
                  iconColor: AppColors.orange,
                  label: 'Kontak Darurat',
                  value: 'Andi (Suami) · 0812-3456',
                ),
                Divider(color: AppColors.of(context).line, height: 1),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: widget.onDoctor,
                  child: _InfoRow(
                    icon: Icons.medical_services_rounded,
                    iconBg: AppColors.tint(AppColors.primary),
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
          Text(
            'PENGATURAN',
            style: TextStyle(
              color: AppColors.of(context).muted,
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
                  onTap: () => widget.onAction('Pengaturan privasi tersedia.'),
                ),
                Divider(color: AppColors.of(context).line, height: 1),
                ProfileRow(
                  icon: Icons.security_rounded,
                  iconColor: AppColors.green,
                  label: 'Keamanan',
                  onTap: () => widget.onAction('Pengaturan keamanan tersedia.'),
                ),
                Divider(color: AppColors.of(context).line, height: 1),
                ProfileRow(
                  icon: Icons.language_rounded,
                  iconColor: AppColors.violet,
                  label: 'Bahasa',
                  trailing: Text(
                    'Indonesia',
                    style: TextStyle(
                      color: AppColors.of(context).muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () => widget.onAction('Bahasa: Indonesia.'),
                ),
                Divider(color: AppColors.of(context).line, height: 1),
                ProfileRow(
                  icon: Icons.dark_mode_rounded,
                  iconColor: AppColors.of(context).text,
                  label: 'Mode Gelap',
                  trailing: Switch(
                    value: widget.darkMode,
                    onChanged: widget.onDarkMode,
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
              onPressed: widget.onLogout,
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

  String _buildSubtitle() {
    if (_dashboard == null) return 'Pasien Sehatiku';
    final age = _dashboard!.profile.age;
    final disease = _diseaseLabel(_dashboard!.profile.diseaseType);
    return '$age tahun · $disease';
  }

  static String _diseaseLabel(String? type) => switch (type) {
        'diabetes_t2' => 'Diabetes Tipe 2',
        'hypertension' => 'Hipertensi',
        'both' => 'Diabetes Tipe 2 & Hipertensi',
        _ => type ?? 'Pasien',
      };
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
                  style: TextStyle(
                    color: AppColors.of(context).muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.of(context).text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailing)
            Icon(Icons.chevron_right_rounded, color: AppColors.of(context).muted),
        ],
      ),
    );
  }
}

