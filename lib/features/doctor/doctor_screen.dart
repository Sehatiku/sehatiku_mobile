import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String? _activeOnset;
  String? _activeSickness;
  String? _activeDetail;
  String? _activeStatus;

  @override
  void initState() {
    super.initState();
    _fetchDoctor();
    _loadActiveConsultation();
  }

  Future<void> _loadActiveConsultation() async {
    final actorId = AuthStore.instance.session?.actorId;
    if (actorId == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _activeOnset = prefs.getString('active_consultation_onset_$actorId');
        _activeSickness = prefs.getString('active_consultation_sickness_$actorId');
        _activeDetail = prefs.getString('active_consultation_detail_$actorId');
        _activeStatus = prefs.getString('active_consultation_status_$actorId');
      });
    }
  }

  Future<void> _saveActiveConsultation({
    required String onset,
    required String sickness,
    required String detail,
  }) async {
    final actorId = AuthStore.instance.session?.actorId;
    if (actorId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_consultation_onset_$actorId', onset);
    await prefs.setString('active_consultation_sickness_$actorId', sickness);
    await prefs.setString('active_consultation_detail_$actorId', detail);
    await prefs.setString('active_consultation_status_$actorId', 'Waiting for Doctor Review');

    await _loadActiveConsultation();
  }

  Future<void> _clearActiveConsultation() async {
    final actorId = AuthStore.instance.session?.actorId;
    if (actorId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_consultation_onset_$actorId');
    await prefs.remove('active_consultation_sickness_$actorId');
    await prefs.remove('active_consultation_detail_$actorId');
    await prefs.remove('active_consultation_status_$actorId');

    await _loadActiveConsultation();
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
          const SizedBox(height: 18),

          // Actions Row or Active Consultation Card
          if (_activeStatus == 'Waiting for Doctor Review')
            _buildActiveConsultationCard(context)
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.whatsapp, Color(0xFF2EBE59)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.whatsapp.withValues(alpha: .24),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          final waLink = doctor.waLink;
                          final phone = doctor.whatsappPhone;

                          final String? urlString;
                          if (waLink != null && waLink.isNotEmpty) {
                            urlString = waLink;
                          } else if (phone.isNotEmpty) {
                            urlString = 'https://wa.me/$phone';
                          } else {
                            urlString = null;
                          }

                          if (urlString == null) {
                            widget.onAction('Nomor WhatsApp dokter tidak tersedia.');
                            return;
                          }

                          final uri = Uri.parse(urlString);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            widget.onAction('Tidak dapat membuka WhatsApp. Pastikan WhatsApp terinstal.');
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'WhatsApp',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, Color(0xFF2A8FE0)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: .3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _showConsultationForm(context),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sick_outlined, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Laporkan Keluhan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
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

  Widget _buildActiveConsultationCard(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Keluhan Aktif',
                style: TextStyle(
                  color: c.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Waiting for Doctor Review',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: c.line, height: 1),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'Sakitnya Apa', _activeSickness ?? ''),
          const SizedBox(height: 12),
          _buildDetailRow(context, 'Keluhan Sejak Kapan', _activeOnset ?? ''),
          const SizedBox(height: 12),
          _buildDetailRow(context, 'Detail Keluhan', _activeDetail ?? ''),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _clearActiveConsultation,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Batalkan Keluhan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: c.muted,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: c.text,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showConsultationForm(BuildContext context) {
    final onsetController = TextEditingController();
    final sicknessController = TextEditingController();
    final detailController = TextEditingController();
    bool isSending = false;
    String? modalError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final c = AppColors.of(context);
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Container(
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              Icons.sick_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Laporkan Keluhan',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded, color: c.muted),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Keluhan Anda akan langsung dikirimkan ke ${_doctorInfo?.fullName ?? 'Dokter Utama'}.',
                        style: TextStyle(color: c.muted, fontSize: 13, height: 1.45),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Keluhan Sejak Kapan',
                        style: TextStyle(
                          color: c.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: onsetController,
                        enabled: !isSending,
                        style: TextStyle(color: c.text),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Sejak kemarin, 3 hari yang lalu...',
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
                      const SizedBox(height: 16),
                      Text(
                        'Sakitnya Apa',
                        style: TextStyle(
                          color: c.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: sicknessController,
                        enabled: !isSending,
                        style: TextStyle(color: c.text),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Nyeri perut, pusing, sesak nafas...',
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
                      const SizedBox(height: 16),
                      Text(
                        'Detailnya Gimana',
                        style: TextStyle(
                          color: c.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: detailController,
                        minLines: 3,
                        maxLines: 5,
                        enabled: !isSending,
                        style: TextStyle(color: c.text),
                        decoration: InputDecoration(
                          hintText: 'Tuliskan detail keluhan yang Anda rasakan...',
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
                                  final onset = onsetController.text.trim();
                                  final sickness = sicknessController.text.trim();
                                  final detail = detailController.text.trim();
                                  
                                  if (onset.isEmpty) {
                                    setStateModal(() {
                                      modalError = 'Onset keluhan tidak boleh kosong.';
                                    });
                                    return;
                                  }
                                  
                                  if (sickness.isEmpty) {
                                    setStateModal(() {
                                      modalError = 'Sakitnya apa tidak boleh kosong.';
                                    });
                                    return;
                                  }
                                  
                                  if (detail.isEmpty) {
                                    setStateModal(() {
                                      modalError = 'Detail keluhan tidak boleh kosong.';
                                    });
                                    return;
                                  }
    
                                  final complaintPayload = 'Sakit: $sickness\nSejak: $onset\nDetail: $detail';
                                  
                                  if (complaintPayload.length > 2000) {
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
                                    await ConsultationService.instance.sendConsultation(complaintPayload);
                                    await _saveActiveConsultation(
                                      onset: onset,
                                      sickness: sickness,
                                      detail: detail,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      widget.onAction('Keluhan berhasil dikirimkan.');
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
                ),
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
