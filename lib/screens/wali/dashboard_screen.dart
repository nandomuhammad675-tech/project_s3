import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/widgets/quick_access_card.dart';
import 'package:si_kesa/widgets/siswa_header.dart';
import 'package:si_kesa/widgets/siswa_data_card.dart';
import 'package:si_kesa/screens/wali/absensi_screen.dart';
import 'package:si_kesa/screens/wali/disiplin_screen.dart';
import 'package:si_kesa/screens/wali/nilai_screen.dart';

class SiswaDashboardScreen extends StatelessWidget {
  const SiswaDashboardScreen({super.key});

  // Warna kartu (perkiraan dari Figma)
  static const _absenBg = Color(0xFFFFEFD2);
  static const _nilaiBg = Color(0xFFB6F0A4);
  static const _disiplinBg = Color(0xFFF6E0E0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SiswaHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
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
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: QuickAccessCard(
                          title: 'Riwayat Absen',
                          subtitle: 'Lihat Riwayat Kehadiran',
                          icon: Icons.calendar_month,
                          cardColor: _absenBg,
                          iconColor: AppColors.primary,
                            onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AbsensiSiswaScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickAccessCard(
                          title: 'Rekap Nilai',
                          subtitle: 'Lihat Rekap Nilai',
                          icon: Icons.note_add,
                          cardColor: _nilaiBg,
                          iconColor: const Color(0xFF2E8B57),
                          onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NilaiSiswaScreen()),
                        ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: QuickAccessCard(
                          title: 'Rekap Kedisiplinan',
                          subtitle: 'Lihat Rekap Kedisiplinan Siswa',
                          icon: Icons.assignment,
                          cardColor: _disiplinBg,
                          iconColor: const Color(0xFFB88A8A),
                          onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DisiplinSiswaScreen()),
                        ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()), // kolom kanan kosong
                    ],
                  ),
                  const SizedBox(height: 28),
                  const SiswaDataCard(
                    nama: 'Aji Ariya',
                    kelas: '6A',
                    nisn: '0087654321',
                    status: 'Aktif',
                    waliKelas: 'Lestari, S.Pd., M.Pd.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}