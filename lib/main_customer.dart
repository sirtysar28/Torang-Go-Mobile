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
  AppConfig.role = AppRole.customer;

  // Status bar transparan & ikon gelap; navigation bar Android diberi
  // latar terang supaya bottom nav floating TIDAK tertutup tombol back /
  // gesture bar (tampil paling depan, full).
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

  runApp(const TorangGoApp());
}

class TorangGoApp extends StatefulWidget {
  const TorangGoApp({super.key});

  @override
  State<TorangGoApp> createState() => _TorangGoAppState();
}

class _TorangGoAppState extends State<TorangGoApp> {
  final _session = Session();

  @override
  void initState() {
    super.initState();
    _session.restore();
  }

  @override
  Widget build(BuildContext context) {
    // PENTING: SessionScope harus berada DI ATAS MaterialApp — bukan hanya
    // membungkus `home:`. Kalau hanya di `home:`, setelah splash/onboarding
    // melakukan pushReplacement, SessionScope ikut ter-dispose bersama route
    // home, sehingga AuthGate/LoginScreen crash "Null check operator used on
    // a null value" saat memanggil SessionScope.of(context) — di build release
    // crash ini tampak sebagai LAYAR BLANK sebelum halaman login.
    return SessionScope(
      session: _session,
      notifier: _session,
      child: MaterialApp(
        title: 'Torang Go',
        debugShowCheckedModeBanner: false,
        theme: TG.theme(context),
        home: const SplashScreen(next: OnboardingScreen(next: AuthGate())),
      ),
    );
  }
}
