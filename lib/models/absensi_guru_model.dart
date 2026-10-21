import 'package:si_kesa/models/absensi_model.dart';
import 'package:si_kesa/utils/json_helper.dart';


/// Satu siswa aktif beserta absensinya pada satu tanggal.
/// [idAbsensi] dan [status] null = siswa itu belum diabsen pada tanggal tersebut.
class AbsensiBaris {
  final int idSiswa;
  final String nama;
  final int? nomorAbsen;
  final int? idAbsensi;
  final StatusKehadiran? status;

  const AbsensiBaris({
    required this.idSiswa,
    required this.nama,
    this.nomorAbsen,
    this.idAbsensi,
    this.status,
  });

  factory AbsensiBaris.fromJson(Map<String, dynamic> j) {
    final s = j['status'];
    StatusKehadiran? status;
    for (final e in StatusKehadiran.values) {
      if (e.name == s) status = e;
    }
    return AbsensiBaris(
      idSiswa: asInt(j['id_siswa']) ?? 0,
      nama: '${j['nama_siswa'] ?? ''}',
      nomorAbsen: asInt(j['nomor_absen']),
      idAbsensi: asInt(j['id_absensi']),
      status: status,
    );
  }
}

/// GET /api/guru/absensi?date= : { tanggal, status_kelas, items: [...] }
class AbsensiHari {
  final String statusKelas; // sudah | belum | libur
  final List<AbsensiBaris> items;

  const AbsensiHari({required this.statusKelas, required this.items});

  bool get libur => statusKelas == 'libur';

  factory AbsensiHari.fromJson(Map<String, dynamic> j) => AbsensiHari(
        statusKelas: '${j['status_kelas'] ?? ''}',
        items: (j['items'] as List)
            .map((e) => AbsensiBaris.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}