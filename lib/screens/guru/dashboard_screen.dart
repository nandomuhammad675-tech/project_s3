import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/guru_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/guru_service.dart';
import 'package:si_kesa/utils/ui_helper.dart';
import 'package:si_kesa/widgets/app_header.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/guru_header.dart';
import 'package:si_kesa/widgets/guru_jadwal_hari_ini_card.dart';
import 'package:si_kesa/widgets/guru_menu_card.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/screens/guru/disiplin/form_screen.dart';
import 'package:si_kesa/screens/guru/disiplin/rekap_screen.dart';
import 'package:si_kesa/screens/guru/piket/piket_screen.dart';
import 'package:si_kesa/screens/guru/absensi/absensi_screen.dart';
import 'package:si_kesa/screens/guru/absensi/riwayat_screen.dart';
import 'package:si_kesa/screens/guru/nilai/input_nilai_screen.dart';
import 'package:si_kesa/screens/guru/nilai/rekap_seluruh_siswa_screen.dart';
import 'package:si_kesa/screens/guru/jadwal/jadwal_mengajar_screen.dart';
import 'package:si_kesa/screens/guru/jadwal/jadwal_hari_ini_screen.dart';

/// Beranda Guru. Memanggil GET /api/guru/me (Dokumen 02 bagian 2.4):
/// - kelas terisi  : menu Akses Cepat dan jadwal hari ini
/// - kelas = null  : pesan "belum ditetapkan sebagai wali kelas", semua menu dimatikan, tanpa crash
/// - memuat/gagal  : indikator / pesan + tombol Coba Lagi
/// 401 ditangani global di ApiClient (hapus token, kembali ke Login).
class GuruDashboardScreen extends StatefulWidget {
  const GuruDashboardScreen({super.key});

  @override
  State<GuruDashboardScreen> createState() => _GuruDashboardScreenState();
}

class _MenuGuru {
  final String judul;
  final String subjudul;
  final IconData ikon;
  final Color warna;

  const _MenuGuru(this.judul, this.subjudul, this.ikon, this.warna);
}

class _GuruDashboardScreenState extends State<GuruDashboardScreen> {
  static const _menu = [
    _MenuGuru('Absensi Harian', 'Lihat & Lakukan absensi', Icons.person, AppColors.accentBlue),
    _MenuGuru('Riwayat Absen', 'Lihat Riwayat Kehadiran', Icons.calendar_month, AppColors.accentOrange),
    _MenuGuru('Input Nilai', 'Masukan Nilai Siswa', Icons.assignment_turned_in, AppColors.accentOrange),
    _MenuGuru('Rekap Nilai', 'Lihat Rekap Nilai', Icons.note_add, AppColors.accentBlue),
    _MenuGuru('Jadwal Mengajar', 'Lihat Jadwal Pelajaran', Icons.groups, AppColors.accentBlue),
    _MenuGuru('Jadwal Piket', 'Lihat Jadwal Piket', Icons.cleaning_services, AppColors.accentOrange),
    _MenuGuru('Kedisiplinan', 'Lihat Kedisiplinan Siswa', Icons.gavel, AppColors.accentRed),
    _MenuGuru('Rekap Kedisiplinan', 'Lihat Rekap', Icons.assignment, AppColors.accentBlue),
  ];

  late Future<GuruModel> _guru = GuruService.me();
  int _versi = 0; // naik tiap penyegaran agar kartu jadwal memuat ulang datanya

  /// Muat ulang semua (tarik layar ke bawah, atau tombol Coba Lagi).
  Future<void> _muat() async {
    setState(() {
      _guru = GuruService.me();
      _versi++;
    });
    try {
      await _guru;
    } catch (_) {
      // Kegagalan sudah tampil lewat ErrorState; RefreshIndicator cukup berhenti berputar.
    }
  }

  // TODO: ganti dengan Navigator.push ke layar fitur bila sudah dibuat.
        void _buka(String nama) {
              if (nama == 'Jadwal Mengajar') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JadwalMengajarGuruScreen()),
      );
      return;
    }
    if (nama == 'Jadwal') {
      // Tombol "Lihat Semua" pada kartu Jadwal Hari Ini di Beranda.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JadwalHariIniGuruScreen()),
      );
      return;
    }
    if (nama == 'Rekap Nilai') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RekapSeluruhSiswaScreen()),
      );
      return;
    }
          if (nama == 'Input Nilai') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const InputNilaiGuruScreen()),
      );
      return;
    }
      if (nama == 'Absensi Harian') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AbsensiGuruScreen()),
      );
      return;
    }
       if (nama == 'Riwayat Absen') {
     Navigator.of(context).push(
       MaterialPageRoute(builder: (_) => const RiwayatAbsenGuruScreen()),
     );
     return;
   }
    if (nama == 'Kedisiplinan') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DisiplinGuruScreen()),
      );
      return;
    }
    if (nama == 'Rekap Kedisiplinan') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RekapDisiplinGuruScreen()),
      );
      return;
    }
    if (nama == 'Jadwal Piket') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PiketGuruScreen()),
      );
      return;
    }
    tampilkanBelumTersedia(context, nama);
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
              child: LayoutBuilder(
                builder: (context, box) {
                  // Tinggi area kosong di bawah header, dipakai agar loading/error tepat di tengah.
                  final tinggiTengah = box.maxHeight - tinggiHeader - 20 - 24;
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, tinggiHeader + 20, 16, 24),
                    child: FutureBuilder<GuruModel>(
                      future: _guru,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return SizedBox(
                            height: tinggiTengah,
                            child: const LoadingIndicator(),
                          );
                        }
                        if (snap.hasError) {
                          return SizedBox(
                            height: tinggiTengah,
                            child: ErrorState(message: pesanDariError(snap.error!), onRetry: _muat),
                          );
                        }
                        return _isi(snap.data!);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          // Header tetap di atas, tidak ikut tergulir.
          const Positioned(top: 0, left: 0, right: 0, child: GuruHeader()),
        ],
      ),
    );
  }

  Widget _isi(GuruModel guru) {
    final aktif = guru.adaKelas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!aktif) ...[
          const _PesanBelumWaliKelas(),
          const SizedBox(height: 20),
        ],
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
                Expanded(child: _kartu(_menu[i], aktif)),
                const SizedBox(width: 12),
                Expanded(child: _kartu(_menu[i + 1], aktif)),
              ],
            ),
          ),
        ],
        if (aktif) ...[
          const SizedBox(height: 20),
          GuruJadwalHariIniCard(
            key: ValueKey('jadwal$_versi'),
            semester: guru.kelas!.semester,
            namaKelas: guru.kelas!.nama,
            onLihatSemua: () => _buka('Jadwal'),
            onTapJudul: () => _buka('Jadwal Mengajar'),
          ),
        ],
      ],
    );
  }

  Widget _kartu(_MenuGuru m, bool aktif) => GuruMenuCard(
        title: m.judul,
        subtitle: m.subjudul,
        icon: m.ikon,
        color: m.warna,
        onTap: aktif ? () => _buka(m.judul) : null, // belum jadi wali kelas: semua menu mati
      );
}

class _PesanBelumWaliKelas extends StatelessWidget {
  const _PesanBelumWaliKelas();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBeige,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentOrange),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.accentOrange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Anda belum ditetapkan sebagai wali kelas pada tahun ajaran aktif. Hubungi Admin.',
              style: TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}