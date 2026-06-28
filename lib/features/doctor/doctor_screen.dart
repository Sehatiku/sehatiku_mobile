import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class DoctorScreen extends StatelessWidget {
  const DoctorScreen({
    super.key,
    required this.onBack,
    required this.onAction,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DetailScaffold(
      title: 'Konsultasi Dokter',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Info Header Card — Glassmorphic feel.
          AppCard(
            padding: 20,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.cyan],
                        ),
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lime.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Dokter Utama',
                              style: TextStyle(
                                color: AppColors.lime,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: .3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'dr. Surya Wijaya, Sp.PD',
                            style: TextStyle(
                              color: colors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Spesialis Penyakit Dalam',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _DoctorStat(
                        value: '10+',
                        label: 'Tahun Eksp',
                        valueColor: colors.text,
                      ),
                    ),
                    const _StatDivider(),
                    const Expanded(
                      child: _DoctorStat(
                        value: '4.9',
                        label: 'Rating Asosiasi',
                        valueColor: AppColors.lime,
                      ),
                    ),
                    const _StatDivider(),
                    Expanded(
                      child: _DoctorStat(
                        value: '99%',
                        label: 'Respon Cepat',
                        valueColor: colors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(color: colors.line, height: 1),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'RS Permata Sehat, Poliklinik Penyakit Dalam',
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          InputCard(
            title: 'Jadwal Praktik',
            icon: Icons.schedule_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.tint(AppColors.primary),
            children: [
              Text(
                'dr. Surya Wijaya hanya melayani konsultasi rawat jalan dan konsultasi jarak jauh pada jam berikut:',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              const _ScheduleRow(day: 'Senin - Jumat', time: '08.00 - 14.00'),
              Divider(color: colors.line, height: 1),
              const _ScheduleRow(day: 'Sabtu', time: '08.00 - 12.00'),
            ],
          ),
          const SizedBox(height: 24),

          // Actions Row — Interactive contact options.
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () => onAction('Membuka chat WhatsApp dokter.'),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.whatsapp,
                      foregroundColor: Colors.white,
                      side: BorderSide.none,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => _showConsultationForm(context),
                    icon: const Icon(Icons.event_rounded, size: 20),
                    label: const Text('Konsultasi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConsultationForm(BuildContext context) {
    final complaintController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final c = AppColors.of(context);
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: c.line),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.tint(AppColors.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kirim Keluhan ke Dokter',
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Keluhan Anda akan langsung dikirimkan ke dr. Surya Wijaya, Sp.PD.',
                style: TextStyle(color: c.muted, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 18),
              Text(
                'Deskripsi Keluhan',
                style: TextStyle(
                  color: c.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: complaintController,
                minLines: 4,
                maxLines: 6,
                style: TextStyle(color: c.text),
                decoration: InputDecoration(
                  hintText: 'Tuliskan gejala atau pertanyaan Anda di sini...',
                  filled: true,
                  fillColor: c.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    final complaint = complaintController.text.trim();
                    if (complaint.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Keluhan tidak boleh kosong.')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    onAction('Keluhan berhasil dikirimkan ke dr. Surya Wijaya.');
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Kirim Sekarang'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DoctorStat extends StatelessWidget {
  const _DoctorStat({
    required this.value,
    required this.label,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor ?? AppColors.of(context).text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.of(context).muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: AppColors.of(context).line);
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.day, required this.time});

  final String day;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              day,
              style: TextStyle(
                color: AppColors.of(context).muted,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              color: AppColors.of(context).text,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}
