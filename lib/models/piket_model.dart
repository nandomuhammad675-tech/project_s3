import 'package:si_kesa/utils/json_helper.dart';

/// Siswa yang bertugas pada satu piket.
class SiswaPiketModel {
  final int idSiswa;
  final String nama;

  const SiswaPiketModel({required this.idSiswa, required this.nama});

  factory SiswaPiketModel.fromJson(Map<String, dynamic> j) => SiswaPiketModel(
        idSiswa: asInt(j['id_siswa']) ?? 0,
        nama: '${j['nama_siswa'] ?? ''}',
      );
}

/// Satu piket per hari (GET /api/guru/piket). Piket berulang tiap minggu, bukan per tanggal.
class PiketModel {
  final int idPiket;
  final String hari; // senin .. sabtu (huruf kecil)
  final String? keterangan;
  final List<SiswaPiketModel> siswa;

  const PiketModel({
    required this.idPiket,
    required this.hari,
    this.keterangan,
    this.siswa = const [],
  });

  String get namaSiswa => siswa.map((s) => s.nama).join(', ');

  factory PiketModel.fromJson(Map<String, dynamic> j) {
    final s = j['siswa'];
    return PiketModel(
      idPiket: asInt(j['id_piket']) ?? 0,
      hari: '${j['hari']}'.toLowerCase(),
      keterangan: j['keterangan'] as String?,
      siswa: s is List
          ? s.map((e) => SiswaPiketModel.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
    );
  }
}