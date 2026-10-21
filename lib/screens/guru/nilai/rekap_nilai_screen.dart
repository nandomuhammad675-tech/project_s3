import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/guru_disiplin_model.dart';
import 'package:si_kesa/models/guru_model.dart';
import 'package:si_kesa/models/kelas_model.dart';
import 'package:si_kesa/screens/guru/nilai/detail_rekap_nilai_screen.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/disiplin_service.dart';
import 'package:si_kesa/services/guru_service.dart';
import 'package:si_kesa/widgets/empty_state.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';

/// Rekap Nilai Guru: daftar siswa aktif kelas sendiri (bisa dicari). Ketuk siswa untuk melihat rinciannya.
class RekapNilaiGuruScreen extends StatefulWidget {
  const RekapNilaiGuruScreen({super.key});

  @override
  State<RekapNilaiGuruScreen> createState() => _RekapNilaiGuruScreenState();
}

class _RekapNilaiGuruScreenState extends State<RekapNilaiGuruScreen> {
  final _cari = TextEditingController();
  String _kata = '';

  KelasModel? _kelas;
  List<SiswaKelasModel> _siswa = const [];
  bool _memuat = true;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  /// [tarik] true = penyegaran tarik-layar (tanpa mengganti layar dengan indikator).
  Future<void> _muat({bool tarik = false}) async {
    if (!tarik) {
      setState(() {
        _memuat = true;
        _galat = null;
      });
    }
    try {
      final h = await Future.wait<dynamic>([
        GuruService.me(),
        DisiplinService.siswa(),
      ]);
      if (!mounted) return;
      setState(() {
        _kelas = (h[0] as GuruModel).kelas;
        _siswa = h[1] as List<SiswaKelasModel>;
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

  void _buka(SiswaKelasModel s) {
    final kelas = _kelas;
    if (kelas == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailRekapNilaiScreen(siswa: s, kelas: kelas)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(title: 'Rekap Nilai', builder: _isiLayar),
    );
  }

  Widget _isiLayar(double tinggiHeader) {
    return RefreshIndicator(
      color: AppColors.primary,
      edgeOffset: tinggiHeader,
      onRefresh: () => _muat(tarik: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, tinggiHeader + 16, 16, 24),
        children: [
          const Text(
            'Pilih Siswa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          _kolomCari(),
          const SizedBox(height: 14),
          _isiDaftar(),
        ],
      ),
    );
  }

  Widget _kolomCari() {
    return TextField(
      controller: _cari,
      onChanged: (v) => setState(() => _kata = v.trim().toLowerCase()),
      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Cari Nama Siswa...',
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textDark),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.headerGreen),
        ),
      ),
    );
  }

  Widget _isiDaftar() {
    if (_memuat) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingIndicator());
    }
    if (_galat != null) {
      return ErrorState(message: _galat!, onRetry: _muat);
    }
    if (_kelas == null) {
      return const EmptyState(
        message: 'Anda belum ditetapkan sebagai wali kelas pada tahun ajaran aktif. Hubungi Admin.',
        icon: Icons.info_outline,
      );
    }
    if (_siswa.isEmpty) {
      return const EmptyState(message: 'Belum ada siswa aktif di kelas ini.');
    }
    final tampil = [
      for (var i = 0; i < _siswa.length; i++)
        if (_kata.isEmpty || _siswa[i].nama.toLowerCase().contains(_kata)) (i, _siswa[i]),
    ];
    if (tampil.isEmpty) {
      return const EmptyState(message: 'Siswa tidak ditemukan.', icon: Icons.search_off);
    }
    return Column(
      children: [
        for (final t in tampil) _kartuSiswa(t.$2, t.$1),
      ],
    );
  }

  Widget _kartuSiswa(SiswaKelasModel s, int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _buka(s),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.headerGreen, shape: BoxShape.circle),
                  child: Text(
                    '${s.nomorAbsen ?? i + 1}.',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Detail', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.textDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}