class DateFormatter {
  DateFormatter._();

  static const _hari = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  static const _bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// "September 2026"
  static String bulanTahun(DateTime d) => '${_bulan[d.month - 1]} ${d.year}';

  /// "Selasa, 15 September 2026"
  static String lengkap(DateTime d) =>
      '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';
}