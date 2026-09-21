import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with AutomaticKeepAliveClientMixin {
  DriverSummary _summary = DriverSummary(
    driverStatus: 'pending',
    dutyStatus: 'offline',
  );
  DriverInfo? _driverInfo;
  List<Order> _available = [];
  Order? _active;
  bool _loading = true;
  bool _busy = false;

  /// GPS simulasi di pusat Jailolo (produksi: pakai geolocator).
  double _lat = AppConfig.jailoloLat;
  double _lng = AppConfig.jailoloLng;

  Timer? _poll;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final sum = await ApiClient.I.get('/driver/summary');
      final prof = await ApiClient.I.get('/driver/profile');
      final act = await ApiClient.I.get(
        '/driver/orders',
        query: {'filter': 'active'},
      );
      if (!mounted) return;
      setState(() {
        _summary = DriverSummary.fromJson(sum);
        _driverInfo = DriverInfo.fromJson(prof['driver']);
        final list = ((act['orders'] as List?) ?? [])
            .map((e) => Order.fromJson(e))
            .toList();
        _active = list.isEmpty ? null : list.first;
        _loading = false;
      });
      if (_driverInfo?.latitude != null) {
        _lat = _driverInfo!.latitude!;
        _lng = _driverInfo!.longitude ?? AppConfig.jailoloLng;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        tgSnackbar(context, e.toString(), error: true);
      }
    }
  }

  /// Dipanggil tiap 5 detik: update posisi + polling order.
  Future<void> _tick() async {
    if (_busy) return;
    final online = _summary.dutyStatus == 'online';
    // Simulasi pergerakan kecil
    _lat += (math.Random().nextDouble() - 0.5) * 0.0006;
    _lng += (math.Random().nextDouble() - 0.5) * 0.0006;
    try {
      if (online) {
        await ApiClient.I.post(
          '/driver/location',
          body: {'latitude': _lat, 'longitude': _lng},
        );
        final avail = await ApiClient.I.get(
          '/driver/orders',
          query: {'filter': 'available'},
        );
        if (!mounted) return;
        setState(() {
          _available = ((avail['orders'] as List?) ?? [])
              .map((e) => Order.fromJson(e))
              .toList();
        });
      }
      // Refresh ringkas order aktif + summary tiap tick
      final act = await ApiClient.I.get(
        '/driver/orders',
        query: {'filter': 'active'},
      );
      final sum = await ApiClient.I.get('/driver/summary');
      if (!mounted) return;
      setState(() {
        final list = ((act['orders'] as List?) ?? [])
            .map((e) => Order.fromJson(e))
            .toList();
        _active = list.isEmpty ? null : list.first;
        _summary = DriverSummary.fromJson(sum);
      });
    } catch (_) {
      // diamkan — polling gagal tidak perlu notif
    }
  }

  Future<void> _toggleDuty() async {
    setState(() => _busy = true);
    final target = _summary.dutyStatus == 'online' ? 'offline' : 'online';
    try {
      await ApiClient.I.put(
        '/driver/duty-status',
        body: {'duty_status': target},
      );
      if (!mounted) return;
      setState(() {
        _summary = DriverSummary(
          driverStatus: _summary.driverStatus,
          dutyStatus: target,
          todayEarnings: _summary.todayEarnings,
          todayOrders: _summary.todayOrders,
          totalOrders: _summary.totalOrders,
          totalEarnings: _summary.totalEarnings,
          rating: _summary.rating,
        );
      });
      tgSnackbar(
        context,
        target == 'online'
            ? 'Kamu ONLINE — siap terima order! ⚡'
            : 'Kamu offline. Istirahat dulu ya 😌',
      );
    } catch (e) {
      if (!mounted) return;
      tgSnackbar(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(String path, String okMsg) async {
    setState(() => _busy = true);
    try {
      await ApiClient.I.post(path);
      if (!mounted) return;
      tgSnackbar(context, okMsg);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      tgSnackbar(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acceptOrder(Order o) async {
    setState(() => _busy = true);
    try {
      await ApiClient.I.post('/driver/orders/${o.id}/accept');
      if (!mounted) return;
      tgSnackbar(context, 'Order diterima! Gas ke titik jemput 🛵');
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      tgSnackbar(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final online = _summary.dutyStatus == 'online';
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: TG.leaf))
            : ListView(
                padding: const EdgeInsets.only(bottom: 26),
                children: [
                  _earningsHeader(online),
                  const SizedBox(height: 16),
                  if (_active != null) ...[
                    _activeTrip(_active!),
                    const SizedBox(height: 16),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: _availableSection(online),
                    ),
                  ],
                  _statCards(),
                ],
              ),
      ),
    );
  }

  // ---------- Header gradient: duty + earning ----------
  Widget _earningsHeader(bool online) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 12, 22, 0),
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
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      online ? 'ONLINE — siap order ⚡' : 'OFFLINE 😴',
                      style: TG.titleSm(context, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _driverInfo?.isVerified == true
                          ? 'Mitra terverifikasi ✓ ${_driverInfo?.code ?? ''}'
                          : 'Status: ${_summary.driverStatus} (menunggu verifikasi admin)',
                      style: TG.bodySm(
                        context,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle online/offline
              GestureDetector(
                onTap: _busy ? null : _toggleDuty,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: 64,
                  height: 34,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: online
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: online
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: online ? TG.brandGradient : null,
                        color: online ? null : Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _statBox(
                'Pendapatan hari ini',
                rp(_summary.todayEarnings),
                Icons.payments_rounded,
              ),
              const SizedBox(width: 10),
              _statBox(
                'Order hari ini',
                '${_summary.todayOrders}',
                Icons.receipt_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(height: 8),
            Text(
              value,
              style: TG
                  .titleSm(context, color: Colors.white)
                  .copyWith(fontSize: 17),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TG.bodySm(
                context,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Order tersedia ----------
  Widget _availableSection(bool online) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Order masuk', style: TG.title(context))),
            if (online)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  color: TG.leaf,
                  strokeWidth: 2.2,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!online)
          EmptyState(
            icon: Icons.bedtime_rounded,
            title: 'Kamu sedang offline',
            subtitle: 'Aktifkan toggle ONLINE untuk mulai menerima order.',
          )
        else if (_available.isEmpty)
          EmptyState(
            icon: Icons.radar_rounded,
            title: 'Belum ada order di sekitar',
            subtitle:
                'Torang pantau terus — order baru muncul otomatis di sini.',
          )
        else
          for (final o in _available) ...[
            _availableCard(o),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _availableCard(Order o) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TG.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TG.coralSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  o.serviceChip,
                  style: TG.bodySm(
                    context,
                    color: TG.coral,
                    w: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(o.status, label: timeAgoIso(o.createdAt)),
              const Spacer(),
              Text(
                '${o.driverDistanceKm?.toStringAsFixed(1) ?? '?'} km dari kamu',
                style: TG.bodySm(
                  context,
                  color: TG.inkSoft,
                  w: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _route('Jemput', o.pickup.name, TG.ocean),
          const SizedBox(height: 6),
          _route('Tujuan', o.destination.name, const Color(0xFFB3261E)),
          const Divider(height: 20, color: TG.line),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimasi earning',
                    style: TG.bodySm(context, color: TG.inkSoft),
                  ),
                  Text(
                    rp(o.driverEarning),
                    style: TG.titleSm(context, color: TG.leafDeep),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () async {
                  await ApiClient.I.post('/driver/orders/${o.id}/reject');
                  setState(() => _available.removeWhere((x) => x.id == o.id));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: TG.inkSoft,
                  side: const BorderSide(color: TG.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Lewati'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy ? null : () => _acceptOrder(o),
                style: FilledButton.styleFrom(
                  backgroundColor: TG.leafDeep,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Terima ⚡'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _route(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label: ', style: TG.bodySm(context, color: TG.inkSoft)),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TG.body(context, w: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ---------- Perjalanan aktif ----------
  Widget _activeTrip(Order o) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: TG.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Perjalanan aktif — ${o.code}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TG.titleSm(context),
                  ),
                ),
                StatusChip(o.status, label: o.label),
              ],
            ),
            const SizedBox(height: 12),
            _route('Jemput', o.pickup.name, TG.ocean),
            const SizedBox(height: 6),
            _route('Tujuan', o.destination.name, const Color(0xFFB3261E)),
            if (!o.isRide) ...[
              const SizedBox(height: 10),
              Text(
                'Pengirim: ${o.senderName ?? '-'} (${o.senderPhone ?? '-'})\nPenerima: ${o.receiverName ?? '-'} (${o.receiverPhone ?? '-'}) • ${o.itemType ?? ''}',
                style: TG.bodySm(context, color: TG.inkSoft),
              ),
            ],
            if (o.itemsSummary != null && o.itemsSummary!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: o.isMart ? TG.oceanSoft : TG.coralSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.isMart
                          ? 'BELANJAKAN DI ${o.pickup.name.toUpperCase()} 🛒'
                          : 'AMBIL PESANAN DI ${o.pickup.name.toUpperCase()} 🍜',
                      style: TG.bodySm(
                        context,
                        color: o.isMart ? TG.oceanDeep : TG.coral,
                        w: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      o.itemsSummary!,
                      style: TG.bodySm(context, color: TG.ink),
                    ),
                    if (o.isMart)
                      Text(
                        'Belanja dulu di toko, uang barang ditagih ke customer.',
                        style: TG.bodySm(
                          context,
                          color: TG.inkSoft,
                          w: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (o.notes != null && o.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TG.sandDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '📝 ${o.notes}',
                  style: TG.bodySm(context, color: TG.inkSoft),
                ),
              ),
            ],
            const Divider(height: 22, color: TG.line),
            Row(
              children: [
                InfoRow(
                  Icons.payments_rounded,
                  'Bayar',
                  o.paymentMethod == 'cash' ? 'Tunai' : 'QRIS',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total ${rp(o.totalFare)}',
                    style: TG.titleSm(context, color: TG.leafDeep),
                  ),
                ),
                Text(
                  'Earning ${rp(o.driverEarning)}',
                  style: TG.bodySm(
                    context,
                    color: TG.inkSoft,
                    w: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _activeAction(o),
          ],
        ),
      ),
    );
  }

  Widget _activeAction(Order o) {
    switch (o.status) {
      case 'driver_assigned':
        return PrimaryButton(
          label: 'Saya Sudah Tiba di Titik Jemput',
          icon: Icons.pin_drop_rounded,
          loading: _busy,
          onTap: () => _action(
            '/driver/orders/${o.id}/arrived',
            'Tiba di titik jemput. Tunggu penumpang/barang ya.',
          ),
        );
      case 'driver_on_the_way':
        return PrimaryButton(
          label: 'Saya Sudah Tiba di Titik Jemput',
          icon: Icons.pin_drop_rounded,
          loading: _busy,
          onTap: () => _action(
            '/driver/orders/${o.id}/arrived',
            'Tiba di titik jemput. Tunggu penumpang/barang ya.',
          ),
        );
      case 'driver_arrived':
        return PrimaryButton(
          label: 'Mulai Perjalanan',
          icon: Icons.play_arrow_rounded,
          loading: _busy,
          onTap: () => _action(
            '/driver/orders/${o.id}/start',
            'Perjalanan dimulai. Gas! 🛵',
          ),
        );
      case 'trip_started':
        return PrimaryButton(
          label: 'Selesaikan Order (${rp(o.totalFare)})',
          icon: Icons.check_circle_rounded,
          loading: _busy,
          onTap: () => _action(
            '/driver/orders/${o.id}/complete',
            'Order selesai! Earning masuk ke dompet 💰',
          ),
        );
      default:
        return PrimaryButton(
          label: 'Tunggu status berikutnya...',
          gradient: false,
          onTap: null,
        );
    }
  }

  // ---------- Stat kecil ----------
  Widget _statCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: TG.card(radius: 20),
              child: Column(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFB300)),
                  const SizedBox(height: 6),
                  Text(
                    _summary.rating.toStringAsFixed(1),
                    style: TG.titleSm(context),
                  ),
                  Text('Rating', style: TG.bodySm(context, color: TG.inkSoft)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: TG.card(radius: 20),
              child: Column(
                children: [
                  const Icon(Icons.route_rounded, color: TG.ocean),
                  const SizedBox(height: 6),
                  Text('${_summary.totalOrders}', style: TG.titleSm(context)),
                  Text(
                    'Total order',
                    style: TG.bodySm(context, color: TG.inkSoft),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: TG.card(radius: 20),
              child: Column(
                children: [
                  const Icon(Icons.savings_rounded, color: TG.leafDeep),
                  const SizedBox(height: 6),
                  Text(
                    _summary.totalEarnings >= 1000000
                        ? rp(_summary.totalEarnings)
                        : rp(_summary.totalEarnings),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TG.titleSm(context),
                  ),
                  Text(
                    'Total earning',
                    style: TG.bodySm(context, color: TG.inkSoft),
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
