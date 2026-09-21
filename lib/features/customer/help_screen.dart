import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/launcher.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';

/// Bantuan Torang — chat dengan bot AI (Tori).
/// Kalau butuh manusia: bot menawarkan chat WhatsApp admin
/// (nomor & status online diatur dari dashboard admin).
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _ChatMsg {
  final String text;
  final bool fromBot;
  final DateTime at;
  _ChatMsg(this.text, this.fromBot, this.at);
}

class _HelpScreenState extends State<HelpScreen> {
  SupportSettings _support = SupportSettings();
  final _msgs = <_ChatMsg>[];
  final _input = TextEditingController();
  bool _sending = false;
  bool _loading = true;
  Timer? _refreshStatus;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Status admin dicek ulang tiap 30 detik (online/offline).
    _refreshStatus = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadSettings(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshStatus?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadSettings({bool silent = false}) async {
    try {
      final res = await ApiClient.I.get('/support/settings');
      if (!mounted) return;
      setState(() => _support = SupportSettings.fromJson(res['support']));
      if (!silent && _msgs.isEmpty) {
        _msgs.add(
          _ChatMsg(
            'Halo torang! 👋 Aku **Tori**, asisten AI Torang Go — siap bantu '
            '24 jam. Tanya apa saja soal Torang Ride, Bentor, Car, Makan, Mart, '
            'Kirim, Bayar, sampai Sewa Kos. Kalau butuh manusia, bilang saja '
            '"admin" — nanti torang sambungkan ke admin lewat WhatsApp ya!',
            true,
            DateTime.now(),
          ),
        );
      }
    } catch (_) {
      if (_msgs.isEmpty) {
        _msgs.add(
          _ChatMsg(
            'Halo! Aku Tori 🤖 asisten Torang Go. Tanya apa saja ya!',
            true,
            DateTime.now(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _msgs.add(_ChatMsg(text, false, DateTime.now()));
      _sending = true;
    });
    _scrollDown();

    try {
      final res = await ApiClient.I.post('/help/chat', body: {'message': text});
      if (!mounted) return;
      final reply = (res['reply'] ?? '…').toString();
      setState(() {
        _msgs.add(_ChatMsg(reply, true, DateTime.now()));
        _support = SupportSettings(
          adminWhatsapp: (res['whatsapp'] ?? _support.adminWhatsapp).toString(),
          supportEmail: _support.supportEmail,
          supportHours: _support.supportHours,
          botName: _support.botName,
          adminOnline: res['admin_online'] == true,
        );
      });
      _scrollDown();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _msgs.add(
          _ChatMsg(
            'Aduh, koneksi ke server torang terganggu 😅 — cek internet kamu lalu coba kirim ulang ya.',
            true,
            DateTime.now(),
          ),
        ),
      );
      _scrollDown();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _chatAdminWa() async {
    final ok = await TgLauncher.openWhatsApp(
      _support.adminWhatsapp,
      message:
          'Halo Admin Torang Go! 👋 Saya butuh bantuan soal aplikasi Torang Go.',
    );
    if (!ok && mounted) {
      tgSnackbar(
        context,
        'Tidak bisa membuka WhatsApp. Pastikan WhatsApp terpasang di HP kamu.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bantuan Torang 💬'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _chatAdminWa,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _support.adminOnline
                      ? const Color(0xFF25D366).withValues(alpha: 0.14)
                      : TG.navySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  size: 20,
                  color: _support.adminOnline
                      ? const Color(0xFF128C4A)
                      : TG.inkSoft,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _statusBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: TG.leaf))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _msgs.length + (_sending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (_sending && i == _msgs.length) {
                        return _typingBubble();
                      }
                      final m = _msgs[i];
                      return _bubble(m);
                    },
                  ),
          ),
          _quickReplies(),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _statusBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: TG.card(radius: 16),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _support.adminOnline ? TG.leaf : TG.inkSoft,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_support.adminOnline ? TG.leaf : TG.inkSoft)
                      .withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _support.adminOnline
                  ? 'Admin ONLINE — siap chat via WhatsApp'
                  : 'Admin offline — dijawab bot AI 24 jam'
                        '${_support.supportHours.isNotEmpty ? ' (${_support.supportHours})' : ''}',
              style: TG.bodySm(context, w: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: _chatAdminWa,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF25D366).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'Chat Admin',
                    style: TG.bodySm(
                      context,
                      color: Colors.white,
                      w: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_ChatMsg m) {
    final isBot = m.fromBot;
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isBot ? TG.white : TG.ocean,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isBot ? 4 : 18),
            bottomRight: Radius.circular(isBot ? 18 : 4),
          ),
          border: isBot ? Border.all(color: TG.line) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBot)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: TG.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _support.botName.split(' ').first,
                      style: TG.bodySm(
                        context,
                        color: TG.ocean,
                        w: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              m.text.replaceAll('**', ''),
              style: TG.body(
                context,
                color: isBot ? TG.ink : Colors.white,
                w: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TG.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TG.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.circle,
                  size: 7,
                  color: TG.inkSoft.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quickReplies() {
    const chips = [
      'Cara pesan ride',
      'Berapa tarif?',
      'Torang Bentor',
      'Torang Makan',
      'Torang Bayar',
      'Sewa Kos',
      'Jadi mitra',
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          backgroundColor: TG.oceanSoft,
          side: const BorderSide(color: TG.line),
          label: Text(
            chips[i],
            style: TG.bodySm(context, color: TG.ocean, w: FontWeight.w700),
          ),
          onPressed: () => _send(chips[i]),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Tanya torang apa saja…',
                  prefixIcon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: TG.inkSoft,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sending ? null : () => _send(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: TG.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: TG.ocean.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _sending
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
