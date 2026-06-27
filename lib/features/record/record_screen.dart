import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/health_record.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
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

  bool _medicineTaken = false;
  final Set<String> _meals = {};
  bool _active30 = false;
  int _sleepQuality = 1; // 0=Buruk, 1=Cukup, 2=Nyenyak
  int _stressIndex = 1; // 0=Santai, 1=Normal, 2=Tinggi
  bool _smoke = false;
  bool _alcohol = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    // Prep from existing record if logged today.
    final today = HealthScope.of(context).today;
    if (today != null) {
      if (today.bloodSugar != null) {
        _bsController.text = today.bloodSugar.toString();
      }
      if (today.systolic != null) {
        _sysController.text = today.systolic.toString();
      }
      if (today.diastolic != null) {
        _diaController.text = today.diastolic.toString();
      }
      _medicineTaken = today.medicineTaken;
      if (today.weight != null) {
        _weightController.text = today.weight.toString();
      }
      if (today.sleepHours != null) {
        _sleepController.text = today.sleepHours.toString();
      }
      _active30 = today.active30;
      _sleepQuality = today.sleepQuality;
      _stressIndex = today.stressIndex;
      _smoke = today.smoke;
      _alcohol = today.alcohol;
      _meals
        ..clear()
        ..addAll(today.meals);
      _noteController.text = today.note;
    }
  }

  @override
  void dispose() {
    _bsController.dispose();
    _sysController.dispose();
    _diaController.dispose();
    _weightController.dispose();
    _sleepController.dispose();
    _noteController.dispose();
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
    FocusScope.of(context).unfocus();

    final bs = _parseInt(_bsController);
    final sys = _parseInt(_sysController);
    final dia = _parseInt(_diaController);
    final w = _parseDouble(_weightController);
    final sleep = _parseDouble(_sleepController);

    // Validate if anything is filled.
    if (bs == null &&
        sys == null &&
        dia == null &&
        w == null &&
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

    final record = HealthRecord(
      date: HealthRecord.dayOf(DateTime.now()),
      bloodSugar: bs,
      systolic: sys,
      diastolic: dia,
      weight: w,
      medicineTaken: _medicineTaken,
      meals: {..._meals},
      active30: _active30,
      sleepHours: sleep,
      sleepQuality: _sleepQuality,
      stressIndex: _stressIndex,
      smoke: _smoke,
      alcohol: _alcohol,
      note: _noteController.text.trim(),
    );

    final store = HealthScope.of(context);
    await store.upsert(record);

    if (mounted) {
      widget.onSaved('Catatan tersimpan · Skor kesehatan ${record.score}/100.');
      widget.onView(MainView.beranda);
    }
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
          InputCard(
            title: 'Gula Darah',
            icon: Icons.water_drop_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.tint(AppColors.primary),
            children: [
              NumberField(
                controller: _bsController,
                hint: '105',
                unit: 'mg/dL',
                accent: AppColors.primary,
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
              Row(
                children: [
                  Expanded(
                    child: LabeledNumberField(
                      label: 'Sistolik',
                      controller: _sysController,
                      hint: '120',
                      accent: AppColors.pink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledNumberField(
                      label: 'Diastolik',
                      controller: _diaController,
                      hint: '80',
                      accent: AppColors.pink,
                    ),
                  ),
                ],
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
              NumberField(
                controller: _weightController,
                hint: '62',
                unit: 'kg',
                accent: AppColors.violet,
                allowDecimal: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.tint(AppColors.violet),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: AppColors.violet,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
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
                        'Metformin · 09.00',
                        style: TextStyle(color: colors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _medicineTaken,
                  onChanged: (v) => setState(() => _medicineTaken = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          InputCard(
            title: 'Makanan',
            icon: Icons.restaurant_rounded,
            iconColor: AppColors.orange,
            iconBg: AppColors.tint(AppColors.orange),
            children: [
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: const ['Sarapan', 'Makan Siang', 'Makan Malam', 'Camilan']
                    .map(
                      (meal) => SelectChip(
                        label: meal,
                        selected: _meals.contains(meal),
                        onTap: () => setState(() {
                          if (_meals.contains(meal)) {
                            _meals.remove(meal);
                          } else {
                            _meals.add(meal);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InputCard(
            title: 'Aktivitas Fisik',
            icon: Icons.directions_run_rounded,
            iconColor: AppColors.lime,
            iconBg: AppColors.tint(AppColors.lime),
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.tint(AppColors.lime),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      color: AppColors.lime,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                          'Jalan kaki, bersepeda, yoga, dll.',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _active30,
                    onChanged: (v) => setState(() => _active30 = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          InputCard(
            title: 'Kualitas Tidur',
            icon: Icons.bedtime_rounded,
            iconColor: AppColors.cyan,
            iconBg: AppColors.tint(AppColors.cyan),
            children: [
              NumberField(
                controller: _sleepController,
                hint: '7',
                unit: 'jam',
                accent: AppColors.cyan,
                allowDecimal: true,
              ),
              const SizedBox(height: 12),
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
                labels: const ['Buruk', 'Cukup', 'Nyenyak'],
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
              Row(
                children: [
                  Expanded(
                    child: StressTile(
                      emoji: '😌',
                      label: 'Santai',
                      selected: _stressIndex == 0,
                      onTap: () => setState(() => _stressIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: StressTile(
                      emoji: '😐',
                      label: 'Normal',
                      selected: _stressIndex == 1,
                      onTap: () => setState(() => _stressIndex = 1),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: StressTile(
                      emoji: '😣',
                      label: 'Tinggi',
                      selected: _stressIndex == 2,
                      onTap: () => setState(() => _stressIndex = 2),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: YesNoCard(
                  label: 'Merokok',
                  value: _smoke,
                  onChanged: (v) => setState(() => _smoke = v),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: YesNoCard(
                  label: 'Alkohol',
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
                    hintText:
                        'Hari ini terasa lebih berenergi setelah jalan pagi…',
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
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Simpan Data',
            icon: Icons.save_rounded,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
