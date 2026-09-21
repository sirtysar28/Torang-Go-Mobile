import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  final Widget next;
  const OnboardingScreen({super.key, required this.next});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final pages = const [
    _OnboardPage(
      emoji: '🛵',
      gradient: [Color(0xFF1477E6), Color(0xFF1D8FE0)],
      title: 'Antar torang ke mana saja',
      subtitle:
          'Ojek & bentor lokal siap antar kamu keliling Jailolo sampai sudut-sudut Halmahera Barat.',
    ),
    _OnboardPage(
      emoji: '📦',
      gradient: [Color(0xFF2FAE4E), Color(0xFF4FC3F7)],
      title: 'Kirim barang lebih gampang',
      subtitle:
          'Paket, dokumen, belanjaan — dijemput di depan rumah, sampai tujuan dengan aman.',
    ),
    _OnboardPage(
      emoji: '🤝',
      gradient: [Color(0xFFFF7A45), Color(0xFF8E5BE6)],
      title: 'Bareng driver lokal',
      subtitle:
          'Tarif transparan, pembayaran tunai atau QRIS, dan driver terverifikasi dari torang sendiri.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => widget.next));
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = AppConfig.role == AppRole.driver;
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => pages[i],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Lewati',
                        style: TG.label(context, color: TG.inkSoft),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) {
                      final on = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: on ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: on ? TG.brandGradient : null,
                          color: on ? null : TG.line,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _page == pages.length - 1
                        ? (isDriver ? 'Mulai Kerja' : 'Gas, Mulai!')
                        : 'Lanjut',
                    icon: _page == pages.length - 1
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    onTap: () {
                      if (_page == pages.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 340),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
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

class _OnboardPage extends StatelessWidget {
  final String emoji, title, subtitle;
  final List<Color> gradient;
  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.4),
                  blurRadius: 34,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 34),
          Text(title, style: TG.display(context, color: TG.ink)),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: TG.body(context, color: TG.inkSoft, w: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
