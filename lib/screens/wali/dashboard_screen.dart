import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/siswa_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/wali_service.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/widgets/quick_access_card.dart';
import 'package:si_kesa/widgets/siswa_header.dart';
import 'package:si_kesa/widgets/siswa_data_card.dart';

class SiswaDashboardScreen extends StatefulWidget {
  /// Pindah tab pada SiswaMainScreen (1 Nilai, 2 Absen, 3 Disiplin).
  final ValueChanged<int> onBukaTab;
  const SiswaDashboardScreen({super.key, required this.onBukaTab});

  @override
  State<SiswaDashboardScreen> createState() => _SiswaDashboardScreenState();
}

class _SiswaDashboardScreenState extends State<SiswaDashboardScreen> {
  // Warna kartu (perkiraan dari Figma)
  static const _absenBg = Color(0xFFFFEFD2);
  static const _nilaiBg = Color(0xFFB6F0A4);
  static const _disiplinBg = Color(0xFFF6E0E0);

  late Future<SiswaModel> _profil = WaliService.profil();

  void _muatUlang() {
    setState(() {
      _profil = WaliService.profil(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SiswaHeader(), // tetap di atas, tidak ikut tergulir
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
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
                            onTap: () => widget.onBukaTab(2),
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
                            onTap: () => widget.onBukaTab(1),
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
                            onTap: () => widget.onBukaTab(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()), // kolom kanan kosong
                      ],
                    ),
                    const SizedBox(height: 28),
                    FutureBuilder<SiswaModel>(
                      future: _profil,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const SizedBox(
                            height: 160,
                            child: LoadingIndicator(),
                          );
                        }
                        if (snap.hasError) {
                          return ErrorState(
                            message: pesanDariError(snap.error!),
                            onRetry: _muatUlang,
                          );
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
        ],
      ),
    );
  }
}