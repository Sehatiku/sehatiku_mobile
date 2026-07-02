import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sehatiku_mobile/app/sehatiku_shell.dart';
import 'package:sehatiku_mobile/core/theme/app_colors.dart';
import 'package:sehatiku_mobile/data/repositories/auth_store.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';
import 'package:sehatiku_mobile/data/models/auth_models.dart';

class SehatikuApp extends StatefulWidget {
  const SehatikuApp({super.key});

  @override
  State<SehatikuApp> createState() => _SehatikuAppState();
}

class _SehatikuAppState extends State<SehatikuApp> {
  final HealthStore _store = HealthStore();
  bool _darkMode = false; // default light
  bool _authLoaded = false;
  Session? _initialSession;

  @override
  void initState() {
    super.initState();
    _store.load();
    _loadThemePref();
    _loadAuth();
  }

  Future<void> _loadThemePref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _darkMode = prefs.getBool('darkMode') ?? false);
  }

  Future<void> _loadAuth() async {
    await AuthStore.instance.load();
    if (mounted) {
      setState(() {
        _initialSession = AuthStore.instance.session;
        _authLoaded = true;
      });
    }
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _darkMode = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    _applyStatusBar(value);
  }

  void _applyStatusBar(bool dark) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          dark ? AppColors.dark.background : AppColors.light.background,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  ThemeData _buildDark() => _buildTheme(
        brightness: Brightness.dark,
        colors: AppColors.dark,
      );

  ThemeData _buildLight() => _buildTheme(
        brightness: Brightness.light,
        colors: AppColors.light,
      );

  ThemeData _buildTheme({
    required Brightness brightness,
    required AppColors colors,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.green,
        tertiary: AppColors.violet,
        surface: colors.surface,
        onSurface: colors.text,
        onPrimary: Colors.white,
        error: AppColors.red,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      cardColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.line),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.line, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          side: BorderSide(color: colors.line),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: colors.text,
        displayColor: colors.text,
      ),
      switchTheme: _switchTheme(AppColors.green),
      textSelectionTheme: _textSelection(),
      inputDecorationTheme: _inputTheme(colors),
      snackBarTheme: _snackTheme(colors),
      chipTheme: ChipThemeData(
        backgroundColor: colors.elevated,
        disabledColor: colors.elevated,
        selectedColor: AppColors.primary.withValues(alpha: .14),
        labelStyle: TextStyle(
          color: colors.text,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: colors.line),
        shape: const StadiumBorder(),
      ),
    );
  }

  SwitchThemeData _switchTheme(Color active) => SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.dark.muted),
    trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? active : AppColors.dark.elevated),
    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
  );

  TextSelectionThemeData _textSelection() => TextSelectionThemeData(
    cursorColor: AppColors.primary,
    selectionColor: AppColors.primary.withValues(alpha: .3),
    selectionHandleColor: AppColors.primary,
  );

  InputDecorationTheme _inputTheme(AppColors c) => InputDecorationTheme(
    filled: true,
    fillColor: c.elevated,
    hintStyle: TextStyle(color: c.muted.withValues(alpha: .7)),
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
  );

  SnackBarThemeData _snackTheme(AppColors c) => SnackBarThemeData(
    backgroundColor: c.elevated,
    contentTextStyle: TextStyle(color: c.text),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    behavior: SnackBarBehavior.floating,
  );

  @override
  Widget build(BuildContext context) {
    // Block rendering until auth state is resolved to avoid a flash to login.
    if (!_authLoaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
        theme: _buildLight(),
        darkTheme: _buildDark(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Sehatiku',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLight(),
      darkTheme: _buildDark(),
      home: AuthScope(
        child: HealthScope(
          store: _store,
          child: SehatikuShell(
            darkMode: _darkMode,
            onDarkMode: _setDarkMode,
            initialSession: _initialSession,
          ),
        ),
      ),
    );
  }
}
