import 'package:si_kesa/models/absensi_model.dart';
import 'package:si_kesa/models/disiplin_model.dart';
import 'package:si_kesa/models/nilai_model.dart';
import 'package:si_kesa/models/siswa_model.dart';
import 'package:si_kesa/services/api_client.dart';

/// Endpoint Wali Murid (read-only). Scope siswa selalu dari token di server.
class WaliService {
  WaliService._();

  static final ApiClient _api = ApiClient.instance;
  static Future<SiswaModel>? _profil;

  static void hapusCache() => _profil = null;

  /// GET /api/wali/siswa. Hasil disimpan selama sesi agar tiap layar tidak memanggil ulang.
  static Future<SiswaModel> profil({bool refresh = false}) {
    if (refresh || _profil == null) {
      _profil = _profilDenganReset();
    }
    return _profil!;
  }

  static Future<SiswaModel> _profilDenganReset() async {
    try {
      final d = await _api.get('/api/wali/siswa');
      return _urai<SiswaModel>(() => SiswaModel.fromJson(d as Map<String, dynamic>));
    } catch (_) {
      _profil = null; // kegagalan tidak boleh tersimpan di cache
      rethrow;
    }
  }

  /// GET /api/wali/nilai. Tanpa [semester]: kedua semester pada tahun ajaran aktif.
  static Future<NilaiResult> nilai({String? semester}) async {
    final d = await _api.get('/api/wali/nilai', query: {'semester': semester});
    return _urai<NilaiResult>(() => NilaiResult.fromJson(d as Map<String, dynamic>));
  }

  /// GET /api/wali/absensi. [bulan] berformat YYYY-MM.
  static Future<AbsensiResult> absensi({String? semester, String? bulan}) async {
    final d = await _api.get('/api/wali/absensi', query: {'semester': semester, 'bulan': bulan});
    return _urai<AbsensiResult>(() => AbsensiResult.fromJson(d as Map<String, dynamic>));
  }

  /// GET /api/wali/disiplin. [bulan] berformat YYYY-MM.
  static Future<DisiplinResult> disiplin({String? bulan}) async {
    final d = await _api.get('/api/wali/disiplin', query: {'bulan': bulan});
    return _urai<DisiplinResult>(() => DisiplinResult.fromJson(d as Map<String, dynamic>));
  }

  static T _urai<T>(T Function() f) {
    try {
      return f();
    } catch (_) {
      throw const ApiException('Data dari server tidak dapat dibaca.');
    }
  }
}
