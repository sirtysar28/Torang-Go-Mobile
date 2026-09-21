import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_config.dart';
import 'core/ca_bundle.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding_screen.dart';
import 'features/splash_screen.dart';

void main() {
  // Trust anchor tambahan (ISRG Root X1/X2) agar SSL Let's Encrypt
  // diterima juga di Android 7.0/7.1 — wajib sebelum request HTTPS pertama.
  CaBundle.init();
  AppConfig.role = AppRole.driver;

  // Status bar transparan & navigation bar Android terang — bottom nav
  // floating tampil full di depan tombol back / gesture bar.
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFFBF6EC),
      systemNavigationBarDividerColor: Color(0xFFE7E0CF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const TorangGoDriverApp());
}

class TorangGoDriverApp extends StatefulWidget {
  const TorangGoDriverApp({super.key});

  @override
  State<TorangGoDriverApp> createState() => _TorangGoDriverAppState();
}

class _TorangGoDriverAppState extends State<TorangGoDriverApp> {
  final _session = Session();

  @override
  void initState() {
    super.initState();
    _session.restore();
  }

  @override
  Widget build(BuildContext context) {
    // PENTING: SessionScope harus berada DI ATAS MaterialApp — bukan hanya
    // membungkus `home:` — agar semua route (splash → onboarding → login →
    // shell driver) tetap bisa akses session. Tanpa ini app BLANK sebelum
    // login di build release (lihat komentar di main_customer.dart).
    return SessionScope(
      session: _session,
      notifier: _session,
      child: MaterialApp(
        title: 'Torang Go Driver',
        debugShowCheckedModeBanner: false,
        theme: TG.theme(context),
        home: const SplashScreen(next: OnboardingScreen(next: AuthGate())),
      ),
    );
  }
}
