# 📱 Torang Go Mobile — Customer & Driver

Aplikasi Flutter **Torang Go** (ojek online Halmahera Barat) — satu codebase, dua aplikasi dengan flavor berbeda. Desain mengikuti dan memodernisasi `torang_go_dashboard.html` (palet ocean–leaf–sand–coral, font Manrope + Inter, kartu gradient, bottom nav floating).

## 🚀 Menjalankan

Pastikan backend jalan dulu:

```bash
cd torang-go/backend
php artisan serve --port=8000
```

### Customer

```bash
cd torang-go/mobile
flutter run --flavor customer -t lib/main_customer.dart
```

### Driver

```bash
flutter run --flavor driver -t lib/main_driver.dart
```

### Ganti alamat server (device fisik / deploy)

```bash
flutter run --flavor customer -t lib/main_customer.dart \
  --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
```

Default: emulator Android → `http://10.0.2.2:8000/api/v1`, iOS simulator / macOS → `http://127.0.0.1:8000/api/v1`.

## 🔑 Akun demo (seed backend)

| Peran    | Login       | Password    |
| -------- | ----------- | ----------- |
| Customer | 081200000001| customer123 |
| Driver Bentor | 081200000002 | driver123 |
| Driver Ojek   | 081200000003 | driver123 |

Tombol **“isi otomatis”** di halaman login app sudah tersedia.

## 📲 Fitur Customer

- Splash animasi + onboarding 3 halaman
- Login / daftar (API `auth/login`, `auth/register`)
- Beranda: greeting, kartu TorangPay gradient, grid 8 layanan, promo carousel, kartu order aktif
- **Torang Ride & Torang Kirim**: pilih lokasi dari `/places` (bottom sheet + pencarian), estimasi tarif real (`orders/estimate`), buat order (`orders`)
- **Tracking order** (polling 5 detik): hero status gradient, peta stilisasi + rute, kartu driver, timeline perjalanan, batalkan (dengan alasan), rating bintang setelah selesai
- Riwayat pesanan (Aktif / Selesai / Dibatalkan)
- Notifikasi (tandai terbaca otomatis)
- Profil + logout

## 🛵 Fitur Driver

- Login driver (dengan chip akun demo)
- Beranda: toggle **Online/Offline** (`duty-status`), pendapatan & order hari ini, rating
- **Order masuk** (polling `/driver/orders?filter=available`): kartu order + jarak dari posisi + estimasi earning, tombol Terima/Lewati
- **Alur perjalanan**: Tiba di jemput → Mulai perjalanan → Selesai (`arrived`/`start`/`complete`)
- Update posisi GPS tiap 5 detik saat online (`driver/location`) — *MVP: simulasi di pusat Jailolo, produksi tinggal ganti dengan `geolocator`*
- Riwayat order
- **Dompet**: saldo, total masuk, komisi, riwayat transaksi, ajukan penarikan (`wallet/withdraw`)
- Profil mitra: status verifikasi, kendaraan, plat, performa

## 🗂 Struktur

```
lib/
├── main_customer.dart      # entrypoint app Customer
├── main_driver.dart        # entrypoint app Driver
├── core/                   # theme (design system), api_client, session, config, format
├── models/                 # model JSON backend (Order, DriverInfo, dst.)
├── shared/widgets.dart     # TGNavBar, StylizedMap (peta custom painter), dll.
└── features/
    ├── splash / onboarding / auth
    ├── customer/           # home, booking, tracking, orders, notif, profile
    └── driver/             # home(duty+order), orders, wallet, profile
```

## 🧱 Android flavors

| Flavor    | Application ID          | Nama app          |
| --------- | ----------------------- | ----------------- |
| customer  | id.toranggo.torang_go.customer | Torang Go |
| driver    | id.toranggo.torang_go.driver   | Torang Go Driver |

## 🎨 Ikon launcher

- **Customer**: logo Torang Go dari `favicon.png` (root project) di atas gradient ocean `#1477E6 → #1D8FE0`.
- **Driver**: logo yang sama + badge **helm** pojok + ribbon **"DRIVER"** di bawah, di atas gradient leaf `#2FAE4E → #4FC3F7` — jadi jelas beda dua aplikasi di home screen.
- Regenerasi (misal logo ganti): edit `favicon.png` lalu jalankan `python3 gen_icons.py` → rebuild. Preview bisa dilihat di `preview-icons/preview.png`.
- Ikon adaptive (Android 8+) + legacy (semua versi) tersedia di `android/app/src/<flavor>/res/`.

Build APK:

```bash
flutter build apk --release --flavor customer -t lib/main_customer.dart
flutter build apk --release --flavor driver   -t lib/main_driver.dart
```

> Catatan Mac ini: Gradle memakai JDK 21 (`org.gradle.java.home` di `android/gradle.properties`) karena JDK default sistem (25) belum didukung Gradle 8.14.

## ✅ Uji end-to-end (sudah diverifikasi ke backend lokal)

login → places → estimate → create order → driver online → lihat order tersedia → accept → arrived → start → complete → rating → wallet — **semua 200 OK**.
# Torang-Go-Mobile
