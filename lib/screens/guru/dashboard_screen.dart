import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/guru_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/guru_service.dart';
import 'package:si_kesa/utils/ui_helper.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/guru_header.dart';
import 'package:si_kesa/widgets/guru_jadwal_hari_ini_card.dart';
import 'package:si_kesa/widgets/guru_kelas_card.dart';
import 'package:si_kesa/widgets/guru_menu_card.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';

/// Beranda Guru. Memanggil GET /api/guru/me (Dokumen 02 bagian 2.4):
/// - kelas terisi  : ringkasan kelas, status absensi hari ini, menu, jadwal hari ini
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
  int _versi = 0; // naik tiap penyegaran agar kartu anak memuat ulang datanya

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

  // TODO: ganti dengan Navigator.push ke layar fitur bila sudah dibuat, lalu panggil _muat()
  // setelah kembali (supaya kartu "Absensi Hari Ini" berubah menjadi "Sudah").
  void _buka(String nama) => tampilkanBelumTersedia(context, nama);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _muat,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const GuruHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: FutureBuilder<GuruModel>(
                  future: _guru,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const SizedBox(height: 280, child: LoadingIndicator());
                    }
                    if (snap.hasError) {
                      return ErrorState(message: pesanDariError(snap.error!), onRetry: _muat);
                    }
                    return _isi(snap.data!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _isi(GuruModel guru) {
    final aktif = guru.adaKelas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (aktif)
          GuruKelasCard(
            key: ValueKey('kelas$_versi'),
            guru: guru,
            onIsiAbsensi: () => _buka('Absensi'),
          )
        else
          const _PesanBelumWaliKelas(),
        const SizedBox(height: 20),
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