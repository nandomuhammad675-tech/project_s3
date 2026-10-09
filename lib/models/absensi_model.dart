enum StatusKehadiran { hadir, sakit, izin, alfa }

class AbsensiModel {
  final DateTime tanggal;
  final StatusKehadiran status;

  const AbsensiModel({required this.tanggal, required this.status});
}