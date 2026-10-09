import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/absensi_model.dart';
import 'package:si_kesa/utils/date_formatter.dart';
import 'package:si_kesa/widgets/sub_page_header.dart';

class AbsensiSiswaScreen extends StatefulWidget {
  final bool showBack;
  const AbsensiSiswaScreen({super.key, this.showBack = true});

  @override
  State<AbsensiSiswaScreen> createState() => _AbsensiSiswaScreenState();
}

class _AbsensiSiswaScreenState extends State<AbsensiSiswaScreen> {
  // Data dummy sementara
  static const _nama = 'Aji Ariya';
  static const _kelas = '6A';

  final _bulanList = [DateTime(2026, 8), DateTime(2026, 9)];
  DateTime _bulanDipilih = DateTime(2026, 9);

  final _semua = [
    AbsensiModel(tanggal: DateTime(2026, 9, 1), status: StatusKehadiran.sakit),
    AbsensiModel(tanggal: DateTime(2026, 9, 7), status: StatusKehadiran.izin),
    AbsensiModel(tanggal: DateTime(2026, 9, 15), status: StatusKehadiran.alfa),
    AbsensiModel(tanggal: DateTime(2026, 9, 16), status: StatusKehadiran.sakit),
    AbsensiModel(tanggal: DateTime(2026, 9, 21), status: StatusKehadiran.izin),
    AbsensiModel(tanggal: DateTime(2026, 9, 22), status: StatusKehadiran.sakit),
    AbsensiModel(tanggal: DateTime(2026, 9, 25), status: StatusKehadiran.izin),
    AbsensiModel(tanggal: DateTime(2026, 9, 29), status: StatusKehadiran.sakit),
    AbsensiModel(tanggal: DateTime(2026, 8, 10), status: StatusKehadiran.sakit),
    AbsensiModel(tanggal: DateTime(2026, 8, 18), status: StatusKehadiran.alfa),
  ];

  List<AbsensiModel> get _bulanIni {
    final list = _semua
        .where((a) =>
            a.tanggal.year == _bulanDipilih.year &&
            a.tanggal.month == _bulanDipilih.month)
        .toList();
    list.sort((a, b) => b.tanggal.compareTo(a.tanggal)); // terbaru di atas
    return list;
  }

  int _hitung(StatusKehadiran s) =>
      _bulanIni.where((a) => a.status == s).length;

  String get _initials {
    final parts = _nama.trim().split(RegExp(r'\s+'));
    final second = parts.length > 1 ? parts[1][0] : '';
    return (parts[0][0] + second).toUpperCase();
  }

  static String _label(StatusKehadiran s) => switch (s) {
        StatusKehadiran.hadir => 'Hadir',
        StatusKehadiran.sakit => 'Sakit',
        StatusKehadiran.izin => 'Izin',
        StatusKehadiran.alfa => 'Alfa',
      };

  static Color _warna(StatusKehadiran s) => switch (s) {
        StatusKehadiran.hadir => const Color(0xFF2E8B57),
        StatusKehadiran.sakit => const Color(0xFF4B5A2F),
        StatusKehadiran.izin => const Color(0xFFB8A12A),
        StatusKehadiran.alfa => const Color(0xFFE00000),
      };

  @override
  Widget build(BuildContext context) {
    final data = _bulanIni;

    return Scaffold(
      body: Column(
        children: [
          SubPageHeader(title: 'Riwayat Absen', showBack: widget.showBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                _kartuSiswa(),
                const SizedBox(height: 24),
                const Text(
                  'Bulan',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 8),
                _pilihBulan(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _kotakRingkasan(
                      _hitung(StatusKehadiran.sakit),
                      'Sakit',
                      const Color(0xFFFBE6D8),
                      _warna(StatusKehadiran.sakit),
                    ),
                    const SizedBox(width: 12),
                    _kotakRingkasan(
                      _hitung(StatusKehadiran.izin),
                      'Izin',
                      const Color(0xFFFAEBD5),
                      _warna(StatusKehadiran.izin),
                    ),
                    const SizedBox(width: 12),
                    _kotakRingkasan(
                      _hitung(StatusKehadiran.alfa),
                      'Alfa',
                      const Color(0xFFFDE0E0),
                      _warna(StatusKehadiran.alfa),
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
                if (data.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Belum ada data absensi.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...data.map(_itemRincian),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuSiswa() {
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
              _initials,
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
              children: const [
                Text(
                  _nama,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text('Kelas $_kelas', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pilihBulan() {
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
          items: _bulanList
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

  Widget _itemRincian(AbsensiModel a) {
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
                const Text(
                  _nama,
                  style: TextStyle(
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