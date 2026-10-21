import 'package:si_kesa/utils/json_helper.dart';

/// Satu baris nilai dari GET /api/guru/nilai.
/// [nomorUh] hanya terisi untuk jenis UH. [jenis]: UH | ASTS | ASAS.
class NilaiGuruBaris {
  final int idNilai;
  final int idSiswa;
  final int idMapel;
  final String namaMapel;
  final String jenis;
  final int? nomorUh;
  final int nilai;

  const NilaiGuruBaris({
    required this.idNilai,
    required this.idSiswa,
    this.idMapel = 0,
    this.namaMapel = '',
    required this.jenis,
    this.nomorUh,
    required this.nilai,
  });

  factory NilaiGuruBaris.fromJson(Map<String, dynamic> j) => NilaiGuruBaris(
        idNilai: asInt(j['id_nilai']) ?? 0,
        idSiswa: asInt(j['id_siswa']) ?? 0,
        idMapel: asInt(j['id_mapel']) ?? 0,
        namaMapel: '${j['nama_mapel'] ?? ''}',
        jenis: '${j['jenis'] ?? ''}',
        nomorUh: asInt(j['nomor_uh']),
        nilai: asInt(j['nilai']) ?? 0,
      );
}