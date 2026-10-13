import 'package:si_kesa/utils/json_helper.dart';

/// Kelas yang diampu Guru sebagai wali kelas pada tahun ajaran aktif (bagian dari GET /api/guru/me).
/// CATATAN: nama field di bawah mengikuti gaya kontrak Wali (snake_case). Cocokkan dengan KONTRAK_API.md.
class KelasModel {
  final int id;
  final String nama; // "6A"
  final String tahunAjaran; // "2026/2027"
  final String semester; // ganjil | genap (semester berjalan)
  final int jumlahSiswaAktif;

  const KelasModel({
    this.id = 0,
    required this.nama,
    required this.tahunAjaran,
    required this.semester,
    this.jumlahSiswaAktif = 0,
  });

  factory KelasModel.fromJson(Map<String, dynamic> j) => KelasModel(
        id: asInt(j['id_kelas'] ?? j['id']) ?? 0,
        nama: '${j['nama_kelas'] ?? j['nama']}',
        tahunAjaran: '${j['tahun_ajaran']}',
        semester: '${j['semester'] ?? j['semester_aktif']}'.toLowerCase(),
        jumlahSiswaAktif: asInt(j['jumlah_siswa_aktif'] ?? j['jumlah_siswa']) ?? 0,
      );

  /// "Ganjil" / "Genap" untuk ditampilkan.
  String get semesterLabel =>
      semester.isEmpty ? '' : '${semester[0].toUpperCase()}${semester.substring(1)}';
}