import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/guru_disiplin_model.dart';
import 'package:si_kesa/models/guru_model.dart';
import 'package:si_kesa/models/kelas_model.dart';
import 'package:si_kesa/models/mapel_model.dart';
import 'package:si_kesa/models/nilai_guru_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/disiplin_service.dart';
import 'package:si_kesa/services/guru_service.dart';
import 'package:si_kesa/services/nilai_service.dart';
import 'package:si_kesa/utils/ui_helper.dart';
import 'package:si_kesa/widgets/empty_state.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';

/// Rekap Per Mapel (hanya baca): pilih mata pelajaran dan semester, lihat nilai UH, ASTS, ASAS semua siswa kelas.
/// Tombol Unduh Laporan hanya tampilan (Laporan Excel tidak ada di aplikasi Guru, Dokumen 02 bagian 1.1).
class RekapPerMapelScreen extends StatefulWidget {
  const RekapPerMapelScreen({super.key});

  @override
  State<RekapPerMapelScreen> createState() => _RekapPerMapelScreenState();
}

class _RekapPerMapelScreenState extends State<RekapPerMapelScreen> {
  static const _lebarKiri = 176.0;
  static const _lebarNilai = 58.0;
  static const _tinggiKepala = 44.0;
  static const _tinggiBaris = 52.0;

  KelasModel? _kelas;
  List<MapelModel> _mapel = const [];
  List<SiswaKelasModel> _siswa = const [];
  List<NilaiGuruBaris> _nilai = const [];
  Map<String, int> _peta = const {}; // kunci: "idSiswa|UH|nomor" atau "idSiswa|ASTS|0"

  int? _idMapel;
  String _semester = 'ganjil';

  bool _memuat = true;
  String? _galat;
  bool _memuatNilai = false;
  String? _galatNilai;
  int _versi = 0; // menolak jawaban lama bila pilihan diganti cepat

  @override
  void initState() {
    super.initState();
    _muatAwal();
  }

  // ===================== Data =====================

  Future<void> _muatAwal({bool tarik = false}) async {
    if (!tarik) {
      setState(() {
        _memuat = true;
        _galat = null;
      });
    }
    try {
      final h = await Future.wait<dynamic>([
        GuruService.me(),
        NilaiService.mapel(),
        DisiplinService.siswa(),
      ]);
      if (!mounted) return;
      final kelas = (h[0] as GuruModel).kelas;
      final mapel = h[1] as List<MapelModel>;
      setState(() {
        _kelas = kelas;
        _mapel = mapel;
        _siswa = h[2] as List<SiswaKelasModel>;
        if (kelas != null && (kelas.semester == 'ganjil' || kelas.semester == 'genap')) {
          _semester = kelas.semester;
        }
        if (_idMapel == null || !mapel.any((m) => m.id == _idMapel)) {
          _idMapel = mapel.isEmpty ? null : mapel.first.id;
        }
        _memuat = false;
        _galat = null;
      });
      await _muatNilai(tarik: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galat = pesanDariError(e);
        _memuat = false;
      });
    }
  }

  Future<void> _muatNilai({bool tarik = false}) async {
    final idMapel = _idMapel;
    if (idMapel == null) return;
    final versi = ++_versi;
    if (!tarik) {
      setState(() {
        _memuatNilai = true;
        _galatNilai = null;
      });
    }
    try {
      final h = await NilaiService.daftar(idMapel: idMapel, semester: _semester);
      if (!mounted || versi != _versi) return;
      final peta = <String, int>{};
      for (final b in h) {
        peta['${b.idSiswa}|${b.jenis}|${b.jenis == 'UH' ? (b.nomorUh ?? 0) : 0}'] = b.nilai;
      }
      setState(() {
        _nilai = h;
        _peta = peta;
        _memuatNilai = false;
        _galatNilai = null;
      });
    } catch (e) {
      if (!mounted || versi != _versi) return;
      setState(() {
        _galatNilai = pesanDariError(e);
        _memuatNilai = false;
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

  String _teksSemester(String s) {
    final label = s == 'genap' ? 'Genap' : 'Ganjil';
    return '$label ${_kelas?.tahunAjaran ?? ''}'.trim();
  }

  // ===================== Tampilan =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(title: 'Rekap Per Mapel', builder: _isiLayar),
    );
  }

  Widget _isiLayar(double tinggiHeader) {
    return RefreshIndicator(
      color: AppColors.primary,
      edgeOffset: tinggiHeader,
      onRefresh: () => _muatAwal(tarik: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, tinggiHeader + 16, 16, 24),
        children: _isi(),
      ),
    );
  }

  List<Widget> _isi() {
    if (_memuat) {
      return const [Padding(padding: EdgeInsets.symmetric(vertical: 60), child: LoadingIndicator())];
    }
    if (_galat != null) {
      return [ErrorState(message: _galat!, onRetry: _muatAwal)];
    }
    if (_kelas == null) {
      return const [
        EmptyState(
          message: 'Anda belum ditetapkan sebagai wali kelas pada tahun ajaran aktif. Hubungi Admin.',
          icon: Icons.info_outline,
        ),
      ];
    }
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _kartuPilihan(
              'Pilih Mata Pelajaran',
              _dropdown<int>(
                nilai: _idMapel,
                petunjuk: 'Pilih',
                pilihan: [for (final m in _mapel) (m.id, m.nama)],
                saatUbah: (v) {
                  if (v == null || v == _idMapel) return;
                  setState(() => _idMapel = v);
                  _muatNilai();
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _kartuPilihan(
              'Pilih Semester',
              _dropdown<String>(
                nilai: _semester,
                pilihan: [('ganjil', _teksSemester('ganjil')), ('genap', _teksSemester('genap'))],
                saatUbah: (v) {
                  if (v == null || v == _semester) return;
                  setState(() => _semester = v);
                  _muatNilai();
                },
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _isiTabel(),
      const SizedBox(height: 22),
      _tombolUnduh(),
    ];
  }

  Widget _kartuPilihan(String label, Widget isi) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.headerGreen),
          ),
          const SizedBox(height: 6),
          isi,
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required T? nilai,
    required List<(T, String)> pilihan,
    required ValueChanged<T?> saatUbah,
    String? petunjuk,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: nilai,
          isExpanded: true,
          hint: petunjuk == null
              ? null
              : Text(petunjuk, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
          style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontFamily: 'Poppins'),
          items: [
            for (final p in pilihan)
              DropdownMenuItem<T>(
                value: p.$1,
                child: Text(p.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: saatUbah,
        ),
      ),
    );
  }

  Widget _isiTabel() {
    if (_idMapel == null) {
      return const EmptyState(message: 'Belum ada mata pelajaran.');
    }
    if (_siswa.isEmpty) {
      return const EmptyState(message: 'Belum ada siswa aktif di kelas ini.');
    }
    if (_memuatNilai) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingIndicator());
    }
    if (_galatNilai != null) {
      return ErrorState(message: _galatNilai!, onRetry: _muatNilai);
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
          // Kiri (tetap): No. dan Nama Siswa
          Container(
            width: _lebarKiri,
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFEFEBDD)))),
            child: Column(
              children: [
                _kepalaKiri(),
                for (var i = 0; i < _siswa.length; i++) _barisKiri(_siswa[i], i, i == _siswa.length - 1),
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
                  for (var i = 0; i < _siswa.length; i++)
                    _barisKanan(_siswa[i], kolom, i == _siswa.length - 1),
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: const Row(
        children: [
          SizedBox(width: 32, child: Text('No.', style: _gayaKepala)),
          Expanded(child: Text('Nama Siswa', style: _gayaKepala)),
        ],
      ),
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

  Widget _barisKiri(SiswaKelasModel s, int i, bool terakhir) {
    return Container(
      height: _tinggiBaris,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: _garis(terakhir),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${s.nomorAbsen ?? i + 1}.',
              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
            ),
          ),
          Expanded(
            child: Text(
              s.nama,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisKanan(SiswaKelasModel s, List<(String, String, int)> kolom, bool terakhir) {
    return Container(
      height: _tinggiBaris,
      decoration: _garis(terakhir),
      child: Row(
        children: [
          for (final k in kolom)
            SizedBox(
              width: _lebarNilai,
              child: Center(child: _sel(_peta['${s.idSiswa}|${k.$2}|${k.$3}'])),
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

  Widget _tombolUnduh() {
    return Material(
      color: AppColors.headerGreen,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => tampilkanBelumTersedia(context, 'Unduh Laporan'),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.file_download_outlined, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Unduh Laporan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}