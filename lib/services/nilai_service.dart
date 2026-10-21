import 'package:si_kesa/models/mapel_model.dart';
import 'package:si_kesa/models/nilai_guru_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/utils/json_helper.dart';

/// Nilai sisi Guru. Kelas, tahun ajaran, dan id_guru selalu diisi server (dari token).
class NilaiService {
  NilaiService._();

  static final ApiClient _api = ApiClient.instance;

  /// GET /api/guru/mapel : daftar mata pelajaran (baca saja).
  static Future<List<MapelModel>> mapel() async {
    final d = await _api.get('/api/guru/mapel', query: {'per_page': '200'});
    return uraiData(() => (d['items'] as List)
        .map((e) => MapelModel.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  /// GET /api/guru/nilai?id_mapel=&id_siswa=&semester= (semua penyaring opsional).
  /// Memuat halaman demi halaman sampai semua baris terambil.
  static Future<List<NilaiGuruBaris>> daftar({
    int? idMapel,
    int? idSiswa,
    required String semester,
  }) async {
    final hasil = <NilaiGuruBaris>[];
    var halaman = 1;
    while (true) {
      final d = await _api.get('/api/guru/nilai', query: {
        'id_mapel': idMapel?.toString(),
        'id_siswa': idSiswa?.toString(),
        'semester': semester,
        'per_page': '200',
        'page': '$halaman',
      });
      final items = uraiData(() => (d['items'] as List)
          .map((e) => NilaiGuruBaris.fromJson(e as Map<String, dynamic>))
          .toList());
      final total = uraiData(() => asInt(d['total']) ?? 0);
      hasil.addAll(items);
      if (items.isEmpty || hasil.length >= total) break;
      halaman++;
    }
    return hasil;
  }

  /// POST /api/guru/nilai. [nomorUh] hanya dikirim untuk jenis UH.
  static Future<void> tambah({
    required int idSiswa,
    required int idMapel,
    required String semester,
    required String jenis,
    int? nomorUh,
    required int nilai,
  }) async {
    await _api.post('/api/guru/nilai', body: {
      'id_siswa': idSiswa,
      'id_mapel': idMapel,
      'semester': semester,
      'jenis': jenis,
      if (jenis == 'UH') 'nomor_uh': nomorUh,
      'nilai': nilai,
    });
  }

  /// PUT /api/guru/nilai/{id} : perbaiki angkanya saja.
  static Future<void> ubah(int idNilai, int nilai) async {
    await _api.put('/api/guru/nilai/$idNilai', body: {'nilai': nilai});
  }

  /// DELETE /api/guru/nilai/{id} : hanya UH. ASTS/ASAS ditolak server (422).
  static Future<void> hapus(int idNilai) async {
    await _api.delete('/api/guru/nilai/$idNilai');
  }
}