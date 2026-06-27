import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sehatiku_mobile/app/sehatiku_app.dart';

void main() {
  testWidgets('Sehatiku splash, onboarding, login and app flow works', (
    tester,
  ) async {
    await tester.pumpWidget(const SehatikuApp());
    await tester.pump();

    // Splash
    expect(find.text('Sehatiku'), findsOneWidget);
    expect(find.text('Ketuk untuk lanjut'), findsOneWidget);

    await tester.tap(find.text('Ketuk untuk lanjut'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Onboarding
    expect(find.text('Pantau Kesehatan Lebih Mudah'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Lanjut'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Mulai Sekarang'));
    await tester.pump(const Duration(milliseconds: 400));

    // Login
    expect(find.text('Masuk ke Sehatiku'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'lavinia');
    await tester.enterText(find.byType(TextField).at(1), 'rahasia123');
    await tester.tap(find.text('Masuk'));
    await tester.pump(const Duration(milliseconds: 400));

    // Dashboard
    expect(find.text('Lavinia 👋'), findsOneWidget);
    expect(find.text('Status Kesehatan Terkini'), findsOneWidget);

    // Navigate to the daily record screen via the bottom nav.
    await tester.tap(find.text('Catat'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Catatan Harian'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    // Let the pending splash timer fire so the test ends cleanly.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('All screens render at phone size without overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> settle() => tester.pump(const Duration(milliseconds: 350));

    await tester.pumpWidget(const SehatikuApp());
    await tester.pump();

    // Skip splash -> onboarding -> login -> app.
    await tester.tap(find.text('Ketuk untuk lanjut'));
    await settle();
    await tester.tap(find.text('Lewati'));
    await settle();
    await tester.enterText(find.byType(TextField).at(0), 'lavinia');
    await tester.enterText(find.byType(TextField).at(1), 'rahasia123');
    await tester.tap(find.text('Masuk'));
    await settle();
    expect(find.text('Lavinia 👋'), findsOneWidget);

    // Main tabs via the floating navigation bar.
    await tester.tap(find.text('Catat'));
    await settle();
    expect(find.text('Catatan Harian'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
    await settle();
    expect(find.text('Asisten AI Sehatiku'), findsOneWidget);

    await tester.tap(find.text('Progres'));
    await settle();
    expect(find.text('Progres Kesehatan'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await settle();
    expect(find.text('Profil Saya'), findsOneWidget);

    // Profile -> doctor detail -> back.
    await tester.tap(find.text('Dokter Penanggung Jawab'));
    await settle();
    expect(find.text('Dokter Saya'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await settle();

    // Detail screens reachable from the dashboard.
    await tester.tap(find.text('Beranda'));
    await settle();
    await tester.ensureVisible(find.text('Riwayat'));
    await settle();
    await tester.tap(find.text('Riwayat'));
    await settle();
    expect(find.text('Riwayat Kesehatan'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await settle();

    await tester.ensureVisible(find.text('Edukasi'));
    await settle();
    await tester.tap(find.text('Edukasi'));
    await settle();
    expect(find.text('Edukasi Kesehatan'), findsOneWidget);
    await tester.tap(find.text('Diabetes'));
    await settle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await settle();

    await tester.tap(find.byIcon(Icons.notifications_rounded));
    await settle();
    expect(find.text('Notifikasi'), findsOneWidget);

    // Drain the pending splash timer.
    await tester.pump(const Duration(seconds: 3));
  });
}
