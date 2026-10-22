import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/guru_disiplin_model.dart';
import 'package:si_kesa/models/kelas_model.dart';
import 'package:si_kesa/models/mapel_model.dart';
import 'package:si_kesa/models/nilai_guru_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/laporan_service.dart';
import 'package:si_kesa/services/nilai_service.dart';
import 'package:si_kesa/utils/berkas_helper.dart';
import 'package:si_kesa/widgets/empty_state.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';

/// Rincian nilai satu siswa pada semester berjalan: satu tabel berisi semua mata pelajaran
/// dengan kolom UH-1.., ASTS, dan ASAS. Hanya baca; tombol Expor mengunduh Excel nilai siswa ini.
class DetailRekapNilaiScreen extends StatefulWidget {
  final SiswaKelasModel siswa;
  final KelasModel kelas;

  const DetailRekapNilaiScreen({super.key, required this.siswa, required this.kelas});

  @override
  State<DetailRekapNilaiScreen> createState() => _DetailRekapNilaiScreenState();
}

class _DetailRekapNilaiScreenState extends State<DetailRekapNilaiScreen> {
  static const _lebarKiri = 150.0;
  static const _lebarNilai = 56.0;
  static const _tinggiKepala = 44.0;
  static const _tinggiBaris = 60.0;

  List<MapelModel> _mapel = const [];
  List<NilaiGuruBaris> _nilai = const [];
  Map<String, int> _peta = const {}; // kunci: "idMapel|UH|nomor" atau "idMapel|ASTS|0"
  bool _memuat = true;
  String? _galat;
  bool _mengunduh = false;

  String get _semester => widget.kelas.semester == 'genap' ? 'genap' : 'ganjil';

  String get _teksSemester {
    final label = _semester == 'genap' ? 'Genap' : 'Ganjil';
    return 'Semester $label ${widget.kelas.tahunAjaran}'.trim();
  }

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat({bool tarik = false}) async {
    if (!tarik) {
      setState(() {
        _memuat = true;
        _galat = null;
      });
    }
    try {
      final h = await Future.wait<dynamic>([
        NilaiService.mapel(),
        NilaiService.daftar(idSiswa: widget.siswa.idSiswa, semester: _semester),
      ]);
      if (!mounted) return;
      final nilai = h[1] as List<NilaiGuruBaris>;
      final peta = <String, int>{};
      for (final b in nilai) {
        peta['${b.idMapel}|${b.jenis}|${b.jenis == 'UH' ? (b.nomorUh ?? 0) : 0}'] = b.nilai;
      }
      setState(() {
        _mapel = h[0] as List<MapelModel>;
        _nilai = nilai;
        _peta = peta;
        _memuat = false;
        _galat = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galat = pesanDariError(e);
        _memuat = false;
      });
    }
  }

  /// Jumlah kolom UH: minimal 3, bertambah bila ada UH dengan nomor lebih besar.
  int get _jumlahUh {
    var maks = 3;
    for (final b in _nilai) {
      final n = b.nomorUh ?? 0;
      if (b.jenis == 'UH' && n > maks && n <= 50) maks = n;
    }
    return maks;
  }

  void _info(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  /// Unduh Excel nilai siswa ini (semua mapel), lalu buka menu Bagikan.
  Future<void> _unduh() async {
    if (_mengunduh) return; // cegah ketukan ganda
    final kelas = widget.kelas;
    if (kelas.idTahunAjaran == 0) {
      _info('Data kelas belum lengkap. Kembali ke daftar siswa lalu coba lagi.');
      return;
    }
    setState(() => _mengunduh = true);
    try {
      final bytes = await LaporanService.unduh(
        idTahunAjaran: kelas.idTahunAjaran,
        semester: _semester,
        jenis: 'nilai',
        idSiswa: widget.siswa.idSiswa,
      );
      if (!mounted) return;
      await bagikanExcel(
        bytes,
        'Rekap-Nilai-${namaBerkasAman(widget.siswa.nama)}-$_semester-${namaBerkasAman(kelas.tahunAjaran)}.xlsx',
      );
    } catch (e) {
      if (!mounted) return;
      _info(pesanDariError(e));
    } finally {
      if (mounted) setState(() => _mengunduh = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(title: 'Detail Rekap Nilai', builder: _isiLayar),
    );
  }

  Widget _isiLayar(double tinggiHeader) {
    return RefreshIndicator(
      color: AppColors.primary,
      edgeOffset: tinggiHeader,
      onRefresh: () => _muat(tarik: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, tinggiHeader + 16, 16, 24),
        children: [
          _kartuSiswa(),
          const SizedBox(height: 16),
          _isiTabel(),
          const SizedBox(height: 18),
          _tombolExport(),
        ],
      ),
    );
  }

  Widget _kartuSiswa() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6E3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5E0B5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.headerGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.siswa.nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelas ${widget.kelas.nama}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                ),
                Text(
                  _teksSemester,
                  style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _isiTabel() {
    if (_memuat) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingIndicator());
    }
    if (_galat != null) {
      return ErrorState(message: _galat!, onRetry: _muat);
    }
    if (_mapel.isEmpty) {
      return const EmptyState(message: 'Belum ada mata pelajaran.');
    }
    return Column(
      children: [
        _tabel(),
        if (_nilai.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Belum ada nilai pada semester ini.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _tabel() {
    final kolom = <(String, String, int)>[
      for (var i = 1; i <= _jumlahUh; i++) ('UH-$i', 'UH', i),
      ('ASTS', 'ASTS', 0),
      ('ASAS', 'ASAS', 0),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kiri (tetap): Mata Pelajaran
          Container(
            width: _lebarKiri,
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFEFEBDD)))),
            child: Column(
              children: [
                _kepalaKiri(),
                for (var i = 0; i < _mapel.length; i++) _barisKiri(_mapel[i], i == _mapel.length - 1),
              ],
            ),
          ),
          // Kanan (bisa digeser): UH-1.., ASTS, ASAS
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  _kepalaKanan(kolom),
                  for (var i = 0; i < _mapel.length; i++)
                    _barisKanan(_mapel[i], kolom, i == _mapel.length - 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _gayaKepala =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark);

  Widget _kepalaKiri() {
    return Container(
      height: _tinggiKepala,
      color: AppColors.cardBeige,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Text('Mata Pelajaran', style: _gayaKepala),
    );
  }

  Widget _kepalaKanan(List<(String, String, int)> kolom) {
    return Container(
      height: _tinggiKepala,
      color: AppColors.cardBeige,
      child: Row(
        children: [
          for (final k in kolom)
            SizedBox(
              width: _lebarNilai,
              child: Text(k.$1, textAlign: TextAlign.center, style: _gayaKepala),
            ),
        ],
      ),
    );
  }

  BoxDecoration _garis(bool terakhir) => BoxDecoration(
        border: terakhir ? null : const Border(bottom: BorderSide(color: Color(0xFFEFEBDD))),
      );

  Widget _barisKiri(MapelModel m, bool terakhir) {
    return Container(
      height: _tinggiBaris,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _garis(terakhir),
      child: Text(
        m.nama,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11.5,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _barisKanan(MapelModel m, List<(String, String, int)> kolom, bool terakhir) {
    return Container(
      height: _tinggiBaris,
      decoration: _garis(terakhir),
      child: Row(
        children: [
          for (final k in kolom)
            SizedBox(
              width: _lebarNilai,
              child: Center(child: _sel(_peta['${m.id}|${k.$2}|${k.$3}'])),
            ),
        ],
      ),
    );
  }

  Widget _sel(int? nilai) {
    if (nilai == null) {
      return const Text('-', style: TextStyle(fontSize: 13, color: AppColors.textMuted));
    }
    return Text(
      '$nilai',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentOrange),
    );
  }

  Widget _tombolExport() {
    return Material(
      color: AppColors.headerGreen,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: _mengunduh ? null : _unduh,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: _mengunduh
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.file_download_outlined, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Expor Nilai Siswa',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}