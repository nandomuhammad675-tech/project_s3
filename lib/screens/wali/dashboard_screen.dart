import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/siswa_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/wali_service.dart';
import 'package:si_kesa/widgets/app_header.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/guru_menu_card.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/widgets/siswa_data_card.dart';
import 'package:si_kesa/widgets/siswa_header.dart';

/// Beranda Wali Murid. Hanya membaca: tiga pintasan (Absen, Nilai, Kedisiplinan) dan data diri anak.
/// Tata letak mengikuti Beranda Guru (header di depan, isi tergulir di belakang gelombang).
class SiswaDashboardScreen extends StatefulWidget {
  /// Pindah tab pada SiswaMainScreen (1 Nilai, 2 Absen, 3 Disiplin).
  final ValueChanged<int> onBukaTab;
  const SiswaDashboardScreen({super.key, required this.onBukaTab});

  @override
  State<SiswaDashboardScreen> createState() => _SiswaDashboardScreenState();
}

class _MenuSiswa {
  final String judul;
  final String subjudul;
  final IconData ikon;
  final Color warna;
  final int tab; // indeks tab di SiswaMainScreen

  const _MenuSiswa(this.judul, this.subjudul, this.ikon, this.warna, this.tab);
}

class _SiswaDashboardScreenState extends State<SiswaDashboardScreen> {
  static const _menu = [
    _MenuSiswa('Riwayat Absen', 'Lihat Riwayat Kehadiran', Icons.calendar_month, AppColors.accentOrange, 2),
    _MenuSiswa('Rekap Nilai', 'Lihat Rekap Nilai', Icons.note_add, AppColors.accentBlue, 1),
    _MenuSiswa('Rekap Kedisiplinan', 'Lihat Rekap Kedisiplinan Siswa', Icons.assignment, AppColors.accentRed, 3),
  ];

  late Future<SiswaModel> _profil = WaliService.profil();

  /// Muat ulang data anak (tarik layar ke bawah, atau tombol Coba Lagi).
  Future<void> _muat() async {
    setState(() {
      _profil = WaliService.profil(refresh: true);
    });
    try {
      await _profil;
    } catch (_) {
      // Kegagalan tampil lewat ErrorState; RefreshIndicator cukup berhenti berputar.
    }
  }

  @override
  Widget build(BuildContext context) {
    final tinggiHeader = AppHeader.tinggi(context);

    return Scaffold(
      body: Stack(
        children: [
          // Isi yang digulir, berada di belakang header.
          Positioned.fill(
            child: RefreshIndicator(
              color: AppColors.primary,
              edgeOffset: tinggiHeader,
              onRefresh: _muat,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, tinggiHeader + 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Akses Cepat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < _menu.length; i += 2) ...[
                      if (i > 0) const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _kartu(_menu[i])),
                            const SizedBox(width: 12),
                            // Jumlah menu ganjil: kolom kanan baris terakhir dibiarkan kosong.
                            Expanded(
                              child: i + 1 < _menu.length
                                  ? _kartu(_menu[i + 1])
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FutureBuilder<SiswaModel>(
                      future: _profil,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const SizedBox(height: 160, child: LoadingIndicator());
                        }
                        if (snap.hasError) {
                          return ErrorState(message: pesanDariError(snap.error!), onRetry: _muat);
                        }
                        final s = snap.data!;
                        return SiswaDataCard(
                          nama: s.nama,
                          kelas: s.namaKelas,
                          nisn: s.nisn,
                          status: 'Aktif',
                          waliKelas: s.namaWaliKelas,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Header tetap di atas, tidak ikut tergulir.
          const Positioned(top: 0, left: 0, right: 0, child: SiswaHeader()),
        ],
      ),
    );
  }

  Widget _kartu(_MenuSiswa m) => GuruMenuCard(
        title: m.judul,
        subtitle: m.subjudul,
        icon: m.ikon,
        color: m.warna,
        onTap: () => widget.onBukaTab(m.tab),
      );
}