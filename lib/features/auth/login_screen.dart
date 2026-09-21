import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_config.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../customer/customer_shell.dart';
import '../diagnostics/connection_check_screen.dart';
import '../driver/driver_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_phone.text.trim().isEmpty || _password.text.isEmpty) {
      tgSnackbar(context, 'Nomor HP dan password wajib diisi.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await sessionOf(context).login(_phone.text.trim(), _password.text);
      if (!mounted) return;
      tgSnackbar(context, 'Selamat datang kembali! 👋');
    } catch (e) {
      if (mounted) tgSnackbar(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo(String phone, String pass) {
    _phone.text = phone;
    _password.text = pass;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = AppConfig.role == AppRole.driver;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: TG.brandGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          isDriver
                              ? Icons.two_wheeler_rounded
                              : Icons.electric_bolt_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDriver ? 'Torang Go Driver' : 'Torang Go',
                            style: TG.title(context),
                          ),
                          Text(
                            isDriver ? 'Mode Mitra Driver' : 'Mode Customer',
                            style: TG.bodySm(context, color: TG.inkSoft),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 38),
                  Text(
                    isDriver ? 'Gas earning hari ini! 💪' : 'Halo, torang! 👋',
                    style: TG.display(context, color: TG.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDriver
                        ? 'Masuk untuk mulai terima order di sekitar kamu.'
                        : 'Masuk untuk pesan ojek, kirim barang, dan lainnya.',
                    style: TG.body(context, color: TG.inkSoft),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.phone_android_rounded,
                        color: TG.inkSoft,
                      ),
                      hintText: '0812xxxxxxx',
                      labelText: 'Nomor HP',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: TG.inkSoft,
                      ),
                      hintText: '••••••••',
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: TG.inkSoft,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Masuk',
                    icon: Icons.login_rounded,
                    loading: _loading,
                    onTap: _login,
                  ),
                  const SizedBox(height: 18),
                  if (!isDriver)
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun?',
                            style: TG.body(context, color: TG.inkSoft),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            child: Text(
                              'Daftar dulu',
                              style: TG.label(context, color: TG.ocean),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 26),
                  // Kartu demo + diagnostik HANYA tampil di build debug.
                  // (Build release di HP user bersih — tanpa teks teknis/server,
                  //  memperbaiki defect "script/teks alamat server tampil").
                  if (kDebugMode) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: TG.card(radius: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: TG.coral,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Akun demo (server lokal)',
                                style: TG.titleSm(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (isDriver) ...[
                            _demoChip(
                              'Bentor — 081200000002',
                              () => _fillDemo('081200000002', 'driver123'),
                            ),
                            const SizedBox(height: 8),
                            _demoChip(
                              'Ojek — 081200000003',
                              () => _fillDemo('081200000003', 'driver123'),
                            ),
                          ] else
                            _demoChip(
                              'Customer — 081200000001',
                              () => _fillDemo('081200000001', 'customer123'),
                            ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ConnectionCheckScreen(),
                              ),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: TG.line),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.wifi_tethering_rounded,
                                    size: 16,
                                    color: TG.ocean,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Server: ${AppConfig.apiBase}',
                                      style: TG.bodySm(
                                        context,
                                        color: TG.inkSoft,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Cek koneksi',
                                    style: TG.bodySm(
                                      context,
                                      color: TG.leafDeep,
                                      w: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!kDebugMode) const SizedBox(height: 30),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: TG.sandDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TG.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.touch_app_rounded, size: 16, color: TG.ocean),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TG.body(context))),
            Text(
              'Isi otomatis',
              style: TG.bodySm(context, color: TG.leafDeep, w: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper: ambil Session dari ancestor (disediakan oleh main_*).
Session sessionOf(BuildContext context) => SessionScope.of(context);

class SessionScope extends InheritedNotifier<Session> {
  final Session session;
  const SessionScope({
    super.key,
    required this.session,
    required super.child,
    required super.notifier,
  });

  static Session of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.session;
}

/// Halaman pertama setelah splash (onboarding → login → shell).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sessionOf(context),
      builder: (context, _) {
        final s = sessionOf(context);
        if (!s.restored) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (s.isAuthed) {
          return AppConfig.role == AppRole.driver
              ? const DriverShell()
              : const CustomerShell();
        }
        return const LoginScreen();
      },
    );
  }
}
