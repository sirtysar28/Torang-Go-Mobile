import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({super.key});

  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen>
    with AutomaticKeepAliveClientMixin {
  List<Order> _orders = [];
  bool _loading = true;
  String _filter = 'active'; // active | history

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
      final res = await ApiClient.I.get(
        '/driver/orders',
        query: {'filter': _filter},
      );
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
              child: Text('Order torang', style: TG.title(context)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  for (final (id, label) in const [
                    ('active', 'Berjalan'),
                    ('history', 'Riwayat'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _filter = id);
                          _load();
                        },
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
                      child: _orders.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                EmptyState(
                                  icon: Icons.motorcycle_rounded,
                                  title: 'Belum ada order',
                                  subtitle:
                                      'Order yang kamu terima muncul di sini.',
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
                              itemCount: _orders.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) => _tile(_orders[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(Order o) {
    final v = OrderStatusVisual.of(o.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TG.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: v.soft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  o.serviceChip,
                  style: TG.bodySm(context, color: v.color, w: FontWeight.w700),
                ),
              ),
              const Spacer(),
              StatusChip(o.status, label: o.label),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${o.pickup.name} → ${o.destination.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TG.body(context, w: FontWeight.w600),
          ),
          if (!o.isRide)
            Text(
              'Penerima: ${o.receiverName ?? '-'} (${o.receiverPhone ?? '-'})',
              style: TG.bodySm(context, color: TG.inkSoft),
            ),
          if (o.itemsSummary != null && o.itemsSummary!.isNotEmpty)
            Text(
              '${o.isMart ? 'Belanja' : 'Pesanan'}: ${o.itemsSummary}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TG.bodySm(context, color: TG.inkSoft, w: FontWeight.w600),
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
                o.isCompleted ? '+${rp(o.driverEarning)}' : rp(o.totalFare),
                style: TG.titleSm(
                  context,
                  color: o.isCompleted ? TG.leafDeep : TG.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
