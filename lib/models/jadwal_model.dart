/// Status satu jadwal pada satu tanggal (dihitung di aplikasi, bukan dari server).
enum StatusJadwal { selesai, berlangsung, menunggu, akanDatang }

/// Satu baris jadwal pelajaran (GET /api/guru/jadwal). Jadwal milik kelas, bukan milik guru pengampu.
class JadwalModel {
  final int id;
  final int idMapel;
  final String hari; // senin .. sabtu (huruf kecil)
  final String jamMulai; // "07:00"
  final String jamSelesai; // "08:30"
  final String mapel;
  final String? keterangan;

  const JadwalModel({
    this.id = 0,
    this.idMapel = 0,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.mapel,
    this.keterangan,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> j) {
    final m = j['mapel'];
    return JadwalModel(
      id: _angka(j['id_jadwal'] ?? j['id']),
      idMapel: _angka(j['id_mapel']),
      hari: '${j['hari']}'.toLowerCase(),
      jamMulai: _jam(j['jam_mulai']),
      jamSelesai: _jam(j['jam_selesai']),
      mapel: '${j['nama_mapel'] ?? (m is Map ? m['nama_mapel'] ?? m['nama'] : m)}',
      keterangan: j['keterangan'] as String?,
    );
  }

  static int _angka(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  /// "07:00:00" -> "07:00"
  static String _jam(dynamic v) {
    final s = '$v';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  String get rentangJam => '$jamMulai - $jamSelesai';

  /// Status jadwal ini pada [tanggal], dilihat dari waktu [sekarang].
  StatusJadwal statusPada(DateTime tanggal, DateTime sekarang) {
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final t = DateTime(tanggal.year, tanggal.month, tanggal.day);
    if (t.isBefore(hariIni)) return StatusJadwal.selesai;
    if (t.isAfter(hariIni)) return StatusJadwal.akanDatang;
    String dua(int n) => n.toString().padLeft(2, '0');
    final jam = '${dua(sekarang.hour)}:${dua(sekarang.minute)}';
    if (jam.compareTo(jamSelesai) >= 0) return StatusJadwal.selesai;
    if (jam.compareTo(jamMulai) >= 0) return StatusJadwal.berlangsung;
    return StatusJadwal.menunggu;
  }
}