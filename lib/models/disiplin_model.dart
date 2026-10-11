class DisiplinModel {
  final DateTime tanggal;
  final String jenisPelanggaran;
  final String catatan;

  const DisiplinModel({
    required this.tanggal,
    required this.jenisPelanggaran,
    this.catatan = '',
  });

  factory DisiplinModel.fromJson(Map<String, dynamic> j) => DisiplinModel(
        tanggal: DateTime.parse(j['tanggal'] as String),
        jenisPelanggaran: j['jenis_pelanggaran'] as String,
        catatan: (j['catatan'] as String?) ?? '',
      );
}

class DisiplinResult {
  final String tahunAjaran;
  final int total;
  final List<DisiplinModel> items;

  const DisiplinResult({
    required this.tahunAjaran,
    required this.total,
    required this.items,
  });

  factory DisiplinResult.fromJson(Map<String, dynamic> j) => DisiplinResult(
        tahunAjaran: j['tahun_ajaran'] as String,
        total: (j['total'] as num).toInt(),
        items: (j['items'] as List)
            .map((e) => DisiplinModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
