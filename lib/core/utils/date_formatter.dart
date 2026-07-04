// lib/core/utils/date_formatter.dart

/// Kumpulan helper untuk memformat tanggal/waktu dari Supabase (format ISO 8601)
/// menjadi tampilan yang enak dibaca, tanpa perlu package tambahan (intl).
class DateFormatter {
  static const List<String> _bulanPendek = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Contoh hasil: "03 Jun 2026, 00:32"
  static String formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final tanggal = dt.day.toString().padLeft(2, '0');
      final bulan = _bulanPendek[dt.month - 1];
      final jam = dt.hour.toString().padLeft(2, '0');
      final menit = dt.minute.toString().padLeft(2, '0');
      return '$tanggal $bulan ${dt.year}, $jam:$menit';
    } catch (_) {
      // fallback kalau gagal parse, biar tidak crash
      return isoString;
    }
  }

  /// Contoh hasil: "03 Jun 2026" (tanpa jam, untuk tampilan ringkas seperti di list)
  static String formatDateOnly(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final tanggal = dt.day.toString().padLeft(2, '0');
      final bulan = _bulanPendek[dt.month - 1];
      return '$tanggal $bulan ${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  /// Contoh hasil: "00:32" (hanya jam, kalau butuh dipisah dari tanggal di UI)
  static String formatTimeOnly(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final jam = dt.hour.toString().padLeft(2, '0');
      final menit = dt.minute.toString().padLeft(2, '0');
      return '$jam:$menit';
    } catch (_) {
      return isoString;
    }
  }
}
