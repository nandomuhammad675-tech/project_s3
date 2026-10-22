import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/absensi_guru_model.dart';
import 'package:si_kesa/models/absensi_model.dart';
import 'package:si_kesa/services/absensi_service.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/utils/date_formatter.dart';
import 'package:si_kesa/widgets/empty_state.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/services/guru_service.dart';
import 'package:si_kesa/services/laporan_service.dart';
import 'package:si_kesa/utils/berkas_helper.dart';

/// Riwayat Absen Guru (hanya baca): pilih bulan, pilih tanggal, lihat status tiap siswa.
/// Data dari GET /api/guru/absensi?date= (satu panggilan per tanggal yang dibuka).
class RiwayatAbsenGuruScreen extends StatefulWidget {
  const RiwayatAbsenGuruScreen({super.key});

  @override
  State<RiwayatAbsenGuruScreen> createState() => _RiwayatAbsenGuruScreenState();
}

class _RiwayatAbsenGuruScreenState extends State<RiwayatAbsenGuruScreen> {
  static const _hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _hijauHadir = Color(0xFF43A047);

  late DateTime _bulan; // tanggal 1 pada bulan terpilih
  DateTime? _tanggal; // null = bulan ini belum punya hari efektif yang bisa dibuka
  AbsensiHari? _data;
  bool _memuat = true;
  String? _galat;
  int _versi = 0; // menolak jawaban lama bila tanggal diganti cepat
    bool _mengunduh = false;
  final _gulir = ScrollController(); // deretan tanggal  // [1]

  static DateTime _tanpaJam(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    final sekarang = DateTime.now();
    _bulan = DateTime(sekarang.year, sekarang.month);
    final hari = _hariDalamBulan(_bulan);
    _tanggal = hari.isEmpty ? null : hari.last; // bawaan: tanggal terbaru  // [4]
    if (_tanggal == null) {
      _memuat = false;
    } else {
      _muat();
      _gulirKeTanggal(); // [4]
    }
  }

  // [2] dispose + fungsi scroll
  @override
  void dispose() {
    _gulir.dispose();
    super.dispose();
  }

  /// Menggeser deretan tanggal agar tanggal terpilih terlihat (tiap kotak 52 + jarak 8).
  void _gulirKeTanggal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final t = _tanggal;
      if (t == null || !_gulir.hasClients) return;
      final i = _hariDalamBulan(_bulan).indexOf(t);
      if (i < 0) return;
      final target = (i * 60.0 - 120).clamp(0.0, _gulir.position.maxScrollExtent);
      _gulir.jumpTo(target);
    });
  }

  /// Hari efektif (bukan Minggu, bukan masa depan) pada [bulan], terlama (tanggal 1) lebih dulu.
  List<DateTime> _hariDalamBulan(DateTime bulan) {
    final hariIni = _tanpaJam(DateTime.now());
    final akhir = DateTime(bulan.year, bulan.month + 1, 0).day;
    final hasil = <DateTime>[];
    for (var i = 1; i <= akhir; i++) { // [3]
      final d = DateTime(bulan.year, bulan.month, i);
      if (d.isAfter(hariIni) || d.weekday == DateTime.sunday) continue;
      hasil.add(d);
    }
    return hasil;
  }

  /// 12 bulan terakhir, bulan ini paling atas.
  List<DateTime> _daftarBulan() {
    final n = DateTime.now();
    return [for (var i = 0; i < 12; i++) DateTime(n.year, n.month - i)];
  }

  // ===================== Data =====================

  Future<void> _muat() async {
    final tgl = _tanggal;
    if (tgl == null) return;
    final versi = ++_versi;
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final h = await AbsensiService.lihat(tgl);
      if (!mounted || versi != _versi) return;
      setState(() {
        _data = h;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted || versi != _versi) return;
      setState(() {
        _galat = pesanDariError(e);
        _memuat = false;
      });
    }
  }

  void _pilihTanggal(DateTime d) {
    if (_tanggal == d) return;
    setState(() {
      _tanggal = d;
      _data = null;
    });
    _muat();
  }

  Future<void> _pilihBulan() async {
    final dipilih = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final b in _daftarBulan())
              ListTile(
                title: Text(
                  DateFormatter.bulanTahun(b),
                  style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500),
                ),
                trailing: b == _bulan ? const Icon(Icons.check, color: AppColors.headerGreen) : null,
                onTap: () => Navigator.pop(ctx, b),
              ),
          ],
        ),
      ),
    );
    if (dipilih == null || !mounted || dipilih == _bulan) return;

    final hari = _hariDalamBulan(dipilih);
    setState(() {
      _bulan = dipilih;
      _tanggal = hari.isEmpty ? null : hari.last; // [4]
      _data = null;
      _galat = null;
      _memuat = _tanggal != null;
    });
    if (_tanggal != null) {
      _muat();
      _gulirKeTanggal(); // [4]
    }
  }

  int _hitung(StatusKehadiran st) =>
      _data?.items.where((s) => s.status == st).length ?? 0;

    void _info(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  /// Unduh Excel laporan absensi satu semester (kelas sendiri), lalu buka menu Bagikan.
  Future<void> _unduh() async {
    if (_mengunduh) return; // cegah ketukan ganda
    setState(() => _mengunduh = true);
    try {
      final guru = await GuruService.me();
      final kelas = guru.kelas;
      if (kelas == null || kelas.idTahunAjaran == 0) {
        _info('Anda belum ditetapkan sebagai wali kelas pada tahun ajaran aktif.');
        return;
      }
      final semester = kelas.semester == 'genap' ? 'genap' : 'ganjil';
      final bytes = await LaporanService.unduh(
        idTahunAjaran: kelas.idTahunAjaran,
        semester: semester,
        jenis: 'absensi',
      );
      if (!mounted) return;
      await bagikanExcel(
        bytes,
        'Laporan-Absensi-$semester-${namaBerkasAman(kelas.tahunAjaran)}-${namaBerkasAman(kelas.nama)}.xlsx',
      );
    } catch (e) {
      if (!mounted) return;
      _info(pesanDariError(e));
    } finally {
      if (mounted) setState(() => _mengunduh = false);
    }
  }
  // ===================== Tampilan =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(title: 'Riwayat Absen', builder: _isiLayar),
    );
  }

  Widget _isiLayar(double tinggiHeader) {
    return RefreshIndicator(
      color: AppColors.primary,
      edgeOffset: tinggiHeader,
      onRefresh: _muat,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, tinggiHeader + 16, 16, 24),
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _kartuBulan()),
                const SizedBox(width: 10),
                Expanded(flex: 6, child: _tombolExport()),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _barisTanggal(),
          const SizedBox(height: 14),
          _ringkasan(),
          const SizedBox(height: 18),
          const Text(
            'Daftar Siswa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          _isiDaftar(),
        ],
      ),
    );
  }

  Widget _kartuBulan() {
    return InkWell(
      onTap: _pilihBulan,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.headerGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bulan', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(
                    DateFormatter.bulanTahun(_bulan),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }

  /// Sesuai Dokumen 02 bagian 1.1, Laporan Excel tidak ada di aplikasi Guru; tombol hanya tampilan.
  Widget _tombolExport() {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _mengunduh ? null : _unduh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
                            _mengunduh
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.file_download_outlined, color: Colors.white, size: 26),
              const SizedBox(width: 6),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Laporan Semester',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      'Kelas Saya - 1 Semester',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Deretan tanggal pada bulan terpilih (tanggal 1 di kiri, terbaru di kanan).
  Widget _barisTanggal() {
    final hari = _hariDalamBulan(_bulan);
    if (hari.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 62,
      child: ListView.separated(
        controller: _gulir, // [5]
        scrollDirection: Axis.horizontal,
        itemCount: hari.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = hari[i];
          final aktif = d == _tanggal;
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _pilihTanggal(d),
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                color: aktif ? AppColors.headerGreen : AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: aktif ? AppColors.headerGreen : AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _hariPendek[d.weekday - 1],
                    style: TextStyle(
                      fontSize: 11,
                      color: aktif ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: aktif ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _ringkasan() {
    Widget kotak(String label, int jumlah, Color warna) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: warna, width: 1.6),
            ),
            child: Column(
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
                Text(
                  '$jumlah',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        kotak('Hadir', _hitung(StatusKehadiran.hadir), _hijauHadir),
        const SizedBox(width: 10),
        kotak('Izin', _hitung(StatusKehadiran.izin), AppColors.accentOrange),
        const SizedBox(width: 10),
        kotak('Sakit', _hitung(StatusKehadiran.sakit), AppColors.accentBlue),
        const SizedBox(width: 10),
        kotak('Alfa', _hitung(StatusKehadiran.alpa), AppColors.accentRed),
      ],
    );
  }

  Widget _isiDaftar() {
    if (_tanggal == null) {
      return const EmptyState(
        message: 'Belum ada hari efektif pada bulan ini.',
        icon: Icons.event_busy,
      );
    }
    if (_memuat) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingIndicator());
    }
    if (_galat != null) {
      return ErrorState(message: _galat!, onRetry: _muat);
    }
    final data = _data;
    if (data == null || data.items.isEmpty) {
      return const EmptyState(message: 'Belum ada siswa aktif di kelas ini.');
    }
    if (data.libur) {
      return const EmptyState(
        message: 'Hari libur, tidak ada absensi pada tanggal ini.',
        icon: Icons.beach_access_outlined,
      );
    }
    if (data.items.every((s) => s.status == null)) {
      return EmptyState(
        message: 'Absensi ${DateFormatter.lengkap(_tanggal!)} belum diisi.',
        icon: Icons.fact_check_outlined,
      );
    }
    return _tabel(data.items);
  }

  Widget _tabel(List<AbsensiBaris> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.cardBeige,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: const Row(
              children: [
                SizedBox(width: 34, child: Text('No.', style: _gayaKepala)),
                Expanded(child: Text('Nama Siswa', style: _gayaKepala)),
                SizedBox(
                  width: 80,
                  child: Text('Status', textAlign: TextAlign.center, style: _gayaKepala),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) _baris(items[i], i, i == items.length - 1),
        ],
      ),
    );
  }

  static const _gayaKepala =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark);

  Widget _baris(AbsensiBaris s, int i, bool terakhir) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: terakhir ? null : const Border(bottom: BorderSide(color: Color(0xFFEFEBDD))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${s.nomorAbsen ?? i + 1}.',
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
          Expanded(
            child: Text(
              s.nama,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          SizedBox(width: 80, child: Center(child: _chip(s.status))),
        ],
      ),
    );
  }

  Widget _chip(StatusKehadiran? st) {
    final (teks, warna) = switch (st) {
      StatusKehadiran.hadir => ('Hadir', _hijauHadir),
      StatusKehadiran.izin => ('Izin', const Color(0xFFFFB74D)),
      StatusKehadiran.sakit => ('Sakit', const Color(0xFF4DA3F0)),
      StatusKehadiran.alpa => ('Alfa', const Color(0xFFE57373)),
      null => ('Belum', const Color(0xFFBDBDBD)),
    };
    return Container(
      width: 70,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(13)),
      child: Text(
        teks,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}