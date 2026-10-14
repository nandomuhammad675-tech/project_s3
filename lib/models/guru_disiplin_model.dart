import 'package:si_kesa/utils/json_helper.dart';

/// Siswa aktif di kelas Guru (GET /api/guru/siswa).
class SiswaKelasModel {
  final int idSiswa;
  final String nama;
  final int? nomorAbsen;

  const SiswaKelasModel({required this.idSiswa, required this.nama, this.nomorAbsen});

  String get label => nomorAbsen == null ? nama : '$nomorAbsen. $nama';

  factory SiswaKelasModel.fromJson(Map<String, dynamic> j) => SiswaKelasModel(
        idSiswa: asInt(j['id_siswa']) ?? 0,
        nama: '${j['nama_siswa'] ?? ''}',
        nomorAbsen: asInt(j['nomor_absen']),
      );
}

/// Satu catatan kedisiplinan (GET /api/guru/disiplin).
class CatatanDisiplinModel {
  final int idCatatan;
  final int idSiswa;
  final String namaSiswa;
  final DateTime tanggal;
  final String jenisPelanggaran;
  final String catatan;

  const CatatanDisiplinModel({
    required this.idCatatan,
    required this.idSiswa,
    required this.namaSiswa,
    required this.tanggal,
    required this.jenisPelanggaran,
    required this.catatan,
  });

  factory CatatanDisiplinModel.fromJson(Map<String, dynamic> j) => CatatanDisiplinModel(
        idCatatan: asInt(j['id_catatan']) ?? 0,
        idSiswa: asInt(j['id_siswa']) ?? 0,
        namaSiswa: '${j['nama_siswa'] ?? ''}',
        tanggal: DateTime.parse('${j['tanggal']}'),
        jenisPelanggaran: '${j['jenis_pelanggaran'] ?? ''}',
        catatan: '${j['catatan'] ?? ''}',
      );
}