import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/screens/guru/nilai/rekap_nilai_screen.dart';
import 'package:si_kesa/screens/guru/nilai/rekap_per_mapel_screen.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';

/// Rekap Seluruh Siswa: pilih jenis rekap.
/// Rekap Per Mapel (semua siswa, satu mapel) atau Rekap Satu Siswa (pilih siswa, lihat semua mapel).
class RekapSeluruhSiswaScreen extends StatelessWidget {
  const RekapSeluruhSiswaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(title: 'Rekap Seluruh Siswa', builder: (tinggi) => _isi(context, tinggi)),
    );
  }

  Widget _isi(BuildContext context, double tinggiHeader) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, tinggiHeader + 20, 16, 24),
      children: [
        const Text(
          'Pilih Jenis Rekap',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.headerGreen),
        ),
        const SizedBox(height: 12),
        _kartu(
          context,
          ikon: Icons.library_books_outlined,
          judul: 'Rekap Per Mapel',
          keterangan: 'Rekap Berdasarkan Mapel',
          tujuan: const RekapPerMapelScreen(),
        ),
        const SizedBox(height: 12),
        _kartu(
          context,
          ikon: Icons.person,
          judul: 'Rekap Satu Siswa',
          keterangan: 'Satu Siswa, Semua Mapel',
          tujuan: const RekapNilaiGuruScreen(),
        ),
      ],
    );
  }

  Widget _kartu(
    BuildContext context, {
    required IconData ikon,
    required String judul,
    required String keterangan,
    required Widget tujuan,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => tujuan)),
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: AppColors.headerGreen, shape: BoxShape.circle),
                child: Icon(ikon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      keterangan,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.headerGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textDark),
            ],
          ),
        ),
      ),
    );
  }
}