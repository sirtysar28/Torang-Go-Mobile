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

  // Regresi "nama customer": driver harus melihat nama & no. HP customer
  // dari relasi user, bukan placeholder "- (-)".
  test('Order: nama & HP customer tersedia untuk driver', () {
    final order = Order.fromJson({
      'id': 9,
      'code': 'TG-0009',
      'service_type': 'food',
      'status': 'driver_assigned',
      'pickup': {
        'name': 'Warung Nasi Ikan',
        'latitude': -0.67,
        'longitude': 127.52,
      },
      'destination': {
        'name': 'Mardika',
        'latitude': -0.68,
        'longitude': 127.53,
      },
      'customer': {'id': 3, 'name': 'Rifky Ansari', 'phone': '081234567890'},
      'total_fare': 25000,
    });

    expect(order.customerName, 'Rifky Ansari');
    expect(order.customerPhone, '081234567890');

    // Order kirim tanpa relasi customer → fallback ke pengirim
    final kirim = Order.fromJson({
      'id': 10,
      'code': 'TG-0010',
      'service_type': 'send',
      'status': 'searching_driver',
      'pickup': {'name': 'A', 'latitude': -0.67, 'longitude': 127.52},
      'destination': {'name': 'B', 'latitude': -0.68, 'longitude': 127.53},
      'sender_name': 'Pengirim A',
      'sender_phone': '089999999999',
      'receiver_name': 'Penerima B',
      'receiver_phone': '087777777777',
      'item_type': 'Dokumen',
      'total_fare': 15000,
    });
    expect(kirim.customerName, 'Pengirim A');
    expect(kirim.customerPhone, '089999999999');
  });

  // Regresi "type 'String' is not a subtype of type 'int'": beberapa
  // hosting mengirim angka dari database sebagai string — parser model
  // harus tetap aman (tidak crash / layar error di app).
  test('Order.fromJson toleran angka bertipe string (hosting PDO)', () {
    final order = Order.fromJson({
      'id': '11',
      'code': 'TG-0011',
      'service_type': 'ride',
      'status': 'completed',
      'pickup': {'name': 'A', 'latitude': '-0.676', 'longitude': '127.529'},
      'destination': {'name': 'B', 'latitude': '-0.68', 'longitude': '127.53'},
      'total_fare': '17500',
      'distance_km': '3.2',
      'duration_minutes': '12',
      'rated': 1,
      'driver': {
        'id': '2',
        'name': 'Driver B',
        'rating': '4.8',
        'total_orders': '21',
      },
    });

    expect(order.id, 11);
    expect(order.totalFare, 17500);
    expect(order.distanceKm, 3.2);
    expect(order.durationMinutes, 12);
    expect(order.rated, isTrue);
    expect(order.driver?.rating, 4.8);
    expect(order.driver?.totalOrders, 21);
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
