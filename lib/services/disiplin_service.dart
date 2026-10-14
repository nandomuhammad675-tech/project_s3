import 'package:si_kesa/models/guru_disiplin_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/utils/date_formatter.dart';

/// Kedisiplinan sisi Guru (kelas sendiri). Tidak ada hapus: server memang tidak menyediakannya.
class DisiplinService {
  DisiplinService._();

  static final ApiClient _api = ApiClient.instance;

  /// GET /api/guru/siswa: siswa aktif kelas sendiri, urut nomor absen.
  static Future<List<SiswaKelasModel>> siswa() async {
    final d = await _api.get('/api/guru/siswa');
    return uraiData(() => (d['items'] as List)
        .map((e) => SiswaKelasModel.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  /// GET /api/guru/disiplin: catatan terbaru di atas.
  static Future<List<CatatanDisiplinModel>> daftar() async {
    final d = await _api.get('/api/guru/disiplin', query: {'per_page': '200'});
    return uraiData(() => (d['items'] as List)
        .map((e) => CatatanDisiplinModel.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  /// POST /api/guru/disiplin. Kelas, tahun ajaran, dan id_guru diisi server.
  static Future<void> tambah({
    required int idSiswa,
    required DateTime tanggal,
    required String jenis,
    required String catatan,
  }) async {
    await _api.post('/api/guru/disiplin', body: {
      'id_siswa': idSiswa,
      'tanggal': DateFormatter.iso(tanggal),
      'jenis_pelanggaran': jenis,
      'catatan': catatan,
    });
  }

  /// PUT /api/guru/disiplin/{id}. Siswa pada catatan tidak boleh diganti, jadi tidak dikirim.
  static Future<void> ubah(
    int idCatatan, {
    required DateTime tanggal,
    required String jenis,
    required String catatan,
  }) async {
    await _api.put('/api/guru/disiplin/$idCatatan', body: {
      'tanggal': DateFormatter.iso(tanggal),
      'jenis_pelanggaran': jenis,
      'catatan': catatan,
    });
  }
}