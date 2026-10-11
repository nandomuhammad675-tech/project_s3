import 'package:si_kesa/utils/json_helper.dart';

/// GET /api/wali/siswa. namaWaliKelas hanya terisi bila backend mengirimnya (belum ada pada kontrak v1).
class SiswaModel {
  final String nama;
  final String nisn;
  final String namaKelas;
  final int tingkatKelas;
  final int? nomorAbsen;
  final String tahunAjaran;
  final String semester;
  final String? namaWaliKelas;

  const SiswaModel({
    required this.nama,
    required this.nisn,
    required this.namaKelas,
    required this.tingkatKelas,
    this.nomorAbsen,
    required this.tahunAjaran,
    required this.semester,
    this.namaWaliKelas,
  });

  factory SiswaModel.fromJson(Map<String, dynamic> j) => SiswaModel(
        nama: j['nama_siswa'] as String,
        nisn: j['nisn'] as String,
        namaKelas: j['nama_kelas'] as String,
        tingkatKelas: asInt(j['tingkat_kelas']) ?? 0,
        nomorAbsen: asInt(j['nomor_absen']),
        tahunAjaran: j['tahun_ajaran'] as String,
        semester: j['semester'] as String,
        namaWaliKelas: j['nama_wali_kelas'] as String?,
      );
}
