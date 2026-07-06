import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/assigned_nakes_info.dart';
import 'package:sehatiku_mobile/data/models/consultation.dart';
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
  List<Consultation> _consultations = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctorAndHistory();
  }

  List<Consultation> get _activeConsultations {
    return _consultations.where((c) => c.status == 'open').toList();
  }

  List<Consultation> get _historicalConsultations {
    return _consultations.where((c) => c.status == 'replied').toList();
  }

  Future<void> _fetchDoctorAndHistory() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final results = await Future.wait([
        ConsultationService.instance.fetchAssignedNakes(),
        ConsultationService.instance.fetchConsultationHistory(),
      ]);
      
      if (mounted) {
        setState(() {
          _doctorInfo = results[0] as AssignedNakesInfo;
          _consultations = results[1] as List<Consultation>;
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
                  onPressed: _fetchDoctorAndHistory,
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
              ] else ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('https://wa.me/628975228858');
                    try {
                      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                      if (!launched) {
                        widget.onAction('Tidak dapat membuka WhatsApp. Pastikan WhatsApp terinstal.');
                      }
                    } catch (_) {
                      widget.onAction('Tidak dapat membuka WhatsApp. Pastikan WhatsApp terinstal.');
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: const Text('Hubungi Faskes Anda'),
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
      final activeConsultations = _activeConsultations;
      final historicalConsultations = _historicalConsultations;

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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.cyan],
                          ),
                        ),
                        child: Image.network(
                          'https://i.pravatar.cc/150?u=${Uri.encodeComponent(doctor.fullName)}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
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

          // Actions Row (Always Visible)
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
                        try {
                          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                          if (!launched) {
                            widget.onAction('Tidak dapat membuka WhatsApp. Pastikan WhatsApp terinstal.');
                          }
                        } catch (_) {
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
          if (activeConsultations.isNotEmpty) ...[
            const SizedBox(height: 18),
            ...activeConsultations.map((c) => _buildActiveConsultationCard(context, c)),
          ],
          const SizedBox(height: 24),
          Text(
            'Riwayat Konsultasi',
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (historicalConsultations.isEmpty)
            AppCard(
              padding: 24,
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: colors.muted.withValues(alpha: 0.4),
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum Ada Riwayat Konsultasi',
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keluhan yang Anda laporkan akan muncul di sini beserta balasan dokter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...historicalConsultations.map((c) => _buildConsultationCard(context, c)),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDoctorAndHistory,
      child: DetailScaffold(
        title: 'Konsultasi Dokter',
        onBack: widget.onBack,
        child: content,
      ),
    );
  }

  Widget _buildActiveConsultationCard(BuildContext context, Consultation openConsultation) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
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
            _buildDetailRow(context, 'Sakitnya Apa', openConsultation.complaintType),
            const SizedBox(height: 12),
            _buildDetailRow(context, 'Keluhan Sejak Kapan', openConsultation.complaintSince),
            const SizedBox(height: 12),
            _buildDetailRow(context, 'Detail Keluhan', openConsultation.complaintDetail),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationCard(BuildContext context, Consultation c) {
    final colors = AppColors.of(context);
    final isReplied = c.status == 'replied';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    c.complaintType,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReplied
                        ? AppColors.green.withValues(alpha: 0.12)
                        : AppColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isReplied ? 'Sudah Dibalas' : 'Menunggu Balasan',
                    style: TextStyle(
                      color: isReplied ? AppColors.green : AppColors.amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatLongDate(c.createdAt),
              style: TextStyle(
                color: colors.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Divider(color: colors.line, height: 1),
            const SizedBox(height: 14),
            _buildDetailRow(context, 'Keluhan Sejak Kapan', c.complaintSince),
            const SizedBox(height: 10),
            _buildDetailRow(context, 'Detail Keluhan', c.complaintDetail),
            if (isReplied && c.nakesNote != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.primary).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.medical_services_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _doctorInfo?.fullName.isNotEmpty == true
                              ? 'Tanggapan ${_doctorInfo!.fullName}'
                              : 'Tanggapan Dokter',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.nakesNote!,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (c.repliedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        formatLongDate(c.repliedAt!),
                        style: TextStyle(
                          color: colors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
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
                                  
                                  if (onset.length > 500) {
                                    setStateModal(() {
                                      modalError = 'Onset tidak boleh melebihi 500 karakter.';
                                    });
                                    return;
                                  }
                                  
                                  if (sickness.length > 500) {
                                    setStateModal(() {
                                      modalError = 'Sakit tidak boleh melebihi 500 karakter.';
                                    });
                                    return;
                                  }
                                  
                                  if (detail.length > 2000) {
                                    setStateModal(() {
                                      modalError = 'Detail keluhan tidak boleh melebihi 2000 karakter.';
                                    });
                                    return;
                                  }
    
                                  setStateModal(() {
                                    isSending = true;
                                    modalError = null;
                                  });
    
                                  try {
                                    await ConsultationService.instance.sendConsultation(
                                      complaintSince: onset,
                                      complaintType: sickness,
                                      complaintDetail: detail,
                                    );
                                    await _fetchDoctorAndHistory();
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      widget.onAction('Keluhan berhasil dikirimkan.');
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      setStateModal(() {
                                        isSending = false;
                                        if (e is ApiException) {
                                          modalError = e.message;
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
