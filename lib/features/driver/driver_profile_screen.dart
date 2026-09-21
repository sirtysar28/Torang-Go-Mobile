import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/launcher.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';
import '../auth/login_screen.dart' show sessionOf;

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen>
    with AutomaticKeepAliveClientMixin {
  DriverInfo? _driver;
  String? _vehicleType, _vehicleLabel, _plate, _vehicleColor;
  double _walletBalance = 0;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.I.get('/driver/profile');
      if (!mounted) return;
      setState(() {
        _driver = DriverInfo.fromJson(res['driver']);
        final v = res['vehicle'];
        _vehicleType = v is Map ? v['type']?.toString() : null;
        _vehicleLabel = v is Map ? v['label']?.toString() : null;
        _plate = v is Map ? v['plate_number']?.toString() : null;
        _vehicleColor = v is Map ? v['color']?.toString() : null;
        _walletBalance = (res['wallet_balance'] as num?)?.toDouble() ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        tgSnackbar(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = sessionOf(context).currentUser;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: TG.leaf))
          : ListView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
              children: [
                Center(
                  child: Column(
                    children: [
                      InitialAvatar(user?.name ?? '?', size: 92),
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
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _driver?.isVerified == true
                              ? TG.leafSoft
                              : TG.coralSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _driver?.isVerified == true
                                  ? Icons.verified_rounded
                                  : Icons.hourglass_top_rounded,
                              size: 15,
                              color: _driver?.isVerified == true
                                  ? TG.leafDeep
                                  : TG.coral,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _driver?.isVerified == true
                                  ? 'Mitra Terverifikasi'
                                  : 'Menunggu verifikasi admin',
                              style: TG.bodySm(
                                context,
                                color: _driver?.isVerified == true
                                    ? TG.leafDeep
                                    : TG.coral,
                                w: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: TG.card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kendaraan 🛵', style: TG.titleSm(context)),
                      const SizedBox(height: 12),
                      InfoRow(
                        Icons.badge_rounded,
                        'Kode mitra',
                        _driver?.code ?? '-',
                      ),
                      const SizedBox(height: 10),
                      InfoRow(
                        Icons.motorcycle_rounded,
                        'Jenis',
                        _vehicleType ?? '-',
                      ),
                      const SizedBox(height: 10),
                      InfoRow(
                        Icons.directions_car_rounded,
                        'Kendaraan',
                        _vehicleLabel ?? '-',
                      ),
                      const SizedBox(height: 10),
                      InfoRow(Icons.pin_rounded, 'Plat nomor', _plate ?? '-'),
                      const SizedBox(height: 10),
                      InfoRow(
                        Icons.palette_rounded,
                        'Warna',
                        _vehicleColor ?? '-',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: TG.card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Performa torang 📈', style: TG.titleSm(context)),
                      const SizedBox(height: 12),
                      InfoRow(
                        Icons.star_rounded,
                        'Rating',
                        '${_driver?.rating.toStringAsFixed(1) ?? '-'} ★',
                      ),
                      const SizedBox(height: 10),
                      InfoRow(
                        Icons.route_rounded,
                        'Total order',
                        '${_driver?.totalOrders ?? 0}',
                      ),
                      const SizedBox(height: 10),
                      InfoRow(
                        Icons.savings_rounded,
                        'Saldo dompet',
                        'Rp ${_walletBalance.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _menuItem(
                  Icons.headset_mic_rounded,
                  'Bantuan mitra',
                  'Bot AI + chat admin BPO via WhatsApp',
                  () async {
                    var ok = false;
                    try {
                      final res = await ApiClient.I.get('/support/settings');
                      final wa = (res['support']['admin_whatsapp'] ?? '')
                          .toString();
                      ok = await TgLauncher.openWhatsApp(
                        wa,
                        message:
                            'Halo Admin! Saya mitra driver Torang Go, butuh bantuan 🛵',
                      );
                    } catch (_) {
                      ok = false;
                    }
                    if (!mounted) return;
                    if (!ok) {
                      tgSnackbar(
                        this.context,
                        'BPO Torang Go: halo@toranggo.biz.id 💬',
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                _menuItem(
                  Icons.book_rounded,
                  'Panduan driver',
                  'Tips aman & sopan',
                  () => tgSnackbar(context, 'Panduan lengkap segera hadir 📖'),
                ),
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
                          'Istirahat dulu atau kerja lagi? 😄',
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
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: TG.card(),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
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
}
