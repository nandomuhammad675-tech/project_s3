import 'package:si_kesa/models/absensi_guru_model.dart';
import 'package:si_kesa/models/absensi_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/utils/date_formatter.dart';

/// Absensi sisi Guru. Kelas, tahun ajaran, semester, dan id_guru selalu diisi server (dari token).
class AbsensiService {
  AbsensiService._();

  static final ApiClient _api = ApiClient.instance;

  /// Status absensi kelas pada [tanggal] (kartu Beranda). Hari Minggu selalu "libur" tanpa memanggil server.
  /// GET /api/guru/dasbor/absensi?date=YYYY-MM-DD
  static Future<StatusAbsensiHari> statusTanggal(DateTime tanggal) async {
    if (tanggal.weekday == DateTime.sunday) return StatusAbsensiHari.libur;

    final d = await _api.get(
      '/api/guru/dasbor/absensi',
      query: {'date': DateFormatter.iso(tanggal)},
    );
    return uraiData(() => bacaStatusAbsensiHari(d as Map<String, dynamic>));
  }

  /// Status absensi hari ini untuk kartu Beranda.
  static Future<StatusAbsensiHari> statusHariIni() => statusTanggal(DateTime.now());

  /// Seluruh siswa aktif kelas + status absensi pada [tanggal] + status kelas (sudah/belum/libur).
  /// GET /api/guru/absensi?date=YYYY-MM-DD
  static Future<AbsensiHari> lihat(DateTime tanggal) async {
    final d = await _api.get(
      '/api/guru/absensi',
      query: {'date': DateFormatter.iso(tanggal)},
    );
    return uraiData(() => AbsensiHari.fromJson(d as Map<String, dynamic>));
  }

  /// Simpan siswa yang BELUM punya catatan pada tanggal itu, dalam satu permintaan (transaksi).
  /// Server membalas 409 bila ada siswa yang sudah tercatat, dan 422 bila Minggu/libur.
  /// POST /api/guru/absensi
  static Future<void> simpanBaru(DateTime tanggal, Map<int, StatusKehadiran> isi) async {
    await _api.post('/api/guru/absensi', body: {
      'tanggal': DateFormatter.iso(tanggal),
      'items': [
        for (final e in isi.entries) {'id_siswa': e.key, 'status': e.value.name},
      ],
    });
  }

  /// Koreksi satu catatan yang sudah ada. PUT /api/guru/absensi/{id_absensi}
  static Future<void> ubah(int idAbsensi, StatusKehadiran status) async {
    await _api.put('/api/guru/absensi/$idAbsensi', body: {'status': status.name});
  }
}