import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/guru_disiplin_model.dart';
import 'package:si_kesa/models/kelas_model.dart';
import 'package:si_kesa/models/mapel_model.dart';
import 'package:si_kesa/models/nilai_guru_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/nilai_service.dart';
import 'package:si_kesa/utils/ui_helper.dart';
import 'package:si_kesa/widgets/empty_state.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';

/// Rincian nilai satu siswa pada semester berjalan: tab UH / ASTS / ASAS, baris per mata pelajaran.
/// Hanya baca. Tombol Expor hanya tampilan (Laporan Excel tidak ada di aplikasi Guru, Dokumen 02 bagian 1.1).
class DetailRekapNilaiScreen extends StatefulWidget {
  final SiswaKelasModel siswa;
  final KelasModel kelas;

  const DetailRekapNilaiScreen({super.key, required this.siswa, required this.kelas});

  @override
  State<DetailRekapNilaiScreen> createState() => _DetailRekapNilaiScreenState();
}

class _DetailRekapNilaiScreenState extends State<DetailRekapNilaiScreen> {
  static const _jenisList = ['UH', 'ASTS', 'ASAS'];
  static const _lebarNilai = 52.0;
  static const _lebarMapelMin = 130.0;

  String _jenis = 'UH';
  List<MapelModel> _mapel = const [];
  List<NilaiGuruBaris> _nilai = const [];
  bool _memuat = true;
  String? _galat;

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
      setState(() {
        _mapel = h[0] as List<MapelModel>;
        _nilai = h[1] as List<NilaiGuruBaris>;
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

  /// Label kolom untuk tab terpilih: UH-1..UH-n, atau satu kolom untuk ASTS/ASAS.
  List<String> _kolom() {
    if (_jenis != 'UH') return [_jenis];
    var maks = 3; // desain menampilkan minimal UH-1 sampai UH-3
    for (final b in _nilai) {
      if (b.jenis == 'UH' && (b.nomorUh ?? 0) > maks && (b.nomorUh ?? 0) <= 50) maks = b.nomorUh!;
    }
    return [for (var i = 1; i <= maks; i++) 'UH-$i'];
  }

  int? _nilaiDari(int idMapel, int indeksKolom) {
    for (final b in _nilai) {
      if (b.idMapel != idMapel || b.jenis != _jenis) continue;
      if (_jenis == 'UH' && b.nomorUh != indeksKolom + 1) continue;
      return b.nilai;
    }
    return null;
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
          const SizedBox(height: 14),
          _tab(),
          const SizedBox(height: 14),
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

  Widget _tab() {
    return Row(
      children: [
        for (var i = 0; i < _jenisList.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _tombolTab(_jenisList[i])),
        ],
      ],
    );
  }

  Widget _tombolTab(String jenis) {
    final aktif = jenis == _jenis;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _jenis = jenis),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: aktif ? AppColors.headerGreen : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: aktif ? AppColors.headerGreen : AppColors.accentOrange),
        ),
        child: Text(
          jenis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: aktif ? Colors.white : AppColors.accentOrange,
          ),
        ),
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
    return _tabel();
  }

  Widget _tabel() {
    final kolom = _kolom();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, box) {
          final lebarMapel = math.max(_lebarMapelMin, box.maxWidth - kolom.length * _lebarNilai);
          final total = lebarMapel + kolom.length * _lebarNilai;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: total,
              child: Column(
                children: [
                  _barisKepala(kolom, lebarMapel),
                  for (var i = 0; i < _mapel.length; i++)
                    _barisMapel(_mapel[i], kolom.length, lebarMapel, i == _mapel.length - 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _barisKepala(List<String> kolom, double lebarMapel) {
    const gaya = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark);
    return Container(
      color: AppColors.cardBeige,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: lebarMapel,
            child: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text('Mata Pelajaran', style: gaya),
            ),
          ),
          for (final k in kolom)
            SizedBox(width: _lebarNilai, child: Text(k, textAlign: TextAlign.center, style: gaya)),
        ],
      ),
    );
  }

  Widget _barisMapel(MapelModel m, int jumlahKolom, double lebarMapel, bool terakhir) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      decoration: BoxDecoration(
        border: terakhir ? null : const Border(bottom: BorderSide(color: Color(0xFFEFEBDD))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: lebarMapel,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                m.nama,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
            ),
          ),
          for (var i = 0; i < jumlahKolom; i++)
            SizedBox(width: _lebarNilai, child: Center(child: _sel(_nilaiDari(m.id, i)))),
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
        onTap: () => tampilkanBelumTersedia(context, 'Expor Nilai Siswa'),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: const Row(
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