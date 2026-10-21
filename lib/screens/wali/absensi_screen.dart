import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/absensi_model.dart';
import 'package:si_kesa/models/siswa_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/wali_service.dart';
import 'package:si_kesa/utils/date_formatter.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/widgets/semester_toggle.dart';
import 'package:si_kesa/widgets/app_header.dart';
import 'package:si_kesa/widgets/sub_page_header.dart';

class AbsensiSiswaScreen extends StatefulWidget {
  final bool showBack;
  final VoidCallback? onBack;
  const AbsensiSiswaScreen({super.key, this.showBack = true, this.onBack});

  @override
  State<AbsensiSiswaScreen> createState() => _AbsensiSiswaScreenState();
}

class _AbsensiSiswaScreenState extends State<AbsensiSiswaScreen> {
  late Future<_Data> _future = _muat();
  DateTime? _bulanDipilih;
  String? _semester; // null = ikut semester berjalan

  Future<_Data> _muat() async {
    final profil = await WaliService.profil();
    final absensi = await WaliService.absensi();
    return _Data(profil, absensi.items, absensi.tahunAjaran, absensi.semesterAktif);
  }

  void _muatUlang() {
    setState(() {
      _bulanDipilih = null;
      _semester = null;
      _future = _muat();
    });
  }

  // Bulan yang punya data, urut dari lama ke baru
  static List<DateTime> _daftarBulan(List<AbsensiModel> items) {
    final set = <DateTime>{
      for (final a in items) DateTime(a.tanggal.year, a.tanggal.month),
    };
    return set.toList()..sort();
  }

  List<AbsensiModel> _bulanIni(List<AbsensiModel> items) {
    final b = _bulanDipilih;
    if (b == null) return const [];
    final list = items
        .where((a) => a.tanggal.year == b.year && a.tanggal.month == b.month)
        .toList();
    list.sort((x, y) => y.tanggal.compareTo(x.tanggal)); // terbaru di atas
    return list;
  }

  int _hitung(List<AbsensiModel> data, StatusKehadiran s) =>
      data.where((a) => a.status == s).length;

  static String _initials(String nama) {
    final parts = nama.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  static String _label(StatusKehadiran s) => switch (s) {
        StatusKehadiran.hadir => 'Hadir',
        StatusKehadiran.sakit => 'Sakit',
        StatusKehadiran.izin => 'Izin',
        StatusKehadiran.alpa => 'Alpa',
      };

  static Color _warna(StatusKehadiran s) => switch (s) {
        StatusKehadiran.hadir => const Color(0xFF2E8B57),
        StatusKehadiran.sakit => const Color(0xFF4B5A2F),
        StatusKehadiran.izin => const Color(0xFFB8A12A),
        StatusKehadiran.alpa => const Color(0xFFE00000),
      };

  @override
  Widget build(BuildContext context) {
    final tinggi = AppHeader.tinggi(context); // tinggi header gelombang
    return Scaffold(
      body: Stack(children: [
Positioned.fill(child: FutureBuilder<_Data>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return Padding(padding: EdgeInsets.only(top: tinggi), child: const LoadingIndicator());
                }
                if (snap.hasError) {
                  return Padding(
                    padding: EdgeInsets.only(top: tinggi),
                    child: ErrorState(message: pesanDariError(snap.error!), onRetry: _muatUlang),
                  );
                }
                final d = snap.data!;
                _semester ??= d.semesterAktif;
                final itemSemester =
                    d.items.where((a) => a.semester == _semester).toList();
                final bulanList = _daftarBulan(itemSemester);
                if (_bulanDipilih == null || !bulanList.contains(_bulanDipilih)) {
                  _bulanDipilih = bulanList.isEmpty ? null : bulanList.last;
                }
                final data = _bulanIni(itemSemester);

                return ListView(
                  padding: EdgeInsets.fromLTRB(20, 20 + tinggi, 20, 24),
                  children: [
                    _kartuSiswa(d.siswa),
                    const SizedBox(height: 16),
                    SemesterToggle(
                      tahunAjaran: d.tahunAjaran,
                      semester: _semester!,
                      semesterAktif: d.semesterAktif,
                      onChanged: (v) => setState(() {
                        _semester = v;
                        _bulanDipilih = null; // bulan dipilih ulang per semester
                      }),
                    ),
                    const SizedBox(height: 20),
                    if (bulanList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'Belum ada data absensi pada semester ini.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else ...[
                      const Text(
                        'Bulan',
                        style: TextStyle(fontSize: 13, color: AppColors.textHint),
                      ),
                      const SizedBox(height: 8),
                      _pilihBulan(bulanList),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _kotakRingkasan(
                            _hitung(data, StatusKehadiran.sakit),
                            'Sakit',
                            const Color(0xFFFBE6D8),
                            _warna(StatusKehadiran.sakit),
                          ),
                          const SizedBox(width: 12),
                          _kotakRingkasan(
                            _hitung(data, StatusKehadiran.izin),
                            'Izin',
                            const Color(0xFFFAEBD5),
                            _warna(StatusKehadiran.izin),
                          ),
                          const SizedBox(width: 12),
                          _kotakRingkasan(
                            _hitung(data, StatusKehadiran.alpa),
                            'Alpa',
                            const Color(0xFFFDE0E0),
                            _warna(StatusKehadiran.alpa),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Rincian Kehadiran',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.headerGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...data.map((a) => _itemRincian(d.siswa.nama, a)),
                    ],
                  ],
                );
              },
            )),
Positioned(top: 0, left: 0, right: 0, child: SubPageHeader(title: 'Riwayat Absen', showBack: widget.showBack, onBack: widget.onBack)),
]),
    );
  }

  Widget _kartuSiswa(SiswaModel s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFD2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Text(
              _initials(s.nama),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppColors.headerGreen,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.nama,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text('Kelas ${s.namaKelas}', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pilihBulan(List<DateTime> bulanList) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          value: _bulanDipilih,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textHint,
          ),
          items: bulanList
              .map(
                (b) => DropdownMenuItem(
                  value: b,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 8),
                      Text(DateFormatter.bulanTahun(b)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _bulanDipilih = v);
          },
        ),
      ),
    );
  }

  Widget _kotakRingkasan(int jumlah, String label, Color bg, Color warna) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$jumlah',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: warna,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: warna,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRincian(String nama, AbsensiModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
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
                  nama,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  DateFormatter.lengkap(a.tanggal),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _label(a.status),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _warna(a.status),
            ),
          ),
        ],
      ),
    );
  }
}

class _Data {
  final SiswaModel siswa;
  final List<AbsensiModel> items;
  final String tahunAjaran;
  final String semesterAktif;
  const _Data(this.siswa, this.items, this.tahunAjaran, this.semesterAktif);
}