import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/theme.dart';

/// Splash dengan animasi logo + tagline.
class SplashScreen extends StatefulWidget {
  final Widget next;
  const SplashScreen({super.key, required this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
  );
  late final Animation<double> _scale = Tween(begin: 0.82, end: 1.0).animate(
    CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    ),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => widget.next,
          transitionsBuilder: (_, a, _, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 450),
        ),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blob dekoratif
          Positioned(
            top: -110,
            right: -90,
            child: _Blob(size: 300, color: TG.ocean.withValues(alpha: 0.14)),
          ),
          Positioned(
            bottom: -130,
            left: -100,
            child: _Blob(size: 340, color: TG.leaf.withValues(alpha: 0.16)),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: TG.brandGradient,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: TG.ocean.withValues(alpha: 0.35),
                            blurRadius: 40,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.electric_bolt_rounded,
                        color: Colors.white,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Torang Go',
                      style: TG.display(context, color: TG.ink),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConfig.tagline,
                      style: TG.body(context, color: TG.inkSoft),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        strokeCap: StrokeCap.round,
                        color: TG.leaf.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Halmahera Barat • Maluku Utara',
                style: TG.bodySm(context, color: TG.inkSoft),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
