import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/assigned_nakes_info.dart';
import 'package:sehatiku_mobile/data/services/consultation_service.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';
import 'package:sehatiku_mobile/data/repositories/auth_store.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({
    super.key,
    required this.onBack,
    required this.onAction,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onAction;

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  AssignedNakesInfo? _doctorInfo;

  @override
  void initState() {
    super.initState();
    _fetchDoctor();
  }

  Future<void> _fetchDoctor() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final info = await ConsultationService.instance.fetchAssignedNakes();
      if (mounted) {
        setState(() {
          _doctorInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e is ApiException) {
            if (e.statusCode == 404) {
              _errorMessage = 'Belum ada dokter yang ditugaskan';
            } else if (e.statusCode == 401) {
              _errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
              AuthStore.instance.clear();
            } else if (e.statusCode >= 500) {
              _errorMessage = 'Terjadi kesalahan pada server. Coba beberapa saat lagi.';
            } else if (e.statusCode == 0) {
              _errorMessage = 'Tidak ada koneksi internet. Periksa jaringan Anda.';
            } else {
              _errorMessage = e.message;
            }
          } else {
            _errorMessage = 'Tidak ada koneksi internet. Periksa jaringan Anda.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    Widget content;

    if (_isLoading) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_errorMessage != null) {
      final isNoDoctor = _errorMessage == 'Belum ada dokter yang ditugaskan';
      content = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.primary),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              if (!isNoDoctor) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _fetchDoctor,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba Lagi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (_doctorInfo == null) {
      content = const SizedBox.shrink();
    } else {
      final doctor = _doctorInfo!;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Info Header Card
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
                            doctor.fullName,
                            style: TextStyle(
                              color: colors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doctor.specialization,
                            style: const TextStyle(
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
                        doctor.hospital,
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

          // Practice Schedule Card
          InputCard(
            title: 'Jadwal Praktik',
            icon: Icons.schedule_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.tint(AppColors.primary),
            children: [
              Text(
                '${doctor.fullName} hanya melayani konsultasi rawat jalan dan konsultasi jarak jauh pada jam berikut:',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              if (doctor.schedule.isEmpty)
                Text(
                  'Belum ada jadwal praktik.',
                  style: TextStyle(color: colors.muted, fontSize: 13),
                )
              else
                ...doctor.schedule.map((s) {
                  final days = s['days']?.toString() ?? 'Hari tidak ditentukan';
                  final time = s['time']?.toString() ?? 'Jam tidak ditentukan';
                  final isLast = s == doctor.schedule.last;
                  return Column(
                    children: [
                      _ScheduleRow(day: days, time: time),
                      if (!isLast) Divider(color: colors.line, height: 1),
                    ],
                  );
                }),
            ],
          ),
          const SizedBox(height: 24),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final waLink = doctor.waLink;
                      final phone = doctor.whatsappPhone;
                      if (waLink != null && waLink.isNotEmpty) {
                        widget.onAction('Membuka chat WhatsApp dokter ($waLink).');
                      } else if (phone.isNotEmpty) {
                        widget.onAction('Membuka chat WhatsApp dokter (https://wa.me/$phone).');
                      } else {
                        widget.onAction('Nomor WhatsApp dokter tidak tersedia.');
                      }
                    },
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
      );
    }

    return DetailScaffold(
      title: 'Konsultasi Dokter',
      onBack: widget.onBack,
      child: content,
    );
  }

  void _showConsultationForm(BuildContext context) {
    final complaintController = TextEditingController();
    bool isSending = false;
    String? modalError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final c = AppColors.of(context);
        return StatefulBuilder(
          builder: (context, setStateModal) {
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
                    'Keluhan Anda akan langsung dikirimkan ke ${_doctorInfo?.fullName ?? 'Dokter Utama'}.',
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
                    enabled: !isSending,
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
                  if (modalError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      modalError!,
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: isSending
                          ? null
                          : () async {
                              final complaint = complaintController.text.trim();
                              
                              if (complaint.isEmpty) {
                                setStateModal(() {
                                  modalError = 'Keluhan tidak boleh kosong.';
                                });
                                return;
                              }
                              
                              if (complaint.length > 2000) {
                                setStateModal(() {
                                  modalError = 'Keluhan tidak boleh melebihi 2000 karakter.';
                                });
                                return;
                              }

                              setStateModal(() {
                                isSending = true;
                                modalError = null;
                              });

                              try {
                                await ConsultationService.instance.sendConsultation(complaint);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  widget.onAction('Keluhan berhasil dikirimkan ke ${_doctorInfo?.fullName}.');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setStateModal(() {
                                    isSending = false;
                                    if (e is ApiException) {
                                      if (e.statusCode == 422) {
                                        modalError = e.message;
                                      } else {
                                        modalError = 'Gagal mengirim keluhan. Periksa koneksi internet Anda.';
                                      }
                                    } else {
                                      modalError = 'Gagal mengirim keluhan. Periksa koneksi internet Anda.';
                                    }
                                  });
                                }
                              }
                            },
                      icon: isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(isSending ? 'Mengirim...' : 'Kirim Sekarang'),
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
      },
    );
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
