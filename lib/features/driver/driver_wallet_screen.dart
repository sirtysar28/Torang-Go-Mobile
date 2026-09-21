import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';

class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen>
    with AutomaticKeepAliveClientMixin {
  double _balance = 0, _totalIncome = 0, _totalCommission = 0;
  List<WalletTransaction> _tx = [];
  bool _loading = true;
  bool _withdrawing = false;

  final _amount = TextEditingController();
  final _bank = TextEditingController();
  final _accountNumber = TextEditingController();
  final _accountName = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _bank.dispose();
    _accountNumber.dispose();
    _accountName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final w = await ApiClient.I.get('/driver/wallet');
      final t = await ApiClient.I.get('/driver/wallet/transactions');
      if (!mounted) return;
      setState(() {
        _balance = (w['balance'] as num?)?.toDouble() ?? 0;
        _totalIncome = (w['total_income'] as num?)?.toDouble() ?? 0;
        _totalCommission = (w['total_commission'] as num?)?.toDouble() ?? 0;
        _tx = ((t['transactions'] as List?) ?? [])
            .map(
              (e) => WalletTransaction(
                e['id'] as int,
                (e['type'] ?? '').toString(),
                (e['amount'] as num?)?.toDouble() ?? 0,
                (e['description'] ?? '').toString(),
                e['at']?.toString(),
              ),
            )
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

  Future<void> _showWithdrawSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TG.sand,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
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
            Text('Tarik saldo 💸', style: TG.title(context)),
            const SizedBox(height: 4),
            Text(
              'Saldo tersedia: ${rp(_balance)}',
              style: TG.body(context, color: TG.inkSoft),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.payments_rounded, color: TG.inkSoft),
                labelText: 'Nominal (min. Rp 10.000)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bank,
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.account_balance_rounded,
                  color: TG.inkSoft,
                ),
                labelText: 'Nama bank (contoh: BRI)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _accountNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.pin_rounded, color: TG.inkSoft),
                labelText: 'Nomor rekening',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _accountName,
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: TG.inkSoft,
                ),
                labelText: 'Nama pemilik rekening',
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Ajukan Penarikan',
              icon: Icons.send_rounded,
              loading: _withdrawing,
              onTap: () async {
                final amt = double.tryParse(_amount.text.trim());
                if (amt == null || amt < 10000) {
                  tgSnackbar(ctx, 'Nominal minimal Rp 10.000 ya.', error: true);
                  return;
                }
                setState(() => _withdrawing = true);
                try {
                  final res = await ApiClient.I.post(
                    '/driver/wallet/withdraw',
                    body: {
                      'amount': amt,
                      'bank_name': _bank.text.trim(),
                      'account_number': _accountNumber.text.trim(),
                      'account_name': _accountName.text.trim(),
                    },
                  );
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    tgSnackbar(ctx, res['message']?.toString() ?? 'Diajukan!');
                    _load();
                  }
                } catch (e) {
                  if (ctx.mounted) tgSnackbar(ctx, e.toString(), error: true);
                } finally {
                  if (mounted) setState(() => _withdrawing = false);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: TG.leaf))
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
                children: [
                  Text('Dompet Driver', style: TG.title(context)),
                  const SizedBox(height: 14),
                  // Kartu saldo
                  Container(
                    padding: const EdgeInsets.all(22),
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
                              Icons.savings_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Saldo siap ditarik',
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
                                'AKTIF',
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
                          rp(_balance),
                          style: TG
                              .display(context, color: Colors.white)
                              .copyWith(fontSize: 32),
                        ),
                        const SizedBox(height: 18),
                        PrimaryButton(
                          label: 'Tarik Saldo',
                          icon: Icons.download_rounded,
                          gradient: false,
                          onTap: _showWithdrawSheet,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _miniStat(
                          'Total masuk',
                          rp(_totalIncome),
                          Icons.trending_up_rounded,
                          TG.leafDeep,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _miniStat(
                          'Komisi app',
                          rp(_totalCommission),
                          Icons.percent_rounded,
                          TG.coral,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionTitle('Riwayat transaksi'),
                  if (_tx.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'Belum ada transaksi',
                    )
                  else
                    for (final t in _tx)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: TG.card(),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: t.isCredit
                                      ? TG.leafSoft
                                      : TG.coralSoft,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  t.isCredit
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 19,
                                  color: t.isCredit ? TG.leafDeep : TG.coral,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TG.body(
                                        context,
                                        w: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeAgoIso(t.at),
                                      style: TG.bodySm(
                                        context,
                                        color: TG.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${t.isCredit ? '+' : '-'}${rp(t.amount.abs())}',
                                style: TG.titleSm(
                                  context,
                                  color: t.isCredit ? TG.leafDeep : TG.coral,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TG.card(),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TG.titleSm(context),
          ),
          const SizedBox(height: 2),
          Text(label, style: TG.bodySm(context, color: TG.inkSoft)),
        ],
      ),
    );
  }
}
