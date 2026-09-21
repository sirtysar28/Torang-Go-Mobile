import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class TGNavBarItem {
  final IconData icon;
  final String label;
  const TGNavBarItem(this.icon, this.label);
}

/// Bottom nav floating ala Torang Go — dipakai customer & driver.
class TGNavBar extends StatelessWidget {
  final int index;
  final List<TGNavBarItem> items;
  final ValueChanged<int> onTap;
  const TGNavBar({
    super.key,
    required this.index,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: TG.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: TG.line),
        boxShadow: [
          BoxShadow(
            color: TG.ink.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final on = i == index;
          final item = items[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  gradient: on ? TG.brandGradient : null,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 21,
                      color: on ? Colors.white : TG.inkSoft,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TG.bodySm(
                        context,
                        color: on ? Colors.white : TG.inkSoft,
                        w: on ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Tombol utama (gradient / solid)
// ------------------------------------------------------------------
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool gradient;
  final bool danger;
  final bool expand;
  final IconData? icon;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.gradient = true,
    this.danger = false,
    this.expand = true,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 52,
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        gradient: danger ? null : (gradient ? TG.brandGradient : null),
        color: danger ? const Color(0xFFB3261E) : (gradient ? null : TG.ink),
        borderRadius: BorderRadius.circular(18),
        boxShadow: onTap == null
            ? null
            : [
                BoxShadow(
                  color: (danger ? const Color(0xFFB3261E) : TG.ocean)
                      .withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.4,
              ),
            )
          else ...[
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TG
                    .label(context, color: Colors.white)
                    .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: loading ? null : onTap,
        child: child,
      ),
    );
  }
}

// ------------------------------------------------------------------
// Judul section + link "Lihat semua"
// ------------------------------------------------------------------
class SectionTitle extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionTitle(this.text, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(text, style: TG.title(context))),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: TG.oceanSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actionLabel!,
                  style: TG.bodySm(
                    context,
                    color: TG.ocean,
                    w: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Chip status order
// ------------------------------------------------------------------
class StatusChip extends StatelessWidget {
  final String status;
  final String? label;
  const StatusChip(this.status, {super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final v = OrderStatusVisual.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: v.soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(v.icon, size: 13, color: v.color),
          const SizedBox(width: 5),
          Text(
            label ?? statusLabelId(status),
            style: TG.bodySm(context, color: v.color, w: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Empty state
// ------------------------------------------------------------------
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: TG.sandDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 34, color: TG.inkSoft),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TG.titleSm(context),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TG.body(context, color: TG.inkSoft),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Grabber untuk bottom sheet
// ------------------------------------------------------------------
class SheetGrabber extends StatelessWidget {
  final String title;
  const SheetGrabber(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 5,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: TG.line,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
          child: Row(
            children: [Expanded(child: Text(title, style: TG.title(context)))],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// Avatar inisial
// ------------------------------------------------------------------
class InitialAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? bg;
  final Color? fg;
  const InitialAvatar(this.name, {super.key, this.size = 48, this.bg, this.fg});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((e) => e.isEmpty ? '' : e[0])
        .join()
        .toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bg ?? avatarColor(name),
            (bg ?? avatarColor(name)).withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TG
            .titleSm(context, color: fg ?? Colors.white)
            .copyWith(fontSize: size * 0.34),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Peta stilisasi (tanpa API key — cukup untuk MVP/mockup)
// Blok kota + jalan + sungai + rute + pin.
// ------------------------------------------------------------------
class StylizedMap extends StatelessWidget {
  /// posisi fraksional 0..1
  final Offset pickup;
  final Offset destination;
  final Offset? driver;
  final double height;

  const StylizedMap({
    super.key,
    this.pickup = const Offset(0.25, 0.72),
    this.destination = const Offset(0.78, 0.24),
    this.driver,
    this.height = 210,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _MapPainter(pickup, destination, driver),
          child: Stack(
            children: [
              Positioned(
                left: 12,
                top: 12,
                child: _LegendChip(
                  icon: Icons.my_location_rounded,
                  text: 'Jailolo, Halbar',
                  color: TG.ink,
                ),
              ),
              _pin(pickup, TG.ocean, Icons.trip_origin_rounded),
              _pin(destination, const Color(0xFFB3261E), Icons.place_rounded),
              if (driver != null)
                _pin(driver!, TG.leaf, Icons.two_wheeler_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pin(Offset frac, Color color, IconData icon) {
    final align = Alignment(frac.dx * 2 - 1, frac.dy * 2 - 1);
    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: TG.ink.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _LegendChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: TG.ink.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TG.bodySm(context, color: TG.ink, w: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final Offset pickup, destination;
  final Offset? driver;
  _MapPainter(this.pickup, this.destination, this.driver);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Latar pasir
    canvas.drawRect(Offset.zero & size, Paint()..color = TG.sandDark);

    // Blok-blok kota
    final blockPaint = Paint()..color = const Color(0xFFF6F1E2);
    final blockStroke = Paint()
      ..color = TG.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 3; col++) {
        final bw = w / 3 - 14, bh = h / 4 - 14;
        final rect = Rect.fromLTWH(
          7 + col * (w / 3),
          8 + row * (h / 4),
          bw,
          bh,
        );
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));
        canvas.drawRRect(rr, blockPaint);
        canvas.drawRRect(rr, blockStroke);
      }
    }

    // Jalan utama diagonal
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-10, h * 0.68), Offset(w + 10, h * 0.30), road);
    canvas.drawLine(Offset(w * 0.22, -10), Offset(w * 0.72, h + 10), road);

    // Jalan tipis
    final thin = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.55), thin);
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.42, h), thin);

    // Teluk (laut) di pojok kanan atas
    final water = Path()
      ..moveTo(w, 0)
      ..lineTo(w, h * 0.34)
      ..quadraticBezierTo(w * 0.76, h * 0.30, w * 0.66, 0)
      ..close();
    canvas.drawPath(
      water,
      Paint()..color = const Color(0xFFBBDDF7).withValues(alpha: 0.9),
    );

    // ---- Rute ----
    final p = pickup, d = destination;
    final mid = Offset((p.dx + d.dx) / 2, (p.dy + d.dy) / 2);
    final ctrl = Offset(
      mid.dx + (d.dy - p.dy) * 0.25,
      mid.dy - (d.dx - p.dx) * 0.25,
    );
    final route = Path()
      ..moveTo(p.dx * w, p.dy * h)
      ..quadraticBezierTo(ctrl.dx * w, ctrl.dy * h, d.dx * w, d.dy * h);

    // garis rute putih tebal + ocean putus-putus di atasnya
    canvas.drawPath(
      route,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    final dashPaint = Paint()
      ..color = TG.ocean
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final metric in route.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + 10), dashPaint);
        dist += 18;
      }
    }

    void marker(Offset frac, Color color, {bool ring = false}) {
      final c = Offset(frac.dx * w, frac.dy * h);
      if (ring) {
        canvas.drawCircle(
          c,
          16,
          Paint()..color = color.withValues(alpha: 0.25),
        );
      }
      canvas.drawCircle(c, 9, Paint()..color = Colors.white);
      canvas.drawCircle(c, 6.5, Paint()..color = color);
    }

    marker(pickup, TG.ocean);
    marker(destination, const Color(0xFFB3261E));
    if (driver != null) marker(driver!, TG.leaf, ring: true);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.pickup != pickup ||
      old.destination != destination ||
      old.driver != driver;
}

// ------------------------------------------------------------------
// Baris info kecil (ikon + label + nilai)
// ------------------------------------------------------------------
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoRow(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: TG.navySoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 17, color: TG.oceanDeep),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: TG.bodySm(context, color: TG.inkSoft)),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TG.body(context, w: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// Util: snackbar singkat
// ------------------------------------------------------------------
void tgSnackbar(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: error ? TG.coral : TG.leaf,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ],
      ),
    ),
  );
}

/// Warna avatar deterministik dari nama.
Color avatarColor(String name) {
  const palette = [
    Color(0xFF1477E6),
    Color(0xFF2FAE4E),
    Color(0xFFFF7A45),
    Color(0xFF8E5BE6),
    Color(0xFF0B3B66),
    Color(0xFF00A6A6),
  ];
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h + c) % 997;
  }
  return palette[h % palette.length];
}

double clamp01(double v) => math.max(0.0, math.min(1.0, v));
