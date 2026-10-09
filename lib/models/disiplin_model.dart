class DisiplinModel {
  final DateTime tanggal;
  final String jenisPelanggaran;
  final String catatan;

  const DisiplinModel({
    required this.tanggal,
    required this.jenisPelanggaran,
    this.catatan = '',
  });
}