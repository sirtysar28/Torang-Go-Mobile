import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/launcher.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';

/// Sewa Kos — cari kos-kosan di sekitar Jailolo / Halmahera Barat.
class KosScreen extends StatefulWidget {
  const KosScreen({super.key});

  @override
  State<KosScreen> createState() => _KosScreenState();
}

class _KosScreenState extends State<KosScreen> {
  List<Merchant> _kos = [];
  bool _loading = true;
  String _query = '';
  String _sort = 'murah'; // murah | rating

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.I.get('/merchants', query: {'type': 'kos'});
      if (!mounted) return;
      setState(() {
        _kos = ((res['merchants'] as List?) ?? [])
            .map((e) => Merchant.fromJson(e))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        tgSnackbar(context, e.toString(), error: true);
      }
    }
  }

  List<Merchant> get _filtered {
    var list = _kos
        .where(
          (k) =>
              _query.trim().isEmpty ||
              k.name.toLowerCase().contains(_query.toLowerCase()) ||
              (k.category ?? '').toLowerCase().contains(_query.toLowerCase()) ||
              (k.address ?? '').toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    list.sort(
      (a, b) => _sort == 'murah'
          ? (a.priceMonthly ?? 0).compareTo(b.priceMonthly ?? 0)
          : b.rating.compareTo(a.rating),
    );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sewa Kos 🏠')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: TG.leaf))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 10),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, color: TG.inkSoft),
                      hintText: 'Cari kos (nama / jenis / alamat)…',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      for (final (id, label) in const [
                        ('murah', 'Harga termurah'),
                        ('rating', 'Rating tertinggi'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _sort = id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: _sort == id ? TG.brandGradient : null,
                                color: _sort == id ? null : TG.white,
                                borderRadius: BorderRadius.circular(20),
                                border: _sort == id
                                    ? null
                                    : Border.all(color: TG.line),
                              ),
                              child: Text(
                                label,
                                style: TG.label(
                                  context,
                                  color: _sort == id
                                      ? Colors.white
                                      : TG.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: TG.ocean,
                    child: _filtered.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              EmptyState(
                                icon: Icons.home_work_rounded,
                                title: 'Kos tidak ketemu',
                                subtitle:
                                    'Coba kata kunci lain — atau chat admin untuk info kos baru.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _kosCard(_filtered[i]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _kosCard(Merchant k) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TG.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: TG.promoGradientAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('🏠', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TG.titleSm(context),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (k.category != null) ...[
                          Text(
                            k.category!,
                            style: TG.bodySm(context, color: TG.inkSoft),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '★ ${k.rating.toStringAsFixed(1)}',
                          style: TG.bodySm(
                            context,
                            color: TG.leafDeep,
                            w: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    k.priceMonthly != null ? rp(k.priceMonthly) : 'Hubungi',
                    style: TG.titleSm(context, color: TG.leafDeep),
                  ),
                  Text('/ bulan', style: TG.bodySm(context, color: TG.inkSoft)),
                ],
              ),
            ],
          ),
          if (k.address != null && k.address!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: TG.inkSoft,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    k.address!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TG.bodySm(context, color: TG.inkSoft),
                  ),
                ),
              ],
            ),
          ],
          if (k.facilities.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in k.facilities.take(5))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: TG.navySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      f,
                      style: TG.bodySm(
                        context,
                        color: TG.oceanDeep,
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (k.lat == null || k.lng == null)
                      ? null
                      : () async {
                          final ok = await TgLauncher.openMaps(
                            k.lat!,
                            k.lng!,
                            label: k.name,
                          );
                          if (!ok && mounted) {
                            tgSnackbar(
                              context,
                              'Aplikasi peta tidak tersedia di HP kamu.',
                              error: true,
                            );
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TG.ocean,
                    side: const BorderSide(color: TG.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: const Icon(Icons.map_rounded, size: 17),
                  label: const Text('Lihat Peta'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final ok = await TgLauncher.openWhatsApp(
                      k.phone ?? '',
                      message:
                          'Halo, saya mau tanya kos "${k.name}" yang saya lihat di aplikasi Torang Go 🏠',
                    );
                    if (!ok && mounted) {
                      tgSnackbar(
                        context,
                        'Nomor pemilik kos belum terdaftar — hubungi admin Torang Go.',
                        error: true,
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 17),
                  label: const Text('Chat Pemilik'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
