import '../core/theme.dart';

/// Model seluruh API Torang Go (bentuk JSON mengikuti Controller.php backend).

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
    id: j['id'] as int,
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
      id: j['id'] as int,
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
      rating: (j['rating'] as num?)?.toDouble() ?? 5.0,
      totalOrders: (j['total_orders'] as num?)?.toInt() ?? 0,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
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
    (j['latitude'] as num?)?.toDouble() ?? 0,
    (j['longitude'] as num?)?.toDouble() ?? 0,
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

  static const kActiveStatuses = [
    'pending',
    'searching_driver',
    'driver_assigned',
    'driver_on_the_way',
    'driver_arrived',
    'trip_started',
  ];

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'] as int,
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
    distanceKm: (j['distance_km'] as num?)?.toDouble() ?? 0,
    durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 0,
    baseFare: (j['base_fare'] as num?)?.toDouble() ?? 0,
    distanceFare: (j['distance_fare'] as num?)?.toDouble() ?? 0,
    totalFare: (j['total_fare'] as num?)?.toDouble() ?? 0,
    serviceFee: (j['service_fee'] as num?)?.toDouble(),
    commissionAmount: (j['commission_amount'] as num?)?.toDouble() ?? 0,
    driverEarning: (j['driver_earning'] as num?)?.toDouble() ?? 0,
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
    rated: j['rated'] as bool?,
    driverDistanceKm: (j['driver_distance_km'] as num?)?.toDouble(),
  );
}

class Zone {
  final int id;
  final String name;
  final double? lat, lng;
  Zone(this.id, this.name, this.lat, this.lng);

  factory Zone.fromJson(Map<String, dynamic> j) => Zone(
    j['id'] as int,
    (j['name'] ?? '-').toString(),
    (j['center_latitude'] as num?)?.toDouble(),
    (j['center_longitude'] as num?)?.toDouble(),
  );
}

class Place {
  final int id;
  final int? zoneId;
  final String name, address;
  final double lat, lng;
  Place(this.id, this.zoneId, this.name, this.address, this.lat, this.lng);

  factory Place.fromJson(Map<String, dynamic> j) => Place(
    j['id'] as int,
    j['zone_id'] as int?,
    (j['name'] ?? '-').toString(),
    (j['address'] ?? '').toString(),
    (j['latitude'] as num?)?.toDouble() ?? 0,
    (j['longitude'] as num?)?.toDouble() ?? 0,
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
      distanceKm: (j['distance_km'] as num?)?.toDouble() ?? 0,
      durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 0,
      baseFare: (j['base_fare'] as num?)?.toDouble() ?? 0,
      distanceFare: (j['distance_fare'] as num?)?.toDouble() ?? 0,
      totalFare: (j['total_fare'] as num?)?.toDouble() ?? 0,
      serviceFee: (j['service_fee'] as num?)?.toDouble(),
      extraFee: (j['extra_fee'] as num?)?.toDouble(),
      driversNearby: (j['drivers_nearby'] as num?)?.toInt() ?? 0,
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
    id: j['id'] as int,
    type: (j['type'] ?? 'restaurant').toString(),
    name: (j['name'] ?? '-').toString(),
    category: j['category']?.toString(),
    address: j['address']?.toString(),
    phone: j['phone']?.toString(),
    lat: (j['latitude'] as num?)?.toDouble(),
    lng: (j['longitude'] as num?)?.toDouble(),
    priceMonthly: (j['price_monthly'] as num?)?.toDouble(),
    facilities: ((j['facilities'] as List?) ?? [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList(),
    rating: (j['rating'] as num?)?.toDouble() ?? 5,
  );
}

/// Ringkasan merchant yang menempel di order.
class MerchantInfo {
  final int id;
  final String name;
  final String? category, address, phone;
  MerchantInfo(this.id, this.name, this.category, this.address, this.phone);

  factory MerchantInfo.fromJson(Map<String, dynamic> j) => MerchantInfo(
    j['id'] as int,
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
    (j['admin_fee'] as num?)?.toDouble() ?? 0,
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
    id: j['id'] as int,
    reference: (j['reference'] ?? '-').toString(),
    productType: (j['product_type'] ?? 'lain').toString(),
    productName: (j['product_name'] ?? 'Tagihan').toString(),
    customerNo: (j['customer_no'] ?? '-').toString(),
    status: (j['status'] ?? 'pending').toString(),
    statusLabel: j['status_label']?.toString(),
    note: j['note']?.toString(),
    createdAt: j['created_at']?.toString(),
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
    adminFee: (j['admin_fee'] as num?)?.toDouble() ?? 0,
    total: (j['total'] as num?)?.toDouble() ?? 0,
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
