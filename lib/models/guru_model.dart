import 'package:si_kesa/models/kelas_model.dart';

/// GET /api/guru/me. [kelas] null = Guru belum ditetapkan sebagai wali kelas pada tahun ajaran aktif.
class GuruModel {
  final String nama;
  final KelasModel? kelas;

  const GuruModel({required this.nama, this.kelas});

  bool get adaKelas => kelas != null;

  factory GuruModel.fromJson(Map<String, dynamic> j) {
    final k = j['kelas'];
    return GuruModel(
      nama: '${j['nama_guru'] ?? j['nama_lengkap'] ?? j['nama']}',
      kelas: k is Map<String, dynamic> ? KelasModel.fromJson(k) : null,
    );
  }
}