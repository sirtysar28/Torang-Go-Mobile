import '../core/theme.dart';

/// Model seluruh API Torang Go (bentuk JSON mengikuti Controller.php backend).

/// Parser angka toleran — beberapa server/hosting (cPanel dll.) mengirim
/// angka dari database sebagai STRING ("12", bukan 12). Dulu bikin crash
/// "type 'String' is not a subtype of type 'int/num' in type cast" yang
/// muncul sebagai teks error di app. Semua parser di bawah jadi kebal itu.
int _asInt(dynamic v) =>
    v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
int? _asIntOrNull(dynamic v) =>
    v is num ? v.toInt() : int.tryParse(v?.toString() ?? '');
double _asDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
double? _asDoubleOrNull(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');

class User {
  final int id;
  final String name, phone;
  final String? email;
  final String? address;
  final String role;
  final bool isActive;
  final DriverInfo? driver;

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    required this.role,
    required this.isActive,
    this.driver,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: _asInt(j['id']),
    name: (j['name'] ?? '').toString(),
    phone: (j['phone'] ?? '').toString(),
    email: j['email']?.toString(),
    address: j['address']?.toString(),
    role: (j['role'] ?? 'customer').toString(),
    isActive: j['is_active'] == true || j['is_active'] == 1,
    driver: j['driver'] is Map ? DriverInfo.fromJson(j['driver']) : null,
  );
}

class DriverInfo {
  final int id;
  final String? code, name, phone, avatar;
  final String? status, dutyStatus;
  final String? vehicleType, vehicleLabel, plateNumber, vehicleColor;
  final double rating;
  final int totalOrders;
  final double? latitude, longitude;

  DriverInfo({
    required this.id,
    this.code,
    this.name,
    this.phone,
    this.avatar,
    this.status,
    this.dutyStatus,
    this.vehicleType,
    this.vehicleLabel,
    this.plateNumber,
    this.vehicleColor,
    this.rating = 5,
    this.totalOrders = 0,
    this.latitude,
    this.longitude,
  });

  bool get isVerified => status == 'verified';
  bool get isOnline => dutyStatus == 'online';

  factory DriverInfo.fromJson(Map<String, dynamic> j) {
    final v = j['vehicle'];
    return DriverInfo(
      id: _asInt(j['id']),
      code: j['code']?.toString(),
      name: j['name']?.toString(),
      phone: j['phone']?.toString(),
      avatar: j['avatar']?.toString(),
      status: j['status']?.toString(),
      dutyStatus: j['duty_status']?.toString(),
      vehicleType: v is Map ? v['type']?.toString() : null,
      vehicleLabel: v is Map ? v['label']?.toString() : null,
      plateNumber: v is Map ? v['plate_number']?.toString() : null,
      vehicleColor: v is Map ? v['color']?.toString() : null,
      rating: _asDoubleOrNull(j['rating']) ?? 5.0,
      totalOrders: _asIntOrNull(j['total_orders']) ?? 0,
      latitude: _asDoubleOrNull(j['latitude']),
      longitude: _asDoubleOrNull(j['longitude']),
    );
  }
}

class OrderPoint {
  final String name;
  final double latitude, longitude;
  final String? address;
  OrderPoint(this.name, this.latitude, this.longitude, this.address);

  factory OrderPoint.fromJson(Map<String, dynamic> j) => OrderPoint(
    (j['name'] ?? '-').toString(),
    _asDouble(j['latitude']),
    _asDouble(j['longitude']),
    j['address']?.toString(),
  );
}

class OrderHistory {
  final String status, note;
  final String? at;
  OrderHistory(this.status, this.note, this.at);
}

class Order {
  final int id;
  final String code, serviceType, status;
  final String? statusLabel;
  final String? serviceLabel;
  final OrderPoint pickup, destination;
  final String? senderName, senderPhone, receiverName, receiverPhone, itemType;
  final String? itemsSummary;
  final MerchantInfo? merchant;
  final String? notes;
  final double distanceKm;
  final int durationMinutes;
  final double baseFare, distanceFare, totalFare;
  final double? serviceFee;
  final double commissionAmount, driverEarning;
  final String paymentMethod, paymentStatus;
  final String? cancelReason, createdAt, completedAt;
  final Map<String, dynamic>? customer;
  final DriverInfo? driver;
  final List<OrderHistory>? histories;
  final bool? rated;
  final double? driverDistanceKm; // khusus daftar "available" driver

  Order({
    required this.id,
    required this.code,
    required this.serviceType,
    required this.status,
    this.statusLabel,
    this.serviceLabel,
    required this.pickup,
    required this.destination,
    this.senderName,
    this.senderPhone,
    this.receiverName,
    this.receiverPhone,
    this.itemType,
    this.itemsSummary,
    this.merchant,
    this.notes,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.baseFare = 0,
    this.distanceFare = 0,
    this.totalFare = 0,
    this.serviceFee,
    this.commissionAmount = 0,
    this.driverEarning = 0,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    this.cancelReason,
    this.createdAt,
    this.completedAt,
    this.customer,
    this.driver,
    this.histories,
    this.rated,
    this.driverDistanceKm,
  });

  bool get isActive => kActiveStatuses.contains(status);
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isRide => serviceType == 'ride';
  bool get isSend => serviceType == 'send';
  bool get isFood => serviceType == 'food';
  bool get isMart => serviceType == 'mart';
  String get label => statusLabel ?? statusLabelId(status);
  String get serviceChip => serviceLabelId(serviceType);
  String get serviceTitle => serviceTitleId(serviceType);

  /// Nama customer pemesan (dari relasi user di API).
  /// Untuk layanan Kirim, fallback ke nama pengirim yang diisi customer.
  String? get customerName {
    final n = customer?['name']?.toString().trim();
    if (n != null && n.isNotEmpty) return n;
    if (isSend) {
      final s = senderName?.trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

  /// No. HP customer pemesan (bisa langsung ditelepon / di-WA driver).
  String? get customerPhone {
    final p = customer?['phone']?.toString().trim();
    if (p != null && p.isNotEmpty) return p;
    if (isSend) {
      final s = senderPhone?.trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

  static const kActiveStatuses = [
    'pending',
    'searching_driver',
    'driver_assigned',
    'driver_on_the_way',
    'driver_arrived',
    'trip_started',
  ];

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: _asInt(j['id']),
    code: (j['code'] ?? '-').toString(),
    serviceType: (j['service_type'] ?? 'ride').toString(),
    status: (j['status'] ?? '-').toString(),
    statusLabel: j['status_label']?.toString(),
    serviceLabel: j['service_label']?.toString(),
    pickup: OrderPoint.fromJson(j['pickup'] ?? {}),
    destination: OrderPoint.fromJson(j['destination'] ?? {}),
    senderName: j['sender_name']?.toString(),
    senderPhone: j['sender_phone']?.toString(),
    receiverName: j['receiver_name']?.toString(),
    receiverPhone: j['receiver_phone']?.toString(),
    itemType: j['item_type']?.toString(),
    itemsSummary: j['items_summary']?.toString(),
    merchant: j['merchant'] is Map
        ? MerchantInfo.fromJson(j['merchant'])
        : null,
    notes: j['notes']?.toString(),
    distanceKm: _asDouble(j['distance_km']),
    durationMinutes: _asInt(j['duration_minutes']),
    baseFare: _asDouble(j['base_fare']),
    distanceFare: _asDouble(j['distance_fare']),
    totalFare: _asDouble(j['total_fare']),
    serviceFee: _asDoubleOrNull(j['service_fee']),
    commissionAmount: _asDouble(j['commission_amount']),
    driverEarning: _asDouble(j['driver_earning']),
    paymentMethod: (j['payment_method'] ?? 'cash').toString(),
    paymentStatus: (j['payment_status'] ?? 'pending').toString(),
    cancelReason: j['cancel_reason']?.toString(),
    createdAt: j['created_at']?.toString(),
    completedAt: j['completed_at']?.toString(),
    customer: j['customer'] is Map
        ? Map<String, dynamic>.from(j['customer'] as Map)
        : null,
    driver: j['driver'] is Map ? DriverInfo.fromJson(j['driver']) : null,
    histories: (j['histories'] as List?)
        ?.map(
          (h) => OrderHistory(
            (h['status'] ?? '').toString(),
            (h['note'] ?? '').toString(),
            h['at']?.toString(),
          ),
        )
        .toList(),
    rated: j['rated'] is bool
        ? j['rated'] as bool
        : (j['rated'] == 1 || j['rated'] == '1'),
    driverDistanceKm: _asDoubleOrNull(j['driver_distance_km']),
  );
}

class Zone {
  final int id;
  final String name;
  final double? lat, lng;
  Zone(this.id, this.name, this.lat, this.lng);

  factory Zone.fromJson(Map<String, dynamic> j) => Zone(
    _asInt(j['id']),
    (j['name'] ?? '-').toString(),
    _asDoubleOrNull(j['center_latitude']),
    _asDoubleOrNull(j['center_longitude']),
  );
}

class Place {
  final int id;
  final int? zoneId;
  final String name, address;
  final double lat, lng;
  Place(this.id, this.zoneId, this.name, this.address, this.lat, this.lng);

  factory Place.fromJson(Map<String, dynamic> j) => Place(
    _asInt(j['id']),
    _asIntOrNull(j['zone_id']),
    (j['name'] ?? '-').toString(),
    (j['address'] ?? '').toString(),
    _asDouble(j['latitude']),
    _asDouble(j['longitude']),
  );
}

class FareEstimate {
  final String? zoneName;
  final double distanceKm;
  final int durationMinutes;
  final double baseFare, distanceFare, totalFare;
  final double? serviceFee;
  final double? extraFee;
  final int driversNearby;

  FareEstimate({
    this.zoneName,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.baseFare = 0,
    this.distanceFare = 0,
    this.totalFare = 0,
    this.serviceFee,
    this.extraFee,
    this.driversNearby = 0,
  });

  factory FareEstimate.fromJson(Map<String, dynamic> j) {
    final zone = j['zone'];
    return FareEstimate(
      zoneName: zone is Map ? zone['name']?.toString() : null,
      distanceKm: _asDouble(j['distance_km']),
      durationMinutes: _asInt(j['duration_minutes']),
      baseFare: _asDouble(j['base_fare']),
      distanceFare: _asDouble(j['distance_fare']),
      totalFare: _asDouble(j['total_fare']),
      serviceFee: _asDoubleOrNull(j['service_fee']),
      extraFee: _asDoubleOrNull(j['extra_fee']),
      driversNearby: _asInt(j['drivers_nearby']),
    );
  }
}

// ============================================================
// Mitra: Torang Makan / Torang Mart / Sewa Kos
// ============================================================
class Merchant {
  final int id;
  final String type; // restaurant | store | kos
  final String name;
  final String? category, address, phone;
  final double? lat, lng;
  final double? priceMonthly;
  final List<String> facilities;
  final double rating;

  Merchant({
    required this.id,
    required this.type,
    required this.name,
    this.category,
    this.address,
    this.phone,
    this.lat,
    this.lng,
    this.priceMonthly,
    this.facilities = const [],
    this.rating = 5,
  });

  factory Merchant.fromJson(Map<String, dynamic> j) => Merchant(
    id: _asInt(j['id']),
    type: (j['type'] ?? 'restaurant').toString(),
    name: (j['name'] ?? '-').toString(),
    category: j['category']?.toString(),
    address: j['address']?.toString(),
    phone: j['phone']?.toString(),
    lat: _asDoubleOrNull(j['latitude']),
    lng: _asDoubleOrNull(j['longitude']),
    priceMonthly: _asDoubleOrNull(j['price_monthly']),
    facilities: ((j['facilities'] as List?) ?? [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList(),
    rating: _asDoubleOrNull(j['rating']) ?? 5,
  );
}

/// Ringkasan merchant yang menempel di order.
class MerchantInfo {
  final int id;
  final String name;
  final String? category, address, phone;
  MerchantInfo(this.id, this.name, this.category, this.address, this.phone);

  factory MerchantInfo.fromJson(Map<String, dynamic> j) => MerchantInfo(
    _asInt(j['id']),
    (j['name'] ?? '-').toString(),
    j['category']?.toString(),
    j['address']?.toString(),
    j['phone']?.toString(),
  );
}

// ============================================================
// Torang Bayar (PPOB)
// ============================================================
class BillProduct {
  final String type, name, customerLabel;
  final double adminFee;
  BillProduct(this.type, this.name, this.customerLabel, this.adminFee);

  factory BillProduct.fromJson(Map<String, dynamic> j) => BillProduct(
    (j['type'] ?? 'lain').toString(),
    (j['name'] ?? 'Tagihan').toString(),
    (j['customer_label'] ?? 'Nomor').toString(),
    _asDouble(j['admin_fee']),
  );
}

class BillPayment {
  final int id;
  final String reference, productType, productName, customerNo, status;
  final String? statusLabel, note, createdAt;
  final double amount, adminFee, total;
  final String paymentMethod;

  BillPayment({
    required this.id,
    required this.reference,
    required this.productType,
    required this.productName,
    required this.customerNo,
    required this.status,
    this.statusLabel,
    this.note,
    this.createdAt,
    this.amount = 0,
    this.adminFee = 0,
    this.total = 0,
    this.paymentMethod = 'cash',
  });

  factory BillPayment.fromJson(Map<String, dynamic> j) => BillPayment(
    id: _asInt(j['id']),
    reference: (j['reference'] ?? '-').toString(),
    productType: (j['product_type'] ?? 'lain').toString(),
    productName: (j['product_name'] ?? 'Tagihan').toString(),
    customerNo: (j['customer_no'] ?? '-').toString(),
    status: (j['status'] ?? 'pending').toString(),
    statusLabel: j['status_label']?.toString(),
    note: j['note']?.toString(),
    createdAt: j['created_at']?.toString(),
    amount: _asDouble(j['amount']),
    adminFee: _asDouble(j['admin_fee']),
    total: _asDouble(j['total']),
    paymentMethod: (j['payment_method'] ?? 'cash').toString(),
  );
}

// ============================================================
// Bantuan — info kontak admin (dari dashboard)
// ============================================================
class SupportSettings {
  final String adminWhatsapp, supportEmail, supportHours, botName;
  final bool adminOnline;
  SupportSettings({
    this.adminWhatsapp = '',
    this.supportEmail = '',
    this.supportHours = '',
    this.botName = 'Tori',
    this.adminOnline = false,
  });

  factory SupportSettings.fromJson(Map<String, dynamic> j) => SupportSettings(
    adminWhatsapp: (j['admin_whatsapp'] ?? '').toString(),
    supportEmail: (j['support_email'] ?? '').toString(),
    supportHours: (j['support_hours'] ?? '').toString(),
    botName: (j['bot_name'] ?? 'Tori').toString(),
    adminOnline: j['admin_online'] == true,
  );
}

// ============================================================
// Feature flags — tampil/sembunyi layanan (diatur dari dashboard admin)
// Default semua true = fallback aman kalau server belum punya
// endpoint /features (semua menu tetap tampil seperti biasa).
// ============================================================
class AppFeatures {
  final bool ride, bentor, car, send, food, mart, bayar, kos, help;

  const AppFeatures({
    this.ride = true,
    this.bentor = true,
    this.car = true,
    this.send = true,
    this.food = true,
    this.mart = true,
    this.bayar = true,
    this.kos = true,
    this.help = true,
  });

  /// Cache flag terakhir yang berhasil diambil dari server
  /// (diisi HomeScreen tiap app dibuka / pull-to-refresh).
  static AppFeatures cached = const AppFeatures();

  /// `false` hanya kalau server eksplisit bilang false;
  /// key hilang (backend lama) → dianggap aktif.
  factory AppFeatures.fromJson(Map<String, dynamic> j) => AppFeatures(
    ride: j['ride'] != false,
    bentor: j['bentor'] != false,
    car: j['car'] != false,
    send: j['send'] != false,
    food: j['food'] != false,
    mart: j['mart'] != false,
    bayar: j['bayar'] != false,
    kos: j['kos'] != false,
    help: j['help'] != false,
  );

  /// Cek flag berdasarkan route layanan
  /// (ride/bentor/car/send/food/mart/bayar/kos/help).
  bool of(String key) => switch (key) {
    'ride' => ride,
    'bentor' => bentor,
    'car' => car,
    'send' => send,
    'food' => food,
    'mart' => mart,
    'bayar' => bayar,
    'kos' => kos,
    'help' => help,
    _ => true,
  };
}

class DriverSummary {
  final String driverStatus, dutyStatus;
  final double todayEarnings;
  final int todayOrders;
  final int totalOrders;
  final double totalEarnings, rating;

  DriverSummary({
    this.driverStatus = 'pending',
    this.dutyStatus = 'offline',
    this.todayEarnings = 0,
    this.todayOrders = 0,
    this.totalOrders = 0,
    this.totalEarnings = 0,
    this.rating = 5,
  });

  factory DriverSummary.fromJson(Map<String, dynamic> j) {
    final today = j['today'];
    final total = j['total'];
    return DriverSummary(
      driverStatus: (j['driver_status'] ?? 'pending').toString(),
      dutyStatus: (j['duty_status'] ?? 'offline').toString(),
      todayEarnings:
          (today is Map ? (today['earnings'] as num?)?.toDouble() : null) ?? 0,
      todayOrders:
          (today is Map ? (today['orders'] as num?)?.toInt() : null) ?? 0,
      totalOrders:
          (total is Map ? (total['orders'] as num?)?.toInt() : null) ?? 0,
      totalEarnings:
          (total is Map ? (total['earnings'] as num?)?.toDouble() : null) ?? 0,
      rating:
          (total is Map ? (total['rating'] as num?)?.toDouble() : null) ?? 5,
    );
  }
}

class WalletTransaction {
  final int id;
  final String type;
  final double amount;
  final String description;
  final String? at;
  WalletTransaction(this.id, this.type, this.amount, this.description, this.at);

  bool get isCredit => type == 'credit' || type == 'earning' || amount > 0;
}

class TgNotification {
  final int id;
  final String title, body;
  final String? readAt;
  final String? createdAt;
  TgNotification(this.id, this.title, this.body, this.readAt, this.createdAt);
  bool get unread => readAt == null;
}
