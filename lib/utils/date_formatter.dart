class DateFormatter {
  DateFormatter._();

  static const _hari = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  static const _bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  /// "2026-10-05" (format tanggal yang dipakai API)
  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// "senin", "selasa", ... (huruf kecil, sama dengan nilai `hari` di API)
  static String hariApi(DateTime d) => _hari[d.weekday - 1].toLowerCase();
  
  /// "September 2026"
  static String bulanTahun(DateTime d) => '${_bulan[d.month - 1]} ${d.year}';

  /// "Selasa, 15 September 2026"
  static String lengkap(DateTime d) =>
      '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';
}