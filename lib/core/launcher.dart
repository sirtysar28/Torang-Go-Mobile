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

  /// Buka koordinat di Google Maps (lihat lokasi kos / merchant).
  static Future<bool> openMaps(double lat, double lng, {String? label}) async {
    final q = label == null
        ? '$lat,$lng'
        : '${Uri.encodeComponent(label)}@$lat,$lng';
    return _tryLaunch(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
      fallback: Uri.parse(
        'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=17/$lat/$lng',
      ),
    );
  }

  static Future<bool> _tryLaunch(Uri uri, {Uri? fallback}) async {
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (fallback != null && await canLaunchUrl(fallback)) {
        return await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
