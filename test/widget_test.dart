import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sehatiku_mobile/app/sehatiku_app.dart';
import 'package:sehatiku_mobile/data/repositories/auth_store.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';

void main() {
  setUpAll(() {
    ApiClient.instance.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.contains('/api/v1/patients/auth/login')) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {
                'patient_id': '123',
                'faskes_id': '456',
                'full_name': 'Lavinia',
                'token': {
                  'access_token': 'fake_access_token',
                  'refresh_token': 'fake_refresh_token',
                  'expires_in': 900,
                }
              }
            },
          ));
        } else if (options.path.contains('/api/v1/patients/dashboard')) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {
                'profile': {
                  'full_name': 'Lavinia',
                  'age': 25,
                  'disease_type': 'diabetes_t2',
                  'companion_name': 'Andi (Suami)',
                  'companion_phone': '0812-3456',
                  'assigned_nakes_name': 'dr. Surya Wijaya, Sp.PD',
                },
                'risk': {
                  'score': 85,
                  'risk_label': 'rendah',
                  'status': 'aman',
                  'main_factor': 'Aktivitas fisik baik',
                  'scored_at': '2026-06-28T00:00:00Z',
                },
                'latest_measurements': {
                  'glucose': {
                    'value': 110,
                    'measured_at': '2026-06-28T00:00:00Z',
                  },
                  'blood_pressure': {
                    'systolic': 120,
                    'diastolic': 80,
                    'measured_at': '2026-06-28T00:00:00Z',
                  },
                },
                'logging': {
                  'logged_today': true,
                  'streak_days': 5,
                },
                'recommendations': [
                  'Kondisi Anda stabil. Pertahankan pola makan rendah garam hari ini.',
                  'Lakukan jalan kaki 30 menit sore ini.',
                ],
              }
            },
          ));
        } else if (options.path.contains('/api/v1/patients/summary')) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'message': 'ringkasan kesehatan berhasil diambil',
              'data': {
                'window': 7,
                'available': true,
                'available_windows': [7],
                'history_days': 4,
                'narrative': 'Berdasarkan tren 7 hari terakhir, gula darah & tekanan Anda diprediksi tetap stabil bila pola hidup sehat dipertahankan.',
              }
            },
          ));
        } else if (options.path.contains('/api/v1/patients/health-score')) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'message': 'success',
              'data': {
                'health_score': 37.0,
                'status': 'bahaya',
                'status_label': 'Parah',
                'message': 'Beberapa indikator berisiko. Pertimbangkan konsultasi dengan dokter Anda.',
                'top_penalties': [
                  'Tekanan darah sistolik tinggi',
                  'Kadar gula darah tinggi'
                ],
                'scored_at': '2026-06-28T00:00:00Z',
              }
            },
          ));
        } else if (options.path.contains('/api/v1/patients/assigned-nakes')) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {
                'nakes_id': '789',
                'full_name': 'dr. Surya Wijaya, Sp.PD',
                'role': 'dokter',
                'specialization': 'Spesialis Penyakit Dalam',
                'hospital': 'Puskesmas Sehat Sentosa',
                'whatsapp_phone': '0812-0000-1111',
                'email': 'surya@example.com',
                'sip_number': 'SIP/123/2026',
                'str_number': 'STR/456/2026',
                'schedule': [
                  {'day': 'Senin - Jumat', 'time': '08.00 - 14.00'},
                ],
              }
            },
          ));
        } else if (options.path.contains('/api/v1/patients/consultations')) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 201,
            data: {
              'message': 'Keluhan berhasil dikirim',
            },
          ));
        } else if (options.path.contains('/api/v1/patients/notifications/unread-count')) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'message': 'jumlah notifikasi belum dibaca',
              'data': {'unread_count': 1}
            },
          ));
        } else if (options.path.contains('/read') || options.path.contains('/read-all')) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'message': 'success',
              'data': null
            },
          ));
        } else if (options.path.contains('/api/v1/patients/notifications')) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': [
                {
                  'id': '1',
                  'title': 'Pengingat Obat',
                  'desc': 'Saatnya minum Metformin pukul 09.00.',
                  'type': 'medicine',
                  'created_at': '2026-06-29T09:00:00.000Z',
                  'is_read': false
                },
                {
                  'id': '2',
                  'title': 'Peringatan AI',
                  'desc': 'Tekanan darah cenderung naik. Kurangi garam hari ini.',
                  'type': 'ai',
                  'created_at': '2026-06-29T08:00:00.000Z',
                  'is_read': true
                }
              ]
            },
          ));
        } else if (options.path.contains('/api/v1/patients/baseline/history')) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': [
                {
                  'date': '2026-06-30',
                  'blood_sugar': 120,
                  'systolic': 125,
                  'diastolic': 80,
                  'weight': 70.0
                },
                {
                  'date': '2026-06-15',
                  'blood_sugar': 130,
                  'systolic': 130,
                  'diastolic': 85,
                  'weight': 72.5
                }
              ]
            },
          ));
        } else {
          handler.next(options);
        }
      },
    ));
  });

  testWidgets('Sehatiku splash, onboarding, login and app flow works', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.clear();
    await tester.pumpWidget(const SehatikuApp());
    await tester.idle();
    await tester.pump();

    // Splash
    expect(find.text('Sehatiku'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

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
    await tester.idle();
    await tester.pump();

    // Dashboard
    expect(find.text('Hallo Lavinia 👋'), findsOneWidget);
    expect(find.text('Health Score AI'), findsOneWidget);

    // Navigate to the daily record screen via the bottom nav.
    await tester.tap(find.text('Catat').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Catatan Harian'), findsOneWidget);
    expect(find.text('Gula Darah'), findsOneWidget);

    // Let the pending splash timer fire so the test ends cleanly.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('All screens render at phone size without overflow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.clear();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> settle() => tester.pump(const Duration(milliseconds: 350));

    await tester.pumpWidget(const SehatikuApp());
    await tester.idle();
    await tester.pump();

    // Skip splash -> onboarding -> login -> app.
    await tester.pump(const Duration(seconds: 3));
    await settle();
    await tester.tap(find.text('Lewati'));
    await settle();
    await tester.enterText(find.byType(TextField).at(0), 'lavinia');
    await tester.enterText(find.byType(TextField).at(1), 'rahasia123');
    await tester.tap(find.text('Masuk'));
    await settle();
    await tester.idle();
    await tester.pump();
    expect(find.text('Hallo Lavinia 👋'), findsOneWidget);

    // Main tabs via the floating navigation bar.
    await tester.tap(find.text('Catat').first);
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
    await tester.idle();
    await tester.pump();
    expect(find.text('Profil Saya'), findsOneWidget);

    // Profile -> doctor detail -> back.
    await tester.tap(find.text('Dokter Penanggung Jawab'));
    await settle();
    await tester.idle();
    await tester.pump();
    expect(find.text('Konsultasi Dokter'), findsWidgets);
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
