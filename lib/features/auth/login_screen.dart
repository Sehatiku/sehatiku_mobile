import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/auth_models.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';
import 'package:sehatiku_mobile/data/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  /// Called after a successful login. Receives the persisted [Session].
  final ValueChanged<Session> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  final _userFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _userFocused = false;
  bool _passFocused = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  AnimationController? _pulseController;
  AnimationController? _ecgController;
  late final TapGestureRecognizer _faskesRecognizer;

  @override
  void initState() {
    super.initState();
    _userFocus.addListener(() {
      setState(() => _userFocused = _userFocus.hasFocus);
    });
    _passFocus.addListener(() {
      setState(() => _passFocused = _passFocus.hasFocus);
    });
    _initControllers();
    _faskesRecognizer = TapGestureRecognizer()..onTap = _contactFaskes;
  }

  void _initControllers() {
    _pulseController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _ecgController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void reassemble() {
    super.reassemble();
    _pulseController?.dispose();
    _pulseController = null;
    _ecgController?.dispose();
    _ecgController = null;
    _initControllers();
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _pulseController?.dispose();
    _ecgController?.dispose();
    _faskesRecognizer.dispose();
    super.dispose();
  }

  Future<void> _contactFaskes() async {
    final uri = Uri.parse('https://wa.me/628975228858');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka WhatsApp. Pastikan WhatsApp terinstal.'),
          ),
        );
      }
    }
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
    _doLogin(user, pass);
  }

  Future<void> _doLogin(String username, String password) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await AuthService.instance.loginPatient(
        username: username,
        password: password,
      );
      if (!mounted) return;
      widget.onLogin(session);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
        _loading = false;
      });
    }
  }

  String _friendlyError(ApiException e) {
    switch (e.statusCode) {
      case 401:
        return 'Username atau password salah.';
      case 429:
        return 'Terlalu banyak percobaan. Coba lagi dalam 15 menit.';
      case 400:
        return 'Data yang dimasukkan tidak valid.';
      case 0:
        return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
      default:
        return e.message.isNotEmpty ? e.message : 'Terjadi kesalahan (${ e.statusCode}).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colors.background : const Color(0xFFF2F6FA), // Light blue-grey background
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Curved Wave Header
            ClipPath(
              clipper: _HeaderWaveClipper(),
              child: Container(
                width: double.infinity,
                height: size.height * 0.36,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1B65EC), // Blue
                      Color(0xFF0F98DF), // Sky Blue
                      Color(0xFF00C69A), // Cyan-Green
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Container (Glassmorphic & Clean)
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/logowhite.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sehatiku',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selamat datang kembali 👋',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Overlapping White Card (Sleek, Modern, Simple)
            Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colors.line.withValues(alpha: isDark ? 0.5 : 0.3),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.03),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: const Color(0xFF1B65EC).withValues(alpha: isDark ? 0.05 : 0.015),
                      blurRadius: 50,
                      offset: const Offset(0, 24),
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masuk ke Sehatiku',
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Masuk dengan username dan password akun Anda.',
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Username Label & Field
                    _FieldLabel(text: 'Username', isFocused: _userFocused),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _userController,
                      focusNode: _userFocus,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                        fontSize: 14,
                      ),
                      decoration: _loginInput(
                        context: context,
                        icon: Icons.person_rounded,
                        hint: 'Masukkan username',
                        isFocused: _userFocused,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Label & Field
                    _FieldLabel(text: 'Password', isFocused: _passFocused),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passController,
                      focusNode: _passFocus,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                        fontSize: 14,
                      ),
                      decoration: _loginInput(
                        context: context,
                        icon: Icons.lock_rounded,
                        hint: 'Masukkan password',
                        isFocused: _passFocused,
                        suffix: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: _passFocused ? AppColors.primary : colors.muted,
                            size: 19,
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AppColors.red,
                                fontSize: 12,
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
                        onPressed: _contactFaskes,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Lupa password?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Submit Button (Matching Blue + Glow Shadow)
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: _loading
                              ? [const Color(0xFF8AAEE8), const Color(0xFF7A9FE0)]
                              : [const Color(0xFF2A6DEC), const Color(0xFF1B5CE3)],
                        ),
                        boxShadow: _loading
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF1B65EC).withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Masuk'),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Creative Heartbeat ECG Divider (Subtle but Unique medical anchor)
                    SizedBox(
                      width: double.infinity,
                      height: 20,
                      child: AnimatedBuilder(
                        animation: _ecgController ?? const AlwaysStoppedAnimation(0),
                        builder: (context, _) {
                          final ecgVal = _ecgController?.value ?? 0.0;
                          return CustomPaint(
                            painter: _SimpleEcgPainter(
                              progress: ecgVal,
                              color: colors.line.withValues(alpha: 0.7),
                              activeColor: AppColors.primary.withValues(alpha: 0.8),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Medical Encryption Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? colors.elevated : const Color(0xFFF6FBF9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? colors.line
                              : const Color(0xFFE2F0EC),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Data login Anda dienkripsi dan tidak dibagikan ke pihak lain.',
                              style: TextStyle(
                                color: isDark ? colors.muted : const Color(0xFF677E75),
                                fontSize: 11.5,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
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

            // 3. Register Nudge (At the Bottom)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Belum punya akun? ',
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: 'Hubungi Faskes Anda',
                        recognizer: _faskesRecognizer,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _loginInput({
    required BuildContext context,
    required IconData icon,
    required String hint,
    required bool isFocused,
    Widget? suffix,
  }) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      prefixIcon: Icon(
        icon, 
        color: isFocused ? AppColors.primary : colors.muted.withValues(alpha: 0.7), 
        size: 19,
      ),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: TextStyle(
        color: colors.muted.withValues(alpha: 0.6),
        fontWeight: FontWeight.w500,
        fontSize: 13.5,
      ),
      filled: true,
      fillColor: isDark ? colors.elevated : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isFocused
              ? AppColors.primary
              : (isDark ? colors.line : const Color(0xFFCBD5E1)),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isFocused
              ? AppColors.primary
              : (isDark ? colors.line : const Color(0xFFCBD5E1)),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.isFocused});

  final String text;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Text(
      text,
      style: TextStyle(
        color: isFocused ? AppColors.primary : colors.text,
        fontWeight: FontWeight.w800,
        fontSize: 13.5,
      ),
    );
  }
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    
    // Wave bezier curve
    final controlPoint = Offset(size.width * 0.46, size.height + 15);
    final endPoint = Offset(size.width, size.height - 50);
    
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Subtle, simple heartbeat ECG line divider
class _SimpleEcgPainter extends CustomPainter {
  _SimpleEcgPainter({
    required this.progress,
    required this.color,
    required this.activeColor,
  });

  final double progress;
  final Color color;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paintBase = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintActive = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final h = size.height;
    final w = size.width;

    path.moveTo(0, h * 0.5);
    path.lineTo(w * 0.4, h * 0.5);
    // Heartbeat Pulse peak
    path.lineTo(w * 0.44, h * 0.15);
    path.lineTo(w * 0.49, h * 0.85);
    path.lineTo(w * 0.54, h * 0.4);
    path.lineTo(w * 0.58, h * 0.5);
    path.lineTo(w, h * 0.5);

    // Draw baseline
    canvas.drawPath(path, paintBase);

    // Draw sweeping active heartbeat sweep
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final len = metric.length;
      final start = len * (progress - 0.15).clamp(0.0, 1.0);
      final end = len * progress;
      if (end > start) {
        final extract = metric.extractPath(start, end);
        canvas.drawPath(extract, paintActive);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleEcgPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
