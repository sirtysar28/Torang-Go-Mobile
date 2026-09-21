import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/launcher.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Order? _order;
  Timer? _timer;
  final bool _busy = false;
  bool _rating = false;
  int _stars = 5;
  final _comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final res = await ApiClient.I.get('/orders/${widget.orderId}');
      if (!mounted) return;
      setState(() => _order = Order.fromJson(res['order']));
      final o = _order;
      if (o != null && o.isCompleted && o.rated == false && !_rating) {
        // tawarkan rating sekali
        _maybeShowRating(o);
      }
    } catch (e) {
      if (!silent && mounted) {
        tgSnackbar(context, e.toString(), error: true);
      }
    }
  }

  void _maybeShowRating(Order o) {
    _rating = true;
    Future.microtask(() => _showRatingSheet(o));
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: TG.sand,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _CancelSheet(
        onConfirm: (reason) async {
          try {
            await ApiClient.I.post(
              '/orders/${widget.orderId}/cancel',
              body: {'reason': reason},
            );
            if (mounted) {
              tgSnackbar(context, 'Order dibatalkan.');
              Navigator.of(context).popUntil((r) => r.isFirst);
            }
          } catch (e) {
            if (mounted) {
              tgSnackbar(context, e.toString(), error: true);
              Navigator.of(context).pop(false);
            }
          }
        },
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  void _showRatingSheet(Order o) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: TG.sand,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: TG.line,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            Text('Sudah sampe tujuan! 🎉', style: TG.title(context)),
            const SizedBox(height: 6),
            Text(
              'Beri rating untuk ${o.driver?.name ?? 'driver'} yuk.',
              style: TG.body(context, color: TG.inkSoft),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final on = i < _stars;
                return IconButton(
                  onPressed: () => setState(() => _stars = i + 1),
                  icon: Icon(
                    on ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: on ? const Color(0xFFFFB300) : TG.line,
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _comment,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Komentar (opsional)',
                hintText: 'Driver ramah, motor bersih...',
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Kirim Rating',
              icon: Icons.send_rounded,
              onTap: () async {
                try {
                  await ApiClient.I.post(
                    '/orders/${widget.orderId}/rate',
                    body: {
                      'stars': _stars,
                      if (_comment.text.trim().isNotEmpty)
                        'comment': _comment.text.trim(),
                    },
                  );
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    tgSnackbar(ctx, 'Terima kasih atas ratingnya! ⭐');
                    _load(silent: true);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    tgSnackbar(ctx, e.toString(), error: true);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesanan ${o?.code ?? '...'}'),
        actions: [
          if (o != null && o.isActive && o.status == 'searching_driver')
            IconButton(
              onPressed: _busy ? null : _cancelOrder,
              icon: const Icon(Icons.close_rounded, color: Color(0xFFB3261E)),
            ),
        ],
      ),
      body: o == null
          ? const Center(child: CircularProgressIndicator(color: TG.leaf))
          : RefreshIndicator(
              onRefresh: () => _load(),
              color: TG.ocean,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _statusHero(o),
                  const SizedBox(height: 16),
                  StylizedMap(
                    height: 200,
                    driver: o.driver?.latitude != null
                        ? Offset(
                            clamp01(
                              0.5 +
                                  ((o.driver!.longitude! -
                                              o.destination.longitude)
                                          .clamp(-0.05, 0.05)) *
                                      4,
                            ),
                            clamp01(
                              0.55 +
                                  ((o.driver!.latitude! -
                                              o.destination.latitude)
                                          .clamp(-0.05, 0.05)) *
                                      4,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (o.driver != null) ...[
                    _driverCard(o),
                    const SizedBox(height: 16),
                  ],
                  _tripTimeline(o),
                  const SizedBox(height: 16),
                  _fareDetail(o),
                ],
              ),
            ),
    );
  }

  Widget _statusHero(Order o) {
    final v = OrderStatusVisual.of(o.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: TG.brandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TG.ocean.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(v.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${o.serviceLabel ?? o.serviceChip} — ${o.label}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TG.titleSm(context, color: Colors.white),
                ),
              ),
              if (o.isActive)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${o.pickup.name} → ${o.destination.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TG.body(
                    context,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _heroPill(Icons.route_rounded, km(o.distanceKm)),
              const SizedBox(width: 8),
              _heroPill(Icons.schedule_rounded, '±${o.durationMinutes} mnt'),
              const SizedBox(width: 8),
              _heroPill(
                o.paymentMethod == 'cash'
                    ? Icons.payments_rounded
                    : Icons.qr_code_rounded,
                o.paymentMethod == 'cash' ? 'Tunai' : 'QRIS',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(text, style: TG.bodySm(context, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _driverCard(Order o) {
    final d = o.driver!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TG.card(),
      child: Row(
        children: [
          InitialAvatar(d.name ?? 'Driver', size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        d.name ?? 'Driver',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TG.titleSm(context),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: TG.leafSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Verifikasi',
                        style: TG.bodySm(
                          context,
                          color: TG.leafDeep,
                          w: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '★ ${d.rating.toStringAsFixed(1)} • ${d.vehicleLabel ?? ''} ${d.plateNumber ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TG.bodySm(context, color: TG.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _circleBtn(Icons.phone_in_talk_rounded, TG.leafDeep, () async {
            final ok = await TgLauncher.call(d.phone ?? '');
            if (!ok && mounted) {
              tgSnackbar(context, 'Nomor driver belum tersedia.', error: true);
            }
          }),
          const SizedBox(width: 8),
          _circleBtn(Icons.chat_rounded, const Color(0xFF25D366), () async {
            final ok = await TgLauncher.openWhatsApp(
              d.phone ?? '',
              message:
                  'Halo ${d.name ?? 'Driver'}! Saya customer order ${o.code} Torang Go 🙌',
            );
            if (!ok && mounted) {
              tgSnackbar(
                context,
                'Chat driver via WA belum tersedia.',
                error: true,
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _tripTimeline(Order o) {
    final steps = kTripFlow;
    final currentIdx = steps.indexOf(o.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: TG.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Linimasa perjalanan', style: TG.titleSm(context)),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            _timelineStep(
              steps[i],
              done: o.isCancelled ? false : (currentIdx >= 0 && i < currentIdx),
              active: i == currentIdx,
              isLast: i == steps.length - 1,
            ),
          if (o.isCancelled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE8E6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFFB3261E),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dibatalkan — ${o.cancelReason ?? '-'}',
                      style: TG.bodySm(
                        context,
                        color: Color(0xFFB3261E),
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timelineStep(
    String status, {
    required bool done,
    required bool active,
    required bool isLast,
  }) {
    final v = OrderStatusVisual.of(status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? v.color : TG.line,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: v.color.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      )
                    : active
                    ? const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: done ? v.color : TG.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusLabelId(status),
                    style: TG.body(
                      context,
                      color: done || active ? TG.ink : TG.inkSoft,
                      w: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (active)
                    Text(
                      status == 'searching_driver'
                          ? 'Sedang mencari driver terdekat...'
                          : 'Sedang berjalan...',
                      style: TG.bodySm(context, color: v.color),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareDetail(Order o) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: TG.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rincian biaya', style: TG.titleSm(context)),
          const SizedBox(height: 12),
          _row('Tarif dasar', rp(o.baseFare)),
          _row('Jarak ${km(o.distanceKm)}', rp(o.distanceFare)),
          _row('Metode bayar', o.paymentMethod == 'cash' ? 'Tunai' : 'QRIS'),
          const Divider(height: 20, color: TG.line),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TG.titleSm(context)),
              Text(
                rp(o.totalFare),
                style: TG
                    .title(context, color: TG.leafDeep)
                    .copyWith(fontSize: 18),
              ),
            ],
          ),
          if (o.itemsSummary != null && o.itemsSummary!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TG.sandDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.isMart ? 'Daftar belanjaan 🛒' : 'Pesanan makanan 🍜',
                    style: TG.bodySm(
                      context,
                      color: TG.inkSoft,
                      w: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    o.itemsSummary!,
                    style: TG.bodySm(context, color: TG.ink),
                  ),
                ],
              ),
            ),
          ],
          if (o.notes != null && o.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Catatan: ${o.notes}',
              style: TG.bodySm(context, color: TG.inkSoft),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Dibuat ${dateTimeId(o.createdAt)}',
            style: TG.bodySm(context, color: TG.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TG.body(context, color: TG.inkSoft)),
          Text(r, style: TG.body(context, w: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CancelSheet extends StatefulWidget {
  final Future<void> Function(String reason) onConfirm;
  const _CancelSheet({required this.onConfirm});

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  String _reason = 'Berubah pikiran';
  static const _reasons = [
    'Berubah pikiran',
    'Terlalu lama menunggu',
    'Salah alamat tujuan',
    'Ada keperluan mendadak',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
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
          Text('Batalkan pesanan?', style: TG.title(context)),
          const SizedBox(height: 6),
          Text(
            'Pilih alasannya biar torang bisa lebih baik:',
            style: TG.body(context, color: TG.inkSoft),
          ),
          const SizedBox(height: 14),
          for (final r in _reasons)
            GestureDetector(
              onTap: () => setState(() => _reason = r),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _reason == r ? TG.oceanSoft : TG.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _reason == r ? TG.ocean : TG.line),
                ),
                child: Row(
                  children: [
                    Icon(
                      _reason == r
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 19,
                      color: _reason == r ? TG.ocean : TG.inkSoft,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r, style: TG.body(context))),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Ya, Batalkan',
            danger: true,
            icon: Icons.close_rounded,
            onTap: () => widget.onConfirm(_reason),
          ),
        ],
      ),
    );
  }
}
