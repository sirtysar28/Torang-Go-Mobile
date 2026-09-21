import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

/// Diagnostik koneksi ke server produksi.
///
/// Dibuka dari layar login: TAP kartu "Server: ..." di bagian bawah.
/// Berguna kalau aplikasi tidak bisa memanggil API — layar ini menunjukkan
/// TAHAP mana yang gagal: DNS, TCP, TLS/SSL, atau HTTP.
class ConnectionCheckScreen extends StatefulWidget {
  const ConnectionCheckScreen({super.key});

  @override
  State<ConnectionCheckScreen> createState() => _ConnectionCheckScreenState();
}

enum _Status { waiting, running, ok, fail }

class _Step {
  final String title;
  final String subtitle;
  _Status status = _Status.waiting;
  String? detail;
  _Step(this.title, this.subtitle);
}

class _ConnectionCheckScreenState extends State<ConnectionCheckScreen> {
  final _steps = <_Step>[
    _Step('Perangkat & jam', 'Info HP + tanggal/jam (SSL sensitif jam)'),
    _Step('Koneksi internet', 'Ping ke server publik (dns.google)'),
    _Step('DNS', 'Terjemahkan nama domain server jadi IP'),
    _Step('TCP :443', 'Sambungan ke port HTTPS server'),
    _Step('TLS/SSL', 'Negosiasi koneksi aman + sertifikat'),
    _Step('HTTP /api/v1/places', 'Request API publik Torang Go'),
  ];

  bool _running = false;
  bool get _allDone => !_steps.any((s) => s.status == _Status.waiting);

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      for (final s in _steps) {
        s.status = _Status.waiting;
        s.detail = null;
      }
    });

    final host = Uri.tryParse(AppConfig.apiBase)?.host ?? AppConfig.apiBase;

    // ---- 0. Info perangkat ----
    final s0 = _steps[0]..status = _Status.running;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 150));
    s0.detail =
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
        'Jam HP: ${DateTime.now()}';
    s0.status = _Status.ok;
    setState(() {});

    // ---- 1. Koneksi internet umum ----
    final s1 = _steps[1]..status = _Status.running;
    setState(() {});
    try {
      final r = await InternetAddress.lookup(
        'dns.google',
      ).timeout(const Duration(seconds: 8));
      s1.detail = 'OK — internet aktif (dns.google → ${r.first.address})';
      s1.status = _Status.ok;
    } catch (e) {
      s1.detail = 'GAGAL: $e';
      s1.status = _Status.fail;
    }
    setState(() {});

    // ---- 2. DNS server Torang Go ----
    final s2 = _steps[2]..status = _Status.running;
    setState(() {});
    try {
      final r = await InternetAddress.lookup(
        host,
      ).timeout(const Duration(seconds: 8));
      final ips = r.map((a) => a.address).toSet().join(', ');
      s2.detail = 'OK — $host → $ips';
      s2.status = _Status.ok;
    } catch (e) {
      s2.detail = 'GAGAL: domain tidak terresolve.\n$e';
      s2.status = _Status.fail;
    }
    setState(() {});

    // ---- 3. TCP ke port 443 ----
    final s3 = _steps[3]..status = _Status.running;
    setState(() {});
    Socket? sock;
    try {
      sock = await Socket.connect(
        host,
        443,
        timeout: const Duration(seconds: 10),
      ).onError((e, _) => throw e!);
      s3.detail = 'OK — port 443 server terbuka';
      s3.status = _Status.ok;
    } catch (e) {
      s3.detail = 'GAGAL: tidak bisa membuka koneksi ke $host:443\n$e';
      s3.status = _Status.fail;
    } finally {
      sock?.destroy();
    }
    setState(() {});

    // ---- 4 & 5. TLS + HTTP via ApiClient (/places) ----
    final s4 = _steps[4]..status = _Status.running;
    final s5 = _steps[5];
    setState(() {});
    final sw = Stopwatch()..start();
    try {
      final res = await ApiClient.I.get('/places');
      sw.stop();
      // TLS sukses (tercepat dari handshake) → tandai OK
      s4.detail = 'OK — sertifikat diterima & dipercaya';
      s4.status = _Status.ok;
      final zones = (res is Map && res['zones'] is List)
          ? (res['zones'] as List).length
          : '?';
      s5.detail = 'OK — ${sw.elapsedMilliseconds} ms • $zones zona diterima';
      s5.status = _Status.ok;
    } catch (e) {
      sw.stop();
      final msg = e.toString().replaceFirst(apiExceptionPrefix, '');
      final isTls =
          msg.contains('SSL') ||
          msg.contains('SSL') ||
          msg.contains('handshake') ||
          msg.contains('Handshake') ||
          msg.contains('CERTIFICATE') ||
          msg.contains('jam');
      if (isTls) {
        s4.detail = 'GAGAL: $msg';
        s4.status = _Status.fail;
        s5.detail = 'Dilewati — TLS belum sukses';
        s5.status = _Status.waiting;
      } else {
        s4.detail = 'OK — koneksi aman terbentuk';
        s4.status = _Status.ok;
        s5.detail = 'GAGAL: $msg';
        s5.status = _Status.fail;
      }
    }
    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final ok = _steps.where((s) => s.status == _Status.ok).length;
    final fail = _steps.where((s) => s.status == _Status.fail).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Koneksi Server'),
        backgroundColor: TG.ocean,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: TG.card(radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dns_rounded, color: TG.ocean, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Server produksi',
                        style: TG.titleSm(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppConfig.apiBase,
                  style: TG.body(context, color: TG.inkSoft),
                ),
                const SizedBox(height: 12),
                if (_allDone)
                  Row(
                    children: [
                      Icon(
                        fail == 0 ? Icons.check_circle : Icons.error,
                        color: fail == 0 ? TG.leafDeep : TG.coral,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        fail == 0
                            ? 'Semua tahap LULUS ($ok/$ok)'
                            : 'Ada $fail tahap GAGAL — lihat detail di bawah',
                        style: TG
                            .label(
                              context,
                              color: fail == 0 ? TG.leafDeep : TG.coral,
                            )
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ..._steps.map(_stepTile),
          const SizedBox(height: 10),
          PrimaryButton(
            label: _running ? 'Memeriksa…' : 'Mulai Periksa',
            icon: Icons.play_arrow_rounded,
            loading: _running,
            onTap: _running ? null : _run,
          ),
          const SizedBox(height: 12),
          Text(
            'Tips: kalau tahap TLS gagal, biasanya jam HP salah atau '
            'jaringan operator memblokir. Kalau DNS gagal, coba ganti '
            'WiFi ↔ kuota internet.',
            style: TG.bodySm(context, color: TG.inkSoft),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan lama untuk salin hasil:',
            style: TG.bodySm(context, color: TG.inkSoft),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onLongPress: () {
              final buf = StringBuffer()
                ..writeln('Torang Go — Cek Koneksi')
                ..writeln('Server: ${AppConfig.apiBase}')
                ..writeln(
                  '${Platform.operatingSystem} '
                  '${Platform.operatingSystemVersion}',
                )
                ..writeln(DateTime.now().toIso8601String());
              for (final s in _steps) {
                buf.writeln('--- ${s.title}: ${s.status.name}');
                if (s.detail != null) buf.writeln(s.detail);
              }
              Clipboard.setData(ClipboardData(text: buf.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hasil pemeriksaan disalin ✓')),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: TG.card(radius: 14),
              child: Text(
                'Hasil lengkap (tekan lama untuk salin)',
                style: TG.bodySm(context, color: TG.inkSoft),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTile(_Step s) {
    late Widget leading;
    switch (s.status) {
      case _Status.waiting:
        leading = const Icon(
          Icons.radio_button_unchecked_rounded,
          color: TG.inkSoft,
          size: 22,
        );
      case _Status.running:
        leading = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        );
      case _Status.ok:
        leading = const Icon(
          Icons.check_circle_rounded,
          color: TG.leafDeep,
          size: 22,
        );
      case _Status.fail:
        leading = const Icon(Icons.cancel_rounded, color: TG.coral, size: 22);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: TG.card(radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title, style: TG.titleSm(context)),
                const SizedBox(height: 2),
                Text(s.subtitle, style: TG.bodySm(context, color: TG.inkSoft)),
                if (s.detail != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: s.status == _Status.fail
                          ? TG.coral.withValues(alpha: 0.08)
                          : TG.sandDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(s.detail!, style: TG.bodySm(context)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Prefix "Exception: ApiException" dari toString().
const apiExceptionPrefix = 'Exception: ';
