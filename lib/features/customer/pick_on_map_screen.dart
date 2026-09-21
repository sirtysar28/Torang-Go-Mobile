import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

/// Hasil pilihan lokasi dari peta.
class MapPick {
  final double lat, lng;
  final String name;
  final String? address;
  const MapPick(this.lat, this.lng, this.name, this.address);
}

/// Peta interaktis (OpenStreetMap — tanpa API key):
/// - geser peta, pin tetap di tengah
/// - cari nama tempat (Nominatim)
/// - pakai posisi GPS saya
/// - tombol "Pakai Lokasi Ini" → kembali ke halaman pesan.
class PickOnMapScreen extends StatefulWidget {
  final String title;
  final LatLng? initial;

  const PickOnMapScreen({super.key, required this.title, this.initial});

  @override
  State<PickOnMapScreen> createState() => _PickOnMapScreenState();
}

class _PickOnMapScreenState extends State<PickOnMapScreen> {
  late final MapController _map = MapController();
  late LatLng _center;

  bool _locating = false;
  bool _naming = false;
  String? _pickedName;
  String? _pickedAddress;
  bool _searching = false;
  final _search = TextEditingController();
  List<_SearchHit> _hits = [];

  @override
  void initState() {
    super.initState();
    _center =
        widget.initial ??
        const LatLng(AppConfig.jailoloLat, AppConfig.jailoloLng);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Ambil nama jalan/tempat dari koordinat (reverse geocode Nominatim).
  Future<void> _resolveName(LatLng p) async {
    setState(() {
      _naming = true;
      _pickedName = null;
      _pickedAddress = null;
    });
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${p.latitude}&lon=${p.longitude}&zoom=17&addressdetails=1&accept-language=id',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'TorangGo/1.0 (mobile app)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final a = j['address'] as Map<String, dynamic>? ?? {};
        String road =
            a['road']?.toString() ??
            a['pedestrian']?.toString() ??
            a['neighbourhood']?.toString() ??
            a['village']?.toString() ??
            a['suburb']?.toString() ??
            '';
        final city =
            a['town']?.toString() ??
            a['city']?.toString() ??
            a['county']?.toString() ??
            a['state']?.toString() ??
            '';
        final display = j['name']?.toString() ?? '';
        final name = display.isNotEmpty
            ? display
            : (road.isNotEmpty ? road : 'Titik peta');
        if (mounted) {
          setState(() {
            _pickedName = name;
            _pickedAddress = [
              if (road.isNotEmpty) road,
              if (city.isNotEmpty) city,
            ].join(', ');
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _pickedName = null;
        _pickedAddress = null;
      });
    }
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          tgSnackbar(
            context,
            'Izin lokasi ditolak. Aktifkan GPS di pengaturan HP ya.',
            error: true,
          );
        }
      } else {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 15));
        final me = LatLng(pos.latitude, pos.longitude);
        _map.move(me, 16.5);
        setState(() => _center = me);
        await _resolveName(me);
      }
    } catch (_) {
      if (mounted) {
        tgSnackbar(
          context,
          'Tidak bisa ambil posisi GPS. Coba lagi.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _doSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _hits = [];
    });
    try {
      // Batasi ke sekitar Halmahera agar hasil relevan
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&limit=8&accept-language=id'
        '&viewbox=126.8,-0.2,128.2,-2.0&bounded=0&q=${Uri.encodeComponent(query)}',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'TorangGo/1.0 (mobile app)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (mounted) {
          setState(
            () => _hits = list
                .map(
                  (e) => _SearchHit(
                    LatLng(
                      (e['lat'] as num).toDouble(),
                      (e['lon'] as num).toDouble(),
                    ),
                    e['name']?.toString() ?? query,
                    e['display_name']?.toString(),
                  ),
                )
                .toList(),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        tgSnackbar(
          context,
          'Pencarian lokasi gagal. Cek internet kamu.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _confirm() {
    final name = _pickedName ?? 'Titik peta';
    Navigator.of(
      context,
    ).pop(MapPick(_center.latitude, _center.longitude, name, _pickedAddress));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Pakai GPS saya',
            onPressed: _locating ? null : _useGps,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- Pencarian tempat ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _search,
              onSubmitted: _doSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: TG.inkSoft),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          size: 19,
                          color: TG.ocean,
                        ),
                        onPressed: () => _doSearch(_search.text),
                      ),
                hintText: 'Cari tempat (contoh: Pasar Jailolo)…',
              ),
            ),
          ),
          if (_hits.isNotEmpty)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                itemCount: _hits.length,
                itemBuilder: (_, i) {
                  final h = _hits[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.location_on_rounded,
                      color: TG.ocean,
                      size: 20,
                    ),
                    title: Text(
                      h.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: h.address == null
                        ? null
                        : Text(
                            h.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TG.bodySm(context, color: TG.inkSoft),
                          ),
                    onTap: () {
                      _map.move(h.point, 16.5);
                      setState(() {
                        _center = h.point;
                        _pickedName = h.name;
                        _pickedAddress = h.address;
                        _hits = [];
                      });
                      _search.clear();
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
          // ---- Peta ----
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 15.5,
                    minZoom: 5,
                    maxZoom: 18.5,
                    onPositionChanged: (pos, _) {
                      setState(() => _center = pos.center);
                    },
                    onTap: (_, _) =>
                        FocusScope.of(context).unfocus(), // tutup keyboard
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'id.toranggo.torang_go',
                    ),
                  ],
                ),
                // Pin tetap di tengah — peta yang bergerak
                const Center(child: IgnorePointer(child: _CenterPin())),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: TG.sand,
            border: Border(top: BorderSide(color: TG.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _naming
                        ? Row(
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                  color: TG.inkSoft,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mendeteksi nama tempat…',
                                style: TG.bodySm(context, color: TG.inkSoft),
                              ),
                            ],
                          )
                        : Text(
                            _pickedName ?? 'Geser peta ke lokasi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TG.titleSm(context),
                          ),
                    if (_pickedAddress != null && _pickedAddress!.isNotEmpty)
                      Text(
                        _pickedAddress!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TG.bodySm(context, color: TG.inkSoft),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              PrimaryButton(
                label: 'Pakai Lokasi Ini',
                icon: Icons.check_rounded,
                expand: false,
                onTap: _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: TG.ocean.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
            const Icon(Icons.place_rounded, color: TG.ocean, size: 34),
          ],
        ),
      ],
    );
  }
}

class _SearchHit {
  final LatLng point;
  final String name;
  final String? address;
  _SearchHit(this.point, this.name, this.address);
}
