import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/data/models/health_score.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';
import 'package:sehatiku_mobile/data/services/record_service.dart';
import 'package:sehatiku_mobile/data/services/dashboard_service.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    required this.onSaved,
    required this.onView,
    this.initialDate,
  });

  final ValueChanged<String> onSaved;
  final ValueChanged<MainView> onView;
  final DateTime? initialDate;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _bsController = TextEditingController();
  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  final _weightController = TextEditingController();
  final _sleepController = TextEditingController();
  final _noteController = TextEditingController();

  final _medicineNameController = TextEditingController();
  final _medicineTimeController = TextEditingController();
  final _customActivityController = TextEditingController();
  final _activityMinutesController = TextEditingController();
  final _mealsController = TextEditingController();
  String _selectedActivityType = 'Jalan Kaki';

  bool _medicineTaken = false;
  bool _saving = false;
  bool _active30 = false;
  int _sleepQuality = 1; // 0=Buruk, 1=Cukup, 2=Nyenyak
  int _stressIndex = 1; // 0=Santai, 1=Normal, 2=Tinggi
  bool _smoke = false;
  bool _alcohol = false;

  int _currentTab = 0; // 0: Vital, 1: Aktivitas, 2: Kondisi
  late DateTime _selectedDate;
  bool _loggedTodayFromServer = false;

  bool get _isLocked {
    final today = HealthRecord.dayOf(DateTime.now());
    if (HealthRecord.dayOf(_selectedDate) == today && _loggedTodayFromServer) {
      return true;
    }

    final record = HealthScope.of(context).recordFor(_selectedDate);
    if (record == null) return false;

    final profile = DashboardService.instance.cachedDashboard?.profile;
    final disease = profile?.diseaseType ?? 'both';

    bool vitalsFilled = true;
    if (disease == 'diabetes' || disease == 'both') {
      if (record.bloodSugar == null) vitalsFilled = false;
    }
    if (disease == 'hypertension' || disease == 'both') {
      if (record.systolic == null || record.diastolic == null) vitalsFilled = false;
    }

    final sleepFilled = record.sleepHours != null;
    final mealsFilled = record.meals.isNotEmpty;

    return vitalsFilled && sleepFilled && mealsFilled;
  }

  Future<void> _syncTodayRecord() async {
    final today = HealthRecord.dayOf(DateTime.now());
    if (HealthRecord.dayOf(_selectedDate) != today) return;

    try {
      final loggedToday = await RecordService.instance.fetchLoggedToday();
      if (mounted) {
        setState(() {
          _loggedTodayFromServer = loggedToday;
        });
      }
      if (loggedToday && mounted) {
        final entries = await RecordService.instance.fetchHistory(limit: 5);
        if (mounted) {
          final store = HealthScope.of(context);
          await store.mergeHistory(entries);
          _loadRecordForDate(_selectedDate);
        }
      }
    } catch (_) {
      // Fail silently
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecordForDate(_selectedDate);
      _syncTodayRecord();
    });
  }

  @override
  void didUpdateWidget(covariant RecordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate && widget.initialDate != null) {
      setState(() {
        _selectedDate = widget.initialDate!;
      });
      _loadRecordForDate(widget.initialDate!);
      _syncTodayRecord();
    }
  }

  void _loadRecordForDate(DateTime date) {
    final record = HealthScope.of(context).recordFor(date);
    if (!mounted) return;
    setState(() {
      if (record == null) {
        _bsController.clear();
        _sysController.clear();
        _diaController.clear();
        _weightController.clear();
        _sleepController.clear();
        _noteController.clear();
        _medicineNameController.clear();
        _medicineTimeController.clear();
        _customActivityController.clear();
        _activityMinutesController.clear();
        _medicineTaken = false;
        _mealsController.clear();
        _active30 = false;
        _sleepQuality = 1;
        _stressIndex = 1;
        _smoke = false;
        _alcohol = false;
        _selectedActivityType = 'Jalan Kaki';
        return;
      }
      if (record.bloodSugar != null) {
        _bsController.text = record.bloodSugar.toString();
      } else {
        _bsController.clear();
      }
      if (record.systolic != null) {
        _sysController.text = record.systolic.toString();
      } else {
        _sysController.clear();
      }
      if (record.diastolic != null) {
        _diaController.text = record.diastolic.toString();
      } else {
        _diaController.clear();
      }
      if (record.weight != null) {
        _weightController.text = _formatNum(record.weight!);
      } else {
        _weightController.clear();
      }
      if (record.sleepHours != null) {
        _sleepController.text = _formatNum(record.sleepHours!);
      } else {
        _sleepController.clear();
      }
      _medicineTaken = record.medicineTaken;
      if (_medicineTaken) {
        _medicineNameController.text = record.medicineName.isEmpty ? 'Metformin' : record.medicineName;
        _medicineTimeController.text = record.medicineTime.isEmpty ? '09:00' : record.medicineTime;
      } else {
        _medicineNameController.text = record.medicineName;
        _medicineTimeController.text = record.medicineTime;
      }
      _mealsController.text = record.meals.isEmpty ? '' : record.meals.join(', ');
      _active30 = record.active30;
      _activityMinutesController.text = record.activityMinutes > 0 ? record.activityMinutes.toString() : (record.active30 ? '30' : '');
      _selectedActivityType = record.activityType.isEmpty ? 'Jalan Kaki' : record.activityType;
      if (!['Jalan Kaki', 'Bersepeda', 'Yoga', 'Senam', 'Lari'].contains(_selectedActivityType) && _selectedActivityType.isNotEmpty) {
        _customActivityController.text = _selectedActivityType;
        _selectedActivityType = 'Lainnya';
      }
      _sleepQuality = record.sleepQuality;
      _stressIndex = record.stressIndex;
      _smoke = record.smoke;
      _alcohol = record.alcohol;
      _noteController.text = record.note;
    });
  }

  String _formatNum(num value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value.toString();
  }

  @override
  void dispose() {
    _bsController.dispose();
    _sysController.dispose();
    _diaController.dispose();
    _weightController.dispose();
    _sleepController.dispose();
    _noteController.dispose();
    _medicineNameController.dispose();
    _medicineTimeController.dispose();
    _customActivityController.dispose();
    _activityMinutesController.dispose();
    _mealsController.dispose();
    super.dispose();
  }

  int? _parseInt(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  double? _parseDouble(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();

    final List<String> missingFields = [];
    if (_bsController.text.trim().isEmpty) missingFields.add('Gula Darah');
    if (_sysController.text.trim().isEmpty || _diaController.text.trim().isEmpty) {
      missingFields.add('Tekanan Darah (Sistolik & Diastolik)');
    }
    if (_weightController.text.trim().isEmpty) missingFields.add('Berat Badan');
    if (_mealsController.text.trim().isEmpty) missingFields.add('Makanan');
    if (_sleepController.text.trim().isEmpty) missingFields.add('Jam Tidur');

    if (_medicineTaken) {
      if (_medicineNameController.text.trim().isEmpty) missingFields.add('Nama Obat');
      if (_medicineTimeController.text.trim().isEmpty) missingFields.add('Waktu Konsumsi Obat');
    }
    if (_active30) {
      if (_activityMinutesController.text.trim().isEmpty) missingFields.add('Durasi Aktivitas');
      if (_selectedActivityType == 'Lainnya' && _customActivityController.text.trim().isEmpty) {
        missingFields.add('Jenis Aktivitas');
      }
    }

    if (missingFields.isNotEmpty) {
      widget.onSaved('Harap lengkapi semua data berikut sebelum menyimpan: ${missingFields.join(", ")}');
      return;
    }

    final bs = _parseInt(_bsController);
    final sys = _parseInt(_sysController);
    final dia = _parseInt(_diaController);
    final w = _parseDouble(_weightController);
    final sleep = _parseDouble(_sleepController);

    // Metrics the backend accepts on POST /records — at least one is required
    // for the record (and the health score) to be saved server-side.
    // A note is NOT a metric: it is never sent to the server.
    final hasRecordMetric = bs != null ||
        (sys != null && dia != null) ||
        w != null ||
        _medicineTaken ||
        _mealsController.text.trim().isNotEmpty;

    // Lifestyle inputs go to /health-logs, not /records.
    final hasLifestyle = sleep != null || _active30 || _smoke || _alcohol;

    if (!hasRecordMetric && !hasLifestyle) {
      widget.onSaved(
        _noteController.text.trim().isNotEmpty
            ? 'Catatan tambahan saja belum cukup. Isi minimal satu data kesehatan (mis. gula darah, tekanan darah, atau berat badan).'
            : 'Silakan masukkan minimal satu data kesehatan.',
      );
      return;
    }

    if ((sys != null && dia == null) || (sys == null && dia != null)) {
      widget.onSaved('Tekanan darah harus diisi lengkap (Sistolik & Diastolik).');
      return;
    }

    setState(() => _saving = true);
    final store = HealthScope.of(context);

    final activityMin = int.tryParse(_activityMinutesController.text.trim()) ?? 0;
    final activityTypeVal = _selectedActivityType == 'Lainnya'
        ? _customActivityController.text.trim()
        : _selectedActivityType;

    final record = HealthRecord(
      date: HealthRecord.dayOf(_selectedDate),
      bloodSugar: bs,
      systolic: sys,
      diastolic: dia,
      weight: w,
      medicineTaken: _medicineTaken,
      medicineName: _medicineTaken ? (_medicineNameController.text.trim().isEmpty ? 'Metformin' : _medicineNameController.text.trim()) : '',
      medicineTime: _medicineTaken ? (_medicineTimeController.text.trim().isEmpty ? '09:00' : _medicineTimeController.text.trim()) : '',
      meals: _mealsController.text.trim().isEmpty ? {} : {_mealsController.text.trim()},
      active30: _active30 && activityMin >= 30,
      activityType: _active30 ? (activityTypeVal.isEmpty ? 'Jalan Kaki' : activityTypeVal) : '',
      activityMinutes: _active30 ? (activityMin == 0 ? 30 : activityMin) : 0,
      sleepHours: sleep,
      sleepQuality: _sleepQuality,
      stressIndex: _stressIndex,
      smoke: _smoke,
      alcohol: _alcohol,
      note: _noteController.text.trim(),
    );

    // Persist locally immediately so data is never lost.
    await store.upsert(record);

    // Per API guide: send lifestyle logs FIRST so the ML has them when /records computes the score.
    await _submitLifestyleLogs(record);

    // Only POST /records when there's a metric it accepts; lifestyle-only
    // input is already sent above via /health-logs and would 400 here.
    // May take up to 90 s on ML cold start.
    HealthScore? score;
    if (hasRecordMetric) {
      try {
        score = await RecordService.instance.saveRecord(record);
        if (score != null) {
          await store.upsert(record.copyWith(
            healthScore: score.healthScore.toInt(),
            apiStatus: score.status,
            apiStatusLabel: score.statusLabel,
          ));
        }
        store.clearPendingSync(record.date);
      } catch (err) {
        if (err is ApiException && err.statusCode == 400) {
          if (mounted) {
            setState(() => _saving = false);
            widget.onSaved('Gagal mengirim ke server: ${(err).message}');
          }
          return;
        }
        // Network/server errors: mark for later sync but don't block the user.
        store.markPendingSync(record.date);
      }
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      final today = HealthRecord.dayOf(DateTime.now());
      if (HealthRecord.dayOf(_selectedDate) == today) {
        _loggedTodayFromServer = true;
      }
    });

    if (score != null && score.topPenalties.isNotEmpty) {
      await _showScoreResultSheet(score);
    }
    if (mounted) {
      final msg = score != null
          ? 'Catatan tersimpan · ${score.statusLabel} · Skor ${score.healthScore.toInt()}/100.'
          : 'Catatan tersimpan. Skor belum tersedia, coba lagi nanti.';
      widget.onSaved(msg);
    }

    if (mounted) widget.onView(MainView.beranda);
  }

  /// Sends lifestyle metrics to /health-logs in parallel so the ML model can
  /// factor them into the score computed by /records. Must be awaited before
  /// calling saveRecord. Failures are silently ignored.
  Future<void> _submitLifestyleLogs(HealthRecord record) async {
    // Noon UTC for the record's date, but never in the future (the backend
    // rejects a future measured_at). See RecordService._recordedAt.
    final nowUtc = DateTime.now().toUtc();
    var measuredAt = DateTime.utc(
        record.date.year, record.date.month, record.date.day, 12, 0, 0);
    if (measuredAt.isAfter(nowUtc)) measuredAt = nowUtc;

    // Map local stressIndex (0=Santai, 1=Normal, 2=Tinggi) → API scale 1–10.
    const stressScale = [2.0, 5.0, 9.0];

    final futures = <Future<void>>[
      RecordService.instance.submitHealthLog(
        metricType: 'stress',
        valueNumeric: stressScale[record.stressIndex],
        measuredAt: measuredAt,
      ),
    ];

    if (record.sleepHours != null) {
      futures.add(RecordService.instance.submitHealthLog(
        metricType: 'sleep',
        valueNumeric: record.sleepHours,
        measuredAt: measuredAt,
      ));
    }

    if (record.active30 && record.activityMinutes > 0) {
      futures.add(RecordService.instance.submitHealthLog(
        metricType: 'activity',
        valueNumeric: record.activityMinutes.toDouble(),
        measuredAt: measuredAt,
      ));
    }

    if (record.smoke) {
      futures.add(RecordService.instance.submitHealthLog(
        metricType: 'smoking',
        valueNumeric: 1,
        measuredAt: measuredAt,
      ));
    }

    if (record.alcohol) {
      futures.add(RecordService.instance.submitHealthLog(
        metricType: 'alcohol',
        valueNumeric: 1,
        measuredAt: measuredAt,
      ));
    }

    try {
      await Future.wait(futures);
    } catch (_) {}
  }

  /// Bottom-sheet displayed after a successful save when the ML model returns
  /// a score with penalties. Colors follow the API status contract:
  ///   aman → green, waswas → amber, bahaya → red.
  Future<void> _showScoreResultSheet(HealthScore score) async {
    final scoreColor = switch (score.status) {
      'bahaya' => AppColors.red,
      'waswas' => AppColors.amber,
      _ => AppColors.lime,
    };

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final c = AppColors.of(ctx);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: c.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            '${score.healthScore.toInt()}',
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Skor Kesehatan Anda',
                              style: TextStyle(color: c.muted, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              score.statusLabel,
                              style: TextStyle(
                                color: scoreColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    score.message,
                    style: TextStyle(color: c.text, fontSize: 13.5, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Faktor yang Perlu Diperhatikan',
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...score.topPenalties.map(
                    (penalty) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: scoreColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              penalty,
                              style: TextStyle(
                                color: c.text,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Mengerti'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Calculates completion progress out of 8 parameters
  int get _filledCount {
    int count = 0;
    if (_bsController.text.trim().isNotEmpty) count++;
    if (_sysController.text.trim().isNotEmpty && _diaController.text.trim().isNotEmpty) count++;
    if (_weightController.text.trim().isNotEmpty) count++;
    if (_medicineTaken) count++;
    if (_mealsController.text.trim().isNotEmpty) count++;
    if (_active30) count++;
    if (_sleepController.text.trim().isNotEmpty) count++;
    if (_noteController.text.trim().isNotEmpty) count++;
    return count;
  }

  double get _progressPercent => _filledCount / 8.0;

  Widget _buildHeaderCard() {
    final count = _filledCount;
    final percent = _progressPercent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primary2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      HealthRecord.dayOf(_selectedDate) == HealthRecord.dayOf(DateTime.now())
                          ? 'Bagaimana kondisimu hari ini?'
                          : 'Bagaimana kondisimu pada tanggal ini?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatLongDate(_selectedDate),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(percent * 100).toInt()}% Terisi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: .2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            count == 8
                ? 'Luar biasa! Semua data hari ini sudah tercatat.'
                : 'Mengisi data kesehatan membantu AI menganalisis kondisi Anda dengan lebih akurat.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .85),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(AppColors colors) {
    final tabs = ['Tanda Vital', 'Aktivitas', 'Kondisi Tubuh'];
    final icons = [Icons.favorite_rounded, Icons.directions_run_rounded, Icons.bedtime_rounded];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _currentTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentTab = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? colors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.text.withValues(alpha: .04),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      size: 15,
                      color: isSelected ? AppColors.primary : colors.muted,
                    ),
                    const SizedBox(width: 5),
                    FittedBox(
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          color: isSelected ? colors.text : colors.muted,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIncrementDecrementField({
    required TextEditingController controller,
    required String hint,
    required String unit,
    required Color accent,
    double step = 1,
    bool isDecimal = false,
    double? min,
    double? max,
  }) {
    final colors = AppColors.of(context);

    void adjust(double amount) {
      double currentVal = 0;
      final text = controller.text.trim().replaceAll(',', '.');
      if (text.isNotEmpty) {
        currentVal = double.tryParse(text) ?? 0;
      } else {
        currentVal = double.tryParse(hint) ?? 0;
      }
      double newVal = currentVal + amount;
      if (min != null && newVal < min) newVal = min;
      if (max != null && newVal > max) newVal = max;

      setState(() {
        if (isDecimal) {
          controller.text = newVal.toStringAsFixed(1).replaceAll('.0', '');
        } else {
          controller.text = newVal.toInt().toString();
        }
      });
    }

    return Row(
      children: [
        GestureDetector(
          onTap: _isLocked ? null : () => adjust(-step),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.elevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.line),
            ),
            child: Icon(Icons.remove_rounded, color: colors.text, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            enabled: !_isLocked,
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                isDecimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
              ),
            ],
            style: TextStyle(
              color: colors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(
                color: colors.muted,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              suffixText: unit,
              suffixStyle: TextStyle(
                color: colors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: colors.elevated,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accent),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isLocked ? null : () => adjust(step),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.elevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.line),
            ),
            child: Icon(Icons.add_rounded, color: colors.text, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildDualIncrementDecrementField({
    required TextEditingController sysController,
    required TextEditingController diaController,
    required Color accent,
  }) {
    final colors = AppColors.of(context);

    Widget buildHalfField({
      required String label,
      required TextEditingController controller,
      required String hint,
      required double step,
    }) {
      void adjust(double amount) {
        double currentVal = 0;
        final text = controller.text.trim();
        if (text.isNotEmpty) {
          currentVal = double.tryParse(text) ?? 0;
        } else {
          currentVal = double.tryParse(hint) ?? 0;
        }
        double newVal = currentVal + amount;
        if (newVal < 0) newVal = 0;
        setState(() {
          controller.text = newVal.toInt().toString();
        });
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: _isLocked ? null : () => adjust(-step),
                child: Container(
                  width: 32,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.line),
                  ),
                  child: Icon(Icons.remove_rounded, color: colors.text, size: 16),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  enabled: !_isLocked,
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: colors.muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    filled: true,
                    fillColor: colors.elevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _isLocked ? null : () => adjust(step),
                child: Container(
                  width: 32,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.line),
                  ),
                  child: Icon(Icons.add_rounded, color: colors.text, size: 16),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: buildHalfField(
            label: 'Sistolik (mmHg)',
            controller: sysController,
            hint: '120',
            step: 5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: buildHalfField(
            label: 'Diastolik (mmHg)',
            controller: diaController,
            hint: '80',
            step: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Color accent,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    IconData? suffixIcon,
    VoidCallback? onTapSuffix,
    ValueChanged<String>? onChanged,
  }) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          enabled: !_isLocked,
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: TextStyle(
            color: colors.text,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: colors.muted.withValues(alpha: .5),
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: colors.elevated,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            suffixIcon: suffixIcon != null
                ? GestureDetector(
                    onTap: _isLocked ? null : onTapSuffix,
                    child: Icon(suffixIcon, size: 18, color: colors.muted),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(AppColors colors) {
    final activeColor = AppColors.violet;
    final String medicineSubtitle;
    if (_medicineTaken) {
      final name = _medicineNameController.text.trim().isEmpty ? 'Metformin' : _medicineNameController.text.trim();
      final time = _medicineTimeController.text.trim().isEmpty ? '09:00' : _medicineTimeController.text.trim();
      medicineSubtitle = '$name · $time';
    } else {
      medicineSubtitle = 'Metformin · 09:00';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _medicineTaken ? activeColor.withValues(alpha: .08) : colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _medicineTaken ? activeColor : colors.line,
          width: _medicineTaken ? 1.5 : 1,
        ),
        boxShadow: _medicineTaken
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: .15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ]
            : [
                BoxShadow(
                  color: const Color(0x0F000000),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isLocked ? null : () {
              setState(() {
                _medicineTaken = !_medicineTaken;
                if (_medicineTaken) {
                  if (_medicineNameController.text.isEmpty) _medicineNameController.text = 'Metformin';
                  if (_medicineTimeController.text.isEmpty) _medicineTimeController.text = '09:00';
                }
              });
            },
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _medicineTaken ? activeColor.withValues(alpha: .2) : AppColors.tint(activeColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: activeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sudah Minum Obat',
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        medicineSubtitle,
                        style: TextStyle(
                          color: _medicineTaken ? activeColor.withValues(alpha: .8) : colors.muted,
                          fontSize: 12,
                          fontWeight: _medicineTaken ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _medicineTaken ? activeColor : colors.elevated,
                    border: Border.all(
                      color: _medicineTaken ? Colors.transparent : colors.line,
                      width: 2,
                    ),
                  ),
                  child: _medicineTaken
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
              ],
            ),
          ),
          if (_medicineTaken) ...[
            const SizedBox(height: 16),
            Divider(color: colors.line, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSmallTextField(
                    label: 'Nama Obat',
                    controller: _medicineNameController,
                    hint: 'Metformin',
                    accent: activeColor,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallTextField(
                    label: 'Waktu Minum',
                    controller: _medicineTimeController,
                    hint: '09:00',
                    accent: activeColor,
                    suffixIcon: Icons.access_time_rounded,
                    onTapSuffix: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (time != null) {
                        setState(() {
                          final hourStr = time.hour.toString().padLeft(2, '0');
                          final minStr = time.minute.toString().padLeft(2, '0');
                          _medicineTimeController.text = '$hourStr:$minStr';
                        });
                      }
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityCard(AppColors colors) {
    final activeColor = AppColors.lime;
    final String activitySubtitle;
    if (_active30) {
      final type = _selectedActivityType == 'Lainnya'
          ? (_customActivityController.text.trim().isEmpty ? 'Aktivitas Lainnya' : _customActivityController.text.trim())
          : _selectedActivityType;
      final minutes = _activityMinutesController.text.trim().isEmpty ? '30' : _activityMinutesController.text.trim();
      activitySubtitle = '$type · $minutes menit';
    } else {
      activitySubtitle = 'Jalan kaki, bersepeda, yoga, dll.';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _active30 ? activeColor.withValues(alpha: .08) : colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _active30 ? activeColor : colors.line,
          width: _active30 ? 1.5 : 1,
        ),
        boxShadow: _active30
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: .15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ]
            : [
                BoxShadow(
                  color: const Color(0x0F000000),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isLocked ? null : () {
              setState(() {
                _active30 = !_active30;
                if (_active30) {
                  if (_activityMinutesController.text.isEmpty) _activityMinutesController.text = '30';
                }
              });
            },
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _active30 ? activeColor.withValues(alpha: .2) : AppColors.tint(activeColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.directions_walk_rounded,
                    color: activeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktif Minimal 30 Menit',
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activitySubtitle,
                        style: TextStyle(
                          color: _active30 ? activeColor.withValues(alpha: .8) : colors.muted,
                          fontSize: 12,
                          fontWeight: _active30 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _active30 ? activeColor : colors.elevated,
                    border: Border.all(
                      color: _active30 ? Colors.transparent : colors.line,
                      width: 2,
                    ),
                  ),
                  child: _active30
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
              ],
            ),
          ),
          if (_active30) ...[
            const SizedBox(height: 16),
            Divider(color: colors.line, height: 1),
            const SizedBox(height: 16),
            Text(
              'Jenis Aktivitas',
              style: TextStyle(
                color: colors.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Jalan Kaki', 'Bersepeda', 'Yoga', 'Senam', 'Lari', 'Lainnya'].map((type) {
                final isSel = _selectedActivityType == type;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _isLocked ? null : () {
                    setState(() {
                      _selectedActivityType = type;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? activeColor.withValues(alpha: .15) : colors.elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? activeColor : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSel ? activeColor : colors.text,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedActivityType == 'Lainnya') ...[
              const SizedBox(height: 12),
              _buildSmallTextField(
                label: 'Aktivitas Lainnya',
                controller: _customActivityController,
                hint: 'Berenang, dll.',
                accent: activeColor,
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 12),
            _buildSmallTextField(
              label: 'Durasi (Menit)',
              controller: _activityMinutesController,
              hint: '30',
              accent: activeColor,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStressSelector(AppColors colors) {
    final stressLevels = [
      {'index': 0, 'emoji': '😌', 'label': 'Santai', 'color': AppColors.green},
      {'index': 1, 'emoji': '😐', 'label': 'Normal', 'color': AppColors.amber},
      {'index': 2, 'emoji': '😣', 'label': 'Tinggi', 'color': AppColors.red},
    ];

    return Row(
      children: stressLevels.map((level) {
        final idx = level['index'] as int;
        final isSelected = _stressIndex == idx;
        final color = level['color'] as Color;
        final label = level['label'] as String;
        final emoji = level['emoji'] as String;

        return Expanded(
          child: GestureDetector(
            onTap: _isLocked ? null : () => setState(() => _stressIndex = idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: .12) : colors.elevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : colors.line,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: .1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.25 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? color : colors.text,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYesNoHabitCard({
    required String label,
    required String emoji,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = AppColors.of(context);
    return AppCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isLocked ? null : () => onChanged(false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !value ? AppColors.green.withValues(alpha: .15) : colors.elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !value ? AppColors.green : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Tidak',
                      style: TextStyle(
                        color: !value ? AppColors.green : colors.muted,
                        fontWeight: !value ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _isLocked ? null : () => onChanged(true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value ? AppColors.red.withValues(alpha: .15) : colors.elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: value ? AppColors.red : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Ya',
                      style: TextStyle(
                        color: value ? AppColors.red : colors.muted,
                        fontWeight: value ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
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

  Widget _buildActiveTabContent(AppColors colors) {
    switch (_currentTab) {
      case 0:
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputCard(
              title: 'Gula Darah',
              icon: Icons.water_drop_rounded,
              iconColor: AppColors.primary,
              iconBg: AppColors.tint(AppColors.primary),
              children: [
                _buildIncrementDecrementField(
                  controller: _bsController,
                  hint: '105',
                  unit: 'mg/dL',
                  accent: AppColors.primary,
                  step: 5,
                  min: 0,
                ),
              ],
            ),
            const SizedBox(height: 14),
            InputCard(
              title: 'Tekanan Darah',
              icon: Icons.favorite_rounded,
              iconColor: AppColors.pink,
              iconBg: AppColors.tint(AppColors.pink),
              children: [
                _buildDualIncrementDecrementField(
                  sysController: _sysController,
                  diaController: _diaController,
                  accent: AppColors.pink,
                ),
              ],
            ),
            const SizedBox(height: 14),
            InputCard(
              title: 'Berat Badan',
              icon: Icons.monitor_weight_rounded,
              iconColor: AppColors.violet,
              iconBg: AppColors.tint(AppColors.violet),
              children: [
                _buildIncrementDecrementField(
                  controller: _weightController,
                  hint: '62',
                  unit: 'kg',
                  accent: AppColors.violet,
                  step: 0.5,
                  isDecimal: true,
                  min: 0,
                ),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMedicineCard(colors),
            const SizedBox(height: 14),
            InputCard(
              title: 'Makanan',
              icon: Icons.restaurant_rounded,
              iconColor: AppColors.orange,
              iconBg: AppColors.tint(AppColors.orange),
              children: [
                Text(
                  'Ceritakan apa saja yang kamu makan hari ini',
                  style: TextStyle(color: colors.muted, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                TextField(
                  enabled: !_isLocked,
                  controller: _mealsController,
                  maxLines: 3,
                  maxLength: 500,
                  style: TextStyle(color: colors.text),
                  decoration: InputDecoration(
                    hintText: 'Contoh: nasi padang rendang, es teh manis, buah apel...',
                    filled: true,
                    fillColor: colors.elevated,
                    contentPadding: const EdgeInsets.all(12),
                    counterStyle: TextStyle(color: colors.muted, fontSize: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.orange),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildActivityCard(colors),
          ],
        );
      case 2:
      default:
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputCard(
              title: 'Kualitas Tidur',
              icon: Icons.bedtime_rounded,
              iconColor: AppColors.cyan,
              iconBg: AppColors.tint(AppColors.cyan),
              children: [
                _buildIncrementDecrementField(
                  controller: _sleepController,
                  hint: '7',
                  unit: 'jam',
                  accent: AppColors.cyan,
                  step: 0.5,
                  isDecimal: true,
                  min: 0,
                  max: 24,
                ),
                const SizedBox(height: 14),
                Text(
                  'Kualitas tidur semalam',
                  style: TextStyle(
                    color: colors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 9),
                SegmentedPills(
                  labels: const ['🥱 Buruk', '😌 Cukup', '💤 Nyenyak'],
                  selected: _sleepQuality,
                  onTap: _isLocked ? (_) {} : (v) => setState(() => _sleepQuality = v),
                  enabledIndices: _isLocked ? [] : null,
                ),
              ],
            ),
            const SizedBox(height: 14),
            InputCard(
              title: 'Tingkat Stres',
              icon: Icons.mood_rounded,
              iconColor: AppColors.amber,
              iconBg: AppColors.tint(AppColors.amber),
              children: [
                _buildStressSelector(colors),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildYesNoHabitCard(
                    label: 'Merokok',
                    emoji: '🚬',
                    value: _smoke,
                    onChanged: (v) => setState(() => _smoke = v),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildYesNoHabitCard(
                    label: 'Alkohol',
                    emoji: '🍺',
                    value: _alcohol,
                    onChanged: (v) => setState(() => _alcohol = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Tambahan',
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !_isLocked,
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 5,
                    style: TextStyle(color: colors.text),
                    decoration: InputDecoration(
                      hintText: 'Hari ini terasa lebih berenergi setelah jalan pagi…',
                      filled: true,
                      fillColor: colors.pale,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildNavigationButtons(AppColors colors) {
    return Row(
      children: [
        if (_currentTab > 0) ...[
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentTab--;
                });
              },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: colors.elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, color: colors.text, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Kembali',
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 3,
          child: _currentTab < 2
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTab++;
                    });
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primary2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: .25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lanjutkan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                )
              : PrimaryButton(
                  label: _isLocked ? 'Sudah Diisi Lengkap' : 'Simpan Data',
                  icon: _isLocked ? Icons.lock_rounded : Icons.save_rounded,
                  onPressed: _isLocked ? null : _save,
                ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(AppColors colors) {
    final today = HealthRecord.dayOf(DateTime.now());
    final yesterday = HealthRecord.dayOf(DateTime.now().subtract(const Duration(days: 1)));
    
    final isToday = HealthRecord.dayOf(_selectedDate) == today;
    final isYesterday = HealthRecord.dayOf(_selectedDate) == yesterday;
    final isOther = !isToday && !isYesterday;

    return Row(
      children: [
        _DatePill(
          label: 'Kemarin',
          selected: isYesterday,
          onTap: () {
            if (_selectedDate != yesterday) {
              setState(() => _selectedDate = yesterday);
              _loadRecordForDate(yesterday);
            }
          },
          colors: colors,
        ),
        const SizedBox(width: 8),
        _DatePill(
          label: 'Hari Ini',
          selected: isToday,
          onTap: () {
            if (_selectedDate != today) {
              setState(() => _selectedDate = today);
              _loadRecordForDate(today);
              _syncTodayRecord();
            }
          },
          colors: colors,
        ),
        const SizedBox(width: 8),
        _DatePill(
          label: isOther ? formatShortDate(_selectedDate) : 'Lainnya',
          selected: isOther,
          icon: Icons.calendar_today_rounded,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: isOther ? _selectedDate : today,
              firstDate: DateTime.now().subtract(const Duration(days: 90)),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              final normalized = HealthRecord.dayOf(picked);
              setState(() => _selectedDate = normalized);
              _loadRecordForDate(normalized);
              if (normalized == today) {
                _syncTodayRecord();
              }
            }
          },
          colors: colors,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            title: 'Catatan Harian',
            subtitle: formatLongDate(_selectedDate),
          ),
          const SizedBox(height: 16),
          _buildDateSelector(colors),
          const SizedBox(height: 16),
          _buildHeaderCard(),
          const SizedBox(height: 16),
           _buildTabSelector(colors),
          const SizedBox(height: 16),
          if (_isLocked) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.elevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Catatan hari ini sudah lengkap dan terkunci.',
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: _isLocked,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isLocked ? 0.62 : 1.0,
                child: _buildActiveTabContent(colors),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildNavigationButtons(colors),
          const SizedBox(height: 90), // Spacing to avoid overlay of floating navbar
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColors colors;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: .15) : colors.elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : colors.line,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? AppColors.primary : colors.muted,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : colors.text,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

