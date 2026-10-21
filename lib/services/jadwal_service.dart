import 'package:si_kesa/models/jadwal_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/utils/date_formatter.dart';

/// Jadwal pelajaran sisi Guru (kelas sendiri). Kelas dan tahun ajaran diisi server (dari token).
class JadwalService {
  JadwalService._();

  static final ApiClient _api = ApiClient.instance;

  /// GET /api/guru/jadwal?semester=ganjil|genap. Menerima respons berupa daftar langsung atau {items: [...]}.
  static Future<List<JadwalModel>> daftar({required String semester}) async {
    final d = await _api.get('/api/guru/jadwal', query: {'semester': semester, 'per_page': '200'});
    return uraiData(() {
      final list = d is Map ? d['items'] as List : d as List;
      return list.map((e) => JadwalModel.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Jadwal untuk hari ini, urut jam mulai. Hari Minggu: kosong tanpa memanggil server.
  static Future<List<JadwalModel>> hariIni({required String semester}) async {
    final sekarang = DateTime.now();
    if (sekarang.weekday == DateTime.sunday) return const [];

    final hari = DateFormatter.hariApi(sekarang);
    final semua = await daftar(semester: semester);
    return semua.where((j) => j.hari == hari).toList()
      ..sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
  }

  /// POST /api/guru/jadwal. Server menjawab 409 bila jamnya bentrok.
  static Future<void> tambah({
    required String semester,
    required int idMapel,
    required String hari,
    required String jamMulai,
    required String jamSelesai,
    String? keterangan,
  }) async {
    await _api.post('/api/guru/jadwal', body: {
      'semester': semester,
      'id_mapel': idMapel,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
    });
  }

  /// PUT /api/guru/jadwal/{id}.
  static Future<void> ubah(
    int id, {
    required String semester,
    required int idMapel,
    required String hari,
    required String jamMulai,
    required String jamSelesai,
    String? keterangan,
  }) async {
    await _api.put('/api/guru/jadwal/$id', body: {
      'semester': semester,
      'id_mapel': idMapel,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'keterangan': keterangan ?? '',
    });
  }

  /// DELETE /api/guru/jadwal/{id}.
  static Future<void> hapus(int id) async {
    await _api.delete('/api/guru/jadwal/$id');
  }
}