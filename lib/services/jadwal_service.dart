import 'package:si_kesa/models/jadwal_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/utils/date_formatter.dart';

/// Jadwal pelajaran sisi Guru (kelas sendiri).
class JadwalService {
  JadwalService._();

  static final ApiClient _api = ApiClient.instance;

  /// GET /api/guru/jadwal?semester=ganjil|genap. Menerima respons berupa daftar langsung atau {items: [...]}.
  static Future<List<JadwalModel>> daftar({required String semester}) async {
    final d = await _api.get('/api/guru/jadwal', query: {'semester': semester});
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
}