import 'dart:async';

import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/jadwal_model.dart';
import 'package:si_kesa/models/kelas_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/guru_service.dart';
import 'package:si_kesa/services/jadwal_service.dart';
import 'package:si_kesa/utils/date_formatter.dart';
import 'package:si_kesa/widgets/empty_state.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/widgets/status_jadwal_chip.dart';

/// Semua jadwal pada satu tanggal (bawaan hari ini). Panah kiri/kanan atau ketuk tanggal untuk pindah hari.
/// Hanya baca. Status (Selesai/Berlangsung/Menunggu/Akan Datang) dihitung dari tanggal dan jam.
class JadwalHariIniGuruScreen extends StatefulWidget {
  const JadwalHariIniGuruScreen({super.key});

  @override
  State<JadwalHariIniGuruScreen> createState() => _JadwalHariIniGuruScreenState();
}

class _JadwalHariIniGuruScreenState extends State<JadwalHariIniGuruScreen> {
  late DateTime _tanggal;
  KelasModel? _kelas;
  List<JadwalModel> _jadwal = const [];
  bool _memuat = true;
  String? _galat;
  Timer? _jam;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _tanggal = DateTime(n.year, n.month, n.day);
    _muat();
    // Segarkan status "Berlangsung" tiap menit tanpa memanggil server.
    _jam = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _jam?.cancel();
    super.dispose();
  }

  Future<void> _muat({bool tarik = false}) async {
    if (!tarik) {
      setState(() {
        _memuat = true;
        _galat = null;
      });
    }
    try {
      final guru = await GuruService.me();
      final kelas = (guru).kelas;
      var jadwal = const <JadwalModel>[];
      if (kelas != null) {
        jadwal = await JadwalService.daftar(semester: kelas.semester == 'genap' ? 'genap' : 'ganjil');
      }
      if (!mounted) return;
      setState(() {
        _kelas = kelas;
        _jadwal = jadwal;
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

  void _geser(int hari) {
    setState(() => _tanggal = DateTime(_tanggal.year, _tanggal.month, _tanggal.day + hari));
  }

  Future<void> _pilihTanggal() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null) setState(() => _tanggal = DateTime(d.year, d.month, d.day));
  }

  bool get _hariIni {
    final n = DateTime.now();
    return _tanggal.year == n.year && _tanggal.month == n.month && _tanggal.day == n.day;
  }

  List<JadwalModel> get _dataHari {
    if (_tanggal.weekday == DateTime.sunday) return const [];
    final kunci = DateFormatter.hariApi(_tanggal);
    return _jadwal.where((j) => j.hari == kunci).toList()
      ..sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(title: 'Jadwal Hari Ini', builder: _isiLayar),
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
          _kartuTanggal(),
          const SizedBox(height: 14),
          ..._isiDaftar(),
        ],
      ),
    );
  }

  Widget _kartuTanggal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: AppColors.headerGreen, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: _pilihTanggal,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  DateFormatter.lengkap(_tanggal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Hari sebelumnya',
            onPressed: () => _geser(-1),
            icon: const Icon(Icons.chevron_left, color: AppColors.textDark),
          ),
          IconButton(
            tooltip: 'Hari berikutnya',
            onPressed: () => _geser(1),
            icon: const Icon(Icons.chevron_right, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  List<Widget> _isiDaftar() {
    if (_memuat) {
      return const [Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingIndicator())];
    }
    if (_galat != null) {
      return [ErrorState(message: _galat!, onRetry: _muat)];
    }
    if (_kelas == null) {
      return const [
        EmptyState(
          message: 'Anda belum ditetapkan sebagai wali kelas pada tahun ajaran aktif. Hubungi Admin.',
          icon: Icons.info_outline,
        ),
      ];
    }
    if (_tanggal.weekday == DateTime.sunday) {
      return const [EmptyState(message: 'Hari Minggu libur.', icon: Icons.beach_access_outlined)];
    }
    final data = _dataHari;
    if (data.isEmpty) {
      return const [
        EmptyState(message: 'Tidak ada jadwal pelajaran pada tanggal ini.', icon: Icons.event_busy),
      ];
    }
    final sekarang = DateTime.now();
    return [
      Text(
        'Semua Jadwal ${_hariIni ? 'Hari Ini' : 'Hari Itu'} (${data.length})',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
      ),
      const SizedBox(height: 10),
      for (final j in data) _kartuJadwal(j, sekarang),
    ];
  }

  Widget _kartuJadwal(JadwalModel j, DateTime sekarang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_filled, size: 20, color: AppColors.textDark),
              const SizedBox(width: 6),
              Text(
                j.rentangJam,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      j.mapel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    Text(
                      'Kelas ${_kelas?.nama ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                    ),
                    if (j.keterangan != null && j.keterangan!.isNotEmpty)
                      Text(
                        j.keterangan!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusJadwalChip(status: j.statusPada(_tanggal, sekarang)),
            ],
          ),
        ],
      ),
    );
  }
}