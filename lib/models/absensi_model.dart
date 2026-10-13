/// Nilai status sama dengan API: hadir, sakit, izin, alpa (bukan "alfa").
enum StatusKehadiran { hadir, sakit, izin, alpa }

class AbsensiModel {
  final DateTime tanggal;
  final StatusKehadiran status;
  final String semester; // 'ganjil' | 'genap'

  const AbsensiModel({
    required this.tanggal,
    required this.status,
    required this.semester,
  });

  factory AbsensiModel.fromJson(Map<String, dynamic> j) {
    final s = j['status'] as String;
    final tgl = DateTime.parse(j['tanggal'] as String);
    return AbsensiModel(
      tanggal: tgl,
      // cadangan bila server tidak mengirim semester: Jul-Des ganjil, Jan-Jun genap
      semester: (j['semester'] as String?) ?? (tgl.month >= 7 ? 'ganjil' : 'genap'),
      status: StatusKehadiran.values.firstWhere(
        (e) => e.name == s,
        orElse: () => throw FormatException('Status absensi tidak dikenal: $s'),
      ),
    );
  }
}

class AbsensiResult {
  final String tahunAjaran;
  final String semesterAktif;
  final List<AbsensiModel> items;

  const AbsensiResult({
    required this.tahunAjaran,
    required this.semesterAktif,
    required this.items,
  });

  factory AbsensiResult.fromJson(Map<String, dynamic> j) => AbsensiResult(
        tahunAjaran: j['tahun_ajaran'] as String,
        semesterAktif: j['semester_aktif'] as String,
        items: (j['items'] as List)
            .map((e) => AbsensiModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Status absensi kelas pada satu tanggal, untuk kartu di Beranda Guru.
enum StatusAbsensiHari { sudah, belum, libur }

/// GET /api/guru/dasbor/absensi?date=YYYY-MM-DD.
/// CATATAN: bentuk respons belum ada di dokumen yang saya baca; parser ini menerima `status`
/// ("sudah"/"belum"/"libur") atau penanda boolean. Cocokkan dengan KONTRAK_API.md.
StatusAbsensiHari bacaStatusAbsensiHari(Map<String, dynamic> j) {
  if (j['libur'] == true) return StatusAbsensiHari.libur;
  final s = '${j['status'] ?? ''}'.toLowerCase();
  if (s.contains('libur')) return StatusAbsensiHari.libur;
  if (s.startsWith('sudah')) return StatusAbsensiHari.sudah;
  if (s.startsWith('belum')) return StatusAbsensiHari.belum;
  if (j['sudah_absen'] == true || j['sudah'] == true || j['terisi'] == true) {
    return StatusAbsensiHari.sudah;
  }
  return StatusAbsensiHari.belum;
}