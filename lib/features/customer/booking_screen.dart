import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';
import 'order_tracking_screen.dart';
import 'pick_on_map_screen.dart';

/// Layanan yang bisa dipesan lewat halaman ini.
const kRideGroup = ['ride', 'bentor', 'car'];

class BookingScreen extends StatefulWidget {
  final String serviceType; // ride | bentor | car | send | food | mart
  const BookingScreen({super.key, required this.serviceType});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late String _service = widget.serviceType;

  List<Place> _places = [];
  List<Merchant> _merchants = [];
  bool _loading = true;
  String _query = '';

  Place? _pickup;
  Place? _destination;
  Merchant? _merchant;
  String _payment = 'cash';
  final _notes = TextEditingController();
  final _items = TextEditingController();
  final _senderName = TextEditingController();
  final _senderPhone = TextEditingController();
  final _receiverName = TextEditingController();
  final _receiverPhone = TextEditingController();
  final _itemType = TextEditingController();

  FareEstimate? _estimate;
  bool _estimating = false;
  bool _ordering = false;

  bool get _isSend => _service == 'send';
  bool get _isFood => _service == 'food';
  bool get _isMart => _service == 'mart';
  bool get _isRideGroup => kRideGroup.contains(_service);
  bool get _hasMerchant => _isFood || _isMart;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    _items.dispose();
    _senderName.dispose();
    _senderPhone.dispose();
    _receiverName.dispose();
    _receiverPhone.dispose();
    _itemType.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final futures = [ApiClient.I.get('/places')];
      if (_hasMerchant) {
        futures.add(
          ApiClient.I.get(
            '/merchants',
            query: {'type': _isFood ? 'restaurant' : 'store'},
          ),
        );
      }
      final res = await Future.wait(futures);
      final p = res[0];
      if (!mounted) return;
      setState(() {
        _places = ((p['locations'] as List?) ?? [])
            .map((e) => Place.fromJson(e))
            .toList();
        if (res.length > 1) {
          _merchants = ((res[1]['merchants'] as List?) ?? [])
              .map((e) => Merchant.fromJson(e))
              .toList();
        }
        // Default titik jemput: alamat tersimpan / lokasi pertama
        _pickup ??= _places.isEmpty ? null : _places.first;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        tgSnackbar(context, e.toString(), error: true);
      }
    }
  }

  List<Place> get _filtered => _query.trim().isEmpty
      ? _places
      : _places
            .where(
              (p) =>
                  p.name.toLowerCase().contains(_query.toLowerCase()) ||
                  p.address.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

  List<Merchant> get _filteredMerchants => _query.trim().isEmpty
      ? _merchants
      : _merchants
            .where(
              (m) =>
                  m.name.toLowerCase().contains(_query.toLowerCase()) ||
                  (m.category ?? '').toLowerCase().contains(
                    _query.toLowerCase(),
                  ),
            )
            .toList();

  // ============================================================
  // Pemilihan lokasi: peta interaktif ATAU daftar lokasi tersimpan
  // ============================================================
  Future<Place?> _pickPlace(String title, Place? selected) {
    return showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TG.sand,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetGrabber(title),
              // ---- Pilih lewat peta ----
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
                child: GestureDetector(
                  onTap: () async {
                    final NavigatorState nav = Navigator.of(context);
                    final pick = await nav.push<MapPick>(
                      MaterialPageRoute(
                        builder: (_) => PickOnMapScreen(
                          title: title,
                          initial: selected != null
                              ? LatLng(selected.lat, selected.lng)
                              : null,
                        ),
                      ),
                    );
                    if (pick != null) {
                      // tutup sheet dulu, lalu kirim hasil
                      nav.pop(
                        Place(
                          -1,
                          null,
                          pick.name,
                          pick.address ?? '',
                          pick.lat,
                          pick.lng,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: TG.brandGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.map_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pilih lewat Peta (GPS / geser pin)',
                            style: TG.titleSm(context, color: Colors.white),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                child: TextField(
                  onChanged: (v) => setSheet(() => _query = v),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: TG.inkSoft,
                    ),
                    hintText: 'Atau cari lokasi tersimpan…',
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  children: [
                    for (final p in _filtered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _placeTile(
                          p,
                          selected: selected?.id == p.id,
                          onTap: () => Navigator.of(context).pop(p),
                        ),
                      ),
                    if (_filtered.isEmpty)
                      const EmptyState(
                        icon: Icons.location_off_rounded,
                        title: 'Lokasi tidak ketemu',
                        subtitle: 'Coba kata kunci lain atau pilih lewat peta.',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Merchant?> _pickMerchant(String title, Merchant? selected) {
    return showModalBottomSheet<Merchant>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TG.sand,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetGrabber(title),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                child: TextField(
                  onChanged: (v) => setSheet(() => _query = v),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: TG.inkSoft,
                    ),
                    hintText: _isFood
                        ? 'Cari rumah makan / warung…'
                        : 'Cari toko / minimarket / sembako…',
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  children: [
                    for (final m in _filteredMerchants)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _merchantTile(
                          m,
                          selected: selected?.id == m.id,
                          onTap: () => Navigator.of(context).pop(m),
                        ),
                      ),
                    if (_filteredMerchants.isEmpty)
                      EmptyState(
                        icon: Icons.storefront_rounded,
                        title: 'Mitra belum tersedia',
                        subtitle: _isFood
                            ? 'Rumah makan mitra akan segera bertambah.'
                            : 'Toko mitra akan segera bertambah.',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeTile(Place p, {bool selected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? TG.oceanSoft : TG.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? TG.ocean : TG.line),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? TG.ocean : TG.navySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected ? Icons.check_rounded : Icons.location_on_rounded,
                color: selected ? Colors.white : TG.oceanDeep,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: TG.titleSm(context)),
                  if (p.address.isNotEmpty)
                    Text(
                      p.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TG.bodySm(context, color: TG.inkSoft),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _merchantTile(
    Merchant m, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? TG.oceanSoft : TG.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? TG.ocean : TG.line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? TG.ocean : TG.coralSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _isFood ? '🍜' : '🛒',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: TG.titleSm(context)),
                  Row(
                    children: [
                      if (m.category != null && m.category!.isNotEmpty) ...[
                        Text(
                          m.category!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TG.bodySm(context, color: TG.inkSoft),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '★ ${m.rating.toStringAsFixed(1)}',
                        style: TG.bodySm(
                          context,
                          color: TG.leafDeep,
                          w: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Estimasi & order
  // ============================================================
  double get _pickupLat =>
      _hasMerchant ? (_merchant?.lat ?? 0) : (_pickup?.lat ?? 0);
  double get _pickupLng =>
      _hasMerchant ? (_merchant?.lng ?? 0) : (_pickup?.lng ?? 0);

  Future<void> _estimateFare() async {
    FocusScope.of(context).unfocus();
    if (_hasMerchant) {
      if (_merchant == null) {
        tgSnackbar(
          context,
          _isFood
              ? 'Pilih dulu rumah makan/warung-nya ya.'
              : 'Pilih dulu toko tempat belanja ya.',
          error: true,
        );
        return;
      }
    } else if (_pickup == null) {
      tgSnackbar(
        context,
        'Pilih titik jemput dulu ya (bisa lewat peta).',
        error: true,
      );
      return;
    }
    if (_destination == null) {
      tgSnackbar(
        context,
        'Pilih tujuan dulu ya (bisa lewat peta).',
        error: true,
      );
      return;
    }
    if (_pickupLat == _destination!.lat &&
        _pickupLng == _destination!.lng &&
        !_hasMerchant) {
      tgSnackbar(context, 'Titik jemput dan tujuan sama 😅', error: true);
      return;
    }
    if (_hasMerchant && _items.text.trim().isEmpty) {
      tgSnackbar(
        context,
        _isFood
            ? 'Tulis dulu pesanan makanan kamu.'
            : 'Tulis dulu daftar belanjaan kamu.',
        error: true,
      );
      return;
    }
    setState(() => _estimating = true);
    try {
      final res = await ApiClient.I.post(
        '/orders/estimate',
        body: {
          'pickup_latitude': _pickupLat,
          'pickup_longitude': _pickupLng,
          'destination_latitude': _destination!.lat,
          'destination_longitude': _destination!.lng,
          'service_type': _service,
        },
      );
      setState(() => _estimate = FareEstimate.fromJson(res));
    } catch (e) {
      if (mounted) tgSnackbar(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _estimating = false);
    }
  }

  Future<void> _createOrder() async {
    FocusScope.of(context).unfocus();
    if (_estimate == null) {
      await _estimateFare();
      return;
    }
    if (_isSend &&
        (_senderName.text.isEmpty ||
            _senderPhone.text.isEmpty ||
            _receiverName.text.isEmpty ||
            _receiverPhone.text.isEmpty)) {
      tgSnackbar(
        context,
        'Lengkapi data pengirim & penerima paket.',
        error: true,
      );
      return;
    }
    if (_hasMerchant && _merchant == null) {
      tgSnackbar(context, 'Pilih mitra dulu ya.', error: true);
      return;
    }
    setState(() => _ordering = true);
    try {
      final res = await ApiClient.I.post(
        '/orders',
        body: {
          'service_type': _service,
          if (!_hasMerchant) ...{
            'pickup_name': _pickup!.name,
            'pickup_latitude': _pickup!.lat,
            'pickup_longitude': _pickup!.lng,
            'pickup_address': _pickup!.address,
          },
          'destination_name': _destination!.name,
          'destination_latitude': _destination!.lat,
          'destination_longitude': _destination!.lng,
          'destination_address': _destination!.address,
          'payment_method': _payment,
          if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
          if (_isSend) ...{
            'sender_name': _senderName.text.trim(),
            'sender_phone': _senderPhone.text.trim(),
            'receiver_name': _receiverName.text.trim(),
            'receiver_phone': _receiverPhone.text.trim(),
            'item_type': _itemType.text.trim().isEmpty
                ? 'Paket'
                : _itemType.text.trim(),
          },
          if (_hasMerchant) ...{
            'merchant_id': _merchant!.id,
            'items_summary': _items.text.trim(),
          },
        },
      );
      if (!mounted) return;
      final order = Order.fromJson(res['order']);
      tgSnackbar(context, res['message']?.toString() ?? 'Order dibuat!');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: order.id),
        ),
      );
    } catch (e) {
      if (mounted) tgSnackbar(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  void _switchService(String s) {
    setState(() {
      _service = s;
      _estimate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(serviceTitleId(_service))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: TG.leaf))
          : ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
              children: [
                if (_isRideGroup) ...[
                  _serviceChips(),
                  const SizedBox(height: 14),
                ],
                _mapPreview(),
                const SizedBox(height: 16),
                if (_hasMerchant) ...[
                  _merchantPicker(),
                  const SizedBox(height: 10),
                ],
                if (!_hasMerchant)
                  _pointPicker(
                    icon: Icons.trip_origin_rounded,
                    color: TG.ocean,
                    title: 'Titik jemput / asal',
                    place: _pickup,
                    onTap: () async {
                      final p = await _pickPlace('Pilih titik jemput', _pickup);
                      if (p != null) {
                        setState(() {
                          _pickup = p;
                          _estimate = null;
                        });
                      }
                    },
                  ),
                if (!_hasMerchant)
                  Padding(
                    padding: const EdgeInsets.only(left: 17),
                    child: Container(width: 2, height: 14, color: TG.line),
                  ),
                _pointPicker(
                  icon: Icons.place_rounded,
                  color: const Color(0xFFB3261E),
                  title: _hasMerchant
                      ? (_isFood
                            ? 'Antar ke mana?'
                            : 'Belanjaan diantar ke mana?')
                      : 'Tujuan',
                  place: _destination,
                  onTap: () async {
                    final p = await _pickPlace('Pilih tujuan', _destination);
                    if (p != null) {
                      setState(() {
                        _destination = p;
                        _estimate = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (_hasMerchant) _itemsCard(),
                if (_isSend) ..._sendFields(),
                TextField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.sticky_note_2_outlined,
                      color: TG.inkSoft,
                    ),
                    labelText: 'Catatan untuk driver (opsional)',
                    hintText: _isMart
                        ? 'Contoh: bayar pakai uang pas, tolong ccek tanggal'
                        : 'Contoh: dekat masjid, warna baju merah',
                  ),
                ),
                const SizedBox(height: 16),
                _paymentSelector(),
                const SizedBox(height: 18),
                _fareCard(),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: _estimate == null
                      ? 'Hitung Tarif Dulu'
                      : (_ordering
                            ? 'Mengirim pesanan...'
                            : 'Pesan Sekarang ⚡'),
                  icon: _estimate == null
                      ? Icons.calculate_rounded
                      : Icons.bolt_rounded,
                  loading: _ordering || _estimating,
                  onTap: _createOrder,
                ),
              ],
            ),
    );
  }

  // ---- Chip ganti layanan (Ride / Bentor / Car) ----
  Widget _serviceChips() {
    return Row(
      children: [
        for (final s in kRideGroup)
          Expanded(
            child: GestureDetector(
              onTap: () => _switchService(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: EdgeInsets.only(right: s == 'car' ? 0 : 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  color: _service == s ? TG.ocean : TG.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _service == s ? TG.ocean : TG.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      serviceVisualOf(s).emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Torang ${serviceVisualOf(s).label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TG.label(
                          context,
                          color: _service == s ? Colors.white : TG.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---- Peta preview asli (OpenStreetMap, non-interaktif) ----
  Widget _mapPreview() {
    final pts = <LatLng>[
      if (_hasMerchant && _merchant?.lat != null)
        LatLng(_merchant!.lat!, _merchant!.lng!),
      if (!_hasMerchant && _pickup != null) LatLng(_pickup!.lat, _pickup!.lng),
      if (_destination != null) LatLng(_destination!.lat, _destination!.lng),
    ];
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TG.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: pts.isEmpty
            ? const StylizedMap(height: 180)
            : AbsorbPointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.coordinates(
                      coordinates: pts,
                      padding: const EdgeInsets.all(38),
                    ),
                    interactionOptions: const InteractionOptions(flags: 0),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'id.toranggo.torang_go',
                    ),
                    if (pts.length == 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: pts,
                            strokeWidth: 4,
                            color: TG.ocean,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        for (var i = 0; i < pts.length; i++)
                          Marker(
                            point: pts[i],
                            width: 36,
                            height: 36,
                            child: Icon(
                              i == 0
                                  ? Icons.trip_origin_rounded
                                  : Icons.place_rounded,
                              size: 30,
                              color: i == 0
                                  ? TG.ocean
                                  : const Color(0xFFB3261E),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _pointPicker({
    required IconData icon,
    required Color color,
    required String title,
    required Place? place,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: TG.card(radius: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TG.bodySm(context, color: TG.inkSoft)),
                  const SizedBox(height: 2),
                  Text(
                    place?.name ?? 'Tap: peta atau daftar lokasi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TG.titleSm(
                      context,
                      color: place == null ? TG.inkSoft : TG.ink,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.unfold_more_rounded, color: TG.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _merchantPicker() {
    return GestureDetector(
      onTap: () async {
        final m = await _pickMerchant(
          _isFood ? 'Pilih rumah makan / warung' : 'Pilih toko belanja',
          _merchant,
        );
        if (m != null) {
          setState(() {
            _merchant = m;
            _estimate = null;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: TG.card(radius: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isFood ? TG.coralSoft : TG.oceanSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  _isFood ? '🍜' : '🛒',
                  style: const TextStyle(fontSize: 19),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isFood ? 'Makan dari mana?' : 'Belanja di toko mana?',
                    style: TG.bodySm(context, color: TG.inkSoft),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _merchant?.name ??
                        (_isFood
                            ? 'Tap untuk pilih warung / rumah makan'
                            : 'Tap untuk pilih Alfamart / Indomaret / sembako'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TG.titleSm(
                      context,
                      color: _merchant == null ? TG.inkSoft : TG.ink,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.unfold_more_rounded, color: TG.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _itemsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TG.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isFood ? 'Pesanan makanan kamu 🍜' : 'Daftar belanjaan kamu 🛒',
            style: TG.titleSm(context),
          ),
          const SizedBox(height: 4),
          Text(
            _isFood
                ? 'Tulis menu + jumlah, driver yang belanjakan & antar.'
                : 'Tulis barang + jumlah. Driver beli di toko pilihanmu, uang barang dibayar tunai ke driver sesuai struk.',
            style: TG.bodySm(context, color: TG.inkSoft),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _items,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) => setState(() => _estimate = null),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.receipt_long_rounded,
                color: TG.inkSoft,
                size: 19,
              ),
              hintText: _isFood
                  ? 'Contoh:\n- Nasi ikan bakar 1\n- Es teh 2\n- Bakso 1'
                  : 'Contoh:\n- Beras 5kg 1\n- Minyak goreng 1L 2\n- Telur 1kg',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sendFields() {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: TG.card(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data paket 📦', style: TG.titleSm(context)),
            const SizedBox(height: 12),
            _miniField(
              _senderName,
              'Nama pengirim',
              Icons.person_outline_rounded,
            ),
            const SizedBox(height: 10),
            _miniField(
              _senderPhone,
              'HP pengirim',
              Icons.phone_android_rounded,
            ),
            const SizedBox(height: 10),
            _miniField(
              _receiverName,
              'Nama penerima',
              Icons.person_outline_rounded,
            ),
            const SizedBox(height: 10),
            _miniField(
              _receiverPhone,
              'HP penerima',
              Icons.phone_android_rounded,
            ),
            const SizedBox(height: 10),
            _miniField(
              _itemType,
              'Isi paket (contoh: dokumen)',
              Icons.inventory_2_rounded,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _miniField(TextEditingController c, String hint, IconData icon) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: TG.inkSoft, size: 19),
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _paymentSelector() {
    return Row(
      children: [
        for (final (id, label, icon) in const [
          ('cash', 'Tunai', Icons.payments_rounded),
          ('qris', 'QRIS', Icons.qr_code_rounded),
        ])
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _payment = id),
              child: Container(
                margin: EdgeInsets.only(right: id == 'cash' ? 10 : 0),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _payment == id ? TG.ocean : TG.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _payment == id ? TG.ocean : TG.line,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: _payment == id ? Colors.white : TG.inkSoft,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TG.label(
                        context,
                        color: _payment == id ? Colors.white : TG.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fareCard() {
    final e = _estimate;
    if (e == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: TG.card(radius: 18),
        child: Row(
          children: [
            const Icon(Icons.calculate_outlined, color: TG.inkSoft, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _hasMerchant
                    ? 'Pilih mitra & tujuan, tulis pesanan, lalu hitung tarif.'
                    : 'Pilih titik jemput & tujuan (bisa lewat peta), lalu hitung tarif.',
                style: TG.body(context, color: TG.inkSoft),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TG.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TG.leaf.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${serviceVisualOf(_service).emoji} ${serviceTitleId(_service).replaceAll(RegExp(r' [^ ]*$'), '')} — estimasi',
                style: TG.body(context, color: TG.inkSoft),
              ),
              StatusChip(
                'searching_driver',
                label: '${e.driversNearby} driver sekitar',
              ),
            ],
          ),
          const Divider(height: 20, color: TG.line),
          _fareRow(
            'Tarif dasar${e.zoneName != null ? ' (${e.zoneName})' : ''}',
            rp(e.baseFare),
          ),
          _fareRow(
            'Jarak ${km(e.distanceKm)} • ±${e.durationMinutes} mnt',
            rp(e.distanceFare),
          ),
          if ((e.extraFee ?? 0) > 0)
            _fareRow(
              _isMart ? 'Biaya jastip belanja' : 'Biaya antar',
              rp(e.extraFee),
            ),
          if (e.serviceFee != null && e.serviceFee! > 0)
            _fareRow('Biaya layanan', rp(e.serviceFee)),
          const Divider(height: 20, color: TG.line),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total bayar', style: TG.titleSm(context)),
              Text(
                rp(e.totalFare),
                style: TG
                    .title(context, color: TG.leafDeep)
                    .copyWith(fontSize: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TG.body(context, color: TG.inkSoft),
            ),
          ),
          Text(value, style: TG.body(context, w: FontWeight.w600)),
        ],
      ),
    );
  }
}
