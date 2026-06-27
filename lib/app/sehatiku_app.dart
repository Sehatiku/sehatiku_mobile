import 'package:flutter/material.dart';
import 'package:sehatiku_mobile/app/sehatiku_shell.dart';
import 'package:sehatiku_mobile/core/theme/app_colors.dart';
import 'package:sehatiku_mobile/data/repositories/health_store.dart';

class SehatikuApp extends StatefulWidget {
  const SehatikuApp({super.key});

  @override
  State<SehatikuApp> createState() => _SehatikuAppState();
}

class _SehatikuAppState extends State<SehatikuApp> {
  final HealthStore _store = HealthStore();

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sehatiku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.green,
          surface: Colors.white,
        ),
        fontFamily: 'sans',
      ),
      home: HealthScope(
        store: _store,
        child: const SehatikuShell(),
      ),
    );
  }
}
