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
  final _noteController = TextEditingController();

  bool _medicineTaken = false;
  final Set<String> _meals = {};
  String _activity = 'none';
  int _activityMinutes = 0;
  int _stressIndex = 1;
  bool _smoke = false;
  bool _alcohol = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    // Pre-fill from today's record so editing is continuous.
    final today = HealthScope.of(context).today;
    if (today != null) {
      _bsController.text = today.bloodSugar?.toString() ?? '';
      _sysController.text = today.systolic?.toString() ?? '';
      _diaController.text = today.diastolic?.toString() ?? '';
      _weightController.text = today.weight != null
          ? today.weight!.toStringAsFixed(today.weight! % 1 == 0 ? 0 : 1)
          : '';
      _noteController.text = today.note;
      _medicineTaken = today.medicineTaken;
      _meals
        ..clear()
        ..addAll(today.meals);
      _activity = today.activity;
      _activityMinutes = today.activityMinutes;
      _stressIndex = today.stressIndex;
      _smoke = today.smoke;
      _alcohol = today.alcohol;
    }
  }

  @override
  void dispose() {
    _bsController.dispose();
    _sysController.dispose();
    _diaController.dispose();
    _weightController.dispose();
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

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final sys = _parseInt(_sysController);
    final dia = _parseInt(_diaController);
    // Blood pressure must be entered as a pair to be meaningful.
    if ((sys == null) != (dia == null)) {
      widget.onSaved('Lengkapi tekanan sistolik dan diastolik.');
      return;
    }

    final record = HealthRecord(
      date: HealthRecord.dayOf(DateTime.now()),
      bloodSugar: _parseInt(_bsController),
      systolic: sys,
      diastolic: dia,
      weight: _parseDouble(_weightController),
      medicineTaken: _medicineTaken,
      meals: {..._meals},
      activity: _activity,
      activityMinutes: _activityMinutes,
      stressIndex: _stressIndex,
      smoke: _smoke,
      alcohol: _alcohol,
      note: _noteController.text.trim(),
    );

    await HealthScope.of(context).upsert(record);
    if (!mounted) return;
    widget.onSaved('Catatan tersimpan · Skor kesehatan ${record.score}/100.');
    widget.onView(MainView.beranda);
  }

  @override
  Widget build(BuildContext context) {
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
            iconBg: const Color(0xFFEAF2FE),
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
            iconBg: const Color(0xFFFFEEF2),
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
            iconBg: const Color(0xFFF0EBFF),
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
                    color: const Color(0xFFF0EBFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: AppColors.violet,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sudah Minum Obat',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Metformin · 09.00',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _medicineTaken,
                  onChanged: (v) => setState(() => _medicineTaken = v),
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          InputCard(
            title: 'Makanan',
            icon: Icons.restaurant_rounded,
            iconColor: AppColors.orange,
            iconBg: const Color(0xFFFFF3E0),
            children: [
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: ['Sarapan', 'Makan Siang', 'Makan Malam', 'Camilan']
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
            iconBg: const Color(0xFFE7F7EC),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: 3.2,
                children: [
                  ActivityTile(
                    icon: Icons.directions_walk_rounded,
                    label: 'Jalan Kaki',
                    selected: _activity == 'walk',
                    onTap: () => _selectActivity('walk'),
                  ),
                  ActivityTile(
                    icon: Icons.directions_run_rounded,
                    label: 'Lari',
                    selected: _activity == 'run',
                    onTap: () => _selectActivity('run'),
                  ),
                  ActivityTile(
                    icon: Icons.directions_bike_rounded,
                    label: 'Sepeda',
                    selected: _activity == 'cycle',
                    onTap: () => _selectActivity('cycle'),
                  ),
                  ActivityTile(
                    icon: Icons.self_improvement_rounded,
                    label: 'Yoga',
                    selected: _activity == 'yoga',
                    onTap: () => _selectActivity('yoga'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFEEF3F9), height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Durasi',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Stepper15(
                    minutes: _activityMinutes,
                    onChanged: (v) => setState(() => _activityMinutes = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          InputCard(
            title: 'Tingkat Stres',
            icon: Icons.mood_rounded,
            iconColor: AppColors.amber,
            iconBg: const Color(0xFFFFF8E6),
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
                const Text(
                  'Catatan Tambahan',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        'Hari ini terasa lebih berenergi setelah jalan pagi…',
                    filled: true,
                    fillColor: AppColors.pale,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.line),
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

  void _selectActivity(String key) {
    setState(() {
      if (_activity == key) {
        _activity = 'none';
      } else {
        _activity = key;
        if (_activityMinutes == 0) _activityMinutes = 30;
      }
    });
  }
}


/// Resolved data for one tab of the progress screen.
