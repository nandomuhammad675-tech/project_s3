import 'package:flutter/material.dart';
import 'package:si_kesa/models/jadwal_model.dart';

/// Label kecil status jadwal: Selesai (hijau), Berlangsung (biru), Menunggu (kuning), Akan Datang (krem).
class StatusJadwalChip extends StatelessWidget {
  final StatusJadwal status;

  const StatusJadwalChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (teks, latar, huruf) = switch (status) {
      StatusJadwal.selesai => ('Selesai', const Color(0xFFD8F3DC), const Color(0xFF2E7D32)),
      StatusJadwal.berlangsung => ('Berlangsung', const Color(0xFFD6EBFF), const Color(0xFF1565C0)),
      StatusJadwal.menunggu => ('Menunggu', const Color(0xFFFFF3B0), const Color(0xFF8A6D00)),
      StatusJadwal.akanDatang => ('Akan Datang', const Color(0xFFF3EFE3), const Color(0xFF4A2E06)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: latar, borderRadius: BorderRadius.circular(6)),
      child: Text(
        teks,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: huruf),
      ),
    );
  }
}