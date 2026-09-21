import 'package:intl/intl.dart';

final NumberFormat _rp = NumberFormat.currency(
  locale: 'id',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String rp(num? v) => _rp.format(v ?? 0);

String km(double? v) => v == null
    ? '-'
    : (v >= 10 ? '${v.toStringAsFixed(0)} km' : '${v.toStringAsFixed(1)} km');

String timeAgoIso(String? iso) {
  if (iso == null) return '-';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '-';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return DateFormat('dd MMM yyyy', 'id').format(dt);
}

String dateTimeId(String? iso) {
  if (iso == null) return '-';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '-';
  return DateFormat('dd MMM yyyy • HH:mm', 'id').format(dt);
}

String clockId(String? iso) {
  if (iso == null) return '-';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '-';
  return DateFormat('HH:mm', 'id').format(dt);
}
