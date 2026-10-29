import 'package:url_launcher/url_launcher.dart';

/// Helper buka aplikasi luar: WhatsApp, telepon, Google Maps, email.
class TgLauncher {
  TgLauncher._();

  /// Normalisasi nomor HP Indonesia ke format internasional tanpa "+".
  /// 08123456789 → 628123456789 ; 62812… → tetap ; +62812… → 62812…
  static String normalizePhone(String raw) {
    var n = raw.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (n.startsWith('62')) return n;
    if (n.startsWith('0')) n = '62${n.substring(1)}';
    return n;
  }

  /// Buka chat WhatsApp ke nomor admin (opsional dengan teks awal).
  static Future<bool> openWhatsApp(String phone, {String message = ''}) async {
    final number = normalizePhone(phone);
    if (number.isEmpty) return false;
    final text = Uri.encodeComponent(
      message.isEmpty ? 'Halo Admin Torang Go! 👋' : message,
    );
    final uri = Uri.parse('https://wa.me/$number?text=$text');
    return _tryLaunch(uri, fallback: Uri.parse('https://wa.me/$number'));
  }

  /// Telepon langsung (driver / pemilik kos).
  static Future<bool> call(String phone) async {
    final number = phone.trim();
    if (number.isEmpty) return false;
    return _tryLaunch(Uri.parse('tel:$number'));
  }

  /// Kirim email (support).
  static Future<bool> email(String address, {String subject = ''}) async {
    return _tryLaunch(
      Uri(
        scheme: 'mailto',
        path: address,
        query: subject.isEmpty
            ? null
            : 'subject=${Uri.encodeComponent(subject)}',
      ),
    );
  }

  /// Buka koordinat di aplikasi peta (Google Maps / app peta lain).
  ///
  /// Urutan percobaan:
  /// 1. URI `geo:` — standar Android, diterima Google Maps & app peta lain
  /// 2. Google Maps versi web (dibuka lewat browser / app)
  /// 3. OpenStreetMap versi web
  ///
  /// TIDAK memakai `canLaunchUrl` — di Android 11+ hasilnya sering `false`
  /// walau aplikasi peta ada (visibilitas package), jadi dulu tombol peta
  /// selalu gagal. Sekarang: launch langsung, tangkap errornya, coba berikutnya.
  static Future<bool> openMaps(double lat, double lng, {String? label}) async {
    final latS = lat.toStringAsFixed(6);
    final lngS = lng.toStringAsFixed(6);
    final name = label?.trim() ?? '';

    // 1) geo: — URI standar Android untuk membuka aplikasi peta
    if (name.isEmpty) {
      if (await _launch(Uri.parse('geo:$latS,$lngS'))) return true;
    } else {
      final q = Uri.encodeQueryComponent(name);
      if (await _launch(Uri.parse('geo:$latS,$lngS?q=$latS,$lngS($q)'))) {
        return true;
      }
      if (await _launch(Uri.parse('geo:$latS,$lngS'))) return true;
    }

    // 2) Google Maps web/app
    final q = name.isEmpty
        ? '$latS,$lngS'
        : '${Uri.encodeQueryComponent(name)}@$latS,$lngS';
    if (await _launch(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
    )) {
      return true;
    }

    // 3) OpenStreetMap web
    return _launch(
      Uri.parse(
        'https://www.openstreetmap.org/?mlat=$latS&mlon=$lngS#map=17/$latS/$lngS',
      ),
    );
  }

  /// Launch URL langsung — true kalau berhasil dibuka aplikasi luar.
  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _tryLaunch(Uri uri, {Uri? fallback}) async {
    // Coba langsung launch dulu (canLaunchUrl tidak selalu akurat di
    // Android 11+), baru fallback ke URL cadangan.
    if (await _launch(uri)) return true;
    if (fallback != null && await _launch(fallback)) return true;
    return false;
  }
}
