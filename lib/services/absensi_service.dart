import 'package:si_kesa/models/absensi_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/utils/date_formatter.dart';

/// Absensi sisi Guru.
class AbsensiService {
  AbsensiService._();

  static final ApiClient _api = ApiClient.instance;

  /// Status absensi hari ini untuk kartu Beranda. Hari Minggu selalu "libur" tanpa memanggil server.
  static Future<StatusAbsensiHari> statusHariIni() async {
    final sekarang = DateTime.now();
    if (sekarang.weekday == DateTime.sunday) return StatusAbsensiHari.libur;

    final d = await _api.get(
      '/api/guru/dasbor/absensi',
      query: {'date': DateFormatter.iso(sekarang)},
    );
    return uraiData(() => bacaStatusAbsensiHari(d as Map<String, dynamic>));
  }
}