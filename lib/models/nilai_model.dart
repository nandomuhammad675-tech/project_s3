import 'package:si_kesa/utils/json_helper.dart';

/// Nilai satu mata pelajaran pada satu semester. Jenis penilaian: UH (bernomor), ASTS, ASAS.
class NilaiMapel {
  final int idMapel;
  final String mapel;
  final String semester; // ganjil | genap
  final List<int?> uh; // indeks 0 = UH-1; null = belum ada nilai
  final int? asts;
  final int? asas;

  const NilaiMapel({
    this.idMapel = 0,
    required this.mapel,
    this.semester = 'ganjil',
    this.uh = const [],
    this.asts,
    this.asas,
  });

  factory NilaiMapel.fromJson(Map<String, dynamic> j) {
    final daftar = (j['uh'] as List? ?? const [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // UH dipetakan menurut nomor_uh agar kolom UH-n tidak bergeser bila ada nomor yang kosong.
    var maks = 0;
    for (final e in daftar) {
      final n = asInt(e['nomor_uh']) ?? 0;
      if (n > maks && n <= 50) maks = n;
    }
    final uh = List<int?>.filled(maks, null);
    for (final e in daftar) {
      final n = asInt(e['nomor_uh']) ?? 0;
      if (n >= 1 && n <= maks) uh[n - 1] = asInt(e['nilai']);
    }

    return NilaiMapel(
      idMapel: asInt(j['id_mapel']) ?? 0,
      mapel: j['nama_mapel'] as String,
      semester: j['semester'] as String,
      uh: uh,
      asts: asInt(j['asts']),
      asas: asInt(j['asas']),
    );
  }
}

class NilaiResult {
  final String tahunAjaran;
  final String semesterAktif;
  final List<NilaiMapel> items;

  const NilaiResult({
    required this.tahunAjaran,
    required this.semesterAktif,
    required this.items,
  });

  factory NilaiResult.fromJson(Map<String, dynamic> j) => NilaiResult(
        tahunAjaran: j['tahun_ajaran'] as String,
        semesterAktif: j['semester_aktif'] as String,
        items: (j['items'] as List)
            .map((e) => NilaiMapel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
