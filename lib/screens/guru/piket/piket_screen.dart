import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/guru_disiplin_model.dart';
import 'package:si_kesa/models/piket_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/piket_service.dart';
import 'package:si_kesa/utils/date_formatter.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';

/// Jadwal Piket Guru: form tambah/ubah piket per hari + enam kartu hari (Senin sampai Sabtu).
/// Memilih hari yang sudah punya piket otomatis membuka mode ubah (satu piket per hari).
class PiketGuruScreen extends StatefulWidget {
  const PiketGuruScreen({super.key});

  @override
  State<PiketGuruScreen> createState() => _PiketGuruScreenState();
}

class _PiketGuruScreenState extends State<PiketGuruScreen> {
  static const _hariApi = ['senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu'];
  static const _namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  List<PiketModel> _piket = const [];
  List<SiswaKelasModel> _siswa = const [];
  bool _memuat = true;
  String? _galatMuat;

  String? _hari; // hari yang sedang dikerjakan di form
  PiketModel? _diubah; // null = mode tambah
  final List<int> _terpilih = []; // id siswa bertugas, urut sesuai pemilihan
  bool _menyimpan = false;
  String? _pesan;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ===================== Data =====================

  /// [senyap] true = muat ulang tanpa mengganti layar dengan indikator/galat (setelah simpan).
  Future<void> _muat({bool senyap = false}) async {
    try {
      final hasil = await Future.wait<dynamic>([
        PiketService.daftar(),
        PiketService.siswa(),
      ]);
      if (!mounted) return;
      setState(() {
        _piket = hasil[0] as List<PiketModel>;
        _siswa = hasil[1] as List<SiswaKelasModel>;
        _memuat = false;
        _galatMuat = null;
      });
    } catch (e) {
      if (!mounted || senyap) return;
      setState(() {
        _galatMuat = pesanDariError(e);
        _memuat = false;
      });
    }
  }

  void _cobaLagi() {
    setState(() {
      _memuat = true;
      _galatMuat = null;
    });
    _muat();
  }

  PiketModel? _cari(String hari) {
    for (final p in _piket) {
      if (p.hari == hari) return p;
    }
    return null;
  }

  String _namaSiswa(int id) {
    for (final s in _siswa) {
      if (s.idSiswa == id) return s.nama;
    }
    return 'Siswa #$id';
  }

  // ===================== Form =====================

  void _reset() {
    setState(() {
      _hari = null;
      _diubah = null;
      _terpilih.clear();
      _pesan = null;
      _menyimpan = false;
    });
  }

  /// Dipakai dropdown Hari dan tombol Ubah/Tambah di kartu.
  /// Hari yang sudah punya piket -> mode ubah (siswa terisi). Hari kosong -> mode tambah.
  void _fokusHari(String hari) {
    final ada = _cari(hari);
    setState(() {
      _pesan = null;
      _hari = hari;
      if (ada != null) {
        _diubah = ada;
        _terpilih
          ..clear()
          ..addAll(ada.siswa.map((s) => s.idSiswa));
      } else {
        if (_diubah != null) _terpilih.clear(); // pindah dari mode ubah ke hari kosong
        _diubah = null;
      }
    });
  }

  void _keAtas() {
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _simpan() async {
    if (_menyimpan) return; // cegah ketukan ganda
    if (_hari == null) {
      setState(() => _pesan = 'Pilih hari terlebih dahulu.');
      return;
    }
    if (_terpilih.isEmpty) {
      setState(() => _pesan = 'Pilih minimal satu siswa piket.');
      return;
    }

    setState(() {
      _menyimpan = true;
      _pesan = null;
    });

    final mengubah = _diubah != null;
    try {
      if (mengubah) {
        await PiketService.ubah(_diubah!.idPiket, idSiswa: List.of(_terpilih));
      } else {
        await PiketService.tambah(hari: _hari!, idSiswa: List.of(_terpilih));
      }
      if (!mounted) return;
      _reset();
      _tampilkanPesan(mengubah ? 'Jadwal piket diperbarui.' : 'Jadwal piket tersimpan.');
      await _muat(senyap: true);
    } catch (e) {
      _gagal(e);
    }
  }

  Future<void> _hapus() async {
    final piket = _diubah;
    if (piket == null || _menyimpan) return;

    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus piket hari ${_namaHari[_hariApi.indexOf(piket.hari)]}?'),
        content: const Text('Daftar siswa piket hari ini ikut terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Color(0xFFFF0000))),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;

    setState(() {
      _menyimpan = true;
      _pesan = null;
    });
    try {
      await PiketService.hapus(piket.idPiket);
      if (!mounted) return;
      _reset();
      _tampilkanPesan('Jadwal piket dihapus.');
      await _muat(senyap: true);
    } catch (e) {
      _gagal(e);
    }
  }

  void _gagal(Object e) {
    if (!mounted) return;
    String pesan;
    if (e is ApiException) {
      // Tanpa kode status = jaringan putus/timeout: pilihan tetap di layar.
      pesan = e.statusCode == null
          ? 'Belum tersimpan. Periksa koneksi lalu coba lagi.'
          : (e.errors.values.firstOrNull ?? e.message);
    } else {
      pesan = pesanDariError(e);
    }
    setState(() {
      _menyimpan = false;
      _pesan = pesan;
    });
  }

  void _tampilkanPesan(String teks) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  // ===================== Tampilan =====================

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(title: 'Jadwal Piket', builder: _isiLayar),
    );
  }

  Widget _isiLayar(double tinggiHeader) {
    if (_memuat) {
      return Padding(
        padding: EdgeInsets.only(top: tinggiHeader),
        child: const LoadingIndicator(),
      );
    }
    if (_galatMuat != null) {
      return Padding(
        padding: EdgeInsets.only(top: tinggiHeader),
        child: ErrorState(message: _galatMuat!, onRetry: _cobaLagi),
      );
    }

    final sekarang = DateTime.now();
    // Minggu: tampilkan minggu depan. Selain itu: minggu berjalan.
    final awal = sekarang.weekday == DateTime.sunday
        ? sekarang.day + 1
        : sekarang.day - (sekarang.weekday - 1);
    final hariIni = sekarang.weekday == DateTime.sunday ? null : _hariApi[sekarang.weekday - 1];

    return RefreshIndicator(
      color: AppColors.primary,
      edgeOffset: tinggiHeader,
      onRefresh: () => _muat(senyap: true),
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, tinggiHeader + 20, 16, 28),
        children: [
          _kartuForm(),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.event_note, size: 24, color: AppColors.headerGreen),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jadwal Piket Mingguan Murid Minggu Ini',
                  style: TextStyle(fontSize: 13, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _hariApi.length; i++)
            _kartuHari(
              i,
              DateTime(sekarang.year, sekarang.month, awal + i),
              _hariApi[i] == hariIni,
            ),
        ],
      ),
    );
  }

  Widget _kartuForm() {
    final mengubah = _diubah != null;
    final sisa = _siswa.where((s) => !_terpilih.contains(s.idSiswa)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.cleaning_services, size: 28, color: AppColors.headerGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mengubah ? 'Ubah Jadwal Piket' : 'Tambah Jadwal Piket',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tentukan siswa piket untuk hari tertentu',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Hari'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: _kotak(),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _hari,
                hint: const Text('Pilih Hari', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                items: [
                  for (var i = 0; i < _hariApi.length; i++)
                    DropdownMenuItem<String>(value: _hariApi[i], child: Text(_namaHari[i])),
                ],
                onChanged: _menyimpan ? null : (v) => v == null ? null : _fokusHari(v),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label('Siswa Piket'),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
            decoration: _kotak(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_terpilih.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _terpilih.map(_chip).toList(),
                    ),
                  ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: null, // selalu menampilkan hint; pilihan masuk ke chip di atas
                    hint: Text(
                      sisa.isEmpty ? 'Semua murid sudah dipilih' : '+ Tambah Murid',
                      style: const TextStyle(fontSize: 14, color: AppColors.textHint),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
                    style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                    items: sisa
                        .map((s) => DropdownMenuItem<int>(
                              value: s.idSiswa,
                              child: Text(s.label, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: _menyimpan
                        ? null
                        : (v) {
                            if (v != null) setState(() => _terpilih.add(v));
                          },
                  ),
                ),
              ],
            ),
          ),
          if (_pesan != null) ...[
            const SizedBox(height: 12),
            Text(_pesan!, style: const TextStyle(fontSize: 13, color: AppColors.accentRed)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _menyimpan ? null : _reset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      backgroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _menyimpan ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: _menyimpan
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            mengubah ? 'Simpan' : 'Simpan',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (mengubah)
            Center(
              child: TextButton.icon(
                onPressed: _menyimpan ? null : _hapus,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Hapus Jadwal'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(int id) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 12, 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E2D3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _menyimpan ? null : () => setState(() => _terpilih.remove(id)),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: AppColors.textDark),
            ),
          ),
          Flexible(
            child: Text(
              _namaSiswa(id),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textTab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuHari(int i, DateTime tanggal, bool hariIni) {
    final api = _hariApi[i];
    final p = _cari(api);
    final dikerjakan = _hari == api;
    final adaSiswa = p != null && p.siswa.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dikerjakan ? AppColors.primary : AppColors.border,
          width: dikerjakan ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _namaHari[i],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (hariIni) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F1DC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Hari ini',
                          style: TextStyle(fontSize: 11, color: AppColors.success),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${tanggal.day} ${DateFormatter.bulanTahun(tanggal)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Text(
                  adaSiswa ? p.namaSiswa : 'Belum ada siswa piket',
                  style: TextStyle(
                    fontSize: 13,
                    color: adaSiswa ? AppColors.textDark : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _menyimpan
                ? null
                : () {
                    _fokusHari(api);
                    _keAtas();
                  },
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD9DDF7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    p == null ? Icons.add : Icons.edit,
                    size: 14,
                    color: const Color(0xFF3B4BB8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    p == null ? 'Tambah' : 'Ubah',
                    style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        teks,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  BoxDecoration _kotak() => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      );
}