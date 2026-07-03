import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sehatiku_mobile/app/sehatiku_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // If Firebase fails to initialize, continue so the app can show an error
    // screen or fallback UI. Log for debugging.
    // ignore: avoid_print
    print('Failed to initialize Firebase: $e');
  }

  runApp(const SehatikuApp());
}
