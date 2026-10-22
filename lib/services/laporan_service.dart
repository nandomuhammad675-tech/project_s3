import 'dart:typed_data';

import 'package:si_kesa/services/api_client.dart';

/// Laporan semester sisi Guru (kelas sendiri, hanya tahun ajaran aktif).
class LaporanService {
  LaporanService._();

  static final ApiClient _api = ApiClient.instance;

  /// GET /api/guru/laporan/excel. [jenis]: absensi | nilai | semua.
  /// [idMapel] dan [idSiswa] opsional, hanya mempersempit rekap nilai.
  static Future<Uint8List> unduh({
    required int idTahunAjaran,
    required String semester,
    String jenis = 'absensi',
    int? idMapel,
    int? idSiswa,
  }) {
    return _api.unduhExcel('/api/guru/laporan/excel', query: {
      'semester': semester,
      'tahun_ajaran': '$idTahunAjaran',
      'jenis': jenis,
      'mapel': idMapel?.toString(),
      'siswa': idSiswa?.toString(),
    });
  }
}