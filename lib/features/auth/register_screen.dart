import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../shared/widgets.dart';
import 'login_screen.dart' show sessionOf;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _agree = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _password.text.length < 6) {
      tgSnackbar(
        context,
        'Nama & nomor HP wajib diisi, password minimal 6 karakter.',
        error: true,
      );
      return;
    }
    if (!_agree) {
      tgSnackbar(context, 'Centang persetujuan dulu ya.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await sessionOf(context).registerCustomer(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) tgSnackbar(context, 'Akun berhasil dibuat! 🎉');
    } catch (e) {
      if (mounted) tgSnackbar(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 8, 26, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gabung bareng torang! 🤝',
              style: TG.title(context, color: TG.ink),
            ),
            const SizedBox(height: 6),
            Text(
              'Daftar sebagai customer — gratis, cuma 1 menit.',
              style: TG.body(context, color: TG.inkSoft),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: TG.inkSoft,
                ),
                labelText: 'Nama lengkap',
                hintText: 'Contoh: Rifky Ansari',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.phone_android_rounded,
                  color: TG.inkSoft,
                ),
                labelText: 'Nomor HP',
                hintText: '0812xxxxxxx',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.alternate_email_rounded,
                  color: TG.inkSoft,
                ),
                labelText: 'Email (opsional)',
                hintText: 'nama@email.com',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: TG.inkSoft,
                ),
                labelText: 'Password (min. 6 karakter)',
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
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _agree = !_agree),
              child: Row(
                children: [
                  Icon(
                    _agree
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_off_rounded,
                    color: _agree ? TG.leafDeep : TG.inkSoft,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saya setuju sama Syarat & Ketentuan Torang Go.',
                      style: TG.body(context, color: TG.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Daftar Sekarang',
              icon: Icons.person_add_rounded,
              loading: _loading,
              onTap: _register,
            ),
          ],
        ),
      ),
    );
  }
}
