import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/absensi_model.dart';
import 'package:si_kesa/models/guru_model.dart';
import 'package:si_kesa/services/absensi_service.dart';

/// Ringkasan kelas Guru + kartu "Absensi Hari Ini" (Sudah / Belum / Libur) dengan tombol Isi Absensi.
/// Status absensi dimuat sendiri; kegagalannya tidak memblokir Beranda. Buat ulang dengan Key baru untuk menyegarkan.
class GuruKelasCard extends StatefulWidget {
  final GuruModel guru;
  final VoidCallback onIsiAbsensi;

  const GuruKelasCard({super.key, required this.guru, required this.onIsiAbsensi});

  @override
  State<GuruKelasCard> createState() => _GuruKelasCardState();
}

class _GuruKelasCardState extends State<GuruKelasCard> {
  late Future<StatusAbsensiHari> _status = AbsensiService.statusHariIni();

  void _muatUlang() => setState(() => _status = AbsensiService.statusHariIni());

  @override
  Widget build(BuildContext context) {
    final kelas = widget.guru.kelas!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBeige,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.headerGreen,
                child: Icon(Icons.school, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wali Kelas ${kelas.nama}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      widget.guru.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                    ),
                    Text(
                      '${kelas.tahunAjaran} \u2022 Semester ${kelas.semesterLabel} \u2022 ${kelas.jumlahSiswaAktif} siswa aktif',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          FutureBuilder<StatusAbsensiHari>(
            future: _status,
            builder: (context, snap) {
              final memuat = snap.connectionState != ConnectionState.done;
              final gagal = snap.hasError;
              final status = snap.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Absensi Hari Ini',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (memuat)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        )
                      else if (gagal)
                        TextButton.icon(
                          onPressed: _muatUlang,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                        )
                      else
                        _ChipStatus(status: status!),
                    ],
                  ),
                  if (status != StatusAbsensiHari.libur) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: memuat ? null : widget.onIsiAbsensi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          status == StatusAbsensiHari.sudah ? 'Perbarui Absensi' : 'Isi Absensi',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChipStatus extends StatelessWidget {
  final StatusAbsensiHari status;
  const _ChipStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, warna) = switch (status) {
      StatusAbsensiHari.sudah => ('Sudah', AppColors.success),
      StatusAbsensiHari.belum => ('Belum', AppColors.primary),
      StatusAbsensiHari.libur => ('Libur', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: warna),
      ),
    );
  }
}