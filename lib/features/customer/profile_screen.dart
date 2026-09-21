import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/launcher.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';
import '../auth/login_screen.dart' show sessionOf;
import 'help_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  bool _saving = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _editProfile() async {
    final user = sessionOf(context).currentUser;
    if (user == null) return;

    final name = TextEditingController(text: user.name);
    final phone = TextEditingController(text: user.phone);
    final email = TextEditingController(text: user.email ?? '');
    final address = TextEditingController(text: user.address ?? '');

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TG.sand,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 22,
            right: 22,
            top: 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: TG.line,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text('Ubah data akun ✏️', style: TG.title(ctx)),
              const SizedBox(height: 4),
              Text(
                'Perubahan langsung tersimpan ke server Torang Go.',
                style: TG.body(ctx, color: TG.inkSoft),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: TG.inkSoft,
                  ),
                  labelText: 'Nama lengkap',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.phone_android_rounded,
                    color: TG.inkSoft,
                  ),
                  labelText: 'Nomor HP (08xxxxxxxxxx)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.alternate_email_rounded,
                    color: TG.inkSoft,
                  ),
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: address,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.home_work_rounded, color: TG.inkSoft),
                  labelText: 'Alamat (rumah / domisili)',
                  hintText: 'Contoh: Jl. Mardika No 5, Jailolo',
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _saving ? 'Menyimpan…' : 'Simpan Perubahan',
                icon: Icons.save_rounded,
                loading: _saving,
                onTap: () async {
                  setSheet(() => _saving = true);
                  try {
                    await sessionOf(ctx).updateProfile(
                      name: name.text.trim(),
                      phone: phone.text.trim(),
                      email: email.text.trim(),
                      address: address.text.trim(),
                    );
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop(true);
                      tgSnackbar(ctx, 'Profil tersimpan! ✅');
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      tgSnackbar(ctx, e.toString(), error: true);
                      setSheet(() => _saving = false);
                    }
                  } finally {
                    _saving = false;
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    if (ok == true && mounted) setState(() {}); // refresh kartu
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = sessionOf(context).currentUser;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
          children: [
            // Header profil
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _editProfile,
                    child: Stack(
                      children: [
                        InitialAvatar(user?.name ?? '?', size: 92),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: TG.leaf,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? '-',
                    style: TG.title(context, color: TG.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? '-',
                    style: TG.body(context, color: TG.inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _editCard(context, user),
            const SizedBox(height: 16),
            _menuCard(),
            const SizedBox(height: 16),
            _aboutCard(),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Keluar Akun',
              danger: true,
              gradient: false,
              icon: Icons.logout_rounded,
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: TG.sand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: Text('Keluar akun?', style: TG.titleSm(context)),
                    content: Text(
                      'Torang kangen kalau kamu pergi 😢',
                      style: TG.body(context, color: TG.inkSoft),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Keluar',
                          style: TextStyle(color: Color(0xFFB3261E)),
                        ),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await sessionOf(context).logout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _editCard(BuildContext context, User? user) {
    return GestureDetector(
      onTap: _editProfile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: TG.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Data akun', style: TG.titleSm(context))),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: TG.oceanSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded, size: 13, color: TG.ocean),
                      const SizedBox(width: 5),
                      Text(
                        'Ubah',
                        style: TG.bodySm(
                          context,
                          color: TG.ocean,
                          w: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InfoRow(Icons.person_rounded, 'Nama', user?.name ?? '-'),
            const SizedBox(height: 10),
            InfoRow(
              Icons.phone_android_rounded,
              'Nomor HP',
              user?.phone ?? '-',
            ),
            const SizedBox(height: 10),
            InfoRow(Icons.alternate_email_rounded, 'Email', user?.email ?? '—'),
            const SizedBox(height: 10),
            InfoRow(
              Icons.home_work_rounded,
              'Alamat',
              (user?.address ?? '').trim().isNotEmpty ? user!.address! : '—',
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard() {
    return Container(
      decoration: TG.card(),
      child: Column(
        children: [
          _menuItem(
            Icons.chat_bubble_rounded,
            'Bantuan torang',
            'Bot AI 24 jam + chat admin WhatsApp',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
          ),
          const Divider(height: 1, indent: 60, color: TG.line),
          _menuItem(
            Icons.home_work_rounded,
            'Alamat tersimpan',
            'Rumah • Kantor — ubah di data akun',
            onTap: _editProfile,
          ),
          const Divider(height: 1, indent: 60, color: TG.line),
          _menuItem(
            Icons.credit_card_rounded,
            'Torang Bayar',
            'Tagihan PLN, pulsa, PDAM, BPJS',
            onTap: () {
              tgSnackbar(context, 'Buka menu Torang Bayar di beranda ya 💳');
            },
          ),
          const Divider(height: 1, indent: 60, color: TG.line),
          _menuItem(
            Icons.handshake_rounded,
            'Jadi mitra driver',
            'Daftar & dapat penghasilan',
            onTap: () async {
              try {
                final res = await ApiClient.I.get('/support/settings');
                final wa = (res['support']['admin_whatsapp'] ?? '').toString();
                final ok = await TgLauncher.openWhatsApp(
                  wa,
                  message:
                      'Halo Admin Torang Go! Saya mau daftar jadi mitra driver 🛵',
                );
                if (!ok && mounted) {
                  tgSnackbar(
                    context,
                    'Download app Torang Go Driver lalu daftar dari sana ya 🤝',
                  );
                }
              } catch (_) {
                if (mounted) {
                  tgSnackbar(
                    context,
                    'Download app Torang Go Driver lalu daftar dari sana ya 🤝',
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TG.oceanSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: TG.ocean),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TG.body(context, w: FontWeight.w600)),
                  Text(subtitle, style: TG.bodySm(context, color: TG.inkSoft)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: TG.inkSoft),
          ],
        ),
      ),
    );
  }

  Widget _aboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TG.card(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: TG.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.electric_bolt_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Torang Go v1.1.0',
                  style: TG.body(context, w: FontWeight.w700),
                ),
                Text(
                  'Ojek & bentor online Halmahera Barat 🇮🇩',
                  style: TG.bodySm(context, color: TG.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
