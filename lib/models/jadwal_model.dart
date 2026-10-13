/// Satu baris jadwal pelajaran (GET /api/guru/jadwal). Jadwal milik kelas, bukan milik guru pengampu.
class JadwalModel {
  final String hari; // senin .. sabtu (huruf kecil)
  final String jamMulai; // "07:00"
  final String jamSelesai; // "08:30"
  final String mapel;
  final String? keterangan;

  const JadwalModel({
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.mapel,
    this.keterangan,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> j) {
    final m = j['mapel'];
    return JadwalModel(
      hari: '${j['hari']}'.toLowerCase(),
      jamMulai: _jam(j['jam_mulai']),
      jamSelesai: _jam(j['jam_selesai']),
      mapel: '${j['nama_mapel'] ?? (m is Map ? m['nama_mapel'] ?? m['nama'] : m)}',
      keterangan: j['keterangan'] as String?,
    );
  }

  /// "07:00:00" -> "07:00"
  static String _jam(dynamic v) {
    final s = '$v';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  String get rentangJam => '$jamMulai - $jamSelesai';
}