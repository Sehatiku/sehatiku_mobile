import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/data/models/history_entry.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
import 'package:sehatiku_mobile/data/repositories/auth_store.dart';
import 'package:sehatiku_mobile/data/services/record_service.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

String recordSummary(HealthRecord r) {
  final parts = <String>[];
  if (r.bloodSugar != null) {
    final tag = bloodSugarTagLabels[r.bloodSugarTag];
    parts.add(tag == null ? 'Gula ${r.bloodSugar}' : 'Gula ${r.bloodSugar} ($tag)');
  }
  if (r.systolic != null && r.diastolic != null) {
    parts.add('Tekanan ${r.bloodPressure}');
  }
  if (r.weight != null) {
    parts.add(
      'Berat ${r.weight!.toStringAsFixed(r.weight! % 1 == 0 ? 0 : 1)} kg',
    );
  }
  if (r.medicineTaken) {
    parts.add(r.medicineName.isNotEmpty ? 'Obat: ${r.medicineName}' : 'Obat tepat waktu');
  } else {
    parts.add('Obat terlewat');
  }
  if (r.active30 || r.activityMinutes > 0) {
    final actName = r.activityType.isNotEmpty ? r.activityType : 'Aktif';
    parts.add('$actName ${r.activityMinutes} mnt');
  }
  if (r.sleepHours != null) {
    final h = r.sleepHours!.toStringAsFixed(r.sleepHours! % 1 == 0 ? 0 : 1);
    parts.add('Tidur ${h}j');
  }
  if (parts.isEmpty) return r.note.isEmpty ? 'Catatan tersimpan' : r.note;
  return parts.join(' · ');
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.onBack,
    this.onViewRecordWithDate,
  });

  final VoidCallback onBack;
  final void Function(DateTime)? onViewRecordWithDate;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  DateTime? _selectedFilterDate;
  
  bool _isLoading = true;
  String? _errorMessage;
  List<HistoryEntry> _apiEntries = [];
  bool _isFallback = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isFallback = false;
    });
    try {
      final entries = await RecordService.instance.fetchHistory(limit: 30);
      if (mounted) {
        final store = HealthScope.of(context);
        await store.mergeHistory(entries);
        setState(() {
          _apiEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFallback = true;
          _isLoading = false;
          if (e is ApiException && e.statusCode == 401) {
            _errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
            AuthStore.instance.clear();
          } else {
            _errorMessage = 'Menampilkan data lokal – tidak dapat terhubung ke server.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = HealthScope.of(context);
    final query = _query.trim().toLowerCase();

    // Map API entries to HealthRecords dynamically
    final apiRecords = _apiEntries.map((e) {
      final existing = store.recordFor(e.date);
      return HealthRecord(
        date: e.date,
        bloodSugar: e.bloodSugar,
        systolic: e.systolic,
        diastolic: e.diastolic,
        weight: e.weight,
        medicineTaken: existing?.medicineTaken ?? false,
        medicineName: existing?.medicineName ?? '',
        medicineTime: existing?.medicineTime ?? '',
        meals: existing?.meals ?? {},
        active30: existing?.active30 ?? false,
        activityMinutes: existing?.activityMinutes ?? 0,
        activityType: existing?.activityType ?? '',
        sleepHours: existing?.sleepHours,
        sleepQuality: existing?.sleepQuality ?? 1,
        stressIndex: existing?.stressIndex ?? 1,
        smoke: existing?.smoke ?? false,
        alcohol: existing?.alcohol ?? false,
        note: existing?.note ?? '',
      );
    }).toList();

    // Show server entries, plus any local records the server doesn't have yet
    // (e.g. a record just saved that hasn't propagated, or a pending offline
    // sync), so a freshly-saved record appears in Riwayat immediately.
    final List<HealthRecord> all;
    if (_isFallback) {
      all = store.records;
    } else {
      final apiDates = apiRecords.map((r) => r.date).toSet();
      final localOnly =
          store.records.where((r) => !apiDates.contains(r.date)).toList();
      all = [...apiRecords, ...localOnly]
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    var filtered = all;
    if (_selectedFilterDate != null) {
      filtered = filtered
          .where((r) => HealthRecord.dayOf(r.date) == _selectedFilterDate)
          .toList();
    }
    if (query.isNotEmpty) {
      filtered = filtered.where((r) {
        final hay =
            '${formatLongDate(r.date)} ${recordSummary(r)} ${r.note}'
                .toLowerCase();
        return hay.contains(query);
      }).toList();
    }

    Widget content;

    if (_isLoading) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isFallback) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: .3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.offline_bolt_rounded,
                    color: AppColors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage ?? 'Menampilkan data lokal – tidak dapat terhubung ke server.',
                      style: TextStyle(
                        color: AppColors.of(context).text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.of(context).line,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.of(context).text.withValues(alpha: .04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF9AA9BB),
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(color: AppColors.of(context).text, fontSize: 14),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Cari tanggal atau catatan…',
                      hintStyle: TextStyle(
                        color: Color(0xFF9AA9BB),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (_query.isNotEmpty || _selectedFilterDate != null)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _selectedFilterDate = null;
                      });
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF9AA9BB),
                      size: 20,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedFilterDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedFilterDate = HealthRecord.dayOf(picked);
                        });
                      }
                    },
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedFilterDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                FilterChip(
                  label: Text(
                    'Filter: ${formatLongDate(_selectedFilterDate!)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  onSelected: (_) {},
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: const BorderSide(color: Colors.transparent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  deleteIcon: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  onDeleted: () {
                    setState(() {
                      _selectedFilterDate = null;
                    });
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          if (all.isEmpty)
            _HistoryEmpty(
              icon: Icons.history_rounded,
              message: _isFallback
                  ? 'Belum ada riwayat. Catatan harian yang Anda simpan akan muncul di sini.'
                  : 'Belum ada riwayat catatan di server.',
            )
          else if (filtered.isEmpty)
            const _HistoryEmpty(
              icon: Icons.search_off_rounded,
              message: 'Tidak ada catatan yang cocok dengan pencarian Anda.',
            )
          else
            for (var i = 0; i < filtered.length; i++)
              HistoryNode(
                record: filtered[i],
                last: i == filtered.length - 1,
                onTap: widget.onViewRecordWithDate != null
                    ? () => widget.onViewRecordWithDate!(filtered[i].date)
                    : null,
              ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: DetailScaffold(
        title: 'Riwayat Kesehatan',
        onBack: widget.onBack,
        child: content,
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.of(context).pale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: const Color(0xFFB6C3D2), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.of(context).muted,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
