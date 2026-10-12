import 'package:flutter_test/flutter_test.dart';
import 'package:si_kesa/models/absensi_model.dart';
import 'package:si_kesa/models/disiplin_model.dart';
import 'package:si_kesa/models/nilai_model.dart';
import 'package:si_kesa/models/siswa_model.dart';

// Uji pemetaan JSON API -> model (KONTRAK_API.md bagian 3). Tidak memakai plugin atau jaringan.
void main() {
  group('NilaiMapel', () {
    test('UH dipetakan menurut nomor_uh; ASTS dan ASAS terbaca', () {
      final m = NilaiMapel.fromJson({
        'id_mapel': 3,
        'nama_mapel': 'Matematika',
        'semester': 'ganjil',
        'uh': [
          {'nomor_uh': 1, 'nilai': 80},
          {'nomor_uh': 3, 'nilai': 90},
        ],
        'asts': 85,
        'asas': null,
      });
      expect(m.uh, [80, null, 90]);
      expect(m.asts, 85);
      expect(m.asas, isNull);
      expect(m.semester, 'ganjil');
    });

    test('tanpa UH menghasilkan daftar kosong', () {
      final m = NilaiMapel.fromJson({
        'id_mapel': 1,
        'nama_mapel': 'IPA',
        'semester': 'genap',
        'uh': [],
        'asts': null,
        'asas': null,
      });
      expect(m.uh, isEmpty);
    });

    test('NilaiResult membaca semester_aktif dan items', () {
      final r = NilaiResult.fromJson({
        'tahun_ajaran': '2026/2027',
        'semester_aktif': 'ganjil',
        'items': [
          {'id_mapel': 1, 'nama_mapel': 'IPA', 'semester': 'ganjil', 'uh': [], 'asts': 70, 'asas': null},
        ],
      });
      expect(r.semesterAktif, 'ganjil');
      expect(r.items.single.asts, 70);
    });
  });

  group('AbsensiModel', () {
    test('status alpa terbaca', () {
      final a = AbsensiModel.fromJson({'tanggal': '2026-10-05', 'status': 'alpa', 'semester': 'ganjil'});
      expect(a.status, StatusKehadiran.alpa);
      expect(a.tanggal, DateTime(2026, 10, 5));
    });

    test('status "alfa" (ejaan lama) ditolak', () {
      expect(
        () => AbsensiModel.fromJson({'tanggal': '2026-10-05', 'status': 'alfa', 'semester': 'ganjil'}),
        throwsFormatException,
      );
    });
  });

  group('DisiplinModel', () {
    test('catatan terbaca', () {
      final d = DisiplinResult.fromJson({
        'tahun_ajaran': '2026/2027',
        'total': 1,
        'items': [
          {'tanggal': '2026-10-05', 'jenis_pelanggaran': 'Terlambat', 'catatan': 'Datang pukul 07.30'},
        ],
      });
      expect(d.total, 1);
      expect(d.items.single.jenisPelanggaran, 'Terlambat');
      expect(d.items.single.catatan, 'Datang pukul 07.30');
    });

    test('catatan null menjadi string kosong', () {
      final d = DisiplinModel.fromJson({'tanggal': '2026-10-05', 'jenis_pelanggaran': 'Seragam', 'catatan': null});
      expect(d.catatan, '');
    });
  });

  group('SiswaModel', () {
    final dasar = {
      'nama_siswa': 'Siswa Uji Aktif',
      'nisn': '0000000001',
      'nama_kelas': '1A',
      'tingkat_kelas': 1,
      'nomor_absen': 1,
      'tahun_ajaran': '2026/2027',
      'semester': 'ganjil',
    };

    test('nama_wali_kelas terisi', () {
      final s = SiswaModel.fromJson({...dasar, 'nama_wali_kelas': 'Guru Uji'});
      expect(s.namaWaliKelas, 'Guru Uji');
      expect(s.nisn, '0000000001');
    });

    test('nama_wali_kelas null atau tidak ada, nomor_absen null', () {
      expect(SiswaModel.fromJson({...dasar, 'nama_wali_kelas': null}).namaWaliKelas, isNull);
      final s = SiswaModel.fromJson({...dasar, 'nomor_absen': null});
      expect(s.namaWaliKelas, isNull);
      expect(s.nomorAbsen, isNull);
    });
  });
}
