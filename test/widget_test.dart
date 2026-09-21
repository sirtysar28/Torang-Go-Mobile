import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torang_go/core/app_config.dart';
import 'package:torang_go/core/theme.dart';
import 'package:torang_go/models/models.dart';
import 'package:torang_go/main_customer.dart';
import 'package:torang_go/main_driver.dart';
import 'package:torang_go/features/auth/login_screen.dart';

void main() {
  setUp(() {
    // Jangan ambil font lewat jaringan saat test — pakai fallback saja.
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });
  test('statusLabelId mengembalikan label Indonesia', () {
    expect(statusLabelId('searching_driver'), 'Mencari Driver');
    expect(statusLabelId('trip_started'), 'Perjalanan Dimulai');
    expect(statusLabelId('completed'), 'Selesai');
  });

  test('Order.fromJson memetakan JSON backend dengan benar', () {
    final order = Order.fromJson({
      'id': 7,
      'code': 'TG-0007',
      'service_type': 'ride',
      'status': 'driver_arrived',
      'status_label': 'Driver Tiba',
      'pickup': {
        'name': 'Pelabuhan Jailolo',
        'latitude': -0.67,
        'longitude': 127.52,
        'address': null,
      },
      'destination': {
        'name': 'Pasar Jailolo',
        'latitude': -0.68,
        'longitude': 127.53,
        'address': null,
      },
      'total_fare': 15000,
      'distance_km': 2.4,
      'payment_method': 'cash',
      'driver': null,
    });

    expect(order.id, 7);
    expect(order.isActive, isTrue);
    expect(order.label, 'Driver Tiba');
    expect(order.pickup.name, 'Pelabuhan Jailolo');
    expect(order.totalFare, 15000);
  });

  test('tema berisi warna brand Torang Go', () {
    expect(TG.ocean, const Color(0xFF1477E6));
    expect(TG.leaf, const Color(0xFF2FAE4E));
  });

  // Regresi untuk bug "blank sebelum login": SessionScope dulu hanya
  // membungkus `home:` — setelah splash & onboarding pushReplacement,
  // AuthGate tidak lagi menemukan SessionScope → build error → di build
  // release tampil sebagai layar blank. Test ini memastikan alur
  // splash → onboarding → login tetap sehat lintas route.
  testWidgets('customer: splash → onboarding → login tampil (tidak blank)',
      (tester) async {
    AppConfig.role = AppRole.customer; // setara main() di main_customer.dart
    await tester.pumpWidget(const TorangGoApp());

    // Lewati durasi splash (1,9 dtk) + transisi fade (450 ms).
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Antar torang ke mana saja'), findsOneWidget);

    // Selesaikan onboarding → harus mendarat di LoginScreen tanpa error.
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('Halo, torang! 👋'), findsOneWidget);
  });

  testWidgets('driver: splash → onboarding → login tampil (tidak blank)',
      (tester) async {
    AppConfig.role = AppRole.driver; // setara main() di main_driver.dart
    await tester.pumpWidget(const TorangGoDriverApp());

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Antar torang ke mana saja'), findsOneWidget);

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('Gas earning hari ini! 💪'), findsOneWidget);
  });
}
