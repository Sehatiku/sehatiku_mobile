import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
import 'package:sehatiku_mobile/data/services/record_service.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key, required this.onSaved, required this.onView});

  final ValueChanged<String> onSaved;
  final ValueChanged<MainView> onView;

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
  String _selectedActivityType = 'Jalan Kaki';

  bool _medicineTaken = false;
  bool _saving = false;
  final Set<String> _meals = {};
  bool _active30 = false;
  int _sleepQuality = 1; // 0=Buruk, 1=Cukup, 2=Nyenyak
  int _stressIndex = 1; // 0=Santai, 1=Normal, 2=Tinggi
  bool _smoke = false;
  bool _alcohol = false;

  int _currentTab = 0; // 0: Vital, 1: Aktivitas, 2: Kondisi

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadToday());
  }

  void _loadToday() {
    final today = HealthScope.of(context).today;
    if (today == null || !mounted) return;
    setState(() {
      if (today.bloodSugar != null) {
        _bsController.text = today.bloodSugar.toString();
      }
      if (today.systolic != null) {
        _sysController.text = today.systolic.toString();
      }
      if (today.diastolic != null) {
        _diaController.text = today.diastolic.toString();
      }
      if (today.weight != null) {
        _weightController.text = _formatNum(today.weight!);
      }
      if (today.sleepHours != null) {
        _sleepController.text = _formatNum(today.sleepHours!);
      }
      _medicineTaken = today.medicineTaken;
      if (_medicineTaken) {
        _medicineNameController.text = today.medicineName.isEmpty ? 'Metformin' : today.medicineName;
        _medicineTimeController.text = today.medicineTime.isEmpty ? '09:00' : today.medicineTime;
      } else {
        _medicineNameController.text = today.medicineName;
        _medicineTimeController.text = today.medicineTime;
      }
      _meals
        ..clear()
        ..addAll(today.meals);
      _active30 = today.active30;
      _activityMinutesController.text = today.activityMinutes > 0 ? today.activityMinutes.toString() : (today.active30 ? '30' : '');
      _selectedActivityType = today.activityType.isEmpty ? 'Jalan Kaki' : today.activityType;
      if (!['Jalan Kaki', 'Bersepeda', 'Yoga', 'Senam', 'Lari'].contains(_selectedActivityType) && _selectedActivityType.isNotEmpty) {
        _customActivityController.text = _selectedActivityType;
        _selectedActivityType = 'Lainnya';
      }
      _sleepQuality = today.sleepQuality;
      _stressIndex = today.stressIndex;
      _smoke = today.smoke;
      _alcohol = today.alcohol;
      if (today.note.isNotEmpty) _noteController.text = today.note;
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

    final bs = _parseInt(_bsController);
    final sys = _parseInt(_sysController);
    final dia = _parseInt(_diaController);
    final w = _parseDouble(_weightController);
    final sleep = _parseDouble(_sleepController);

    if (bs == null &&
        sys == null &&
        dia == null &&
        w == null &&
        !_medicineTaken &&
        sleep == null &&
        _meals.isEmpty &&
        _noteController.text.trim().isEmpty) {
      widget.onSaved('Silakan masukkan minimal satu data kesehatan.');
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
      date: HealthRecord.dayOf(DateTime.now()),
      bloodSugar: bs,
      systolic: sys,
      diastolic: dia,
      weight: w,
      medicineTaken: _medicineTaken,
      medicineName: _medicineTaken ? (_medicineNameController.text.trim().isEmpty ? 'Metformin' : _medicineNameController.text.trim()) : '',
      medicineTime: _medicineTaken ? (_medicineTimeController.text.trim().isEmpty ? '09:00' : _medicineTimeController.text.trim()) : '',
      meals: {..._meals},
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

    // Upsert locally first
    await store.upsert(record);

    // Save to API asynchronously in background
    RecordService.instance.saveRecord(record).then((_) {
      store.clearPendingSync(record.date);
    }).catchError((_) {
      store.markPendingSync(record.date);
    });

    if (mounted) {
      widget.onSaved('Catatan tersimpan · Skor kesehatan ${record.score}/100.');
      widget.onView(MainView.beranda);
    }
  }

  // Calculates completion progress out of 8 parameters
  int get _filledCount {
    int count = 0;
    if (_bsController.text.trim().isNotEmpty) count++;
    if (_sysController.text.trim().isNotEmpty && _diaController.text.trim().isNotEmpty) count++;
    if (_weightController.text.trim().isNotEmpty) count++;
    if (_medicineTaken) count++;
    if (_meals.isNotEmpty) count++;
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
                    const Text(
                      'Bagaimana kondisimu hari ini?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatLongDate(DateTime.now()),
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
          onTap: () => adjust(-step),
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
          onTap: () => adjust(step),
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
                onTap: () => adjust(-step),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.line),
                  ),
                  child: Icon(Icons.remove_rounded, color: colors.text, size: 16),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: colors.muted,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    filled: true,
                    fillColor: colors.elevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
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
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => adjust(step),
                child: Container(
                  width: 38,
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
                    onTap: onTapSuffix,
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
            onTap: () {
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
            onTap: () {
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
                  onTap: () {
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

  Widget _buildMealChips(AppColors colors) {
    final mealTypes = [
      {'key': 'Sarapan', 'label': '🍳 Sarapan'},
      {'key': 'Makan Siang', 'label': '🍲 Makan Siang'},
      {'key': 'Makan Malam', 'label': '🥗 Makan Malam'},
      {'key': 'Camilan', 'label': '🍎 Camilan'},
    ];

    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: mealTypes.map((meal) {
        final key = meal['key']!;
        final label = meal['label']!;
        final isSelected = _meals.contains(key);

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (_meals.contains(key)) {
                _meals.remove(key);
              } else {
                _meals.add(key);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.orange.withValues(alpha: .15) : colors.elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.orange : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.orange : colors.text,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
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
            onTap: () => setState(() => _stressIndex = idx),
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
                  onTap: () => onChanged(false),
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
                  onTap: () => onChanged(true),
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
                _buildMealChips(colors),
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
                  onTap: (v) => setState(() => _sleepQuality = v),
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
                  label: 'Simpan Data',
                  icon: Icons.save_rounded,
                  onPressed: _save,
                ),
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
            subtitle: formatLongDate(DateTime.now()),
          ),
          const SizedBox(height: 16),
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildTabSelector(colors),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: _buildActiveTabContent(colors),
          ),
          const SizedBox(height: 20),
          _buildNavigationButtons(colors),
          const SizedBox(height: 90), // Spacing to avoid overlay of floating navbar
        ],
      ),
    );
  }
}

