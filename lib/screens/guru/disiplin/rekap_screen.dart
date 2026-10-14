import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/guru_disiplin_model.dart';
import 'package:si_kesa/screens/guru/disiplin/form_screen.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/disiplin_service.dart';
import 'package:si_kesa/utils/date_formatter.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';

/// Rekap Kedisiplinan Guru: semua catatan kelas sendiri, terbaru di atas.
/// Ketuk kartu untuk mengubah catatan. Tidak ada hapus (server tidak menyediakannya).
class RekapDisiplinGuruScreen extends StatefulWidget {
  const RekapDisiplinGuruScreen({super.key});

  @override
  State<RekapDisiplinGuruScreen> createState() => _RekapDisiplinGuruScreenState();
}

class _RekapDisiplinGuruScreenState extends State<RekapDisiplinGuruScreen> {
  List<CatatanDisiplinModel> _catatan = const [];
  bool _memuat = true;
  String? _galat;
  int? _filterSiswa; // null = semua siswa

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat({bool senyap = false}) async {
    try {
      final d = await DisiplinService.daftar();
      if (!mounted) return;
      setState(() {
        _catatan = d;
        _memuat = false;
        _galat = null;
        // Filter yang siswanya sudah tidak punya catatan dikembalikan ke "Semua".
        if (_filterSiswa != null && !d.any((c) => c.idSiswa == _filterSiswa)) {
          _filterSiswa = null;
        }
      });
    } catch (e) {
      if (!mounted || senyap) return;
      setState(() {
        _galat = pesanDariError(e);
        _memuat = false;
      });
    }
  }

  void _cobaLagi() {
    setState(() {
      _memuat = true;
      _galat = null;
    });
    _muat();
  }

  Future<void> _ubah(CatatanDisiplinModel c) async {
    final hasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DisiplinGuruScreen(catatan: c)),
    );
    if (hasil == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Catatan diperbarui.')));
      await _muat(senyap: true);
    }
  }

  /// Siswa yang punya catatan, urut nama (untuk pilihan filter).
  List<MapEntry<int, String>> get _opsiSiswa {
    final m = <int, String>{};
    for (final c in _catatan) {
      m[c.idSiswa] = c.namaSiswa;
    }
    return m.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(title: 'Rekap Kedisiplinan', builder: _isiLayar),
    );
  }

  Widget _isiLayar(double tinggiHeader) {
    if (_memuat) {
      return Padding(
        padding: EdgeInsets.only(top: tinggiHeader),
        child: const LoadingIndicator(),
      );
    }
    if (_galat != null) {
      return Padding(
        padding: EdgeInsets.only(top: tinggiHeader),
        child: ErrorState(message: _galat!, onRetry: _cobaLagi),
      );
    }

    final tampil = _catatan.where((c) => _filterSiswa == null || c.idSiswa == _filterSiswa).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      edgeOffset: tinggiHeader,
      onRefresh: () => _muat(senyap: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, tinggiHeader + 24, 20, 24),
        children: [
          const Text(
            'Rekap Kedisiplinan Siswa',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.headerGreen,
            ),
          ),
          const SizedBox(height: 20),
          if (_opsiSiswa.isNotEmpty) _filter(),
          const SizedBox(height: 8),
          if (tampil.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Belum ada catatan kedisiplinan.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...tampil.map(_item),
        ],
      ),
    );
  }

  Widget _filter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: _filterSiswa,
          hint: const Text('Semua Siswa', style: TextStyle(fontSize: 14, color: AppColors.textDark)),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Semua Siswa')),
            ..._opsiSiswa.map((e) => DropdownMenuItem<int?>(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (v) => setState(() => _filterSiswa = v),
        ),
      ),
    );
  }

  Widget _item(CatatanDisiplinModel c) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _ubah(c),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.namaSiswa,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.jenisPelanggaran,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (c.catatan.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          c.catatan,
                          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        DateFormatter.lengkap(c.tanggal),
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.edit_outlined, size: 20, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}