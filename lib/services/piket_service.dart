import 'package:si_kesa/models/guru_disiplin_model.dart';
import 'package:si_kesa/models/piket_model.dart';
import 'package:si_kesa/services/api_client.dart';

/// Piket kebersihan kelas sendiri. Kelas dan tahun ajaran selalu dari token di server.
class PiketService {
  PiketService._();

  static final ApiClient _api = ApiClient.instance;

  /// GET /api/guru/piket: piket per hari, urut Senin sampai Sabtu.
  static Future<List<PiketModel>> daftar() async {
    final d = await _api.get('/api/guru/piket');
    return uraiData(() => (d['items'] as List)
        .map((e) => PiketModel.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  /// GET /api/guru/siswa: siswa aktif kelas sendiri (pilihan siswa piket).
  static Future<List<SiswaKelasModel>> siswa() async {
    final d = await _api.get('/api/guru/siswa');
    return uraiData(() => (d['items'] as List)
        .map((e) => SiswaKelasModel.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  /// POST /api/guru/piket. Hari yang sudah ada dibalas 409.
  static Future<void> tambah({required String hari, required List<int> idSiswa}) async {
    await _api.post('/api/guru/piket', body: {'hari': hari, 'id_siswa': idSiswa});
  }

  /// PUT /api/guru/piket/{id}. Daftar siswa yang dikirim MENGGANTI seluruh daftar lama.
  static Future<void> ubah(int idPiket, {required List<int> idSiswa}) async {
    await _api.put('/api/guru/piket/$idPiket', body: {'id_siswa': idSiswa});
  }

  /// DELETE /api/guru/piket/{id}. Daftar siswa bertugas ikut terhapus.
  static Future<void> hapus(int idPiket) async {
    await _api.delete('/api/guru/piket/$idPiket');
  }
}