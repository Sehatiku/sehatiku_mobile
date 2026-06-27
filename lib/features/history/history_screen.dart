import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
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
  parts.add(r.medicineTaken ? 'Obat tepat waktu' : 'Obat terlewat');
  if (r.active30) parts.add('Aktif ≥30 mnt');
  if (r.sleepHours != null) {
    final h = r.sleepHours!.toStringAsFixed(r.sleepHours! % 1 == 0 ? 0 : 1);
    parts.add('Tidur ${h}j');
  }
  if (parts.isEmpty) return r.note.isEmpty ? 'Catatan tersimpan' : r.note;
  return parts.join(' · ');
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HealthScope.of(context);
    final query = _query.trim().toLowerCase();
    final all = store.records;
    final filtered = query.isEmpty
        ? all
        : all.where((r) {
            final hay =
                '${formatLongDate(r.date)} ${recordSummary(r)} ${r.note}'
                    .toLowerCase();
            return hay.contains(query);
          }).toList();

    return DetailScaffold(
      title: 'Riwayat Kesehatan',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      hintText: 'Cari tanggal atau catatan…',
                      hintStyle: TextStyle(
                        color: Color(0xFF9AA9BB),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF9AA9BB),
                      size: 20,
                    ),
                  )
                else
                  const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primary,
                    size: 21,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (all.isEmpty)
            const _HistoryEmpty(
              icon: Icons.history_rounded,
              message:
                  'Belum ada riwayat. Catatan harian yang Anda simpan akan muncul di sini.',
            )
          else if (filtered.isEmpty)
            const _HistoryEmpty(
              icon: Icons.search_off_rounded,
              message: 'Tidak ada catatan yang cocok dengan pencarian Anda.',
            )
          else
            for (var i = 0; i < filtered.length; i++)
              HistoryNode(
                date: formatLongDate(filtered[i].date),
                score: 'Skor ${filtered[i].score}',
                scoreColor: filtered[i].statusColor,
                scoreBg: filtered[i].statusBg,
                desc: recordSummary(filtered[i]),
                last: i == filtered.length - 1,
              ),
        ],
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

