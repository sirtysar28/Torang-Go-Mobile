import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system Torang Go — modernisasi dari torang_go_dashboard.html
class TG {
  TG._();

  // ---- Palet warna ----
  static const ocean = Color(0xFF1477E6);
  static const oceanDeep = Color(0xFF0B3B66);
  static const leaf = Color(0xFF2FAE4E);
  static const leafDeep = Color(0xFF177A34);
  static const sand = Color(0xFFFBF6EC);
  static const sandDark = Color(0xFFEDE7D6);
  static const coral = Color(0xFFFF7A45);
  static const ink = Color(0xFF0E2233);
  static const inkSoft = Color(0xFF5B6B76);
  static const line = Color(0xFFE7E0CF);
  static const white = Color(0xFFFFFFFF);

  static const oceanSoft = Color(0xFFE3F0FE);
  static const leafSoft = Color(0xFFE6F6E9);
  static const coralSoft = Color(0xFFFFEBE1);
  static const navySoft = Color(0xFFE7EEF6);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1477E6), Color(0xFF1D8FE0), Color(0xFF2FAE4E)],
  );

  static const promoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B3B66), Color(0xFF1477E6), Color(0xFF2FAE4E)],
  );

  static const promoGradientAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF177A34), Color(0xFF2FAE4E), Color(0xFF4FC3F7)],
  );

  // ---- Tipografi ----
  static TextStyle display(BuildContext c, {Color? color}) =>
      GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.2,
      );

  static TextStyle title(BuildContext c, {Color? color}) => GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: color,
    height: 1.3,
  );

  static TextStyle titleSm(BuildContext c, {Color? color}) =>
      GoogleFonts.manrope(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle body(
    BuildContext c, {
    Color? color,
    FontWeight w = FontWeight.w400,
  }) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: w,
    color: color,
    height: 1.45,
  );

  static TextStyle bodySm(
    BuildContext c, {
    Color? color,
    FontWeight w = FontWeight.w400,
  }) => GoogleFonts.inter(fontSize: 11.5, fontWeight: w, color: color);

  static TextStyle label(BuildContext c, {Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: color,
  );

  // ---- Dekorasi kartu ----
  static BoxDecoration card({Color color = white, double radius = 20}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static ThemeData theme(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: sand,
      colorScheme: base.colorScheme.copyWith(
        primary: ocean,
        secondary: leaf,
        error: coral,
        surface: sand,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: sand,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        iconTheme: const IconThemeData(color: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        hintStyle: GoogleFonts.inter(color: inkSoft, fontSize: 13.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ocean, width: 1.4),
        ),
        errorStyle: GoogleFonts.inter(fontSize: 11),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// Status order → warna & ikon chip.
class OrderStatusVisual {
  final Color color;
  final Color soft;
  final IconData icon;
  const OrderStatusVisual(this.color, this.soft, this.icon);

  static OrderStatusVisual of(String? status) {
    switch (status) {
      case 'pending':
      case 'searching_driver':
        return const OrderStatusVisual(
          TG.coral,
          TG.coralSoft,
          Icons.travel_explore_rounded,
        );
      case 'driver_assigned':
      case 'driver_on_the_way':
        return const OrderStatusVisual(
          TG.ocean,
          TG.oceanSoft,
          Icons.two_wheeler_rounded,
        );
      case 'driver_arrived':
        return const OrderStatusVisual(
          Color(0xFF8E5BE6),
          Color(0xFFF0E8FE),
          Icons.pin_drop_rounded,
        );
      case 'trip_started':
        return const OrderStatusVisual(
          TG.leafDeep,
          TG.leafSoft,
          Icons.route_rounded,
        );
      case 'completed':
        return const OrderStatusVisual(
          TG.leafDeep,
          TG.leafSoft,
          Icons.check_circle_rounded,
        );
      case 'cancelled':
        return const OrderStatusVisual(
          Color(0xFFB3261E),
          Color(0xFFFCE8E6),
          Icons.cancel_rounded,
        );
      default:
        return const OrderStatusVisual(
          TG.inkSoft,
          TG.navySoft,
          Icons.info_rounded,
        );
    }
  }
}

/// Urutan milestone perjalanan (untuk timeline customer).
const kTripFlow = [
  'searching_driver',
  'driver_assigned',
  'driver_on_the_way',
  'driver_arrived',
  'trip_started',
  'completed',
];

const kActiveStatuses = [
  'pending',
  'searching_driver',
  'driver_assigned',
  'driver_on_the_way',
  'driver_arrived',
  'trip_started',
];

/// Label Indonesia untuk flow order (fallback jika API tak mengirim).
String statusLabelId(String? status) {
  switch (status) {
    case 'pending':
      return 'Menunggu';
    case 'searching_driver':
      return 'Mencari Driver';
    case 'driver_assigned':
      return 'Driver Ditugaskan';
    case 'driver_on_the_way':
      return 'Driver Menuju Lokasi';
    case 'driver_arrived':
      return 'Driver Tiba';
    case 'trip_started':
      return 'Perjalanan Dimulai';
    case 'completed':
      return 'Selesai';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      return status ?? '-';
  }
}

// ============================================================
// Layanan Torang Go — label, emoji & warna chip
// ============================================================
class ServiceVisual {
  final String label;
  final String emoji;
  final Color color;
  final Color soft;
  const ServiceVisual(this.label, this.emoji, this.color, this.soft);
}

const _serviceVisuals = {
  'ride': ServiceVisual('Ride', '🛵', TG.ocean, TG.oceanSoft),
  'bentor': ServiceVisual('Bentor', '🛺', TG.leafDeep, TG.leafSoft),
  'car': ServiceVisual('Car', '🚗', TG.oceanDeep, TG.navySoft),
  'send': ServiceVisual('Kirim', '📦', TG.leafDeep, TG.leafSoft),
  'food': ServiceVisual('Makan', '🍜', TG.coral, TG.coralSoft),
  'mart': ServiceVisual('Mart', '🛒', TG.ocean, TG.oceanSoft),
};

ServiceVisual serviceVisualOf(String? type) =>
    _serviceVisuals[type] ??
    const ServiceVisual('Order', '⚡', TG.inkSoft, TG.navySoft);

/// "🛵 Ride" — chip layanan di kartu order.
String serviceLabelId(String? type) {
  final v = serviceVisualOf(type);
  return '${v.emoji} ${v.label}';
}

/// Nama lengkap layanan untuk AppBar.
String serviceTitleId(String? type) => switch (type) {
  'ride' => 'Torang Ride 🛵',
  'bentor' => 'Torang Bentor 🛺',
  'car' => 'Torang Car 🚗',
  'send' => 'Torang Kirim 📦',
  'food' => 'Torang Makan 🍜',
  'mart' => 'Torang Mart 🛒',
  _ => 'Torang Go ⚡',
};
