/// Role aplikasi — ditentukan dari entrypoint (main_customer / main_driver).
enum AppRole { customer, driver }

class AppConfig {
  AppConfig._();

  static AppRole role = AppRole.customer;

  /// Bisa dioverride saat build/run (untuk development lokal):
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
  static const _envBase = String.fromEnvironment('API_BASE_URL');

  /// Default: server produksi Torang Go — dipakai di APK/HP asli.
  static String get apiBase {
    if (_envBase.isNotEmpty) return _envBase;
    return 'https://toranggo.biz.id/api/v1';
  }

  static String get appName =>
      role == AppRole.customer ? 'Torang Go' : 'Torang Go Driver';

  static String get tagline => role == AppRole.customer
      ? 'Jalan santai torang sama-sama'
      : 'Kerja keras, untung bareng';

  /// Pusat Jailolo (fallback GPS simulasi).
  static const jailoloLat = -0.676;
  static const jailoloLng = 127.529;
}
