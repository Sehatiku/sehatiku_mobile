import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sehatiku_mobile/core/app_colors.dart';
import 'package:sehatiku_mobile/models/app_models.dart';
import 'package:sehatiku_mobile/state/health_store.dart';
import 'package:sehatiku_mobile/widgets/sehatiku_widgets.dart';

const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const _dayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

String _dayName(DateTime d) => _dayNames[d.weekday - 1];
String _monthName(DateTime d) => _monthNames[d.month - 1];

/// e.g. "Senin, 23 Juni 2026".
String formatLongDate(DateTime d) =>
    '${_dayName(d)}, ${d.day} ${_monthName(d)} ${d.year}';

/// e.g. "Sen, 23 Jun".
String formatShortDate(DateTime d) =>
    '${_dayName(d).substring(0, 3)}, ${d.day} ${_monthName(d).substring(0, 3)}';

/// Time-aware Indonesian greeting.
String greeting() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat Pagi';
  if (h < 15) return 'Selamat Siang';
  if (h < 18) return 'Selamat Sore';
  return 'Selamat Malam';
}

String bloodSugarStatus(int? v) {
  if (v == null) return 'Belum dicatat';
  if (v < 70) return 'Rendah';
  if (v <= 130) return 'Normal';
  if (v <= 180) return 'Tinggi';
  return 'Sangat tinggi';
}

Color bloodSugarColor(int? v) {
  if (v == null) return AppColors.muted;
  if (v < 70) return AppColors.amber;
  if (v <= 130) return AppColors.green;
  if (v <= 180) return AppColors.orange;
  return AppColors.red;
}

String bloodPressureStatus(int? sys, int? dia) {
  if (sys == null || dia == null) return 'Belum dicatat';
  if (sys >= 140 || dia >= 90) return 'Tinggi';
  if (sys >= 130 || dia >= 85) return 'Waspada';
  if (sys < 90 || dia < 60) return 'Rendah';
  return 'Optimal';
}

Color bloodPressureColor(int? sys, int? dia) {
  if (sys == null || dia == null) return AppColors.muted;
  if (sys >= 140 || dia >= 90) return AppColors.red;
  if (sys >= 130 || dia >= 85) return AppColors.orange;
  if (sys < 90 || dia < 60) return AppColors.amber;
  return AppColors.green;
}

class TrendInfo {
  const TrendInfo(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

/// Summarises the direction of a metric series (oldest -> newest).
/// [lowerIsBetter] flips the colour semantics (e.g. blood sugar going down).
TrendInfo trendInfo(List<double> values, {bool lowerIsBetter = false}) {
  if (values.length < 2) {
    return const TrendInfo(
      'Belum cukup data',
      AppColors.muted,
      Icons.remove_rounded,
    );
  }
  final delta = values.last - values.first;
  if (delta.abs() < 0.0001) {
    return const TrendInfo(
      'Stabil',
      AppColors.muted,
      Icons.trending_flat_rounded,
    );
  }
  final goingDown = delta < 0;
  final good = lowerIsBetter ? goingDown : !goingDown;
  return TrendInfo(
    goingDown ? 'Menurun' : 'Meningkat',
    good ? AppColors.green : AppColors.orange,
    goingDown ? Icons.trending_down_rounded : Icons.trending_up_rounded,
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onContinue,
      child: Container(
        key: const ValueKey('splash'),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF1AA1C4), AppColors.green],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -60,
              child: SoftCircle(size: 280, opacity: .12),
            ),
            const Positioned(
              bottom: 60,
              left: -70,
              child: SoftCircle(size: 230, opacity: .10),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: 118, onColor: true),
                  const SizedBox(height: 26),
                  const Text(
                    'Sehatiku',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(
                    width: 260,
                    child: Text(
                      'Pendamping Kesehatan Anda Setiap Hari',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: 54,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                      backgroundColor: Color(0x4DFFFFFF),
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Ketuk untuk lanjut',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.index,
    required this.onDot,
    required this.onSkip,
    required this.onNext,
  });

  final int index;
  final ValueChanged<int> onDot;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  static const items = [
    OnboardingItem(
      icon: Icons.insert_chart_rounded,
      title: 'Pantau Kesehatan Lebih Mudah',
      desc:
          'Catat gula darah, tekanan, dan obat harian Anda dalam satu tempat yang rapi dan jelas.',
      colors: [AppColors.primary, AppColors.cyan],
      blob: Color(0xFFBCDFFF),
    ),
    OnboardingItem(
      icon: Icons.psychology_alt_rounded,
      title: 'AI Membantu Memahami Kondisi Anda',
      desc:
          'Dapatkan analisis dan rekomendasi personal berbasis Machine Learning setiap hari.',
      colors: [AppColors.violet, AppColors.cyan],
      blob: Color(0xFFDCD2FF),
    ),
    OnboardingItem(
      icon: Icons.spa_rounded,
      title: 'Mulai Hidup Lebih Sehat Hari Ini',
      desc:
          'Bangun kebiasaan sehat dengan pengingat lembut dan pendampingan menyeluruh.',
      colors: [AppColors.green, AppColors.lime],
      blob: Color(0xFFBFF0DF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final item = items[index];
    final compact = MediaQuery.sizeOf(context).height < 700;
    final visualSize = compact ? 196.0 : 248.0;
    final cardSize = compact ? 150.0 : 188.0;
    final cardRadius = compact ? 36.0 : 46.0;
    final iconSize = compact ? 76.0 : 96.0;
    return SafeArea(
      key: const ValueKey('onboarding'),
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, compact ? 8 : 18, 28, 28),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onSkip, child: const Text('Lewati')),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: visualSize,
                        height: visualSize,
                        decoration: BoxDecoration(
                          color: item.blob.withValues(alpha: .5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Transform.rotate(
                        angle: -math.pi / 30,
                        child: Container(
                          width: cardSize,
                          height: cardSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(cardRadius),
                            gradient: LinearGradient(colors: item.colors),
                            boxShadow: [
                              BoxShadow(
                                color: item.colors.first.withValues(alpha: .35),
                                blurRadius: 54,
                                offset: const Offset(0, 24),
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: math.pi / 30,
                            child: Icon(
                              item.icon,
                              color: Colors.white,
                              size: iconSize,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 22 : 44),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: compact ? 24 : 27,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  Text(
                    item.desc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: compact ? 14 : 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                items.length,
                (i) => GestureDetector(
                  onTap: () => onDot(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: index == i ? 26 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == i
                          ? AppColors.primary
                          : const Color(0xFFBCD0E6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 18 : 28),
            PrimaryButton(
              label: index < 2 ? 'Lanjut' : 'Mulai Sekarang',
              icon: Icons.arrow_forward_rounded,
              onPressed: onNext,
            ),
            if (index == 2)
              TextButton(
                onPressed: onSkip,
                child: const Text(
                  'Masuk',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final user = _userController.text.trim();
    final pass = _passController.text;
    if (user.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Username dan password wajib diisi.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter.');
      return;
    }
    setState(() => _error = null);
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('login'),
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: 250,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.green, AppColors.primary, AppColors.violet],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x2E5B3FD8),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                top: -56,
                right: -44,
                child: SoftCircle(size: 200, opacity: .14),
              ),
              const Positioned(
                top: 36,
                right: 40,
                child: SoftCircle(size: 64, opacity: .10),
              ),
              const Positioned(
                bottom: -34,
                left: -30,
                child: SoftCircle(size: 150, opacity: .10),
              ),
              const Positioned(
                bottom: 30,
                left: 44,
                child: SoftCircle(size: 26, opacity: .14),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: .35),
                            blurRadius: 36,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const BrandLogo(size: 76, radius: 22, onColor: true),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Sehatiku',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Selamat datang kembali 👋',
                      style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x241565D8),
                  blurRadius: 50,
                  offset: Offset(0, 24),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masuk ke Sehatiku',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Masuk dengan username dan password akun Anda.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                const _FieldLabel('Username'),
                const SizedBox(height: 8),
                TextField(
                  controller: _userController,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                  decoration: _loginInput(
                    icon: Icons.person_rounded,
                    hint: 'Masukkan username',
                  ),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Password'),
                const SizedBox(height: 8),
                TextField(
                  controller: _passController,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                  decoration: _loginInput(
                    icon: Icons.lock_rounded,
                    hint: 'Masukkan password',
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: AppColors.muted,
                        size: 21,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.red,
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Lupa password?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppColors.primary, AppColors.violet],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violet.withValues(alpha: .38),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Masuk'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pale,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        size: 17,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Data login Anda dienkripsi dan tidak dibagikan ke pihak lain.',
                          style: TextStyle(
                            color: AppColors.muted.withValues(alpha: .95),
                            fontSize: 11.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 30),
          child: Text.rich(
            TextSpan(
              text: 'Belum punya akun? ',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
              children: [
                TextSpan(
                  text: 'Hubungi Faskes Anda',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  InputDecoration _loginInput({
    required IconData icon,
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.muted, size: 21),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFB6C3D2),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: AppColors.pale,
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF46586B),
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class AppHome extends StatelessWidget {
  const AppHome({
    super.key,
    required this.view,
    required this.progressIndex,
    required this.rangeIndex,
    required this.forecastIndex,
    required this.educationFilter,
    required this.darkMode,
    required this.onView,
    required this.onProgress,
    required this.onRange,
    required this.onForecast,
    required this.onEducationFilter,
    required this.onDarkMode,
    required this.onAction,
    required this.onLogout,
  });

  final MainView view;
  final int progressIndex;
  final int rangeIndex;
  final int forecastIndex;
  final int educationFilter;
  final bool darkMode;
  final ValueChanged<MainView> onView;
  final ValueChanged<int> onProgress;
  final ValueChanged<int> onRange;
  final ValueChanged<int> onForecast;
  final ValueChanged<int> onEducationFilter;
  final ValueChanged<bool> onDarkMode;
  final ValueChanged<String> onAction;
  final VoidCallback onLogout;

  bool get _showNav => {
    MainView.beranda,
    MainView.catatan,
    MainView.ai,
    MainView.progres,
    MainView.profil,
  }.contains(view);

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('app'),
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE9F3FF),
                  Color(0xFFF4F9FF),
                  Color(0xFFFBFDFF),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (view) {
              MainView.beranda => DashboardScreen(onView: onView),
              MainView.catatan => RecordScreen(
                onSaved: onAction,
                onView: onView,
              ),
              MainView.ai => AiScreen(
                forecastIndex: forecastIndex,
                onForecast: onForecast,
                onAction: onAction,
              ),
              MainView.progres => ProgressScreen(
                progressIndex: progressIndex,
                rangeIndex: rangeIndex,
                onProgress: onProgress,
                onRange: onRange,
              ),
              MainView.profil => ProfileScreen(
                darkMode: darkMode,
                onDarkMode: onDarkMode,
                onLogout: onLogout,
                onAction: onAction,
                onDoctor: () => onView(MainView.dokter),
              ),
              MainView.dokter => DoctorScreen(
                onBack: () => onView(MainView.beranda),
                onAction: onAction,
              ),
              MainView.riwayat => HistoryScreen(
                onBack: () => onView(MainView.beranda),
              ),
              MainView.notifikasi => NotificationScreen(
                onBack: () => onView(MainView.beranda),
              ),
              MainView.edukasi => EducationScreen(
                onBack: () => onView(MainView.beranda),
                selectedFilter: educationFilter,
                onFilter: onEducationFilter,
                onAction: onAction,
              ),
            },
          ),
        ),
        if (_showNav)
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: FloatingNav(view: view, onView: onView),
          ),
      ],
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onView});

  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    final store = HealthScope.of(context);
    final latest = store.latest;
    final today = store.today;
    final hasData = latest != null;
    final bsRecords = store
        .recent(7)
        .where((r) => r.bloodSugar != null)
        .toList();
    final bsValues = bsRecords.map((r) => r.bloodSugar!.toDouble()).toList();
    final bsTrend = trendInfo(bsValues, lowerIsBetter: true);
    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.violet, AppColors.cyan],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: .35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  'LV',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${greeting()},',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'Lavinia 👋',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  IconCircle(
                    icon: Icons.notifications_rounded,
                    onTap: () => onView(MainView.notifikasi),
                  ),
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          HealthScoreCard(record: latest),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: SectionTitle(title: 'Ringkasan Terakhir')),
              const SizedBox(width: 8),
              Text(
                hasData ? formatShortDate(latest.date) : 'Belum ada data',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (!hasData)
            _EmptyDataCard(onView: onView)
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 13,
              crossAxisSpacing: 13,
              childAspectRatio: 1.4,
              children: [
                SummaryCard(
                  icon: Icons.water_drop_rounded,
                  label: 'Gula Darah',
                  value: latest.bloodSugar?.toString() ?? '—',
                  unit: 'mg/dL',
                  status: bloodSugarStatus(latest.bloodSugar),
                  statusColor: bloodSugarColor(latest.bloodSugar),
                  iconColor: AppColors.primary,
                ),
                SummaryCard(
                  icon: Icons.favorite_rounded,
                  label: 'Tekanan Darah',
                  value: latest.bloodPressure,
                  status: bloodPressureStatus(
                    latest.systolic,
                    latest.diastolic,
                  ),
                  statusColor: bloodPressureColor(
                    latest.systolic,
                    latest.diastolic,
                  ),
                  iconColor: AppColors.pink,
                ),
                SummaryCard(
                  icon: Icons.monitor_weight_rounded,
                  label: 'Berat Badan',
                  value: latest.weight != null
                      ? latest.weight!.toStringAsFixed(
                          latest.weight! % 1 == 0 ? 0 : 1,
                        )
                      : '—',
                  unit: 'kg',
                  status: 'Tercatat',
                  statusColor: AppColors.muted,
                  iconColor: AppColors.violet,
                ),
                SummaryCard(
                  icon: Icons.medication_rounded,
                  label: 'Obat',
                  value: latest.medicineTaken ? 'Diminum' : 'Terlewat',
                  status: latest.medicineTaken
                      ? 'Tepat waktu'
                      : 'Belum diminum',
                  statusColor: latest.medicineTaken
                      ? AppColors.lime
                      : AppColors.red,
                  iconColor: latest.medicineTaken
                      ? AppColors.lime
                      : AppColors.red,
                  valueIcon: latest.medicineTaken
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                ),
              ],
            ),
          if (today == null) ...[
            const SizedBox(height: 14),
            _TodayPromptCard(onView: onView),
          ],
          const SizedBox(height: 28),
          const SectionTitle(title: 'Aksi Cepat'),
          const SizedBox(height: 13),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 13,
            crossAxisSpacing: 13,
            childAspectRatio: 1.25,
            children: [
              BigAction(
                icon: Icons.edit_note_rounded,
                label: 'Catat Hari Ini',
                colors: const [AppColors.primary, AppColors.cyan],
                onTap: () => onView(MainView.catatan),
              ),
              BigAction(
                icon: Icons.history_rounded,
                label: 'Riwayat',
                colors: const [AppColors.green, AppColors.lime],
                onTap: () => onView(MainView.riwayat),
              ),
              BigAction(
                icon: Icons.menu_book_rounded,
                label: 'Edukasi',
                colors: const [AppColors.violet, AppColors.cyan],
                onTap: () => onView(MainView.edukasi),
              ),
              BigAction(
                icon: Icons.medical_services_rounded,
                label: 'Hubungi Dokter',
                colors: const [AppColors.pink, Color(0xFFFF9472)],
                onTap: () => onView(MainView.dokter),
              ),
            ],
          ),
          const SizedBox(height: 26),
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => onView(MainView.ai),
            child: GradientPanel(
              radius: 26,
              colors: const [
                AppColors.violet,
                Color(0xFF9B7BFF),
                AppColors.cyan,
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Insight AI Hari Ini',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '"Kondisi Anda stabil. Pertahankan pola makan rendah garam hari ini."',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Text(
                        'Lihat detail',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: 16,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.alarm_rounded,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minum Obat Metformin',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hari ini, pukul 09.00',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '09:00',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Gula Darah · ${bsValues.length} catatan',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(bsTrend.icon, color: bsTrend.color, size: 15),
                        const SizedBox(width: 3),
                        Text(
                          bsTrend.label,
                          style: TextStyle(
                            color: bsTrend.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  child: bsValues.length < 2
                      ? const _ChartEmpty()
                      : TrendChart(color: AppColors.primary, values: bsValues),
                ),
                const SizedBox(height: 6),
                if (bsValues.length >= 2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: bsRecords
                        .map(
                          (r) => Text(
                            _dayName(r.date).substring(0, 3),
                            style: const TextStyle(
                              color: Color(0xFF9AA9BB),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFDFF3EC), Color(0xFFEAF2FE)],
              ),
              border: Border.all(color: AppColors.green.withValues(alpha: .12)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -4,
                  right: 0,
                  child: Icon(
                    Icons.format_quote_rounded,
                    size: 36,
                    color: AppColors.green.withValues(alpha: .3),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: Text(
                    'Kesehatan adalah investasi terbaik untuk masa depan Anda.',
                    style: TextStyle(
                      color: Color(0xFF1F5E4F),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HealthScoreCard extends StatelessWidget {
  const HealthScoreCard({super.key, this.record});

  final HealthRecord? record;

  @override
  Widget build(BuildContext context) {
    final score = record?.score ?? 0;
    final label = record?.statusLabel ?? 'Belum ada';
    final subtitle = record == null
        ? 'Catat data harian pertama Anda untuk melihat skor.'
        : _scoreInsight(score);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.green, Color(0xFF13A8B8), AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: .45),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        children: [
          ScoreRing(
            progress: score / 100,
            color: Colors.white,
            size: 124,
            stroke: 14,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const Text(
                  'dari 100',
                  style: TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Kesehatan Terkini',
                  style: TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Dot(color: Color(0xFFC9FF8F)),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'Bukan diagnosis medis',
                          style: TextStyle(
                            color: Color(0xF2FFFFFF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _scoreInsight(int score) {
  if (score >= 85) {
    return 'Kondisi Anda sangat baik. Pertahankan kebiasaan ini.';
  }
  if (score >= 70) return 'Kondisi Anda baik. Sedikit perbaikan akan membantu.';
  if (score >= 60) return 'Perlu perhatian pada beberapa indikator hari ini.';
  return 'Beberapa indikator perlu diperhatikan. Tetap jaga pola hidup.';
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Placeholder shown inside a chart card when there aren't enough points yet.
class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty();

  static const message = 'Butuh minimal 2 catatan untuk menampilkan grafik';

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.pale,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.show_chart_rounded,
            color: Color(0xFFB6C3D2),
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown on the dashboard when no records exist yet.
class _EmptyDataCard extends StatelessWidget {
  const _EmptyDataCard({required this.onView});

  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: 22,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada catatan kesehatan',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mulai catat gula darah, tekanan, dan obat harian Anda untuk melihat ringkasan dan skor di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Catat Sekarang',
            icon: Icons.add_rounded,
            onPressed: () => onView(MainView.catatan),
          ),
        ],
      ),
    );
  }
}

/// Nudges the user to log today's data when only older records exist.
class _TodayPromptCard extends StatelessWidget {
  const _TodayPromptCard({required this.onView});

  final ValueChanged<MainView> onView;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onView(MainView.catatan),
      child: AppCard(
        padding: 16,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F7EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.today_rounded,
                color: AppColors.green,
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum mencatat hari ini',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ketuk untuk mengisi catatan harian.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC2CEDB)),
          ],
        ),
      ),
    );
  }
}

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

double _avg(List<double> v) =>
    v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

/// Resolved data for one tab of the progress screen.
class _ProgressMetric {
  _ProgressMetric({
    required this.name,
    required this.color,
    required this.records,
    required this.values,
    required this.averageText,
    required this.highText,
    required this.lowText,
    required this.lowerIsBetter,
  });

  final String name;
  final Color color;
  final List<HealthRecord> records;
  final List<double> values;
  final String averageText;
  final String highText;
  final String lowText;
  final bool lowerIsBetter;

  String insight(TrendInfo t, bool hasChart) {
    if (!hasChart) {
      return 'Tambahkan minimal 2 catatan $name untuk melihat analisis tren otomatis.';
    }
    if (t.label == 'Stabil') {
      return '$name Anda relatif stabil dalam ${records.length} catatan terakhir. Pertahankan rutinitas Anda.';
    }
    final good = t.color == AppColors.green;
    final dir = t.label.toLowerCase();
    return good
        ? '$name Anda $dir ke arah yang baik. Konsistensi Anda membuahkan hasil.'
        : '$name Anda $dir. Perhatikan kembali pola makan, aktivitas, dan obat Anda.';
  }
}

_ProgressMetric _metricFor(int index, List<HealthRecord> recs) {
  switch (index) {
    case 1:
      final rs = recs
          .where((r) => r.systolic != null && r.diastolic != null)
          .toList();
      final sys = rs.map((r) => r.systolic!.toDouble()).toList();
      final dia = rs.map((r) => r.diastolic!.toDouble()).toList();
      return _ProgressMetric(
        name: 'Tekanan Darah',
        color: AppColors.pink,
        records: rs,
        values: sys,
        lowerIsBetter: true,
        averageText: rs.isEmpty
            ? '—'
            : '${_avg(sys).round()}/${_avg(dia).round()}',
        highText: sys.isEmpty ? '—' : '${sys.reduce(math.max).round()}',
        lowText: sys.isEmpty ? '—' : '${sys.reduce(math.min).round()}',
      );
    case 2:
      final rs = recs.where((r) => r.weight != null).toList();
      final vals = rs.map((r) => r.weight!).toList();
      return _ProgressMetric(
        name: 'Berat Badan',
        color: AppColors.violet,
        records: rs,
        values: vals,
        lowerIsBetter: false,
        averageText: vals.isEmpty ? '—' : '${_avg(vals).toStringAsFixed(1)} kg',
        highText: vals.isEmpty ? '—' : vals.reduce(math.max).toStringAsFixed(1),
        lowText: vals.isEmpty ? '—' : vals.reduce(math.min).toStringAsFixed(1),
      );
    case 3:
      final rs = recs.toList();
      final vals = rs.map((r) => r.medicineTaken ? 100.0 : 0.0).toList();
      final taken = rs.where((r) => r.medicineTaken).length;
      return _ProgressMetric(
        name: 'Kepatuhan Obat',
        color: AppColors.green,
        records: rs,
        values: vals,
        lowerIsBetter: false,
        averageText: vals.isEmpty ? '—' : '${_avg(vals).round()}%',
        highText: rs.isEmpty ? '—' : '$taken hari',
        lowText: rs.isEmpty ? '—' : '${rs.length - taken} hari',
      );
    default:
      final rs = recs.where((r) => r.bloodSugar != null).toList();
      final vals = rs.map((r) => r.bloodSugar!.toDouble()).toList();
      return _ProgressMetric(
        name: 'Gula Darah',
        color: AppColors.primary,
        records: rs,
        values: vals,
        lowerIsBetter: true,
        averageText: vals.isEmpty ? '—' : '${_avg(vals).round()} mg/dL',
        highText: vals.isEmpty ? '—' : '${vals.reduce(math.max).round()}',
        lowText: vals.isEmpty ? '—' : '${vals.reduce(math.min).round()}',
      );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({
    super.key,
    required this.progressIndex,
    required this.rangeIndex,
    required this.onProgress,
    required this.onRange,
  });

  final int progressIndex;
  final int rangeIndex;
  final ValueChanged<int> onProgress;
  final ValueChanged<int> onRange;

  @override
  Widget build(BuildContext context) {
    final store = HealthScope.of(context);
    final count = const [7, 30, 365][rangeIndex];
    final recs = store.recent(count);
    final metric = _metricFor(progressIndex, recs);
    final color = metric.color;
    final values = metric.values;
    final hasChart = values.length >= 2;
    final trend = trendInfo(values, lowerIsBetter: metric.lowerIsBetter);
    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            title: 'Progres Kesehatan',
            subtitle: 'Pantau tren Anda dari waktu ke waktu',
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: PillTab(
                      label: const [
                        'Gula Darah',
                        'Tekanan Darah',
                        'Berat Badan',
                        'Kepatuhan Obat',
                      ][i],
                      selected: progressIndex == i,
                      onTap: () => onProgress(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            padding: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${metric.name} · Rata-rata',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metric.averageText,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SegmentedMini(
                      labels: const ['Minggu', 'Bulan', 'Tahun'],
                      selected: rangeIndex,
                      onTap: onRange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 170,
                  child: hasChart
                      ? TrendChart(color: color, values: values)
                      : const _ChartEmpty(),
                ),
                const SizedBox(height: 8),
                if (hasChart)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatShortDate(metric.records.first.date),
                        style: const TextStyle(
                          color: Color(0xFF9AA9BB),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatShortDate(metric.records.last.date),
                        style: const TextStyle(
                          color: Color(0xFF9AA9BB),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 13,
            crossAxisSpacing: 13,
            childAspectRatio: 1.9,
            children: [
              StatBox(
                label: 'Tertinggi',
                value: metric.highText,
                color: AppColors.pink,
              ),
              StatBox(
                label: 'Terendah',
                value: metric.lowText,
                color: AppColors.green,
              ),
              StatBox(
                label: 'Rata-rata',
                value: metric.averageText,
                color: AppColors.primary,
              ),
              StatBox(
                label: 'Tren',
                value: hasChart ? trend.label : '—',
                color: hasChart ? trend.color : AppColors.muted,
                icon: hasChart ? trend.icon : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFFF0EBFF), Color(0xFFEAF2FE)],
              ),
              border: Border.all(
                color: AppColors.violet.withValues(alpha: .14),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: const LinearGradient(
                      colors: [AppColors.violet, AppColors.cyan],
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analisis AI',
                        style: TextStyle(
                          color: Color(0xFF5A4BB0),
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.insight(trend, hasChart),
                        style: const TextStyle(
                          color: Color(0xFF5A6B7D),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AiScreen extends StatelessWidget {
  const AiScreen({
    super.key,
    required this.forecastIndex,
    required this.onForecast,
    required this.onAction,
  });

  final int forecastIndex;
  final ValueChanged<int> onForecast;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final foreLabel = const ['7 hari', '30 hari', '90 hari'][forecastIndex];
    final latest = HealthScope.of(context).latest;
    final risk = latest?.riskPercent ?? 0;
    final hasData = latest != null;
    final riskColor = !hasData
        ? AppColors.muted
        : risk < 15
        ? AppColors.lime
        : risk < 30
        ? AppColors.amber
        : AppColors.red;
    final riskLabel = !hasData
        ? 'Belum ada data'
        : risk < 15
        ? 'Risiko Rendah'
        : risk < 30
        ? 'Risiko Sedang'
        : 'Risiko Tinggi';
    final riskDesc = !hasData
        ? 'Catat data harian Anda agar AI dapat memperkirakan risiko komplikasi.'
        : risk < 15
        ? 'Indikator diabetes & hipertensi Anda terkendali dengan baik.'
        : risk < 30
        ? 'Beberapa indikator perlu diperhatikan minggu ini.'
        : 'Beberapa indikator berisiko. Pertimbangkan konsultasi dengan dokter Anda.';
    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.violet, Color(0xFF6F78F0), AppColors.green],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 7),
                    Text(
                      'Didukung AI & Machine Learning',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Asisten AI Sehatiku',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Analisis personal dari data kesehatan harian Anda',
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Rekomendasi Hari Ini'),
              const SizedBox(height: 13),
              AppCard(
                padding: 6,
                child: Column(
                  children: const [
                    RecommendTile(
                      icon: Icons.restaurant_rounded,
                      color: AppColors.lime,
                      bg: Color(0xFFE7F7EC),
                      title: 'Kurangi asupan garam',
                      desc: 'Maksimal 1 sendok teh per hari',
                      trailing: RecommendCheck(),
                    ),
                    _DividerLine(),
                    RecommendTile(
                      icon: Icons.water_drop_rounded,
                      color: AppColors.cyan,
                      bg: Color(0xFFEAF6FF),
                      title: 'Minum 2 liter air',
                      desc: 'Sekitar 8 gelas hari ini',
                      trailing: RecommendBadge(
                        text: '5/8',
                        color: AppColors.cyan,
                      ),
                    ),
                    _DividerLine(),
                    RecommendTile(
                      icon: Icons.directions_walk_rounded,
                      color: AppColors.lime,
                      bg: Color(0xFFE7F7EC),
                      title: 'Jalan kaki 30 menit',
                      desc: 'Pagi atau sore hari',
                      trailing: RecommendCheck(),
                    ),
                    _DividerLine(),
                    RecommendTile(
                      icon: Icons.bedtime_rounded,
                      color: AppColors.violet,
                      bg: Color(0xFFF0EBFF),
                      title: 'Tidur sebelum 22.00',
                      desc: 'Target 7-8 jam',
                      trailing: RecommendBadge(
                        text: 'Nanti',
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Prediksi Risiko'),
              const SizedBox(height: 13),
              AppCard(
                padding: 22,
                child: Row(
                  children: [
                    ScoreRing(
                      progress: risk / 100,
                      color: riskColor,
                      size: 104,
                      stroke: 16,
                      trackColor: const Color(0xFFEEF3F9),
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$risk%',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'risiko',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: riskColor.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _Dot(color: riskColor),
                                const SizedBox(width: 6),
                                Text(
                                  riskLabel,
                                  style: TextStyle(
                                    color: riskColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            riskDesc,
                            style: const TextStyle(
                              color: Color(0xFF5A6B7D),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SegmentedPills(
                labels: const ['7 Hari', '30 Hari', '90 Hari'],
                selected: forecastIndex,
                onTap: onForecast,
              ),
              const SizedBox(height: 16),
              GradientPanel(
                radius: 24,
                colors: const [AppColors.violet, AppColors.cyan],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Penjelasan AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      'Berdasarkan tren $foreLabel terakhir, gula darah & tekanan Anda diprediksi tetap stabil bila pola hidup sehat dipertahankan.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => onAction(
                        'Penjelasan lengkap prediksi $foreLabel dibuka.',
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Lihat Penjelasan Lengkap'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.violet,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: Color(0xFFEEF3F9),
      height: 1,
      indent: 12,
      endIndent: 12,
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.darkMode,
    required this.onDarkMode,
    required this.onLogout,
    required this.onAction,
    required this.onDoctor,
  });

  final bool darkMode;
  final ValueChanged<bool> onDarkMode;
  final VoidCallback onLogout;
  final ValueChanged<String> onAction;
  final VoidCallback onDoctor;

  @override
  Widget build(BuildContext context) {
    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil Saya',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.green],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .4),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .4),
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'LV',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lavinia Putri',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '28 tahun · Gol. Darah O',
                        style: TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Akun Terverifikasi',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: 18,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.monitor_heart_rounded,
                  iconBg: const Color(0xFFFFEEF2),
                  iconColor: AppColors.pink,
                  label: 'Riwayat Penyakit',
                  value: 'Diabetes Tipe 2, Hipertensi',
                ),
                const Divider(color: Color(0xFFEEF3F9), height: 1),
                _InfoRow(
                  icon: Icons.emergency_rounded,
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: AppColors.orange,
                  label: 'Kontak Darurat',
                  value: 'Andi (Suami) · 0812-3456',
                ),
                const Divider(color: Color(0xFFEEF3F9), height: 1),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onDoctor,
                  child: _InfoRow(
                    icon: Icons.medical_services_rounded,
                    iconBg: const Color(0xFFEAF2FE),
                    iconColor: AppColors.primary,
                    label: 'Dokter Penanggung Jawab',
                    value: 'dr. Surya Wijaya, Sp.PD',
                    trailing: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'PENGATURAN',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: 18,
            child: Column(
              children: [
                ProfileRow(
                  icon: Icons.lock_rounded,
                  label: 'Privasi',
                  onTap: () => onAction('Pengaturan privasi tersedia.'),
                ),
                const Divider(color: Color(0xFFEEF3F9), height: 1),
                ProfileRow(
                  icon: Icons.security_rounded,
                  iconColor: AppColors.green,
                  label: 'Keamanan',
                  onTap: () => onAction('Pengaturan keamanan tersedia.'),
                ),
                const Divider(color: Color(0xFFEEF3F9), height: 1),
                ProfileRow(
                  icon: Icons.language_rounded,
                  iconColor: AppColors.violet,
                  label: 'Bahasa',
                  trailing: const Text(
                    'Indonesia',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () => onAction('Bahasa: Indonesia.'),
                ),
                const Divider(color: Color(0xFFEEF3F9), height: 1),
                ProfileRow(
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF46586B),
                  label: 'Mode Gelap',
                  trailing: Switch(
                    value: darkMode,
                    onChanged: onDarkMode,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Keluar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF5A5A),
                side: const BorderSide(color: Color(0xFFFFD9DF)),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trailing = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailing)
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC2CEDB)),
        ],
      ),
    );
  }
}

class DoctorScreen extends StatelessWidget {
  const DoctorScreen({super.key, required this.onBack, required this.onAction});

  final VoidCallback onBack;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Dokter Saya',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: 24,
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.cyan],
                            ),
                          ),
                          child: const Text(
                            'SW',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.lime,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'dr. Surya Wijaya',
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Sp.PD · Penyakit Dalam',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.local_hospital_rounded,
                                size: 16,
                                color: AppColors.muted,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'RS Medika Husada',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(color: Color(0xFFEEF3F9), height: 1),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Expanded(
                      child: _DoctorStat(value: '4.9', label: 'Rating'),
                    ),
                    _StatDivider(),
                    Expanded(
                      child: _DoctorStat(value: '12 th', label: 'Pengalaman'),
                    ),
                    _StatDivider(),
                    Expanded(
                      child: _DoctorStat(
                        value: 'Online',
                        label: 'Status',
                        valueColor: AppColors.lime,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      size: 21,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Jadwal Praktik',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ScheduleRow(day: 'Senin - Jumat', time: '08.00 - 14.00'),
                const Divider(color: Color(0xFFEEF3F9), height: 1),
                _ScheduleRow(day: 'Sabtu', time: '08.00 - 12.00'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () =>
                  onAction('Membuka chat WhatsApp dr. Surya Wijaya.'),
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Chat WhatsApp'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.whatsapp,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () => onAction('Profil dokter dibuka.'),
                    icon: const Icon(Icons.person_rounded, size: 20),
                    label: const Text('Profil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.line),
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
                    onPressed: () =>
                        onAction('Form konsultasi siap digunakan.'),
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
}

class _DoctorStat extends StatelessWidget {
  const _DoctorStat({
    required this.value,
    required this.label,
    this.valueColor = AppColors.text,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
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
    return Container(width: 1, height: 34, color: const Color(0xFFEEF3F9));
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
              style: const TextStyle(
                color: Color(0xFF46586B),
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

const _activityLabels = {
  'walk': 'Jalan kaki',
  'run': 'Lari',
  'cycle': 'Sepeda',
  'yoga': 'Yoga',
};

/// One-line summary of a record for history/search rows.
String recordSummary(HealthRecord r) {
  final parts = <String>[];
  if (r.bloodSugar != null) parts.add('Gula ${r.bloodSugar}');
  if (r.systolic != null && r.diastolic != null) {
    parts.add('Tekanan ${r.bloodPressure}');
  }
  if (r.weight != null) {
    parts.add(
      'Berat ${r.weight!.toStringAsFixed(r.weight! % 1 == 0 ? 0 : 1)} kg',
    );
  }
  parts.add(r.medicineTaken ? 'Obat tepat waktu' : 'Obat terlewat');
  if (r.activity != 'none' && r.activityMinutes > 0) {
    parts.add(
      '${_activityLabels[r.activity] ?? 'Aktivitas'} ${r.activityMinutes} mnt',
    );
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .07),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x141565D8),
                  blurRadius: 18,
                  offset: Offset(0, 8),
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
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
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
                color: AppColors.pale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: const Color(0xFFB6C3D2), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
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

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Notifikasi',
      onBack: onBack,
      child: Column(
        children: const [
          NotifCard(
            icon: Icons.alarm_rounded,
            color: AppColors.orange,
            bg: Color(0xFFFFF3E0),
            title: 'Pengingat Obat',
            desc: 'Saatnya minum Metformin pukul 09.00.',
            time: '2m',
          ),
          NotifCard(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.violet,
            bg: Color(0xFFF0EBFF),
            title: 'Peringatan AI',
            desc: 'Tekanan darah cenderung naik. Kurangi garam hari ini.',
            time: '1j',
          ),
          NotifCard(
            icon: Icons.event_rounded,
            color: AppColors.primary,
            bg: Color(0xFFEAF2FE),
            title: 'Janji Dokter',
            desc: 'Konsultasi dengan dr. Surya, besok pukul 10.00.',
            time: '3j',
          ),
          NotifCard(
            icon: Icons.task_alt_rounded,
            color: AppColors.lime,
            bg: Color(0xFFE7F7EC),
            title: 'Catatan Harian',
            desc: 'Data kesehatan hari ini berhasil disimpan. Skor 87!',
            time: '5j',
          ),
        ],
      ),
    );
  }
}

class EducationScreen extends StatelessWidget {
  const EducationScreen({
    super.key,
    required this.onBack,
    required this.selectedFilter,
    required this.onFilter,
    required this.onAction,
  });

  final VoidCallback onBack;
  final int selectedFilter;
  final ValueChanged<int> onFilter;
  final ValueChanged<String> onAction;

  static const _filters = ['Semua', 'Diabetes', 'Hipertensi', 'Nutrisi'];

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Edukasi Kesehatan',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _filters.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: PillTab(
                      label: _filters[i],
                      selected: selectedFilter == i,
                      compact: true,
                      onTap: () => onFilter(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GradientPanel(
            radius: 24,
            colors: const [AppColors.primary, AppColors.green],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 6),
                      Text(
                        'Pilihan Hari Ini',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mengelola Gula Darah di Rumah dengan Tepat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Color(0xD9FFFFFF),
                      size: 15,
                    ),
                    SizedBox(width: 5),
                    Text(
                      '5 menit baca',
                      style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Artikel untuk Anda'),
          const SizedBox(height: 12),
          ArticleTile(
            icon: Icons.restaurant_rounded,
            category: 'NUTRISI',
            title: '5 Makanan Penurun Tekanan Darah Alami',
            time: '4 menit baca',
            color: AppColors.primary,
            onTap: () => onAction('Membuka artikel nutrisi.'),
          ),
          ArticleTile(
            icon: Icons.directions_walk_rounded,
            category: 'AKTIVITAS',
            title: 'Olahraga Aman untuk Penderita Diabetes',
            time: '6 menit baca',
            color: AppColors.green,
            onTap: () => onAction('Membuka artikel aktivitas.'),
          ),
          ArticleTile(
            icon: Icons.medication_rounded,
            category: 'OBAT',
            title: 'Pentingnya Minum Obat Tepat Waktu',
            time: '3 menit baca',
            color: AppColors.violet,
            onTap: () => onAction('Membuka artikel obat.'),
          ),
          ArticleTile(
            icon: Icons.bedtime_rounded,
            category: 'TIDUR & STRES',
            title: 'Cara Tidur Berkualitas untuk Kontrol Gula',
            time: '5 menit baca',
            color: AppColors.orange,
            onTap: () => onAction('Membuka artikel tidur & stres.'),
          ),
        ],
      ),
    );
  }
}
