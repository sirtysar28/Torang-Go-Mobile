import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with AutomaticKeepAliveClientMixin {
  List<Order> _orders = [];
  bool _loading = true;
  String _filter = 'aktif'; // aktif | selesai | batal

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.I.get('/orders');
      setState(() {
        _orders = ((res['orders'] as List?) ?? [])
            .map((e) => Order.fromJson(e))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) tgSnackbar(context, e.toString(), error: true);
    }
  }

  List<Order> get _filtered {
    switch (_filter) {
      case 'selesai':
        return _orders.where((o) => o.isCompleted).toList();
      case 'batal':
        return _orders.where((o) => o.isCancelled).toList();
      default:
        return _orders.where((o) => o.isActive).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
              child: Text('Pesanan torang', style: TG.title(context)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  for (final (id, label) in const [
                    ('aktif', 'Aktif'),
                    ('selesai', 'Selesai'),
                    ('batal', 'Dibatalkan'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: _filter == id ? TG.brandGradient : null,
                            color: _filter == id ? null : TG.white,
                            borderRadius: BorderRadius.circular(20),
                            border: _filter == id
                                ? null
                                : Border.all(color: TG.line),
                          ),
                          child: Text(
                            label,
                            style: TG.label(
                              context,
                              color: _filter == id ? Colors.white : TG.inkSoft,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: TG.leaf),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: TG.ocean,
                      child: _filtered.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                EmptyState(
                                  icon: Icons.receipt_long_rounded,
                                  title: 'Belum ada pesanan di sini',
                                  subtitle:
                                      'Pesanan torang bakal muncul di halaman ini.',
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                14,
                                22,
                                26,
                              ),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) => _orderTile(_filtered[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTile(Order o) {
    final v = OrderStatusVisual.of(o.status);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: o.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: TG.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: v.soft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    o.serviceChip,
                    style: TG.bodySm(
                      context,
                      color: v.color,
                      w: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                StatusChip(o.status, label: o.label),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.trip_origin_rounded,
                  size: 13,
                  color: TG.ocean,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    o.pickup.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TG.body(context, w: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.place_rounded,
                  size: 13,
                  color: Color(0xFFB3261E),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    o.destination.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TG.body(context, w: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Divider(height: 18, color: TG.line),
            Row(
              children: [
                Text(
                  timeAgoIso(o.createdAt),
                  style: TG.bodySm(context, color: TG.inkSoft),
                ),
                const Spacer(),
                Text(
                  rp(o.totalFare),
                  style: TG.titleSm(context, color: TG.leafDeep),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
