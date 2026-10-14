import 'package:si_kesa/utils/json_helper.dart';

/// Kelas wali Guru pada tahun ajaran aktif.
/// GET /api/guru/me: { guru, tahun_ajaran: {nama_tahun, semester}, kelas: {id_kelas, nama_kelas, ...} }
class KelasModel {
  final int id;
  final String nama; // "6A"
  final String tahunAjaran; // "2026/2027"
  final String semester; // ganjil | genap
  final int? jumlahSiswaAktif; // null = belum atau gagal dimuat

  const KelasModel({
    this.id = 0,
    required this.nama,
    required this.tahunAjaran,
    required this.semester,
    this.jumlahSiswaAktif,
  });

  /// [tahun] = objek `tahun_ajaran` dari /me (sejajar dengan `kelas`, bukan di dalamnya).
  factory KelasModel.fromJson(Map<String, dynamic> j, {Map<String, dynamic>? tahun}) =>
      KelasModel(
        id: asInt(j['id_kelas'] ?? j['id']) ?? 0,
        nama: '${j['nama_kelas'] ?? j['nama'] ?? ''}',
        tahunAjaran: '${tahun?['nama_tahun'] ?? j['tahun_ajaran'] ?? ''}',
        semester: '${tahun?['semester'] ?? j['semester'] ?? ''}'.toLowerCase(),
        jumlahSiswaAktif: asInt(j['jumlah_siswa_aktif']),
      );

  KelasModel denganJumlahSiswa(int? jumlah) => KelasModel(
        id: id,
        nama: nama,
        tahunAjaran: tahunAjaran,
        semester: semester,
        jumlahSiswaAktif: jumlah,
      );

  /// "Ganjil" / "Genap" untuk ditampilkan.
  String get semesterLabel =>
      semester.isEmpty ? '' : '${semester[0].toUpperCase()}${semester.substring(1)}';
}