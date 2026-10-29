import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';
import '../auth/login_screen.dart' show sessionOf;
import 'bills_screen.dart';
import 'booking_screen.dart';
import 'help_screen.dart';
import 'kos_screen.dart';
import 'order_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Order? _active;
  bool _loadingActive = true;

  /// Layanan yang tampil di beranda — diatur admin dari dashboard
  /// (GET /features). Fallback: semua tampil.
  AppFeatures _features = AppFeatures.cached;

  @override
  void initState() {
    super.initState();
    _loadActive();
    _loadFeatures();
  }

  Future<void> _loadActive() async {
    try {
      final res = await ApiClient.I.get('/orders/active');
      if (mounted) {
        setState(() {
          _active = res['order'] is Map ? Order.fromJson(res['order']) : null;
          _loadingActive = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingActive = false);
    }
  }

  Future<void> _loadFeatures() async {
    try {
      final res = await ApiClient.I.get('/features');
      final j = res['features'];
      if (mounted && j is Map) {
        setState(
          () => _features =
              AppFeatures.cached =
                  AppFeatures.fromJson(Map<String, dynamic>.from(j)),
        );
      }
    } catch (_) {
      // Server belum update / offline → pakai cache (semua tampil)
    }
  }

  /// Layanan transport pertama yang aktif (untuk search bar beranda).
  String? _firstTransport() {
    for (final r in const ['bentor', 'ride', 'car', 'send']) {
      if (_features.of(r)) return r;
    }
    return null;
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final user = sessionOf(context).currentUser;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: TG.ocean,
          onRefresh: () async {
            await _loadActive();
            await _loadFeatures();
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 26),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _header(user?.name ?? 'Torang', address: user?.address),
              // Search bar hanya tampil kalau ada layanan transport aktif
              if (_firstTransport() case final t?) _SearchBar(serviceType: t),
              const _WalletCard(),
              _services(),
              _PromoCarousel(features: _features),
              _activeOrderSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header + bell ----------------
  Widget _header(String name, {String? address}) {
    final loc = (address != null && address.trim().isNotEmpty)
        ? address.trim()
        : 'Jailolo, Halmahera Barat — Maluku Utara';
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: TG.brandGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.electric_bolt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: '$_greeting(), ',
                    style: TG.titleSm(context, color: TG.inkSoft),
                    children: [
                      TextSpan(
                        text: name.split(' ').first,
                        style: TG.title(context, color: TG.ink),
                      ),
                      const TextSpan(text: ' 👋'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: TG.coral,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        loc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TG.bodySm(context, color: TG.inkSoft),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: TG.card(radius: 14),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: TG.ink,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Services ----------------
  Widget _services() {
    // route: ride/bentor/car/send/food/mart → BookingScreen,
    // bayar → BillsScreen, kos → KosScreen, help → HelpScreen.
    // Menu yang dinonaktifkan admin (dashboard) otomatis disembunyikan.
    final items = const [
      ('Torang Bentor', '🛺', TG.leafDeep, TG.leafSoft, 'bentor'),
      ('Torang Ride', '🛵', TG.ocean, TG.oceanSoft, 'ride'),
      ('Torang Car', '🚗', TG.oceanDeep, TG.navySoft, 'car'),
      ('Torang Makan', '🍜', TG.coral, TG.coralSoft, 'food'),
      ('Torang Kirim', '📦', TG.leafDeep, TG.leafSoft, 'send'),
      ('Torang Mart', '🛒', TG.ocean, TG.oceanSoft, 'mart'),
      ('Torang Bayar', '💳', TG.oceanDeep, TG.navySoft, 'bayar'),
      ('Sewa Kos', '🏠', TG.coral, TG.coralSoft, 'kos'),
      ('Bantuan', '💬', TG.leaf, TG.leafSoft, 'help'),
    ];
    final visible = items
        .where((it) => _features.of(it.$5))
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Layanan Torang Go',
            actionLabel: 'Zona Jailolo',
            onAction: () {},
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.86,
            mainAxisSpacing: 14,
            children: [
              for (final (name, emoji, fg, bg, route) in visible)
                _ServiceTile(
                  emoji: emoji,
                  label: name,
                  fg: fg,
                  bg: bg,
                  onTap: () {
                    switch (route) {
                      case 'bayar':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BillsScreen(),
                          ),
                        );
                      case 'kos':
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const KosScreen()),
                        );
                      case 'help':
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HelpScreen()),
                        );
                      default:
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(serviceType: route),
                          ),
                        );
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Order aktif ----------------
  Widget _activeOrderSection() {
    if (_loadingActive) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: TG.leaf)),
      );
    }
    final o = _active;
    if (o == null) return const SizedBox.shrink();

    final v = OrderStatusVisual.of(o.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('Perjalanan torang saat ini'),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderTrackingScreen(orderId: o.id),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: TG.card(),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: v.soft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(v.icon, color: v.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.label, style: TG.titleSm(context)),
                        const SizedBox(height: 2),
                        Text(
                          o.isRide
                              ? 'Ke ${o.destination.name}'
                              : o.isSend
                              ? 'Paket ke ${o.destination.name}'
                              : o.isFood
                              ? 'Makanan dari ${o.pickup.name}'
                              : o.isMart
                              ? 'Belanjaan dari ${o.pickup.name}'
                              : 'Ke ${o.destination.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TG.bodySm(context, color: TG.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '≈${o.durationMinutes} mnt',
                        style: TG.titleSm(context, color: TG.leafDeep),
                      ),
                      Text(
                        'tiba di tujuan',
                        style: TG.bodySm(context, color: TG.inkSoft),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Search bar
// ============================================================
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.serviceType});

  /// Layanan transport aktif pertama (dipakai tombol Pesan)
  final String serviceType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingScreen(serviceType: serviceType),
          ),
        ),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: TG.card(radius: 16),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: TG.inkSoft),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Torang jalan ke mana hari ini?',
                  style: TG.body(context, color: TG.inkSoft),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: TG.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Pesan',
                  style: TG.bodySm(
                    context,
                    color: Colors.white,
                    w: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Wallet gradient card (visual — TorangPay segera hadir)
// ============================================================
class _WalletCard extends StatelessWidget {
  const _WalletCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: TG.brandGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: TG.ocean.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'TorangPay',
                  style: TG.titleSm(context, color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'SEGERA HADIR',
                    style: TG.bodySm(
                      context,
                      color: Colors.white,
                      w: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Rp ••••••',
              style: TG
                  .display(context, color: Colors.white)
                  .copyWith(fontSize: 24),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (icon, label) in [
                  (Icons.add_card_rounded, 'Top Up'),
                  (Icons.upload_rounded, 'Tarik'),
                  (Icons.receipt_long_rounded, 'Riwayat'),
                  (Icons.star_rounded, 'Poin'),
                ])
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          tgSnackbar(context, 'TorangPay segera hadir! 💳'),
                      child: Column(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: Colors.white, size: 18),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            style: TG.bodySm(
                              context,
                              color: Colors.white,
                              w: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Tile layanan
// ============================================================
class _ServiceTile extends StatelessWidget {
  final String emoji, label;
  final Color fg, bg;
  final VoidCallback onTap;
  const _ServiceTile({
    required this.emoji,
    required this.label,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 23)),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TG.bodySm(context, w: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Promo carousel (promo layanan yang dinonaktifkan ikut disembunyikan)
// ============================================================
class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel({required this.features});

  final AppFeatures features;

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final _controller = PageController(viewportFraction: 0.88);
  int _page = 0;

  // (kicker, judul, kode, utama?, layanan terkait)
  static const _promos = [
    (
      'KHUSUS JAILOLO',
      'Diskon 30% antar-jemput Pelabuhan Jailolo',
      'Pakai kode TORANGJAILOLO',
      true,
      ['ride', 'bentor', 'car'],
    ),
    (
      'TORANG KIRIM',
      'Gratis ongkir kirim paket se-Halmahera Barat',
      'Min. transaksi Rp 15.000',
      false,
      ['send'],
    ),
  ];

  List<(String, String, String, bool, List<String>)> get _visible => _promos
      .where((p) => p.$5.any(widget.features.of))
      .toList();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promos = _visible;
    if (promos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: SectionTitle('Promo torang hari ini'),
        ),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: promos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final (kicker, title, code, main, _) = promos[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: main ? TG.promoGradient : TG.promoGradientAlt,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (main ? TG.ocean : TG.leaf).withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          kicker,
                          style: TG.bodySm(
                            context,
                            color: Colors.white,
                            w: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 190,
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TG
                              .titleSm(context, color: Colors.white)
                              .copyWith(fontSize: 15, height: 1.3),
                        ),
                      ),
                      Text(
                        code,
                        style: TG.bodySm(
                          context,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(promos.length, (i) {
            final on = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: on ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                gradient: on ? TG.brandGradient : null,
                color: on ? null : TG.line,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}
