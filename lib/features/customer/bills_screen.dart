import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';

/// Torang Bayar — PPOB: token PLN, pulsa, paket data, PDAM, BPJS, dll.
/// MVP: pengajuan → dikonfirmasi admin dari dashboard.
class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  List<BillProduct> _products = [];
  List<BillPayment> _bills = [];
  bool _loading = true;
  bool _submitting = false;

  BillProduct? _product;
  final _customerNo = TextEditingController();
  final _amount = TextEditingController();
  String _payment = 'cash';

  static const _icons = {
    'pln_token': Icons.bolt_rounded,
    'pulsa': Icons.phone_android_rounded,
    'pakta_data': Icons.wifi_rounded,
    'pdam': Icons.water_drop_rounded,
    'bpjs': Icons.health_and_safety_rounded,
    'tv': Icons.tv_rounded,
    'game': Icons.sports_esports_rounded,
    'lain': Icons.receipt_long_rounded,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customerNo.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await Future.wait([
        ApiClient.I.get('/bills/products'),
        ApiClient.I.get('/bills'),
      ]);
      if (!mounted) return;
      setState(() {
        _products = ((res[0]['products'] as List?) ?? [])
            .map((e) => BillProduct.fromJson(e))
            .toList();
        _bills = ((res[1]['bills'] as List?) ?? [])
            .map((e) => BillPayment.fromJson(e))
            .toList();
        _product ??= _products.isEmpty ? null : _products.first;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        tgSnackbar(context, e.toString(), error: true);
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_product == null ||
        _customerNo.text.trim().isEmpty ||
        (double.tryParse(_amount.text.trim()) ?? 0) < 1000) {
      tgSnackbar(
        context,
        'Lengkapi nomor & nominal (min. Rp 1.000) dulu ya.',
        error: true,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ApiClient.I.post(
        '/bills',
        body: {
          'product_type': _product!.type,
          'customer_no': _customerNo.text.trim(),
          'amount': double.tryParse(_amount.text.trim()) ?? 0,
          'payment_method': _payment,
        },
      );
      if (!mounted) return;
      tgSnackbar(context, res['message']?.toString() ?? 'Pengajuan dikirim!');
      _customerNo.clear();
      _amount.clear();
      _load();
    } catch (e) {
      if (mounted) tgSnackbar(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Torang Bayar 💳')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: TG.leaf))
          : RefreshIndicator(
              onRefresh: _load,
              color: TG.ocean,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _heroCard(),
                  const SizedBox(height: 16),
                  Text('Pilih jenis tagihan', style: TG.title(context)),
                  const SizedBox(height: 12),
                  _productGrid(),
                  const SizedBox(height: 18),
                  _formCard(),
                  const SizedBox(height: 20),
                  if (_bills.isNotEmpty) ...[
                    SectionTitle('Riwayat Torang Bayar'),
                    for (final b in _bills)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _billTile(b),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: TG.promoGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TG.oceanDeep.withValues(alpha: 0.35),
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
              const Icon(
                Icons.credit_card_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Bayar tagihan tanpa antre',
                style: TG.titleSm(context, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Token listrik, pulsa, paket data, PDAM, BPJS, TV & voucher game — cukup dari rumah. Admin torang yang proses & konfirmasi.',
            style: TG.bodySm(
              context,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.86,
      mainAxisSpacing: 12,
      children: [
        for (final p in _products)
          GestureDetector(
            onTap: () => setState(() => _product = p),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _product?.type == p.type ? TG.ocean : TG.oceanSoft,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: _product?.type == p.type ? TG.ocean : TG.line,
                      width: _product?.type == p.type ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    _icons[p.type] ?? Icons.receipt_rounded,
                    color: _product?.type == p.type
                        ? Colors.white
                        : TG.oceanDeep,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TG.bodySm(
                    context,
                    color: _product?.type == p.type ? TG.ink : TG.inkSoft,
                    w: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _formCard() {
    final p = _product;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TG.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajukan pembayaran — ${p?.name ?? '-'}',
            style: TG.titleSm(context),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customerNo,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.pin_rounded, color: TG.inkSoft),
              labelText: p?.customerLabel ?? 'Nomor',
              hintText: p?.customerLabel ?? 'Nomor',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.payments_rounded, color: TG.inkSoft),
              labelText: 'Nominal (Rp)',
              hintText: 'Contoh: 50000',
              suffixText: p != null && p.adminFee > 0
                  ? '+ admin ${rp(p.adminFee)}'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (id, label) in const [
                ('cash', 'Tunai'),
                ('qris', 'QRIS'),
              ])
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _payment = id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: id == 'cash' ? 10 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: _payment == id ? TG.ocean : TG.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _payment == id ? TG.ocean : TG.line,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TG.label(
                            context,
                            color: _payment == id ? Colors.white : TG.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: _submitting ? 'Mengirim…' : 'Kirim Pengajuan',
            icon: Icons.send_rounded,
            loading: _submitting,
            onTap: _submit,
          ),
          const SizedBox(height: 8),
          Text(
            'Catatan: admin akan menghubungi kamu untuk pembayaran sebelum tagihan diproses.',
            style: TG.bodySm(context, color: TG.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _billTile(BillPayment b) {
    final (color, soft) = switch (b.status) {
      'paid' => (TG.leafDeep, TG.leafSoft),
      'failed' => (const Color(0xFFB3261E), const Color(0xFFFCE8E6)),
      _ => (TG.coral, TG.coralSoft),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TG.card(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _icons[b.productType] ?? Icons.receipt_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TG.titleSm(context),
                ),
                const SizedBox(height: 2),
                Text(
                  '${b.reference} • ${b.customerNo} • ${timeAgoIso(b.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TG.bodySm(context, color: TG.inkSoft),
                ),
                if (b.note != null && b.note!.isNotEmpty)
                  Text(
                    b.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TG.bodySm(context, color: color),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rp(b.total), style: TG.titleSm(context, color: color)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  b.statusLabel ?? b.status,
                  style: TG.bodySm(context, color: color, w: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
